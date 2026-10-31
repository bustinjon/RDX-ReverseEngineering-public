# Evidence index for the offline review

No vehicle or phone commands were run for this review. Reports below are dated evidence, not new milestone declarations. Root-relative paths are used so Claude can locate the originals.

| ID | Primary evidence / canonical report | Supports |
|---|---|---|
| E1 | `analysis/test-prep/runs/helper_20261031T051918_e24f47ab1b7548cb92193e19fa5dc8f4/REPORT.md`, RESULTS.json, collection.json and original capture | Latest C458 candidate: operator confirms movement/Select/Back; right-third Spotify controls fail; 18 duplicate ENTERs removed; no forwarded duplicate DOWN |
| E2 | Same run, `device-evidence/rdx_7af26727dcdd45778868a2a86049dff6/capture.log`; SHA-256 `1C30CD45060A522FDB06A2F1950A0A48EC1744D98F2A0BF64562B9096628D1F2`; boundary 33919, PID 8808 | Actual key/motion/callback sequence; main Down submissions and ignored secondary key events |
| E3 | `coordinate-study.json`, coordinate-strokes.csv and Coordinate-Study.js in this folder | 149 contact IDs; 15 consecutive strokes have constant x=1723, 178 x-clipped samples, and no native directional key associated with those strokes; raw key 38/39 details |
| E4 | `decompiled/SystemUI/sources/com/android/systemui/statusbar/auto/HondaBZoneHoverRootLayout.java:130-170`; HondaStatusBar.java:318-342; systemui-archive/verification.json | Archived B-zone handling: raw 38 on release invokes Bottom, 39 invokes Top; OEM implementation changes cards/pages. Mapping independently checked in archived APK DEX; current vehicle SystemUI binary parity UNKNOWN |
| E5 | `analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/InputEvents.java:5-25`; AaOverlayService.java:153 onward; AaSessionService.java:189-215 | Current raw key allowlist excludes 38/39; first local key-path divergence; raw x clamped to 1324 before native pad send |
| E6 | `decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/service/media/GalMediaSessionCallback.java:139-203` | Factory Next/Previous callbacks send protocol key 87/88 DOWN/UP; release scheduled after 100 ms |
| E7 | Factory `.../ui/ProjectionActivity.java:2267-2370`; `decompiled/AndroidAuto-current/sources/com/google/android/projection/proto/Protos.java:3155`; current helper InputSource.java native declarations | Factory forwards media keys and relative rotary events; rotary protocol code is 65536; helper already declares nativeSendRelativeEvent but exposes no delivery wrapper |
| E8 | `analysis/test-prep/runs/helper_20261031T041524_80b16905aa3048e99d3f52f817379dbb/REPORT.md`, RESULTS.json and original capture | Hover restoration restored grid navigation; panel still failed; native Down burst already present while panel inaccessible |
| E9 | `analysis/test-prep/runs/helper_20261031T000705_990b5e7dac5f4bf9b19bf2639551fe4f/RESULTS.json` and capture | Page/move-key variant initially changed tracks, then failed after panel return; do not repeat it as an untried fix |
| E10 | `analysis/parallel-aa-receiver/src/com/google/android/projection/protocol/AudioSource.java`; factory `.../audio/MicrophoneRecorder.java:24,97,186,295-343`; helper manifest | No mic capture/send implementation; no RECORD_AUDIO permission; factory callback returns incrementing session IDs starting at zero; ACK accounting exists in stock |
| E11 | Factory `.../audio/GalAudioManager.java:42-92`; `.../ui/ProjectionActivity.java:2509-2565`; current GalReceiver.java:93 | OEM mic ownership/processing setup and restoration; current voice notification only logs |
| E12 | `analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/UsbHelperService.java:68-85,107-151,163-182,207-213`; AaSessionService.java:459-469,589-638 | Persisted cooperative policy now loads before startup; detach only logs; helper polling stops at GRANTED/FAILED; session shutdown does not visibly return helper phase to WAITING; transport abort posts shutdown to handler |
| E13 | Current `AudioSink.java:33-61,155-188`; AaSessionService.java:312-338 | Real PCM output/focus handling exists; both tracks use Android STREAM_MUSIC; guidance requests transient ducking; mic is service 7 |
| E14 | Current `SensorSource.java:60-100` | Advertises 15 sensor types and emits static parked/day/zero-speed initial state; not live vehicle telemetry |
| E15 | Helper AndroidManifest.xml; BootBlockerReceiver.java; BootBlockerService.java:18-25,73-76; AaOverlayService.java window layout | Launcher/USB attach already exist; boot starts an eight-second high-level cover after an eight-second delay; overlay is SYSTEM_ERROR; third-party integration/interrupt behavior not proven |
| E16 | `analysis/parallel-aa-receiver/HONDA-UNAUTHORIZED-APP-WARNING-PHONEFREE-ANALYSIS.md` and HONDA-WARNING-DETECTOR-PERSISTENCE-MAP.md with their saved DEX/branch evidence | Persisted detector history and current package flags; no established normal-app per-package exemption; masking the dialog does not clear detector state |
| E17 | `analysis/agent-reviews/friend-pdf-20261030/REVIEW.md`, artifact-comparison.json and original rendered PDF pages | TLX D1.6.4 comparison: eight matching artifacts; does not establish identical physical inputs, mic, policy or camera behavior |
| E18 | `before.json`, git-head.txt, git-status.txt, public-status.txt in this folder; latest build-report.json | Tested source snapshot, preservation checks, local HEAD `a313153f4dcfa162ba878915f15a2fa24b2b2264`, dirty private workspace and separate clean public snapshot; remote visibility not verified |
| E19 | `scripts/device-car-test-watchdog.sh`; refused-run cleanup evidence under runs `helper_20261031T050743_...` and `helper_20261031T051112_...`; successful run final-ready.json | Timer currently sleeps then runs cleanup; final readiness correctly refused Diagnostics; manual cleanup can leave the sleeping watchdog until explicitly stopped |
| E20 | `photos/THISSETUP.jpg`; SHA-256 `195826E670CC17B26CD4C254A320F50CA8A7AEC3A6FF361ECC16562D41429656`; latest private capture frame_5_943263.png | Right widget draws its skip controls; full Spotify player can select Next. No exact photo/log clock synchronization established |

## External primary sources checked on 2026-10-31

| ID | Source | Bounded use |
|---|---|---|
| W1 | [Google Desktop Head Unit documentation](https://developer.android.com/training/cars/testing/dhu) | Supports touchpad/gesture and controller comparisons, sequential rotation, input flags and desktop testing. Does not prove RDX behavior. |
| W2 | [Android MediaSession API](https://developer.android.com/reference/android/media/session/MediaSession) | API exists from Android 21 and accepts media-control callbacks. OEM routing/permissions still need qualification. |
| W3 | [Google Android Auto voice help](https://support.google.com/androidauto/answer/6348083?hl=en) | Phone-managed Gemini/Assistant and supported user initiation paths. Does not guarantee this receiver's microphone path. |
| W4 | [Android AudioRecord API](https://developer.android.com/reference/android/media/AudioRecord) | Standard recording permission and initialization requirements. Does not establish cabin-mic routing. |
| W5 | [Open Headunit upstream](https://github.com/andreknieriem/open-headunit) | Auditable alternative; maintainer documents USB/native wireless/developer-server approaches and legacy-trigger caveats. Actual RDX APK/ABI/input qualification remains UNKNOWN. |
| W6 | [HUR developer page](https://www.b3itlabs.com/prod.php?id=1) and [official listing](https://play.google.com/store/apps/details?id=gb.xxy.hr) | Alternative packaged receiver candidate; no purchase/installation or exact-version compatibility claim made. |

No community troubleshooting answer was used as authoritative evidence. Production code and devices were unchanged.
