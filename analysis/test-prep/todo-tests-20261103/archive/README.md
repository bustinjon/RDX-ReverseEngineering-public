# Archived car-test bundles

Moved 2026-11-08: every bundle before T170. Moved 2026-11-10: T170-T290, their Start/Collect launchers, Recover-T240-interrupted.cmd and the one-off T240 tools (tools/Build-T240.ps1, Finalize-, Prepare-, Recover-T240Interrupted, Validate-, Verify-T240Package). Each folder keeps its source overlay, RESULT.md (where tested), build reports and operator evidence folders. Nothing was changed apart from the move.

Kept in builds/:
- B-current-baseline: the baseline package
- T24-volume-android: referenced by baseline-source/baseline.json and the Save-Baseline command
- T300 (daily build since 2026-11-10) and T310 (current)

To rerun an archived test, move its folder back to builds/ and its .cmd files back to the suite folder (the tools look for tests under builds/). The archived T240 tools expect their original tools/ location.
