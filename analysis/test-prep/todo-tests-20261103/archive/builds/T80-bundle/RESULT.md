# T80 bundle: car results (2026-11-06, about 15:38-15:56)

Collect: SAFE TO DISCONNECT with UNDO (operator-20261106-205627). Evidence: runs/helper_20261106T203838_*.
Not done this visit: dongle (step 4) and buttons after a power-off (step 5).

| Item | Result | Notes |
|---|---|---|
| Honda audio source auto-select | PASS | Selected Hackura with no input (log 15:45:59 setSelectedAudioSourceComponent ...AaMediaSourceService) |
| Dash track after Home and back | PASS | Track and steering-wheel controls kept |
| Knob / wheel power pause and resume | PASS | |
| Home-screen card | PASS | Hackura music (and navigation) shown in the side-panel cards |
| Strip scroll v2 (T81) | PARTIAL | Finger up (list scrolls down) works; finger down does not. Cause (log): the rest anchor was taken at the top edge of the pane (anchors 1177,62 and 1870,46). Upward grabs move to mid-screen; downward grabs start at the anchor, on the card title bar. Fix: always keep the grab start inside the middle half of the screen |
| Separate nav volume (T85) | PASS | stream=10 used, no fallback needed |
| Gemini | FAIL (both T85 on and off) | Mic opens, frames reach the phone (rms 80-190), music pauses, but the phone listens about 10 s and never replies. In T70 (10:59) it closed at 5 s and answered. No mic code changed in T80. Possibly phone side (network); to retest |
| Now-playing tap returns AA / while driving | Not reported | |

Requests:
- Dash: show the track all the time, not only on song change.
- Steering-wheel talk button: hold opens Gemini (as stock AA), press stays Honda voice.

Talk button research (offline, TJBASpeechRecognizer + com.honda.auto.voicerecognition.jar from the system dump):
- Stock AA is a "projected VR provider" (service meta-data com.honda.vrprojected). Honda's VRController.getEngines only accepts system apps (flags & (FLAG_SYSTEM|FLAG_UPDATED_SYSTEM_APP)), so Hackura cannot be a provider.
- PTT_DOWN / PTT_UP / LONG_PRESS are broadcasts; Honda's receivers require the sender to hold auto.permission.VRCOMM_SERVICE. Whether the sender restricts who may receive them is unknown (no sent records captured).
- Stock long press sends AA key 84 (SEARCH) as a long key event (ProjectionActivity.reportASRKeyLongPress). Our InputSource facade has no long-key method yet.
- Next: a probe that listens for the three PTT broadcasts and logs them; if they arrive, long press -> key 84 long event.
