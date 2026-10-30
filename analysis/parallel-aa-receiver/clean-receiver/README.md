> CURRENT M6 OFFLINE 2026-10-25: receiver remains57 modules, original source/tests/DEX unchanged; fresh full regression110521checks/8235885properties PASS (certificate-carrier count variation documented). Separate [M6 package](../M6-AOA-FROZEN.md):9modules/392checks/9304615properties/50000sequences, permanently disabled in this frozen release. M5 permission does not transfer to M6. API22 runtime remainsD;166receiver/220qualifier/137M6 refs resolve statically, Java7/D8min22 PASS. Next LIVE M5 RETRY ONLY;M7 NOT AUTHORIZED. [Freeze](../OFFLINE-FOUNDATION-FREEZE.md), [index](../INDEX.md). Earlier banners are dated snapshots.

> CURRENT 2026-10-24 API22 qualification: **RUNTIME TEST UNAVAILABLE; STATIC EVIDENCE ONLY.** No local emulator/image/AVD exists in inventoried locations.57 production modules unchanged;110504 deterministic /7425807 property assertions PASS includes22 new static-model checks and288625 model assertions/10000 sequences, **not Android runtime tests**.120 fixtures; Java7/D8min22/166 external API22 refs PASS; DEX unchanged. Saved close/output and peer-close concerns remain unqualified; foundation NOT FINALIZED. [Qualification](API22-TLS-RUNTIME-QUALIFICATION.md), [differential](API22-PROVIDER-DIFFERENTIAL.md), [inventory](API22-RUNTIME-INVENTORY.md), [status](OFFLINE-FOUNDATION-STATUS.md). Next LIVE **M5 RETRY ONLY**;M6disabled. All earlier banners below are chronology.
> CURRENT 2026-10-24 REAL host-memory TLS: **57 modules,110,478 deterministic checks,7,137,182 property assertions PASS**;10,000 new TLS mechanics +10,000 combined cases;120 independent fixtures. SunJSSE TLS1.2 mutual disposable-test trust; exact AA/media recovery; fake decoder only. API22 method surface PASS, provider runtime UNTESTED. [Report](OFFLINE-REAL-TLS-LOOPBACK.md), [Java conformance](JAVA-TLS-CONFORMANCE.md), [backend decision](TLS-BACKEND-SELECTION.md). Next LIVE=M5 RETRY ONLY;M6disabled. Earlier banners are chronology.
> CURRENT 2026-10-24 secure BODY adapter: **53 modules,72,211 deterministic checks,7,077,158 property assertions PASS**;112,500 randomized cases total;115 fixtures/52 transcripts. Fake transformation only; furthest ABSTRACT_INPUT_ACCEPTED; no real TLS/crypto/phone/decoder/display claim. Next LIVE=M5 RETRY ONLY;M6disabled. [Implementation](OFFLINE-TLS-BODY-ADAPTER-IMPLEMENTATION.md). Earlier banners below are preserved history.
> CURRENT 2026-10-23 offline VIDEO data plane: **45modules,66,293deterministic checks,6,791,914property assertions PASS**;82,500random cases;94fixtures/46transcripts. Furthest HOST state ABSTRACT_INPUT_ACCEPTED; no real AA/decoder/display pass. M4PASS;frozenM5retry nextLIVE only;M6disabled. [Full result](OFFLINE-M7-VIDEO-DATA-PLANE.md), [state guarantees](STATE-GUARANTEES.md), [data coverage](VIDEO-DATA-COVERAGE.csv). All earlier banners below are chronological history.
> CURRENT 2026-10-23 Honda media implementation: **39 modules,612 deterministic checks,3,956,937 property assertions PASS**;52,500 randomized cases total. Explicit Honda profile reaches MEDIA_CONFIGURATION_SELECTED, never MEDIA_RUNNING. M4 PASS; frozen M5 retry READY/next LIVE; M6 disabled. [Implementation and validation](OFFLINE-M7-MEDIA-CONFIG-IMPLEMENTATION.md). Earlier counts/UNKNOWN setup findings below are chronological history.
> CURRENT STATUS — OFFLINE M7 continuation: 36 modules,475 deterministic checks,1541937 property assertions PASS. M4 PASS; M5 original INCONCLUSIVE; frozen M5 retry READY and next LIVE milestone; M6 disabled. See OFFLINE-M7-STATE-MACHINE-VALIDATION.md. Earlier M4-pending counts/plans below are historical.

# Clean receiver foundation — API22, inert library revision

> The foundation description below is historical (67-check revision), preserved in protocol-core-session/foundation-before-protocol-core.zip. **Current protocol-core continuation:** see [PROTOCOL-CORE-RESULTS-20261023.md](PROTOCOL-CORE-RESULTS-20261023.md). It adds pure serialization/state/conversation logic,31 modules,261 deterministic checks and23059 property assertions. No I/O is enabled; this remains a library, not an APK.

Compileable Java7 library JAR plus D8 min-api22 DEX, **not an APK**. No manifest, Android component, credentials or native library. No installation/USB/AA/decoder execution. `latest-build.txt` identifies current build, `build-validation.json` records hashes/reference inventory;67 deterministic host checks PASS in test-results.txt.

## Implemented pure logic

- AaFrame/AaFrameWriter: immutable outer frame and bounded byte serialization.
- AaFrameParser: incremental4-byte envelope, optional BE32 first-fragment total, partial header/body handling, multiple frames per chunk, reserved flags and size/frame-count limits. TLS bodies remain opaque.
- AaMessageAssembler: per-channel bounded **post-decryption** reassembly, split message type/zero-or-one-byte tails, expected plaintext length, overlap/order/flag consistency checks, active-channel and aggregate reservation limits. Discard session/parser on malformed data; no automatic stream resynchronization.
- VideoConfig/InputConfig/AaServiceRegistry/AaServiceDiscovery: clean internal capability models. Conservative1280x688/229/60 is default; experimental nominal1920x1080/margins0,360/229/30 expresses active1920x720 with placement UNSPECIFIED. No crop/touch offset is inferred. No protobuf wire serialization yet.
- AoaRequestPlan/AoaNegotiator: pure metadata for51/52/53, request types, value/index, bounded UTF8 NUL strings. **Execution false at compile time; query/send/start always throw.**

## Scaffolded, intentionally disabled

UsbInventory contract and explicit AndroidUsbInventory.snapshot (getDeviceList/hasPermission only); UsbPermissionController contract; AndroidUsbTransport open/read/write disabled; AaTlsSession start disabled; AaControlChannel version exchange disabled; AaVideoChannel open disabled; AaVideoDecoder and SurfaceRenderer contracts only. No real transport/TLS/control/discovery serialization/video decoder/renderer implementation is claimed. The audited M5 remains a separate package; it is not wired into this library.

All supplied constructors perform only local field/container/model initialization. None starts threads, enumerates, opens USB, negotiates AOA/TLS, submits data or allocates a decoder. AndroidUsbInventory requires an explicitly supplied manager; snapshot is an explicit later call. Future adapters must retain this separation. ARMv7 compatibility is Java-bytecode portability; no native ARM build is needed yet. Android public methods used by the inventory adapter are available beforeAPI22; compiling with android-33.jar is not by itself an API22 runtime proof.

## Tests and limits

Host tests cover complete frames; one-byte chunks; partial headers/payloads; several frames in one buffer; integrated writer/parser/reassembly; interleaved channels; BE16/BE32 fields; split type; legal empty/one-byte continuation; encrypted-input refusal without TLS adapter; explicit post-TLS seam; oversized/reserved/malformed/overlapping/out-of-order/underflow/overflow; channel/memory/frame-per-feed bounds; EOF; immutability; model arithmetic/defaults; channel registry; NUL/UTF8/index/request metadata; disabled stages and constructor decoder-call count.

This is a strict initial parser based on pinned public reference behavior, not a proven full AA stack. TLS record boundaries can differ from AAP fragments: the future adapter must handle SSLEngine streaming before calling acceptDecoded with correctly associated metadata. Synthetic decrypted bytes are not a TLS implementation. No credentials/phone authentication has been tested. Limits are local safety policy (default test16KiB frame/64KiB message/8active channels/512KiB reservations); tune only from evidence. Audio/TTI/sensors remain later.

Host build/test: `scripts/Build-RdxCleanFoundation.ps1`. Tests use synthetic byte arrays on the development machine; DEX excludes test classes. Method audit confirms no USB open/request/claim/transfer, socket/TLS, MediaCodec, Runtime.exec, ProcessBuilder or native loading. Source independently authored from behavioral/schema references, not copied Open Headunit/AASDK implementation. Upstream AGPL/GPL licenses remain relevant if future code is copied; no protocol credentials are included.

Next offline work: strengthen parser with independently derived fixtures/property tests and add pure discovery protobuf encoding/control-message models. Do not enable ownership/AOA/TLS in response to a successful host build. Next live milestone remains M4 ONLY.

## 2026-10-23 protocol-core continuation (supersedes the missing-pieces list above)

Implemented: bounded protobuf wire subset; raw version/control codecs; video/input/discovery serialization and inspection; distinct service/channel mapping; explicit control state model; plaintext-only offline HeadUnitProtocolCore; disabled TLS boundary; video access-unit callback/backpressure contract. No real protocol startup, TLS, USB, AOA, decoder or threads. FakePhoneEndpoint/FakeTlsAdapter exist only in tests and are excluded from JAR/DEX.

Build/test: `scripts/Build-RdxCleanFoundation.ps1`; verify preservation/capture fixtures/pulled-platform method definitions with `scripts/Validate-RdxProtocolCore.ps1`. Both are local-only. `latest-build.txt` points to immutable timestamped JAR/DEX/test reports. Current detailed records:

* [Results and34 requested answers](PROTOCOL-CORE-RESULTS-20261023.md)
* [Message inventory](PROTOCOL-MESSAGE-INVENTORY.md)
* [Bounds/tests and interpretation](BOUNDS-AND-TESTS.md)
* [Reference conflicts/license provenance](PROVENANCE.md)
* [Independent fixture provenance](fixtures/PROVENANCE.md)

FPS wire mapping uses Honda/OHU/OAA60=1/30=2, explicitly conflicting with pinned AASDK. Channel-open priority uses Honda/OHU/OAA ZigZag, not pinned AASDK int32. HU AuthComplete direction is modeled explicitly. Conservative advertisement remains default; fullscreen opt-in leaves placement UNSPECIFIED. Synthetic arbitrary service/channel remapping is a lookup test, not a proved phone capability.

Installed compiler stubs are Android33 (no Android22 SDK installed); Java7/D8min22 build succeeds and all69 external DEX method references resolve to declared/inherited/native/abstract methods in the pulled D.1.6.4 platform or array intrinsics. This improves static API evidence but is not execution on Android. Existing disabled adapters remain disabled. Next live experiment stays **M4 ONLY**.

## 2026-10-23 independent-oracle validation continuation

Newest report: [OFFLINE-PROTOCOL-VALIDATION.md](OFFLINE-PROTOCOL-VALIDATION.md). The descriptions/counts above are historical. Current31 production modules pass **329 deterministic and43295 property assertions**. A separate host-only batch oracle agrees on5000 valid and2500 deliberately malformed randomized cases;28 versioned golden fixtures live under [test-fixtures/v1](test-fixtures/v1/README.md). All prior tests remain.

ProtoWire now retains exact supported-wire bytes, with encoded()/unknownFields(); DiscoveryCodec.Decoded.originalEncoding() retains nested unknowns for immutable inspection. Typed responses still emit approved known fields rather than echoing arbitrary unknown requests. [Field confidence](FIELD-CONFIDENCE.md) separates confirmed layouts, inferred behavior and unknown extensions.

Fresh builds have identical class/JAR-entry payloads and byte-identical DEX; normal JAR ZIP timestamps cause container hash differences, recorded without normalization. Java7/D8min22 and pulled-platform API checks PASS. No production module was added, no adapter enabled, no APK built/installed, no ADB/device I/O. All48 protected APKs unchanged. Next live stays **M4 ONLY**; no M7 runtime pass is implied.

Normal build remains `scripts/Build-RdxCleanFoundation.ps1`; it runs all three host suites and consumes the checked-in immutable fixture version. Session verification: `scripts/Validate-RdxProtocolOfflineSession.ps1`; active session evidence is identified by latest-host-validation-session.txt. The fixture authoring script refuses to overwrite v1 and is not part of automatic builds.

## 2026-10-23 explicit offline M7 session engine

[Final validation](OFFLINE-M7-STATE-MACHINE-VALIDATION.md), [state graph/confidence](SESSION-STATE-TRANSITIONS.md), [media evidence/conflicts](MEDIA-CONTROL-EVIDENCE.md), [14-column coverage matrix](MESSAGE-STATE-COVERAGE.csv), [independent fixture provenance](SESSION-FIXTURE-PROVENANCE.md).

New five production modules: SessionPolicy,SessionCatalog,SimulatedSessionEngine,MediaControlMessages,DecoderBoundary. All31 original production sources unchanged. Pure engine queues arrays only; injected monotonic clock, explicit synthetic timeouts, empty registry until discovery, known/unknown service separation, fail-closed malformed/state errors and explicit new-object reset. Constructor does not progress or send. Test-only InMemorySessionTransport supports chunking/delay/drop/duplicate/reorder/EOF, excluded from JAR/DEX.

Current36 modules/475 deterministic/1541937 property assertions;15000 new seeded24-event sequences (37500 total randomized iterations including prior suites),22 new independent session fixtures plus28 prior golden fixtures,18 saved transcripts. Both profiles stop at MEDIA_SETUP_PENDING/UNKNOWN_MEDIA_TRANSITION. No MEDIA_READY/RUNNING, decoder allocation or real TLS claim. Setup scalar and setup-response direction conflict across pinned AASDK/newer OAA; AV setup OK2 differs from control success0. No reply/progression guessed.

Build-RdxCleanFoundation.ps1 now runs all4 suites. Current validator is scripts/Validate-RdxM7Session.ps1. Older validators/reports remain historical subset records and should not be used as the M7 total-count/readiness authority. Two fresh final builds have identical DEX/classes/JAR-entry payloads and18 transcripts; ZIP container timestamps differ. SDK33 compile stubs/Java7/D8min22 with80 method refs verified in actual pulled API22 definitions. No real credentials, new runtime dependency or APK. All69 protected APKs and M4/M5 live reports unchanged; frozen M5 hash remainsA22E96490B9557AFF022893A8B8B7A08BB13CEC236E52704CDDAFA90A8EE8F40.

Next OFFLINE candidate: resolve existing local0x8000/0x8003 target-generation semantics/order before adding readiness. Next LIVE remains separately authorized M5 retry ONLY; M6 disabled, M3 deferred. No device/phone/USB/TLS/MediaCodec operation occurred.


## Explicit Honda media profile (host only)

Use `new SimulatedSessionEngine(clock,policy,catalog,true)` to select the Honda typed-media path. Existing constructor overloads preserve the prior inspection-only mode and unchanged regression suite. The parent lifetime/control graph remains11states; one HondaMediaFlow owns6media substates. Query `mediaState()` or `progression()` for media extent; parent `state()` stays MEDIA_SETUP_PENDING during the active media subflow. Constructors remain inert.

Explicit inbound codec3 Setup records onMediaSetup. Explicit `advertiseMediaConfig(...)` captures Config WAIT1 or READY2; no guessed production readiness trigger. Valid Start selects only advertised configuration indices and records onConfigurationSelected before onMediaStartObserved. Optional projected focus never becomes required. `accountMedia` is flow control only, including abstract input-failure accounting; no decoder/display measurement exists. No automatic Config/ACK/focus or live transport is enabled by construction.

New fixture set honda-media-v1 has20 independently handwritten vectors; old50 fixtures untouched. New suite HondaMediaTests has137deterministic checks plus2,415,000property assertions (15,000x20events,seed20353395894340919) and11transcripts. Current complete build: scripts/Build-RdxCleanFoundation.ps1; current validation: scripts/Validate-RdxM7MediaConfig.ps1. Old M7 validator/report counts describe the earlier snapshot and do not permit the now-intentionally-modified engine.

See OFFLINE-M7-MEDIA-CONFIG-IMPLEMENTATION.md for exact final builds/DEX, side-effect review, API22 reference resolution and frozen artifact preservation. No real TLS/USB/MediaCodec/vehicle compatibility is claimed.


## Explicit offline video data model

MediaPayload models Honda0000 BE64+opaque bytes and0001 opaque configuration. H264 is bounded AnnexB/SPS/PPS inspection only; arbitrary slice/AU grouping and real phone format remain UNKNOWN. VideoDataPlane requires a selected Honda control context and explicit HOST_ONE_MESSAGE_PER_MP4_ACCESS_UNIT boundary policy; UNKNOWN policy does not configure or queue. PlaintextVideoBridge only accepts already-decrypted complete-protocol-frame simulation bytes and rejects encrypted flags. This does not implement streaming TLS.

Host-only Mp4FixtureReader/FakeVideoDecoder/VideoWireOracle/VideoDataTests stay under tests and are excluded from JAR/DEX. All6unchanged clips and2,700samples compare with independent ffprobe metadata. Fake input acceptance/rejection/backpressure/reset and bounded count-credit policy are exercised; no displayed-frame count exists. Count-only duplicate wire ACKs remain indistinguishable when debt exists. 60,000long events finish with zero queue/debt/config; tested window up to32; queue policy1MiB.

Current build: scripts/Build-RdxCleanFoundation.ps1. Current validator: scripts/Validate-RdxM7VideoData.ps1. Earlier validators/reports preserve their revision-specific source-count assumptions. New fixture authoring scripts refuse overwrite. See MEDIA-DATA-0000-0001-EVIDENCE-REVIEW.md before altering wire assumptions. NextLIVE remains frozenM5retry separately authorized;no active M6 or real TLS/decoder operation is enabled.

## 2026-10-24 metadata-preserving fake secure-body path

The current path is documented in OFFLINE-TLS-BODY-ADAPTER-IMPLEMENTATION.md. Saved Honda TLS synthesis is now persisted in TLS-PLAINTEXT-ASSOCIATION-REVIEW.md, TLS-NATIVE-EVIDENCE-INVENTORY.md and TLS-IMPLEMENTATION-PLAN.md.

Eight new production modules preserve outer context, distinguish raw/decrypted bodies, define SecureBodyAdapter progress, model synthetic security state/policy, implement bounded body framing and integrate the existing control/media engine. All cryptography remains absent. The old TlsAdapter identity-scaffold is retained solely for existing historical test compatibility; new session work uses SecureBodyAdapter. PlaintextVideoBridge remains an unchanged synthetic whole-frame convenience and is NOT the real decryption seam.

Inbound: outer parser -> retained context -> body transform -> plaintext fragment reassembly -> dispatch. Outbound: logical plaintext ->16128byte fragments ->body transform ->actual ciphertext size ->plaintext header. BODY_DECRYPT_INCOMPLETE terminates rather than attributing delayed output to a later frame. AuthResponse0004 remains explicitly plaintext after synthetic verification. See TLS-BODY-COVERAGE.csv and STATE-GUARANTEES.md.

Reproduce with scripts/Build-RdxCleanFoundation.ps1 and scripts/Validate-RdxSecureBody.ps1. Library JAR/DEX only; no APK, native code, credential loading, TLS runtime or device interaction. M4 PASS; original M5 timing-INCONCLUSIVE; frozen M5 retry READY and next LIVE milestone; M6 disabled; M7 host foundation only.



