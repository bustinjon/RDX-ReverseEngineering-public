# Archived car-test bundles (moved 2026-11-08)

All bundles before T170 and their Start-/Collect-*.cmd launchers. Each folder keeps its source overlay, RESULT.md (where tested), build reports and operator evidence folders. Nothing was changed apart from the move.

Kept in builds/:
- B-current-baseline: the baseline package
- T24-volume-android: referenced by baseline-source/baseline.json and the Save-Baseline command
- T170 and T180: the current bundles

To rerun an archived test, move its folder back to builds/ and its .cmd files back to the suite folder. The tools look for tests under builds/.
