# T280 reconciliation (Claude, 2026-11-09)

Final build: T280-bundle CF3B52A4D596F5E2DF3166E9487FEFDC45A42A17EDA0E06E41D87BC6ADDB775F, PASS 253.

Contents:
- Cushion off (operator request; T270 added ~3 s of latency).
- FreezeRecorder: p2p interface, TCP, CPU and top processes before and during a freeze.
- Auto-save at lowest priority with `-t 15000`.
- preStartAdb opens Honda Settings, then Home (fixes the T270 Home-focus refusal).
- Collect-T280 pulls the head-unit logs first.

CODEX-T280.md: no BLOCKER.
- Applied:
  - generation token (one recorder per session)
  - scans bounded (baseline at onset, then at most 4 scans of 4 s or more per freeze)
  - at most 30 DURING lines per freeze
  - cpuBusy excludes iowait
- Accepted as is:
  - `true` on the hook is intentional (best effort). The template readiness check still verifies Home afterwards.
  - `logcat -t` implies -d on Android 4.x and later (UNVERIFIED on this unit). A failed or empty save is reported and never prunes older files.
  - PID-reuse misattribution within 4 s is negligible.
- Loop stopped.
