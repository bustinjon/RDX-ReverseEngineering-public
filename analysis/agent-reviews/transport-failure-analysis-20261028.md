# Transport Write Failure — Root Cause Analysis

**Date:** 2026-10-28
**Test:** car-test-20261028-1145 (Test 3)
**Phone:** OnePlus 13, serial 11111111
**Head Unit:** 2021 Acura RDX, Android 5.1.1 (API 22)

---

## 1. Root Cause Analysis

### Reconstructed Timeline (elapsedRealtime ms)

| Time | Event | Source |
|------|-------|--------|
| 1241953 | Phone connects as USB device (vid=22d9/OnePlus, pid=2769/ADB mode) | RDX.USB log |
| 1241997 | Phone detaches (Honda sent AOAP switch via vendor requests 51-53) | RDX.USB + GalService |
| 1242686 | Phone re-enumerates as AOAP (vid=18d1, pid=2d01) at /dev/bus/usb/003/003 | RDX.USB log |
| ~1242700 | Honda sees accessory, starts GAL session, establishes SSL transport | GalService: "isAccessory=true", "Started USB host connection" |
| ~1242700-1268000 | **Honda has an active AA session for ~25 seconds** (video streaming confirmed by "onGalVideoStarted" log) | GalService: "cancel mGalStartVideoTimer" |
| 1242842 | Our service detects AOAP device | RDX.USB log |
| 1243925-1260294 | Three permission attempts (first two denied — Honda UI blocks dialog) | RDX.USB log |
| 1268143 | Permission GRANTED on attempt 3 | RDX.USB log |
| 1268343 | Protocol stack init starts | RDX.SESSION log |
| 1268381 | GalReceiver + VideoSink + InputSource + VideoDecoder initialized | RDX.SESSION log |
| **1268397** | **`UsbBulkTransport` constructor: `claimInterface(iface, true)` — force-steals interface 0 from Honda** | RDX.SESSION: "USB transport opened" |
| 1268397 | Honda's `GAL_RECEIVER` (pid 9042): `IOException: read failed -1` — Honda's bulkTransfer reads fail instantly | AHU.GAL_RECEIVER log |
| 1268397 | Honda tries `resetDevice()` via reflection — `NoSuchMethodException` (hidden `@SystemApi`, absent from API 22 SDK) | AHU.USB_HOST_CONNECTION log |
| 1268397 | Honda's writer/reader threads shut down. Honda logs: "read returned 0 while expecting 4" | AHU.GAL_RECEIVER log |
| 1268407 | Our reader/writer/ping threads start | RDX.SESSION log |
| **~1268407-1271490** | **3.08 seconds pass** — writer blocks in `nativeGetEncodedFrame()` | Inferred: no "write ended" until 1271490 |
| **1271490** | **`bulkTransfer(out, ...)` returns <= 0 — WRITE FAILS** | RDX.SESSION: "Transport write ended: USB write failed" |
| 1271493 | Session shutdown | RDX.SESSION log |

**Second session (auto-grant via UsbAttachActivity — same USB device, no re-enumeration):**

| Time | Event |
|------|-------|
| 1289587 | Transport opened + threads started |
| **1290582** | **WRITE FAILS (0.995s after open)** |

### The Failure Mechanism [SUPPORTED]

**The phone's AOAP gadget (f_accessory kernel driver) is in a dead-session state where no process on the phone side is servicing USB bulk transfers.**

Step-by-step:

1. **Honda had an active AA session for ~25 seconds.** Honda's `GalService` successfully negotiated AOAP, established SSL transport, completed the GAL handshake, started video, and was actively streaming. The phone's Android Auto app (`com.google.android.projection.gearhead`) was running an encrypted GAL session over the AOAP USB interface.

2. **We force-claim the interface.** `claimInterface(iface, true)` at the Linux kernel level reassigns interface 0 to our file descriptor. Honda's file descriptor immediately becomes invalid — every subsequent `bulkTransfer` from Honda returns -1.

3. **Honda's reader/writer threads die.** Honda logs `read failed -1` and tries `resetDevice()` (which fails on API 22). Honda's AA session terminates uncleanly. Honda cannot reset the USB device or signal the phone.

4. **The phone doesn't know the host-side session changed.** From the phone's perspective, the USB cable is still connected and the AOAP configuration is still active. But the host-side entity changed from Honda to us. The phone's gearhead app is still trying to send encrypted video frames and read from the USB.

5. **The phone detects the dead session within ~1-3 seconds.** The phone's write attempts fail (host isn't reading what it sends — we haven't consumed the phone's queued data fast enough, or the phone's writes timeout). Gearhead closes the AOAP file descriptor (`/dev/usb-accessory`). The `f_accessory` kernel driver sets its `disconnected` flag but does NOT tear down the USB configuration — the cable is still connected.

6. **Our writer produces its first frame after ~3 seconds.** The native library (`nativeGetEncodedFrame`) blocks for ~2 seconds waiting for the GAL handshake to progress. The reader thread IS reading data — but it's stale encrypted video frames from the Honda session, which the native library cannot interpret as valid GAL handshake messages. Eventually the native library produces a frame (version request or initial handshake).

7. **The bulk OUT write times out.** With no process on the phone reading from `/dev/usb-accessory`, the USB gadget's OUT endpoint has no consumer. The host's bulk OUT transfer sits in the USB host controller's queue. After the 1000ms timeout, `bulkTransfer` returns -1.

8. **Session 2 fails faster** because the native library, already initialized, produces its first frame almost immediately. The write times out at exactly the 1000ms timeout (`1290582 - 1289587 = 995ms`).

### Why the Phone Won't Start a New Session [CONFIRMED]

The AOAP session lifecycle is tied to USB enumeration. The phone enters AOAP mode when the head unit sends vendor control requests 51-53 and the phone re-enumerates with Google's VID/PID. A new session starts when:
- The phone re-enumerates (USB disconnect + reconnect), OR
- The gearhead app reopens `/dev/usb-accessory` (unlikely without a USB event trigger)

Since the USB cable never disconnected, the phone remains in AOAP mode with the stale USB configuration. No re-enumeration occurs. No new session starts.

### Confidence Assessment

| Finding | Confidence |
|---------|-----------|
| Honda had an active AA session when we claimed the interface | **CONFIRMED** — logs show "onGalVideoStarted", "transport connected", 25s of active session |
| Force-claim caused Honda's read failure | **CONFIRMED** — Honda's IOException at exact timestamp of our claimInterface |
| `resetDevice()` is unavailable on API 22 | **CONFIRMED** — hidden `@SystemApi` method, Honda's NoSuchMethodException in logs |
| Phone's gearhead closed its AOAP session after Honda died | **LIKELY** — consistent with 3s delay (detection + close) and session 2 timing (immediate timeout) |
| Bulk OUT write failure is a timeout (no consumer on phone side) | **SUPPORTED** — session 2 duration = 995ms matches 1000ms timeout exactly; session 1 delay consistent with native library blocking + timeout |
| Phone won't start new AOAP session without re-enumeration | **SUPPORTED** — AOAP spec ties session to enumeration; no evidence of re-connection in logs |
| Stale encrypted data from Honda session fed to our native library | **LIKELY** — reader thread had no errors (no read timeout logged), suggesting it was reading something |

---

## 2. Ranked Solutions

### Solution 1: Disable Honda's AA Components Before Phone Plug-In [RECOMMENDED]

**Mechanism:** Prevent Honda from ever starting a session. If Honda never claims the interface or initiates AOAP mode switching, the phone's first AA session is with us.

**Implementation:**
[Code block omitted from public report; see authored source where available.]

**Important caveat:** Honda's `GalService` also performs the AOAP mode switch (vendor requests 51-53) that puts the phone into accessory mode. With Honda disabled, **we must implement AOAP mode switching ourselves**, or the phone will never enter AOAP mode (it will stay in MTP/ADB mode with OnePlus VID/PID).

**Risk:** Low if we implement AOAP switching. The `pm disable` command requires `CHANGE_COMPONENT_ENABLED_STATE` permission, which shell (uid 2000) has. Persists across reboots, reversible.

**Requires ADB:** Yes, for the `pm disable` commands. Can be done from our APK only if we have shell-level permissions.

**Confidence:** HIGH — eliminates the root cause entirely.

### Solution 2: Implement AOAP Mode Switching in Our App [REQUIRED for Solution 1]

**Mechanism:** When the phone connects in MTP/ADB mode (vid=22d9), our app detects it and sends the AOAP vendor control requests (51-53) to switch the phone to accessory mode. This is what Honda does in `processDevice()`.

**Implementation (from our APK, needs USB permission for the MTP device):**
[Code block omitted from public report; see authored source where available.]

**Risk:** Medium. The manufacturer/model strings must match what the phone's Android Auto expects from a head unit. If Google's AA validates these strings, mismatches could prevent AOAP mode entry. Honda uses specific strings we'd need to reverse-engineer from their `processDevice()` code.

**Requires ADB:** No — runs from our APK. But needs USB permission for the pre-AOAP device (vid=22d9), which requires either a device_filter.xml match or `requestPermission()`.

**Confidence:** HIGH that the mechanism works (it's the standard AOAP protocol). MEDIUM confidence that gearhead accepts arbitrary manufacturer/model strings.

### Solution 3: Force-Stop Honda Before Phone Plug-In [SIMPLE ALTERNATIVE]

**Mechanism:** Kill Honda's process entirely so it can't respond to USB events.

**Implementation:**
[Code block omitted from public report; see authored source where available.]

**Caveat:** This kills the process but doesn't disable the broadcast receiver or service components. If a `USB_DEVICE_ATTACHED` broadcast fires, Android may restart the service. The `force-stop` sets a "stopped" flag that blocks broadcast delivery until the user explicitly launches the app, but a matching USB device_filter intent-filter may override this for USB events. **Needs testing.**

The `pm disable` approach (Solution 1) is more reliable because it prevents the component from being launched at all.

**Risk:** Low. Reversible (process restarts on next USB event or boot).

**Requires ADB:** Yes.

**Confidence:** MEDIUM — may not fully prevent Honda from restarting.

### Solution 4: Clear Endpoint Halts + Drain Stale Data Before Protocol Start [DEFENSIVE]

**Mechanism:** After force-claiming the interface but before starting the GAL protocol, clear any USB endpoint HALT conditions and drain all stale data from the IN endpoint. This addresses the USB-level symptom even if the root cause (phone-side session closure) is the real problem.

**Implementation:**
[Code block omitted from public report; see authored source where available.]

**Risk:** Low — this is purely defensive USB housekeeping. CLEAR_FEATURE is a standard USB request supported since USB 1.0. `controlTransfer()` has been in Android since API 12.

**Limitation:** This likely WON'T fix the underlying problem. If the phone-side gearhead has closed its AOAP file descriptor, clearing endpoint halts and draining data won't create a new reader/writer on the phone. The OUT writes will still timeout because nobody is consuming them. **However, this should be implemented regardless as defense-in-depth.**

**Requires ADB:** No — runs from our APK.

**Confidence:** LOW for fixing the root cause. HIGH for being correct USB housekeeping.

### Solution 5: USB Reset via Close/Reopen Cycle with Delay [SPECULATIVE]

**Mechanism:** After force-claiming the interface, close the `UsbDeviceConnection`, wait several seconds for the phone-side to stabilize, then reopen. The close/reopen cycle might trigger the host controller to signal the phone, potentially causing the phone's gearhead to re-initialize.

**Implementation:**
[Code block omitted from public report; see authored source where available.]

**Risk:** Low — worst case, the phone still doesn't re-initialize and we're back to the same failure.

**Limitation:** `close()` + `openDevice()` at the Android API level may not cause any USB bus event visible to the phone. The kernel may keep the USB configuration active.

**Requires ADB:** No.

**Confidence:** LOW — the phone probably won't see this as a USB disconnect.

### Solution 6: Trigger USB Re-Enumeration via SET_CONFIGURATION(0) [SPECULATIVE]

**Mechanism:** Send a USB standard request to set the device configuration to 0 (unconfigured), then back to 1. This forces the phone's gadget driver to go through `set_alt` / `config` callbacks, potentially resetting the AOAP session state.

**Implementation:**
[Code block omitted from public report; see authored source where available.]

**Risk:** Medium — could confuse the USB host controller or cause the phone to drop off the bus entirely. The phone's USB controller may not support SET_CONFIGURATION while the bus is active.

**Requires ADB:** No.

**Confidence:** SPECULATIVE — might work based on USB spec, but untested. The phone's UDC (USB device controller) may not honor SET_CONFIGURATION from the host after initial enumeration.

### Solution 7: Send AOAP Start Request (53) to Already-AOAP Device [SPECULATIVE]

**Mechanism:** Even though the phone is already in AOAP mode, sending vendor request 53 (start accessory mode) might trigger a re-enumeration. If the phone drops off the bus and re-enumerates, we get a fresh AOAP session.

**Implementation:**
[Code block omitted from public report; see authored source where available.]

**Risk:** Medium. The phone's `f_accessory` driver may ignore vendor requests in AOAP mode (they're typically handled by the `f_accessory` driver only in the pre-accessory configuration). Or it might cause unexpected behavior.

**Requires ADB:** No.

**Confidence:** LOW — vendor requests 51-53 are documented for the pre-AOAP state only.

---

## 3. Questions, Challenges, and Answers

### Can we clear USB endpoint halts via controlTransfer() on API 22?

**YES [CONFIRMED].** `UsbDeviceConnection.controlTransfer()` has been available since API 12. The call is:
[Code block omitted from public report; see authored source where available.]
This sends a standard USB CLEAR_FEATURE(ENDPOINT_HALT) request. The requestType `0x02` means host-to-device, standard type, endpoint recipient.

**However:** This clears a USB-level STALL/HALT, not the phone-side application state. If the phone's AOAP file descriptor is closed, the endpoints aren't halted — they're just not being serviced. Clearing halts won't create a new reader on the phone side.

### Can we drain stale data from the IN endpoint before starting protocol?

**YES [CONFIRMED].** Call `bulkTransfer(in, buffer, size, shortTimeout)` in a loop until it returns <= 0. This will consume any data the phone queued before its session ended.

**However:** The stale data is encrypted (Honda's SSL session). It can't be interpreted by our native library. Draining it prevents the native library from being confused by garbage input, but doesn't fix the write-side problem.

### Would a brief delay after claiming let the phone's AOAP stack reset?

**UNLIKELY [SUPPORTED].** The phone's gearhead app will detect the dead session and close its AOAP file descriptor, but it won't automatically reopen it. AOAP session creation is tied to USB enumeration events, not timers. Without a USB disconnect/reconnect, no new session starts.

A longer delay (e.g., 30 seconds) might let gearhead fully clean up, but there's no evidence it would re-open the AOAP session. The `f_accessory` driver's `disconnected` flag stays set until the file is re-opened, and the `online` flag stays set until USB is actually disconnected.

### Can we trigger USB port reset via UsbDeviceConnection or UsbRequest?

**NO [CONFIRMED].** `UsbDeviceConnection.resetDevice()` exists in AOSP source but is annotated `@hide` and `@SystemApi`. It requires a privileged system app. Honda tried to call it via reflection and got `NoSuchMethodException` — the method isn't even present in the API 22 runtime. There is no public API for USB device reset on any Android version up to at least API 30.

The Android USB Port Reset API (for HAL-level resets) requires Android 13+ and a system-privileged app with USB HAL v2.0.

### Is the phone sending bye-bye data to the old Honda session that we need to consume?

**LIKELY [SUPPORTED].** The phone may send a GAL bye-bye message when it detects the dead session. This bye-bye would be encrypted in Honda's SSL context. We can't decrypt it, but we should drain it to keep the USB buffers clean.

More importantly, the phone was actively streaming video to Honda. There may be several kilobytes of video frame data in the USB gadget's IN buffers. Draining this data prevents our reader from feeding it to the native library as a "handshake response."

### Is force-stop of Honda via ADB before phone plug-in the simplest path?

**YES, with caveats [SUPPORTED].** `am force-stop` kills the process and sets the "stopped" flag. However:
- Honda's `StartReceiver` has a USB device filter in its manifest. The AOSP `UsbSettingsManager` may still launch it for USB events even in the stopped state.
- `pm disable` on the specific receiver/service components is more reliable than `force-stop`.
- **Critical:** With Honda disabled, nobody performs the AOAP mode switch. We must implement it ourselves (Solution 2) or use a separate ADB script to send the vendor control requests.

### Could we implement AOAP mode switch ourselves and bypass Honda entirely?

**YES [CONFIRMED].** The AOAP mode switch is a documented protocol:
1. Vendor request 51 (Get Protocol) — check AOAP support
2. Vendor request 52 (Send String) — send manufacturer, model, etc.
3. Vendor request 53 (Start Accessory) — phone re-enumerates

This requires USB permission for the **pre-AOAP** device (vid=22d9 OnePlus, not vid=18d1 Google). Our `device_filter.xml` currently only matches AOAP PIDs (0x2d00/0x2d01). We'd need to:
- Add a filter for the phone's normal VID/PID, OR
- Use `requestPermission()` for the non-AOAP device

**Challenge:** The identifying strings (manufacturer/model) sent during the mode switch might matter. Honda sends specific strings. If gearhead validates them against a known-head-unit list, arbitrary strings might be rejected. We should match Honda's strings (discoverable from Honda's smali or from USB packet capture).

---

## 4. Recommended Action Plan

### Phase 1: Eliminate the Race (ADB prep, before phone plug-in)
[Code block omitted from public report; see authored source where available.]

### Phase 2: Add AOAP Mode Switching to Our App
Since Honda won't do the AOAP switch, our `UsbHelperService` must:
1. Detect the phone in MTP/ADB mode (vid=22d9 or other vendor VIDs)
2. Request USB permission for it
3. Send AOAP vendor requests 51-53
4. Wait for re-enumeration (USB_DEVICE_DETACHED + USB_DEVICE_ATTACHED with vid=18d1)
5. Proceed with existing AOAP session flow

**Alternatively:** Use an ADB script to perform the mode switch:
[Code block omitted from public report; see authored source where available.]

### Phase 3: Defensive USB Housekeeping (add to UsbBulkTransport)
Regardless of the approach, add to the constructor after `claimInterface`:
- Clear endpoint halts on both IN and OUT
- Drain stale IN data (timeout after 2 seconds of silence)
- Brief 500ms pause before protocol start

### Phase 4: Add Write Retry with Halt Recovery
In `UsbBulkTransport.write()`, instead of immediately throwing on `n <= 0`:
[Code block omitted from public report; see authored source where available.]

---

## 5. Summary

**The root cause is not a USB-level stall or protocol error. It's a session lifecycle problem.** Honda establishes an AOAP session with the phone. We force-claim the USB interface, killing Honda's session. The phone detects the dead session and closes its AOAP file descriptor. With no reader/writer on the phone side, our bulk OUT writes timeout. The phone won't start a new session without a USB re-enumeration, and re-enumeration won't happen because the cable is still connected.

**The fix is to prevent Honda from ever starting a session**, by disabling its components before the phone is plugged in, and implementing the AOAP mode switch ourselves. This eliminates the fundamental problem: there's never a stale session to fight.

**Secondary improvements** (endpoint halt clearing, stale data draining, write retry) should be added as defense-in-depth but alone won't fix the root cause.
