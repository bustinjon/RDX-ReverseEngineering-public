**No verified “force one full-width app” command was found in Honda’s receiver interface.** The practical candidates are AA’s own app-view controls, different advertised geometry, real density, and pixel aspect ratio. Geometry changes may produce a single-app layout, but preserving a correctly proportioned picture across all 1920×720 pixels remains **UNKNOWN**.

**1. Files inspected**

Read `PROJECT-RULES.md` first, then `AGENTS.md`. Inspected these sources, including targeted excerpts/searches:

- `decompiled/AndroidAuto-current/sources/com/google/android/projection/proto/Protos.java`.
- Stock protocol `VideoSink.java`, `GalReceiver.java`, `InputSource.java`, `NavigationStatus.java`, and `GalVerificationVendorExtension.java`.
- Honda `GalIntegration.java`, `AbstractGalIntegration.java`, `ProjectionListenerWrapper.java`, `ProjectionActivity.java`, and `HMIPresenter.java`.
- Full-smali `VideoSink.smali`, `InputSource.smali`, and `GalReceiver.smali`.
- `analysis/libautoreceiver_jni.so.strings.txt`.
- Hackura’s supplied protocol `VideoSink.java`, `GalReceiver.java`, `InputSource.java`; projection session/decoder sources.
- Helper `VideoGeometry.java`, relevant session/overlay excerpts.
- T60’s saved `AppSettings.java`, `VideoSink.java`, `AaSessionService.java`, `RESULT.md`, and `VISIT-NOTES-20261106.md`.
- Public `LATEST-TEST-PLAN.md`, earlier fullscreen-layout theory, and targeted related review excerpts.

**2. Files changed**

None by this review. One inspected file’s byte hash differed between checks; see preservation checks.

**3. Commands run**

Only local read/search/hash/arithmetic commands:

- `Get-Content`, `rg -n`, `rg --files`, `Select-String`, `Select-Object`.
- `Get-FileHash -Algorithm SHA256`, `Get-Item`.
- PowerShell arithmetic for nominal dp dimensions and aspect fitting.

Some exploratory commands failed: an unexpanded `*.java` path, two guessed helper filenames, unavailable `python.exe`, and a .NET byte-inspection attempt blocked by PowerShell’s constrained language mode. Subsequent searches found the relevant files; arithmetic succeeded in PowerShell. No Git, network, build, device, ADB, or credential-material access occurred.

**4. Tests run and results**

- **No software or car tests executed.**
- Static checks cross-checked Java against smali descriptors and native symbol strings.
- Arithmetic confirmed the dimensions below.
- T60’s recorded car result was reviewed, not rerun.
- Hash checks: protobuf and native strings unchanged; supplied facade hash mismatch recorded below.

**5. Findings**

Evidence references E1–E12 are mapped to paths and lines in section 6. Likelihood rankings are engineering estimates, not measured probabilities.

**Receiver-controlled fields**

This version’s `VideoConfiguration` contains **exactly nine declared fields**. Eight reach the stock JNI configuration call; viewing distance does not. “Settable” below means exposed at the JNI boundary, not independently verified on-wire transmission. [E1–E3]

| Field / protobuf number | Potential layout significance | Honda native / supplied Hackura facade |
|---|---|---|
| `codec_resolution` / 1 | Selects coded raster; influences available geometry and negotiation. | Settable. Defined enums are 800×480, 1280×720, 1920×1080. Hackura advertises enums 3 and 1. |
| `frame_rate` / 2 | Timing/performance; no evidence of a split-layout function. | Settable; stock converts enum to 30/60. Hackura uses 60. |
| `width_margin` / 3 | Reduces active width; directly changes active aspect ratio and nominal logical width. | Settable. Hackura primary uses 0. |
| `height_margin` / 4 | Reduces active height; directly changes active aspect ratio and nominal logical height. | Settable. Hackura primary uses 360. |
| `density` / 5 | Logical UI scale; potential layout input. | Settable. Supplied facade uses 229; T60 substituted 320/400. |
| `decoder_additional_depth` / 6 | Decoder buffering parameter; no evidenced layout-selection role. | Settable. Hackura uses 0. |
| `viewing_distance` / 7 | Could inform physical-size/readability policy if transmitted and used. Exact units/use here **UNKNOWN**. | Builder supports it, but stock `addSupportedConfiguration()` never forwards it. No corresponding setter found. |
| `pixel_aspect_ratio_e4` / 8 | Non-square-pixel geometry description; could affect effective aspect/physical-size interpretation. Phone behavior **UNKNOWN**. | Settable as eighth JNI integer. Java converts ratio ×10,000; default/Hackura value is 10,000. |
| `real_density` / 9 | Physical-density description, distinct from logical UI density; possible physical-size policy input. | Settable as sixth JNI integer. Stock measures average `xdpi/ydpi`; T60 passes constant 229. |

The margins are **total dimensions removed**, not separately addressable left/right/top/bottom insets: Honda subtracts width margin once and height margin once. Hackura’s renderer centers the resulting margins when decoding the whole coded raster. [E2, E6, E11]

Other relevant protocol surfaces:

| Surface | What is available | Layout implication / limitation |
|---|---|---|
| Media sink description | Codec `available_type`, video-configuration list, audio fields, availability during calls. | `available_type` is a **codec**, not main/cluster display type. No full-screen preference field appears here. [E10] |
| Configuration selection | `Config`: status, max unacknowledged frames, configuration indices; `Start`: session ID, configuration index. | Supports profile negotiation. No “maximize Maps/Spotify” field. Selection and actual decoder output must be logged. [E10] |
| Session configuration | `HIDE_CLOCK=1`, `HIDE_PHONE_SIGNAL=2`, `HIDE_BATTERY_LEVEL=4`, native-media-during-VR=8. | Exposed through `CarInfo`; no declared hide-secondary-pane/fullscreen bit. Hiding status indicators is not evidence of pane removal. [E7] |
| Driver position | Left/right/center/unknown. | Plausible control-side/layout-placement input; no evidenced single-pane meaning. [E7] |
| Vehicle/head-unit identity | Make/model/year/ID, head-unit identity/version, display name; discovery also has probe-for-support. | Identity-dependent phone policy is possible but **UNKNOWN**. No documented fullscreen value found. [E7] |
| Touchscreen | Width, height, capacitive/resistive/infrared type. | Native supports registration; supplied facade declares the native method but exposes no public touchscreen-registration wrapper. These describe input, not an evidenced pane count. [E8] |
| Touchpad | Logical width/height, physical width/height, UI navigation, UI absolute, tap-as-select. | Native supports all; supplied wrapper fixes tap-as-select false. Changing these risks focus/input behavior; layout effects **UNKNOWN**. [E8] |
| Keys/feedback | Supported keycodes and feedback events; input events. | Navigation/media category keys exist. They can request an app/category; no declared maximize key was identified. [E8, E10] |
| Video/navigation focus | Projected/native/transient video focus; navigation-focus notifications. | Changes projection/native ownership, not an identified AA internal pane-selection command. [E10] |
| Display/service IDs | Generic service IDs; focus request has display-channel ID. | Multiple channel identifiers do not establish support for multiple independently classified video displays. Hackura fixes video service ID 1. [E3, E10] |
| “Cluster” service | Navigation status, IMAGE/ENUM type, image dimensions/depth, update interval. | This is turn-by-turn information. Stock Honda chooses ENUM; callbacks carry road/turn/image/distance, not a second continuous map-video stream. [E9] |
| Display-information diagnostic | Native view width/height response. | Verification endpoint, not an identified layout-control API. [E12] |

**Insets and newer display features:** no per-edge UI insets, stable-content insets, main/cluster display-role field, car-display UI-feature structure, or explicit split/fullscreen field was found in this `Protos.java` and native strings search. This is a bounded finding about these artifacts. Newer protocol implementations may differ; their field definitions and Honda-library support are **UNKNOWN**. Adding Java protobuf fields alone would not extend this eight-integer JNI call. [E1–E3, E12]

**What T60 actually established**

“320/400 dp” is misleading terminology in the public checklist. T60’s saved source sends **320/400 dpi**, not 320/400 dp widths. `layoutDpi()` overrides logical density, while the second density argument remains 229. Geometry and pixel aspect remain unchanged. [E4]

Using conventional `dp = pixels × 160 / density`:

| Advertised logical density | Nominal active dimensions |
|---|---|
| 229 dpi | 1341.48 × 503.06 dp |
| 320 dpi | 960 × 360 dp |
| 400 dpi | 768 × 288 dp |

These are calculations, not captured phone display metrics. T60 records enlarged UI and split layout remaining at both probes. [E5]

That is a counterexample to a simple assertion that this phone necessarily becomes single-pane below 960 or 768 nominal dp wide. It does **not** establish that density never affects layout, nor isolate aspect ratio, real density, caching, or phone-version policy. Increasing density further rapidly sacrifices height: 480 dpi gives only 240 nominal dp vertically; a genuine 400-dp width would require 768 dpi and yield 150-dp height.

**Known behavior versus unverified knowledge**

- **Repository evidence:** geometry, density and input capabilities are receiver advertisements; the receiver receives video frames. No app-layout command was identified. The exact phone-side decision code is unavailable. [E1–E3, E8]
- **General Android Auto knowledge, not verified against this phone:** AA offers dashboard and app views; opening an app/tapping its tile can expand it on supported layouts. Wide-display layouts can retain a companion pane. Available controls vary by phone/AA release.
- **General community knowledge, unverified here:** receiver/emulator and wireless-adapter users experiment with density, negotiated resolution and aspect ratio. This supports investigating those variables, not a universal threshold.
- **Verified community numerical recipes: UNKNOWN.** No primary captured community result establishing a particular resolution/margin/dpi tuple was found in the searched local material. Network access was prohibited. The following geometries are experiments, not claimed community-proven settings.
- Existing archived “fullscreen receiver” discussions often concern filling Honda’s physical viewport. That does not establish removal of Coolwalk’s companion pane.

**Ranked options**

| Rank | Option | Likelihood and risk |
|---|---|---|
| 1 | Open Maps/Spotify through AA’s app icon, tap the dashboard tile, and use any visible expand/app-view control. | Best first check: negligible risk, unchanged advertisement. Success on this ultrawide layout **UNKNOWN**; expansion may stop at the existing large pane. |
| 2 | Advertise a less-wide active picture using margins. | **Medium** prospect of changing phone layout; untested here. **Low–medium** implementation risk. A 1280×720 single-app source preserves aspect only with side bars on this panel. |
| 3 | Change `real_density` alone, keeping logical density and geometry unchanged. | **Low/UNKNOWN** prospect, but an independent exposed variable T60 did not isolate. Low configuration risk; may change physical-size interpretation or be ignored. |
| 4 | Change pixel aspect ratio alone. | **Low/UNKNOWN**, potentially useful because dimensions can remain 1920×720. Medium risk: distortion, different phone scaling, or ignored value. Direction of its layout effect is unproven. |
| 5 | Further logical-density experiments. | **Low** expected value after T60. Reversible, but likely oversized/unusable UI. Lower density may rearrange content without eliminating the pane. |
| 6 | Force a lower-resolution negotiated profile, including existing fallback. | **Medium** prospect of a different app layout; full physical width with correct proportions unlikely under present aspect fitting. Risks blur, bars, and input-scale mistakes. |
| 7 | AA phone settings: layout/driver-side choice, taskbar widgets, quick controls; Maps/Spotify preferences; launcher customization. | Negligible direct risk. No locally evidenced setting forces this wide display to one pane. Settings that move controls or remove widgets may leave the companion pane. |
| 8 | AA developer settings. | “Unknown sources” and app/developer modes have no evidenced pane-selection function. Resolution caps may change negotiation and therefore belong to rank 6. A current supported “disable Coolwalk” toggle is **UNKNOWN**. |
| 9 | Navigation/media keys or repeated video-focus requests. | Useful for opening/foregrounding an app, **very low** prospect of removing a layout-imposed pane. Focus changes can disturb native/projection transitions. |
| 10 | Session hide-clock/signal/battery flags. | **Very low** prospect: declared meanings concern status indicators. Low risk if valid bits only; no justification for guessing undocumented bits. |
| 11 | Change touchscreen/touchpad/navigation capabilities. | **Very low/UNKNOWN** prospect. Medium risk of losing usable focus, selection, or coordinate mapping. Not an early layout test. |
| 12 | Insets, stable insets, newer UI/display features. | No identified setter through this library/facade. High implementation uncertainty; not a simple configuration experiment. |
| 13 | Secondary/cluster video stream. | No supported full-map video route established here. High implementation cost/risk; existing turn-by-turn service does not provide it or arbitrary Spotify video. |
| 14 | Spoof vehicle/head-unit identity. | **Low/UNKNOWN** prospect; potential cached-profile and compatibility effects. No evidenced identity value to recommend. |
| 15 | Phone-side root/AA patching, old versions, launcher hacks. | Outside a receiver-supported solution; exact effectiveness **UNKNOWN**. Highest maintenance/compatibility risk. Not recommended for this investigation. |
| 16 | Crop/stretch the received large pane across the panel. | High certainty of visually hiding the other pane, but **does not make the phone reflow**. Stretch distorts; aspect-preserving zoom loses content/controls. Input must follow the transform. |

Maps’ ordinary phone UI preferences, Spotify’s phone UI, and a phone’s home-screen launcher should not be assumed to control AA’s host layout. No such control was established here. Likewise, a dedicated modern cluster map, where supported elsewhere, would not itself prove that the main AA display can maximize arbitrary apps.

**Concrete future car-test plan — proposed only**

Prerequisite for any new profile: advertising values, selection callback, decoder configuration, renderer geometry and input mapping must agree. The supplied facade’s callback hardcodes 1920×720 at index 0; changing only its native advertisement would create inconsistent local geometry. [E3, E11] No implementation/build is authorized or performed by this report.

Each test below is one independently selected change, restored to baseline before the next:

| Test | Single switch/change | What it distinguishes; expected risks |
|---|---|---|
| T0 | Baseline, unchanged advertisement. | Record phone OS, AA/Maps/Spotify versions and existing settings. Open each app through its icon/tile; try only visible expand controls, one action at a time. |
| T1 | Primary `widthMargin: 0 → 640`; everything else unchanged. | Active 1280×720, 16:9, about 894×503 nominal dp. Does reduced width/aspect enable one app? Present renderer predicts **320-pixel bars per side**. |
| T2 | Primary `heightMargin: 360 → 0`; everything else unchanged. | Active 1920×1080, 16:9, same nominal width as baseline. Comparison with T1 helps distinguish width from aspect/height effects. Aspect fitting again predicts 1280-pixel physical width. |
| T3, conditional | If T1 succeeds, `widthMargin: 0 → 480` from baseline. | Active 1440×720, 2:1. Searches for a less restrictive successful geometry. Still not guaranteed true panel-width output. |
| T4 | `realDensity: 229 → 320`, assuming baseline log confirms 229. | Holds logical density/aspect constant. Tests physical-density interpretation separately from T60. |
| T5, exploratory | `pixelAspectE4: 10000 → 7500`. | Tests non-square-pixel interpretation at unchanged active dimensions. Reject visible geometric distortion; effect may be ignored. |
| T6, conditional | Restore baseline, then `pixelAspectE4: 10000 → 13333`. | Reciprocal-direction probe only if T5 remains usable and informative. No direction is presumed correct. |
| T7, optional | Cap negotiation to an existing lower profile, with matching callback geometry. | Tests whether another raster/profile offers app-view expansion. Record actual selection; do not assume the phone chose the requested profile. |

For every test, log intended configuration fields, configuration index, selected codec/active dimensions, decoder output size/crop, viewport transform and input geometry. Existing sources already expose selection, decoder-crop and geometry logging points. These local callbacks alone do not prove the phone’s internal logical metrics. [E3, E11]

Use parked operator photos and receiver logs to record dashboard → Maps → Spotify transitions, pane boundaries and corner/center input accuracy. Confirm media, navigation prompts and return to Honda remain usable. No live action is authorized here.

**Success has two separate levels:**

- **Layout success:** one app owns the active application canvas, excluding normal AA system chrome; no companion pane or replacement stacked card remains.
- **Requested panel-width success:** that app also uses the physical 1920×720 area with usable controls and acceptable proportions. Bars, stretching, or cropping must be reported as tradeoffs, not silently counted as equivalent success.

Risks include wrongly centered crops, black bars, unexpected SPS/decoder dimensions, blurry scaling, distorted maps, oversized UI, touch-coordinate errors and lost controls. Native acceptance and phone behavior for unusual margins/PAR remain **UNKNOWN**.

**6. Primary evidence for findings**

- **E1 — schema:** [Protos.java:9095](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/google/android/projection/proto/Protos.java:9095), fields at 9096–9104; [resolution enums:611](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/google/android/projection/proto/Protos.java:611).
- **E2 — conversion/JNI boundary:** [stock VideoSink.java:78](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/google/android/projection/protocol/VideoSink.java:78): margin calculations 82–93, viewing-distance builder 103–104, eight forwarded values at 118. [Smali:117](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current-smali-full/com/google/android/projection/protocol/VideoSink.smali:117) confirms `(IIIIIIII)V`; call at 229.
- **E3 — Hackura/native:** [supplied VideoSink.java:17](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/src/com/google/android/projection/protocol/VideoSink.java:17), advertisements 27–29 and hardcoded callback 42–45. [Native strings:418](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/libautoreceiver_jni.so.strings.txt:418) identifies JNI and C++ eight-integer method; protobuf field symbols at 9368–9376.
- **E4 — T60 units/path:** [AppSettings.java:90](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/test-prep/todo-tests-20261103/builds/T60-bundle/source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/AppSettings.java:90); choices at 13–17. [AaSessionService.java:375](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/test-prep/todo-tests-20261103/builds/T60-bundle/source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/AaSessionService.java:375), `DPI=229` at 42. [Saved VideoSink.java:31](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/test-prep/todo-tests-20261103/builds/T60-bundle/source/analysis/parallel-aa-receiver/src/com/google/android/projection/protocol/VideoSink.java:31) forwards `layoutDpi,realDpi`.
- **E5 — observed outcome:** [T60 RESULT.md:13](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/test-prep/todo-tests-20261103/builds/T60-bundle/RESULT.md:13); [visit notes:13](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/test-prep/todo-tests-20261103/builds/T60-bundle/VISIT-NOTES-20261106.md:13); public terminology at [LATEST-TEST-PLAN.md:68](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/publication/RDX-ReverseEngineering-public/LATEST-TEST-PLAN.md:68).
- **E6 — Honda geometry:** [HMIPresenter.java:819](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/presentation/HMIPresenter.java:819); [AbstractGalIntegration.java:152](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/integration/AbstractGalIntegration.java:152) measures real DPI; [ProjectionListenerWrapper.java:25](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/integration/ProjectionListenerWrapper.java:25) subtracts margins. Local renderer emulation is in [ProjectionActivity.java:2232](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/ui/ProjectionActivity.java:2232).
- **E7 — session/identity:** [Protos.java:243](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/google/android/projection/proto/Protos.java:243), discovery fields at 4752–4766; [Hackura CarInfo:18](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/src/com/google/android/projection/protocol/GalReceiver.java:18); stock native setters at [GalReceiver.java:166](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/google/android/projection/protocol/GalReceiver.java:166); native member-name strings 13471–13485.
- **E8 — input:** [Protos.java:10877](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/google/android/projection/proto/Protos.java:10877), touchscreen fields 10973–10976, touchpad fields 11448–11455; [stock InputSource.java:38](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/google/android/projection/protocol/InputSource.java:38); [Hackura wrapper:59](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/src/com/google/android/projection/protocol/InputSource.java:59).
- **E9 — cluster distinction:** [NavigationStatus.java:22](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/google/android/projection/protocol/NavigationStatus.java:22); [Honda ENUM configuration:61](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/integration/GalIntegration.java:61); [Protos.java:15267](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/google/android/projection/proto/Protos.java:15267), type/image options 15353–15400, next-turn payload 70501–70507.
- **E10 — negotiation/focus/keys:** [Protos.java:8405](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/google/android/projection/proto/Protos.java:8405); `Start` 38486–38488; `Config` 39205–39208; focus fields 40178–40181 and 40659–40661; focus enum 1685–1688; navigation/media keys 3156–3157.
- **E11 — presentation/logging:** [VideoGeometry.java:14](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/VideoGeometry.java:14), fitting 27–29 and inverse coordinates 59–60; [selection log:525](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/AaSessionService.java:525); [geometry log:609](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/AaOverlayService.java:609); [decoder crop:76](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/src/com/rdx/fullscreen/projection/VideoDecoder.java:76).
- **E12 — diagnostics/negative search:** [GalVerificationVendorExtension.java:135](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/google/android/projection/protocol/GalVerificationVendorExtension.java:135). `rg -n -i 'inset|stable.?content|display.?type|display.?id|car.?display|ui.?features|full.?screen|split.?screen|coolwalk'` over `Protos.java` and native strings returned no matches, exit 1.

**7. Assumptions**

- “Full screen” means one app across the panel while retaining normal AA chrome, usable controls and acceptable geometry.
- Android’s conventional density formula is useful for comparison; actual phone-reported metrics were not captured.
- The supplied stock sources/native strings describe the intended library interface; runtime artifact parity was not established.

**8. Unresolved uncertainties**

Phone OS/AA versions, server-side feature policy, exact split-layout thresholds, current expand controls, use of real density/PAR, viewing-distance defaults, unusual-profile acceptance, and multi-video support are **UNKNOWN**. Native strings establish symbols, not complete function behavior. No community numerical recipe was verified.

**9. Exact diff summary**

None produced; no edits made. A stable whole-workspace comparison was not available, and Git was prohibited.

**10. Preservation checks performed**

Repeated SHA-256 checks produced:

| Artifact | First → later hash |
|---|---|
| `Protos.java` | Unchanged: `D54025923E8454691FF08BA2F6CBD3935F2D7A417EC3F582DFDFD5DF29270E45` |
| Native strings | Unchanged: `27C3F9523C8696F78B1E9FA011715667FBAF4DC98B32D5E73C75A0E500D816DF` |
| Supplied `VideoSink.java` | `7BB6AF00A810FB11A64F9015F5B4E6D9DE6A447B075789A1FDB3D10393616C8C` → `9607810F730B038519E49080EADDCA74610E0EEDB4315CC7AAD06FBEDF71895A` |

The facade was reread; its displayed configuration and JNI lines still match the findings above. Cause of the byte-hash difference is **UNKNOWN**; line-ending inspection failed, so no explanation is asserted. This review issued no write commands. Frozen binaries were neither rebuilt nor modified by this review; their hashes were not independently verified.