# T34 — Nicer volume display (look check)

**Type:** Build  
**Run with:** Start-T34-volume-look.cmd / Collect-T34-volume-look.cmd  
**Do first:** T24 passed

**Why:** User: T24 works, make it look nicer. Option A built: rounded dark panel, VOL label, blue level bar scaled to the real maximum (hidden getMasterMaxVolume, fallback 40), number, fade in/out, top centre. Alternatives if not liked: B) slim vertical bar at the right edge; C) small round badge near the clock area.

## Connection steps
Parked at Home, phone unplugged during prep. Run the Start shortcut, type START, wait for READY, do the Diagnostics checkpoint and type PASS. Switch USB to phone mode in the Honda Diagnostics menu (the label may say Apple CarPlay/phone mode), return to the Home screen FIRST (never plug the phone in while the Diagnostics menu is still open: on 2026-11-04 that left the permission overlay stuck until a car restart), then plug in the phone. Afterward: unplug the phone, switch back to ADB mode, reconnect the laptop, run the Collect shortcut, wait for SAFE TO DISCONNECT.

## Steps
- 1 Play music and turn the knob up and down; also use the wheel volume buttons.
- 2 Expected: a rounded dark panel at the top centre with VOL, a blue level bar and the number; it fades in, stays about 3 s after the last change, then fades out.
- 3 Check it does not cover anything important in Maps (lane guidance, next turn) and that the bar fill looks right at low, middle and high volume. Photo.
- 4 Say what you would change (size, position, colour, show time).
- Pass: you like the look; the numbers still follow the knob.

**Pass:** User approves the look.

**Emergency stop:** stay parked and unplug the phone — that always ends our session.

**Evidence Claude reads:** VOLUME_HUD_STYLE panel max=, VOLUME_FEEDBACK_SHOWN.

## Result (fill in)
- Date:
- Result: PASS / FAIL / PARTIAL / NOT RUN
- What you saw:
- Photos:
