# Offline protocol-core continuation — 2026-10-23

**OFFLINE PROTOCOL CORE: READY for the implemented, bounded host-test subset.** It is not a complete Android Auto receiver and has not been tested with a real phone. No ADB, Android install, device/USB enumeration, AOA, GAL, external TLS, projection, decoder or display operation occurred. No new APK was built. M4 ONLY remains the next live milestone.

## Build and evidence

* Workspace write/read/delete check succeeded at the requested project path.
* Original21 source modules reviewed; now31 Java source modules, plus host-only test fixtures/endpoints.
* Original67 deterministic checks plus194 new deterministic checks = **261**. **23059 property assertions PASS**, fixed seed23156093377450019. Counts distinguish assertions from randomized iterations.
* Build: `build/20261023-152200-374/` (also in latest-build.txt). Java7 compile and D8min-api22 PASS. JAR/DEX only, no manifest/components/native library.
* DEX SHA256: `85CC611FF466FEE782A98523280EA2FA51F32325339A911BF1F79FE8D352F383`.
* `build-validation.json`, `test-results.txt`, `protocol-test-results.txt`, `dexdump.txt`, `dex-methods.txt`, `api22-local-platform-method-check.json` are in that build directory.
* `protocol-core-session/validation.json`:69 external method references resolve against actual method definitions/inheritance in pulled core-libart/framework or array intrinsics;48 protected APK hashes unchanged;3 public capture payload literals independently verified.
* Snapshot of prior source/tests/README/build script: `protocol-core-session/foundation-before-protocol-core.zip`. Partial/failed drafts remain in timestamped build directories; they are not current validated artifacts.

## Requested test summary (1–34)

| # | Result |
|---|---|
|1|Workspace-write PASS; requested WRITE-CHECK.txt was read back and removed.|
|2|Reviewed frame/writer/parser/assembler, video/input/discovery/registry, disabled USB/AOA/TLS/control/video adapters, contracts, original tests and build workflow. Relevant NOTES/architecture/build matrix read.|
|3|31 source modules compile. Ten new modules: ProtocolLimits, ProtoWire, ControlMessages, DiscoveryCodec, ControlStateMachine, TlsAdapter, DisabledTlsAdapter, VideoSink, VideoProtocolBoundary, HeadUnitProtocolCore.|
|4|261 deterministic host checks (67 original +194 new).|
|5|23059 fixed-seed property assertions.15000 randomized iterations across chunk partitions, writer roundtrips,8-channel completion permutations, framing garbage and protobuf garbage; additional all-split/property subassertions. Framing garbage loop has30-second internal bound; test JVM heap128MiB.|
|6|Literal framing/control/protobuf/full-discovery fixtures added; partial extension, empty/over/unknown/malformed/concatenated/interleaved variants included.|
|7|Pinned AASDK frame format, OHU/OAA schemas, Honda field/enum decompilation;3 small public captured plaintext excerpts. Exact provenance/reference hashes recorded. No captured outer headers were fabricated as observations.|
|8|Every single split of the independent mixed transcript and1000 randomized chunk partitions PASS. Invariance is scoped within the256-frames/feed quota.|
|9|Malformed framing fails before unbounded allocation; failure clears partial state and requires explicit reset. Core enters ERROR; no automatic resync.|
|10|Independent interleaved fixtures and1000 randomized8-channel completion orders PASS. Wrong-channel continuation and cross-state overlap rejected.|
|11|Control0 reserved; deterministic allocation; separate local service/channel columns; duplicate IDs/channels, unknown lookup, invalid range, capacity and reset tested. Non-identity synthetic maps do not prove actual phone remapping.|
|12|Required initial inventory includes raw version, TLS envelope boundary, HU AuthComplete, discovery, service channel-open; ping likely required for duration; media setup/start/config/acks/focus needed before video. Channel-close payload unknown, not guessed.|
|13|Encode/decode: base raw version request/response; ping; status(AuthComplete/OpenResponse); ZigZag OpenRequest; discovery request/response; video and configured touchpad; stop reason and empty stop-response envelope. Real TLS/media payloads not implemented.|
|14|Known-wire literals PASS, including full nested discovery encoder equality and separate decoder literal; public captured Open/Ping/PingResponse excerpts validated independently from original JSON source.|
|15|Conservative nominal1280×720, margins0/32, active1280×688/229dpi/60fps works and remains default.|
|16|Opt-in fullscreen nominal1920×1080, margins0/360, active1920×720/229dpi/30fps serializes and parses.|
|17|Placement remains UNSPECIFIED. No top/bottom split, actual crop or touch offset inferred.|
|18|Input model retains independent1325×720 logical,60×40mm physical, navigation/absolute flags; configurable within explicit bounds.|
|19|Tests prove swapping conservative/fullscreen video does not alter input width/height/mm/flags.|
|20|Pure explicit state progression, duplicate/out-of-order rejection, fixed required-channel count, reset, fatal error and stop PASS. READY is fake modeled channel-open completion only.|
|21|Fake A conservative, B fullscreen, C byte-at-a-time, D concatenated opens, E malformed/error/reset, F unknown service inspection/unknown channel rejection PASS. Ping/stop also checked.|
|22|TlsAdapter interface and DisabledTlsAdapter production default; test-only identity-copy FakeTlsAdapter. No real handshake/crypto; streamed TLS-to-AAP metadata association unresolved.|
|23|No real credentials, certificates/private keys or Honda authentication material packaged. No APK is produced.|
|24|VideoSink and VideoProtocolBoundary deliver explicit selected-config/access-unit/stop callbacks and bounded ack accounting. No MediaCodec, wire-media header parser, automatic allocation or invented acknowledgment bytes.|
|25|Default frame16KiB, typed message64KiB,8 partial channels,512KiB reserved partial bytes,256 fragments/message and256 frames/feed; protobuf64KiB/256 fields;16 services/8 configs;256-byte identity strings;128 incoming fake messages; abstract AU1MiB.|
|26|Boundary tests PASS at max−1/max/max+1 for the main parsing/resource limits, plus signed/unsigned integer/varint/tag/UTF8/required/wire-type errors. See BOUNDS-AND-TESTS.md for exact scope and transient-memory caveats.|
|27|Java7 compilation PASS using installed Android33 public stubs. Android22 SDK is not installed. All69 external DEX method references resolve against pulled D.1.6.4 method definitions/inheritance or array intrinsics. No new desugaring dependency; static evidence only.|
|28|D8 min-api22 PASS; DEXDUMP/method-reference audit PASS; no enabled USB-open/request/claim/transfer, TLS/socket, native load, shell or MediaCodec calls. Existing explicit read-only inventory adapter is never invoked by tests.|
|29|PROVENANCE.md records pinned GPL/AGPL/proprietary references, schema facts versus implementation, tiny capture excerpts and conflicts. No substantial upstream implementation/generated runtime copied; not a formal clean-room or legal-clearance claim.|
|30|External reference/capture work needed: exact real version/options policy, TLS fragmentation association and encryption choices, media headers/acks/focus/input binding, omitted-service acceptance, channel remapping, unknown close payload. These cannot be established by more self-generated fake transcripts alone.|
|31|Vehicle evidence needed later: M4 visibility, then separately permission/ownership/races; actual phone acceptance; TI decoder performance; SPS/crop/input. No request to combine those with M4.|
|32|YES: M4 ONLY remains next live milestone. Cleared M4 artifact unchanged.|
|33|No reason emerged to revisit M3. Native receiver loading remains deferred/off the critical path.|
|34|Clean ordinary-app receiver remains preferred. Host core improvement does not resolve stock AA USB ownership or prove real-phone compatibility.|

## Findings that changed code

**FPS:** pinned AASDK says30=1/60=2; Honda/OHU/OAA say60=1/30=2. New serializer uses the corroborated Honda mapping. **Open priority:** pinned AASDK int32 conflicts with Honda/OHU/OAA sint32; codec uses ZigZag. **AuthComplete direction:** HU sends after TLS; first fake draft was corrected before final build. **Driver position:** field6 is modeled as enum, not silently copied as old AASDK boolean.

Parser failure is now explicitly latched/resettable. Assembler exact-size buffers avoid ByteArrayOutputStream capacity growth beyond declared reservation. Per-message fragment counts cap repeated empty continuations. Local state/byte bounds are security policy, not negotiated protocol maxima. Strict subset rejects groups/unknown enums/wrong known-field types and drops unknown fields when re-encoding. See inventory/provenance for intentional omissions.

## Honest limits and validation notes

Fake TLS is only an identity transform compiled in host tests. The production library cannot authenticate or start real TLS. HeadUnitProtocolCore accepts explicitly labeled unencrypted synthetic envelopes at a post-TLS seam; it is not safe to feed real encrypted traffic into that entry point. Its hardcoded1.1 fixture policy is not a production version choice. Registry non-identity maps test local lookups rather than wire-negotiated remapping. READY is not streaming readiness.

An optional independent JADX attempt using the bundled JRE failed before decompilation with AccessDeniedException reading that JRE's java.security configuration. No elevation/bypass was attempted. Do not count that attempt as successful decompilation. Compilation, fresh DEXDUMP, source/control-flow review, prohibited-reference audit, target-platform method-definition resolution and host tests are the completed verification paths. No claim is made that SDK33 compilation alone proves API22 execution.

Some initial tests exposed mistakes in the new test harness: expected disabled-TLS exceptions were not included in the rejection helper, and a purported valid chunking transcript overlapped a complete message with a partial message on the same channel. Both fixtures/helpers were corrected; failure logs remain preserved. These were not vehicle failures. Later direction review corrected AuthComplete as described above.

No permission approval was necessary for project-local writes/builds/tests. All48 pre-existing analysis APKs, including Candidates A/B and the cleared M4/M5/grid/decoder builds, retain baseline SHA256. Original source materials and historical reports were not rewritten.

## Roadmap

| DONE | NOW | NEXT | LATER |
|---|---|---|---|
|Historical M0–M2; M4/M5 artifacts;31-module pure core;261 deterministic/23059 property assertions; API/DEX/provenance checks|Host-only tested subset ready; real transport/TLS/video disabled|LIVE: M4 ONLY. OFFLINE: independent media/control fixtures and schema review before more wire codecs|After separately authorized M5 and M6: real ownership/transport/TLS/discovery, conservative video, fullscreen video,1920×720 Surface, then TTI|
