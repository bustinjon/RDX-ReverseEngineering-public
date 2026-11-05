# T27 — Repeated unplug/replug

**Type:** Watch  
**Run with:** Start-B-current-baseline.cmd / Collect-B-current-baseline.cmd  
**Do first:** —

**Why:** Item 1. Two replugs reconnected on 2026-11-04; this makes it a controlled test.

## Connection steps
Parked at Home, phone unplugged during prep. Run the Start shortcut, type START, wait for READY, do the Diagnostics checkpoint and type PASS. Switch USB to phone mode in the Honda Diagnostics menu (the label may say Apple CarPlay/phone mode), return to the Home screen FIRST (never plug the phone in while the Diagnostics menu is still open: on 2026-11-04 that left the permission overlay stuck until a car restart), then plug in the phone. Afterward: unplug the phone, switch back to ADB mode, reconnect the laptop, run the Collect shortcut, wait for SAFE TO DISCONNECT.

## Steps
- With AA running: unplug, wait 10 s, replug from Home. Repeat 5 times. Note each time whether AA came back and roughly how long it took.

**Pass:** 5 of 5 come back within about 15 s with picture, touch and audio.

**Emergency stop:** stay parked and unplug the phone — that always ends our session.

**Evidence Claude reads:** USB_DEVICE_DETACHED/ATTACHED, AUTO_GRANTED, Handing off.

## Result (fill in)
- Date:
- Result: PASS / FAIL / PARTIAL / NOT RUN
- What you saw:
- Photos:
