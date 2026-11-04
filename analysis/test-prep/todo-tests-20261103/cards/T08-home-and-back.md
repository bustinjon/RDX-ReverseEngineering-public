# T08 — Home and back to AA

**Type:** Watch  
**Run with:** Session A (Start-A-watch-only.cmd / Collect-A-watch-only.cmd), Maps-only build, no new code  
**Do first:** —

**Why:** The Honda launch/resume flow is incomplete; we do not know what happens when you leave AA and return.

## Connection steps
Parked at Home, phone unplugged during prep. Run the Start shortcut, type START, wait for READY, do the Diagnostics checkpoint and type PASS. Switch USB to phone mode in the Honda Diagnostics menu (the label may say Apple CarPlay/phone mode), return to the Home screen FIRST (never plug the phone in while the Diagnostics menu is still open: on 2026-11-04 that left the permission overlay stuck until a car restart), then plug in the phone. Afterward: unplug the phone, switch back to ADB mode, reconnect the laptop, run the Collect shortcut, wait for SAFE TO DISCONNECT.

## Steps
- Session A step 2: press Home, open Audio or Settings, return to AA the usual way.

**Pass:** AA comes back with picture, touchpad and audio.

**Emergency stop:** stay parked and unplug the phone — that always ends our session.

**Evidence Claude reads:** RDX.AAOVERLAY, ActivityManager.

## Result (fill in)
- Date:
- Result: PASS / FAIL / PARTIAL / NOT RUN
- What you saw:
- Photos:
