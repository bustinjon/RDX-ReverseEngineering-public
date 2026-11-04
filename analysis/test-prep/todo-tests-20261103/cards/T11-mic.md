# T11 — Microphone / Assistant (experiment)

**Type:** Build  
**Run with:** Start-T11-mic.cmd / Collect-T11-mic.cmd  
**Do first:** —

**Why:** The mic is currently refused. Stock also switches the car mic into voice mode through a privileged service we cannot call, so quality is unknown.

## Connection steps
Parked at Home, phone unplugged during prep. Run the Start shortcut, type START, wait for READY, do the Diagnostics checkpoint and type PASS. Switch USB to phone mode in the Honda Diagnostics menu (the label may say Apple CarPlay/phone mode), return to the Home screen FIRST (never plug the phone in while the Diagnostics menu is still open: on 2026-11-04 that left the permission overlay stuck until a car restart), then plug in the phone. Afterward: unplug the phone, switch back to ADB mode, reconnect the laptop, run the Collect shortcut, wait for SAFE TO DISCONNECT.

## Steps
- 1 With AA showing, select the microphone icon in AA with the touchpad. Say: what is the weather today.
- 2 Note: does AA show it is listening, does it understand you, do you hear the answer, does music come back after.
- 3 Try once with the windows closed and fan low, once with the fan high. Note how well it understood.
- 4 If the phone supports it, say Hey Google once with AA on screen.
- Pass: AA understands a spoken request and answers. This is an experiment - poor quality or no response is a valid result.

**Pass:** AA understands a spoken request and answers.

**Emergency stop:** stay parked and unplug the phone — that always ends our session.

**Evidence Claude reads:** MIC_REQUEST / MIC_RECORDING / MIC_FRAMES rms= / MIC_ACK_TIMEOUT (RDX.AUDIOSRC).

## Result (fill in)
- Date:
- Result: PASS / FAIL / PARTIAL / NOT RUN
- What you saw:
- Photos:
