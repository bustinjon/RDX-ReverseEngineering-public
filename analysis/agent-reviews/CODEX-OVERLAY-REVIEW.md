The saved logs support fullscreen **window drawing**, but the AA video path is not ready: the test pattern prevents decoder reuse of its Surface, surface destruction is uncoordinated, and the USB/video/input handoff is absent.

1. **Files inspected**

   All six requested files, plus `PROJECT-RULES.md`, `AGENTS.md`, and these integration/preservation files under `analysis/parallel-aa-receiver/`:

   - `usb-helper/AndroidManifest.xml`
   - `usb-helper/source/com/rdx/fullscreen/usbhelper/UsbHelperService.java`
   - `clean-receiver/source/com/rdx/fullscreen/clean/DiscoveryCodec.java`
   - `clean-receiver/source/com/rdx/fullscreen/clean/SessionCatalog.java`
   - `clean-receiver/source/com/rdx/fullscreen/clean/SurfaceViewport.java`
   - `src/com/rdx/fullscreen/projection/ProjectionSession.java`
   - `src/com/rdx/fullscreen/projection/ReceiverActivity.java`
   - `PROJECT-INTEGRITY.json` and `hashes.json` for preservation metadata.

2. **Files changed**

   None.

3. **Commands run**

   Read-only `Get-Content`, `rg`, `rg --files`, `Get-FileHash -Algorithm SHA256`, and initial/final `git status --short`; in-memory coordinate calculations; Android/AOSP documentation lookups.

   One PowerShell wildcard search and two calculations using restricted language features failed. Corrected searches/calculations succeeded. No build, device command, or repository mutation ran.

4. **Tests run and results**

   Reproduced Java float arithmetic using JavaScript `Math.fround`, including the service’s clamp:

   | Raw X | Scaled X | If subsequently truncated |
   |---:|---:|---:|
   | 20 | 28.9811 | 28 |
   | 1280 | 1854.7925 | 1854 |
   | 1324 | 1918.5510 | 1918 |
   | 1325 | 1919 after clamp | 1919 |
   | 1400 | 1919 after clamp | 1919 |

   Static call-site searches found declarations of the overlay’s Surface/touch accessors, but no integration callers in the searched receiver/helper source.

   No compilation, Android runtime, decode-throughput, or vehicle tests ran.

5. **Findings**

   **F1 — Touch coordinate scaling: IMPORTANT**

   The division uses floats correctly; there is no integer-division bug. Its correctness nevertheless depends on an unproved assumption: a zero-origin, linear input range whose extent is exactly 1325×720.

   Six DOWN samples establish observed coordinates, not calibrated endpoints or linearity. Three samples landing at exactly X=1324 suggest saturation, but do not establish whether that saturation originates in the touchpad, Honda’s mapping, or another layer. Left-edge reachability, MOVE behavior, dead zones, and nonlinear mapping remain **UNKNOWN**. [E1]

   Counterexamples: if the true horizontal extent is 1280, the assumed transform undershoots the intended right edge by approximately 65 pixels. If it is 1400, coordinates above the assumed extent collapse onto the right edge. With the measured maximum 1324, subsequent integer truncation produces 1918, leaving column 1919 unreachable through that sample.

   **Recommendation:** calibrate minimum/maximum coordinates and intermediate targets using complete gestures. Define whether endpoints are inclusive, then apply one documented transform shared with rendering. Treat clipping as observable diagnostic data rather than silently hiding calibration errors.

   **F2 — TextureView inside TYPE_SYSTEM_ERROR on API 22: IMPORTANT**

   The approach is plausible; the reviewed evidence does not establish that it works on this Honda graphics stack. The successful diagnostic uses an ordinary custom `View.onDraw()`, not a TextureView or decoder. [E2]

   TextureView requires an accelerated window. The service requests acceleration before `addView()`, which is appropriate. AOSP Android 5.1.1’s renderer setup checks the flag and renderer availability; that method contains no exclusion specific to `TYPE_SYSTEM_ERROR`. Honda runtime acceleration remains **UNKNOWN**. [Android TextureView documentation](https://developer.android.com/reference/android/view/TextureView), [AOSP 5.1.1 renderer setup](https://raw.githubusercontent.com/aosp-mirror/platform_frameworks_base/android-5.1.1_r1/core/java/android/view/ViewRootImpl.java).

   SurfaceView can reduce GPU composition work because it supplies a separate composition layer. That separate layer also introduces placement and stacking behavior that the ordinary-View diagnostic did not test. It is not automatically a better fullscreen solution on this modified WindowManager. [AOSP rendering comparison](https://source.android.com/docs/core/graphics/arch-tv).

   **Recommendation:** establish actual `isHardwareAccelerated()`, surface availability, dimensions, and decoded-frame presentation. Compare SurfaceView only with explicit coverage/stacking evidence.

   **F3 — Surface lifecycle: CRITICAL**

   The Surface does **not** survive the implemented destruction path. `onSurfaceTextureDestroyed()` clears the field and returns `true`, without notifying or stopping the decoder. It also drops the Surface wrapper without explicitly releasing it there. `removeOverlay()` cannot release a wrapper already cleared by that callback. [E3]

   Android requires rendering to stop after a destruction callback returning `true`. Releasing the SurfaceTexture abandons its BufferQueue; retaining a Java Surface reference does not preserve it. The exact vendor-codec symptom—error, stalled output, or another failure—is **UNKNOWN**. [Destruction contract](https://developer.android.com/reference/android/view/TextureView.SurfaceTextureListener#onSurfaceTextureDestroyed(android.graphics.SurfaceTexture)), [SurfaceTexture release behavior](https://developer.android.com/reference/android/graphics/SurfaceTexture#release()).

   Furthermore, `VideoDecoder.surface()` only assigns a field. An existing codec retains its configured output target. Public `setOutputSurface()` starts at API 23, so API 22 needs codec reconfiguration/recreation for a replacement target. [MediaCodec API](https://developer.android.com/reference/android/media/MediaCodec#setOutputSurface(android.view.Surface)).

   **Recommendation:** introduce explicit ready/retiring/destroyed ownership callbacks. Stop and confirm decoder teardown before releasing the target, then configure a fresh decoder against the replacement Surface. The existing activity already demonstrates deferred SurfaceTexture release. [E3]

   **F4 — Video resolution and margins: IMPORTANT**

   `fullscreenExperiment()` advertises **1920×1080, margins 0×360, 30 fps**. Its modeled active dimensions are 1920×720. `DiscoveryCodec` transmits resolution enum 3 plus margins; it does not transmit arbitrary raster dimensions. `VideoConfig` rejects nominal 1920×720. [E4]

   Therefore, the service comment that 1920×720 is “what we tell the phone” is misleading. Whether this phone produces a cropped 1920×720 stream, a nominal stream containing margins, or another supported output is **UNKNOWN**.

   The overlay applies no video transform or negotiated-geometry update. If decoded output contains margin pixels, displaying the whole buffer across 1920×720 would retain/compress those margins. If output is already cropped, another crop would be wrong. The existing decoder correctly treats SPS/output crop as authoritative. [E4]

   **Recommendation:** retain the distinction between advertised nominal geometry, margins, decoded crop, displayed viewport, and input coordinates. Derive rendering and its inverse input mapping from observed negotiated/output geometry. Do not hard-code margin placement; `VideoConfig` explicitly leaves placement unspecified.

   **F5 — Touch pass-through and physical controls: IMPORTANT**

   For touch streams targeted to this full-screen window, the overlay consumes them: it lacks `FLAG_NOT_TOUCHABLE`, and `handleTouch()` always returns `true`, even without a listener. Underlying Honda touch UI consequently loses those streams. [E5]

   `FLAG_NOT_FOCUSABLE` preserves key focus behind the overlay and implies nonmodal behavior for pointer events **outside** its bounds. A fullscreen window has no useful outside region. It does not broadcast intercepted touches to Honda. [Window flag contracts](https://developer.android.com/reference/android/view/WindowManager.LayoutParams#FLAG_NOT_FOCUSABLE).

   Center-console buttons delivered as ordinary key events should retain their underlying focus destination; this overlay also cannot receive those keys for AA navigation. Actual Honda button and volume-knob routing is **UNKNOWN** from these files. A control might operate underneath while its resulting UI remains covered.

   **Recommendation:** document routing separately for touch, keys, rotary input, and system-handled controls. Provide a reliable overlay dismissal path and verify each relevant physical control rather than inferring its behavior from window flags.

   **F6 — Performance: IMPORTANT**

   Sustained 30/60 fps is **UNKNOWN**. Naming the TI codec proves implementation selection, not supported profile/level, throughput, resource availability, or composition performance. The inspected activity’s allocation probe explicitly does not configure/start/feed the codec. [E6]

   TextureView adds GPU composition work. If the phone sends nominal 1920×1080, the decoder processes 2,073,600 pixels per frame rather than 1,382,400 for 1920×720—a 50% increase before considering composition. [AOSP composition explanation](https://source.android.com/docs/core/graphics/arch-tv).

   There is also a concrete backpressure weakness: a single 10 ms input-buffer timeout permanently sets `broken=true`; subsequent packets are still acknowledged without decoding. The 24-packet queue could represent approximately 800 ms at 30 fps or 400 ms at 60 fps, assuming one frame per packet. [E6]

   **Recommendation:** use measured negotiated-raster/profile/bitrate performance, frame latency, and drops. Handle temporary decoder backpressure separately from terminal failure and propagate terminal failure to session shutdown.

   **F7 — UsbHelperService integration: CRITICAL**

   No implemented handoff was found. USB success changes state and logs; it neither starts an AA session nor supplies an overlay Surface. The overlay returns `null` from `onBind()`, has no ready/lost callback, and offers instance methods without a demonstrated way for another service to obtain the instance. Its comment references nonexistent `provideSurface()`. [E7]

   There is an additional coordinate-contract conflict: the clean experimental catalog still advertises a **1325×720 touchpad**, while this callback emits coordinates approaching **1920×720**. Forwarding them unchanged would exceed the declared horizontal input extent; another mapping layer could instead double-scale them. Actual phone interpretation is **UNKNOWN** without the missing input integration. [E7]

   **Recommendation:** specify a session-owned handoff contract for verified USB availability, Surface readiness/loss, decoder lifetime, and input delivery. Choose whether the wire carries touchpad-space or video-space coordinates and make its advertisement agree. Overlay creation alone must not imply session readiness.

   **Additional issues**

   - **F8 — CRITICAL: test-pattern Surface cannot become decoder output.** Every START sets `testMode=true`; availability then calls `videoSurface.lockCanvas()`. Android documents that CPU Canvas attachment prevents later video-decoder use of that Surface. Disabling the boolean afterward would not repair the existing target. **Recommendation:** use a separate diagnostic Surface or draw diagnostics in sibling Views; create a fresh decoder target never locked for Canvas. [E8; AOSP Surface contract](https://source.android.com/docs/core/graphics/arch-sh).
   - **F9 — IMPORTANT: no bounded diagnostic exit.** Unlike `OverlayTestService`, the new service has no auto-dismiss or visible dismiss control. Its `Handler` is unused. Physical navigation can change the obscured application without dismissing the overlay. **Recommendation:** retain a bounded diagnostic lifetime and an explicit accessible exit. [E9]
   - **F10 — IMPORTANT: unrestricted exported service.** The manifest exports `AaOverlayService` without a protecting permission, allowing other applications to request its START/STOP behavior. **Recommendation:** make it nonexported for internal use or protect the intended external control interface. [E10]
   - **F11 — IMPORTANT: incomplete input event contract.** The listener carries one coordinate and a masked action, without pointer identity or action index. The service also substitutes receipt-time `elapsedRealtime()` for the event timestamp. Multitouch reconstruction and cancellation on overlay removal are absent. **Recommendation:** define explicit single-pointer behavior or preserve pointer identities, cancellation, and agreed timestamp semantics. [E11]

6. **Primary evidence for each finding**

   Paths below are under `C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/`.

   - **E1:** [Scaling and clamp, lines 164–198](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/AaOverlayService.java:164); [six saved DOWN samples](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/overlay-test-results-20261027.md:86).
   - **E2:** [Diagnostic ordinary View](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/OverlayTestService.java:115); [new window flags](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/AaOverlayService.java:139).
   - **E3:** [Surface callbacks](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/AaOverlayService.java:104), [removal](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/AaOverlayService.java:389), [decoder configuration](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/src/com/rdx/fullscreen/projection/VideoDecoder.java:23), [existing deferred release](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/src/com/rdx/fullscreen/projection/ReceiverActivity.java:117).
   - **E4:** [VideoConfig](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/clean-receiver/source/com/rdx/fullscreen/clean/VideoConfig.java:3), [wire encoding](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/clean-receiver/source/com/rdx/fullscreen/clean/DiscoveryCodec.java:6), [decoder crop handling](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/src/com/rdx/fullscreen/projection/VideoDecoder.java:53).
   - **E5:** [Touchable fullscreen flags](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/AaOverlayService.java:139); [unconditional consumption](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/AaOverlayService.java:197).
   - **E6:** [Decoder queue](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/src/com/rdx/fullscreen/projection/VideoDecoder.java:11), [timeout](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/src/com/rdx/fullscreen/projection/VideoDecoder.java:41), [permanent broken state and acknowledgements](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/src/com/rdx/fullscreen/projection/VideoDecoder.java:63), [allocation-only probe](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/src/com/rdx/fullscreen/projection/ReceiverActivity.java:93).
   - **E7:** [USB success branch](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/UsbHelperService.java:246), [overlay accessors/null binder](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/AaOverlayService.java:380), [catalog input choice](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/clean-receiver/source/com/rdx/fullscreen/clean/SessionCatalog.java:23), [1325×720 input definition](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/clean-receiver/source/com/rdx/fullscreen/clean/InputConfig.java:2).
   - **E8:** [Unconditional test mode](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/AaOverlayService.java:86); [Canvas lock](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/AaOverlayService.java:208).
   - **E9:** [New START/STOP handling](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/AaOverlayService.java:75); [diagnostic auto-dismiss](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/OverlayTestService.java:212).
   - **E10:** [Exported service declaration](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/usb-helper/AndroidManifest.xml:14).
   - **E11:** [Listener signature](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/AaOverlayService.java:63); [event extraction/delivery](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/AaOverlayService.java:164).

7. **Assumptions**

   The supplied files are the intended implementation under review. Range-error examples are hypothetical counterexamples, not additional vehicle measurements. Queue-delay calculations assume one frame per queued packet.

8. **Unresolved uncertainties**

   True touch calibration; Honda hardware acceleration and SurfaceView stacking; phone-selected raster/crop/margin placement; physical-control routing; TI decoder throughput and destroyed-target behavior; intended input wire semantics.

9. **Exact diff summary**

   None from this review. Initial and final Git status both showed the preexisting modified helper manifest and untracked `AaOverlayService.java`.

10. **Preservation checks performed**

   SHA-256 comparisons reported `UNCHANGED=True` for all six requested files and the helper manifest.

   Frozen M5 APK, disabled M6 APK, API22 qualifier APK, and both manifest-listed receiver DEX copies matched their preservation anchors: **five checks, all `MATCH=True`**. No artifacts were rebuilt; no key material or devices were accessed; no milestones advanced.