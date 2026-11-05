# T33 — Absolute touchpad inside AA (experiment)

**Type:** Build  
**Run with:** Start-T33-absolute-touch.cmd / Collect-T33-absolute-touch.cmd  
**Do first:** —

**Why:** User idea: on Honda screens the pad is absolute; inside AA it acts like arrow keys. This build registers a touchscreen (1920x1080 frame) instead of the navigation touchpad; resting a finger shows a ring cursor, pressing taps there, press-and-slide drags. Design: analysis/agent-reviews/absolute-touchpad-20261104/REPORT.md.

## Connection steps
Parked at Home, phone unplugged during prep. Run the Start shortcut, type START, wait for READY, do the Diagnostics checkpoint and type PASS. Switch USB to phone mode in the Honda Diagnostics menu (the label may say Apple CarPlay/phone mode), return to the Home screen FIRST (never plug the phone in while the Diagnostics menu is still open: on 2026-11-04 that left the permission overlay stuck until a car restart), then plug in the phone. Afterward: unplug the phone, switch back to ADB mode, reconnect the laptop, run the Collect shortcut, wait for SAFE TO DISCONNECT.

## Steps
- 1 With AA up, rest a finger on the touchpad: a small white ring should follow your finger across the AA screen.
- 2 Move the ring onto an AA button (app icon, Maps search, Spotify play) and press the pad: that exact button should activate.
- 3 In Maps, press and hold, then slide: the map should pan.
- 4 Check Back and the console track buttons still work. Note anything that is hard to hit.
- 5 If taps do nothing at all, that is a valid result (the phone may not accept a touchscreen here); unplug to end.
- Pass: taps land where the ring is, dragging pans, Back works.

**Pass:** Taps land under the ring, dragging pans, Back works.

**Emergency stop:** stay parked and unplug the phone — that always ends our session.

**Evidence Claude reads:** Touchscreen registered, INPUT_TOUCHSCREEN action= x= y= result= (RDX.SESSION / RDX.INPUT).

## Result (fill in)
- Date:
- Result: PASS / FAIL / PARTIAL / NOT RUN
- What you saw:
- Photos:
