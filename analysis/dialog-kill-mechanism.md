# Dialog Kill Mechanism — Root Cause Analysis

**Status: SUPPORTED** (mechanism confirmed in code; exact trigger UNKNOWN)
**Date: 2026-10-28, revised after Codex adversarial review**

## Root Cause

`UsbPermissionActivity` is killed by `AMS.closeSystemDialogsLocked()` via the `finishOnCloseSystemDialogs` flag. The exact component that triggers the kill during Honda AA startup is **unknown**.

**What IS confirmed:**

1. `UsbPermissionActivity` declares `android:finishOnCloseSystemDialogs="true"` in `SystemUI/AndroidManifest.xml` (line 205)
2. `ActivityStack.closeSystemDialogsLocked()` (line 2437) checks flag 256 and calls `finishActivityLocked` on matching activities
3. `AMS.closeSystemDialogs()` Binder RPC (line 3991) triggers the kill chain

**What is NOT the trigger (Codex-verified REFUTATION):**

HMIPresenter's `sendBroadcastAsUser(CLOSE_SYSTEM_DIALOGS)` does NOT kill activities. Honda removed the standard AOSP handling from `broadcastIntentLocked` — the action switch at AMS:12645-12762 has no CLOSE_SYSTEM_DIALOGS case. The broadcast only reaches registered receivers (HondaStatusBar etc.). The activity-killing path is a **separate Binder RPC** (AMS:3991), not reachable via broadcast.

## Kill Chain (revised)

1. Phone plugs in → Honda AA detects USB → `UsbPermissionActivity` displays our permission dialog
2. **UNKNOWN trigger** calls `AMS.closeSystemDialogs()` Binder RPC (line 3991)
3. `AMS.closeSystemDialogsLocked()` (line 4018) executes three steps synchronously then one async:
   a. `mWindowManager.closeSystemDialogs(reason)` — dispatches to windows (sync)
   b. `mStackSupervisor.closeSystemDialogsLocked()` — kills flagged activities (sync)
   c. `broadcastIntentLocked(...)` — enqueues notification broadcast (delivered later)
4. `ActivityStack.closeSystemDialogsLocked()` (line 2437-2446) finishes UsbPermissionActivity
5. The notification broadcast is delivered asynchronously — HondaStatusBar logs it much later

**Known Binder RPC callers** (PhoneWindowManager:4961-4964):
- `sendCloseSystemWindows("homekey")` — HOME key press
- `sendCloseSystemWindows("globalactions")` — power/global actions
- `sendCloseSystemWindows("assist")` — assist action
- `sendCloseSystemWindows()` — startDockOrHome (null reason)

**HMIPresenter's role (CORRECTED):**
HMIPresenter sends `sendBroadcastAsUser(CLOSE_SYSTEM_DIALOGS)` from 8 callsites (line 842-843). This broadcast goes through `broadcastIntentLocked` which has NO special handling for the action. It only reaches registered BroadcastReceivers (like HondaStatusBar, which collapses panels). It does NOT trigger `closeSystemDialogsLocked` and does NOT kill activities.

## Evidence

### Manifest (CONFIRMED)
`decompiled/SystemUI/resources/AndroidManifest.xml:201-205`:
[Code block omitted from public report; see authored source where available.]
ALL 7 USB/system dialog activities in SystemUI have this flag — not just UsbDebuggingActivity.

### AMS Binder RPC vs Broadcast (CONFIRMED — two separate paths)
**Path A — Binder RPC (kills activities):**
`AMS.closeSystemDialogs()` (line 3991) → `closeSystemDialogsLocked()` (line 4018) → `mStackSupervisor.closeSystemDialogsLocked()` → finishes flagged activities, then enqueues notification broadcast.

**Path B — Broadcast (does NOT kill activities):**
`sendBroadcast(CLOSE_SYSTEM_DIALOGS)` → `AMS.broadcastIntentLocked()` → delivers to registered receivers only. The action switch at AMS:12645-12762 handles PACKAGE_REMOVED, TIMEZONE_CHANGED, etc. but has **NO CLOSE_SYSTEM_DIALOGS case** (Codex-verified).

Honda removed the standard AOSP bridge between these paths. In stock AOSP 5.1, `broadcastIntentLocked` has a `CLOSE_SYSTEM_DIALOGS` case that calls `closeSystemDialogsLocked`. Honda's build does not.

### HMIPresenter (CONFIRMED as red herring for activity kill)
`decompiled/AndroidAuto-current/.../HMIPresenter.java:842-843`:
[Code block omitted from public report; see authored source where available.]
Called from 8 methods (360, 428, 478, 484, 533, 564, 620, 307) — but this takes Path B (broadcast only). It collapses HondaStatusBar panels and notifies receivers. It does NOT finish activities.

### ActivityStack (CONFIRMED)
`decompiled/Services/.../ActivityStack.java:2437-2446`:
[Code block omitted from public report; see authored source where available.]

### Log Correlation (SUPPORTING — consistent but not conclusive)
`analysis/logs/car-test-20261028-1130.txt`:
- Dialog displayed: line 3330 → dialog killed: line 3904 (574 lines, ~7.1 seconds)
- ZERO `CLOSE_SYSTEM_DIALOGS` broadcasts between display and kill — expected because AMS enqueues the notification broadcast AFTER the synchronous activity kill (AMS:4024-4026)
- UsbConfirmActivity (same task) briefly resumes (3906) then destroyed (4194) — consistent with `closeSystemDialogsLocked` finishing all flagged activities
- `HondaStatusBar` logs `CLOSE_SYSTEM_DIALOGS` at line 6135 with flags `0x50000010` — matches AMS's construction (line 4019-4020: `addFlags(1342177280)` = 0x50000000, plus default 0x10). HMI's bare intent would produce 0x00000010. This confirms the broadcast came through the Binder RPC path, not HMI's broadcast.
- The "(has extras)" on line 6135 means a reason string was passed (AMS:4021-4022 adds reason as extra). PhoneWindowManager passes "homekey", "globalactions", "assist", or null.

## Why Timing Varies (2.8-8.7s)

The exact trigger for `closeSystemDialogs` is unknown. Possible sources:
- PhoneWindowManager HOME key simulation during Honda UI transitions
- Framework-internal calls during activity stack changes
- Timing depends on Honda AA protocol negotiation and UI transition sequence

Codex found an 8.668-second interval in the data, exceeding the originally proposed 7.1s upper bound.

## Analysis Corrections

1. **Earlier error**: "finishOnCloseSystemDialogs only set on UsbDebuggingActivity, NOT UsbPermissionActivity" — **wrong**. Manifest shows ALL 7 USB/system dialog activities have the flag.

2. **This revision (Codex adversarial review)**: The original analysis claimed HMIPresenter's broadcast triggered the kill chain. **Refuted.** Honda's `broadcastIntentLocked` has no CLOSE_SYSTEM_DIALOGS handling. The kill comes through the separate Binder RPC path. See `analysis/agent-reviews/codex-dialog-kill-review-20261028.md` for full review.

## Impact on Our Strategy

### Force-stop neutralizes the kill chain (SUPPORTED)

The `USB_DEVICE_ATTACHED` broadcast at `UsbSettingsManager.deviceAttached` (line 607-614) does NOT set `FLAG_INCLUDE_STOPPED_PACKAGES`. Android automatically adds `FLAG_EXCLUDE_STOPPED_PACKAGES` — so **force-stopped Honda AA won't receive the broadcast**.

Verified: Honda AA is NOT `android:persistent` (not in manifest). `StateMachineService.EXCLUDED_APPS_PREFIXES` includes Honda AA (line 48) — it's excluded from cleanup but also NOT actively restarted. No other system service references Honda AA.

**Result: force-stop → Honda AA stays dead → no startup → whatever normally triggers `closeSystemDialogs` doesn't fire → dialog lives indefinitely.**

Even though the exact trigger is unknown, force-stop eliminates Honda AA from the equation entirely. If the trigger is within Honda AA's process (HMI transitions, activity launches), it can't fire. If it's a framework response to Honda AA's activity transitions, those transitions don't happen.

The script runs `am force-stop com.honda.androidauto.projection.sink` before phone connection (Step 8).

### Without force-stop: A11Y must win the race

Dialog display to kill: 2.8-8.7 seconds. Our first click attempt fires ~100-200ms after dialog start (A11Y event at onResume + tree traversal). 15 retries × 150ms = 2.25s backup window.

The keyevent fallback (DPAD_RIGHT + ENTER) must also beat this race.
