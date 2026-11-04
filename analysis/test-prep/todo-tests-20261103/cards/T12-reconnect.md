# T12 — Reconnect after unplug/replug

**Type:** Build  
**Run with:** Start-T12-reconnect.cmd / Collect-T12-reconnect.cmd  
**Do first:** —

**Why:** Today a replug needs the laptop. This build re-arms the helper after a clean session end, with a loop guard.

## Connection steps
Parked at Home, phone unplugged during prep. Run the Start shortcut, type START, wait for READY, do the Diagnostics checkpoint and type PASS. Switch USB to phone mode in the Honda Diagnostics menu (the label may say Apple CarPlay/phone mode), return to the Home screen FIRST (never plug the phone in while the Diagnostics menu is still open: on 2026-11-04 that left the permission overlay stuck until a car restart), then plug in the phone. Afterward: unplug the phone, switch back to ADB mode, reconnect the laptop, run the Collect shortcut, wait for SAFE TO DISCONNECT.

## Steps
- 1 Wait until AA is fully on screen and music plays.
- 2 Unplug the phone. Wait 10 seconds. Honda Home should return.
- 3 Plug the phone back in. Within about 15 s AA should come back on its own (the permission prompt may flash and be auto-accepted).
- 4 Repeat unplug/replug two more times (3 total). A 4th quick cycle within 10 minutes is expected NOT to reconnect (loop guard) - note it.
- Pass: AA comes back after each of the first 3 replugs with no laptop action, picture, touchpad and audio working each time.

**Pass:** Three replugs each bring AA back without the laptop.

**Emergency stop:** stay parked and unplug the phone — that always ends our session.

**Evidence Claude reads:** SESSION_START / SESSION_ENDED / RECONNECT_ARMED / RECONNECT_DISABLED (RDX.USB).

## Result (fill in)
- Date:
- Result: PASS / FAIL / PARTIAL / NOT RUN
- What you saw:
- Photos:
