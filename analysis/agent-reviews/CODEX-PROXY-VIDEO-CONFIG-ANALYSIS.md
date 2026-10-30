**Verdict — SUPPORTED:** An SDR-only proxy rewrite is insufficient to produce correct 1920×720 video through the inspected stock receiver. Honda resolves the phone’s selected **index against its original Java configuration list**, then uses those original dimensions for decoder setup, viewport sizing, and cropping. A larger stream might decode, but the receiver would still use the old presentation geometry. Decoder acceptance is **UNKNOWN**.

1. **Files inspected**

   Paths below use these abbreviations:

   - **H:** `decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink`
   - **G:** `decompiled/AndroidAuto-current/sources/com/google/android/projection`
   - **C:** `analysis/parallel-aa-receiver/clean-receiver`

   Inspected relevant portions of:

   - `PROJECT-RULES.md`, `AGENTS.md`.
   - `Notes/RDX-Android-Auto-Fullscreen-Findings.md`, `analysis/HMIPresenter-video-mode-analysis.md`, `analysis/FIRST-LIVE-TEST-CANDIDATES.md`.
   - **H:** `presentation/HMIPresenter.java`; `integration/{AbstractGalIntegration,GalIntegration,ProjectionListenerWrapper}.java`; `ui/{ProjectionActivity,VirtualPointer}.java`; `video/{ProjectionRenderer,DimensionUtils}.java`; `settings/{Settings,StartPreferences}.java`; `service/GalService.java`; `transport/usb/UsbHostSetup.java`.
   - **G:** `protocol/{VideoSink,InputSource}.java`, `proto/Protos.java`, `transport/usb/UsbHostTransport.java`.
   - Corresponding `VideoSink.smali` and `ProjectionRenderer.smali`; `resources/res/xml/usb_device_filter.xml`.
   - `adb/AndroidAuto-system/lib/arm/libautoreceiver_jni.so`; saved native strings, symbol summaries, relocations, and selected disassembly under **C**`/media-8000-evidence/`.
   - **C:** `source/com/rdx/fullscreen/clean/{DiscoveryCodec,VideoConfig,InputConfig,HondaMediaMessages}.java`; experimental discovery fixture; `MEDIA-8000-8003-EVIDENCE-REVIEW.md`.
   - `logs/2026-10-22-investigation/media-codecs.xml`; selected saved log content, principally `analysis/parallel-aa-receiver/m5-live-retry-20261025-185128/reconnect-logcat.txt`.
   - Preservation-manifest metadata; `scripts/RdxElf.cs` and disassembly-script excerpts.

   No `analysis/agent-reviews/` file contents were inspected.

2. **Files changed**

   **None.** No report, code, fixture, or binary was written.

3. **Commands run**

   Read-only commands comprised:

   - `Get-Content`, `Select-String`, `Select-Object`, `ConvertFrom-Json`.
   - `rg --files`, `rg -n`, `rg -l`, and fixed-string searches over the scoped sources, evidence, and saved logs.
   - `git status --short`.
   - `Get-FileHash -Algorithm SHA256`.
   - `Get-Command` and targeted `Get-ChildItem` tool/file inventories.
   - Inline PowerShell ELF section/symbol parsing; selected function bytes piped through installed `llvm-mc.exe --disassemble --triple=thumbv7-linux-android --show-encoding --print-imm-hex`. The ARM library was never loaded or executed.
   - Arithmetic checks of viewport dimensions and macroblock rates.

   Unsuccessful attempts: Python’s WindowsApps executable was inaccessible; `Add-Type` and `[Math]` calls were blocked by constrained language mode; two searches used unsupported PowerShell wildcard/brace syntax. Subsequent reads, byte parsing, disassembly, and arithmetic used supported operations.

4. **Tests run and results**

   - **No runtime, device, decoder, or protocol-session tests run.**
   - Geometry calculation reproduced **1340×720, left=290**, and vertical scale **1.0465116279**.
   - Both stock modes have identical aspect ratio:  
     `1280/688 = 800/430 = 1.8604651163`.
   - Macroblock calculations reproduced:
     - 1080-class/60: **489600 blocks/s**.
     - 1080-class/30: **244800 blocks/s**.
     - 1280×720/60: **216000 blocks/s**.
   - All five checked manifest entries covering the four frozen artifact categories matched their expected SHA-256 values; details in item 10.

5. **Findings**

   **Q1 — CONFIRMED: 1340 and 290 are calculated geometry; 1240×606 are preference values.**

   `DimensionUtils.makeViewport()` uses the Java logical video dimensions, the available surface, and the scaling flag:

   ```text
   r = min(surfaceWidth/videoWidth, surfaceHeight/videoHeight)
   W = min(surfaceWidth,  2 × floor(round(videoWidth × r)/2))
   H = min(surfaceHeight, 2 × floor(round(videoHeight × r)/2))
   left = integer_divide(surfaceWidth − W, 2)
   top  = integer_divide(surfaceHeight − H, 2)
   ```

   For surface 1920×720 and logical video 1280×688:

   ```text
   r = 720/688
   W = 1340; H = 720
   left = (1920−1340)/2 = 290
   ```

   The renderer writes those dimensions and margins into `LayoutParams`. “pivotWidth” is the resulting viewport width; the actual matrix pivot is half that width, **670**, with vertical pivot **360**. Evidence: **H**`/video/DimensionUtils.java:14`, **H**`/video/ProjectionRenderer.java:264`, `:270`, `:275`, `:656`.

   The crop transform separately chooses nominal codec dimensions from the **logical width tier**:

   ```text
   scaleX = nominalCodecWidth/logicalVideoWidth
   scaleY = nominalCodecHeight/logicalVideoHeight
   ```

   Stock gives `1280/1280=1`, `720/688=1.0465117`. Smali confirms floating-point division, despite JADX displaying integer-looking expressions: `ProjectionRenderer.smali:611`–`:622`.

   **1240×606** come from preference defaults `"screen_width", "1240"` and `"screen_height", "606"`; `ProjectionActivity` passes them into `ScreenSettings`. `makeViewport()` uses `settings.isScaled()`, **not those stored width/height values**. Evidence: **H**`/settings/Settings.java:48`, `:56`, `:73`; **H**`/ui/ProjectionActivity.java:2231`; **H**`/video/DimensionUtils.java:14`.

   Available surface size remains independent. The saved retry log contains:

   > `Surface Rect(0, 0 - 1339, 720) becomes Rect(0, 0 - 1338, 720) for video Rect(0, 0 - 1280, 688)`

   Thus even a genuinely changed logical mode would still depend on the Activity receiving a sufficiently wide surface. The historical 1920-surface excerpt is reproduced in `Notes/RDX-Android-Auto-Fullscreen-Findings.md:74`; this review did not independently locate its original raw capture.

   **Q2 — CONFIRMED: Java owns the selected-index-to-render-dimensions mapping.**

   The construction and selection path is:

   ```text
   HMIPresenter.getVideoMode()
     → AbstractGalIntegration.initDisplayConfiguration()
     → VideoSink.nearestVideoConfiguration()
     → VideoSink.addSupportedConfiguration()
         stores Java configuration AND passes fields to native
     → native VideoSink::addSupportedConfiguration()
     → native VideoSink::addDiscoveryInfo()
         copies native configuration entries into SDR
     → phone Start.configuration_index
     → MediaSinkBase::handleStart()
     → VideoSink::handleMediaConfiguration(index)
     → JNI sourceVideoConfigCallback(index)
     → Java mVideoConfigurations.get(index)
     → Java enum → nominal dimensions
     → ProjectionListenerWrapper subtracts original margins
     → ProjectionActivity.prepareStart(width,height)
   ```

   Java offers:

   | Index | Resolution enum | Margins | Logical dimensions |
   |---|---|---|---|
   | 0 | `VIDEO_1280x720 = 2` | 0,32 | 1280×688 |
   | 1 | `VIDEO_800x480 = 1` | 0,50 | 800×430 |

   Evidence: **H**`/presentation/HMIPresenter.java:819`; **H**`/integration/AbstractGalIntegration.java:156`; **G**`/protocol/VideoSink.java:77`, `:116`, `:160`; **H**`/integration/ProjectionListenerWrapper.java:25`.

   Native disassembly confirms field storage and copying at `VideoSink::addSupportedConfiguration`, **VA 0xCA182**, and `VideoSink::addDiscoveryInfo`, **VA 0xC9F76**. It does not cause an outgoing proxy rewrite to update the already-stored Java list.

   **Existing index, including mapping back to index 0:** Java still reports 1280×688. Replacing entry 0 in the outgoing SDR already has this effect without any index translation. Honda configures the decoder for 1280×688, retains its old viewport, and applies its old `720/688` vertical crop transform. It does not learn the proxy’s 360-pixel margin.

   If the larger stream decodes, **wrong viewport/aspect/crop is SUPPORTED**. Whether SPS-triggered decoder resizing succeeds, fails allocation, or otherwise disrupts playback is **UNKNOWN**.

   **Unlisted index:** the inspected native dispatch does **not** reject it against the advertised list. `MediaSinkBase::handleStart`, **0xC547A**, forwards the index; `VideoSink::handleMediaConfiguration`, **0xC9E92**, forwards it to the callback and returns zero. Java immediately executes:

   > `Protos.VideoConfiguration config = this.mVideoConfigurations.get(index);`

   An index outside 0–1 therefore causes a Java bounds exception at that lookup. **CONFIRMED:** failing lookup. **UNKNOWN:** final JNI/process outcome—exception propagation, teardown, or crash was not demonstrated.

   **Enum versus index matters:** `Start` carries `configuration_index`, field 2, not a resolution enum. Sending numeric `3` as the selection means Java index 3; it does not request 1080p. Native’s separate resolution helper supports enums 1–3 and returns **−8** for other values. Evidence: **G**`/proto/Protos.java:38486`; native `codecResolutionToPixels`, **0xC9EDC**; `VideoCodecResolutionType_IsValid`, **0x158A52**.

   **Q3 — CONFIRMED setup; UNKNOWN mismatched-stream behavior.**

   Honda initially configures MediaCodec from the Java callback’s logical dimensions:

   > `MediaFormat.createVideoFormat("video/avc", this.mVideoSize.width(), this.mVideoSize.height())`

   It adds `zero_display_delay=1`, calls `configure()`, sets video scaling mode 1, then starts. It chooses the codec using `createDecoderByType("video/avc")`; it does not explicitly name TI in this method. Evidence: **H**`/video/ProjectionRenderer.java:287`–`:305`.

   Codec-configuration bytes are subsequently queued as input; this Java path does not parse SPS to replace `mVideoSize`. The output loop does not rebuild layout on `INFO_OUTPUT_FORMAT_CHANGED`: it renders nonnegative output indices and otherwise continues. Evidence: the same file `:213`–`:236`, `:378`–`:411`, `:487`–`:508`.

   The saved XML declares for `OMX.TI.DUCATI1.VIDEO.DECODER`, `video/avc`:

   | Limit | Declared value |
   |---|---|
   | Size | 64×64 through 1920×1088 |
   | Alignment | 2×2 |
   | Block size | 16×16 |
   | Blocks/second | 1–489600 |
   | Bitrate | 1–62500000 |
   | Feature | `adaptive-playback` |

   Evidence: `logs/2026-10-22-investigation/media-codecs.xml`, quoted `<Limit>`/`<Feature>` elements. Its CR-CR-LF formatting makes line numbering reader-dependent.

   **SUPPORTED:** 1920×1080 is within the declared decoder envelope. Its macroblock grid is 120×68, so 60 fps reaches the exact declared ceiling. Margins do not reduce decoding cost if the transmitted raster remains 1080-class.

   **LIKELY:** 1080p30 presents less throughput risk than 1080p60; 720p presents still less. Neither establishes correct presentation through stock Java.

   **UNKNOWN:** TI’s acceptance of a 1920-class SPS after Honda configures 1280×688, actual profile/level support, allocation headroom, and resulting crop. The XML does not state AVC profile/level limits. Adaptive-playback declaration alone does not settle this configuration mismatch.

   Native offers the three resolution enums **800×480, 1280×720, 1920×1080**. There is no inspected native enum for 1920×720. Native `handleSetup`, **0xCA338**, accepts codec value **3**, H.264 baseline, and returns −8 for another setup codec.

   **Q4 — CONFIRMED: Honda’s pad coordinate range is independent of video geometry.**

   `HMIPresenter` returns input type **2**, coordinate dimensions **1325×720**, physical dimensions **60×40 mm**. Registration is:

   > `registerTouchPad(width, height, true, physicalWidth, physicalHeight, true, false)`

   These mean UI navigation enabled, UI absolute enabled, tap-as-select disabled. Evidence: **H**`/presentation/HMIPresenter.java:717`–`:738`; **H**`/integration/GalIntegration.java:120`–`:126`.

   Type 2 attaches the pad hover/touch listeners. Hover actions are translated into touchpad actions and sent using the event’s coordinates; clicks dispatch key events. `InputSource.sendTouchPadEvent()` truncates coordinates to integers. Native JNI/report/population paths copy these arrays into the touch event without geometry rescaling. Evidence: **H**`/ui/ProjectionActivity.java:559`, `:579`, `:2220`; **G**`/protocol/InputSource.java:140`; native **0xC1B9E**, **0xCAC3E**, **0xCA3AE**.

   The renderer’s `logicalWidth/surfaceWidth` and `logicalHeight/surfaceHeight` scaling belongs to the separate surface-touch path. It is not automatically applied to the active pad-hover path. “Pivot” dimensions control image transformation, not touchpad registration.

   **SUPPORTED requirement:** advertised pad dimensions must describe the coordinate domain actually transmitted. Keeping Honda’s 1325×720 pad advertisement is internally consistent even when video dimensions change; pad coordinates need not equal video pixels.

   Advertising 1920×720 pad coordinates while continuing to transmit the old range creates a mismatch unless the proxy also translates input events. **UNKNOWN:** exact runtime endpoint conventions and phone-side mapping. No evidence establishes a required 180-pixel touch offset. **C**`/source/.../InputConfig.java` explicitly states:

   > `Input geometry is independent of video geometry. No automatic touch transform.`

   **Q5 — CONFIRMED: a different serial is a consent issue, not an absolute phone whitelist.**

   `StartPreferences.getStatus()` defaults to **2 / ASK_USER**. Stored choices are **1 / ALWAYS**, **0 / NEVER**. An already-accessory device starts directly when ALWAYS or when its serial equals the temporary `mAllowedDeviceSerial`; ASK_USER leads to the new-device presentation. An accepted ordinary-mode device follows the same ASK_USER route. Evidence: **H**`/settings/StartPreferences.java:14`, `:33`; **H**`/service/GalService.java:736`–`:759`, `:790`–`:798`, `:1579`.

   Enabling in that presentation proceeds to GAL; “remember” saves ALWAYS. Disabling refuses the device and optionally saves NEVER. The temporary allowed serial is set before accessory switching to recognize the same device after re-enumeration. Evidence: `GalService.java:976`, `:1529`–`:1551`, `:1630`.

   **674 ms is not a switching deadline.** The log prints `mAttachTS − mDetachTS`. Actual accessory switching timeout is **3000 ms**, or **10000 ms** when started by LUM. Evidence: `GalService.java:694`–`:696`, `:973`–`:999`.

   Other inspected gates:

   - Non-null USB serial; valid device path under `/dev/bus/usb/003`; exclusion of the root hub and device class 9.
   - Excluded VIDs: Apple **1452 / 0x05AC**, and quirk-list **1921 / 0x0781**.
   - USB permission; ordinary-mode accessory protocol response greater than zero.
   - Accessory recognition checks PIDs **0x2D00, 0x2D01, 0x2D04, 0x2D05**. This particular function does **not** check VID.
   - Transport requires interface 0 with usable bulk IN and OUT endpoints.

   Evidence: `GalService.java:118`–`:122`, `:1035`–`:1079`, `:1940`; **H**`/transport/usb/UsbHostSetup.java:62`; **G**`/transport/usb/UsbHostTransport.java:51`.

   Honda sends these AOA identifying strings:

   | Index | Value |
   |---|---|
   | Manufacturer 0 | `Android` |
   | Model 1 | `Android Auto` |
   | Description 2 | `Android Auto` |
   | Version 3 | `1.0` |
   | URI 4 | `http://www.android.com/auto` |
   | Serial 5 | `0000000012345678` |

   Evidence: `UsbHostSetup.java:76` onward, `sendAccessoryString()` calls.

   These are **host-supplied AOA strings**, not an inspected comparison against the gadget’s USB manufacturer/model descriptors. The AOA string at index 5 is distinct from `UsbDevice.getSerialNumber()` used by consent handling.

   **SUPPORTED:** a board can use a new stable serial and pass through normal consent; reproducing the user’s phone serial is not statically required. Its descriptors, AOA behavior, re-enumeration, endpoints, and protocol session must still satisfy these paths. Overall board compatibility remains **UNKNOWN**.

   **Q6 — LIKELY ranking, conditional on successful connection and index 0 selection.**

   | Rank | Outcome | Assessment |
   |---|---|---|
   | 1 | **(b) Mis-scaled/cropped/misaligned video** | Best-supported result **if larger-stream decoding succeeds**. Honda retains the original viewport and crop transform. |
   | 2 | **(c) Black/error/crash** | Credible alternative from decoder mismatch. An unlisted index additionally produces the confirmed Java bounds failure. |
   | 3 | **(d) Refusal to connect** | Conditional on USB/AOA/permission/consent incompatibility. Unknown serial alone normally prompts. |
   | 4 | **(a) Correct full-width video** | No supported SDR-only path: neither valid Java index produces 1920×720 geometry. |

   Ranking (b) above (c) is an engineering estimate, **not a measured probability**. Decoder behavior prevents a stronger ordering. If an unlisted index is used, (c) becomes the leading outcome class.

   **Single settling observation:** one bench run of the unchanged receiver with rewritten entry 0, selection 0, and an edge-labelled 1920-class H.264 stream, recording decoder output and the resulting viewport. Successful decode into the old viewport establishes (b); decoder failure establishes (c). Correct full-width rendering would contradict this traced path and require checking runtime artifact identity or an additional geometry-changing mechanism. No such run was performed.

   **Q7 — CONFIRMED advertisement fields; no sufficient SDR-only edit set exists.**

   For a phone-facing Candidate A advertisement, replace the existing primary entry while preserving its index:

   | Path within SDR | Field/value |
   |---|---|
   | `service.media_sink_service.available_type` | Preserve **3**, H.264 baseline |
   | `media_sink_service.video_configs[0].codec_resolution` | **3**, `VIDEO_1920x1080` |
   | `.frame_rate` | **1**, `VIDEO_FPS_60`, for Candidate A |
   | `.width_margin` | **0** |
   | `.height_margin` | **360** |
   | `.density` | Preserve **229** |
   | `.real_density`, decoder depth, pixel aspect | Preserve actual advertised values |
   | `input_source_service.touchpad` | Preserve **1325×720**, **60×40 mm**, navigation=true, absolute=true, tap-as-select=false |

   A 30 fps variant uses frame-rate enum **2**. That matches the later clean-receiver experiment, rather than Candidate A’s 60 fps.

   Protocol nesting and field numbers:

   - SDR services: field **1**.
   - Service media sink: field **3**; input source: field **4**.
   - Media sink video configurations: field **4**; codec type: field **1**.
   - Video configuration: resolution **1**, frame rate **2**, width margin **3**, height margin **4**, density **5**.
   - Input source touchpad: field **3**.
   - Touchpad: width **1**, height **2**, navigation **3**, physical width **4**, physical height **5**, absolute **6**, tap-as-select **7**.

   Evidence: **C**`/source/.../DiscoveryCodec.java:6`–`:21`; **G**`/proto/Protos.java:5918`, `:8410`, `:9095`, `:10880`, `:11448`.

   Preserve fallback entry 1 and the existing service IDs. Replacing entry 0 avoids inventing an unlisted selection. Appending a new entry would also require consistent `Config.configuration_indices` and `Start.configuration_index` translation; that still would not update Honda’s Java geometry.

   Native strings expose `VideoConfiguration`, margin/density field symbols, `InputSourceService_TouchPad`, and touchpad field symbols. Exact numeric values above come from the primary protobuf definitions and native disassembly, not inference from strings.

6. **Primary evidence for each finding**

   - **Q1:** `DimensionUtils.java:14` calculates the viewport; `Settings.java:50`/`:58` contain `"1240"`/`"606"`; `ProjectionRenderer.smali:615`/`:622` use `div-float`.
   - **Q2:** `VideoSink.java:161`: **`mVideoConfigurations.get(index)`**; `ProjectionListenerWrapper.java:26`: **`width - config.getWidthMargin()`**, corresponding height subtraction. Native **0xC547A** and **0xC9E92** forward the selected index.
   - **Q3:** `ProjectionRenderer.java:291`: **`MediaFormat.createVideoFormat(...)`** using `mVideoSize`; XML: **`max="1920x1088"`**, **`max="489600"`**, **`adaptive-playback`**.
   - **Q4:** `GalIntegration.java:126`: **`registerTouchPad(...)`**; `InputSource.java:149`–`:153` copies event coordinates; native **0xCA40E–0xCA432** copies coordinate arrays into protobuf entries.
   - **Q5:** `StartPreferences.java:35`: **`prefs.getInt(statusKey(serial), 2)`**; `GalService.java:758`: **`setupGui(GUI.ASKUSER)`**; `UsbHostSetup.java:62` recognizes accessory PIDs.
   - **Q6:** Combination of the confirmed Java lookup, viewport, decoder setup, and independent USB gates above. Outcome frequencies remain unmeasured.
   - **Q7:** `DiscoveryCodec.java:7`–`:8` encodes resolution/rate/margins/density; `Protos.java:9096`–`:9104` and `:11449`–`:11455` define the field numbers.

   Native addresses refer to the verified library SHA-256:  
   **`031797DD4B0AECCA007A3AD7AF31C365BA3D47BEBDA8C94BFF13C5289F464C50`**.

7. **Assumptions**

   - “Protocol-only proxy” changes wire advertisements/selections/input, while Honda Java/native configuration objects remain unchanged.
   - The inspected artifacts represent the relevant stock receiver implementation. Complete live APK/DEX identity parity was not independently established here.
   - The proposed phone actually accepts the rewritten advertisement and emits the intended stream; that is not demonstrated by the synthetic fixtures.

8. **Unresolved uncertainties**

   **UNKNOWN:** actual phone SPS/raster/margin placement; TI response to the larger initial stream; negotiated AVC profile/level; final JNI consequence of a bounds exception; exact pad endpoint ranges and phone normalization; board-specific connection compatibility.

   The decisive distinction is established statically: **changing what the phone sees does not change which original Java entry Honda uses for rendering.**

9. **Exact diff summary**

   **None.** No edits or generated artifacts.

10. **Preservation checks performed**

   Manifest-based SHA-256 checks all returned `match=True`:

   - Frozen M5 APK: `A22E96490B9557AFF022893A8B8B7A08BB13CEC236E52704CDDAFA90A8EE8F40`.
   - Disabled M6 APK: `D4DAC2DD8B2AFF1FA7B64BFB32D2A5E889854CCEB4B4A9F7AD5AEF89FB28761F`.
   - Both listed receiver DEX copies: `2FDBC63F2F9D63B764697D311AF89D460AE6B8E14B0FADABA9C9339F7FE7C235`.
   - TLS qualifier APK: `86350131FFC5CBE5766E523AB03AE07D4C9F5EAD78F0570B68255C9A3999FC1F`.

   Native source/evidence copies matched the hash in item 6; the source library was rehashed at completion. No device commands, USB operations, milestone actions, builds, or key-material reads were performed.