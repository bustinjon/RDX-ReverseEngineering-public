# TLX D1.6.4 research review against the RDX v5 experiment

Read-only engineering review, 2026-10-30. Source: `photos/Acura_D164_Fullscreen_Research.pdf`, 20 pages, SHA-256 `868D9DC1EFD8546A5D34EC7B599372BFF8825B432A0A383E05DA5722A877B539`.

**Conclusion:** useful, carefully qualified TLX research with substantial shared software identity. It supports separating display, negotiation, rendering and input. It does not directly diagnose the RDX's Spotify lower-right problem or establish production readiness. Eight listed artifact hashes match available RDX bytes, but policy/hardware conclusions still need build-specific verification. Do not treat the same D1.6.4 label as universal equivalence.

## 1. Files inspected

- Entire PDF: text extracted and all 20 pages rendered. Contact-sheet overview inspected; pages 6 and 11 inspected at full page size for geometry table/input caveats and runtime-route qualifications. Source/evidence atlas and hashes on pages 17–20 read in full.
- `PROJECT-RULES.md` and current v5 overlay, InputEvents, InputSource, VideoSink and session configuration source.
- Current factory AA decompilation: ProjectionActivity, GalIntegration and HMIPresenter; archived PhoneWindowManager, WindowManagerService, DisplaySettings and HondaStatusBarWindowManager; Framework WindowManager constants.
- Local artifact bytes under adb/, apks/ and the last live preflight services.jar, by hash only where appropriate. No key material opened.
- Latest RDX attempt-1 RESULTS.json/RESULTS.md and prior framework parity review. The PDF's underlying 46-file research bundle was not supplied; its claimed models/checks were not independently rerun.

## 2. Files changed

Only local review artifacts: this report, extracted.txt/pages.json, rendered PNGs/contact sheet, artifact-comparison.json, comparison-summary.json, arithmetic-checks.json and preservation.json. Added a local PDF reader/render script and npm dependencies under analysis/tools/friend-pdf-review. Source PDF, receiver/public diagnostic source, APKs, historical reports, Git and device state unchanged.

## 3. Commands run

Local Get-Content/Get-FileHash/rg; installed PDF.js and canvas reader dependencies after the sandboxed network attempt stalled; local Node PDF text extraction and rendering; artifact SHA-256 comparisons; arithmetic checks; source searches. Python runtime was unavailable. Initial renderer completed outputs but its cleanup method was wrong; corrected to the loading-task cleanup method and reran successfully. No ADB, binder calls, settings commands, native execution, app build, Git mutations or publication.

## 4. Tests run and results

- PDF read/render: 20 pages, 58,908 extracted characters; 20 page PNGs and a contact sheet generated. Final script exited successfully.
- Fifteen firmware artifact claims compared: **8 MATCH, 5 container hashes DIFFERENT, 2 unavailable**. See artifact-comparison.json. Initial comparison limited to older adb/ copies was expanded to include current apks/ and actual preflight files; do not use the incomplete initial mismatch count.
- Arithmetic reproduced: stock content aspect-fit to a wide surface gives 1340x720 centered at x=290; 720p60 carrier budget=216,000 macroblocks/s; 1080p60 carrier budget=489,600 macroblocks/s; the stated overscan width algebra evaluates to 1920. Arithmetic is not runtime validation, sustained decoding evidence or permission qualification.
- Source PDF, working v5 APK and four frozen anchors verified unchanged in preservation.json. No hardware tests performed.

## 5. Findings

### F1 — Same release label, selectively identical artifacts

The user identifies the friend's car as a TLX, and the PDF specifies 2023 TLX Type S. Exact hash matches exist for current AA, native AA receiver, services.jar, honda-manager.jar, libavjni, libAirPlay, libScreenStream and libdevelupdate. This is stronger than firmware-label similarity for those particular files.

Five PDF container hashes do not match available older local CarPlay APK, android.policy.jar, framework-res.apk, SystemUI APK and touchbridge.jar. That **does not prove their executable payloads differ**: this project's prior framework review independently showed ZIP timestamp-only differences between build containers. The friend's corresponding bytes/payload inventory are needed to resolve these cases. airplay.conf/media_codecs.xml matching local candidates were not available in the bounded search. Matching native libraries do not prove matching mic/camera/input hardware, vehicle signal mapping or OEM settings.

### F2 — The input separation is directly useful; it is not a scaling fix

PDF pages 3/6 distinguish 1920x720 video from the native 1325x720 type-2 pad, and movement from select presses. Current factory code agrees with raw pad forwarding and separate key-23 click handling. V5's successful click implementation already uses this distinction.

The failed RDX attempt reached raw x=1324 and right-side y=719, with 28 successful native Down-key press/release pairs. This argues against immediately stretching pad coordinates. It does not establish correct phone focus traversal or reachability of the intended Spotify control.

The PDF does not identify the RDX-specific missing swipe mappings. Our matched current AA source independently does: raw 146/148/150/152 map to 93/122/123/92, and stock GalIntegration explicitly adds those four supported keys. V5 omits both those mappings and registration. This is a concrete gap and a plausible targeted experiment, not a proven cause. Stock gesture and regular DPAD events can both occur; avoid inventing blanket timing-based suppression without testing their distinct semantics.

### F3 — Geometry negotiation agrees with our carrier/margin model; profiles differ

PDF page 6's 1920x1080 carrier with 360 **total** vertical margin matches v5's active 1920x720 contract. It is not 360 pixels cropped from each edge. Our decoded-format geometry and operator observations already support a bounded working display result.

The PDF proposes 240 DPI and a 1280x480 fallback; v5 currently advertises 229 DPI and retains the 800x430 stock fallback. Its Candidate A/B labels therefore must not be copied onto our current configuration as if identical. Lower-load 1280x480 is a reasonable contingency if sustained decoding becomes a demonstrated problem. It is not evidence that changing DPI/resolution will fix the Spotify navigation issue. The PDF's decoder-XML limit is a reported TLX source claim; the matching RDX XML was not available in this review.

### F4 — Overlay priority and ownership remain an RDX integration gap

The PDF correctly treats visible fullscreen, input ownership and normal vehicle interruption as separate questions. V5 currently creates TYPE_SYSTEM_ERROR rather than a scoped ordinary projection window and has a bounded test watchdog; it does not implement the paper's proposed authenticated per-session geometry lease, coordinated SystemUI release, native camera supervision or production recovery.

**Policy discrepancy:** PDF pages 4/9 say TYPE_PROJECTED_WINDOW 2037 has layer 5. Available archived RDX PhoneWindowManager groups 2037 with 2029 at layer 13; layer 5 is 2031 (voice interaction). The PDF's policy container hash differs, so this is a discrepancy requiring its exact source/DEX, not a definitive claim that the friend is wrong. Do not transplant its table into a live RDX priority decision. The same local archived code puts type 2010 at 24, SystemUI panel 2014 at 16, vehicle warning 2039 at 31 and rear camera 2041 at 38; these are archived static mappings, not proof of current compositor or native camera behavior.

Home/exit/input ownership and normal OEM interruption need explicit RDX evidence before production reliability claims. No layer change or camera test was performed here.

### F5 — Runtime overscan is a real research lead, not the next input repair

PDF page 11 explicitly labels its negative-overscan route global, persistent and untested. Available local WMS checks WRITE_SECURE_SETTINGS, saves DisplaySettings and reconfigures; DisplaySettings uses display_settings.xml. The cited width algebra is internally consistent.

The friend's captured shell permission grant, exact current policy effects, actual prior tuple and independent restoration route were not re-established in this offline review. This route changes more than AA and does not by itself update video negotiation or prove BZone input relinquishment. Our existing NOTES/October 27 review already record a historical user-run overscan precedent, so it is additional analysis of a known lead, not newly demonstrated RDX behavior. No overscan command should be run merely because this PDF contains the value.

### F6 — CarPlay findings transfer as offline leads, not a live change

PDF pages 7/8/12 trace existing native configuration setters, shared advertisement/HID dimensions and a missing negotiated-size bridge; it explicitly admits its review diff does not restore partially changed native state. Three relevant CarPlay native library hashes match our files, strengthening the relevance of those native-code leads. The CarPlay APK container differs and the underlying curated disassembly/check bundle is unavailable, so setter/control-flow assertions remain reported research rather than independently reproduced findings here.

No CarPlay stream, setter, modified APK or lifecycle was tested on the RDX in this review. Keep this separate from the current AA input investigation.

## 6. Primary evidence for each finding

| Finding | Evidence |
|---|---|
| F1 | PDF pages 2,19,20; artifact-comparison.json with actual local paths/hashes; apks/AndroidAuto-current-2026-10-22.apk; last attempt preflight services.jar; framework parity review describing independently verified timestamp-only differences |
| F2 | PDF pages 3,6; current factory ProjectionActivity.java:559–615 and :2308–2326; GalIntegration.java:108–115 appends 92/93/122/123; private helper InputEvents.java:5–6 and InputSource.java:64; latest RDX run RESULTS.json and capture hash 3A41DF093BE406D397730394693E58593488CF91AE06984B33C6B7194F199757 |
| F3 | PDF pages 5–6; arithmetic-checks.json; shared VideoSink.java:26–29 (229 DPI, 360 total margin, retained fallback); latest run decoded VIDEO_GEOMETRY_V1 diagnostics |
| F4 | PDF pages 4,9,13–15; AaOverlayService.java:250; archived Policy PhoneWindowManager.java:1644, :1672–1682, :1714–1731; Framework WindowManager.java:208/225 confirms named types; PDF's different policy SHA in artifact-comparison.json |
| F5 | PDF page 11; WMS.java:6055–6084; DisplaySettings.java:42 and :245 onward; archived PhoneWindowManager.java:1765–1769 and :3101 onward; EVENING-EXPLORATION-PLAN-20261027.md:14 records older precedent |
| F6 | PDF pages 7–8,12,18; three exact native-library matches in artifact-comparison.json. No underlying friend native audit bundle available to independently reproduce its offsets/checks |

Paths for decompiled sources are rooted under `decompiled/AndroidAuto-current/sources/`, `decompiled/Policy/sources/`, `decompiled/Services/sources/` or `decompiled/Framework/sources/` as indicated. Report prose is not substituted for the source evidence.

## 7. Assumptions

Friend's TLX model/firmware and reported hash provenance are taken from the PDF/user, not independently attested. Equality checks establish correspondence to the printed hashes only. Shared software components can coexist with different hardware and configuration.

## 8. Unresolved uncertainties

Exact policy-layer discrepancy, contents of differing containers, hardware-specific touchbridge/camera/mic behavior, raw friend's evidence/model outputs, full runtime overscan/restoration behavior, sustained profile performance and current Spotify failure cause. The 1,252 model scenarios and other static-check counts are reported results, not rerun tests or device evidence.

For the current AA issue, the most concrete next proposal is a separate candidate restoring stock swipe mappings **and supported-key registration**, with host mapping tests and a targeted replay of the same Spotify layout. Keep v5 intact; do not combine that experiment with scaling, overscan, DPI or audio changes. This recommendation does not itself start or authorize implementation/live testing.

For a productive response to the friend, provide the public CURRENT-FINDINGS and effective source paths, point out that the RDX already has a bounded working v5 display/audio/click result, and request the exact policy layer snippet/hash plus curated source/check bundle for the discrepancy. Do not send private APKs, credentials or raw logs. No message was sent to anyone.

## 9. Exact diff summary

Added local PDF extraction/rendering, hash-comparison and arithmetic evidence and this ten-section review. No changes to project production code, APKs, source PDF, guards, device state or Git/publication.

## 10. Preservation checks performed

Source PDF hash before/after matched; working v5 APK hash matched; four frozen anchors matched (preservation.json). Reader dependency installation and PNG/text outputs stayed in project-local review/tool directories. No credentials read, ADB/device actions, signing/builds, binder execution, settings writes, guard bypass, Git mutation, milestone advancement or friend contact.
