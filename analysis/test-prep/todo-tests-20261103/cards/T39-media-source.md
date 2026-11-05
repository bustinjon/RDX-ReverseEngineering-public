# T39 — Our app as a Honda audio source

**Type:** Build  
**Run with:** Start-T39-media-source.cmd / Collect-T39-media-source.cmd  
**Do first:** —

**Why:** Honda lists any MediaBrowserService as a source (confirmed). "AA Fullscreen" source; Honda next/previous forwarded to the phone as 87/88. May end the FM/Bluetooth source conflicts; wheel buttons probably still blocked.

## Connection steps
Parked at Home, phone unplugged during prep. Run the Start shortcut, type START, wait for READY, do the Diagnostics checkpoint and type PASS. Switch USB to phone mode in the Honda Diagnostics menu (the label may say Apple CarPlay/phone mode), return to the Home screen FIRST (never plug the phone in while the Diagnostics menu is still open: on 2026-11-04 that left the permission overlay stuck until a car restart), then plug in the phone. Afterward: unplug the phone, switch back to ADB mode, reconnect the laptop, run the Collect shortcut, wait for SAFE TO DISCONNECT.

## Steps
- 1 With AA playing music, press Home and open the Honda audio source list. Is there an AA Fullscreen source? Photo.
- 2 Select it. Does AA music keep playing (no silence, no FM taking over)? Return to AA with the side-panel button.
- 3 Console Next/Previous: one track per press? Any double skips?
- 4 Hold a console seek button: any pause now?
- 5 Steering-wheel Next/Previous once each (expected: probably still nothing, but note it). Note the times.
- 6 Select FM again from the Honda source list and back to AA Fullscreen: does AA audio return?
- Pass: AA Fullscreen listed and selectable, audio keeps playing, one track per press.

**Pass:** Listed, selectable, audio keeps playing, one track per press.

**Emergency stop:** stay parked and unplug the phone — that always ends our session.

**Evidence Claude reads:** MEDIASRC_* (RDX.MEDIASRC), HondaAudioSourcesMgr, SeekKeyHandler.

## Result (fill in)
- Date:
- Result: PASS / FAIL / PARTIAL / NOT RUN
- What you saw:
- Photos:
