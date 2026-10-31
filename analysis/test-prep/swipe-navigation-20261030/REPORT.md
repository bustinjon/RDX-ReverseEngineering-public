# Swipe navigation candidate preparation

Built/signed/locally verified, hardware pending. No device commands run. See [NEXT-TEST.md](NEXT-TEST.md) for the complete phone-connection instructions and exact hypothesis.

## 1. Files inspected

PROJECT-RULES.md; effective helper InputSource/InputEvents and existing overlay key dispatch; host InputPcmTest; factory current ProjectionActivity swipe handlers and GalIntegration supported-key list; v5 build metadata; last lower-right failure report and capture-derived statistics; existing artifact planner/PhonePreference requirements.

## 2. Files changed

- `analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/InputEvents.java`
- `analysis/parallel-aa-receiver/usb-helper/source/com/google/android/projection/protocol/InputSource.java`
- `tools/car-test/InputPcmTest.java`
- New test plan, validation/results/provenance files and exact original-source reference copies in this directory; new private helper build and offline prepared artifact plan.

No overlay, geometry, audio, lifecycle, watchdog, native library, private/public existing APK, original .gitignore, public snapshot or Git history changes.

## 3. Commands run

Local source inspection; JDK 17 host javac/java; existing Build-RdxUsbHelper.ps1 with label v6h-swipe-navigation-v6 using the previously authorized local signing process; source/APK/DEX/frozen hash checks; packaged DEX marker check; Run-CarTest Mode Prepare with deliberately nonexistent ADB path. No key material contents printed or read by review tools; no ADB, Git or publication command.

## 4. Tests run and results

- **PASS: 25805 input/PCM assertions**, results.txt. Includes existing PCM/focus/click tests, four OEM mappings, recorded swipe+DPAD sequence preservation, supported-key coverage, uniqueness and fresh-array isolation. Count includes repeated per-byte assertions.
- All 25 Java inputs compiled. Current sources match recorded build inputs: zero differences.
- Source comparison to v5: exactly the two production files listed above changed.
- API-22 signature and alignment checks passed. Packaged DEX matches generated DEX and contains KEYSET_OEM_SWIPE_V1.
- Public signing-certificate digest matches v5, and packaged native-library SHA-256 matches v5 exactly.
- V5 APK and four frozen anchors unchanged. Original two v5 source references independently match v5 build hashes.
- StaticAudit remains PENDING. JNI behavior, paired physical gesture delivery, focus movement and Spotify reachability have not been tested on hardware.

## 5. Findings

Factory source establishes four missing swipe mappings and explicit registration. The candidate restores these while preserving DPAD and select handling. The prior v5 failure is not proven to have this cause; this is a controlled compatibility experiment. No coordinate scaling or resolution change is justified by the available failure evidence.

## 6. Primary evidence

- Factory `decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/ui/ProjectionActivity.java:2308–2326`: 146→93, 148→122, 150→123, 152→92.
- Factory `.../integration/GalIntegration.java:108–115`: append 92,93,122,123 to registered keys.
- Helper InputEvents.java:5–19 implements mapping/filter/list; helper InputSource.java:65–66 registers it and emits KEYSET_OEM_SWIPE_V1.
- Last v5 failure: `analysis/test-prep/runs/helper_20261030T234615_99356193e031448eb0d3fb4ebd9b5be9/RESULTS.json` records full pad bounds, 28 successful Down pairs and lower-right operator failure.
- validation.json: candidate APK `analysis/parallel-aa-receiver/usb-helper/build/20261030-200012-348/rdx-usb-helper-v6h-swipe-navigation-v6.apk`, SHA-256 `2EF2FB9AAB41446D57D942E3F155F337E08D71282A85F8E148651B2A2B36FD03`, source scope/provenance and preservation checks. results.txt records actual host output.

## 7. Assumptions

The same OEM swipe events and Spotify layout can be reproduced on the RDX. No assumption is made that native key acceptance means correct UI focus or that a single physical swipe should be deduplicated into one specific key event; compare with observed behavior.

## 8. Unresolved uncertainties

Whether additional page/move keys repair the lower-right focus trap, whether all keys get physical releases, or whether combined OEM/DPAD events introduce unwanted movement. Existing Home/OEM interruption, microphone, calls and longer-session gaps remain. PhonePreference refuses a HistoricalBaseline candidate; retain the guard and re-establish original source provenance before any future v5 rollback.

## 9. Exact diff summary

InputEvents adds four raw-key translations, accepts the four supported page/move keys and exposes the ten-key registration list. InputSource registers that list and logs its marker. Host tests add 92 assertions. No key timing suppression, geometry/audio changes or native JNI signature changes. Preserve original v5 source pair as reference only; no source restoration performed.

## 10. Preservation checks performed

Known-working v5 hash and four PROJECT-RULES frozen anchors match; packaged candidate DEX/source provenance verified. Exact v5 source-pair hashes saved separately. No device state, original private signing identity, factory software, guard or milestone status changed. Helper revision suffix v6 does not mean project milestone M6 was activated.
