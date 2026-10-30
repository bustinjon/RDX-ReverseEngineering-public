# OFFLINE CONTINUATION COMPLETE: YES

2026-10-23, project C:/Users/REDACTED\Desktop\RDX-ReverseEngineering. Workspace write/read/delete check PASS. **No ADB, Android installation, vehicle communication or live milestone occurred. NEXT LIVE SESSION REMAINS M4 ONLY, GPT-6.1 Sol High.**

## Host toolchain

No existing encoder was found. Project-local FFmpeg9.0.2 essentials build acquired from the Gyan Windows build linked by ffmpeg.org/download.html. Pinned URL: https://www.gyan.dev/ffmpeg/builds/packages/ffmpeg-9.0.2-essentials_build.zip . Published/archive SHA256 `60F467265B1E312373DBCD92200C2618A74850F98D3D078E94296BB3FA2047BA` matched. Archive paths/symlinks inspected before execution; only ffmpeg/ffprobe and license/readme extracted. No installer/global PATH modification. See tools/ffmpeg/provenance.json and README.md.

- tools/ffmpeg/ffmpeg-9.0.2-essentials_build/bin/ffmpeg.exe: `3256173F3F8BFFD7DF12227C68ADF68025EDB1832273A9530688A7BB1ED8EDEC`.
- ffprobe.exe in same directory: `F0D36ECBBDD3BCFAC3EFA078C96C7271C2E68B3810595552AC3B7F17E9A65C52`.
- Version output9.0.2-essentials_build-www.gyan.dev, gcc16.2.0, static GPL/version3/libx264 enabled. HTTPS publisher checksum verification is not an independent reproducible binary build or upstream source signature.

## Clips generated and independently inspected

All six MP4s reside in `decoder-test/assets/clips/`.10seconds each, Constrained Baseline/yuv420p/no audio/no B-frames; moving testsrc2,100px grid, colored edges/center, resolution/FPS/frame labels.300frames for30fps/600 for60fps;10keyframes at1second spacing. Full bitrate/container/ffprobe/frame/SPS/PPS evidence and CSV/JSON in [clip manifest](decoder-test/clips/CLIP-MANIFEST.md). A representative1920x720 frame was visually inspected. All six decoded successfully with host software FFmpeg; this is not TI/vehicle execution.

| File | SHA256 | FPS / level | Independent SPS coded -> display |
|---|---|---|---|
| grid-1280x720-30.mp4 | B733B0F7FF6C0F856F7F905EEDDD3664DBEAC5F70A18CCCAA4EEE8C41238374C |30 /3.1|1280x720 ->1280x720|
| grid-1280x688-60.mp4 | B1F09F1B81B47DE67B77E60DAF99D682D7E379A6F6A59AD66A1DE33A2F321DB4 |60 /3.2|1280x688 ->1280x688|
| grid-1920x720-30.mp4 | 6A318F17189D63514983AF3FC579D369731ABD49CD33E9B8620A8970A1945621 |30 /4.0|1920x720 ->1920x720|
| grid-1920x720-60.mp4 | EC4AA353496E4D4BD66BD67267B3A47014D7B32A0D4B61DF681455F2D6AA1F8F |60 /4.2|1920x720 ->1920x720|
| grid-1920x1080-30.mp4 | 56652AF8B6448365480DDEB222F7576B1D2AE29527702B66C42C6F12A4774485 |30 /4.0|1920x1088 ->1920x1080|
| grid-1920x1080-60.mp4 | FCD0C365D9557AD81C403FC0E00AEFCCB2A2D13214FE923D92A1A3A3DAAEADAD |60 /4.2|1920x1088 ->1920x1080|

Independent baseline SPS parser scripts/RdxH264Sps.cs parses AnnexB/RBSP/Exp-Golomb dimensions/crop separately from ffprobe. FFmpeg trace_headers agrees:1080 sample width-in-MBs-minus1=119,height-map-units-minus1=67,bottom crop units4 ->8pixels. SPS/PPS IDs0 captured. This is synthetic encoder padding, not evidence that the phone uses1088 or where AA's360px margin lies. Phone SPS/crop/input offset remain unmeasured.

## Decoder revision

Package com.rdx.fullscreen.decodertest/versionCode2/version0.2.0-with-clips; min21/target22.
APK `decoder-test/build/20261023-112223-673/rdx-decoder-test-0.2.0-with-clips-development.apk`.
SHA256 `ADD395FC46626DD3C43F527E10B1D8C49092DB43C8088CAEABB4A553BE90A374`.
Development signer SHA256 `c001f59b25081ddfc73937155ca3580717e817c45c66e68b9e059737b0b28831`.

READY for a separately authorized phone-disconnected decoder session, not the next M4. Final aapt/JADX/DEXDUMP/reference/source/manual review, fresh API22 v1/alignment and packaged uncompressed asset hash/catalog checks PASS. One Activity, no permissions/shared UID/auto-start/native libraries. Requested component exclusively OMX.TI.DUCATI1.VIDEO.DECODER; no generic/software fallback. Only explicit one-clip START allocates; Surface layout settled first. UI shows clip/raster/FPS/duration/component and progress. Input/output format keys, host-SPS coded dimensions, PTS/buffer/EOS/errors/duration logged with unavailable keys qualified. Released buffers do not prove displayed frames.

20sec pump/2ms dequeues; watchdog checks250ms and flags25sec total or5sec cleanup. Java deadlines cannot forcibly interrupt hung media Binder configure/stop/release. Error/shared-media disruption/cleanup failure is STOP; no mediaserver kill/restart/reboot/retry. Explicit order baseline720/30, Honda-like688/60, fullscreen720/30,720/60,1080/30,1080/60. Actual TI level4.2 acceptance/performance unknown. See [APK audit](decoder-test/DECODER-APK-AUDIT.md) and [procedure](DECODER-TEST-PLAN.md).

Historical decoder0.1 APK/source snapshots preserved. No Candidate A/B or factory code changed.

## M5 built and gated

Package com.rdx.fullscreen.m5permission/version0.1.0-M4-PASS-REQUIRED.
APK `m5-permission/build/20261023-112129-849/rdx-m5-permission-0.1.0-M4-PASS-REQUIRED-development.apk`.
SHA256 `757726DE360D466ACE5F7C12A90DE5B4377F2BD19D8D4BD8C13879967FDE95C8`.
min21/target22, same development signer; v1/alignment/aapt/JADX/DEXDUMP/manual flow PASS.

One Service; no Activity/permissions/auto filters/native assets. requestPermission PRESENT, openDevice/claim/control/bulk/release/AOA/GAL/MediaCodec ABSENT. Wrong action/missing m4_pass_confirmed or current exact device-name/VID/PID mismatch stops before requesting. Already-granted returns. One request per Service lifetime, duplicate suppression, nonce/identity/actual-permission callback,45sec timeout, stop/cancel/unregister, START_NOT_STICKY. Acknowledgment is not proof of M4; live M4 PASS plus separate M5 authorization required. SystemUI can resume/create normal Honda effects; pending-callback cancellation does not guarantee permission dialog/grant rollback. [Audit](m5-permission/M5-INDEPENDENT-AUDIT.md), [procedure](M5-USB-PERMISSION-TEST.md). DO NOT RUN WITH M4.

## Clean foundation / disabled M6

`clean-receiver/` now contains21 Java source modules compiled to Java7 library JAR and D8 min22 DEX; no APK/manifest/components/native libraries/credentials.67 synthetic host checks PASS. Parsers/writers/reassembly/capability/channel models are implemented pure logic; permission/transport/TLS/control/video/Surface integration remains contracts or disabled stubs. All supplied constructors initialize local fields/containers only. Method audit excludes USB open/request/claim/transfer, socket/TLS, decoder, shell and native loading. Android inventory only runs on explicit snapshot via injected UsbManager. ARMv7 compatibility is Java-bytecode portability, not native execution.

Tests cover single/multiple frames; partial headers/payloads/one-byte chunks; integrated fragmented wire; type splitting/empty/one-byte tails; encrypted-body refusal and post-TLS seam; oversize/reserved flags/order/overlap/overflow/underflow/truncation; channel separation and channel/memory/feed bounds; immutability; explicit registry; conservative/fullscreen arithmetic; UNSPECIFIED placement and non-default fullscreen; disabled stages/constructor decoder-call count; AOA metadata/UTF8/NUL/indices. TLS-to-fragment streaming association is not implemented or claimed proven. Protocol framing limits are local policy, not confirmed phone limits.

M6's AoaNegotiator.EXECUTION_ENABLED=false; queryVersion/sendIdentity/start unconditionally throw. Only pure request plans exist:51/typeC0/value0/index0/two-byte response;52/type40/value0/indices0–5/NUL UTF8;53/type40/value0/index0/no data. Compared Honda/Open Headunit/AASDK: request semantics agree, but Honda/Open Headunit Java lacks explicit NUL while AASDK appends it; forceClaim/reset/aggressive loops not copied. No active AOA tool. [Foundation README](clean-receiver/README.md) and M6 design document preserve details.

Conservative model1280x688/229/60 is default; future nominal1920x1080/margins0,360/229/30 is expressible but crop placement and touch offset remain unspecified. No new reason to reconsider M3; clean ordinary-app architecture remains preferred.

## Stock competition / warning collection

Updated static T0–T9 timeline in STOCK-AA-USB-COMPETITION.md: framework attachment -> Honda receiver/service -> conditional query/conversion -> detach/accessory attach -> Honda open/claim/protocol. M4 sampling can miss initial device. ALWAYS/ASK/NEVER/power/allowed serial affect path; auto-start=false does not suppress transport. No suppression/forceClaim is proposed for passive M4.

Prepared separate read-only MaliciousDetector resolve/dump/pull/hash/public-signer/log instructions. Target historical `/system/app/MaliciousDetector/MaliciousDetector.apk`, package com.honda.maliciousdetector; resolve actual active path first. No collection performed; exact warning predicate/persistence/Dismiss implementation still unknown. This acquisition is NOT part of M4 and no bypass was designed.

## Validation / next steps

See [current build matrix](BUILD-VALIDATION-MATRIX.md) and offline-continuation-validation.json. Four APK rows include unchanged M4/grid and new decoder/M5. Historical source/artifact/raw evidence preservation checks PASS; no new live result. Prior no-clips/source-only plans and earlier matrix preserved as dated backups. NOTES and relevant reports updated chronologically.

Next LIVE: **M4 ONLY, GPT-6.1 Sol High**. No decoder/grid/M5/M6/pull additions without separate authorization. Next OFFLINE if vehicle unavailable: add independently derived parser fixtures/property tests and pure discovery/control protobuf serialization; keep active I/O disabled. No root/OEM signing/update/system/firmware paths pursued.

| Stage | State |
|---|---|
| DONE | Workspace writes, pinned tools, six clips/SPS/package audit, decoder0.2, gated M5,67 foundation tests, docs |
| NOW | All offline deliverables prepared; actual USB/TI runtime remains unknown |
| NEXT | Authorized M4 only; later separate decoder/M5 sessions |
| LATER | Gated AOA/ownership/TLS/discovery/video/fullscreen Surface/TTI |

Additional inspection detail: For these1080 files, ffprobe width/height AND coded_width/coded_height fields report1920x1080, while the independent raw SPS parser and trace_headers show1920x1088 with8px bottom crop. Both raw outputs are retained; use SPS macroblock dimensions for coded-raster throughput. This does not measure Android Auto phone output.
