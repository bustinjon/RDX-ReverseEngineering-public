# Profile A — collection result

## 1. Files inspected
Pinned session.json, existing collection template/procedure and returned collection evidence. User's result applies to this run. Detailed profile/build provenance remains in page-profile-ab-20261031/REPORT.md.

## 2. Files changed
New Collect-A.ps1/generated collector and run evidence/report. Temporary helper/A11Y/logger/watchdog cleaned up. No rebuild or new input implementation change; local source selection for subsequent B is separately recorded.

## 3. Commands run
`pwsh -File analysis/test-prep/page-profile-ab-20261031/Collect-A.ps1`. It reuses the established explicit-target procedure: pull logs first, cleanup, pull final evidence/private captures/installed APK, verify hashes and restoration. No new A test after collection.

## 4. Tests run and results
Collection exited0: logs,8 private captures and installed APK retrieved; cleanup verified, original A11Y restored, helper and owned logger/watchdog absent. Installed APK expected/matched C3EDC256281D1F923CD65785DB0C0FA6B5E36E182FD602194245B89DB5875DDF. Runtime input details still require the offline paired review.

## 5. Findings
Operator reports profileA still cannot reach Spotify's compact bottom playback row. Playlist navigation and Maps in the right third work. This is the A reference result, not a B outcome or a cause determination.

## 6. Primary evidence for each finding
collection.json stores the operator result, retrieved hashes/count and cleanup checks. postchecks.json/manual-cleanup.txt and evidence/image hash manifests retain returned state. session.json binds the run to A. Original captured log/private images remain local.

## 7. Assumptions
Operator statement applies to the A run just completed. No unreported general Select/Back success inferred. B is a separately prepared session.

## 8. Unresolved uncertainties
Exact focused node, event/frame timing, root cause and whether omitting advertised arrows changes the symptom remain UNKNOWN. StaticAudit PENDING. No interpretation of native return0 as phone focus success.

## 9. Exact diff summary
Only saved collection script substitutions (A run ID/operator statement) and generated evidence/report. No guard, native, manifest, frozen artifact or production-policy edit during collection.

## 10. Preservation checks performed
Installed APK identity matches pinned A; initial/final logs/private images hashed; baseline A11Y and owned-process cleanup verified by collector. No key inspection, frozen rebuild, Git mutation, guard bypass or milestone action. B installation can proceed only through its separate pinned workflow/readiness gate.
