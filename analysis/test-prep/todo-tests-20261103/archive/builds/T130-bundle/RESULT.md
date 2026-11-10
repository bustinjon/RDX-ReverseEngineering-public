# T130 bundle: car results (2026-11-08, operator report + logs)

Collect: SAFE TO DISCONNECT with UNDO. Evidence: runs/helper_20261108T061529_*.

| Item | Result | Notes |
|---|---|---|
| Settings (bigger text, Day / Night / Auto, Reset confirm) | PASS | "Much better" |
| Talk button press: Gemini (default on) | PASS | |
| Talk button hold: Gemini (switch) | PASS | Hold opens Gemini; with the press switch off a short press gives Acura voice, like stock AA. Defaults stay: press on, hold off |
| Side-panel Gemini off by default | PASS | Short side-panel press did nothing with the switch off |
| Cursor | Request | Must be "right on" a target. Log: 11 presses; cursor shift from 150-600 ms before the press to the press itself: median 7, p75 27, max 107 raw pad units (up to about 155 screen px): pushing the pad rolls the finger |

Next: research Honda's "Non authorized apps" warning (Codex, offline); plan how to test the final installer.
