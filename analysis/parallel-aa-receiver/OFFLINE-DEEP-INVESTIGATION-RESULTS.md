# CURRENT BEST PATH

**Prioritize C: a clean, ordinary-app receiver using Android USB/AOA, an open-derived Android Auto protocol implementation, MediaCodec, and our own Surface. Keep Honda-native reuse as an optional fallback.**

**M3 is no longer on the critical path.** It cannot resolve USB ownership, and it is unnecessary for passive USB enumeration or independent decoder testing.

The most consequential finding is that **Honda’s `auto-start=false` preference does not disable its USB/protocol startup**. Stock AA can respond to attachment and accessory re-enumeration regardless of whether our application launches a UI.

This session used local files and public documentation only. **No ADB operations occurred.** The workspace is read-only, so I could not save the requested reports, update `NOTES.md`, generate streams, or build APKs. The findings and implementation plans below are the deliverable; no new build is claimed.

## 1. Native loading and M3

### What is established

The receiver library has three automatic initialization entries:

| Entry | Actual behavior | Classification | Confidence |
|---|---|---|---|
| `0xBB180`, `OPENSSL_cpuid_setup` | Reads CPU/environment information; performs guarded instruction probes; temporarily changes signal handling and restores it | Process-local runtime initialization | HIGH |
| `0xBB358` | Initializes generated Acura protobuf descriptors/default objects; initializes 82 empty strings and registers destructors | Runtime allocation and protobuf initialization | HIGH for identified entry and principal calls |
| `0xBBCE8` | Sets `WireFormatLite::kMessageSetItemTagsSize` to `4` | Static constant initialization | HIGH |

These are **not three receiver-session startup functions**.

The receiver has no identified `DT_INIT`, exported `JNI_OnLoad`, or ELF TLS sections. Its first initializer slot is relocation-backed; interpreting the unrelocated zero as a function address would be incorrect.

The dependency tree is:

[Code block omitted from public report; see authored source where available.]

The local copies of `liblog`, `libm`, `libstdc++`, and `libdl` have no identified initialization arrays. `libc` has seven entries, but libc is already initialized in a running Android Java process; loading another dependent library does not normally execute those constructors again.

### What the deeper STLport analysis resolved

The two STLport entries lead to iostream initialization and mutex initialization.

| Function/path | Observed behavior |
|---|---|
| `_Locale_init`, `0x325E8` | Builds ASCII character-classification tables and clears remaining table storage |
| `ios_base::Init` | Initialization-count guard, then locale/iostream/file-buffer setup |
| `ios_base::_S_initialize`, `0x1E508` | Constructs narrow/wide standard-stream wrappers, ties streams, sets flags and vtables |
| `_Filebuf_base::_S_initialize` | Calls `sysconf`, stores a runtime value |
| `_Filebuf_base::_M_open(int,int)`, `0x1BDF0` | Wraps an **existing file descriptor**; calls `fcntl(F_GETFL)` and `fstat` |
| `locale` initialization | Builds classic locale facets, reference counts, strings, vectors and synchronization |
| `codecvt` methods examined | Constant-return encoding/conversion metadata |
| Message/money facets examined | Object construction and mutex initialization |
| Time facets examined | String/table construction |

**The `_M_open(int,int)` path is not a filename-open operation.** It does not establish a USB-device or Honda-private-file access.

No GAL session, USB operation, decoder allocation, Honda Binder call or preference write was identified in the traced initialization paths.

However, **complete load-time safety is not yet established to the requested standard**. Remaining closure work includes all locale-facet/vtable targets, exceptional cleanup paths, protobuf transitive initialization beyond the existing direct-call survey, and precise resolution against the libraries actually mapped in the future process. One examined invariant-failure path can print and abort; “runtime initialization” does not mean loading cannot crash its process.

**Overall confidence: MEDIUM. M3 remains deferred.**

### Answers 1–5

1. **Complete library-load safety established?** No; substantially narrowed, not fully closed.
2. **What remained in STLport?** Standard streams, locale facets, character tables, mutexes, existing-FD inspection and allocation/cleanup—not an identified projection startup.
3. **Safe to build an inert headless M3 probe?** A disabled skeleton is appropriate. An enabled probe is not cleared under your conditional requirement.
4. **Built?** No—read-only workspace.
5. **Do we still need M3?** **No, strategically.** Retain it only if Honda’s protocol implementation later offers enough savings to justify its remaining audit and integration burden.

A future M3 service should have no Activity, credentials, Google receiver facade, USB code or media code. `stopSelf()` ends the service but **does not guarantee process termination or native-library unloading**; cleanup must verify its process is gone.

## 2. Honda USB/AOA and stock competition

The relevant local implementation is [UsbHostSetup.java](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/transport/usb/UsbHostSetup.java), together with [GalService.java](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/service/GalService.java).

### Exact Honda sequence

1. USB attachment reaches Honda’s receiver or its running `GalService`.
2. Honda checks operating state, device identity and per-phone start policy.
3. For a non-accessory device, it opens the device and queries AOA support.
4. Its conversion path opens the device, calls `claimInterface(interface0, true)`, sends identification strings, then sends AOA START.
5. The phone disconnects and re-enumerates.
6. For an accepted accessory device, Honda creates its connection manager.
7. Its transport opens interface 0, force-claims it, locates bulk IN/OUT endpoints and starts transport.

| Operation | Honda implementation |
|---|---|
| AOA protocol query | Request `51`, request type `0xC0`, two-byte response |
| Identification | Request `52`, request type `0x40`, indices 0–5 |
| Start accessory mode | Request `53`, request type `0x40`, no payload |
| Control timeout | **100,000 ms** |
| Manufacturer/model/description | `Android` / `Android Auto` / `Android Auto` |
| Version | `1.0` |
| URI | `http://www.android.com/auto` |
| Serial string | Fixed implementation string |
| Accepted accessory PIDs | `0x2D00`, `0x2D01`, `0x2D04`, `0x2D05` |
| Bulk endpoints | Type 2, directions IN/OUT |
| Bulk transfer timeout | **36,000,000 ms** |
| Cleanup | Includes a hidden USB reset path for some stop reasons |

The PID helper itself does not check VID. Our implementation should validate both.

Honda and the examined Open Headunit Java path send string bytes without explicitly appending a NUL. Official AOA documentation specifies NUL-terminated UTF-8 strings. Our implementation should follow that specification rather than copy this discrepancy. [AOA protocol documentation](https://source.android.com/docs/core/interaction/accessories/aoa)

Accessory-capable Google PIDs are `18D1:2D00/2D01/2D04/2D05`; `2D02/2D03` are audio-only variants. The ADB interface, where present, is not our projection interface. [AOA 2.0](https://source.android.com/docs/core/interaction/accessories/aoa2)

### Privilege boundary

The pulled framework explicitly implements:

[Code block omitted from public report; see authored source where available.]

Otherwise it checks a per-device permission map for the calling UID.

Therefore:

- **Honda benefits from UID1000’s automatic USB permission.**
- Ordinary apps have a separate supported permission path.
- Enumeration does not use the device-open permission check.
- `openDevice()` checks permissions and restricted-bus rules.
- A permission grant does **not** provide exclusive ownership of an interface.

See [UsbSettingsManager.java](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/usb/UsbSettingsManager.java:818) and [UsbHostManager.java](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/usb/UsbHostManager.java:170).

### Answers 6–12

6. **How does Honda perform USB/AOA?** Through normal Android USB objects and control/bulk transfers, plus OEM reset/state-management integration.
7. **Privileged USB behavior?** Yes: UID1000 bypasses normal permission prompting. This does not prove ordinary-app USB access is impossible.
8. **Reusable Open Headunit portions?** Device identification, permission flow, endpoint validation, bounded transfer handling, framing/reassembly, TLS integration, service discovery and MediaCodec patterns. Its Android build declares older-API support. **Do not import its force-claim, reset/reconnect loops, root/Shizuku dependencies or OEM-app controls.** Its checked-in license is AGPLv3; preserve applicable licensing when reusing code.
9. **M4?** Passive `getDeviceList()`/descriptor/`hasPermission()` observations only.
10. **M5?** Standard permission request and verified grant result only; no open or transfers.
11. **M6?** AOA query/identification/start and re-enumeration only—but **not ready for execution** until stock reaction is characterized.
12. **First ownership conflict?** Honda can already open/query/switch the original phone while our app observes it. Later, stock AA may own the accessory interface before our non-forcing claim. The first conflict can therefore precede bulk transport.

`claimInterface(..., true)` is not an acceptable competition strategy. It may detach a kernel driver and is not a safe guarantee of taking ownership from another application.

**A critical limit on M6:** our app can avoid starting GAL, but stock Honda AA may start GAL in response to the same re-enumeration. “Our harness performs AOA only” cannot yet mean “the vehicle performs no Android Auto activity.”

## 3. Clean receiver architecture and minimum protocol

### Answers 13–15

13. **Can a clean receiver avoid Honda GAL entirely?** Architecturally yes. Ordinary USB/AOA supplies transport; open-derived code can implement framing, authentication and channels. Success on this head unit remains unproved.
14. **Minimum before video?** USB access, accessory transport, version exchange, TLS/authentication, service discovery, channel opening, video setup/start/focus, media framing, codec configuration, access-unit delivery and acknowledgments.
15. **What can initially be omitted?** OEM navigation, Bluetooth management, calls, microphone, steering controls, HUD and Honda vehicle integration. Do not advertise unsupported services. Pure video-only discovery is a hypothesis, not established phone compatibility; a small truthful input/sensor/control implementation may be needed.

Recommended boundaries:

[Code block omitted from public report; see authored source where available.]

Each stage should require an explicit command. Constructing an object must not automatically advance to the next stage.

Important protocol details confirmed in the Open Headunit reference:

- Envelope: channel byte, flags byte, two-byte big-endian body length.
- FIRST/LAST fragmentation bits are independent of CONTROL/ENCRYPTED bits.
- A first fragmented frame carries an additional four-byte total length.
- USB transfer boundaries are not protocol-message boundaries.
- Continuations do not repeat the message type.
- Video delivery needs bounded buffering and correct acknowledgments.
- Channel 0 is control; other service IDs should match our advertised discovery response, not be assumed universal.

The strongest reusable Android reference is **Open Headunit**, with AASDK as an independent transport/protocol reference and Open Android Auto for schemas/captures. LibAuto remains useful design evidence, but its current `minSdk=26` prevents direct API22 deployment.

### Credentials remain a separate issue

Honda Java explicitly supplies credentials through `nativeSetCreds` after loading and native initialization. The existing provider is static; no package-signature, UID or hardware lookup was identified there.

That establishes technical separation between:

1. APK signing;
2. Honda update signing;
3. Android Auto protocol authentication.

It does **not** establish phone acceptance of a new implementation. M3/M4/M5/decoder harnesses need no protocol credentials and should contain none.

## 4. Decoder, fullscreen negotiation and input

### Answers 16–20

16. **Safest first video configuration?** For independent decoder validation, begin with a simple `1280×720 @ 30` H.264 stream, then the known stock-sized case. For the first fullscreen experiment, prefer `1920×720 @ 30`, with 229 dpi when AA negotiation is eventually involved.
17. **Is 30 fps preferable initially?** Yes. It creates decoder headroom while preserving the geometry question. This is a proposed new experimental configuration; Candidate A/B remain unchanged.
18. **Throughput result?** See below.
19. **Can the decoder be tested independently?** Yes, using packaged MP4/H.264 through MediaExtractor → MediaCodec → Surface, with no AA stack.
20. **Built?** No. No streams were generated either.

The saved [codec declaration](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/logs/2026-10-22-investigation/media-codecs.xml) gives H.264 maximum `1920×1088`, 16×16 blocks and **489,600 blocks/second**.

| Encoded dimensions | FPS | Macroblocks/frame | Macroblocks/second |
|---|---:|---:|---:|
| 1280×688 | 60 | 3,440 | 206,400 |
| 1280×720 | 60 | 3,600 | 216,000 |
| 1920×720 | 30 | 5,400 | 162,000 |
| 1920×720 | 60 | 5,400 | 324,000 |
| 1920×1080 | 30 | 8,160 | 244,800 |
| 1920×1080 | 60 | 8,160 | **489,600** |

These are declaration comparisons, not measured performance guarantees. A cropped 1080 stream still has 1080-class decoding cost if its coded raster remains 1080.

### Decoder harness design

Package: `com.rdx.fullscreen.decodertest`

Classes:

- `DecoderTestActivity`: explicit selection/start/exit; synthetic grid first.
- `ClipCatalog`: fixed bundled assets only.
- `DecodeWorker`: MediaExtractor and named TI MediaCodec, one clip per run.
- `DecodeMetrics`: timestamps, queue/output counts, format changes and errors.
- `GridView`: visible resolution/frame labels and coordinate reference.

Requirements:

- No permissions, USB, GAL, audio, network or background startup.
- Explicit `OMX.TI.DUCATI1.VIDEO.DECODER`; no silent software fallback.
- Preserve extractor CSD; record SPS profile/level/coded dimensions/cropping.
- Record `INFO_OUTPUT_FORMAT_CHANGED`, crop fields, stride/slice-height where exposed.
- Bound run duration and queue waits; release only our codec.
- Stop if allocation/configuration fails.
- A decoder crash could affect shared media services; uninstall is not proof that a wedged media service recovered.

API22 lacks the newer frame-render callback. Output-buffer counts must be described as **decoded/released counts**, not proven displayed-frame counts. Surface rendering is supported by the public MediaCodec API. [MediaCodec reference](https://developer.android.com/reference/android/media/MediaCodec)

Future stream-generation template—not executed:

[Code block omitted from public report; see authored source where available.]

Generate each requested raster/rate separately, inspect with `ffprobe`, and hash it before packaging. FFmpeg was not found on the current command path.

### Answers 21–24: margins and touch

21. **What does the margin model establish?** `1920×1080` with total vertical margin `360` represents a `1920×720` active region. It does not establish actual H.264 SPS dimensions.
22. **Unknown crop placement?** Centered versus top-left content remains unresolved for our phone/session.
23. **Unknown touch relationship?** Whether input uses active-content coordinates, nominal raster coordinates or another advertised input geometry remains unresolved.
24. **What should TTI logs contain?** Raw event source/device, action/actionIndex, pointer IDs/count, coordinates, ranges, tool type, buttons, timestamps, view location, Surface size, renderer transform, advertised input geometry and outgoing protocol coordinates.

The conflicting evidence is concrete:

- Open Android Auto records `codec=800×480`, `display=800×410`, `dispTop=35`: centered placement for that capture.
- Open Headunit’s touch mapper explicitly uses active coordinates without a half-margin offset and reports that adding one displaced touches.

These may involve different coordinate spaces or implementations. Neither justifies a universal `+180` offset.

Honda advertises touchpad dimensions **1325×720**, physical **60×40 mm**, with navigation and absolute UI flags. Those values are independent of video negotiation.

A further check corrected a decompiler ambiguity: the renderer’s scaling is floating-point division, confirmed in [ProjectionRenderer.smali](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current-smali-full/com/honda/androidauto/projection/sink/video/ProjectionRenderer.smali:1034). The hover/touchpad path and transformed touchscreen-style path are different; do not apply one blanket transformation to both.

Preserve 229 dpi for the initial geometry experiment. Moving to 240 increases advertised density by about 4.8% and reduces logical canvas dimensions by about 4.6%; it is a separate UI-scale variable.

## 5. Lifecycle behavior and future test boundaries

### Answers 25–27

25. **Does a headless Service avoid the known preference side effect?** **Yes, for the identified Activity-resume path, with high static confidence.** No Activity resumes, so `AcuraLifecycleCallbacks.onActivityResumed()` does not emit that broadcast.
26. **What will stock AA do when a phone attaches?** It can inspect the phone, query AOA, apply per-device policy, switch modes, open transport and start protocol independently.
27. **Must we suppress stock AA first?** **No for passive observation.** Observe normal competition before considering any suppression. No suppression method is recommended here.

The application-level fixup still runs in a Service process. The examined code registers lifecycle callbacks and checks whether the package exposes a MediaBrowserService; it does not itself send `APP_LAUNCHED`.

Therefore M3/M4 packages should contain:

- no Activity;
- no MediaBrowserService;
- no attach/boot receiver;
- no Honda integration classes.

**M5 is different:** its permission request launches a SystemUI Activity. Even though our harness is headless, the permission UI could participate in Honda foreground behavior. Monitor this rather than promising no preference effects.

The broader fixup framework also has media/call-related lifecycle behavior for recognized audio apps. A minimal non-media Service avoids those identified registrations. Searches of available decompiled Java found no additional `APP_LAUNCHED` receiver beyond stock AA, but that is not exhaustive proof covering every binary.

Future preservation reports must separately state:

- APK/path/version/signer/package identity;
- process/UI state;
- observed preference setter calls;
- actual preference values, **only if legitimately readable**.

A setter log does not prove the old value differed. No preference restoration is proposed.

## 6. Implementation-ready M4 harness

**This is source for later saving/building, not a built artifact.**

Proposed layout:

[Code block omitted from public report; see authored source where available.]

Manifest:

[Code block omitted from public report; see authored source where available.]

No permissions or intent filters are required for this bounded inventory service.

[Code block omitted from public report; see authored source where available.]

This uses enumeration and permission inspection only. Android distinguishes those from opening the device and requesting permission. [UsbManager reference](https://developer.android.com/reference/android/hardware/usb/UsbManager)

### Build instructions for a writable session

Adapt the already-proven [synthetic build pipeline](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/scripts/Build-RdxLive02Synthetic.ps1) into a **new** build script:

1. Compile this source against the installed Android jar, Java 7 output.
2. D8 with `--min-api 21`.
3. Package the new manifest and DEX.
4. **Do not copy the old native-library packaging step.**
5. Zipalign.
6. Sign with the existing local development key, enabling v1 signatures.
7. Verify signatures for API22.
8. Inspect final manifest and DEX for absence of native loading, `openDevice`, `requestPermission`, `claimInterface`, transfers, MediaCodec and Activity components.
9. Save source/APK hashes and validation output.

The source above has not been compiled or runtime-tested.

For a disabled M3 skeleton, use a separate package and Service with:

[Code block omitted from public report; see authored source where available.]

Do not package credentials or receiver-session classes.

## 7. Future bounded tests and cleanup

### M4 — preferred next live test

**Purpose:** prove ordinary-app USB visibility and observe stock behavior without taking ownership.

1. Baseline with phone disconnected.
2. Install only `com.rdx.fullscreen.usbprobe`.
3. Start the headless inventory service; confirm no Activity or `APP_LAUNCHED` from our package.
4. Under separate authorization, attach the phone during a bounded observation window.
5. Record inventory, stock logs and USB state.
6. Stop after visibility/competition evidence.
7. Disconnect the phone normally; uninstall our package.
8. Verify package/process removal and factory package identity.

**Important:** phone attachment may trigger normal factory AA behavior and private-state updates. M4 promises no transport actions by our harness, not zero factory behavior.

Future commands—**not executed**:

[Code block omitted from public report; see authored source where available.]

Use explicit serial selection and stop if installation fails. A cached process after `stopservice` is not necessarily a failure; verify removal after uninstall.

### M5 — permission only

- Require a selected device from M4.
- Check `hasPermission`.
- Issue one standard permission request.
- Use an explicit PendingIntent callback and verify the selected device and actual permission map afterward.
- No `openDevice`.
- No default-app selection or “always use” change.
- Bound the wait; denial/detach/timeout ends the test.
- Monitor SystemUI and Honda lifecycle effects.
- Detachment clears the device permission entry in this framework.

### M6 — AOA only, still gated

- Require M5 and a credible stock-competition plan.
- Endpoint-zero control transfers do not inherently require claiming the data interface.
- Query protocol, send six bounded NUL-terminated strings, send START once.
- Close our handle, observe detach/attach, record new VID/PID, then stop.
- No post-switch open, claim, TLS or channels.
- Do not assume the old permission survives re-enumeration.
- Uninstall does not reverse the phone’s USB mode; normal physical disconnect is part of rollback.
- **Do not run while the requirement is that no stock GAL/projection startup may occur.**

### Separate fullscreen grid test

Use `com.rdx.fullscreen.gridtest`, no USB/native/media dependencies. Render grid lines and labels at `0`, `100`…`1900`, with explicit boundaries at `1338`, `1339`, and `1919`.

Measure stock geometry first. Any later overscan test must record and restore the **exact prior overscan**, not assume zero. App uninstall does not undo overscan. This remains separate from AA and decoder tests.

### Capture tooling

The existing [Capture-RdxReadOnly.ps1](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/scripts/Capture-RdxReadOnly.ps1) should **not be reused unchanged**: it contains historical PID assumptions, JDWP and updater-oriented captures outside the present scope.

A new capture tool should use a fixed read-only allowlist:

| Capture | Commands/data |
|---|---|
| Identity | `devices`, selected build properties, `/proc/uptime` |
| Packages | `pm path`, targeted `dumpsys package` |
| Processes | `ps`, supported SELinux-context variant |
| Display | `dumpsys window`, `dumpsys display` |
| Activities | `dumpsys activity activities` |
| USB | `dumpsys usb` |
| Logs | `logcat -d -v threadtime`, without clearing buffers |
| Own process | Dynamically resolved PID, readable `/proc/PID/status`, maps and context |

Save timestamped stdout, stderr, command arguments, exit code and timeout status under `analysis/live-logs/`. Missing commands or denied reads are evidence, not reasons to escalate. Never hardcode a previous PID or attempt private preference access through a privileged workaround.

## 8. Final decisions and artifact status

### Answers 28–31

28. **Which APKs/scripts are ready?** The preserved synthetic revision and historical tooling remain. **No new M3, M4, decoder or grid APK was built in this read-only pass.** M4 source and build requirements are provided above; other harnesses have implementation plans.
29. **Exact next live test?** **Headless M4 passive inventory**, beginning phone-disconnected, then a separately authorized phone-attachment observation. Independent decoder testing is a separate useful branch.
30. **What should not be tested yet?** Enabled M3, AOA conversion, interface claiming, GAL/TLS negotiation, simultaneous receiver competition, combined overscan/projection experiments, or any stock-package/root/update modification.
31. **Which model next?** **GPT-6.1 Sol High** for implementing, building and validating the bounded probes. Use **GPT-6 Astra Medium** if returning to exhaustive native call-graph closure or difficult protocol/crop contradictions. This is a task-fit recommendation, not a measured comparison on this repository; official guidance positions Sol for intelligence/cost balance and Astra for the most demanding reasoning. [OpenAI model guidance](https://developers.openai.com/api/docs/models)

### Architecture decision

| Consideration | Honda-native route | Clean ordinary receiver |
|---|---|---|
| Protocol implementation effort | Lower if compatibility succeeds | Higher, with reusable open code |
| Native-load uncertainty | Still present | Avoids proprietary receiver library |
| USB ownership problem | Still present | Still present |
| OEM integration dependencies | Must remove or isolate | Can omit |
| API22 feasibility | Original binary is appropriate ABI/API | Android reference supports older APIs; extracted build needs validation |
| Fullscreen control | Existing native schema | Explicit discovery/renderer control |
| Lifecycle effects | Headless work can avoid known callback | Same |
| Reversibility | Disposable package, but opaque native teardown | Disposable package with controlled ownership/teardown |
| Maintainability | Proprietary binary dependence | Better source-level observability |
| Recommendation | Optional fallback | **Primary path** |

**The first unresolved boundary worth measuring is ordinary-app USB visibility and stock ownership timing—not root, signing, or Honda-native loading.**

## Roadmap

| State | Work |
|---|---|
| **DONE** | Historical M0–M2; three receiver initializer identities; substantial STLport tracing; UID1000 USB permission bypass identified; stock auto-start preference distinguished from transport ownership; decoder throughput calculated; touch scaling checked against smali |
| **NOW** | Save this analysis when workspace writes are available; build/validate passive headless M4 and independent decoder/grid harnesses; leave M3 disabled |
| **NEXT** | Bounded M4 observation, then permission-only M5 if visibility succeeds; separately test packaged H.264 without a phone |
| **LATER** | Resolve stock USB arbitration; gated AOA/transport/TLS/video stages; measure SPS/crop; fullscreen Surface experiment; only then TTI mapping |

**No new vehicle milestone was demonstrated during this offline session. M0–M2 remain the verified live result.**