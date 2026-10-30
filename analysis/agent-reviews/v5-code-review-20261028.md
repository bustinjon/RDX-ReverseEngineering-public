# UsbHelperService v5 + UsbBulkTransport — Adversarial Code Review
**Date:** 2026-10-28  
**Reviewer:** Claude (adversarial review, correctness focus)  
**Files:** `UsbHelperService.java` (v5), `UsbBulkTransport.java`

---

## CRITICAL-1: `switchToAoap()` failure permanently blocks non-AOAP detection

**File:** `UsbHelperService.java` — lines 127-129, 227-230, 371-374 (all three call sites)  
**Severity:** CRITICAL

All three callers of `switchToAoap()` unconditionally set `aoapSwitchSent = true` afterward, regardless of whether the switch actually succeeded:

[Code block omitted from public report; see authored source where available.]

`switchToAoap()` can fail silently in multiple ways:
- `openDevice()` returns null (line 427) — returns early, no exception
- `GET_PROTOCOL` fails (line 434) — returns early
- `SEND_STRING` fails (line 453-454) — returns early
- `START_ACCESSORY` fails (line 458) — logged but not acted on; falls through to "AOAP switch complete" log

Once `aoapSwitchSent = true`, the non-AOAP detection in `tick()` is permanently blocked (line 175: `!aoapSwitchSent`), and the phone never enters AOAP mode (since the switch failed), so `isAllowedPhone()` never matches either. The service polls indefinitely doing nothing.

**Failure scenario:** Phone's USB stack is slow to respond. `openDevice()` returns null because the system hasn't finished enumerating. `aoapSwitchSent = true`. The phone is stuck in non-AOAP mode. No recovery. The only fix is replug or service restart.

**Suggested fix:** `switchToAoap()` should return `boolean`. Callers should only set `aoapSwitchSent = true` on success. Also add a timeout: if `aoapSwitchSent` is true and no AOAP device appears within ~10 seconds, reset `aoapSwitchSent` and retry.

[Code block omitted from public report; see authored source where available.]

---

## CRITICAL-2: `START_ACCESSORY` return value not checked

**File:** `UsbHelperService.java` — line 458  
**Severity:** CRITICAL (subsumes into CRITICAL-1 but distinct root cause)

[Code block omitted from public report; see authored source where available.]

If `START_ACCESSORY` returns `-1` (failure), the code logs "AOAP switch complete" anyway. Combined with CRITICAL-1, this means a failed mode switch is reported as success and blocks all retries. `GET_PROTOCOL` and `SEND_STRING` failures are properly checked (lines 434, 453), but the final critical step is not.

**Suggested fix:** Check `r < 0` after START_ACCESSORY and return early (or return false per the CRITICAL-1 fix).

---

## MAJOR-1: `tryForceStopHonda()` blocks main thread with no timeout

**File:** `UsbHelperService.java` — lines 403-416  
**Severity:** MAJOR

[Code block omitted from public report; see authored source where available.]

This runs in `onCreate()` on the main thread. `Process.waitFor(long, TimeUnit)` does not exist on API 22 (added in API 26). If `am` hangs for any reason (system under load, binder congestion), the main thread blocks indefinitely. Android enforces a ~20s ANR timeout for service creation; exceeding it kills the process.

Secondary issue: stdout/stderr are not drained. While `am force-stop` produces minimal output, the pipe buffer could theoretically fill if error messages are generated, creating a deadlock between `waitFor()` and the blocked child process write.

**Suggested fix:** Run the command on a background thread, or implement a manual timeout:

[Code block omitted from public report; see authored source where available.]

---

## MAJOR-2: REQUESTING phase has no timeout — can get permanently stuck

**File:** `UsbHelperService.java` — lines 285-306, 157-241  
**Severity:** MAJOR

When `doRequest()` is called, `phase` is set to `REQUESTING` (line 286). The only exit from REQUESTING is the `resultReceiver` callback. If the callback never fires, the service is stuck:

- `tick()` does nothing useful during REQUESTING (lines 200, 211 only handle WAITING and STABILIZING)
- `pollRunnable` keeps running but `tick()` just falls through
- `attempts` is not incremented (only incremented in STABILIZING, line 234)
- Cannot reach `MAX_RETRIES` to trigger failure recovery

**When can the callback fail to fire?** On Android 5.1.1, if the USB device detaches while the permission dialog is showing, the system may auto-dismiss the dialog without delivering the PendingIntent. The `PendingIntent.FLAG_ONE_SHOT` means it can only fire once — if the dialog is dismissed without user action, the intent may never be sent.

The code logs "Device disconnected while permission request pending" (line 194) but does not change phase:

[Code block omitted from public report; see authored source where available.]

**Suggested fix:** Add a timeout for REQUESTING phase. Either track when REQUESTING started and check in `tick()`, or use `handler.postDelayed()`:

[Code block omitted from public report; see authored source where available.]

Also, the `target == null` + `phase == REQUESTING` path should reset to WAITING:
[Code block omitted from public report; see authored source where available.]

---

## MAJOR-3: No timeout waiting for AOAP re-enumeration

**File:** `UsbHelperService.java` — after `switchToAoap()` calls  
**Severity:** MAJOR

After a successful AOAP switch, the phone should re-enumerate within 1-3 seconds as VID 0x18d1, PID 0x2d00/0x2d01. But there is no timeout for this. If the phone fails to re-enumerate (USB glitch, phone crash, cable issue), the service polls indefinitely in WAITING phase:

- `aoapSwitchSent = true` blocks the non-AOAP path
- No AOAP device ever appears
- `pollRunnable` runs every 500ms forever, burning CPU

**Suggested fix:** Track when the AOAP switch was sent. If no AOAP device appears within ~15s, reset `aoapSwitchSent` and log a diagnostic:

[Code block omitted from public report; see authored source where available.]

---

## MAJOR-4: `onStartCommand(AUTO_GRANTED)` does not check current phase

**File:** `UsbHelperService.java` — lines 114-138  
**Severity:** MAJOR

The `AUTO_GRANTED` handler does not check `phase` before acting. If `phase == GRANTED` (session already running), a late `AUTO_GRANTED` from `UsbAttachActivity` (e.g., phone briefly disconnects and reconnects) calls `startAaSession()` a second time.

`AaSessionService` has a `protocolInitialized` guard, so the second call is a no-op during an active session. **However**, if the first session has already shut down and `AaSessionService` was destroyed, the second `startAaSession()` call could reinitialize with a stale `UsbDevice` object from the intent extra — a device that may have been physically detached and reattached at a different bus path.

[Code block omitted from public report; see authored source where available.]

**Suggested fix:** Add a phase guard at the top of the `AUTO_GRANTED` handler:

[Code block omitted from public report; see authored source where available.]

---

## MAJOR-5: `onStartCommand(AUTO_GRANTED)` bypasses `forceStopSucceeded` guard

**File:** `UsbHelperService.java` — lines 122-129  
**Severity:** MAJOR

The `tick()` path correctly requires `forceStopSucceeded` before attempting AOAP switch on a non-AOAP phone (line 175):

[Code block omitted from public report; see authored source where available.]

But the `AUTO_GRANTED` path does not check this:

[Code block omitted from public report; see authored source where available.]

If Honda's `am force-stop` failed (insufficient permissions on this head unit), Honda's AA is still running. The `AUTO_GRANTED` path would try to switch the phone to AOAP mode anyway. When the phone re-enumerates as AOAP, Honda's AA (still running) races to claim it.

**Suggested fix:** Check `forceStopSucceeded` before calling `switchToAoap()` in the `AUTO_GRANTED` path, or at least log a prominent warning.

---

## MINOR-1: Signed-byte arithmetic in `checkAoapAlive()`

**File:** `UsbBulkTransport.java` — line 67  
**Severity:** MINOR

[Code block omitted from public report; see authored source where available.]

Compare with the correct version in `UsbHelperService.switchToAoap()` line 438:

[Code block omitted from public report; see authored source where available.]

`buf[0]` and `buf[1]` are Java signed bytes. If either byte has bit 7 set (value > 127), the arithmetic produces a wrong result. For AOAP protocol versions 1-2 this never triggers, but it's a latent bug and inconsistent with the other call site.

**Suggested fix:** Apply `& 0xFF` masking:
[Code block omitted from public report; see authored source where available.]

---

## MINOR-2: `isNonAoapPhone()` hardcoded to OnePlus VID only

**File:** `UsbHelperService.java` — line 418-419  
**Severity:** MINOR

[Code block omitted from public report; see authored source where available.]

Any non-OnePlus phone in non-AOAP mode (Samsung 0x04e8, Google 0x18d1 non-AOAP PIDs, Xiaomi 0x2717, etc.) is invisible to both the `AUTO_GRANTED` and `tick()` detection paths. The service logs "unknown device — ignoring" and does nothing.

This is likely intentional for the current test setup, but should be documented or expanded if other phones will be used.

**Suggested fix:** Add a comment documenting this is intentional, or expand to a VID list/table.

---

## MINOR-3: CLEAR_HALT log message off-by-one

**File:** `UsbBulkTransport.java` — line 120  
**Severity:** MINOR

[Code block omitted from public report; see authored source where available.]

After the 10th failure (`retries` = 10), the inner loop exits. The last CLEAR_HALT log says "before retry 11" — but retry 11 never happens (max is 10). Misleading but not harmful.

**Suggested fix:** Change to "after attempt " + retries:
[Code block omitted from public report; see authored source where available.]

---

## Summary

| # | Severity | One-liner |
|---|----------|-----------|
| C-1 | CRITICAL | `aoapSwitchSent` set unconditionally — failed AOAP switch permanently blocks detection |
| C-2 | CRITICAL | `START_ACCESSORY` return value not checked — logs "complete" on failure |
| M-1 | MAJOR | `tryForceStopHonda()` blocks main thread with no timeout (ANR risk) |
| M-2 | MAJOR | REQUESTING phase has no timeout — lost permission callback = permanent stuck |
| M-3 | MAJOR | No timeout for AOAP re-enumeration — polls forever if phone doesn't reappear |
| M-4 | MAJOR | `AUTO_GRANTED` handler ignores current phase — duplicate session start |
| M-5 | MAJOR | `AUTO_GRANTED` bypasses `forceStopSucceeded` guard for non-AOAP path |
| m-1 | MINOR | Signed-byte arithmetic in `checkAoapAlive()` (inconsistent with switchToAoap) |
| m-2 | MINOR | `isNonAoapPhone()` only matches OnePlus VID |
| m-3 | MINOR | CLEAR_HALT log prints retry N+1 on last attempt |

### Priority order for fixes
1. **C-1 + C-2** (same area): Make `switchToAoap()` return boolean, check START_ACCESSORY, only set `aoapSwitchSent` on success
2. **M-2**: Add timeout for REQUESTING phase + reset on device disconnect
3. **M-3**: Add AOAP re-enumeration timeout with `aoapSwitchSent` reset
4. **M-1**: Move `tryForceStopHonda()` off the main thread or add a manual timeout
5. **M-4 + M-5**: Add phase guard and `forceStopSucceeded` check to `AUTO_GRANTED` handler
