# T05 — Steering-wheel talk button

**Type:** Watch  
**Run with:** Session A (Start-A-watch-only.cmd / Collect-A-watch-only.cmd), Maps-only build, no new code  
**Do first:** —

**Why:** The talk button goes to Honda's voice service, which needs a privileged permission. Expected: nothing reaches us.

## Connection steps
Parked at Home, phone unplugged during prep. Run the Start shortcut, type START, wait for READY, do the Diagnostics checkpoint and type PASS. Switch USB to phone mode in the Honda Diagnostics menu (the label may say Apple CarPlay/phone mode), return to the Home screen FIRST (never plug the phone in while the Diagnostics menu is still open: on 2026-11-04 that left the permission overlay stuck until a car restart), then plug in the phone. Afterward: unplug the phone, switch back to ADB mode, reconnect the laptop, run the Collect shortcut, wait for SAFE TO DISCONNECT.

## Steps
- Press the talk button once. Note what you see and hear.

**Pass:** Recorded (any outcome). Decides whether a talk-button route exists.

**Emergency stop:** stay parked and unplug the phone — that always ends our session.

**Evidence Claude reads:** INPUT_RAW_KEY lines.

## Result (fill in)
- Date:
- Result: PASS / FAIL / PARTIAL / NOT RUN
- What you saw:
- Photos:
