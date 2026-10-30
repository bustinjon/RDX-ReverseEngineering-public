# Decoder0.2 independent APK audit — 2026-10-23

**PASS: READY for a separate, authorized phone-disconnected decoder test. Next car session still M4 ONLY. No Android codec execution occurred here.**

Package com.rdx.fullscreen.decodertest, versionCode2/versionName0.2.0-with-clips, min21/target22.
APK `build/20261023-112223-673/rdx-decoder-test-0.2.0-with-clips-development.apk`.
SHA256 `ADD395FC46626DD3C43F527E10B1D8C49092DB43C8088CAEABB4A553BE90A374`.
Signer SHA256 `c001f59b25081ddfc73937155ca3580717e817c45c66e68b9e059737b0b28831`.

Fresh API22 v1 signature/alignment checks PASS. Actual packaged manifest has one landscape Activity, no permissions/shared UID/services/receivers/filters. JADX/SDK DEXDUMP/reference/class/string audits and source hash comparison PASS. Manual final control-flow review confirms explicit selection/START, named TI creation only, no createDecoderByType/software fallback, no allocation on launch, stable Surface dimensions before start, one worker and no automatic sequence.

Final ZIP: six MP4 clips stored uncompressed, a small public host-SPS catalog, manifest/DEX/signatures only. `latest-audit.txt` points to evidence including `packaged-assets-validation.json`: each MP4's packaged hash matches independently inspected source; metadata catalog matches; frame counts/dimensions/profile/B-frame invariants PASS. No protocol credentials/native libraries are present.

| Check | Result |
|---|---|
| MediaExtractor / explicit TI MediaCodec | PRESENT, intended |
| Actual component string OMX.TI.DUCATI1.VIDEO.DECODER | PRESENT |
| Generic/software decoder fallback | ABSENT |
| USB API / AOA / GAL / Honda package control | ABSENT |
| Runtime.exec / ProcessBuilder / native loading | ABSENT |
| Settings/property/display mutation / root | ABSENT |
| Network/audio/microphone/sensors | ABSENT |
| Boot/USB auto-start / background Service | ABSENT |
| Assets | Six hash-verified stored MP4s + public SPS catalog |

Logs separate host-verified input SPS from MediaExtractor's format and actual decoder output format. This avoids treating a1080 display height as a1080 coded height. UI reports clip/raster/FPS/10sec/requested component; progress/status and final counts. No released-buffer=displayed-frame claim.

Pump deadline20sec, dequeue waits2ms, periodic250ms UI watchdog reports total25sec or cleanup5sec deadline. Cancellation is cooperative; platform Binder calls configure/stop/release cannot be forcibly bounded by Java timers. A timeout is STOP, not a guaranteed successful recovery. No media-process restart/kill/reboot/retry is implemented. One test case per explicit user action.

All files also decoded successfully with host FFmpeg software decoder; that only verifies file integrity and is **not TI or vehicle validation**. Representative1920x720 frame was visually inspected for labels/movement/grid/center/edges. Profile level4.2 clips deliberately test a higher envelope; acceptance/performance remains unknown.

Historical0.1 APK A9509D00E312725F0062292950F513FF44BD9D5AB3C38C4B9A6B864397504B05 and its source snapshot remain preserved. Do not use an intermediate0.2 build; this audit is tied to the exact hash above. See clips/CLIP-MANIFEST.md and current DECODER-TEST-PLAN.md.
