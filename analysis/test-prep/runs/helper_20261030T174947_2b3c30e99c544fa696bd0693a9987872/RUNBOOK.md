# New car-test preparation — 2026-10-30

**Local preparation complete. ADB is needed next.** The head unit is currently disconnected, as reported by the user. No device command was attempted during this turn. Prior explicit authorization to use ADB for this helper test remains applicable.

## 1. Files inspected

Project instructions; corrected runner/core/tests; the last failed session and its command journal; the saved API22 shell probes and previous test results. Review focuses on the cutoff run, not a new app implementation.

## 2. Files changed

Updated `tools/car-test/CarTest.Core.ps1` and `tools/car-test/Test-CarTestOffline.ps1`. Added `tools/car-test/fixtures/api22-service-response.json`, containing the captured service response. Added this packet's `artifact-plan.json`, `review-and-validation.json`, and `RUNBOOK.md`; new simulation evidence is under `analysis/test-prep/runner-fix-20261030/tests-pty/`.

## 3. Commands run

Local `Get-Content`, `Get-FileHash`, JSON inspection, PowerShell parser checks, the offline test suite, and the runner's `Prepare` branch with an intentionally nonexistent device executable. Git Bash `-n` parsed shell sources and generated cleanup without executing their bodies. No ADB/device command this turn.

## 4. Tests run and results

**38 PASS, 0 FAIL.** Includes the exact captured response replay, complete simulated setup with ordinary CRLF and doubled-CR output, existing refusal paths, and capture-cleanup scoping checks. Three PowerShell files and three shell files parse successfully. Fresh local artifact preparation passed. Four frozen hashes match.

See [review-and-validation.json](review-and-validation.json) and [test results](../../runner-fix-20261030/tests-pty/results.json). These are local checks; hardware readiness remains unestablished.

## 5. Findings and prepared attempt

The last run, [helper_20261029T200753](../helper_20261029T200753_d9606d74d1d447c5a239fb0bdf086b9c/session.json), stopped at accessibility parsing. Its raw response contains an active `PermissionClickService` at PID **9135**, with a received binder and `hasBound=true`. The parser rejected it because the legacy ADB PTY emitted **CR CR LF** and the active-section regular expression expected CRLF or LF. This is a runner compatibility failure; it does not establish a permission or decoder failure.

The shell-response boundary now normalizes carriage returns before parsing while preserving the raw command journal. Replay of the exact response now yields PID 9135. No readiness check was removed.

Earlier compatibility corrections remain in place: `echo` replaces unavailable `printf`; background launches ignore HUP before starting external executables. Those corrections had live shell-probe evidence in the previous turn; the new tests cover the current code.

The failed run recorded helper/settings cleanup commands without a recorded cleanup error. It did not stop its capture logger. Current logger/device state is **UNKNOWN** while disconnected. Cleanup now attempts to stop only the capture PID whose command line contains the unique session capture path; a PID mismatch is refused. The generated deadline cleanup includes that capture shutdown too. Runtime behavior of this new cleanup remains to be checked.

The selected APK remains the explicit historical baseline:
`C7943B4FD9194E6AAD3E2C28AE68F880519D8EC624148AA794FBE9CA97F80757`.

Two recorded Java inputs differ from current source; audit is PENDING. No app rebuild occurred. This helper automatically starts projection after permission; this is not an isolated M5 harness.

On reconnection:

1. Confirm serial 00000000 and current Home/UI state. Requalify the lock-task getter against the reviewed framework hashes before using it if firmware identity has changed.
2. Inspect the old session's owned capture under `/data/local/tmp/rdx_afba33165b0c4a2cad473919dafd4c77`. Preserve evidence and stop only the verified owned logger. Check for helper/test processes and timers.
3. Confirm restored settings/current installed APK. No current state is inferred from yesterday's cleanup record.
4. Start a fresh setup only after those checks. Keep the phone unplugged until an actual READY cue. The test keeps its 60-second cleanup timer and minimum remaining-window checks.
5. Record permission, transport, protocol, decoder, and visible image separately; retrieve evidence and check cleanup after the attempt.

The new preparation ID is this directory's name. An actual connected attempt will get a separate run ID. No timer or phone test has been launched by this packet.

## 6. Primary evidence for each finding

- Prior [session.json](../helper_20261029T200753_d9606d74d1d447c5a239fb0bdf086b9c/session.json): FAILED at accessibility, cleanup attempted, no recorded cleanup error.
- Prior [commands.jsonl](../helper_20261029T200753_d9606d74d1d447c5a239fb0bdf086b9c/commands.jsonl): raw doubled-CR service output, PID/binder details, and cleanup commands.
- [Captured fixture](../../../../tools/car-test/fixtures/api22-service-response.json): exact response retained for repeatable local replay.
- [Core](../../../../tools/car-test/CarTest.Core.ps1): `Invoke-CTShell` normalizes parser input; `New-CTStopCaptureText` checks PID identity; catch path records capture cleanup attempts/errors.
- [Artifact plan](artifact-plan.json): exact APK/build hashes, role, source differences, and audit status.
- [Validation](review-and-validation.json): current code hashes, test result hash, and preservation comparisons.

## 7. Assumptions

The user wants a fresh helper-baseline attempt after reviewing the cutoff. Their prior explicit ADB authorization persists. Their latest message establishes that the car is disconnected; connection has not been probed.

## 8. Unresolved uncertainties

Current connection, Home/lock-task state, installed app, settings, old capture state, actual service callback readiness, and all phone-test outcomes are UNKNOWN. The next connection must verify them. No READY or phone-test start was recorded in the cutoff session.

## 9. Exact diff summary

Two existing runner/test files updated: newline normalization, scoped capture cleanup, and four additional regression checks. One captured-response fixture added. New packet and test evidence added. No app source, APK, project instructions, historical log/report, M5 guard, or milestone state edited.

## 10. Preservation checks performed

All four frozen anchors match. The 261 original-inventory files outside the two previously authorized runner/shell edits remain unchanged; no unexpected original-inventory changes. The selected APK hash is unchanged. No key material was read, no builds/signing or device actions occurred, and nothing was staged or committed.
