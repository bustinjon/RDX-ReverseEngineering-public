# Click and audio focus candidate — 2026-10-30

Built locally, not installed or hardware tested. Candidate: `analysis/parallel-aa-receiver/usb-helper/build/20261030-184144-863/rdx-usb-helper-v6h-enter-focus-v4.apk`.

SHA-256: `DC4E6E1B3D3EDE944F953DD20F804FC71F3AED07FBDD80E51566C5853FFB3863`.

## 1. Files inspected

- `PROJECT-RULES.md`.
- Saved run `analysis/test-prep/runs/helper_20261030T222844_7dfd0314697941a49430aae941cae1c8/`: session.json, device-evidence/capture.log, watchdog.log, postchecks.txt. Capture SHA-256: `8C2D15BB40BA2C0864063A5142ED1CBE904F384891518CA9CFE954848EE887CF`.
- `decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/ui/ProjectionActivity.java:2303` and matching `com/google/android/projection/proto/Protos.java:1733`, `:1783`.
- Helper InputEvents, AaOverlayService, AaSessionService; shared GalReceiver, AudioSink, PcmFrames; host InputPcmTest; build metadata.

## 2. Files changed

Relative to `analysis/parallel-aa-receiver/`:

- `usb-helper/source/com/rdx/fullscreen/usbhelper/InputEvents.java`
- `usb-helper/source/com/rdx/fullscreen/usbhelper/AaOverlayService.java`
- `usb-helper/source/com/rdx/fullscreen/usbhelper/AaSessionService.java`
- `src/com/google/android/projection/protocol/GalReceiver.java`
- `src/com/google/android/projection/protocol/AudioSink.java`
- New `src/com/google/android/projection/protocol/AudioFocusPolicy.java`

Also `tools/car-test/InputPcmTest.java` and generated build/preparation/report files. No factory APK replacement or frozen artifact rebuild.

## 3. Commands run

- Local file inspection with Get-Content and rg; saved capture boundary/counter analysis.
- JDK 17 javac/java host test.
- `scripts/Build-RdxUsbHelper.ps1 -Version v6h-enter-focus-v4` using the existing authorized signing workflow.
- Get-FileHash checks for candidate, recorded Java inputs and four frozen anchors.
- Run-CarTest Mode Prepare with CurrentSource, PhonePreference, 120 seconds and deliberately nonexistent ADB path. Prepared plan: `analysis/test-prep/runs/helper_20261030T224230_c4afee7c337d4ced82d47ca8885bf059/artifact-plan.json`.
- No ADB/device commands in this build task.

## 4. Tests run and results

- **PASS: 25696 input/PCM checks**, `results.txt`. Includes prior PCM/input assertions plus Enter normalization and focus request/reply/change mappings. Count includes repeated per-byte assertions, not independent scenarios.
- Full 25-source Java build, DEX, packaging and signing succeeded.
- API-22 signature verification and alignment passed. Current source hashes match all recorded build inputs (zero differences).
- Candidate APK actual hash matches build metadata. All four frozen anchor hashes match; see `validation.json`.
- Full static audit remains PENDING. Android focus delivery, actual key codes, native focus exchange, PCM playback and speaker routing remain untested for this candidate.

## 5. Findings

1. Prior test obtained overlay focus and forwarded navigation events. User confirmed movement, but no click/audio. A missing Enter-to-select mapping is a concrete implementation gap; whether this physical click produced Enter is UNKNOWN because the prior handler did not log unsupported keys.
2. Prior protocol audio callback unconditionally sent state 3 (LOSS). That cannot grant the phone playback focus. The saved test does not prove that this callback was invoked; it had no request diagnostic. Therefore this is a code defect and plausible contributor, not an established sole cause of silence.
3. Saved run has two audio setup callbacks, zero PCM diagnostic entries and zero AudioTrack-ready entries after the unique run boundary. It provides no evidence of PCM playback or audible routing. Click failure may also have prevented initiating playback.

## 6. Primary evidence for each finding

- Finding 1: capture lines 37499–37500 show focus true; 37923 onward show navigation keys. `previous-run-observations.json` records 36 forwarded key events and zero select-key events. Factory `ProjectionActivity.java:2303–2305` maps Enter 66 to DPAD_CENTER 23. New `InputEvents.java:5` implements that mapping; `AaOverlayService.java:138` logs raw key/scan codes and `:142` forwards normalized codes.
- Finding 2: stock `Protos.java:1783` defines GAIN=1 and `:1785` LOSS=3; request values are at 1733–1736. New `GalReceiver.java:86` logs/dispatches requests; `:11` guards and logs responses. `AaSessionService.java:328` defers handling to its Handler, outside the native incoming callback. `AudioSink.java:33` uses the Android focus result rather than claiming unconditional gain. `AudioFocusPolicy.java` and host tests encode the enum mapping.
- Finding 3: capture lines 37567–37568 show negotiated sink formats and 37664/37666 show setup. Machine-readable boundary/counts are in `previous-run-observations.json` (boundary line 29240). Zero log counts are bounded observations, not proof no phone app attempted audio.

## 7. Assumptions

- Stock enum numbers and factory Enter conversion apply to the loaded matching native receiver. Existing JNI signatures were preserved.
- Generic Android STREAM_MUSIC focus and output are usable on this head unit. OEM routing applicability is UNKNOWN.

## 8. Unresolved uncertainties

- Does the physical click send 66? New INPUT_RAW_KEY logs will answer this; other raw click codes must be evaluated from evidence.
- Does the phone request focus and receive a successful response? New AUDIO_PROTOCOL_REQUEST/REPLY and AUDIO_FOCUS_REQUEST diagnostics distinguish this from PCM absence.
- Does PCM then arrive, get written, and become audible? Existing PCM/AudioTrack counters distinguish these stages. Do not infer speaker routing merely from written byte counts.
- Media sink owns protocol focus requests. Guidance retains its existing transient focus behavior; concurrent media/guidance behavior is not hardware validated. This is a limited public-API implementation, not a reproduction of Honda's full OEM focus manager.
- Next test is the same bounded helper test with the phone's factory preference disabled. Candidate is prepared only; no new live attempt was started.

## 9. Exact diff summary

- InputEvents adds normalization 66→23 and accepts normalized keys. Overlay logs raw DOWN key/scan codes and forwards normalized DOWN/UP codes.
- GalReceiver adds an optional audio-focus listener and guarded reply method, replacing unconditional LOSS in the configured helper path. Unconfigured callers retain LOSS fallback.
- AudioSink exposes protocol focus requests using its existing media focus listener: request Android gain/transient/duck, return protocol gain only when granted; release/unsupported requests pause/flush, abandon focus and report loss. Actual media focus changes are observed and forwarded through the service Handler as unsolicited protocol changes.
- AaSessionService wires requests and focus changes to guarded native replies on its Handler. Responses are skipped when no longer running; receiver replies are refused after prepare/destroy.
- New pure AudioFocusPolicy plus 32 additional host assertions. No geometry, touchpad coordinates, native library, watchdog, phone policy or readiness-guard change.

## 10. Preservation checks performed

All four frozen artifact hashes match `PROJECT-RULES.md`, recorded in `validation.json`. No device commands, milestone advancement, Git mutation, factory package modification or guard bypass in this build task. Historical live reports remain unchanged; this is a new report. Latest build metadata points to this candidate; previous candidates remain preserved.
