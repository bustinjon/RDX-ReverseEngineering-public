# T09 — Volume display (NOT POSSIBLE: volume signal requires a Honda-only permission, signal check 2026-11-04)

**Type:** Dropped  
**Run with:** Start-T09-volume-display.cmd / Collect-T09-volume-display.cmd  
**Do first:** T06 says readable

**Why:** Volume changes work but Honda's indicator is hidden under our overlay.

## Connection steps
Parked at Home, phone unplugged during prep. Run the Start shortcut, type START, wait for READY, do the Diagnostics checkpoint and type PASS. Switch USB to phone mode in the Honda Diagnostics menu (the label may say Apple CarPlay/phone mode), return to the Home screen FIRST (never plug the phone in while the Diagnostics menu is still open: on 2026-11-04 that left the permission overlay stuck until a car restart), then plug in the phone. Afterward: unplug the phone, switch back to ADB mode, reconnect the laptop, run the Collect shortcut, wait for SAFE TO DISCONNECT.

## Steps
- Play music in AA. Turn the volume knob up and down a few clicks, then use the wheel volume buttons.
- Pass: a small Volume N box appears at the top centre for about 3 seconds, the number matches the change, and touchpad control keeps working while it shows.
- If no box appears at all, that is still a useful result - note it.

**Pass:** A "Volume N" box shows ~3 s, matches the change, touchpad unaffected.

**Emergency stop:** stay parked and unplug the phone — that always ends our session.

**Evidence Claude reads:** VOLUME_FEEDBACK_* lines, VolumeManager.

## Result (fill in)
- Date:
- Result: PASS / FAIL / PARTIAL / NOT RUN
- What you saw:
- Photos:
