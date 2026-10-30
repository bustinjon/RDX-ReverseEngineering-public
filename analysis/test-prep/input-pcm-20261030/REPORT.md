# Input and PCM candidate — 2026-10-30

Local implementation and validation complete; hardware behavior UNKNOWN. No device commands were run for this preparation. This does not change milestone status or authorize a live milestone.

Candidate: `analysis/parallel-aa-receiver/usb-helper/build/20261030-181715-757/rdx-usb-helper-v6h-input-pcm-v3.apk`

SHA-256: `60EBAB8EA01F1DD81E04CAACD12C19EF055C6156E061EDF9F6DB01C3379060BC`.

## 1. Files inspected

- `PROJECT-RULES.md` and the helper source files listed below.
- Previous successful geometry test: `analysis/test-prep/runs/helper_20261030T220238_2e0863ac272d459989e6ab863a86f66b/RESULTS.md` and `device-evidence/capture.log`.
- Factory input reference: `decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/ui/ProjectionActivity.java` (hover mapping at 574–615; key handling at 2267–2287).
- Build metadata: candidate directory `build-report.json`, signature verification and alignment outputs.
- `validation.json`, `results.txt`, and prepared artifact plan under `analysis/test-prep/runs/helper_20261030T221833_c4f75de8784748fc876231f495ec3029/`.

## 2. Files changed

Paths below are relative to `analysis/parallel-aa-receiver/`:

- `usb-helper/source/com/rdx/fullscreen/usbhelper/AaOverlayService.java`: video window focus, navigation key forwarding and hover conversion.
- `usb-helper/source/com/rdx/fullscreen/usbhelper/AaSessionService.java`: key forwarding and audio context wiring.
- `usb-helper/source/com/google/android/projection/protocol/InputSource.java`: register Back/DPAD/center keys and log native send result.
- `src/com/google/android/projection/protocol/AudioSink.java`: PCM playback implementation.
- New `usb-helper/source/com/rdx/fullscreen/usbhelper/InputEvents.java` and `src/com/google/android/projection/protocol/PcmFrames.java`: pure input/PCM helpers.
- New `tools/car-test/InputPcmTest.java` (repository relative).
- Generated build, local preparation and validation artifacts; this report.

Other working-tree changes predate this implementation. Repository-wide diff statistics include those changes and are not this task's diff.

## 3. Commands run

- Existing `scripts/Build-RdxUsbHelper.ps1` workflow, final label `v6h-input-pcm-v3`; build/sign/align succeeded. Existing authorized local signing workflow used; no credential contents recorded here.
- JDK 17 compilation and execution of `InputPcmTest` with `InputEvents` and `PcmFrames`.
- PowerShell artifact-plan and phone-preference assertions; ZIP DEX extraction/hash comparison; public certificate comparison; `Get-FileHash` for frozen anchors.
- `scripts/Run-CarTest.ps1 -Mode Prepare`, CurrentSource, PhonePreference, HondaPhoneDisabled, SafetySeconds 120; deliberately nonexistent device-tool path. Generated artifact plan only.
- Read-only `rg`, `Get-Content`, directory listings and `git diff --stat` for inspection. No commit, staging, reset or cleanup command.

## 4. Tests run and results

- Host test: **PASS: 25664 input/PCM checks**, saved in `results.txt`. These are assertions, including repeated byte comparisons across 100 partial-write cases, not 25,664 independent scenarios.
- Covers hover mapping, key whitelist, invalid PCM rejection, immutable copying, complete partial writes and termination on zero/negative/overreported writes.
- All 24 Java source inputs compiled. Source provenance comparison found zero differences after build.
- API-22 signature and alignment verification passed; signer matches previous geometry candidate. Packaged DEX hash matches generated DEX.
- Frozen anchor hashes all match. Machine-readable evidence: `validation.json`.
- Android runtime, JNI key acceptance, AudioTrack lifecycle, actual audio routing and physical input delivery: **NOT TESTED**. Full static audit remains **PENDING** in build metadata.

## 5. Findings

1. A candidate now requests window focus for video and forwards Back/DPAD/center keys. Hover enter/move/exit are converted into down/move/up. This addresses the observed Home-control symptom, but does not establish its cause or prove that the overlay receives physical input.
2. AudioSink now copies PCM16 into a bounded queue and writes it through public AudioTrack. Received frames, played bytes, drops, focus changes and playback failures are observable. Successful writes alone would not prove audible speaker output.
3. The last successful video test did not establish whether audio data arrived. Its older stub lacked the new PCM counters. Audio routing remains UNKNOWN.
4. The candidate is ready for a controlled hardware evaluation; it is not a verified touch/audio fix.

## 6. Primary evidence for each finding

- Finding 1: `AaOverlayService.java:137` key dispatch, `:146` hover dispatch, `:235` focusable video flags and `:254` focus request; `AaSessionService.java:189` forwarding; helper `InputSource.java:64` native key registration. Factory hover mapping is referenced in section 1.
- Finding 2: `AudioSink.java:30` bounded queue, `dataAvailableCallback`, `playLoop`, `:155` track diagnostic and `:172` summary. `PcmFrames.java` implements validation/copy and partial-write handling. `results.txt` records host assertions.
- Finding 3: prior run's `device-evidence/capture.log` records audio setup and successful video. Lack of a data diagnostic in that implementation cannot establish absence of data. User reported no audio and Home responding to touch.
- Finding 4: `validation.json` explicitly records `hardware_tested: false`, verified APK hash and local verification results.

## 7. Assumptions

- Factory hover mapping and the existing native key API are applicable to this helper. Hardware verification is required.
- Current negotiated formats remain PCM16 mono/stereo; other formats are rejected by this candidate.
- Public STREAM_MUSIC playback may reach the intended output. OEM route ownership is UNKNOWN; no privileged route or system volume changes were added.

## 8. Unresolved uncertainties

- Whether physical touchpad input reaches the newly focusable window, whether JNI accepts forwarded keys, and whether pointer behavior is correct.
- Whether media/guidance PCM is delivered; whether focus is granted; whether audio reaches speakers.
- Audio concurrency and shutdown behavior on the head unit. A blocked worker has a two-second join diagnostic; host tests do not exercise Android AudioTrack.
- Counters are diagnostic, not atomic accounting. Single-pointer hover/navigation only; rotary, multitouch and microphone capture are not implemented by this change.
- For the next authorized test, inspect INPUT_FOCUS_REQUEST/INPUT_FOCUS, INPUT_KEY/native results, touch markers, PCM counters, AUDIO_TRACK_READY, AUDIO_FOCUS and AUDIO_SUMMARY. Use known audio at normal volume. If bytes are written but no sound is heard, investigate routing using that evidence rather than assuming a transport failure.
- No live test was initiated. Physical test readiness and applicable authorization must be established before any device action under the current instructions.

## 9. Exact diff summary

- Overlay: add navigation listener method, filtered dispatchKeyEvent, mapped dispatchHoverEvent, focus request/change logs and focusable VIDEO flags. Existing video geometry and raw touch coordinates retained.
- Session: implement onAaKey and provide application context to media/guidance AudioSink.
- Effective helper InputSource: add `{4,19,20,21,22,23}` registration and native key result logging.
- AudioSink: replace discard-only PCM behavior with a 16-frame queue, 64-KiB maximum validated frame, native acknowledgement, session filtering, public focus/AudioTrack worker and teardown. Handle partial writes; suspend after permanent focus loss until a new playback/session request; throttle denied focus attempts.
- Add pure helpers and host assertions. No frozen artifact rebuild, M5 guard change, factory package replacement or milestone transition.
- Final candidate supersedes earlier local input/PCM builds; use only the hash at the top of this report. No candidate from this preparation has been installed.

## 10. Preservation checks performed

`validation.json` contains expected paths and actual SHA-256 values for all four PROJECT-RULES frozen anchors; every `match` is true. API-22 signature, alignment, source provenance and packaged DEX checks passed. No device commands, frozen artifact modifications, guard bypasses, Git mutations or milestone advancement occurred in this preparation.
