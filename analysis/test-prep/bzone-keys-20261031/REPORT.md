# v6h-bzone-release-a — offline build report, 2026-10-31

Built the next scoped input experiment. **Offline validation PASS; hardware result UNKNOWN.** Nothing was installed or run on a vehicle/phone. This is not a declaration that the Spotify widget is fixed or that a live session is ready.

APK: `analysis/parallel-aa-receiver/usb-helper/build/20261031-021001-636/rdx-usb-helper-v6h-bzone-release-a.apk`  
SHA-256: `DB9B0598467DE2BD1C7D363E52F5A0E6C759641F6490A66ED18632F402371206`

## 1. Files inspected

- `PROJECT-RULES.md` and the user-supplied AGENTS.md instructions.
- Previous C458 build report/signature report; current 27 Java build inputs and selected APK entries. Paths/hashes: [before.json](before.json), [candidate.json](candidate.json), [validation.json](validation.json).
- `InputEvents.java` and `AaOverlayService.java` under `analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/`, including saved pre-change copies in `prior-source-reference/`.
- `tools/car-test/InputPcmTest.java`, `HoverContactReplayTest.java`, `BZoneSwipeTest.java`; host PCM/focus dependencies.
- `scripts/Build-RdxUsbHelper.ps1` through the existing build entrypoint, `scripts/Run-CarTest.ps1`, and previous `analysis/test-prep/hover-dedup-20261031/Prepare-AuthorizedRetry.ps1` as the preparation template. No key files inspected.
- Latest capture: `analysis/test-prep/runs/helper_20261031T051918_e24f47ab1b7548cb92193e19fa5dc8f4/device-evidence/rdx_7af26727dcdd45778868a2a86049dff6/capture.log` (PID 8808). Test fixture reads only relevant input log records.
- Canonical prior analysis: [offline alternatives evidence](../../agent-reviews/offline-alternatives-20261031/EVIDENCE.md), its coordinate study and archived SystemUI verification; no research archive duplicated into instructions.
- Decompiled selected candidate DEX classes under `packaged-code/` and the future preparation script. No private APK assets extracted or inspected.

## 2. Files changed

Two production Java files: `InputEvents.java`, `AaOverlayService.java`. New test: `tools/car-test/BZoneSwipeTest.java`.

Added this report, `NEXT-TEST.md`, scripts, source-reference copies, scoped diffs and generated evidence under this directory. The normal builder created its new timestamped build and updated `usb-helper/latest-build.txt`. Offline Prepare created the run directory named in `validation.json`. No existing historical live report was rewritten.

## 3. Commands run

From the project root, using saved scripts rather than giant inline procedures:

1. `& analysis/test-prep/bzone-keys-20261031/Save-Baseline.ps1`
2. `& analysis/test-prep/bzone-keys-20261031/Build-OfflineCandidate.ps1` — host compilation/tests, policy comparison, existing `Build-RdxUsbHelper.ps1 -Version v6h-bzone-release-a`.
3. `& analysis/test-prep/bzone-keys-20261031/Verify-OfflineCandidate.ps1` — selected ZIP entry hashes, API22 signature/alignment evidence, preservation, JADX inspection, tests of the APK-derived InputEvents, then existing runner in **Mode Prepare** with a nonexistent ADB executable path.
4. `& analysis/test-prep/bzone-keys-20261031/Write-LivePlan.ps1` — generate/parse the future script; never execute it.
5. `& analysis/test-prep/bzone-keys-20261031/Finish-Offline.ps1` — scoped `git diff --no-index`, final hashes and syntax verification.

Also used targeted `Get-Content`, `rg`, `Get-ChildItem`, `Get-FileHash`, and file edits to inspect/save the scoped work. No ADB/fastboot, device operations, Git index changes, commit/push, key inspection, guard bypass or milestone action.

## 4. Tests run and results

| Check | Result / evidence |
|---|---|
| Existing input/PCM host tests | PASS, 25,799 checks, `input-results.txt` |
| New B-zone adapter tests | PASS, 135 checks, `bzone-results.txt` |
| Prior real hover replay | PASS, 1,248 checks; 1,202 input events, 10 duplicate ENTERs suppressed, 96 DOWN / 1,000 MOVE / 96 UP, `hover-results.txt` |
| Existing policy isolation | PASS, `policy-checks.json`: normal key dispatcher, hover/dedup, Select, window/release and capture/video code unchanged |
| APK-derived InputEvents host tests | PASS, same 25,799 input/PCM and 135 adapter checks; `packaged-input-results.txt`, `packaged-bzone-results.txt` |
| APK identity/source consistency | PASS, 27 recorded Java inputs match disk, packaged DEX matches generated DEX; `validation.json` |
| Signing/alignment | PASS for API22, same public signer as C458; build `signature-verification.txt`, `candidate.json`, `validation.json` |
| Manifest/resources/native library | Byte hashes unchanged from C458, `validation.json` |
| Offline existing runner Prepare | PASS, zero source differences; explicitly no device command invoked, `offline-prepare.txt` |
| Future live script | Parser PASS only, **not executed**; `live-script-validation.json` |
| Preserved artifacts | Nine unchanged, including four frozen anchors and C458; `final-preservation.json` |

The first extra packaged-code test compilation failed because javac did not resolve the PCM/focus dependency classes via the chosen classpath. Saved failure: `verification-failure.txt`. The verifier now compiles those same dependency sources explicitly alongside APK-decompiled InputEvents; it then passed. Production code/APK were not changed to resolve this test-harness failure. These are host tests of decompiled InputEvents, not execution of Android DEX/JNI, an overlay, or a device session. PCM/focus dependencies remain host source in that extra test.

The B-zone fixture has **14 real recorded DOWN signatures**. Its UP events are **synthetic**, explicitly identified in the test output. Actual hardware release delivery remains **UNKNOWN**. `staticAudit` remains **PENDING**, as recorded by the builder; these targeted checks do not constitute a full audit or reproducible-build attestation.

## 5. Findings

1. The latest working baseline is C458: the operator reported movement, Select and Back working, with only the Spotify right-third lower controls inaccessible. This experiment preserves those paths instead of replacing their behavior.
2. Historical secondary-pad inputs reached the overlay as raw 38/39 with scans 36/37 and source 257. The global key filter excluded them, so that **local key path** did not reach AA. Archived Honda SystemUI handles these keys on release as B-zone Bottom/Top actions. This is a supported reason to test this missing path, not proof that it explains the entire widget failure.
3. The candidate adds a separate, explicit **one-video-session opt-in**. Normal 38/39 handling stays off by default. Once armed, raw 38/scan36 maps to AA Down (20), raw 39/scan37 maps to AA Up (19), only for source 257 and a nonnegative device ID. A matching owned DOWN/UP sequence emits one balanced AA pair on release. Repeats, duplicate DOWN, orphan UP and foreign-device UP do not emit extra commands.
4. Existing AA registration remains `{4,19,20,21,22,23}`. No new native key/capability, media, mic, audio, coordinate or window policy is introduced. The existing `touchListener.onAaKey` path delivers the new ordinary Up/Down pairs.
5. The signature is not a unique device identity: 38/39 are also keyboard J/K. This is an explicitly armed diagnostic experiment without external keyboards; it logs the input device descriptor/name/vendor/product for later qualification. There is no hardcoded device ID 1. A qualified production device gate remains outside this build.
6. Actual hardware release delivery, AA widget focus behavior and the final fix remain UNKNOWN. Earlier evidence already contained successfully submitted main Down events while the panel was inaccessible. If this adapter delivers complete pairs but the controls remain unreachable, simply adding more Down mappings is not supported as the next diagnosis. See the existing alternatives report rather than combining untested approaches here.

## 6. Primary evidence for each finding

- Finding 1: latest run `REPORT.md` / `RESULTS.json` under `runs/helper_20261031T051918_e24f47ab1b7548cb92193e19fa5dc8f4/`; C458 hash in `before.json`; unchanged-code assertions in `policy-checks.json`.
- Finding 2: canonical alternatives `EVIDENCE.md` entries E2–E5, coordinate-study.json, capture hash `1C30CD45060A522FDB06A2F1950A0A48EC1744D98F2A0BF64562B9096628D1F2`; archived `decompiled/SystemUI/sources/com/android/systemui/statusbar/auto/HondaBZoneHoverRootLayout.java:157` and release branches through line 166. Current vehicle SystemUI binary parity is UNKNOWN.
- Finding 3: current `InputEvents.java:28` (BZoneSwipe); `AaOverlayService.java:114` (arm), `:160` (consume one-session flag), `:168` (routing/logging); source hashes in `candidate.json`; `packaged-bzone-results.txt` and `InputEvents.java.diff`.
- Finding 4: `InputEvents.java:20` (registered keys), `AaOverlayService.java:182` (existing callback); `policy-checks.json`; unchanged manifest/resources/native hashes in `validation.json`.
- Finding 5: `InputEvents.java:32` (signature gate and no hardcoded ID), `AaOverlayService.java:169` (device logging); archived mapping/source evidence in E3/E4; new tests explicitly vary device ID. Device identity is explicitly UNQUALIFIED in `validation.json`.
- Finding 6: `BZoneSwipeTest.java:82` identifies the synthetic UP; `bzone-results.txt`; earlier hover-restoration run `runs/helper_20261031T041524_80b16905aa3048e99d3f52f817379dbb/RESULTS.json` and alternatives E8. Android UI/JNI behavior cannot be established by these host tests.

## 7. Assumptions

The requested next build means the narrowly scoped B-zone experiment identified in the preceding review. Future test uses the same vehicle/phone arrangement and Spotify right-third layout, without an external keyboard. Neither which physical pad caused the reported problem nor equivalence of archived/live SystemUI is assumed as a fact.

## 8. Unresolved uncertainties

Actual raw UP delivery, input device identity, whether B-zone Up/Down changes the widget focus, behavior after leaving/returning, and absence of OEM double handling require a future authorized hardware test. Select/Back/movement are verified unchanged in source and host policy tests, not re-proven on this APK in a car. StaticAudit PENDING. No installation, readiness or hardware result is claimed.

## 9. Exact diff summary

- `InputEvents.java`: adds only the nested `BZoneSwipe` adapter. Existing mapping, dispatch, HoverContact and SelectPress remain unchanged. Exact patch: [InputEvents.java.diff](InputEvents.java.diff).
- `AaOverlayService.java`: adds the pending one-session flag/arm action; captures it for the next real overlay; routes/logs only raw 38/39 ahead of the unchanged normal dispatcher; adds one device identity log and the experiment marker. Exact patch: [AaOverlayService.java.diff](AaOverlayService.java.diff).
- `tools/car-test/BZoneSwipeTest.java`: new host fixture/scenario tests, including explicit synthetic-UP caveat.
- This directory: offline build/verification/finish scripts, generated candidate/provenance/test outputs, future-script template generation and these reports. `Prepare-LiveTest.ps1` pins this exact APK/hash and requires fresh B-zone plus capture-arm acknowledgements. Its existing readiness/identity/watchdog checks remain; stale-watchdog cleanup selects the latest real session rather than one old refused session and failure cleanup stops only its own watchdog. Syntax checked only.
- Normal generated build outputs and `latest-build.txt` changed through the builder. No other production source changed among the 27 build inputs; manifest/native unchanged.

## 10. Preservation checks performed

`before.json` records the pre-edit source and nine preserved artifacts. `validation.json` and `final-preservation.json` compare their actual hashes with the recorded values. The four frozen anchors match PROJECT-RULES.md; previous test APKs including C458 are unchanged. Current source hashes and packaged DEX match the candidate. No key material/private APK assets read, no device operation, no frozen rebuild, no Git write or milestone change.

Future procedure and decision criteria: [NEXT-TEST.md](NEXT-TEST.md). Broader recommendations stay in [the canonical alternatives review](../../agent-reviews/offline-alternatives-20261031/REPORT.md).
