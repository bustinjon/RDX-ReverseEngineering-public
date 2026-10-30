# Independent TI decoder0.2 procedure — separate future session

**READY STATIC/ASSETS for a separately authorized decoder session. Next live session remains M4 ONLY.** Updated2026-10-23. Previous no-clips plan is preserved in DECODER-TEST-PLAN-before-clips-foundation.md. No TI/vehicle decoding occurred offline.

## Reviewed artifact

Package com.rdx.fullscreen.decodertest, versionCode2/version0.2.0-with-clips, min21/target22.
APK decoder-test/build/20261023-112223-673/rdx-decoder-test-0.2.0-with-clips-development.apk.
SHA256 ADD395FC46626DD3C43F527E10B1D8C49092DB43C8088CAEABB4A553BE90A374.
Development signer SHA256 c001f59b25081ddfc73937155ca3580717e817c45c66e68b9e059737b0b28831.
Final manifest/ZIP/DEX/aapt/JADX/DEXDUMP, v1/API22 signature, alignment, manual flow and six uncompressed packaged-asset hashes PASS. See decoder-test/DECODER-APK-AUDIT.md and clips/CLIP-MANIFEST.md under that project. Historical0.1 APK/source remains preserved; do not use an intermediate0.2 build.

## Future prerequisites

Separate authorization, phone disconnected, no concurrent M4/M5/grid/GAL/AA/overscan work. Capture baseline with the explicit serial using the read-only tool. Verify firmware/build and target identity. If this package is unexpectedly present, STOP instead of replacing it with -r. Normal Activity launch can trigger Honda's auto-start=false commit and installation detection; do not claim private-data neutrality or suppress warning history.

## Commands — documentation only

[Code block omitted from public report; see authored source where available.]

Launch only creates UI/Surface, not a decoder. Verify ordinary UID/domain/window and selection label. Then select **one case and press START TEST**. STOP/EXIT cancels cooperatively; no auto-run-all. The future operator must explicitly authorize progression between cases after reviewing each result.

| Order | Clip | Purpose | Macroblocks/sec |
|---|---|---|---:|
| 1 | 1280x720/30 | Baseline sanity |108000|
| 2 | 1280x688/60 | Closest to known Honda source |206400|
| 3 | 1920x720/30 | First important fullscreen raster |162000|
| 4 | 1920x720/60 | Higher-rate active raster |324000|
| 5 | 1920x1080/30 | Padded1088 coded height |244800|
| 6 | 1920x1080/60 | Declared TI block-rate ceiling |489600|

The phone video protocol/margin model is not involved. 1080 samples are coded1920x1088 with an8px bottom SPS crop; that is encoder padding, not evidence about360px AA margins or touch offsets. Level4.2 acceptance is unknown; failure of a later case must not be treated as an invitation to software fallback.

## Measurement

RDX.DECODER records clip/requested and actual component, host-verified input SPS/expected asset hash, MediaExtractor raw format and individual MIME/width/height/frame-rate/profile/level fields, configure/start result, every queued/released output PTS/flags/size, output raw format and crop/stride/slice-height keys, EOS/errors/elapsed time and shutdown. Missing keys explicitly UNAVAILABLE. Requested codec is exclusively OMX.TI.DUCATI1.VIDEO.DECODER. No generic/software fallback, native receiver, USB/GAL/AA/audio/network/sensors or permissions.

Count queued/received/released buffers and render requests, not proven displayed frames. API22 lacks newer presentation callbacks. Future logs/visual moving frame counter are needed to interpret stutter/drops; verbose logging itself affects performance. Aspect-fit Surface dimensions and full physical-display width are separate from coded video dimensions.

## Limits and STOP

One worker, no automatic retry or sequence. Dequeue waits2000us; pacing sleeps2ms; pump20sec, UI watchdog checks every250ms and flags total25sec or cleanup5sec. Configure/stop/release Binder calls are not forcibly bounded by Java timers. A watchdog reports failure, not guaranteed recovery. Do not kill/restart shared media services or reboot automatically.

STOP after codec creation/configuration error, missing Surface, crash/AVC, watchdog, bad cleanup, system/media disruption, lost ADB or failed uninstall. Release own resources if possible; retain raw logs and do not run another case to probe a wedged service.

Use normal STOP then EXIT. Cleanup only own package:

[Code block omitted from public report; see authored source where available.]

Uninstall must remove app/process; it does not establish recovery of a stalled shared media service or clear Honda preference/detection history. No private-file bypass/deletion, root, display changes, updater/factory operations or head-unit reboot are included.

## Host reproducibility

Project-local tools/ffmpeg/provenance.json identifies FFmpeg9.0.2 and publisher checksum. Generate-RdxDecoderClips.ps1 produced all six10sec files; ffprobe, per-frame/keyframe inventories, trace_headers, extracted AnnexB and independent baseline SPS parser evidence are under decoder-test/clips/. All six host software decodes PASS; representative frame visually checked. MP4s are the only large assets; metadata catalog is public synthetic data, not AA credentials. Rebuild only when needed and re-audit any new hash; clip hashes are fixed in CLIP-MANIFEST.md/JSON.
