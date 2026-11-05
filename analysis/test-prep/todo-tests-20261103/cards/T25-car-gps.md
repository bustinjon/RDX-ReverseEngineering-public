# T25 — Car GPS to the phone (nice-to-have)

**Type:** Build  
**Run with:** Start-T25-car-gps.cmd / Collect-T25-car-gps.cmd  
**Do first:** —

**Why:** Nice-to-have. Stock AA forwards the head unit's standard gps location provider (Garmin); ours now does too, with stock unit conversion. Speed travels inside the location fix only; driving status stays parked (user decision). Speed/gear as separate sensors use protected Honda broadcasts (signal check), so they stay an optional offer.

## Connection steps
Parked at Home, phone unplugged during prep. Run the Start shortcut, type START, wait for READY, do the Diagnostics checkpoint and type PASS. Switch USB to phone mode in the Honda Diagnostics menu (the label may say Apple CarPlay/phone mode), return to the Home screen FIRST (never plug the phone in while the Diagnostics menu is still open: on 2026-11-04 that left the permission overlay stuck until a car restart), then plug in the phone. Afterward: unplug the phone, switch back to ADB mode, reconnect the laptop, run the Collect shortcut, wait for SAFE TO DISCONNECT.

## Steps
- 1 Start a Maps route and drive normally for a few minutes, ideally including a spot with weak phone signal (parking garage, tunnel, tall buildings).
- 2 Note whether the AA map position is smooth and correct and whether it keeps tracking where the phone alone might lose it.
- 3 Note anything odd: position jumps, wrong direction, map snapping.
- Pass: position at least as good as before, no jumps. Logs should show GPS_FORWARDING and GPS_FIX lines.

**Pass:** Position at least as good as before, no jumps.

**Emergency stop:** stay parked and unplug the phone — that always ends our session.

**Evidence Claude reads:** GPS_FORWARDING, GPS_FIX (RDX.GPS).

## Result (fill in)
- Date:
- Result: PASS / FAIL / PARTIAL / NOT RUN
- What you saw:
- Photos:
