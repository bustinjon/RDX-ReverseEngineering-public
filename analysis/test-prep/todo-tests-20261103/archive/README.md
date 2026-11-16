# Archived car-test bundles

Moved 2026-11-08: every bundle before T170. Moved 2026-11-10: T170-T290, their Start/Collect launchers, Recover-T240-interrupted.cmd and the one-off T240 tools (tools/Build-T240.ps1, Finalize-, Prepare-, Recover-T240Interrupted, Validate-, Verify-T240Package). Moved 2026-11-16: T24-volume-android and T300-T370 (wireless-AA freeze fixes, reboot-loop fix and the audio start-up work up to and including T370). Each folder keeps its source overlay, RESULT.md (where tested), build reports and operator evidence folders. Nothing was changed apart from the move.

Note: the baseline manifest (baseline-source/baseline.json) is self-contained - it hashes the parallel-aa-receiver source directly, so Build-Test/Switch-Source still restore the baseline after the move. Its baselineBuildReport pointer was repointed to archive/builds/T24-volume-android/build-report.json.

Kept in builds/:
- B-current-baseline: the baseline package
- T380 (current; audio start-up auto-flush, car-test pending)

To rerun an archived test, move its folder back to builds/ and its .cmd files back to the suite folder (the tools look for tests under builds/). The archived T240 tools expect their original tools/ location.
