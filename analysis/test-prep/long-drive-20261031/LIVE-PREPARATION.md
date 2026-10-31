# Untimed handoff preparation — 2026-10-31 17:39 UTC

## 1. Files inspected

PROJECT-RULES.md; NEXT-DRIVE.md; Prepare-LongDrive.ps1 and its timed stage; CarTest.Core.ps1; the failed-run command journal, cleanup, pulled device files, process/settings dump and target logcat help; successful run session/installed APK/readiness/proof metadata.

## 2. Files changed

Prepare-LongDrive.ps1, configure-untimed.sh; new one-time recovery/inspection scripts (now retired with a refusal at entry); live evidence directories and this report. App Java/APK code unchanged.

## 3. Commands run

Saved procedures: Prepare-LongDrive.ps1 (initial failure and final success), Resume-PreparedHandoff.ps1 (failed handoff), Inspect-FailedHandoff.ps1 (pull then owned cleanup), Validate-LongDrive.ps1, Finalize-LongDrive.ps1. Explicit head-unit serial only, through saved scripts. Read-only Get-Content/rg/Get-ChildItem inspected saved results. No Git operation or additional app feature work.

## 4. Tests run and results

Offline validator PASS: 27 unchanged Java inputs, seven identical public APK payload entries, 15 artifacts preserved, nine simulated watchdog fixtures, PS/shell syntax and artifact-plan checks. Final preparation PASS: installed APK matches D1A29B34812B2C3188C57C840DB1DE4F44E1362FF8BD8E3D9A52B1317EDABCE4; ordinary readiness completed; helper and permission service present; own timer absent; rotating logger and health monitor live. AA phone connection and long-drive stability remain PENDING.

## 5. Findings

First attempt installed correctly but wrapper failed reading an unset LASTEXITCODE under the core's strict mode. Corrected to check script invocation success. One recovery attempt disarmed its timer, then the nested shell diagnostics setup exceeded the host timeout; its logs and first memory sample prove diagnostics did start, but the reason the invocation did not finish is UNKNOWN. Evidence was pulled and own cleanup executed. Detached starts now use separate top-level shell calls matching the existing runner. A fresh preparation completed successfully. No timer remains scheduled for this successful run.

## 6. Primary evidence

Initial failure: `live-20261031-173443/failure.txt` and `timed-stage-output.txt`. Failed recovery: `live-20261031-173605/failure.txt`; failed run `analysis/test-prep/runs/helper_20261031T173455_b5fb5a9ca2e24ea2a405626606641b6b/commands.jsonl`, `failed-handoff-evidence/`, diagnostic and cleanup files. Successful evidence: `analysis/test-prep/runs/helper_20261031T173855_e72a6103b88a4bdc815a3e210f2c4f69/longdrive-session.json`, `untimed-live-proof.txt`, `watchdog-disarm.txt`, `session.json` and `commands.jsonl`. Authoritative mode is longdrive-session.json, superseding the timed stage's historical final-ready.json.

## 7. Assumptions

User's current message authorizes this prepared long-drive installation/handoff and confirms Home. Only existing required readiness checks were performed. Prior per-phone Honda Disable and USB procedure remain applicable.

## 8. Unresolved uncertainties

Phone AA connection, multi-hour operation and final manual collector remain unverified in this run. Failed attempt's cleanup reported settings no longer equal to its own write; it preserved that condition instead of overwriting. Final run recorded its actual baseline independently. No claim that the failed attempt's baseline was restored follows from its cleanup acknowledgment alone.

## 9. Exact diff summary

Wrapper status check changed from unset LASTEXITCODE access to invocation success; detached logger/monitor launches moved from nested configure shell to the established top-level launch pattern. Configure shell now prepares the log transition only. App input/audio/native behavior unchanged. Recovery-only scripts are blocked from future replay. New evidence, no historical report rewritten.

## 10. Preservation checks

Final source/APK/artifact checks recorded by final-preservation.json. All 27 Java inputs and 15 prior artifacts retained. No frozen artifact rebuilt, M5 guard modified, milestone advanced, key read, or Git write performed. Successful run remains intentionally active for the user-requested untimed handoff; cleanup is manual after the drive.
