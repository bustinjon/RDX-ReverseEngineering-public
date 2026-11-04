# T10 — Track buttons (Next/Previous)

**Type:** Build  
**Run with:** Start-T10-track-buttons.cmd / Collect-T10-track-buttons.cmd  
**Do first:** —

**Why:** Raw track keys reach us but are not forwarded. Risk: double skip when the car also sends a Bluetooth skip.

## Connection steps
Parked at Home, phone unplugged during prep. Run the Start shortcut, type START, wait for READY, do the Diagnostics checkpoint and type PASS. Switch USB to phone mode in the Honda Diagnostics menu (the label may say Apple CarPlay/phone mode), return to the Home screen FIRST (never plug the phone in while the Diagnostics menu is still open: on 2026-11-04 that left the permission overlay stuck until a car restart), then plug in the phone. Afterward: unplug the phone, switch back to ADB mode, reconnect the laptop, run the Collect shortcut, wait for SAFE TO DISCONNECT.

## Steps
- Play music in AA first. Test each physical control separately and say which one you used (steering wheel left side, console, anything else).
- 1 Short press Next, wait 3 s, short press Previous. Count how many tracks each press moved.
- 2 Hold Next for about 2 seconds, release. Expected: no skip from our app (a hold is ignored). Note what happens.
- 3 Repeat steps 1-2 with phone Bluetooth Media audio OFF, then ON. With it ON, watch for a double skip (two tracks per press).
- Pass: one press = one track, both directions, both Bluetooth settings.

**Pass:** One press = one track, both directions, Bluetooth media on and off. Holds do not skip.

**Emergency stop:** stay parked and unplug the phone — that always ends our session.

**Evidence Claude reads:** INPUT_MEDIA_RAW / INPUT_MEDIA_KEY / INPUT_MEDIA_NOT_SENT, SeekKeyHandler.

## Result (fill in)
- Date:
- Result: PASS / FAIL / PARTIAL / NOT RUN
- What you saw:
- Photos:
