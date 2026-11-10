# Next build to-do (operator requests)

- (2026-11-08) Start should stop an untracked Hackura copy left from daily drives by itself, so the operator doesn't have to run the previous bundle's Collect + UNDO first. Hit before T100, T160 and T170: UNTRACKED_HELPER in Prepare-TimedStage.ps1:96.
- DONE in T190 (2026-11-08): settings are kept across updates (only new switches get defaults).

## For the final package / installer (with the full uninstall + reinstall test)
- (2026-11-08) Rename the app from "Hackura" to **FS-AA**, with a new icon. Change the launcher label, the Settings title, the Honda media-source and navigation-provider names, the notification and status texts, and the user guide. Do it together with the installer build and the clean uninstall/reinstall test, not in a test bundle. Honda caches the source and navigation names, so they need a fresh install to update.
- (2026-11-08) Uninstall / restore-stock goes in the final installer/uninstaller, not a Settings button (operator).
- (2026-11-08) Operator confirmed from daily use: reverse camera and phone calls work fine with Hackura. No dedicated test needed.

- (2026-11-08) DAILY WIRELESS (operator): wireless AA auto-starts with the car, Quiet Wi-Fi ON by default (station Wi-Fi paused). Release notes: owners who need the car on Wi-Fi should turn wireless AA / Quiet off. Overrides CODEX-WIRELESS-DAILY "Quiet off".
