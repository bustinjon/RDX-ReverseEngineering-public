# T70 bundle: car results (2026-11-06, operator report)

Main run: Collect SAFE TO DISCONNECT, cleanup verified. Power-off (step 4) skipped. T73 was done (operator), PASS.

| Item | Result | Notes |
|---|---|---|
| 1b Bluetooth battery/signal | PASS (already there) | Shown on Honda Home and in AA. No work needed. |
| 2 New defaults | PASS | |
| Honda audio source | PARTIAL | Works once "Hackura - Android Auto" is selected by hand (steering wheel controls OK). Going Home and back to Hackura makes the dash show "No device connected"; it still works on Honda Home. Want: select it automatically when our AA opens, and keep it across Home/Hackura. |
| T71 strip scroll | PARTIAL | Works when the app is in the 2/3 pane, not in the 1/3 pane. |
| T72 track info | PASS with the audio-source caveat | Works with steering-wheel controls, needs Hackura reselected; same "No device connected" after Home and back. |
| T74 Maps turn-by-turn | PASS | |
| T73 remember this phone | PASS | Operator: no USB popups on the second plug-in. "Use by default" now stays set for this phone. |
| P3 wireless announce | NO RESULT | Probe at 11:08, nothing on the phone. |
| Hackura while driving | ISSUE | Launching Hackura from Home while driving: "For your safety, this application is not available while driving. Please stop your car and try again". Works parked. Want a fix. |
| New request | | Separate volume for Maps/Gemini (navigation/assistant) vs media, like stock AA. Knob now controls both. |

Evidence: live-20261106-155515, operator-20261106-155508, operator-20261106-160914 (log analysis pending).

## Dongle (round B, ~11:13-11:15)
Serial DONGLE_SERIAL (from 2025-10-25 logs: Android/smartBox, vid 2717 pid ff40, switches to 18d1:2d00 when Honda drives it). Added via Add-Phone (POLICY_EXTRA_PHONES saved).
Car: dongle attached as 2717:ff40 and re-enumerated every ~13 s (7 attaches); our helper never acted (no AOAP switch). Phone said "Android Auto is available, continue on vehicle screen" / briefly "connected to your car". Hackura tap opened Settings (no session).
Cause (code): isNonAoapPhone() accepts only vid 0x22d9 (OnePlus), so the dongle is never switched to AOAP even though its serial is allowed. Fix: allow the AOAP switch for any device whose serial is on the allowed list.

## Power-off with T73 (after round B, without "Start without laptop")
- Quick off/on with the phone plugged in: AA reconnected by itself, no popups. But Home and the side-panel long hold did nothing; had to unplug.
- Long 2-min power-off, phone unplugged until Honda's "Non authorized" screen cleared, then plugged in: AA started, no popups, no laptop. PASS.
- Likely cause of dead buttons (to confirm in logs): Home/side-panel keys are read by the accessibility service, which is off after Collect/power-off.
- Final Collect (operator-20261106-162816): UNDO run, SAFE TO DISCONNECT. App (T70 build) and the T73 USB default remain on the car.
Evidence: runs/helper_20261106T161644_0e5f9f0eeb424e918f7563f88d753132
