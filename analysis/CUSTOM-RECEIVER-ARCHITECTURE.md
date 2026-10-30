> Current2026-10-25 status: separate clean receiver remains preferred; factory Honda untouched. M4PASS, originalM5 timing-INCONCLUSIVE, frozenM5retry nextLIVE ONLY, M6disabled. [Freeze/index](parallel-aa-receiver/OFFLINE-FOUNDATION-FREEZE.md) supersedes dated module/TLS-readiness statements below.

# Separate receiver architecture and offline prototype

Target:2021 RDX D.1.6.4 / API22 / ARMv7. Package `com.rdx.fullscreen.projection`, independent development signer, ordinary app UID. Factory AA and Candidate A/B remain unchanged. No prototype was installed/launched. No newer-unit reference or network dependency was used.

## Strategy A: clone Honda's application

A package-name/signing edit by itself is insufficient. Removing shared UID loses its automatic USB grants, shared-user permission union and system_app context. Many OEM integrations then lack permissions; fixed global actions/components can collide or continue targeting stock. This is not proof the projection core needs those privileges.

Required clone work would include: new manifest package/task affinity and own launcher identity; removal of android.uid.system and unavailable privileged permissions; explicit inventory of every exported action/receiver/provider/authority; preserving original resource IDs or correctly rebuilding all integer resource references; updating runtime package/component strings and own-data preferences; removing boot/USB auto-start and OEM-only callbacks; retaining required Java/JNI namespaces; replacing privileged Honda focus/vehicle/BT/startup/media functions with narrow test implementations. Uses-library declarations may make resources/APIs available, but do not grant their service permissions.

Existing fully qualified Java class names can technically remain under com.honda inside a differently named manifest package; that does not change hardcoded **application package** references. It is cleaner to avoid these application classes entirely. Protected permissions and missing framework/voice/media registrations are unnecessary failure surfaces for the first video test. The [dependency matrix](AA-PRIVILEGE-DEPENDENCY-MATRIX.md) separates them individually.

No renamed Honda APK was built. The offline prototype uses Strategy B/C below, without original Honda application DEX/resources/components.

## Strategy B: minimum independent receiver

[Code block omitted from public report; see authored source where available.]

The minimum new implementation preserves just the native-facing ABI and public SDK paths, not Honda's entire integration object graph. The small DEX includes inner UI/thread/listener helpers; its exact class count is recorded in the validation report. No com.honda application class, protobuf-generated catalog, Honda framework uses-library, service, provider or attach receiver is included.

Current source set:

- `com.rdx.fullscreen.projection.ReceiverActivity`: UI, Surface, manual stages, input/geometry logs, exit/background cleanup. Optional explicit launch extras `stage=inventory` and `stage=native` avoid making TTI necessary to reach diagnostics. Default launch does neither native nor USB setup.
- `ProjectionSession`: credential container read, native/session ownership, local video registration, USB reader/writer/ping, bounded shutdown and milestone logs.
- `UsbBulkTransport`: enumerated Google AOAP-only interface0, normal openDevice, claimInterface(false), buffered reads preserving USB packet tails, bounded timeouts, partial-write handling and release/close. No AOAP mode switch, reset, forced claim or daemon call.
- `VideoDecoder`: ordinary MediaCodec, TI component by name, configured coded raster, codec header, bounded queue, output-format/crop logging, frame acknowledgements and release. No audio, Honda focus or screenshot privilege.
- `com.google.android.projection.protocol.GalReceiver`/VideoSink and `common.BufferPool`: small independently written native-facing facades preserving required class names, native handle fields, callbacks and static buffer-pool descriptors.

This is a **staged research prototype**, not a complete supported receiver. The phone may require additional standard input/audio/service-discovery endpoints. The original native/Java stack permits registering services individually; the phone's acceptance of this video-only catalog remains untested. Those endpoints could be added without automatically importing Honda integration, but are not claimed implemented here.

## Candidate A configuration

| Field | Primary index0 | Fallback index1 |
| --- | --- | --- |
| Logical active size | 1920x720 | 800x430 |
| Density / fps | 229dpi /60fps | 143dpi /60fps |
| Codec resolution enum | VIDEO_1920x1080, numeric3 | VIDEO_800x480, numeric1 |
| Total width/height margins | 0 /360 | 0 /50 |
| Codec | H264 baseline, numeric3 | Same video service |
| Other fields | Real DPI from own DisplayMetrics; decoder depth0; pixelAspectRatioE4=10000 | Same field construction |

These arguments reproduce stock VideoSink.nearestVideoConfiguration/addSupportedConfiguration for Candidate A; Candidate B is not used. Local native configuration is **not** phone advertisement/selection. L5 requires an actual sourceVideoConfigCallback. The360px margin is a protocol total; no arbitrary180px per-side crop is assumed.

## Unchanged native library: portability models

| Model | Assessment |
| --- | --- |
| A. Package copy in own APK | Chosen. Fresh current libautoreceiver_jni.so is copied byte-for-byte to lib/armeabi-v7a. No native patch/re-sign assumption. New APK signer signs this package only. |
| B. Load installed system copy | Plausible on API22: current file is world-readable system_file, required32-bit system dependencies are present, and this runtime predates app linker namespaces. Exact effective mapping policy is not runtime-proved. Direct load would depend on that installed file remaining compatible. Not needed by this prototype. |
| C. Reimplement Java-facing subset, reuse native engine | Chosen together with A. Preserve exported JNI class/method/field/callback ABI and replace Honda application orchestration with ordinary SDK code. This avoids needing Honda resources/protected services merely to initialize GAL. |

Current native library SHA256 `031797DD4B0AECCA007A3AD7AF31C365BA3D47BEBDA8C94BFF13C5289F464C50`, size1918948. DT_NEEDED: libc.so, liblog.so, libm.so, libstdc++.so, libstlport.so, libdl.so. The STL dependencies exist in the saved/current platform baseline; actual loading in our app remains L2, not a host claim.

There are119 exported Java_* entrypoints and no exported JNI_OnLoad in the examined symbol tables. Relevant names are `Java_com_google_android_projection_protocol_*`, not the manifest package. Original class names **must** be preserved for these native methods; the manifest owner/signing certificate need not have that Java namespace. No mandatory registration of every Honda application class was found. BufferPool and GalReceiver$ConnectedDevice are explicit FindClass-style references and are retained.

Selected normalized Thumb addresses:

| Native function | Address / role |
| --- | --- |
| GalReceiver.nativeInit | 0xBCD50,392 bytes: constructs synchronization/SSL/receiver/controller callbacks and stores native handle. |
| GalReceiver.nativeSetCreds | 0xBCF20,220 bytes: converts Java strings, obtains receiver, calls Controller.setClientCreds. |
| GalReceiver.nativeStart | 0xBC898; local protocol start. Framing queue/dequeue at0xBC8FC/0xBC94C. |
| VideoSink.nativeInit | 0xC3FC8,316 bytes: initializes video service bound to receiver. |
| VideoSink.nativeAddSupportedConfiguration | 0xC3F62: adds native protocol configuration; codec setter0xC3FBA. |
| SslWrapper.init | Symbolized calls at0xCB98A onward read certificates/private key from memory BIOs, use SSL_CTX_use_certificate/use_PrivateKey and SSL_check_private_key. |

[Native summary](parallel-aa-receiver/evidence/receiver-native-summary.json), [direct-call evidence](parallel-aa-receiver/evidence/receiver.direct-calls.json), [ABI validation](parallel-aa-receiver/evidence/prototype-static-validation.json). Direct-call survey is not a complete control-flow/indirect-call proof. getuid appears in RAND_poll entropy collection; it must not be misrepresented as a Honda UID1000 gate. OpenSSL's EGD helper also contains socket/connect calls; these do not turn the protected GAL reset socket into the data path.

Host checks compare22 used native entrypoint descriptors,19 callback descriptors,16 native-relevant fields and the BufferPool API against original DEX. This is strong ABI preparation, **not** proof of dynamic JNI success, native lifecycle/threading or phone compatibility.

## Protocol authentication and three separate trust boundaries

1. **APK signing:** new local development RSA certificate, ordinary package identity. It is not Windriver-signed and does not request android.uid.system.
2. **Honda update authentication:** OTA delivery root/catalog/official signing remains a separate mechanism. No RedBend/updater is involved in this app's build or proposed normal install.
3. **GAL/Android Auto TLS credentials:** stock CertKeys→PlatformCertKeysImpl supplies software constants decoded from Base64. Original Java passes root/client/private-key strings into GalReceiver.nativeSetCreds. Native memory-BIO/SSL initialization consumes them. No head-unit hardware-backed key retrieval, APK-signature lookup, UID-derived key or VIN-derived secret is present in this provider/call path.

Protocol public certificate fingerprints: root DER SHA256 `49E52EFC13AD2ED09F204C3B10698BD84BB7105F510558AA14B8119A5C4AD17F` (Google Automotive Link); client DER SHA256 `AD978F651A92A1E7C18AC72C7497A5272D8D942B97DCD6053228F63EF4660022` (Honda). The local build verified client private-key/public-certificate match without reporting key contents. [Metadata only](parallel-aa-receiver/evidence/protocol-credential-metadata.json).

The prototype includes the existing protocol material in a local binary asset solely to test this same head-unit stack. **The APK/asset contain sensitive original protocol credentials: keep them local; do not publish them.** Reports/logs do not include private-key contents. This is technically separate from signing our APK and does not establish permission to redistribute Honda/Google software or that the phone accepts our changed catalog/identity. CarInfo uses an empty vehicleId and experimental labels; no VIN/hardware identity was read or altered for this prototype.

## Decoder and renderer

Stock ProjectionRenderer calls MediaCodec.createDecoderByType("video/avc"), configure(Surface), start, input buffers and releaseOutputBuffer(render=true). An ordinary app can use these public APIs without MANAGE_USB, READ_FRAME_BUFFER or MEDIA_CONTENT_CONTROL. The codec runs through the media service, which owns hardware access; our app does not open Ducati hardware nodes.

Saved codec XML advertises OMX.TI.DUCATI1.VIDEO.DECODER, AVC up to1920x1088,16x16 blocks and489600 blocks/sec. A1920x1080 picture uses120×68 macroblocks; at60fps this reaches489600. This makes Candidate A structurally within the declared envelope, **at its limit**, not demonstrated playback or a guaranteed available simultaneous decoder instance.

The prototype offers separate enumeration and allocate/release controls before configuration/streaming. Video configuration uses the protocol coded raster; actual H264 SPS/output crop remains authoritative. The decoder logs format/crop changes and the TextureView preserves the observed content aspect ratio. It does not stretch a narrow stream or force a guessed crop. Unexpected black borders/crop or capacity/resource errors are findings, not success. Stock decoder arbitration remains unresolved while it is active.

## Window geometry and input are separate

Expected stock app region is1339x720 from prior WMS observations. Negative right overscan historically exposed1920x720 to stock AA. WMS display overscan is per-display/global, with no discovered normal-app UID exclusion; therefore a normal fullscreen Activity is expected to benefit too, **but its actual Surface has not been observed**. No UI flags alone promise removal of Honda's reserved region or overlay occlusion.

**Overscan is reversible persistent state:** WMS.setOverscanLocked calls DisplaySettings.writeSettingsLocked, backed by `/data/system/display_settings.xml`. Uninstalling the app does not undo it; reboot is not the restore procedure. Optional overscan is outside the first test and has its own baseline/rollback in the [live-test design](PARALLEL-AA-FIRST-LIVE-TEST.md).

Normal Activity MotionEvent/hover/generic-motion/key delivery does not inherently require system UID. Actual TTI routing and touchpad-as-pointer/rotary sources must be observed later. Stock handles local View events and generic axes17/18, then sends protocol InputSource events; its1325x720 touchpad registration is an independent assumption. The prototype only logs these own-window events and forwards none to the phone. No TouchBridge service, event injection, steering-wheel or vehicle-state integration is required for L1/L2. Add ordinary InputSource translation only after video; do not make corrected TTI a prerequisite.

## Built artifacts and limits

[Prototype directory](parallel-aa-receiver/README.md), [build report](parallel-aa-receiver/build/build-report.json), [API22 signing verification](parallel-aa-receiver/build/signature-verification.txt). Build is offline using local Java17/SDK32 tools, public compileSDK33, source/target Java7, minSDK21/targetSDK22 and DEX035. Source APIs used are available on API21/22; runtime behavior is not emulated by compiling against33. No Gradle/network download required.

Highest supported **host** status is compile/package/signature/descriptor validation. Every vehicle runtime level remains NOT RUN. Prototype constraints include AOAP already required, unresolved stock ownership, video-only service catalog, untested native teardown, no audio/input/vehicle integration, possible MediaCodec resource/crop differences, and no claim of production suitability. L1 first, then explicit native-only L2, before any separately approved phone test.
