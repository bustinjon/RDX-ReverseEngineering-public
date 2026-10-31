# Car-test preparation: helper_20261029T194340_120f2cc7c14848b38620f43f1903a0a4

**OFFLINE PREPARED. No connected test has started.** The next dependency is the laptop connected to the head unit by ADB, with the phone unplugged from the car. Local preparation used the explicit historical APK baseline and the corrected runner.

**Purpose of one proposed attempt:** determine whether the selected helper acquires verified permission and opens its USB transport with the corrected setup. Record later protocol/video stages separately if reached. This helper automatically starts projection after permission; it is not an isolated M5 permission harness.

The user requested preparation and notification when ADB is needed. [AGENTS.md](../../../../AGENTS.md) still says, “Never run `adb`, `fastboot`, or anything that touches a car, phone or USB device.” No override has been assumed. ADB connection and explicit authorization for this helper test are required before this agent performs connected work. [PROJECT-RULES.md](../../../../PROJECT-RULES.md) remains unchanged; no milestone is advanced.

## 1. Files inspected

Project rules; the corrected runner; its [implementation/test report](../../../agent-reviews/codex-20261029-car-test-runner-fix.md) and saved validation; latest helper build pointer/metadata; the observation template. Hashed the five implementation/test files, four frozen anchors, and saved final test results.

## 2. Files changed

Only this new preparation directory: `artifact-plan.json`, `preflight.json`, `observations.json`, and `RUNBOOK.md`. No existing source, script, APK, historical evidence, or project instructions edited.

## 3. Commands run

Local reads, `git status --short`, `Get-FileHash`, JSON parsing, and `Run-CarTest.ps1 -Mode Prepare` with an explicit APK/hash, `HistoricalBaseline`, and an intentionally nonexistent device-tool path. The Prepare branch returned without invoking any device executable. The real SDK executable was checked for local file existence only.

## 4. Tests run and results

- Fresh artifact preparation: PASS. Exact inputs and source differences are in [artifact-plan.json](artifact-plan.json).
- Five implementation/test hashes match the previously validated revision.
- Saved final simulation result matches its recorded hash: 34 PASS, 0 FAIL. The suite was not repeated because its inputs are unchanged.
- Four frozen artifact hashes match.
- PowerShell 7.6.9 is available; the configured SDK device-tool file exists.
- No hardware readiness, installation, permission, USB, decoder, or cleanup result is claimed.

## 5. Findings and proposed sequence

Selected APK SHA-256:

`C7943B4FD9194E6AAD3E2C28AE68F880519D8EC624148AA794FBE9CA97F80757`

The baseline's `AaSessionService.java` and `VideoDecoder.java` recorded hashes differ from current source. Its audit remains PENDING. This attempt would evaluate the known binary with the corrected runner; it would not validate the newer unbuilt app changes or v6h.

Once connection and the scoped authorization are established:

1. Start with read-only head-unit checks: confirm target serial `00000000`, installed helper identity, current user/UI and lock-task context, accessibility state, and any prior helper/test processes or timers. Preserve relevant pre-existing evidence. Connection alone must not trigger the runner's Live branch.
2. Assess those results against project restrictions and the candidate selection before installation or startup. The helper runner's checks do not replace the M5 readiness guard.
3. For an authorized attempt, the runner binds every operation to the head unit, verifies installed bytes, prepares capture and fresh service/binding evidence, starts bounded cleanup, and refuses inadequate timing windows.
4. Keep the phone unplugged until the runner actually reports READY. Its minimum remaining windows are 30 seconds to cleanup and 15 seconds for the Honda loop; displayed values are estimates at the readiness sample.
5. Record the first failing stage. Verified permission, transport open, discovery, video selection, decoder start, render report, and physical image observation are distinct outcomes.
6. Preserve capture/watchdog/session evidence, assess cleanup, and stop after the attempt. Do not infer permission for a retry, another milestone, or an app replacement.

Planned safety timer: 60 seconds. No timer is currently running. The actual connected run will generate its own session directory and run ID; this directory is the preparation reference. [observations.json](observations.json) has the known candidate fields filled, with all live outcomes still UNKNOWN and `status=NOT_RUN`.

## 6. Primary evidence for each finding

- [preflight.json](preflight.json): fresh hash comparisons, saved-test hash, local runtime/file checks, and actual Prepare output.
- [artifact-plan.json](artifact-plan.json): exact APK SHA, build-report SHA, recorded-input differences, and PENDING audit.
- [Final offline test results](../../runner-fix-20261029/tests-final/results.json): 34 passing simulations, not live evidence.
- [Runner](../../../../scripts/Run-CarTest.ps1):5–12 mandatory selection/default mode; 23–28 offline return; 53–57 live readiness output.
- [Core](../../../../tools/car-test/CarTest.Core.ps1):126 onward connected preparation, installed-byte verification, timing, cleanup, and evidence recording.
- [AGENTS.md](../../../../AGENTS.md): device prohibition; [PROJECT-RULES.md](../../../../PROJECT-RULES.md): milestone and guard boundaries.

## 7. Assumptions

The request continues the selected historical helper-baseline experiment. It authorizes local preparation, not an implicit override of the supplied device-access prohibition. The target remains the same head unit; no phone/head-unit connection has been probed.

## 8. Unresolved uncertainties

UNKNOWN: connection/authorization, installed APK, UI/lock-task state, accessibility binding, old timers, USB defaults, phone preference, and all live outcomes. Actual command/output parity and watchdog/cleanup behavior still require connected validation. The two app-source differences remain unbuilt.

## 9. Exact diff summary

Four new preparation files; zero existing files edited or removed; zero Git staging/commits. No executable auto-start launcher was added. The observation file separates this preparation ID from the future live run ID.

## 10. Preservation checks performed

The five corrected implementation/test files and all four frozen anchors match their recorded SHA-256 values. APK verification passed against the explicit candidate hash. Prior worktree modifications were preserved. No ADB/fastboot command, device-facing script body, build/signing operation, credential read, or milestone action occurred.
