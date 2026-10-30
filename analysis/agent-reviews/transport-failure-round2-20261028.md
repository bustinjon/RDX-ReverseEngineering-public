# Transport Write Failure — Round 2: Challenges & Counter-Analysis

**Date:** 2026-10-28
**Responding to:** Coordinator's challenges on pm disable, confidence levels, and AOAP mode switch plan

---

## Challenge 1: "pm disable doesn't work from shell"

**ACCEPTED.** My Round 1 analysis listed `pm disable` as Solution #1 — that was wrong. The permission dump shows `CHANGE_COMPONENT_ENABLED_STATE` is `signature|system` (defined in the `android` package, uid 1000). Shell (uid 2000) is a system package, but `pm disable` on a system package's component may still fail if the target package shares uid 1000 (Honda's AA sink does: `userId=1000`). The coordinator confirmed the SecurityException on-car. Solution 1 from Round 1 is dead.

**However:** `am force-stop` uses a DIFFERENT permission: `FORCE_STOP_PACKAGES`, also `signature|system`. The key question is whether shell can exercise it. On stock AOSP 5.1, `com.android.shell` is installed in `/system/app/Shell` and declares `<uses-permission android:name="android.permission.FORCE_STOP_PACKAGES"/>`. Being a system package satisfies the `signature|system` protection. **This has NOT been tested on the head unit.** The permission dump at `analysis/parallel-aa-receiver/evidence/device/permissions.stdout.txt` shows `FORCE_STOP_PACKAGES` exists (line 1523) at protection level `signature|system`, but we don't have a dump of `com.android.shell`'s granted permissions.

**Recommended test:**
[Code block omitted from public report; see authored source where available.]

If `am force-stop` fails: we need a different strategy entirely. More on this below.

---

## Challenge 2: Confidence Level — "Phone closed its AOAP FD"

### The coordinator's NAK timing argument is incorrect

The coordinator argues: "if f_accessory had its disconnected flag set, the host's OUT bulk transfers should be NAK'd IMMEDIATELY by the gadget controller, not timeout after 1000ms."

**This misunderstands how USB bulk transfer NAKs work at the host level.** [CONFIRMED by USB 2.0 spec behavior]

In USB 2.0, when a bulk OUT endpoint has no pending request buffer (because f_accessory has no reader, or the buffer is full), the device controller sends a NAK handshake token for each host attempt. But the host controller **retries automatically on NAK**. The application-level `bulkTransfer()` API never sees individual NAKs — it keeps retrying until either:

1. **Data accepted** (device submits a request buffer) — returns the byte count
2. **Timeout expires** (too many NAKs within the timeout) — returns -1
3. **STALL** (endpoint halted) — returns -1 **immediately, without waiting for timeout**

A **STALL** produces an immediate failure. A **NAK-driven failure** produces a timeout. The 995ms duration in session 2 is diagnostic:

- If it were a STALL: the write would fail in <1ms, not 995ms
- 995ms matching the 1000ms timeout parameter means perpetual NAKs until timeout

**This is fully consistent with my "phone closed its FD" theory.** When f_accessory has no reader, no USB request buffers are submitted for the OUT endpoint, the device NAKs every host token, and the host times out.

But the coordinator raises a valid alternative: **the phone's FD might be open but the phone's read buffer is full (gearhead stuck in a blocking read on its SSL layer, waiting for encrypted data that will never come from the dead Honda session).** This would also produce NAKs and the same timeout behavior.

### Revised confidence assessment

**I'm revising the confidence:**

| Scenario | Session 1 evidence | Session 2 evidence | Rating |
|----------|-------------------|-------------------|--------|
| Phone FD closed by session 2 | Compatible (3.1s = ~2s native block + 1s timeout) | STRONG: 22 seconds elapsed since Honda died; any reasonable AA ping timeout (5-10s) would have triggered session closure | **LIKELY** |
| Phone FD still open but stuck (read buffer full, no consumer) | Compatible | WEAK: 22 seconds of stuck state without gearhead timing out and closing is implausible | **UNLIKELY for session 2** |
| Phone FD open, gearhead actively processing | CONTRADICTED: if gearhead were reading from OUT endpoint, bulkTransfer would succeed (data goes into the request buffer), not timeout | CONTRADICTED by same reasoning | **RULED OUT** |

**The coordinator's own counter-counter-argument is the strongest evidence:** the phone had 22 seconds between sessions. If gearhead hasn't closed its AOAP session in 22 seconds with zero incoming host data, something is very wrong with gearhead's timeout handling. Android Auto's ping interval is typically 1-2 seconds with a 5-second timeout. By session 2, the phone's AA session is dead.

**Upgraded to LIKELY (was LIKELY, stays LIKELY) for session 2.** Downgraded to SUPPORTED for session 1 (the phone might still have been in the process of closing during the 3-second window).

### What would distinguish the scenarios definitively

The coordinator's proposed timeout/retry fix (Challenge 3) is exactly the right diagnostic:

- **If write succeeds after retry** → phone FD was open, endpoint was just stalled (need CLEAR_FEATURE)
- **If write succeeds after drain + delay** → phone FD was open, OUT buffer was full
- **If ALL writes timeout regardless of retries/clearing** → phone FD is closed, no consumer on phone side

---

## Challenge 3: Timeout/retry fix is worth testing

**AGREED.** The diagnostic value alone justifies it. Even if endpoint clearing doesn't fix the root cause, the log output from the first 5 frames tells us exactly what's happening:

[Code block omitted from public report; see authored source where available.]

This turns one black-box failure into a diagnostic trace. Cost: zero risk, ~30 lines of code. Should be implemented regardless of which solution path we pursue.

**Recommended additions to UsbBulkTransport.write():**
[Code block omitted from public report; see authored source where available.]

Also add to the constructor, after `claimInterface`:
[Code block omitted from public report; see authored source where available.]

---

## Challenge 4: Attacking the AOAP Mode Switch Plan

The coordinator proposes: disable Honda, add OnePlus VID to device_filter.xml, implement AOAP mode switch ourselves.

### Verified: Honda's AOAP strings are NOT Honda-specific [CONFIRMED]

From `UsbHostSetup.java` (line 12-21), Honda sends:
[Code block omitted from public report; see authored source where available.]

**These are Google's standard AA strings, not Honda-proprietary.** Every Android Auto head unit sends "Android" / "Android Auto" — the phone's gearhead app checks for these specific strings to decide whether to enter AOAP mode. Using them is safe and expected.

### Problem 1: Permission Chicken-and-Egg [CRITICAL]

To send controlTransfer (AOAP vendor requests 51-53), we need `UsbDeviceConnection`, which requires USB permission. For the non-AOAP device (OnePlus vid=0x22d9), our options are:

**Option A: UsbAttachActivity with vid=8921 (0x22d9) in device_filter.xml**
- Honda's USB matcher is a **BroadcastReceiver** (`StartReceiver`), not an Activity
- AOSP's `resolveActivity()` only queries Activities, not receivers
- If we're the sole Activity match → system launches `UsbConfirmActivity` (permission dialog)
- User taps OK → permission granted → we can send control transfers

**The dialog is NOT auto-grant.** From the test logs (line 12138), when our UsbAttachActivity matched the AOAP device, the system launched `com.android.systemui/.usb.UsbConfirmActivity` — a confirmation dialog, not a silent grant. Silent grant only happens when the app is already the stored default for that device.

**However**, the dialog is manageable. It's a simple "Allow access?" dialog. If the boot blocker suppresses the malicious detector, and Honda's ProjectionActivity isn't competing for focus, the user can tap OK.

### Problem 2: Race Against Honda [CRITICAL — but solvable with force-stop]

**Without force-stop: the race is UNWINNABLE.**

From the car-test-20261028-1145 logs, the AOAP device attach timeline:

| Elapsed (lines) | Event |
|------|-------|
| 12135 | System sends USB_DEVICE_ATTACHED broadcast |
| 12137 | Honda's BT receiver sees it |
| 12138 | System launches UsbConfirmActivity for our UsbAttachActivity |
| 12139 | **Honda's GalServiceReceiver fires** (same broadcast) |
| 12149 | Honda: `isAccessory() returned: true` |
| 12175 | Honda: starts projection activity |
| 12196 | Honda: `changeState DEVICE_ACCESORY` |
| 12197 | Honda's StartReceiver also fires |
| 12253 | **Our service first detects the device** (156ms later, via polling) |
| 12396-12399 | **Honda opens USB transport, claims interface** |

Honda's BroadcastReceiver fires INSTANTLY on the system broadcast. Honda doesn't need USB permission (runs as uid 1000 with MANAGE_USB). Honda opens the device, claims the interface, and starts its GAL session — all before our Activity even finishes launching.

For the non-AOAP device, the race is even worse: Honda calls `processDevice()` which sends the AOAP switch in the BroadcastReceiver callback. By the time `UsbConfirmActivity` displays and the user taps OK, the phone has already re-enumerated.

**With force-stop: NO RACE.** Honda's process is dead. The "stopped" flag on the package blocks delivery of implicit broadcasts (including `USB_DEVICE_ATTACHED`). We're the only actor on the bus. Timeline becomes:

1. Phone plugs in (MTP/ADB mode)
2. System sends USB_DEVICE_ATTACHED
3. Honda is stopped → doesn't receive it
4. Our UsbAttachActivity is the sole match
5. UsbConfirmActivity appears → user taps OK
6. We get permission for non-AOAP device
7. We send AOAP switch (requests 51-53)
8. Phone re-enumerates as AOAP
9. System sends another USB_DEVICE_ATTACHED
10. Our UsbAttachActivity matches again
11. UsbConfirmActivity appears → user taps OK (or auto-grants if stored default)
12. We start AA session on clean AOAP connection

**Two permission dialogs.** The user must tap OK twice: once for the non-AOAP device, once for the AOAP device. On the second connect, if the user checked "Use by default" on the first dialog for the AOAP device... actually no, they're different devices (different VID/PID), so the default doesn't carry over.

However: after the first successful run, the stored default for the AOAP device persists. On subsequent phone connections, only the non-AOAP dialog appears (the AOAP connect is auto-granted). Eventually, both could be defaults.

### Problem 3: Honda's ProjectionActivity Steals Focus [SIGNIFICANT]

From the logs (line 12188):
[Code block omitted from public report; see authored source where available.]

Honda launches its ProjectionActivity immediately after detecting the AOAP device. This full-screen activity **pushes UsbConfirmActivity to the background** (line 12272: `onPause: UsbConfirmActivity`, line 12354: `onResume: UsbConfirmActivity`). The user can't see or tap the permission dialog because Honda's activity is on top.

**With force-stop: this problem disappears.** Honda's activity doesn't launch.

**Without force-stop: our TYPE_SYSTEM_ERROR overlay draws over everything**, including Honda's ProjectionActivity. We could show a "tap OK" guide overlay. But the UsbConfirmActivity is behind Honda's activity, and our overlay is FLAG_NOT_TOUCHABLE — taps pass through to Honda's activity, not to UsbConfirmActivity.

### Problem 4: UsbConfirmActivity vs Lock Task Mode [UNKNOWN]

From the logs, `UsbConfirmActivity` DID launch successfully during the test. LTM didn't block it. The activity is launched by system_server (uid 1000), and SystemUI might be whitelisted. **This is a non-issue based on observed evidence.**

### Problem 5: What if force-stop DOESN'T work? [CONTINGENCY]

If `am force-stop` also throws SecurityException:

**Fallback A: Pre-claim race optimization.** Restructure our app to claim the AOAP interface as FAST as possible:

1. In `UsbAttachActivity.onCreate()`, immediately open the device and claim interface 0 (before handing off to any service). Store the UsbDeviceConnection in a static field.
2. AaSessionService retrieves the pre-claimed connection from the static field.
3. This cuts our claim time from ~26 seconds (permission + service hops) to ~0ms after permission grant.

The race is still tight, but if we ever get permission before Honda claims, we win. The problem is Honda doesn't need permission at all.

**Fallback B: Drain + delay + retry (diagnostic-first approach).**

Accept that Honda will always claim first. After we force-claim from Honda:
1. Clear endpoint halts on both endpoints
2. Drain all stale IN data (up to 5 seconds)
3. Wait 3 seconds for phone-side session to close
4. Send AOAP start request (53) to already-AOAP device (speculative — might trigger phone-side reopen)
5. Start protocol with retry-capable write

If the phone's gearhead reopens the AOAP FD after its session timeout (which it might do if it detects the USB is still connected), the delay would give it time to do so. This is speculative but low-risk.

**Fallback C: Trigger USB re-enumeration via SET_CONFIGURATION.**

[Code block omitted from public report; see authored source where available.]

This is speculative but has a reasonable mechanism: the `set_alt` callback in f_accessory sets the `online` flag and wakes up waiters. If gearhead has a thread waiting for the device to come online, this might trigger a new session.

---

## Revised Ranked Solutions

### Tier 1: Must test first

**A. Test `am force-stop` on Honda's package** (1 minute, zero risk)
[Code block omitted from public report; see authored source where available.]
If this works, the entire plan becomes viable.

### Tier 2: If force-stop works

**B. force-stop Honda + AOAP mode switch from our app**
1. `am force-stop` before phone plug-in
2. Add vid=8921 (OnePlus) to device_filter.xml
3. UsbHelperService detects non-AOAP phone
4. User taps OK on UsbConfirmActivity
5. We send AOAP switch with Google's standard strings
6. Phone re-enumerates as AOAP
7. User taps OK for AOAP device (or auto-granted if default)
8. Clean AA session, no Honda involvement

### Tier 3: Implement regardless (defense-in-depth + diagnostics)

**C. Enhanced UsbBulkTransport with halt clearing, drain, retry, logging**
- Clear endpoint halts after claimInterface
- Drain stale IN data
- Retry writes once after CLEAR_FEATURE
- Log everything: return values, timings, frame numbers

### Tier 4: If force-stop fails (fallback)

**D. Pre-claim race optimization**
- Claim interface in UsbAttachActivity.onCreate, before service handoff
- Cuts our reaction time to near-zero after permission grant

**E. SET_CONFIGURATION(0/1) cycle after force-claim**
- Speculative but mechanistically sound
- Might trigger f_accessory state reset on phone

**F. Post-claim delay (3-5s) then retry**
- Give phone time to close dead session and potentially reopen
- Combine with drain + clear halts

---

## Summary of Position Changes

| Point | Round 1 | Round 2 |
|-------|---------|---------|
| pm disable as Solution #1 | Recommended | **WITHDRAWN** — confirmed to fail with SecurityException |
| "Phone closed FD" confidence | LIKELY | **LIKELY for session 2** (22s is plenty for timeout), SUPPORTED for session 1 |
| NAK vs immediate failure | Not addressed | **CLARIFIED** — NAK produces timeout, not immediate failure; 995ms confirms NAK/timeout, rules out STALL |
| Timeout/retry fix value | "Won't fix root cause" | **AGREED** — invaluable diagnostic data regardless |
| AOAP mode switch from our app | Listed as Solution 2 | **Viable only with force-stop**; race is unwinnable otherwise because Honda has MANAGE_USB |
| Honda's AOAP strings | "Match Honda's strings" | **CONFIRMED** — they're Google's standard strings, not Honda-specific |
| force-stop as alternative | Listed as Solution 3 (simple) | **Promoted to critical path** — must test on-car; determines entire strategy |
