# T37 — Measure the real video frame rate

**Type:** Build (diagnostic)  
**Run with:** Start-T37-frame-rate.cmd / Collect-T37-frame-rate.cmd  
**Do first:** —

**Why:** We request 60 fps at 1080p (VideoSink) but never measured what the phone sends. Logs VIDEO_FPS every 10 s.

## Connection steps
Parked at Home, phone unplugged during prep. Run the Start shortcut, type START, wait for READY, do the Diagnostics checkpoint and type PASS. Switch USB to phone mode in the Honda Diagnostics menu (the label may say Apple CarPlay/phone mode), return to the Home screen FIRST (never plug the phone in while the Diagnostics menu is still open: on 2026-11-04 that left the permission overlay stuck until a car restart), then plug in the phone. Afterward: unplug the phone, switch back to ADB mode, reconnect the laptop, run the Collect shortcut, wait for SAFE TO DISCONNECT.

## Steps
- 1 Use AA for about 5 minutes: scroll a list, pan the map, play a video-like animation if any.
- 2 Nothing to judge on screen; the logs record frames per second every 10 s.
- Pass: logs show VIDEO_FPS values; that tells us whether the phone sends 30 or 60.

**Pass:** VIDEO_FPS values recorded; decides whether to push for 60.

**Emergency stop:** stay parked and unplug the phone — that always ends our session.

**Evidence Claude reads:** VIDEO_FPS fps= totalFrames=.

## Result (fill in)
- Date:
- Result: PASS / FAIL / PARTIAL / NOT RUN
- What you saw:
- Photos:
