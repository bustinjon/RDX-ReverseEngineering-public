# T110 bundle: car results (2026-11-07, about 23:05-23:20, operator report + logs)

Collect: SAFE TO DISCONNECT with UNDO. Evidence: runs/helper_20261108T040526_*. Power-off not re-run (passed in T100).

| Item | Result | Notes |
|---|---|---|
| Startup picture (decoder retry) | PASS so far | Maps looked good. Monitor on the long-drive test |
| Home from any menu while AA runs | PASS | |
| Blue AA box removed | PASS | Operator: good |
| Map colours (hold console skip-forward) | PASS | Did not disturb audio; short press still skips. Request: also in Settings, plus a list of all button mappings |
| Talk button takeover (T115) | PARTIAL | First press: grab at +90 ms, Honda aborted (NOT_ACTIVE), Gemini opened. Later presses: grab at +14 ms came before Honda's own focus request; Honda took focus back 58 ms later (TALK_FOCUS change=-2) and continued. Fix: hold focus and re-take it until Honda reports NOT_ACTIVE, then send the Assistant key |
| Side-panel press opens Gemini | PASS | A second side-panel press closes Gemini (unless it clears itself after speaking) |
| Cursor hides after 5 s | PASS | |
| USB devices | PARTIAL | smartBox listed ON; phone shown "always on". Request: a Devices submenu listing recently plugged phones/dongles, each enabled or disabled, the main phone included |
| Wireless dongle | PASS | |

Open questions from the operator: more wireless AA testing without a dongle? Hackura tile while driving?
