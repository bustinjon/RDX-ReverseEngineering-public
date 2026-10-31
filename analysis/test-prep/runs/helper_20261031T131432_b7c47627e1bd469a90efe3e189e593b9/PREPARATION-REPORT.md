# B-zone candidate — live preparation only

## 1. Files inspected
PROJECT-RULES.md, pre-adb preflight.json, and the existing pinned Prepare-LiveTest.ps1. The runner reads candidate/build inputs and readiness evidence; see session.json, artifact-plan.json, final-readiness-check.json and final-ready.json in this run.

## 2. Files changed
Generated live-run/preparation evidence and this report. Installed the authorized diagnostic candidate and started temporary test services/capture/watchdog through the existing runner. No source/APK rebuild.

## 3. Commands run
Get-Content of rules/preflight; `& analysis/test-prep/bzone-keys-20261031/Prepare-LiveTest.ps1`; polling its completion. Device commands are contained in that saved script and the existing Run-CarTest.ps1 runner; detailed output is in the preparation evidence path recorded by final-ready.json.

## 4. Tests run and results
Preparation command exited 0: READY, 168 seconds remained at completion. Existing runner/outer script require target identity/firmware, five-second stable Honda Home with inactive lock-task, candidate/installed hash, temporary A11Y, logging/watchdog and fresh B-zone/capture arm acknowledgements. This is preparation success, not input behavior success.

## 5. Findings
The pinned candidate is installed and the next video session is armed for the B-zone experiment and private capture. The hardware test result remains PENDING.

## 6. Primary evidence for each finding
session.json and artifact-plan.json identify the run/candidate. final-readiness-check.json records the final Home/lock-task sample. final-ready.json records installed hash, both arm confirmations, remaining watchdog time and the preparation evidence directory. Raw runner output is retained there.

## 7. Assumptions
User's connected-on-Home message continues the explicitly requested diagnostic test. Phone remains unplugged until the READY cue; prior stock-phone preference configuration is retained unless reported changed.

## 8. Unresolved uncertainties
Actual B-zone UP delivery, Spotify lower-control focus, preserved main-pad behavior on this APK and behavior after widget return require operator results plus collected logs. Watchdog time is measured from preparation, not phone connection. StaticAudit remains PENDING.

## 9. Exact diff summary
No production code, native, manifest, frozen artifact or guard edit. New generated session/preparation evidence and this report; temporary device state changes only through the existing authorized preparation procedure.

## 10. Preservation checks performed
Existing runner verifies current candidate source/artifact and installed hash. Prior offline preflight verified all 27 Java input hashes and nine preserved artifacts; these frozen hashes were not rechecked in this live step. No Git mutation, key inspection, frozen rebuild, milestone advancement or guard bypass. Cleanup/log retrieval are still required after the operator test.
