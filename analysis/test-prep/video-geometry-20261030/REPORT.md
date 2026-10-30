# Video geometry correction — 2026-10-30

**Implemented, locally tested, and signed. Not installed or visually validated yet.** The candidate corrects display mapping for the negotiated 1920×1080 codec / 1920×720 active area, while preserving decoder dimensions and the native touchpad contract.

Final candidate: [rdx-usb-helper-v6h-phone-never-geometry-v2.apk](../../parallel-aa-receiver/usb-helper/build/20261030-144741-663/rdx-usb-helper-v6h-phone-never-geometry-v2.apk).

SHA-256: `CFFC54940CD46857E7B9C49208D6851FE7FA8A50C83E11F0CAC36EFFB6444F33`.

Use build **20261030-144741-663**. An earlier geometry build/preparation was superseded by final lifecycle-publication and diagnostic-log adjustments; neither geometry build was installed. The previously tested phone-policy APK remains preserved.

## 1. Files inspected

Project rules, the successful car capture and results, helper overlay/session wiring, decoder and effective input facade, video configuration callback, builder, and current source/build hashes. Android primary documentation was checked for TextureView transform and SurfaceTexture buffer-size behavior.

## 2. Files changed

- Modified helper `AaOverlayService.java` and `AaSessionService.java`.
- Added helper `VideoGeometry.java`.
- Added `tools/car-test/VideoGeometryTest.java` and `Test-VideoGeometry.ps1`.
- Added local test/build/preparation evidence; builder updated its latest-build pointer and usual authorized staging files.
- Decoder, native input facade, protocol negotiation, Honda phone policy, runner guards, and frozen artifacts were not edited.

## 3. Commands run

Local source/log reads and searches; pure Java geometry tests; existing authorized helper build/signing process; APK DEX-entry/hash, API22 signature, alignment, signer, and source-provenance checks; runner Prepare mode with an intentionally nonexistent device executable. No ADB, installation, new phone test, staging, commit, or milestone action.

## 4. Tests run and results

| Check | Result |
|---|---|
| Geometry and diagnostic coordinate checks | **2,048 PASS**; [results](unit-tests/results.txt) |
| Full helper compile | **22 Java inputs**, build succeeded |
| Current recorded Java source hashes | **22/22 match**, no differences |
| Packaged DEX | Matches build output; geometry class/marker and phone policy present |
| API22 signing and alignment | PASS |
| Development signer | Matches previous phone-policy APK |
| Offline PhonePreference preparation | PASS for the pinned candidate |
| Frozen anchors | **4/4 match** |

The model checks cover source corners/center, equal horizontal/vertical pixel scale, all negotiated margins, clamping, already-active decoder output, fallback 800×430 content, view resizing, odd margins, invalid sizes, and rejection of the observed padded 2048×1184 storage dimensions. Two hundred deterministic varied geometries exercise the matrix/inverse invariants. Tests apply the exact matrix values used by the Android integration; Android GPU/lifecycle execution still requires a car test.

The prior 42 runner simulations were not repeated because the runner/core were unchanged. No pass from those simulations is claimed as Android rendering validation.

## 5. Findings and implementation

### Display transform, keeping codec and content geometry distinct

The car capture records selected codec 1920×1080, active area 1920×720, a 1920×720 TextureView, and visible decoder crop 1920×1080. Its padded storage size 2048×1184 is separate. The previous overlay applied no content transform.

The new immutable geometry model computes an active source rectangle and an aspect-preserving destination rectangle from negotiated and visible sizes. It supplies a Matrix to the TextureView. For the observed case, a centered active region produces scale `(1,1.5)` and translation `(0,-180)`: source y=180..900 fills display y=0..720. Equal source pixel distances remain equal on the display. **Centering is a testable assumption, not a measured black-bar boundary.**

If decoder-visible dimensions already equal the active dimensions, no margin crop is applied. Unexpected visible dimensions reset the transform and emit `VIDEO_GEOMETRY_REJECTED`, rather than guessing a crop from storage padding. Fallback configurations and different view ratios fit uniformly and retain intentional letterboxing where needed.

Selected configuration and decoder-visible-size callbacks now update the overlay through its main-thread handler. The transform reapplies when the texture becomes available or resizes. Overlay removal clears geometry state. The instance is published after handler initialization; late work on a destroyed service is ignored. Logs emit `VIDEO_GEOMETRY_V1` with source offset, view size, matrix coefficients, and whether actual decoder format is confirmed.

### Decoder and input behavior

MediaCodec still receives the selected codec dimensions. No SPS/raster/storage-size workaround was added. The native InputSource facade and session's raw 1325×720 touchpad forwarding remain unchanged. Only diagnostic active-video coordinates use the inverse display mapping; there is no 180-pixel addition to native touchpad input. Physical touch accuracy remains unverified.

Android documents that [TextureView.setTransform](https://developer.android.com/reference/android/view/TextureView#setTransform(android.graphics.Matrix)) affects content rather than view bounds. [SurfaceTexture.setDefaultBufferSize](https://developer.android.com/reference/android/graphics/SurfaceTexture#setDefaultBufferSize(int,int)) can be overridden by video producers, so changing a default buffer size is not used as the geometry fix. A black container and non-opaque texture cover any aspect-preserving letterbox region.

### Next controlled test

Use the final APK/hash with CurrentSource, PhonePreference, phone serial 11111111, and operator-confirmed Honda Disable/Never. Use **SafetySeconds=120** through the existing bounded parameter; do not remove cleanup or readiness guards. The previous successful attempt left only 7.2 seconds of video because the cable swap consumed much of the 60-second window.

Recheck Home/lock-task and current device state on connection. After actual READY, swap to the phone. Verify normal proportions, visible top/bottom UI, and whether unwanted bars remain. Inspect `VIDEO_GEOMETRY_V1`/`VIDEO_GEOMETRY_REJECTED` after retrieval. If UI is clipped, measure the actual active rectangle before changing crop offsets. Stop after evidence retrieval/cleanup. No new device attempt was started here.

## 6. Primary evidence for each finding

- Previous run: `analysis/test-prep/runs/helper_20261030T183215_3af01827a7df4edf8ccb704085b71079/device-evidence/capture.log`:43067 actual texture size; :43553 selected geometry; :43744 decoder crop; :43746 first frame. Operator independently reported bars/stretching.
- [Geometry source](../../../analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/VideoGeometry.java), overlay's applyVideoTransform, and session config/format callback wiring.
- [Tests](../../../tools/car-test/VideoGeometryTest.java), [test output](unit-tests/results.txt), and [source scope](source-scope.json).
- Final [build report](../../parallel-aa-receiver/usb-helper/build/20261030-144741-663/build-report.json) and [geometry verification](../../parallel-aa-receiver/usb-helper/build/20261030-144741-663/geometry-validation.json) pin source and packaged DEX hashes, signer, signature/alignment status, and frozen checks.
- [Fresh local artifact plan](../runs/helper_20261030T184900_26170f62db52402c9016c5c25ac36689/artifact-plan.json). Planned 120-second window is recorded in geometry-validation.json; no live clock is running.

## 7. Assumptions

“Continue” authorizes the geometry implementation and another local build using the already authorized credential/signing process. The same OnePlus 13/Honda phone preference remains the intended next-test configuration, subject to fresh connected checks. No unrelated feature or milestone is advanced.

## 8. Unresolved uncertainties

Actual margin centering, final visible proportions/clipping, Android matrix/GPU behavior, physical touch accuracy, and longer projection stability require hardware validation. Static audit remains PENDING; successful tests/signing do not establish those runtime outcomes. No screenshot of the previous video was captured. Audio, microphone, reconnect recovery, and unrelated protocol gaps remain outside this correction.

## 9. Exact diff summary

Two existing app Java files changed; one app geometry class and two host-test files added; new build/test/preparation evidence and latest-build pointer update. Geometry-only scope is checked against the previous APK's recorded inputs in source-scope.json. No decoder, effective input facade, runner, instruction, historical report, or milestone-state edit. No files deleted or Git staging/commit.

## 10. Preservation checks performed

Four frozen artifacts match their SHA-256 anchors. The previous signed phone-policy candidate and its signer are retained. Only overlay/session differ among the previous build's Java inputs; the geometry class is newly added. Current candidate's 22 recorded hashes match disk. Authorized credential handling stayed local; credential values were not printed. No car access or milestone change occurred in this turn.
