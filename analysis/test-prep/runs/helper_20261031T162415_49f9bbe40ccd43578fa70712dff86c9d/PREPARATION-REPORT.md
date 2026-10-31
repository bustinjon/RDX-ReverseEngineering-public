# Down-only probe — live preparation

## 1. Files inspected
Existing pinned Prepare-LiveTest.ps1/current artifact inputs; prior connection-failure output/inventory; generated current run evidence. Canonical offline scope/results: analysis/test-prep/down-motion-only-20261031/REPORT.md.

## 2. Files changed
New connection diagnostic/preparation/run evidence and this report; temporary authorized diagnostic APK installation, A11Y/helper/logger/watchdog state. No rebuild or new production input edit.

## 3. Commands run
Saved Prepare-LiveTest.ps1 initially failed get-state on two attempts. Saved Check-Connection.ps1 reported zero attached ADB devices. User explicitly corrected the connection. `pwsh -File analysis/test-prep/down-motion-only-20261031/Prepare-LiveTest.ps1` then completed; polling retrieved output. No ADB server restart or added Home polling loop.

## 4. Tests run and results
Successful preparation exited0: READY with168seconds remaining. Existing target/firmware/readiness/current-source/installed-hash/A11Y/logger/watchdog/capture requirements passed as enforced by the procedure. Down-only behavior test remains PENDING.

## 5. Findings
The pinned Down-only APK is installed and the capture-armed next session is prepared. It consumes raw146's synthetic key pulse while retaining pad motion, other controls and the B declaration; B-zone is unarmed. This is not a successful navigation/fix result.

## 6. Primary evidence for each finding
Connection errors/inventory retained under down-motion-only-20261031/retry-20261031-162159, retry-20261031-162249 and connection-20261031-162331. Current session.json/artifact-plan.json/final-readiness-check.json/final-ready.json bind installation and readiness. Expected installed SHA-256:28659795FC5228988FB56E0D006328DE0D13F65421560C27DFCEB28CDDF8367A. Detailed preparation path recorded in final-ready.json.

## 7. Assumptions
User's corrected connection continues the requested probe. Phone unplugged until READY; same phone/queue/other settings and stock-phone preference retained unless reported changed.

## 8. Unresolved uncertainties
Raw146 consumption/absent native93 in a running session, pad movement, preserved other controls, compact-row entry and repeatability require operator results and collected logs. Down-triggered screenshots may be fewer because the key consumer is not called. Root cause UNKNOWN; StaticAudit PENDING.

## 9. Exact diff summary
Generated diagnostic/session evidence/report and existing prepared installation steps only. No guard, native, manifest or production source changes in this live step; no old A/B selector invoked. No APK rebuild.

## 10. Preservation checks performed
Existing CurrentSource runner checks source/APK and installed identity. Offline report preserves27 inputs/fourteen previous/frozen artifacts; no repeat frozen hash audit in this live step. No key inspection, Git mutation, frozen rebuild, guard bypass or milestone action. Log retrieval and cleanup remain required after the operator test.
