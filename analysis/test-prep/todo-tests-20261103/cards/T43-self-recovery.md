# T43 — Self-recovery without replugging

**Type:** Build  
**Run with:** Start-T43-self-recovery.cmd / Collect-T43-self-recovery.cmd  
**Do first:** —

**Why:** Reviewed T12 reconnect design (single start gate, unique generations, watchdog reconcile, fail-closed, loop guard) ported onto today's baseline: a session that ends with the cable still in restarts by itself; replug keeps working.

## Connection steps
Parked at Home, phone unplugged during prep. Run the Start shortcut, type START, wait for READY, do the Diagnostics checkpoint and type PASS. Switch USB to phone mode in the Honda Diagnostics menu (the label may say Apple CarPlay/phone mode), return to the Home screen FIRST (never plug the phone in while the Diagnostics menu is still open: on 2026-11-04 that left the permission overlay stuck until a car restart), then plug in the phone. Afterward: unplug the phone, switch back to ADB mode, reconnect the laptop, run the Collect shortcut, wait for SAFE TO DISCONNECT.

## Steps
- Session ends with the cable still in are rare; this mostly runs as a normal drive with protection.
- 1 Use AA normally. If AA drops back to Honda Home while the cable is in, wait 10 s: it should come back by itself. Note the time. (A frozen picture that does not end the session is NOT covered: unplug/replug then.)
- 2 Replug check: unplug and replug 3 times; AA must come back each time.
- 3 A 4th quick drop within 10 minutes is expected NOT to auto-restart (loop guard).
- Pass: no replug regression; ended sessions recover by themselves.

**Pass:** No replug regression; in-session drops recover by themselves.

**Emergency stop:** stay parked and unplug the phone — that always ends our session.

**Evidence Claude reads:** SESSION_START / SESSION_ENDED / RECONNECT_ARMED / RECONNECT_DISABLED.

## Result (fill in)
- Date:
- Result: PASS / FAIL / PARTIAL / NOT RUN
- What you saw:
- Photos:
