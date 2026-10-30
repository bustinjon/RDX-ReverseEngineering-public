# Offline protocol validation — independent host oracle, 2026-10-23

**PASS for the bounded host-only protocol subset. No ADB or vehicle communication occurred.** No APK was installed/built, no USB enumeration/open/request/claim/transfer, AOA, GAL, external TLS, projection, MediaCodec, Android component or display-state operation occurred. M4 remains the next live milestone; this is not M4/M5/M6 authorization or an M7 runtime pass.

## Exact baseline before modification

The prompt's21-module/67-check baseline is historical. The newest saved workspace already contained31 production Java source modules, the67 original FoundationTests checks plus194 ProtocolCoreTests checks (261 deterministic), and23059 property assertions. I preserved and freshly rebuilt that actual state before modification rather than regressing it to21 modules.

* Fresh baseline build: `build/20261023-164210-195`.
* Snapshot/current session: `host-validation-session-20261023-164209-740/` (also latest-host-validation-session.txt).
* `baseline.json`, `preexisting-build-validation.json`, `source-before.zip` preserve exact baseline hashes, source/tests/README/build script and prior validated build metadata.
* Baseline Java7 compile, D8min22 and all original/current tests PASS before changes. Constructors retained explicit/inert behavior. No adapter was enabled.

## Current results

| Measure | Result |
|---|---|
|Production source modules|31, unchanged module count; only ProtoWire and DiscoveryCodec production implementations changed|
|Original FoundationTests|67 PASS, not deleted or weakened|
|Existing ProtocolCoreTests|194 deterministic +23059 property assertions PASS, unchanged expectations|
|New independent suite|68 deterministic +20236 property assertions PASS|
|Total|**329 deterministic +43295 property assertions =43624 checks/assertions PASS**|
|New randomized cases|5000 valid differential conversations +2500 deliberately malformed cases|
|Randomized iterations including prior suite|22500, distinct from assertion count; extra fixed replay/lifetime tests are not mislabeled random cases|
|Seeds|Existing23156093377450019; new21734399680196657 (0x4d375244583031)|
|Golden fixtures|28 versioned binary fixtures with per-case metadata, expected fields/bytes, SHA256 and provenance|
|Java/API build|Java7 compile; D8min-api22; fresh DEXDUMP/reference audit PASS|
|Target API evidence|69 external DEX method references resolve to actual pulled D.1.6.4 platform method definitions/inheritance or array intrinsics|
|Active I/O/new APK|None; test-only oracle/fakes/classes excluded from production JAR/DEX|
|Preservation|48 protected analysis APK hashes unchanged, including Candidate A/B and M4/M5/grid/decoder|

Final build: `build/20261023-164856-260/`; `latest-build.txt` points to it. DEX SHA256:

[Code block omitted from public report; see authored source where available.]

Machine evidence: `host-validation-session-20261023-164209-740/final-validation.json`, `reproducibility.json`, `compiler-input-hashes.json`; build test logs/DEXDUMP/method inventories and `api22-local-platform-method-check.json`. Prior core validation JSON was copied into the session before refreshing its current validation pointer.

## Independent framing oracle

ReferenceWireOracle is **test-only** and imports no production framing/codec classes or constants. It uses a whole-buffer DataInputStream/DataOutputStream implementation, its own record types, switch over two-bit fragment kinds and TreeMap/ByteArrayOutputStream reassembly. Production uses incremental header/body parsing and exact-sized reservation arrays. This structural separation avoids merely generating tests with our writer and reading them with our parser.

The oracle authors legal randomized frame streams, interleaves up to5 independent channel sequences, fragments2..1024-byte logical payloads into1..8 pieces (including empty fragments), varies CONTROL independently, and serializes BE fields itself. Production receives arbitrary chunks; expected frames/messages come from the oracle. Production writer bytes are compared separately to the independently encoded stream. ENCRYPTED fixture remains opaque; no crypto runs.

Golden tests cover single/multiple complete frames, every single split of the small accepted logical fixture streams (including each header/payload position), one-byte-at-a-time delivery including the maximum body, FIRST/middle/LAST/complete forms, interleaving, immediate next frame after fragmented completion, zero-body structural envelopes and maximum16384-byte body. Existing tests cover all prior partial/split-type/short-tail/capacity cases. Every valid differential case agreed exactly.

Agreement establishes implementation consistency with an independently authored local oracle—not proof that every reverse-engineered assumption matches every phone. Golden expected bytes are independently authored from documented/pinned structural facts, not recalculated through production Java codecs.

## Malformed input, ordering and failure semantics

Both implementations reject unsupported flags, truncated headers/extensions/bodies, unexpected continuation, overlapping complete/first, inconsistent fragment flags, underflow/overflow, incomplete logical EOF and excessive unsigned totals.2500 seeded malformed cases were rejected by both; repeated fresh production runs returned identical exception class/message for each case.

All original bounds checks remain: frame16KiB, complete message64KiB,8 active partial channels,512KiB aggregate reservation,256 fragments/message and256 frames/feed; registry16 services;8 video configs; protobuf64KiB/256 fields; identity strings256 UTF8 bytes. Public configurable constructors also retain their absolute caps. Main limits are exercised at max−1/max/max+1; signed/unsigned integer and impossible-length cases remain covered.

The current architecture intentionally **invalidates the whole session** on malformed logical input. A failed channel clears all pending channels/reservations and latches failure; it does not silently corrupt or resume another channel. That is an explicit fail-closed policy, not per-channel fault containment. Tests verify global cleanup and explicit reset. No automatic resynchronization was introduced.

100 repeated attacks with empty continuations hit the256-fragment cap, release all reservation memory and fail deterministically. A peer that sends nothing further can leave a bounded partial allocation until explicit reset/EOF: pure code has no clock/thread/idle timeout. A future transport/session adapter needs an explicit idle-deadline event. This is a remaining runtime design requirement, not an unbounded allocation path.

Per-feed256-frame quota remains deliberately batch-dependent. Chunking invariance is tested within that quota; a257-frame batch is rejected rather than promising the same behavior as257 separate calls. Total heap includes immutable/output/object/transient copies, not just reservation counters. Tests run under128MiB JVM heap; no formal whole-JVM memory proof is claimed.

## Unknown fields: actual production change

Previously, parsed unknown fields could be inspected generically but their exact wire bytes were discarded. ProtoWire.Field now retains a bounded defensive raw encoding, and ProtoWire.Message.encoded() returns byte-exact supported-wire input, preserving order, duplicates and accepted nonminimal varints. unknownFields(known...) extracts raw unknowns without interpreting them. Supported types remain0/1/2/5; obsolete groups/invalid wire types still fail.

DiscoveryCodec.Decoded.originalEncoding() retains immutable original response bytes, including nested unknown service/video extensions. Tests prove root/nested retention and defensive copies, including at the65536-byte protobuf ceiling. Retention adds bounded raw copies—approximately another input-size copy per parsed layer, not an unbounded stash. Fixed schema traversal depth remains bounded.

Typed control codecs and fresh advertisement generation still intentionally emit only understood fields. A response must not blindly echo unknown request bytes. Lossless inspection is available through the generic message/original discovery encoding; editable unknown-field merging is not implemented. Existing known message serializers/defaults did not change.

## Control/discovery and field status

The pre-existing pure codecs/state/registry were validated rather than redesigned. Base raw version, AuthComplete/OpenResponse status, Ping, ZigZag OpenRequest, discovery request/response, video/touchpad and shutdown payloads remain supported. Control0 stays reserved; deterministic allocation and explicit service↔channel columns remain. Synthetic remapping is not proof that a phone negotiates arbitrary mappings. HU AuthComplete direction remains correct after the explicit fake handshake event.

`FIELD-CONFIDENCE.md` classifies **every implemented field family** as CONFIRMED in pinned static code, STRONGLY INFERRED interpretation or UNKNOWN/PASSTHROUGH. Unknown optional fields are retained without fabricating values. New advertisement still contains only video and optional input; audio/microphone/sensors/navigation/phone/HUD are omitted, with real-phone sufficiency unproved.

Video capability bytes remain:

[Code block omitted from public report; see authored source where available.]

Fullscreen is not default. Crop placement remains **UNSPECIFIED**. No180/180 split, encoded SPS raster, top alignment, touch offset or phone acceptance is inferred. Input1325x720/60x40mm remains independent; existing no-silent-mutation checks PASS.

## Cross-reference agreements and conflicts

Pinned AASDK/OHU/OAA/Honda references agree on the broad envelope, FIRST-only total extension, continuation semantics, discovery/service concepts and nominal video plus margins. Details/provenance and source SHA256 remain in PROVENANCE.md and the earlier reference inventory.

Conflicts retained:

* FPS: pinned AASDK says30=1/60=2; Honda/OHU/OAA say60=1/30=2. We use corroborated Honda mapping.
* Open priority: pinned AASDK int32 versus Honda/OHU/OAA sint32; we use ZigZag.
* Legacy AASDK field6 boolean description versus driver-position enum in other references; current synthetic response explicitly uses enum0.
* Limited public TouchConfig versus Honda's richer touchpad fields; physical/navigation/absolute fields are retained based on actual Honda tags and OAA corroboration.
* Crop placement, encoded dimensions, touch relationship, ping encryption/version suffixes and real channel binding remain unresolved. No silent reconciliation or new claim from oracle agreement.

No upstream implementation or generated protobuf runtime was copied. Oracle and generator are independently authored; GPL/AGPL/proprietary reference context is documented rather than treated as legal clearance. No private authentication material is in fixtures/library.

## Constructors, API22 and reproducibility

Modified production constructors only assign fields, clone bounded byte arrays or initialize containers. No new constructor performs inventory, permission, device open, threads, sockets, TLS, GAL, MediaCodec, Activity/Service, networking or negotiation. Test constructors likewise remain local; fixture file reads occur only through explicit host-test main calls. Reference batch streams wrap memory, not hardware.

Java7 source/bytecode and D8min22 pass. Installed compile stubs are SDK33, not a silently claimed installedSDK22. The actual69 external references resolve in the pulled D.1.6.4 core-libart/framework definition/inheritance inventory or array intrinsics. No new runtime dependency/native library/desugaring requirement. No Android runtime compatibility claim beyond this static evidence.

Clean builds `20261023-164804-368` and `20261023-164856-260` have identical source/test/fixture inputs, identical class/JAR-entry payloads and **byte-identical DEX**. JAR container hashes differ:

* First `0E1B4D988D77CEF91CB874469DC7901001214E6C55DFA7A8A98099DAA5A843B4`
* Second `FC2B4BB0E2E2D340D1F037F2A20EAA19361B214123FB9AF623384658898D79B9`

Standard jar cf retains file/creation ZIP timestamps. Entry timestamps and payload hashes are saved in reproducibility.json. No timestamps were normalized and no historical output overwritten to conceal nondeterminism. Compiler executable/D8/stub hashes are recorded and rechecked.

## Files created/modified

Production modified: `source/.../ProtoWire.java`, `DiscoveryCodec.java`. No new production module or adapter activation.

Host tests created: `tests/.../ReferenceWireOracle.java`, `IndependentValidationTests.java`. All previous tests remain.

Fixtures/docs created: `test-fixtures/v1/` (28 binary/metadata pairs, manifest, TSV, README), `FIELD-CONFIDENCE.md`, this report; timestamped baseline/build/validation/reproducibility evidence. README/build matrix/NOTES and bounds/provenance receive chronological appendices, not rewritten historical conclusions.

Scripts: updated `Build-RdxCleanFoundation.ps1` to run the independent suite and record fixture hashes; new `New-RdxProtocolGoldenFixtures.ps1`, `Compare-RdxProtocolBuilds.ps1`, `Validate-RdxProtocolOfflineSession.ps1`. The earlier core validator remains available for target-method/APK/capture checks. No live script was invoked.

## Exact relevant commands used

From the project root, each build creates a fresh timestamped directory:

[Code block omitted from public report; see authored source where available.]

The build script executes javac -source7 -target7 against the installed android.jar, the three host suites (new suites with -Xmx128m), jar cf, D8 --min-api22 and SDK dexdump. Full inputs/hashes and test outputs are preserved. No test fixture generation reruns during a normal build.

## Most important finding and next steps

No framing/reassembly discrepancy was found between the incremental implementation and the independent batch oracle across the tested corpus. The concrete production gap was unknown-field byte loss; bounded lossless inspection is now available. This reduces risk but does not validate real phone behavior.

Before M7 runtime, real transport ownership/permissions and AOA must be demonstrated in their own authorized milestones; real TLS metadata association, version/options, media setup/focus/acks and phone acceptance still require independent evidence/implementation. Recommended next **offline** task is independent media/control capture fixtures and schemas for the video setup/start/ack boundary, plus explicit injected idle-timeout design. Recommended next **live** milestone remains **M4 ONLY**. Neither next task is executed automatically here.
