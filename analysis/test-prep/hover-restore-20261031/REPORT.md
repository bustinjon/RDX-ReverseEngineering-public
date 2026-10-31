# Hover restore A build report

Built and signed offline. Not installed; hardware behavior remains UNKNOWN. Test procedure: [NEXT-TEST.md](NEXT-TEST.md). Machine-readable checks: [validation.json](validation.json).

APK: `analysis/parallel-aa-receiver/usb-helper/build/20261031-000234-450/rdx-usb-helper-v6h-hover-restore-a.apk`

SHA-256: `D404014AC8D4F58F2C79AA51DE8DF0D9146A80A801B1FC1AF8BA7A1B9511E612`.

## 1. Files inspected

AGENTS.md; PROJECT-RULES.md; current and preserved v5 AaOverlayService; effective InputEvents/InputSource/session source; prior observer build report; existing host tests; build and Prepare-mode runner; signature outputs; generated and packaged DEX; manifest/resources/native hashes; three prior APKs and four frozen anchors. Historical input evidence remains in the existing run directories; this report does not replace it.

## 2. Files changed

One production input: `analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/AaOverlayService.java`.

Added this preparation directory with prior source snapshot, baseline/policy/validation evidence, host test outputs/classes, packaged-DEX inspection output, report and test steps. The existing builder produced the new timestamped private APK/build outputs and updated `usb-helper/latest-build.txt`. Offline Prepare created `analysis/test-prep/runs/helper_20261031T040331_08271fcda90645c8a1eedcc1a0ee694b/artifact-plan.json`.

## 3. Commands run

Read-only Get-Content/rg/git status/source searches; baseline Copy-Item/Get-FileHash; the scoped overlay patch; JDK 17 javac/java for existing InputPcmTest and FocusCaptureBudgetTest; `scripts/Build-RdxUsbHelper.ps1 -Version v6h-hover-restore-a` through the established build/signing process; selected ZIP-entry inspection and SHA-256 comparisons; JADX CLI on only the extracted classes.dex; `scripts/Run-CarTest.ps1 -Mode Prepare -CandidateRole CurrentSource -SafetySeconds 180 -HondaStrategy PhonePreference` with a nonexistent ADB executable; Node source-policy/provenance checks. No device command, agent delegation or publication.

## 4. Tests run and results

- PASS: 25799 input/PCM checks and 10019 capture-budget assertions, saved in input-results.txt and capture-results.txt. Counts include repeated assertions, not independent scenario counts. These existing tests do not execute Android hover dispatch or prove AA movement.
- Policy check PASS: restored hover handler exactly matches the preserved v5 handler. The rest of the overlay source is byte-equivalent after normalizing line endings and replacing only the handler and diagnostic marker. Key dispatch, Select and window code are unchanged.
- All 27 Java inputs compile. New build provenance matches current source with zero differences; exactly one Java input differs from the pre-edit snapshot, AaOverlayService.java. The helper InputSource override remains the sole effective InputSource.
- API-22 v1 signature and alignment verification PASS through the existing builder; public signer digest matches v5. No signing material was printed or inspected by review tools.
- Packaged DEX matches generated DEX: `C7B637F103BC2899DC6C314A579E3D397CCFD3C85E72E3CBDBE8AF7EA332F6CF`. Packaged-code inspection confirms actual hover forwarding and the new marker; old key-only/hover-ignored markers are absent.
- APK manifest, resources and native library match the previous observer APK. Three previous APKs and four frozen anchors retain their recorded hashes.
- Offline Prepare PASS: CurrentSource, zero source differences; no device command invoked. StaticAudit remains PENDING. No new live result.

## 5. Findings

This candidate isolates the removal of hover forwarding while preserving the current explicit key path and working Select code. The current failed test had Up/Down/Back submissions reaching JNI; changing those key labels is not supported by evidence of a local mapping drop. The earlier Up failure predates observer additions.

The operator corrected the historical baseline: earlier Up/Down worked; Back was untested. Do not treat Back as a proven regression from that earlier version. The exact APK associated with the passing Up/Down observation remains UNKNOWN. V5 is a preserved comparison reference and already had a later, narrower lower-right Spotify Down defect.

The expected benefit from restoring hover is a hypothesis, not a confirmed fix. Restoring a second navigation path could also cause extra movement; the next test explicitly checks preservation of Left/Right/Select and normal-context Back before repeating the Spotify panel-return case.

## 6. Primary evidence for each finding

- before.json records all 27 pre-edit source hashes and seven preserved artifacts. prior-source-reference/AaOverlayService.java is the exact pre-edit observer source.
- policy-checks.json records the exact v5 hover-handler comparison and unchanged remaining overlay code. Compare the new source with `analysis/test-prep/directional-focus-20261030/prior-source-reference/AaOverlayService.java:148` for the older forwarding handler. source-change.patch records the controlled delta.
- `packaged-code/sources/com/rdx/fullscreen/usbhelper/AaOverlayService.java:146` shows the installed-candidate DEX handler invoking handleTouch with a copied/mapped MotionEvent and recycling it; line 161 contains INPUT_HOVER_RESTORE_V1. This is candidate inspection, not evidence of installation.
- The new build's build-report.json and signature-verification.txt record Java inputs, successful API-22 signing verification and public signer. validation.json independently records actual file/ZIP hashes, effective override, unchanged sources and preservation results.
- Prior failed capture: `analysis/test-prep/runs/helper_20261031T010702_42a9d5741bbb419bb451dcecae540d7b/device-evidence/capture.log:57850` (Up), :57987 (Down), :58674 (Back). Voice session begins at :58605 before all recorded Back attempts. Capture SHA-256: `758F6FC795AE691D07A4688BE2FB9F4A598BBDF08DE759B8AE0C308DDB7451B9`.
- Earlier directional-only retry evidence remains in `analysis/test-prep/runs/helper_20261031T002831_3108073116014a1d9a52966de9841a43/RESULTS.json` and its capture, fresh process 6848/run boundary 49984. It records the operator's Up failure before the observer build.

## 7. Assumptions

The next comparison will use the same phone/layout and one deliberate gesture at a time, from a UI position where that movement is possible. The operator will distinguish ordinary app navigation from voice/reminder UI. These assumptions require live observation; offline preparation does not establish them.

## 8. Unresolved uncertainties

Whether restoring hover repairs vertical movement, whether both motion/key paths produce duplicate movement, Back behavior in ordinary AA navigation, and persistence of the original Spotify panel-return defect. Phone-side handling after native submission remains UNKNOWN. Image capture stays opt-in and unchanged; whether it is armed must be recorded for the actual session.

## 9. Exact diff summary

Replace the VIDEO-mode hover suppression branch with the preserved v5 forwarding branch: require a listener, copy the MotionEvent, convert hover action to pad action, call existing handleTouch, and recycle the copy in finally. Change only the diagnostic policy marker to INPUT_HOVER_RESTORE_V1. No mapping, Select, focus/window, JNI, capability registration, geometry, audio, protocol lifecycle, capture or guard changes.

## 10. Preservation checks performed

validation.json confirms unchanged hashes for v5, directional A, observer A and all four PROJECT-RULES frozen anchors. Native library remains `031797DD4B0AECCA007A3AD7AF31C365BA3D47BEBDA8C94BFF13C5289F464C50`; manifest/resources and public signer match the prior artifacts. Only AaOverlayService differs among the 27 Java inputs. No historical report was rewritten; no ADB, car/phone access, Git mutation, public upload, guard bypass or milestone advancement occurred.
