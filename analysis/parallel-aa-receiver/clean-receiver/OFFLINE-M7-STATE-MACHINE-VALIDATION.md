# Offline M7 session-state-machine validation — 2026-10-23

**PASS for the bounded HOST SIMULATION subset. No M7 live pass or real-phone compatibility is claimed.** M4=PASS; original M5=INCONCLUSIVE timing only; frozen M5 retry=READY for future separate live test; M6=disabled/not authorized. Clean ordinary receiver remains preferred. No ADB, vehicle, phone, USB hardware, APK installation, socket, real TLS, Honda JNI or MediaCodec execution occurred.

## 1. Actual reproduced baseline

Before modification, rebuilt31 production modules,329 deterministic checks,43295 property assertions,22500 randomized iterations and28 immutable v1 golden fixtures. Original suites: Foundation67; ProtocolCore194 +23059properties; Independent68 +20236properties. Baseline build20261023-193454-086 reproduced Java7/D8min22. Baseline source/tests/README/build script snapshot and build-validation JSON saved under m7-session-20261023-193451-888/.

All31 prior production sources and all prior tests remain unchanged; five production source modules and two test modules were added. No working legacy parser/codec/adapter was redesigned.

## 2. Final counts and scope

|Measure|Result|
|---|---|
|Production Java source modules|36 (31 prior +5 new)|
|Deterministic assertions|475 total =329 prior +146 session assertions|
|Property assertions|1541937 total =43295 prior +1498642 new|
|New generated sessions|15000 sequences ×24 events =360000 event opportunities; assertions include per-event invariants/reset checks|
|Randomized iterations total|37500 including22500 prior cases; distinct from assertion count|
|Seeds|Prior23156093377450019 and21734399680196657; new21734403991622473 (0x4D375345535349)|
|Independent fixtures|22 new session .bin/.json cases plus original28 v1 fixtures; all bytes/hash/metadata checked|
|Saved transcripts|18 deterministic scenarios, including all requested14; transcript12 includes old failure, explicit new-object reset and clean progression|
|States/graph|11 states;18 declared non-error edges plus9 whole-session invalidation edges|
|Illegal-event coverage|44 state/event cells (4 explicit inputs ×11 states), plus duplicate/out-of-order/wrong-channel/media/version/discovery negatives; not exhaustive all-message testing|
|Framing/oracle|All pre-existing independent framing/oracle tests still PASS; arbitrary host chunks/new one-byte and concatenated-message session tests PASS|
|Target API|80 external method references resolve in actual locally saved D.1.6.4 API22 definitions/inheritance or array intrinsics|
|Artifact|Library JAR/DEX only; no receiver APK produced|
|Protected artifacts|69 pre-existing APKs unchanged, including frozen M5; M4/M5 live report hashes unchanged|

## 3. Session engine, graph and constructor audit

[Complete state table/diagram](SESSION-STATE-TRANSITIONS.md). States: NEW, TRANSPORT_READY, VERSION_PENDING, VERSION_ESTABLISHED, DISCOVERY_PENDING, SERVICES_ADVERTISED, VIDEO_SERVICE_AVAILABLE, MEDIA_SETUP_PENDING, STOPPING, CLOSED, ERROR. One central state field governs progression; per-channel opened sets are data, not scattered progression booleans. legalEdge/edgeConfidence declare the graph explicitly.

Each state and transition has confidence in that table. Abstract state names are IMPLEMENTATION STRUCTURE; payload evidence and STRONGLY INFERRED ordering are distinguished. No READY/running state is manufactured. MEDIA_SETUP_PENDING records an observed setup boundary, not completed setup.

All five new production module constructors were inspected: SessionPolicy assigns explicit limits; SessionCatalog clones bounded local models/bytes; SimulatedSessionEngine initializes parser/assembler/maps/queues and does not even read its clock until an explicit event; MediaControlMessages.Value clones payload only during explicit parsing; DecoderBoundary has no constructor/implementation. No constructor opens/enumerates/sends/spawns/negotiates/allocates Android media or components. The default catalog's encoding is pure local byte construction, not transmission.

Explicit reset returns a NEW engine with fresh parser/assembler/registry/queues and no retained unknown payload. The old ERROR/CLOSED object remains terminal. No inbound/tick/start event silently revives it. Explicit EOF and local shutdown are local structure policies, not proof all phones require this exact lifecycle.

## 4. In-memory transport and deterministic transcripts

InMemorySessionTransport exists ONLY under tests and is excluded from JAR/DEX. It queues synthetic inbound chunks by fake time, captures outbound arrays, supports one-byte/arbitrary chunks, multiple logical messages in one chunk, delayed delivery, dropped/duplicated/reordered messages, EOF and explicit reset. No socket/USB/Android/network implementation exists here. Its nested Clock is injected; tests use no sleeps or system-time advances.

Engine rows record t,direction,channel,flags,raw hex,known type/decoded event,state before/after,outcome. IN_CHUNK retains full incoming wire chunks; IN_FRAME retains individual frame bodies; OUT retains complete framed arrays; LOCAL_DISCOVERY retains the candidate HU advertisement even if rejected. Thus a malformed local catalog is not misattributed to a phone's otherwise-valid discovery request. Expected output is checked against independently authored fixture bytes, including the exact version request and complete conservative HU advertisement.

Transcripts under final build/session-transcripts/:

1. conservative supported progression;
2. experimental explicit opt-in;
3. unsupported version;
4. malformed LOCAL HU discovery;
5. optional unknown service;
6. duplicate local channel binding;
7. FIRST-fragment silence expiry;
8. control-response expiry;
9. EOF during negotiation;
10. unknown protobuf field retention;
11. illegal media start;
12. terminal error → explicit new-object reset → clean progression;
13. malformed framing;
14. unknown-service isolation with valid input/video opens;
15. partial-header/body silence expiry;
16. supported media payload inspection with UNKNOWN progression;
17. orderly shutdown;
18. one-byte transport delivery.

Both profile transcripts are labeled **SUCCESSFUL SYNTHETIC PROGRESSION THROUGH MEDIA_SETUP_PENDING**, never successful Android Auto sessions. Neither proves TLS, codec allocation, phone selection or projection.

## 5. Deadline and memory policies

Production timeout values remain **POLICY_UNSPECIFIED**: callers must explicitly inject SessionPolicy. Host policy uses10ms incomplete frame,20ms incomplete fragmented message,100ms expected control response and1000ms inactivity. Those are synthetic test deadlines, not recommendations for a car. tick() evaluates deadlines; no background thread/timer/sleep is created. A future adapter must supply reliable tick events. Without ticks, retained partial state is still bounded but not automatically expired.

Partial frame → silence, FIRST → silence, version request → silence and general inactivity tests all fail deterministically and release parser/assembler/registry/output state. A fragment's first-seen deadline is not refreshed by empty/slow continuations. Expected control response applies to version/discovery/explicit shutdown; no media-response direction is invented at the UNKNOWN stop point.

Bounds: frame body16KiB,logical message64KiB,input batch64KiB,8 active fragmented channels,512KiB aggregate reservations,256 fragments/message,256 frames/feed,128 processed logical messages/session,16 registry entries,8video configs,protobuf64KiB/256fields. New limits:32 queued outbound frames,1024 transcript rows/1048576 transcript CHARACTERS, one bounded last-unknown payload. Transcript characters are not a total-heap byte bound; object/array/copy overhead remains. Test transport limits256 queued chunks/1MiB aggregate,128 captured outbound chunks, bounded synthetic delay and overflow checks.

Tests exercise output queue, transcript, conversation-step and incoming-batch overflow in addition to original boundary tests. Fatal faults clear all reservations. Existing batch-dependent frames/feed limit remains intentional; there is no promise of unlimited chunking invariance across a quota violation.

## 6. Version/control/discovery integration

Raw base version request/response is BE16, **not protobuf**. Supported local profile1.1/status0 proceeds; other versions/statuses are unsupported. Short/malformed base fails; duplicate/illegal-state versions fail. Longer version suffixes are retained and stop as **UNKNOWN_VERSION_EXTENSION**, rather than guessing their meaning or declaring all possible extensions malformed. Peer silence and negotiation EOF are tested.

Real security is not simulated as a successful handshake. enterPlaintextSimulation is an explicit transcripted bypass after base version establishment; it queues HU AuthComplete at the plaintext model seam. It never calls TLS. Existing TlsAdapter/DisabledTlsAdapter remain unchanged.

Phone requests discovery; **HU sends the capability advertisement**. SessionCatalog is a local HU catalog plus explicit service↔channel bindings. Tests with malformed/duplicate/excess/missing catalog fields validate local advertisement data; they do not invent a phone discovery-response flow. Required-field checks describe the existing strict supported codec subset, not a universal Android Auto requiredness claim.

The registry starts empty until successful atomic catalog validation. Video/input mappings use explicit separate service IDs and byte channel IDs.0 reserved; duplicate service/channel, malformed entry, missing known field, excessive count, early channel use, wrong service/media channel and repeated discovery are tested. Unknown optional service99 is preserved in the original catalog but never registered/opened; known services remain usable. Actual phone acceptance of arbitrary nonidentity mappings remains UNKNOWN, as before.

## 7. Capability profiles and exact vectors

Conservative remains default:

[Code block omitted from public report; see authored source where available.]

Experimental requires explicit opt-in:

[Code block omitted from public report; see authored source where available.]

Both full transcripts reach **MEDIA_SETUP_PENDING**, with **UNKNOWN_MEDIA_TRANSITION**. Crop placement remains UNSPECIFIED. No180/180 split, touch offset, encoded SPS geometry or phone acceptance is inferred. Input remains1325x720/60x40mm/navigation+absolute in both fixture catalogs; video changes do not mutate input dimensions. FPS mapping remains the previously corroborated Honda/OHU/OAA mapping, with pinned AASDK disagreement preserved in existing provenance.

## 8. Media control: evidence and deliberate unknowns

[Detailed local evidence](MEDIA-CONTROL-EVIDENCE.md), [fixture provenance](SESSION-FIXTURE-PROVENANCE.md), [full14-column coverage matrix](MESSAGE-STATE-COVERAGE.csv).

Established at the source/layout level: setup0x8000; start0x8001 with session1/config2; empty-base stop0x8002; legacy ACK0x8004 session1/count2. Independently authored codecs inspect these supported payloads and retain unknown supported-wire fields exactly. Fresh start/ACK encoding matches literal independent fixtures. Positive/illegal-state/malformed tests are present; no automatic ACK or media-data delivery is generated.

**Most consequential finding:** setup field1 is called config_index in pinned AASDK, media_codec_type in newer OAA; setup-response0x8003 direction differs between AASDK's explicit video send path and newer OAA notes. Honda Java setup/config/start callbacks confirm the functional families but not native wire ordering. Therefore no setup reply, configuration-ready, focus-granted, MEDIA_READY or MEDIA_RUNNING transition was added. No separate configuration response/start acknowledgment is assumed.

A second important distinction: AV setup status values are NONE0/FAIL1/OK2 in the pinned schema family, unlike the existing control-status success0. Reusing ControlMessages.Status for an AV setup success would be wrong; this engine does not do it.

Newer ACK timestamps/ackless modes, signed/extended session values beyond the strict legacy subset, focus sequencing, codec-config/access-unit association and exact decoder-consumption acknowledgment remain UNKNOWN/out of subset. The existing VideoSink/VideoProtocolBoundary are not wired to this session engine.

## 9. Error containment and unknown bytes

A whole-session invalidation: malformed framing/known schema, invalid local mapping, illegal known-message state, unsupported/unknown version format, clock/bounds failure or EOF while awaiting required control. Whole-session failure is inherited from the parser architecture and intentionally clears other pending channel allocations too.

B message rejection: unsupported valid envelope/type, unknown post-discovery channel or opaque encrypted payload. It preserves bounded raw data without progressing state; a later valid understood message may proceed.

C service unsupported: optional unknown catalog service IDs are retained but excluded from the known registry; input/video can continue.

D timeout: explicit tick expires one of the four synthetic deadline classes, invalidates state and releases allocations.

All four classes are tested. Generic ProtoWire preserves supported wire0/1/2/5 raw fields/order; immutable discovery original encoding retains nested/root unknowns. Session sidecar retains the last inspected control/media payload. Typed replies construct only understood response fields; they do not blindly echo unknown requests. Raw version suffixes are not parsed as protobuf. Unknown-field preservation is bounded and immutable, not a schema guess or an editable arbitrary-field merge.

## 10. TLS/decoder boundaries and remaining M7 blocker

Opaque encrypted frame bodies are retained without decoding. Future real streaming TLS belongs between outer-frame handling and correctly associated plaintext passed to AaMessageAssembler.acceptDecoded; TLS record boundaries must not be confused with USB/AAP fragments. The present TlsAdapter contract/disabled implementation remain, but stream buffering/association needs evidence-driven integration. No credentials, certificate/key, Honda authentication material or real TLS implementation is packaged.

DecoderBoundary declares configure/start/queue(opaque AU,PTS)/flush/stop only. No implementation, decoder instance, MediaCodec allocation or Android component exists in this engine. The prior decoder APK was neither changed nor run.

Biggest immediate protocol-core blocker: resolve the setup scalar/direction/order for the target generation before media readiness can be modeled honestly. Biggest integration gap remains actual secure streaming/transport and live USB permission/ownership prerequisites. A host progression does not solve these boundaries.

Next OFFLINE task: narrow comparison of existing capture/native dispatch evidence for0x8000/0x8003 and configuration/start/focus ordering, recording version context. Do not automatically implement a chosen interpretation. Next LIVE milestone remains **M5 retry ONLY**, separately authorized; M6 disabled, M3 deferred.

## 11. Build, reproducibility and preservation

Java7 source/target, D8min22, DEXDUMP/reference audit PASS. Compiler stubs are SDK33, not a claimed installed SDK22.80 referenced external methods resolve in actual saved D.1.6.4 API22 class definitions/inheritance or array intrinsics. Test/fake transport classes are excluded from the library. No native dependency or real TLS/MediaCodec/USB opening API was enabled.

Two fresh final builds use identical source/test/fixture inputs, byte-identical class/JAR ENTRY payloads and byte-identical DEX. Ordinary JAR container timestamps differ, documented without normalization or overwriting. Session fixture input and all18 transcript payload hashes are compared separately. Exact build paths/hashes are recorded below and in active M7 final-validation/reproducibility JSON.

All69 pre-existing APK hashes and M4/M5 live report hashes verified unchanged. Frozen M5 remains:

[Code block omitted from public report; see authored source where available.]

No APK was rebuilt in this M7 session. Original M5 is still timing-INCONCLUSIVE; its zero requests/callbacks are not a permission failure. No M6 change or live authorization.

## 12. Exact implementation changes and reproduction

New production: SessionPolicy.java,SessionCatalog.java,MediaControlMessages.java,SimulatedSessionEngine.java,DecoderBoundary.java under source/com/rdx/fullscreen/clean/. All31 original production sources unchanged.

New test-only: InMemorySessionTransport.java,SessionEngineTests.java. Original tests retained unchanged. New22 .bin/.json session fixtures +manifest. New scripts New-RdxSessionFixtures.ps1 and Validate-RdxM7Session.ps1; Build-RdxCleanFoundation.ps1 updated to run/record the new suite. Existing Compare-RdxProtocolBuilds.ps1 reused unchanged; M7 session comparison adds fixture/transcript checks.

New reports: this report,SESSION-STATE-TRANSITIONS.md,MEDIA-CONTROL-EVIDENCE.md,SESSION-FIXTURE-PROVENANCE.md,MESSAGE-STATE-COVERAGE.csv. Updated README/build matrix/NOTES chronologically. M5 documents/source/APK and historical M4/M5 reports unchanged. Generated baseline/snapshots/failed draft/host builds/transcripts/API proofs/hashes live under current M7 evidence and build directories; files-inventory.csv enumerates exact paths/hashes.

Relevant commands executed (all HOST ONLY):

[Code block omitted from public report; see authored source where available.]

The first new-suite draft rejected a malformed independently authored unknown-service fixture caused by PowerShell byte-array flattening. The draft was preserved, fixture author corrected and rerun; no production decoder or expectation was weakened. Later changes improved explicit opaque/unknown outcomes, bounds evidence, raw local-catalog trace and combined reset transcript; full tests were rerun, and final reproducibility compares identical final inputs only.

**NO ADB, VEHICLE, PHONE, USB HARDWARE, REAL TLS OR MEDIACODEC WAS USED. NO APK WAS INSTALLED. M7 REMAINS HOST SIMULATION ONLY.**

## Final immutable outputs

Baseline: build/20261023-193454-086.
First final: C:/Users/REDACTED\Desktop\RDX-ReverseEngineering\analysis\parallel-aa-receiver\clean-receiver\build\20261023-195715-450
Second final: C:/Users/REDACTED\Desktop\RDX-ReverseEngineering\analysis\parallel-aa-receiver\clean-receiver\build\20261023-195743-219
DEX SHA256: 562564A2D070414225B10B44E8D1BA246C52C36DC3834F85E5390CBB12024EAF
JAR SHA256 first: 636127F721E7660E69AE08AB435801466C46B9C608B539479E74C435A6BB43B2
JAR SHA256 second: 614CE3234721A2279E3E393932A6B1750F7CB7DC56F32E2A9E437BC3A555103C
DEX/class/JAR-entry/transcript bytes and session fixture inputs are identical. JAR container hashes differ due standard ZIP timestamps.
Evidence: C:/Users/REDACTED\Desktop\RDX-ReverseEngineering\analysis\parallel-aa-receiver\clean-receiver\m7-session-20261023-193451-888
Latest build and latest-m7-session pointer files resolve these directories. All source/test/fixture hashes, API80 proofs, compiler-input hashes, source snapshot, independent reference hashes, preservation checks and exact generated file inventory are retained there.
