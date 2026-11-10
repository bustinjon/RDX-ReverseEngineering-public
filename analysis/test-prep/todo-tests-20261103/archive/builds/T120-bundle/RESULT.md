# T120 bundle: car results (2026-11-08, about 00:20-00:35, operator report + logs)

Collect: SAFE TO DISCONNECT with UNDO (operator-20261108-053528). Evidence: runs/helper_20261108T052347_*. The automatic grant ran.

| Item | Result | Notes |
|---|---|---|
| Settings layout | PASS, too small | Screenshot screens/settings-002534.png: text tiny next to Honda's, bottom 40% empty. Request: bigger text everywhere; rename "Map colours" to Day / Night / Auto; "Are you sure?" on Reset all |
| Hold skip-forward switch, Home switch | PASS | |
| Console and wheel skip switch | PASS | |
| Disable / enable main phone | PASS | |
| Talk button opens Gemini (T125) | **PASS** | Each press: TALK_TAKEOVER done hondaStopped=true (0-1 re-grabs), TALK_ASSISTANT sent; Gemini opens. Operator: make it the default; side-panel Gemini off by default but kept as an option |
| Talk button during a call | PASS | Nothing happens |
| Talk button hold | Nothing happens | LONG_PRESS delivered to com.honda.siri; Siri reports only NOT_ACTIVE 18 ms later (no "not iOS" message seen). Siri also reports NOT_ACTIVE after every short press, but only right after a takeover. Plan: Siri NOT_ACTIVE with no Honda voice activity in the last 3 s = a hold -> Gemini |
