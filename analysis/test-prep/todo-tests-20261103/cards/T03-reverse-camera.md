# T03 — Reverse camera with AA on screen

**Type:** Watch (safety)  
**Run with:** Session A (Start-A-watch-only.cmd / Collect-A-watch-only.cmd), Maps-only build, no new code  
**Do first:** Stock baseline first

**Why:** Honda's camera window ranks above ours, but the camera image itself is drawn natively, so we do not know it shows. HOME is ignored in reverse.

## Before starting
- With our app NOT running: parking brake on, foot on brake, shift to R, photo of the normal camera view, back to P.

## Connection steps
Parked at Home, phone unplugged during prep. Run the Start shortcut, type START, wait for READY, do the Diagnostics checkpoint and type PASS. Switch USB to phone mode in the Honda Diagnostics menu (the label may say Apple CarPlay/phone mode), return to the Home screen FIRST (never plug the phone in while the Diagnostics menu is still open: on 2026-11-04 that left the permission overlay stuck until a car restart), then plug in the phone. Afterward: unplug the phone, switch back to ADB mode, reconnect the laptop, run the Collect shortcut, wait for SAFE TO DISCONNECT.

## Steps
- Session A step 1: foot on brake, shift to R. Whole picture and guidelines visible, nothing of ours on top? Photo.
- Shift to P. AA returns? Touchpad works? Photo.
- If anything is wrong: stay in P and unplug the phone.

**Pass:** Camera identical to the stock baseline photo; AA and touchpad recover.

**Stop rule:** Camera blocked even partly: do not drive with our app until fixed.

**Emergency stop:** stay parked and unplug the phone — that always ends our session.

**Evidence Claude reads:** DummyHondaRearCameraDialog, PopUpManager, WindowManager tags (added for this session).

## Result (fill in)
- Date:
- Result: PASS / FAIL / PARTIAL / NOT RUN
- What you saw:
- Photos:
