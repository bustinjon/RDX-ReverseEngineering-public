# Down-only probe — collected result

## 1. Files inspected
Current session.json, collection.json, original fresh capture.log and returned cleanup/hash evidence. Previous collector template reused; canonical build/scope remains analysis/test-prep/down-motion-only-20261031/REPORT.md.

## 2. Files changed
New pinned collection/report scripts and generated run collection evidence, input-result.json and this report. Temporary device helper/A11Y/logger/watchdog cleaned up. No production edit or rebuild.

## 3. Commands run
`pwsh -File analysis/test-prep/down-motion-only-20261031/Collect-ThisTest.ps1`; `pwsh -File analysis/test-prep/down-motion-only-20261031/Save-Result.ps1`. Collector uses the established explicit-target/time-limited procedure: retrieve logs first, clean up, retrieve final evidence/private captures/installed APK, verify original settings and process absence. Result script reads only saved evidence.

## 4. Tests run and results
Collection exited0: logs,4 private captures and installed APK saved. APK matches pinned28659795FC5228988FB56E0D006328DE0D13F65421560C27DFCEB28CDDF8367A. Fresh boundary, baseline A11Y restoration, helper/logger/watchdog absence and cleanup completion verified. Original capture hash rechecked locally. input-result.json records raw146, native93/20, other key and pad counts and whether suppression was exercised; no new device test after collection.

## 5. Findings
Operator reports Right reaches Spotify's compact playback row, but after moving Up, Down cannot return. The target return-path criterion therefore remains failed by operator report. If input-result.json confirms raw146 without native93/20 and other live input/pad activity, the requested suppression ran and withholding that pulse alone was insufficient. Do not infer repair or a specific phone-side defect from local return codes.

## 6. Primary evidence for each finding
collection.json retains operator result, APK/capture hashes,4 captures and cleanup assertions; postchecks.json/manual-cleanup.txt and saved evidence/image hash manifests preserve returned state. input-result.json records fresh boundary, runtime-marker line references, counts and the explicit exercised/not-exercised verdict. Native logs establish local submission only, not exact focused nodes. Original images/logs retained privately.

## 7. Assumptions
User's Right->Up->failed Down report refers to this installed probe. No inference about unreported playlist/Maps/Select/Back checks. No exact operator-action synchronization assumed.

## 8. Unresolved uncertainties
Exact focus history, focused button identity, gesture distances, phone interpretation, other live regression results and root cause remain UNKNOWN. StaticAudit PENDING. The result cannot distinguish all phone/input-contract explanations. Offline review no longer needs the car.

## 9. Exact diff summary
Only collection template substitutions (run/operator), saved result script and generated evidence/report. No input implementation, supported-key list, hover, native, manifest, guard, APK or historical evidence changes.

## 10. Preservation checks performed
Installed APK hash matches candidate; initial/final evidence and private images hashed; capture hash locally reverified; original accessibility restored and owned processes absent. No key inspection, new build, frozen artifact change, Git mutation, guard bypass, milestone advancement or external publication. SAFE TO DISCONNECT given only after successful collection/cleanup; no automatic re-arm or next test.
