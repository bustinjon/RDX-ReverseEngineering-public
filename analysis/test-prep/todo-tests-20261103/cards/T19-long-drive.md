# T19 — Multi-hour drive + memory

**Type:** Watch  
**Run with:** Start-B-current-baseline.cmd / Collect-B-current-baseline.cmd (or the new launcher, T31)  
**Do first:** —

**Why:** Reliability item 7. Nothing has been proven over hours. The untimed session samples memory every minute.

## Connection steps
Parked at Home, phone unplugged during prep. Run the Start shortcut, type START, wait for READY, do the Diagnostics checkpoint and type PASS. Switch USB to phone mode in the Honda Diagnostics menu (the label may say Apple CarPlay/phone mode), return to the Home screen FIRST (never plug the phone in while the Diagnostics menu is still open: on 2026-11-04 that left the permission overlay stuck until a car restart), then plug in the phone. Afterward: unplug the phone, switch back to ADB mode, reconnect the laptop, run the Collect shortcut, wait for SAFE TO DISCONNECT.

## Steps
- Normal driving 2+ hours with Maps and music. Note drop-outs, audio glitches, lag, heat.

**Pass:** No drop-outs; memory flat in the health samples.

**Emergency stop:** stay parked and unplug the phone — that always ends our session.

**Evidence Claude reads:** health.log memory samples, AUDIO_SUMMARY drops.

## Result (fill in)
- Date:
- Result: PASS / FAIL / PARTIAL / NOT RUN
- What you saw:
- Photos:
