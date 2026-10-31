# Media/input fix candidate — 2026-10-31

## 1. Files inspected

PROJECT-RULES.md and root AGENTS.md; canonical Spotify matrix/mechanism and media/video reviews; last long-drive raw key/volume evidence; current InputEvents, AaOverlayService, AaSessionService, InputSource and retained GalReceiver. Stock decompiled HondaStatusBar, SeekKeyHandler, VolumeManager, PhoneWindowManager, ProjectionActivity, GalIntegration and amplifier broadcast definitions supplied the key/payload/window contracts. Baseline and new build metadata, APK public entries and compiled classes were compared. Indexed excerpts are in stock-source-evidence.txt; original-run references are in observed-media-volume-keys.txt.

## 2. Files changed

Production changes: InputEvents.java, AaOverlayService.java and one live registration line in AaSessionService.java; new VolumeFeedback.java. All are beneath `analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/`. Added this scoped candidate's tests/provenance/verification/evidence/preparation/report. Standard builder created `analysis/parallel-aa-receiver/usb-helper/build/20261031-151555-694/` and updated latest-build.txt. No installation or device commands.

## 3. Commands run

Saved procedures: Snapshot-Baseline.ps1; Test-MediaInput.ps1; Build-Candidate.ps1; Generate-Preparation.ps1; Save-SourceEvidence.ps1; Verify-Candidate.ps1. JDK javac/java compiled and ran actual pure-Java input/volume implementations; existing builder performed normal opaque signing. SDK dexdump inspected public DEX. Read-only `git diff --no-index` recorded each production diff. `Run-CarTest.ps1 -Mode Prepare` used a nonexistent ADB path, generating an offline artifact plan only. Get-Content/rg/Get-ChildItem inspected scoped evidence. Initial guessed Services/PhoneWindowManager path was absent; the actual class is under decompiled/Policy. No Git mutation, network, device action or delegation.

## 4. Tests run and results

**77 host checks PASS**: normal Page/Move/Select/Back delivery; no declared arrows19–22; declared media87/88; Honda138/139 and standard87/88 media dispatch; balanced release pairs; held-key repeat suppression; orphan/duplicate/cancelled releases; wrong scan/source/device rejection; ownership and cross-raw/device mismatch; reset; unchanged Select cancellation and hover dedup; actual amplifier level acceptance, duplicate suppression, invalid-value preservation and lifecycle reset. No Android UI, OEM broadcast delivery, actual JNI or car behavior is simulated by these host checks.

Artifact validation PASS: three changed existing Java inputs, one new input,24 unchanged existing inputs;28 total. Compiled class differences stay within the allowed helper classes. GalReceiver.class is byte-identical to the preceding navigation-focus candidate, so its earlier10 behavior cases and negative-control results remain applicable without rerunning unchanged code. Packaged DEX equals build DEX and contains new diagnostic markers. Five non-DEX public APK entries are unchanged. API22/v1 signature and alignment PASS.17 previous/frozen artifacts and six shared guard/runner files retain their hashes. PS scripts parse; untimed wrapper/readiness stage are independently compared with parent templates, and collector/four shell payloads are byte-identical copies. Offline CurrentSource/PhonePreference plan PASS.

## 5. Findings and implemented attempts

**Track controls — concrete forwarding gap addressed:** stock SystemUI maps raw138 to seekDown and139 to seekUp; its streaming handler translates these to Previous and Next. The saved drive recorded those exact raw codes, scans66/67, source257 and device1 reaching our overlay. The old input filter did not forward them. New MediaButtons handles those signatures and standard87/88, consumes recognized press/release events locally, and sends one balanced AA pair on an owned noncancelled release. Repeats and orphan releases do not create skips. New supported keys declare87/88 to the native service. Both raw phases and emitted/native events are logged. This covers the observed car path and standard media events; delivery from every steering-wheel route is not established. OEM out-of-band media processing, if any, is not globally disabled. Actual one-action-per-press and wheel behavior require the car test. Long-press fast-forward/rewind is outside this candidate.

**Volume display — narrow alternate presentation:** Honda's volume dialog uses window type2014/layer16, while our current type2010 AA overlay is layer24 in the inspected policy. This is a concrete stacking reason the OEM dialog can be hidden. Lowering the entire AA window could change working input/OEM layering, so no window type, flags or position changed. Instead, a noninteractive TextView inside the existing AA container displays `Volume N` using the exact amplifier broadcast/byte payload read by SystemUI. It never adjusts vehicle volume or estimates a value from key counts. Changes show for3 seconds; an ordinary volume key can re-show the last actually received level. Repeated identical background data does not continually show the HUD. Receiver/callback/state cleanup follows overlay teardown. Android broadcast delivery, visible rendering and lack of actual focus interference are hardware UNVERIFIED; logs distinguish registration, received data and attempted display. This is a new indicator, not a patch to Honda's volume dialog.

**Spotify row — evidence-based profile experiment:** the saved matrix shows that Down-key suppression alone did not fix title-to-playback traversal. It does not include the combination of page/move keys, no declared arrows, absolute=true and ordinary Down, under the current hover implementation. Factory integration requests that pad mode and sends PageDown normally. This candidate restores native93 for raw146 and requests true/true for live pad navigation/absolute flags, retaining the existing page/move Left/Right/Up, Select, Back, geometry and hover paths. It is a navigation subset plus the newly supported media keys, not complete factory parity. Spotify's actual focus implementation and causal defect remain UNKNOWN. A gap in the test matrix is not evidence the row is cured.

**Maps fix retained:** the already verified request-dependent navigation-focus reply/logging is unchanged. No sensors, audio transport/focus, mic, Gemini or vehicle-data behavior changed.

APK: **rdx-usb-helper-v6h-media-input-a.apk**, SHA-256 **A2F4785466AD41E2459051A096B917881349EC2B64E06303D19F66DA38D4FB0F**. Separate Maps-only candidate21037…4084 remains preserved.

## 6. Primary evidence for each finding

- Key meaning: `decompiled/SystemUI/sources/com/android/systemui/statusbar/auto/HondaStatusBar.java:2518–2535`, SeekKeyHandler.java:250–266. Original live capture references and signatures: observed-media-volume-keys.txt; original long-drive capture.log:2342–2347.
- New dispatch/declaration: InputEvents.java:20–60; AaOverlayService.java:190–210. Behavioral evidence: MediaInputTest.java, host-test-result.json and host-tests/test-output.txt.
- OEM volume input: stock VolumeManager.java:259–273,456–465,647–650; its numeric display uses mAmpVolume. OEM dialog: HondaStatusBar.java:3110–3135; layer contract: `decompiled/Policy/sources/com/android/internal/policy/impl/PhoneWindowManager.java:1637–1724`. New passive source/UI: VolumeFeedback.java and AaOverlayService.java:94–107,575–623. Exact unchanged window parameters are checked by Verify-Candidate.ps1.
- Spotify comparison: `analysis/agent-reviews/spotify-row-mechanism-20261031/REPORT.md` section5E/test-matrix.json; stock GalIntegration.java:107–126 and ProjectionActivity.java:2303–2326. Actual live registration change: AaSessionService.java:304; restored Down dispatch: InputEvents.java:22–26. No phone focus-tree or new UI outcome is claimed.
- Build identity/preservation: candidate.json, before.json, validation.json, compiled-class-diff.json, public-apk-entry-hashes.json, candidate-dexdump.txt and build-directory signature/alignment reports. Maps regression evidence is retained in the preceding candidate's host-test-result.json/negative-control-result.json with unchanged GalReceiver.class verified here.

## 7. Assumptions

User's request authorizes offline implementation/test/build attempts for all three named issues. It does not authorize a connected test this turn. Observed Honda raw signatures are treated as the specific vendor-button path identified by stock code, not as proof every steering-wheel button uses it. OEM volume byte payload semantics follow inspected SystemUI; delivery to this package remains to be observed.

## 8. Unresolved uncertainties

All three vehicle outcomes remain UNKNOWN until tested. A valid local native return is not proof of phone receipt/playback action. A separate steering-wheel broadcast/MediaSession path may need additional work if standard/raw key events do not reach this overlay. Independent OEM processing may cause duplicates and must be checked rather than globally disabled. The HUD may receive no amplifier broadcast or may not visibly render; it intentionally provides no guessed fallback. Existing TextureView screenshots exclude this HUD, so visibility needs operator observation. Spotify could still fail under the restored profile; this combined candidate cannot attribute an improvement to one profile difference without a later controlled comparison. Full static audit remains PENDING. Untimed launch and existing failure handling are retained; no new reconnect implementation is included.

## 9. Exact diff summary

- InputEvents: declare87/88; remove the Down-probe consume-only branch; add isolated MediaButtons press ownership/release/cancellation/reset adapter. Existing key mapping, B-zone adapter, SelectPress and HoverContact logic retained.
- AaSessionService: one live registerTouchPad call changes its final boolean false -> true; diagnostic call unchanged.
- AaOverlayService: add media adapter/logging before generic dispatch; pass through ordinary volume handling; add passive OEM volume receiver, noninteractive temporary HUD and teardown. Window type, flags, position and video/coordinate behavior unchanged.
- New VolumeFeedback: actual signed-byte range validation, change detection and reset only. Three exact diffs are saved as InputEvents.diff, AaSessionService.diff and AaOverlayService.diff.
- New candidate analysis/preparation files and standard build/latest-pointer outputs. No shared guard/script or historical report edit. No Git writes.

## 10. Preservation checks performed

17 previous/frozen artifacts, including navigation-focus21037…, long-driveD1A29… and all four frozen anchors, match their before hashes. Six shared guard/runner files are unchanged.24 unrelated Java inputs and compiled classes outside the scoped helper families remain unchanged; GalReceiver.class is explicitly identical. Five public non-DEX APK entries match; private credential/signature entry contents are excluded before opening and no key material is inspected. No frozen rebuild, M5 guard bypass, milestone advancement, ADB/car/phone/USB action or Git mutation. Future procedure and evidence criteria are in NEXT-TEST.md.
