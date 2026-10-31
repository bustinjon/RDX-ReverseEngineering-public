# Directional focus A — offline implementation and preparation

Built, signed and locally checked; no hardware result. Complete user instructions in [NEXT-TEST.md](NEXT-TEST.md).

## 1. Files inspected

PROJECT-RULES.md; latest swipe-candidate capture summary and fallback review; effective InputEvents/InputSource/AaOverlayService dispatch; host tests; v5/prior candidate build provenance and frozen-anchor validation metadata.

## 2. Files changed

Effective helper InputEvents.java, InputSource.java, AaOverlayService.java; tools/car-test/InputPcmTest.java; new source references, plan/report, host results, validation and private helper build. No shared geometry/audio/session source, native library, guards, existing APKs, public snapshot or historical report changed.

## 3. Commands run

Local source reads; preserve prior source references with hashes; JDK 17 host javac/java; existing Build-RdxUsbHelper.ps1 label v6h-directional-focus-a using the authorized local signing workflow; source/APK/DEX/native/signing-certificate/frozen checks; Run-CarTest **Prepare** with nonexistent ADB path. No device commands, Git or publication.

## 4. Tests run and results

- **PASS: 25799 input/PCM assertions**, results.txt. Mapping tests now exercise the consume/send helper used in the real overlay: one send per accepted DOWN/UP event, intended arrow code, invalid/unsupported event rejection, no page-key dispatch, supported-key coverage and uniqueness. Existing PCM/focus/select-state checks retained. Count includes per-byte comparisons and changed with the smaller registration domain; it is not an independent scenario count.
- Full 25-source compile, DEX, package/sign succeeded; zero source provenance differences.
- Exactly three production inputs differ from prior swipe candidate: InputEvents, InputSource, AaOverlayService.
- API-22 signature/alignment passed, signer matches v5, packaged DEX matches generated DEX; policy/hover/directional marker strings present.
- Native library matches v5; v5, prior swipe APK and four frozen anchors preserved. StaticAudit remains PENDING; Android routing and actual UI focus behavior remain hardware-unverified.

## 5. Findings

The last experiment changed effective directional semantics, not merely supported-key coverage: consuming raw swipes replaced Android's directional fallback with page/move events. V5 already had directional keys but still failed, so an explicit-arrow-only label change would not be a sufficient new hypothesis. This candidate intentionally isolates keys from native hover/pad movement while making key consumption explicit. This is an experimental policy change; success is not established by the build.

## 6. Primary evidence

- Latest actual run `analysis/test-prep/runs/helper_20261031T000705_990b5e7dac5f4bf9b19bf2639551fe4f/RESULTS.json`: initial operator success then panel-return failure; mapped pairs and zero normal DPAD events; framework/keymap support described in its RESULTS.md.
- Effective helper InputEvents.java: key normalization 146/148/150/152→20/21/22/19, six-key list and dispatchKey consumption contract. AaOverlayService uses that helper and logs/consumes hover without handleTouch forwarding in VIDEO mode. Diagnostic test-mode touch path retained.
- validation.json: APK `analysis/parallel-aa-receiver/usb-helper/build/20261030-201558-444/rdx-usb-helper-v6h-directional-focus-a.apk`; SHA-256 `F6D485977DEF00B0C6BADE0E0CD7ED50E8615923E522B3CC73F7BF0D66C57F92`; source scope, DEX/signing/native comparisons and preservation flags.
- results.txt records host output; prior-source-reference.json hashes the pre-edit input source snapshots. No Android framework is executed by the host tests.

## 7. Assumptions

The user can reproduce the same panel entry/exit and Spotify layout. This is a focus-navigation interface per the user's report, not a literal screen pointer. Actual physical repeats/keymaps and phone focus policy still require observation.

## 8. Unresolved uncertainties

Whether suppressing hover improves panel re-entry, whether directional keys alone traverse intended controls, physical repeat behavior, and whether this mode is desirable outside the narrow test. Key-dispatch assertions are not Android input-pipeline integration tests. Geometry/audio/OEM camera/voice/call limitations unchanged. A result with initial success but failed return remains NOT_FIXED. If the input-policy experiment helps, its explicit key mapping versus removed hover effects are not independently isolated by this combined candidate.

## 9. Exact diff summary

- Replace page/move swipe mapping with arrows; restrict supported registration to Back, DPAD and select.
- Add pure consume/send contract and use it from overlay; accepted events return true, preventing reliance on synthetic keyboard fallback.
- VIDEO-mode hover is consumed locally with sampled diagnostics, no native pad send. Add input-policy marker and key flags/repeat/source/device logging. Existing physical select, diagnostic touch mode and Back behavior retained.
- Replace synthetic raw+fallback test sequence with direct dispatch contract tests. Do not add timing deduplication, UI focus reset, phone-side actions, video or audio changes.

## 10. Preservation checks performed

Known-working and prior candidate APK hashes unchanged; four frozen anchors match; exact native bytes and public signer match v5; current source provenance verified. Private helper APK remains local and contains existing private runtime prerequisites; it is not suitable for public upload. No ADB, private key contents printed/read by inspection tools, Git mutation, guard bypass, factory modification or milestone action.
