# Independent TI H.264 test — 2026-10-23

Package `com.rdx.fullscreen.decodertest`, version `0.1.0-decoder`, min21/target22. Built/signature/alignment/aapt/JADX/DEXDUMP/reference audit PASS; see build matrix. **NOT READY FOR VIDEO TEST: all six clip assets are missing.** No car decoding was performed.

Source is under `decoder-test/source`; entry `.DecoderTestActivity`. Explicit START selects one clip; no automatic sequence. MediaExtractor reads a packaged MP4 asset, MediaCodec.createByCodecName requests **only `OMX.TI.DUCATI1.VIDEO.DECODER`**, then configures a Surface. No software fallback, USB, GAL, Honda/protocol native library, credentials, network, audio, sensors or permissions. Merely launching creates UI/Surface, not a decoder. Missing asset fails visibly before codec creation.

The reviewed revision waits for target Surface dimensions before starting to avoid resizing/destroying an active codec. Aspect-fit layout uses floating division, verified in DEX despite JADX omitting casts in one expression. Zero-sized Surface output need not imply no picture; the render decision excludes codec config and empty EOS rather than rejecting every size-zero output.

## Assets and reproducibility

No FFmpeg/ffprobe executable was found on PATH, in the project, Program Files or searched Local AppData. No encoder was downloaded or machine-wide software installed. `scripts/Generate-RdxDecoderClips.ps1` accepts explicit existing ffmpeg/ffprobe paths, refuses overwrite, generates moving testsrc2/grid/resolution/FPS/frame-label H.264 baseline yuv420p/no-B clips, 10 seconds, fixed GOP, single encoder thread. It records hashes, ffprobe JSON, and first-access-unit SPS header traces. The generator has been syntax-reviewed, **not executed**; its FFmpeg/font-filter compatibility needs host verification when tools are supplied. Exact bytes depend on encoder build; record that build before generating.

Required assets, all currently absent:

| File | Blocks/frame | Blocks/sec |
|---|---:|---:|
| grid-1280x720-30.mp4 | 3600 | 108000 |
| grid-1280x688-60.mp4 | 3440 | 206400 |
| grid-1920x720-30.mp4 | 5400 | 162000 |
| grid-1920x720-60.mp4 | 5400 | 324000 |
| grid-1920x1080-30.mp4 | 8160 | 244800 |
| grid-1920x1080-60.mp4 | 8160 | 489600 |

After generation, inspect SPS/profile/level/crop, duration/frame rate, moving labels; rebuild with `scripts/Build-RdxBoundedHarness.ps1 -Harness decoder-test`, then rerun independent audit. Assets are stored uncompressed for openFd. Never install an intermediate old build by accident; use latest matrix/hash. The TI XML maximum 1920x1088 and489600 blocks/sec is a declaration, not a runtime guarantee. A 1080-coded picture cropped to720 retains1080-class decode cost.

## Future separate session

Phone disconnected. Capture baseline, install only this package, launch `.DecoderTestActivity`, verify Surface/UI, select baseline1280x720/30 and press START once. Run no further case after allocation/configuration/media error until reviewed. Progress only through separately authorized cases; first fullscreen-relevant raster1920x720/30. Keep overscan untouched.

Logs `RDX.DECODER`: clip name, exact codec/getName, input MediaFormat (width/height/frame rate/MIME/profile/level where exposed), configuration/start status, every input/output PTS/size/flags, output format (crop/stride/slice-height when exposed), received/released counts, errors, cleanup and elapsed duration. Missing format keys are unavailable, not zero. Counts of released buffers do not prove displayed frames; API22 lacks newer frame-render callbacks. No claim of dropped-frame count or sustained render FPS until independently measured. Instrumentation/log overhead is itself a performance variable.

Input/output dequeue waits2000us; frame pacing sleeps2ms; pump deadline20sec; UI watchdog25sec cancels/logs. Binder calls such as configure/stop/release cannot be forcibly bounded by these timers. Watchdog/cleanup/media-service failure means STOP; never restart/kill a shared media service or reboot automatically. Cancellation/backgrounding/Surface loss requests worker shutdown; repeated START is blocked while active, and error latches prevent another allocation in the Activity. Surface lifetime belongs to SurfaceView.

Future commands only: `adb -s SERIAL install APK`; `adb -s SERIAL shell am start -n com.rdx.fullscreen.decodertest/.DecoderTestActivity`; use STOP/EXIT UI; `adb -s SERIAL uninstall com.rdx.fullscreen.decodertest`; verify `pm path` absent and `ps` has no package. If UI hangs, stop and collect evidence; no system-process manipulation. Activity resume can trigger Honda's persistent auto-start setter. This test is separate from M4 and requires its own live authorization.
