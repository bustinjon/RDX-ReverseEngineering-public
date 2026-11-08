# T100 bundle: car results (2026-11-07, about 22:00-22:15, operator report + logs)

Collect: SAFE TO DISCONNECT with UNDO, done **before** the power-off section (section 6 not run). Evidence: runs/helper_20261108T030131_*.
First Start was refused (UNTRACKED_HELPER: Hackura still running from daily drives); Collect-T90 with UNDO cleared it.

| Item | Result | Notes |
|---|---|---|
| FM takeover | Accepted | AA audio takes over; Home lets FM resume. Operator: fine |
| Exit icon "Honda Home" | PASS | Video focus request=2 reason=0 at 22:03:31 -> EXIT_ICON decision=1; Hackura brings AA back |
| Blue AA button | FAIL | Visible at bottom-left, but the touchpad only gives a general press there, so it cannot be tapped. Remove |
| Now Playing card | PASS (parked) | |
| Console skip | PASS | SKIP_DUPLICATE dropped 3 doubled presses (22:04:47-49), confirming the two-route cause |
| Wheel controls | PASS | |
| USB devices: Seen -> Allow | PASS | Request: list every detected device with an on/off toggle |
| Strip scroll v4 (T101) | FAIL | Drags sent correctly (DOWN, one-to-one MOVEs 16+ ms apart, UP) but the phone did not scroll. Fourth failure; retire |
| Talk button takeover (T105) | FAIL, cause found | Honda's voice states reach us (ACTIVE, LISTENING...), but dismissVrSession throws SecurityException inside Honda (permission checked against our uid). Honda aborts its own session on audio-focus loss (AbstractSpeechRecognizerService.onAudioFocusChange -> sendSilentAbort): use that |
| Side-panel press opens Assistant (T103) | PASS | KEY_LONG code=84 result=0, Gemini opened |
| Side-panel press returns to AA (T104) | PASS | Also while driving |
| Start AA while driving (T102) | PASS | Plugging in while moving starts AA (ATTACH_BROADCAST path). The Hackura tile still shows "For your safety": Honda's framework refuses every third-party activity while moving |
| Power-off / Start without laptop (second run, 22:16) | **PASS** | Non-authorized acked about 22:21; 22:22 Settings: Auto-accept ON, connected. Home works after the cold start; Hackura and the side panel return AA; side-panel hold still opens Settings after 6 min; dongle works. Cause confirmed: the missing WRITE_SETTINGS. Collected before the dongle power-off check (third run started for it). Note: leave Settings with Back, not Home |

Requests: hide the touch cursor after about 5 s; a Hackura-tile return while driving (not possible: framework block; side panel does it); remove Honda's "Non authorized apps" warning (to-do).

Also reported: occasional Maps graphic damage, mostly at startup (photos/Map_Issue.jpg): H.264 smearing. Every session start logs "Decoder drop #1/#2: No decoder input buffer": the first frames are thrown away after a 50 ms wait. T110 retries with output drained.
Request: a Day/Night icon in the app list (Auto / Day / Night with a popup), or a button shortcut.
