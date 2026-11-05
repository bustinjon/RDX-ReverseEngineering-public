# T18 — Recovery after a failure mid-drive

**Type:** Watch  
**Run with:** Start-B-current-baseline.cmd / Collect-B-current-baseline.cmd  
**Do first:** —

**Why:** Reliability item 7. Replug already recovers; this checks every failure kind does.

## Connection steps
Parked at Home, phone unplugged during prep. Run the Start shortcut, type START, wait for READY, do the Diagnostics checkpoint and type PASS. Switch USB to phone mode in the Honda Diagnostics menu (the label may say Apple CarPlay/phone mode), return to the Home screen FIRST (never plug the phone in while the Diagnostics menu is still open: on 2026-11-04 that left the permission overlay stuck until a car restart), then plug in the phone. Afterward: unplug the phone, switch back to ADB mode, reconnect the laptop, run the Collect shortcut, wait for SAFE TO DISCONNECT.

## Steps
- During normal use note any drop-out (black screen, frozen picture, no audio). Each time: unplug, wait 5 s, replug, note whether AA comes back and how long it took.

**Pass:** Every drop-out recovers with one replug.

**Emergency stop:** stay parked and unplug the phone — that always ends our session.

**Evidence Claude reads:** Transport write ended / USB_DEVICE_DETACHED / AUTO_GRANTED timeline.

## Result (fill in)
- Date:
- Result: PASS / FAIL / PARTIAL / NOT RUN
- What you saw:
- Photos:
