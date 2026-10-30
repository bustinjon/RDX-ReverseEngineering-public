# Clean receiver architecture V2 — 2026-10-23

Primary direction remains an ordinary separately signed receiver; Honda-native reuse is optional. M3 is deferred and outside the critical path. No full receiver/protocol startup was implemented in this build session.

| Module | Explicit operation | Must not do during construction |
|---|---|---|
| AndroidUsbInventory | Snapshot descriptors/permission | Request/open/claim |
| UsbPermissionController | One chosen-device request | Set default or begin transport |
| AoaNegotiator | One gated conversion | Claim data/TLS/reconnect |
| AndroidUsbTransport | Authorized open and non-forcing ownership attempt | AOA or automatic protocol |
| AaFramer | Bounded frame parsing/reassembly | Access USB |
| AaTlsSession | Explicit handshake over supplied transport | Discovery/video |
| AaControl / ServiceDiscovery | Explicit negotiated service map | Advertise unsupported services |
| VideoChannel | Setup/start/acks/access units | Allocate decoder before command |
| AndroidMediaCodecDecoder | Named codec configure/decode | Silent software fallback |
| SurfaceRenderer | Measured viewport/crop | System display mutations |
| Later Input/Audio/Sensor | Separately staged | Honda integration by default |

Use observable states and explicit permission/identity/ownership results, not cascading constructors. Every resource owner implements cancellation/close with a bounded policy; caller decides whether progression is authorized. A previous stage succeeding never automatically starts the next stage.

Minimum receiver path: USB/AOA/ownership -> version exchange -> TLS/auth -> service discovery -> channel opening/video setup/start/focus -> codec CSD/access units and acknowledgments -> MediaCodec/Surface. Pure video-only discovery may be rejected; minimally truthful input/driving/night/control service support may be needed. Do not claim phone compatibility until observed. Calls/mic/BT/OEM navigation/steering/HUD can initially be omitted rather than falsely advertised.

Envelope is channel u8, flags u8, body length BE16. FIRST/LAST independent of CONTROL/ENCRYPTED. First fragment can add BE32 total length; continuation need not repeat type/timestamp. USB reads are not message boundaries. Bound both individual frames and reconstructed messages; handle short reads/writes without unbounded retry. Control is channel0; other IDs follow the actual advertised map. No parser here receives vehicle data yet.

APK signing, Honda update signing and AA authentication remain separate trust boundaries. Honda Java calls nativeSetCreds after native initialization; static provider has no identified package/UID/hardware lookup. That does not prove phone acceptance. No credentials or proprietary receiver library belong in M4/M5/grid/decoder harnesses.

Open Headunit (local pinned e9377ff) supplies the strongest older-Android behavior reference: device identity/permission, endpoints, buffered transfers, bounded framing, TLS, discovery, MediaCodec and viewport patterns. AASDK is an independent protocol/USB reference; Open Android Auto supplies schemas/captures. LibAuto'smin26 prevents directAPI22 use. Open Headunit's checked-in license is AGPLv3: document provenance and obligations before copying implementation. Current new harnesses are locally authored public-API code; no upstream implementation files were copied. No force-claim/reset/reconnect, root/Shizuku, OEM-app control or attach-autostart reuse.

Conservative future video first; then active1920x720/30fps/229dpi via nominal1080 mode/margins0,360. Preserve historical Candidate A/B. Encoded SPS/crop placement and input geometry remain unmeasured; no180px input offset. Host appSurface1339 and physical1920 are separate from protocol negotiation. Overscan remains a separately authorized display-state experiment. TTI1325x720/60x40mm/navigation+absolute stays later, with raw/transformed/outgoing coordinate logging.

## 2026-10-23 clips and clean-foundation continuation

A compileable Java7/API22 library foundation now exists under clean-receiver/ (README and latest-build.txt). No manifest/APK/native library/credentials. Real pure logic: frame parser/writer/post-TLS bounded reassembly, immutable capability/input/channel models and disabled AOA request metadata. Contracts/stubs: permission/USB transport/TLS/control/video decoder/Surface adapter. Inventory is explicit public getDeviceList/hasPermission only. All supplied constructors store local fields/containers; no external calls or resource startup. Android transport/AOA/TLS/control/video execution throws, even if explicitly invoked in this revision.

67 synthetic host checks PASS, including malformed/oversize/out-of-order/partial/empty-tail/channel/memory limits, serialization and non-default fullscreen arithmetic with placement UNSPECIFIED. D8 min22 DEX reference audit excludes USB open/request/claim/transfer, sockets/TLS, MediaCodec, shell/native loading. This is not a complete receiver or tested phone stack. TLS streaming-to-AAP metadata association, protobuf wire serialization, service startup/acks and actual transport remain future work. Source independently authored from protocol behavior; no upstream AGPL/GPL implementation copied. Clean ordinary-app strategy remains preferred; M3 still deferred.

## 2026-10-23 pure protocol-core continuation

The missing protobuf/state-model pieces above are now implemented as local byte-array machinery.31 source modules compile;261 deterministic/23059 property assertions PASS. [Results](clean-receiver/PROTOCOL-CORE-RESULTS-20261023.md), [inventory](clean-receiver/PROTOCOL-MESSAGE-INVENTORY.md), [bounds](clean-receiver/BOUNDS-AND-TESTS.md). No transport/TLS/media startup was enabled. HeadUnitProtocolCore is explicitly an offline plaintext conversation model, not the transport-facing receiver. Fake phone/TLS implementations are host-test-only and excluded from library JAR/DEX.

Layer boundaries remain explicit: frame parsing → future real TLS streaming adapter → bounded decoded-message assembly → typed control/discovery codecs → registry/state model → future media message parser → VideoSink → separately implemented decoder. Unknown encrypted bytes cannot bypass decryption. Constructors only initialize local fields/models; explicit callbacks use supplied fake sinks during host tests. Registry distinguishes service/channel identities but real remapping is not inferred from synthetic tests. Conservative advertisement default and independent input geometry are preserved. Next live is still M4 ONLY; M3 deferred.
