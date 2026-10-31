# Hover duplicate-ENTER isolation A — build report

**Built and signed; not installed.** Hardware result UNKNOWN. The only new input behavior is suppressing repeated hover ENTER while a pad contact is active. This is an isolation test, not a confirmed Spotify fix.

APK: `analysis/parallel-aa-receiver/usb-helper/build/20261031-003921-309/rdx-usb-helper-v6h-hover-dedup-a.apk`

SHA-256: `C458B51DA03A9B96776E233A220B03C04254C13F4AC7E2BB790325590DDA14FD`.

See [NEXT-TEST.md](NEXT-TEST.md) for connection instructions and [validation.json](validation.json) for artifact checks. Prior live analysis remains canonical at `analysis/test-prep/runs/helper_20261031T041524_80b16905aa3048e99d3f52f817379dbb/REPORT.md`.

## 1. Files inspected

PROJECT-RULES.md; previous live result/contact evidence; current and preserved InputEvents/AaOverlayService; existing InputPcmTest; previous hover-restoration build/provenance, native/manifest/resources/signature outputs; build/Prepare-mode tools; four frozen anchors and prior candidate APKs. No device data was newly queried.

## 2. Files changed

- `analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/InputEvents.java`: add isolated HoverContact state class; existing methods unchanged.
- `analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/AaOverlayService.java`: fresh state per overlay, hover filter and diagnostic markers.
- New `tools/car-test/HoverContactReplayTest.java`: recorded contact-sequence replay and click/reentry/lifecycle boundary checks.
- New preparation directory: before/source snapshots, source patches, tests/classes/results, packaged DEX inspection, validation, report and test instructions. Existing builder created the timestamped candidate and updated latest-build.txt. Offline Prepare created a new artifact-plan directory.

## 3. Commands run

Local source reads and SHA-256 snapshots; scoped patch; JDK 17 javac/java for existing input tests and new replay test; `scripts/Build-RdxUsbHelper.ps1 -Version v6h-hover-dedup-a` through the established build/signing process; selected APK ZIP-entry hashes and source/signature comparisons; JADX CLI on extracted classes.dex for InputEvents and AaOverlayService; `scripts/Run-CarTest.ps1 -Mode Prepare -CandidateRole CurrentSource -SafetySeconds 180 -HondaStrategy PhonePreference` with a nonexistent ADB executable; controlled source diffs. No ADB/device command, publication or Git mutation.

Replay commands use `HoverContactReplayTest <capture.log> <pid> <expected-duplicates> <expected-events>`:

- Current fixture: prior run's `device-evidence/rdx_55bdb829127e4c229f44186937b71a9d/capture.log`, PID 5815, expected 10 duplicates / 1202 events.
- V5 fixture: run `helper_20261030T234615_99356193e031448eb0d3fb4ebd9b5be9/device-evidence/capture.log`, PID 5395, expected 13 duplicates / 964 events.

## 4. Tests run and results

- Existing input/Select suite: **PASS: 25799 input/PCM checks**. Existing test source unchanged.
- Latest physical capture replay: **PASS: 1248 checks; input=1202 suppressed=10 outputDown=96 moves=1000 outputUp=96**.
- Earlier v5 capture replay: **PASS: 1010 checks; input=964 suppressed=13 outputDown=77 moves=797 outputUp=77**.
- Replay asserts every recorded MOVE and release survives; accepted contacts balance and end released; only duplicate ENTER is suppressed. Scenarios cover initial/repeated entry, unknown actions without changing contact state, fresh overlay state and repeated Select/reentry sequences. Previously forwarded idle MOVE/EXIT are preserved deliberately. These assertions do not execute Android routing, native sends or phone UI.
- Source isolation PASS: remove the new nested class and InputEvents is otherwise identical to the prior source. Overlay is otherwise identical after removing per-overlay initialization and substituting the hover handler/marker. Existing key, Select and window code is unchanged.
- All 27 Java inputs compile; zero current-source differences. Exactly InputEvents.java and AaOverlayService.java differ among production Java inputs.
- API-22 signature and alignment PASS. Packaged DEX matches generated/extracted DEX; actual packaged code contains fresh per-overlay contact state and duplicate-enter branch. Public signer, native bytes, manifest and resources match the previous hover-restoration APK.
- Eight preservation checks PASS: four previous candidates and four frozen anchors. Offline CurrentSource Prepare PASS with zero differences and no device command. StaticAudit remains PENDING.

## 5. Findings

The prior test restored grid Up/Down but retained the Spotify dashboard failure. Its forwarded pad stream contained ten duplicate DOWNs, while key delivery succeeded locally. This candidate tests that concrete sequence anomaly without changing the current key path or capability advertisement.

The filter is event/state based, with no timing threshold. It consumes duplicate ENTER locally, logging INPUT_HOVER_DUPLICATE_ENTER_DROPPED, and forwards the first ENTER and existing MOVE/EXIT mapping. Each newly created overlay gets independent state. Select and hover state remain separate.

Offline replay shows the intended sequence correction on two saved physical-test captures. It does not establish that these duplicates caused the inaccessible skip controls. If contacts become clean but the right panel still fails, record the hypothesis as unconfirmed/negative rather than adding simultaneous remapping or geometry changes.

## 6. Primary evidence for each finding

- Prior live capture SHA-256 `A52F7D0AD4508A3AE6F9AE4F8AF17CB1F284D7CFE2EFCEC16E18347204E49DE6`, unique boundary line 35229, PID 5815. Initial duplicate at lines 43460-43461; Select release and repeated reentry at 44937-44939. Canonical run RESULTS.json records the counts and operator's working grid/failing right panel.
- before.json and prior-source-reference contain the two exact pre-edit source copies and all 27 source hashes. policy-checks.json and *.java.patch establish the isolated delta. InputEvents.HoverContact has no access to key/Select state.
- input-results.txt, replay-current-results.txt and replay-v5-results.txt contain actual test output. HoverContactReplayTest.java checks physical-fixture invariants rather than fabricated raw-key fallback sequences.
- packaged-code/sources/com/rdx/fullscreen/usbhelper/InputEvents.java:57 onward shows the compiled active-contact check; AaOverlayService.java:124 initializes state per createOverlay and :150 onward uses it in hover dispatch. These files were decompiled from the candidate's packaged DEX.
- validation.json records APK/DEX/native hashes, successful signature/alignment flags, changed input list, unchanged resources/signer, preservation and offline plan. The build's build-report.json and signature-verification.txt provide underlying build/verification output.
- Offline plan: `analysis/test-prep/runs/helper_20261031T044031_663e4f7675a44ed2b43c9bafd4fe4996/artifact-plan.json`.

## 7. Assumptions

The next car session reproduces the same phone/layout and right-third Spotify behavior. Recorded mapped pad DOWN/MOVE/UP events can be replayed through their corresponding hover ENTER/MOVE/EXIT for testing this filter; this assumption does not substitute for Android integration testing. No assumption of successful hardware repair is made.

## 8. Unresolved uncertainties

Whether duplicate-contact suppression changes AA widget focus; whether legitimate hardware reentry differs from the recorded sequences; phone-side focus/capability interpretation; Back behavior; and repeatability after leaving/returning to Spotify. The mixed pad-motion/DPAD stream is unchanged and remains a separate hypothesis. StaticAudit remains PENDING.

## 9. Exact diff summary

Add InputEvents.HoverContact: map hover as before, reject ENTER while active, set active on first ENTER and clear on EXIT; preserve MOVE, idle EXIT and unknown-action behavior. Create one contact object per overlay. Gate only forwarding through it and consume/log rejected duplicate ENTER. Change the diagnostic marker to INPUT_HOVER_DEDUP_V1. Add recorded-sequence validation; no other input, UI, protocol or lifecycle change.

## 10. Preservation checks performed

All 27 Java inputs match new build provenance; exactly two changed from the pre-edit snapshot. Manifest, resources, native library and public signer match the preceding candidate. Four prior APKs and all four frozen PROJECT-RULES anchors remain unchanged. No historical report was rewritten, credential contents inspected/printed by review tools, ADB invoked, device accessed, guard bypass added, Git mutation/publication performed or milestone advanced. The APK is prepared only; installation/live readiness are not established.
