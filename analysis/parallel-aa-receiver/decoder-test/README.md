# RDX independent TI decoder harness

com.rdx.fullscreen.decodertest 0.1.0-decoder. Built and independently statically audited, but **NOT READY FOR DECODING: no test assets generated**. See [test plan](../DECODER-TEST-PLAN.md) and [matrix](../BUILD-VALIDATION-MATRIX.md).

Explicit one-clip action only; fixed named TI codec, no software fallback, no USB/GAL/native/protocol credentials. Source reviewed to avoid allocation before stable Surface geometry and to cancel on backgrounding. No runtime codec capability/performance is claimed.

Supply trusted existing FFmpeg/ffprobe to `scripts/Generate-RdxDecoderClips.ps1`, inspect generated SPS/probe/hash evidence, then rebuild and re-audit: `scripts/Build-RdxBoundedHarness.ps1 -Harness decoder-test`; `scripts/Audit-RdxBoundedHarness.ps1 -Harness decoder-test`. Generator has not run in this session. Intermediate builds are preserved; only latest-build/matrix identifies the reviewed revision.

## 2026-10-23 clips and clean-foundation continuation

Current0.2.0-with-clips supersedes the historical no-assets status above. Six generated/independently inspected MP4s and a public SPS catalog are packaged. Current APK ADD395FC46626DD3C43F527E10B1D8C49092DB43C8088CAEABB4A553BE90A374 passes independent audit and is ready for a separately authorized decoder session; see DECODER-APK-AUDIT.md/current DECODER-TEST-PLAN.md/build matrix. Historical0.1 source/APK remains preserved. No vehicle decoding has occurred. Next live session remains M4 only.
