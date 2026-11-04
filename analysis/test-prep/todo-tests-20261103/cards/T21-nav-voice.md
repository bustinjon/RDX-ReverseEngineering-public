# T21 — Navigation voice prompts play out

**Type:** Build  
**Run with:** Start-T21-nav-voice.cmd / Collect-T21-nav-voice.cmd  
**Do first:** —

**Why:** Session A: Maps prompts were silent while music ducked. The phone sends each prompt faster than real time and then says stop; the receiver discarded the unplayed part (181 of 205 frames). This build lets guidance audio play out. Music is unchanged.

## Connection steps
Parked at Home, phone unplugged during prep. Run the Start shortcut, type START, wait for READY, do the Diagnostics checkpoint and type PASS. Switch USB to phone mode in the Honda Diagnostics menu (the label may say Apple CarPlay/phone mode), return to the Home screen FIRST (never plug the phone in while the Diagnostics menu is still open: on 2026-11-04 that left the permission overlay stuck until a car restart), then plug in the phone. Afterward: unplug the phone, switch back to ADB mode, reconnect the laptop, run the Collect shortcut, wait for SAFE TO DISCONNECT.

## Steps
- 1 Play music in AA. Start a Maps route with turns coming up soon (or tap the speaker icon in Maps to replay the next instruction).
- 2 Listen: do you hear the spoken direction in full, does music dip under it and come back afterwards?
- 3 Do this at least 3 times. Also check music still pauses straight away when you press pause.
- Pass: every prompt is heard in full; music ducks and returns; pause still instant.

**Pass:** Every prompt heard in full; music ducks and returns; pause still instant.

**Emergency stop:** stay parked and unplug the phone — that always ends our session.

**Evidence Claude reads:** Audio playback stop ... draining=N, Audio guidance drained, AUDIO_SUMMARY id=5 dropped count.

## Result (fill in)
- Date:
- Result: PASS / FAIL / PARTIAL / NOT RUN
- What you saw:
- Photos:
