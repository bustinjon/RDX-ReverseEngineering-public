# Absolute-off candidate — live preparation

## 1. Files inspected
Existing pinned `analysis/test-prep/pad-absolute-off-20261031/Prepare-LiveTest.ps1` and its runner inputs/evidence. Canonical build/scope checks: that directory's REPORT.md and validation.json. Current device observations are saved by the existing procedure, not separately repeated.

## 2. Files changed
Generated run/preparation evidence and this report; temporary authorized device installation/services/A11Y/logging/watchdog state. No production code or APK rebuilt.

## 3. Commands run
`pwsh -File analysis/test-prep/pad-absolute-off-20261031/Prepare-LiveTest.ps1`, then polling its completion. No additional Home checks were run outside that existing procedure. Device commands and outputs are saved in the run/preparation evidence referenced by final-ready.json.

## 4. Tests run and results
Preparation exited0: READY,168 seconds remained at completion. The existing procedure requires artifact/source/installed hash verification, target/firmware identity, readiness, A11Y, logger/watchdog and fresh B-zone/capture arm acknowledgements. Operator behavior result PENDING.

## 5. Findings
The A58A absolute-off candidate is installed and the session preparation completed. Actual runtime pad registration and Spotify/Maps behavior must still be checked in collected test evidence. No repair declared.

## 6. Primary evidence for each finding
session.json/artifact-plan.json identify the pinned candidate and installation; final-readiness-check.json and final-ready.json record the procedure's readiness/arm confirmations and remaining time. final-ready.json identifies the directory with detailed preparation output. Expected installed SHA-256: A58A391BBC2A855E91F472403045490816E02598C5EBA09410EE85DCB078FA73.

## 7. Assumptions
User's ADB-connected/Home statement authorizes this prepared comparison. Phone remains unplugged until READY and previous stock-phone preference/audio setup is retained unless reported changed.

## 8. Unresolved uncertainties
Runtime `nav=true abs=false`, phone interpretation, Spotify lower-control access, Maps/grid/Select/Back preservation and repeated widget entry remain UNKNOWN. Watchdog time begins during preparation. StaticAudit PENDING.

## 9. Exact diff summary
No production or guard change. Existing preparation script executed as saved; no added Home verification loops. New run/preparation evidence and this report only, plus the procedure's temporary device state.

## 10. Preservation checks performed
Existing runner verifies artifact/source and installed APK identity. Earlier offline build report preserves27 inputs and10 prior/frozen artifacts; frozen hashes were not separately rechecked in this live step. No key inspection, Git write, frozen rebuild, guard bypass or milestone action. Log collection and cleanup still required after the user test.
