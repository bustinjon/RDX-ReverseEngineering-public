# Down-motion-only probe — offline build

**Built and verified offline.** The only production change is one dispatch branch that consumes raw146's valid key press/release without invoking its native-key consumer. Continuous pad motion and every other control/declaration remain identical to profileB. Whether this repairs the compact Spotify row remains UNKNOWN.

APK: `analysis/parallel-aa-receiver/usb-helper/build/20261031-112151-466/rdx-usb-helper-v6h-down-motion-only-a.apk`  
SHA-256: `28659795FC5228988FB56E0D006328DE0D13F65421560C27DFCEB28CDDF8367A`  
Reference B: `E931C7A4368465F52B218C5E973540F26D5C3D438F02751CC3C0B6FB15CEF383`.

## 1. Files inspected

- PROJECT-RULES.md/AGENTS.md; prior `analysis/agent-reviews/page-profile-ab-results-20261031/NEXT-PROBE.md` and its established evidence limits.
- Current profileB InputEvents.java, its saved snapshot/build report and prior fourteen-artifact preservation chain.
- Existing builder, offline artifact planner, previous verification patterns, HoverContactReplayTest.java and new DownMotionOnlyTest.java.
- New candidate's27 recorded Java input hashes, selected public ZIP entries, public signature-verification output, and APK-derived InputEvents class.
- Previous Prepare-padonly.ps1 template and new generated Prepare-LiveTest.ps1. No old device logs/media recollected or decoded in this build task.

## 2. Files changed

- One line added to production `analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/InputEvents.java:25`.
- New `tools/car-test/DownMotionOnlyTest.java`.
- New saved scripts/reports/snapshot/provenance/test evidence in this directory; normal timestamped builder output/latest-build pointer and existing runner's offline artifact-plan directory.
- Other26 Java inputs, native library, manifest, resources, original evidence and frozen artifacts unchanged.

## 3. Commands run

[Code block omitted; consult project-authored source.]

Saved wrappers reuse the standard Build-RdxUsbHelper.ps1, previous hover replay, existing CurrentSource/PhonePreference runner in **Mode Prepare** with a nonexistent ADB path, and previous live-script template. Detailed output remains under analysis. Also used targeted source/metadata reads and a scoped patch. No ADB, install, phone/car/USB action or live-script execution.

## 4. Tests run and results

| Check | Result/evidence |
|---|---|
| Exact change vs saved B source | PASS, scope-check.json: only the single branch added after existing validation |
| New host suppression/preserved-control tests | PASS,59 checks, down-test-results.txt |
| Existing recorded hover replay | PASS,1,248 checks;1,202 input events,10 duplicate ENTERs suppressed,96 DOWN/1,000 MOVE/96 UP; hover-results.txt |
| Tests of InputEvents decompiled from actual APK | PASS,59 checks, packaged-down-test.txt |
| Source/artifact provenance | PASS,27 inputs match candidate, only InputEvents differs from B; packaged DEX matches generated DEX |
| API22 signing/alignment | PASS, same public signer as B |
| Manifest/resources/native ZIP entries | Identical hashes to B |
| Existing offline artifact plan | PASS CurrentSource, zero differences, no device command; offline-prepare.txt |
| Future live script | Parser/hash checks PASS only; not executed |
| Fourteen previous/frozen artifacts | Hashes unchanged; validation.json/final-preservation.json |

Tests cover consumption of both raw146 phases/repeats with zero native calls, rejection with invalid action/no sink, preserved Up/Left/Right/Back/Select pairs, Select cancellation and hover dedup, and interleaved Select while Down is suppressed. Direct raw93 remains valid and emits a native pair: the probe is source-code146-specific, not removal of93 capability. Undeclared/unrelated input remains rejected.

APK-derived tests execute decompiled Java on a host JVM; they do not execute Android DEX/JNI or establish phone focus behavior. Old directional/page-pair test expectations were not rerun unchanged because suppression intentionally changes raw146 delivery; unchanged PCM/audio logic is outside this change. StaticAudit remains PENDING.

## 5. Findings

The candidate implements the exact proposed isolation: raw146 passes existing consumer/key/action validation, then returns true before the consumer callback. Both phases are consumed, preventing fallback while withholding that gesture's extra PageDown93 pulse. The continuous hover-derived pad stream remains the movement path. Up92, Left122, Right123, Select23 and Back4 use the previous path.

The supported-key array remains `{4,23,92,93,122,123}`; mappings and profileB's nav=true/abs=false/dimensions remain unchanged. B-zone stays OFF in the future preparation script. The branch matches keycode146 irrespective of device, as the prior mapping already did; this is a controlled Honda main-pad experiment without external keyboards, not a uniquely qualified input-device classifier.

Down no longer invokes the key consumer, so it also does not invoke the existing consumer-side FocusCapture.key scheduling/annotation. RAW_DOWN diagnostics and pad logs remain, and Up/Right/Select still schedule captures. Fewer Down-triggered screenshots are expected; missing screenshots alone must not be mistaken for protocol loss or successful suppression. Prove the active installed artifact, actual raw146 input, live pad/other controls and absent native93/20 delivery together.

The old A/B source-selector prelude was removed from this new preparation template. It would properly reject this new source as unknown to its two snapshots. The new script requires the usual matching **CurrentSource** APK directly; no source selection, historical-role exception or guard bypass. The current latest-build pointer identifies this new APK, not the old dated selected-profile.json record.

This build does not establish that a key was reversing focus. It will test whether that extra Down delivery is sufficient to affect the path-dependent symptom under the same B profile.

## 6. Primary evidence for each finding

- Exact dispatch branch: InputEvents.java:23–28; InputEvents.before.java, InputEvents.java.diff and scope-check.json.
- Control/capability invariants: exact full-file comparison except the branch, unchanged26 input hashes, DownMotionOnlyTest.java and its host/APK-derived result files.
- Packaged implementation: packaged-code/sources/com/rdx/fullscreen/usbhelper/InputEvents.java, packaged-down-test.txt and candidate.json's APK/DEX binding.
- Signature/entry identity: build signature-verification.txt, candidate.json, validation.json packagedHashes and retained old public signer comparison.
- Capture consequence: unchanged AaOverlayService key consumer logs/calls focusCapture.key before onAaKey; raw146 no longer calls that consumer. Existing hover forwarding and first-frame capture code unchanged by source hashes.
- Future procedure: future-script-validation.json and Prepare-LiveTest.ps1; template hash and explicit removal of prior selector recorded. No am BZONE_ARM_ONCE command retained.
- Motivation remains canonical in `analysis/agent-reviews/page-profile-ab-results-20261031/REPORT.md`; no prior observations reclassified as proof of repair.

## 7. Assumptions

User's “continue” after the proposed next probe authorizes this scoped offline build, not a new live test. Later comparison uses the same large pad/phone/queue/settings and the previous stock-phone preference. The active input source is the Honda raw146 family; no external keyboard.

## 8. Unresolved uncertainties

Actual phone focus path, whether pad-only Down is sufficient, whether menu/Maps Down depends on the extra key, repeatability after moving Up/leaving/returning, complete live regression behavior and root cause remain UNKNOWN. Native result0 alone is not phone receipt. StaticAudit PENDING. No device install or behavioral test occurred here.

## 9. Exact diff summary

One production line inserted after existing validation:

[Code block omitted; consult project-authored source.]

No mappings, key declaration, other dispatch logic, hover/dedup, SelectPress, BZoneSwipe implementation, window handling, services, video or audio edits. New host test/scripts/evidence as listed above. Future script substitutions pin the new APK/hash/profile and remove obsolete A/B source selection; existing readiness/identity/install/A11Y/capture/timer/cleanup behavior retained, B-zone OFF. No guard source modified.

## 10. Preservation checks performed

All27 pre-edit inputs matched B;14 previous/frozen artifacts matched. Post-build27 inputs match the new candidate, only InputEvents differs, selected public APK entries/signer remain stable and all14 anchors are unchanged. Final hashes/doc/script checks saved in final-preservation.json. No original media/log writes, key-material inspection by the agent, frozen rebuild, Git mutation, ADB/USB/phone/car step, guard bypass, milestone action, spawned agent or external publication. Standard existing signing workflow used opaquely.

Future sequence: [NEXT-TEST.md](NEXT-TEST.md). **Built, not installed.**
