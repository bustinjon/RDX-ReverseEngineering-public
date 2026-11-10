# T300 reconciliation (Claude, 2026-11-10)

Final build: T300-bundle 7744AD4630912D129146CCDBA2A38D5D259B4C655E7A4884DFA6BF3CBE0FD5F6, PASS 263.

Contents (operator request after T290):
- Channel 149 by default (stored index 1; a saved 36 stays 36).
- 30-s boot wait. The T290 car bug is fixed with a main-looper start and a generation token.
- A "Fewer car Wi-Fi scans (test)" switch (OFF). It raises three Settings.Global scan intervals to 300 s while wireless runs, then restores them at stop and at boot.
- The "Black screen at boot (old)" toggle is removed from the Developer page.

CODEX-T300.md (no BLOCKER):
- Scan-only crash recovery: fixed. restoreAfterBoot also triggers when a scan backup exists.
- A stored blackout ON with no toggle: fixed. The boot ignores it (retired).
- Process death during the wait: fixed. The gate returns START_STICKY, so the sticky null restart re-enters the gate with the time left.
- Accepted, UNVERIFIED until the car test: whether Honda's 5.1 WifiStateMachine reads these keys live, and whether its scans come from the framework or from Honda's settings app. The car log answers it: T290_EVENT wifi.SCAN_RESULTS cadence with the switch on, plus T300_SCANS_QUIETED/RESTORED lines. If the cadence stays 10 s, the switch has no effect and is dropped.

Loop stopped.
