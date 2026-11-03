# Rollback to last car-tested source/APK — 2026-10-31

## 1. Files inspected

PROJECT-RULES.md; media candidate/baseline records, Maps-only and long-drive candidate metadata, verified pre-change source snapshots; current builder source-selection rules and existing readiness preparer/parser. Canonical shortcut evidence remains in `analysis/agent-reviews/diagnostic-shortcut-20261031/REPORT.md`.

## 2. Files changed

Restored GalReceiver.java, InputEvents.java, AaOverlayService.java and AaSessionService.java to the selected long-drive candidate's exact hashes. Moved VolumeFeedback.java out of the production tree into this directory's saved-media-source/. Added rollback scope, snapshots/provenance, verification and install-only test preparation. No artifact rebuilt, manifest/native/guard edited or device action taken.

## 3. Commands run

Saved Restore-TestedBaseline.ps1, Generate-InstallComparison.ps1 and Verify-Rollback.ps1; read-only source/metadata inspections and SHA-256 comparisons. The restore invokes `Run-CarTest.ps1 -Mode Prepare -CandidateRole CurrentSource` with a nonexistent ADB path as an offline artifact check only. Copy-Item/Move-Item preserve the newer implementation; paths are resolved and constrained to the workspace. No git checkout/reset/revert/commit/push and no device command.

## 4. Tests run and results

Exact effective source inventory:27 Java inputs, all hashes match D1A29… candidate. Five newer source files retained with hashes matching A2F478… metadata.18 prior/frozen artifacts and six guard/runner files unchanged. Existing selected APK hash intact; offline CurrentSource plan PASS. Generated install-only script and all rollback PS scripts parse; no helper-start or accessibility-write action appears in the installer. No new behavior tests were needed for byte-identical restored source; prior candidate evidence is reused. Hardware rollback outcome remains UNKNOWN.

## 5. Findings

The selected baseline is the last actually car-tested long-drive APK, not the intermediate uninstalled Maps-only APK. SHA-256 **D1A29B34812B2C3188C57C840DB1DE4F44E1362FF8BD8E3D9A52B1317EDABCE4**. Its old container is reused exactly, avoiding a rebuild as an additional variable.

This restores the older six-key/down-motion probe profile and removes the new media adapter/HUD/absolute-mode attempt. The untested request-dependent Maps navigation-focus change is also rolled back for a clean prior-build comparison. All newer code and APKs remain available. Earlier functional limitations are expected in this baseline; the first test is manual Diagnostics access with the helper stopped.

Local rollback is complete; **the car still has the newer installed APK until the later authorized installation**. The new installer is deliberately install-only, with existing normal Home/lock-task/firmware checks retained. It does not arm the receiver, enable the auto-clicker, alter global/OEM settings or clear package data. Installation/reinstallation can itself change transient state, so success alone would not isolate one feature as the cause.

## 6. Primary evidence

candidate.json and rollback-result.json pin the selected APK and four source restorations. verification.json records the exact27-input inventory and preservation results. saved-source-hashes.json and saved-media-source/ preserve all five newer files; their hashes are checked against the media candidate. offline-artifact-plan.txt records a successful device-free artifact selection. installer-provenance.json records the original readiness segment retained from the prior preparer. Original prior evidence remains in the long-drive run helper_20261031T173855_e72a6103b88a4bdc815a3e210f2c4f69/; no old report was rewritten.

## 7. Assumptions

User's request to revert and retest authorizes restoring the complete change bundle since the last car-tested build. It does not imply a current ADB connection after the explicit disconnect. A future ADB confirmation in this test context permits installing the exact baseline and checking the manual shortcut before receiver activation.

## 8. Unresolved uncertainties

Whether rollback restores manual Diagnostics is UNKNOWN. A stale OEM state could survive installation or be reset by it, so either result must be recorded without overclaiming causality. The exact prior manual shortcut trigger was not instrumented; the user reports earlier normal operation and repeated sufficient holds during the failure. The install-only procedure has offline syntax/provenance checks, not a live run yet. Current general host tests for the newer media profile are not baseline tests and should not be represented as passing against reverted sources.

## 9. Exact diff summary

Four production files restored byte-for-byte from hash-verified pre-change snapshots; one newly added production source archived outside the effective build tree. Other23 recorded production inputs unchanged. New rollback analysis/test preparation only. No new APK, change to latest-build history, user data clear, OEM reset or Git mutation. Source working-tree changes are intentionally unpublished while Git updates are paused.

## 10. Preservation checks performed

Five newer source files match A2F478… recorded hashes in their archive. A2F478…,21037…,D1A29… and all earlier preservation artifacts remain intact (18 total), as do six shared guard/runner files. Selected source matches its exact27-input build record and old APK hash. No credential entry opened, signing key read, frozen rebuild, guard bypass, milestone advancement, ADB/USB/car/phone operation or Git publication occurred.
