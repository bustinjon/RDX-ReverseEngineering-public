# Absolute-off comparison — collected result

## 1. Files inspected
Existing previous Collect-CurrentTest.ps1 template; current run session.json, collection.json, capture.log and cleanup/postcheck evidence. Readiness/build evidence remains in PREPARATION-REPORT.md and analysis/test-prep/pad-absolute-off-20261031/REPORT.md.

## 2. Files changed
New Collect-ThisTest.ps1, generated Collect-CurrentTest.ps1 and Save-CollectionReport.ps1 under the candidate preparation directory; current run's collection evidence, input-result.json and this report. Temporary device test state cleaned up. No source or APK change.

## 3. Commands run
Saved-file execution: `pwsh -File analysis/test-prep/pad-absolute-off-20261031/Collect-ThisTest.ps1`; `pwsh -File analysis/test-prep/pad-absolute-off-20261031/Save-CollectionReport.ps1`. Collector reuses the existing explicit-target/time-limited ADB procedure with only run ID and operator text changed. It pulls run logs first, then performs cleanup and final evidence/hash/state verification. Reporting reads local files only.

## 4. Tests run and results
PASS: logs retrieved before manual cleanup; eleven private captures and installed APK retrieved; installed APK matches A58A391BBC2A855E91F472403045490816E02598C5EBA09410EE85DCB078FA73; fresh run boundary; baseline accessibility restored; helper, logger and watchdog absent. Runtime pad registration uniquely confirms `nav=true abs=false`. Capture hash rechecked locally. Native key counts/results are recorded in input-result.json; local return values do not prove phone focus changes.

## 5. Findings
Operator reports Down navigation works inside the Spotify right-third menu/playlists, while the lower-right previous/next playback controls remain unreachable. The candidate really requested the false flag in its active session, so changing this flag alone did not resolve the target symptom in this test. This does not establish that menu navigation improved: the earlier menu baseline was not measured. Other controls were not explicitly reported for this run. Root cause remains UNKNOWN; failure depends on the particular control region, not simply every Spotify Down interaction.

## 6. Primary evidence for each finding
collection.json retains the operator statement and collection/cleanup results; input-result.json records the original capture hash, fresh boundary, exact runtime registration line and key counts. Original logs/captures, postchecks.json, manual-cleanup.txt and saved hashes remain in this run. Existing candidate scope/build report proves the intended one-boolean source change; retrieved installed APK hash matches it. No exact operator-action-to-focus synchronization is claimed.

## 7. Assumptions
User's reported menu/control behavior belongs to this prepared run. The user requested log collection; no additional car test or source change was authorized or started. Do not assume the exact pad used where it was not separately reported in this run.

## 8. Unresolved uncertainties
Phone-side media-card focus structure, absolute/gesture interpretation beyond the requested registration, interaction with pad/key streams, exact action timing, and root cause remain UNKNOWN. No global movement/Select/Back regression verdict can be inferred from unreported controls. StaticAudit PENDING.

## 9. Exact diff summary
Only new saved collection/report scripts and generated run evidence. Collector substitutions: latest run ID plus operator result; no readiness/cleanup logic changes. Production code, APK, native, manifest, frozen artifacts and historic reports unchanged.

## 10. Preservation checks performed
Installed APK identity verified against the pinned candidate; initial/final run evidence and private capture hashes saved; original capture rehashed; baseline accessibility and owned-process cleanup verified. Frozen artifacts were not rehashed or modified in this collection step. No key inspection, build, Git mutation, guard bypass or milestone action. Private captures retained locally. SAFE TO DISCONNECT given only after successful collection/cleanup. No reconnection needed for this offline review.
