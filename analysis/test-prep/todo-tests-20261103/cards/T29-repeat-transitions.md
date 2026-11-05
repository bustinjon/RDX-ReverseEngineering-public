# T29 — Repeated call / reverse / voice / minimize transitions

**Type:** Watch  
**Run with:** Start-B-current-baseline.cmd / Collect-B-current-baseline.cmd (T22 once it passes)  
**Do first:** —

**Why:** Reliability item 7. Single passes do not prove repeatability.

## Connection steps
Parked at Home, phone unplugged during prep. Run the Start shortcut, type START, wait for READY, do the Diagnostics checkpoint and type PASS. Switch USB to phone mode in the Honda Diagnostics menu (the label may say Apple CarPlay/phone mode), return to the Home screen FIRST (never plug the phone in while the Diagnostics menu is still open: on 2026-11-04 that left the permission overlay stuck until a car restart), then plug in the phone. Afterward: unplug the phone, switch back to ADB mode, reconnect the laptop, run the Collect shortcut, wait for SAFE TO DISCONNECT.

## Steps
- 5 times each, parked: incoming call (answer, hang up); shift R then P; trigger a Maps prompt; Gemini question. After each, check picture, touchpad and music.
- Also: hold the touchpad pressed, swipe fast, press two buttons at once (input edge cases).

**Pass:** Every transition recovers; no stuck input.

**Emergency stop:** stay parked and unplug the phone — that always ends our session.

**Evidence Claude reads:** AUDIO_FOCUS, PopUpManager, INPUT_* lines.

## Result (fill in)
- Date:
- Result: PASS / FAIL / PARTIAL / NOT RUN
- What you saw:
- Photos:
