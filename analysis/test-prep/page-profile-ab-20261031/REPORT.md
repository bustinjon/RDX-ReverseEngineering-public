# Matched page/move input profiles — A/B test preparation

Both comparison APKs built and validated **offline**. Start with **A (arrows advertised)**, collect the result, then test **B (arrows omitted)**. Both use the same page/move events and current stable Select/Back/hover implementation. Their only source-line difference is the supported-key array. This is a diagnostic comparison, not a claimed Spotify fix.

| Profile | APK | SHA-256 |
|---|---|---|
| A — page/move plus advertised arrows | `analysis/parallel-aa-receiver/usb-helper/build/20261031-102313-010/rdx-usb-helper-v6h-page-profile-arrows-a.apk` | `C3EDC256281D1F923CD65785DB0C0FA6B5E36E182FD602194245B89DB5875DDF` |
| B — page/move navigation subset | `analysis/parallel-aa-receiver/usb-helper/build/20261031-102523-035/rdx-usb-helper-v6h-page-profile-pad-b.apk` | `E931C7A4368465F52B218C5E973540F26D5C3D438F02751CC3C0B6FB15CEF383` |

## 1. Files inspected

- PROJECT-RULES.md, AGENTS.md and the preceding `spotify-bottom-row-20261031/DECISION-TESTS.md`.
- Current InputEvents.java and its pre-edit snapshot; prior A58A build report and preservation manifest.
- Existing Build-RdxUsbHelper.ps1, Run-CarTest.ps1, CarTest.Core.ps1:6–36, previous saved preparation script and HoverContactReplayTest.java.
- All27 recorded build inputs, selected public APK entries and public signature-verification reports; packaged InputEvents decompilation from both new APKs.
- New NavigationProfileTest.java, snapshot selection logic and generated future preparation scripts.
- Canonical archived/historical profile evidence remains in `analysis/agent-reviews/spotify-bottom-row-20261031/REPORT.md`; it was not recollected.

## 2. Files changed

- One production file: `analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/InputEvents.java`.
- New `tools/car-test/NavigationProfileTest.java`.
- New saved scripts, source snapshots, reports and evidence in this preparation directory; normal timestamped build outputs/latest-build pointer; offline runner artifact-plan directories.
- Other26 production Java inputs, manifest/resources/native library and existing historical reports unchanged. Final active source/latest pointer are deliberately **A**, matching the first planned APK.

## 3. Commands run

All multi-step procedures were saved before execution:

[Code block omitted; consult project-authored source.]

Wrappers reuse the standard builder, recorded hover replay, existing CurrentSource artifact planner and previous preparation template. Detailed output goes to this directory; terminal results are concise. Verification internally selects each known source snapshot, runs **Mode Prepare** with a nonexistent ADB path, then selects A again. No ADB/install/phone/car step or Git mutation.

## 4. Tests run and results

| Check | Result |
|---|---|
| Exact production scope against A58A baseline | PASS for each profile; only four swipe mappings, declared-key filter and supported-key list change |
| Exact A/B source comparison | PASS: one supported-array line differs |
| New navigation/Select/Back/hover host contract | PASS,72 checks per profile |
| Recorded hover replay | PASS,1,248 checks per profile;1,202 inputs,10 suppressed duplicate ENTERs,96 DOWN/1,000 MOVE/96 UP |
| Tests against APK-derived InputEvents | PASS,72 checks per APK |
| APK identity/provenance | PASS: generated/packaged DEX match;27 recorded Java inputs match each selected profile |
| API22 signing/alignment | PASS for both; public signer unchanged from A58A |
| Manifest/resources/native library | Selected entry hashes unchanged from A58A in both APKs |
| Existing CurrentSource/PhonePreference offline plan | PASS with zero source differences for each; no device command invoked |
| Future A/B preparation scripts | Parser/hash checks PASS only; neither executed |
| Previous/frozen artifacts | Twelve hashes unchanged; final active sourceA matches its27 inputs |

Source tests verify physical raw146/152/148/150 and Select/Back are consumed and emit exactly one balanced, declared native pair. They reject undeclared/unrelated input and exercise Select release/cancel and hover dedup invariants. This is not execution of Android DEX/JNI or AA phone focus. The existing old directional-mapping test suite expects the previous mapping and was not rerun as if its expectations still applied; its unchanged PCM/audio behavior is outside this change.

Details: validation.json, navigation-*.txt, hover-*.txt, packaged-navigation-*.txt and final-preservation.json. `staticAudit` remains PENDING. No hardware result or completed fix is claimed.

## 5. Findings

### What is being compared

Both profiles translate raw146->93(PageDown),152->92(PageUp),148->122(MoveHome),150->123(MoveEnd). Raw66 still maps to Select23; Back4 and Select's press/release/cancellation state remain unchanged. Existing hover forwarding/dedup, window policy, audio/video, pad dimensions60x40mm/1325x720 and the tested absolute=false flag remain unchanged.

ProfileA advertises `{4,19,20,21,22,23,92,93,122,123}`. ProfileB advertises `{4,23,92,93,122,123}`. A shared filter accepts only mapped codes in the selected declaration, preventing emission of undeclared keys. Therefore direct raw DPAD19–22 would be accepted in A and rejected in B; **for the controlled physical swipe codes146/152/148/150, mappings/delivery remain identical**. No external keyboard. A run with direct raw DPAD inputs must be analyzed separately rather than claiming its outcome isolates advertisement alone.

This deliberately revisits the historical page/move comparison with a matched control, retaining the later Select/hover fixes. Neither APK is full factory parity: media/voice/phone shortcuts and other stock behaviors are outside this navigation subset.

### Secondary pad held off

The BZoneSwipe implementation remains byte-identical in source, but both new preparation scripts omit its arm and reject an unexpected fresh B-zone arm acknowledgement. Capture remains armed. The class's old19/20 output must not be mixed into profileB, whose navigation keys omit19/20. Use the large pad for every diagnostic gesture and confirm the collected overlay reports B-zone enabled=false.

### Avoiding build/source mismatch

Each immutable APK has its exact recorded InputEvents snapshot. `Select-Profile.ps1` accepts only these two known snapshot hashes, refuses unknown edits or changes to the other26 inputs, checks the pinned APK, selects the matching source, checks all27 inputs, and updates latest-build.txt. The future per-profile preparation script performs this local selection **before any device action**, then uses the unchanged `CurrentSource` runner. There is no HistoricalBaseline exception or bypass of PhonePreference/readiness checks.

Final selection is A. Future B preparation selects B explicitly. This is a documented selection between reviewed builds, not a hidden rebuild or relabeling of a mismatched APK.

### Live result remains open

If A fails and B succeeds under the same playlist/layout, the advertisement/filter profile distinction becomes relevant. Collect raw events to confirm only the expected swipe family was used. If both fail, that contrast alone did not solve the row; do not declare a phone bug proved. If A loses basic movement, stop and review before continuing. See NEXT-TEST.md for exact sequence and interpretation.

## 6. Primary evidence for each finding

- Mappings/filter: InputEvents.java:5–25, baseline-to-a.diff and scope-arrows.json/scope-padonly.json. Snapshot-to-snapshot exact line difference: a-to-b.diff.
- Register/delivery consistency: NavigationProfileTest.java and navigation/packaged-navigation results; existing InputSource registerTouchPad calls InputEvents.supportedKeyCodes, unchanged source hash.
- Preserved Select/Back/hover/B-zone implementation: exact scope checks compare all other InputEvents text with InputEvents.before.java; other26 source hashes unchanged; replay results.
- APKs/entry/signature identity: candidate-arrows.json, candidate-padonly.json, validation.json and build signature-verification.txt files. Only public DEX entries extracted.
- Source selection: Select-Profile.ps1, select-arrows.txt/select-padonly.txt, selected-profile.json and offline-prepare-arrows.txt/offline-prepare-padonly.txt.
- Future scripts/B-zone off: future-scripts.json, Prepare-arrows.ps1 and Prepare-padonly.ps1. Existing checks retained; no live execution.
- Frozen/prior artifacts: before.json, validation.json and final-preservation.json.

## 7. Assumptions

The user's next-test request authorizes building this matched comparison offline; no connection was assumed. A later test uses the same phone/app versions, known multi-track queue and compact layout with the large pad. CurrentSource selection assumes only the two reviewed snapshots may be activated; unknown work is refused rather than overwritten. Previous stock-phone preference must still be confirmed before live use.

## 8. Unresolved uncertainties

Phone capability interpretation, compact-row focus, whether A/B have equivalent physical-event traces, working movement after remapping, exact factory runtime parity and all live outcomes remain UNKNOWN. Raw DPAD acceptance necessarily differs with the declaration and is a potential confound if those raw inputs occur. B-zone is intentionally out of this comparison. StaticAudit PENDING. Automatic navigation back to the USB menu remains separately unqualified and was not added here.

## 9. Exact diff summary

- InputEvents: four swipe output codes changed to93/92/122/123; key acceptance follows supportedKeyCodes; A has10 declared codes and B has6. No dispatch algorithm, HoverContact, SelectPress or BZoneSwipe implementation edits. A/B Java source differs only in the supportedKeyCodes array line.
- New NavigationProfileTest.java and saved analysis/test-preparation artifacts.
- Future templates: pinned new APK/hash; known-snapshot source selection prelude; remove B-zone arm/positive requirement, reject unexpected arm, record B-zone OFF/profile; preserve existing target/firmware/Home/lock-task/timeout/install/A11Y/capture/watchdog checks. No guard source edit or bypass.
- Existing builder outputs/latest pointer and offline artifact plans generated. Final InputEvents source/latest pointer identify A. Existing reports/old artifacts unchanged.

## 10. Preservation checks performed

Pre-edit27 inputs matched A58A and twelve earlier/frozen artifacts matched their recorded hashes. Each selected comparison matches all27 inputs; manifest/resources/native hashes and signer remain stable; packaged DEX matches generated DEX. Twelve anchors rechecked after build. Original logs/media are read-only fixtures, no recollection. No key material/private APK assets, ADB/car/phone/USB, Git write, frozen rebuild, guard bypass, milestone advancement, agent spawn or external sharing.

Procedure: [NEXT-TEST.md](NEXT-TEST.md). Both APKs are prepared, neither installed.
