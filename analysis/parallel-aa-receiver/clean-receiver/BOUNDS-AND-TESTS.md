# Bounds and host-test interpretation

## Default core policy

| Resource | Maximum | Enforcement |
|---|---|---|
|Outer frame body|16384 bytes|Validate BE16 before body allocation; absolute frame constructor limit65535|
|Reassembled typed message|65536 bytes|BE32 first-fragment total checked before exact allocation; includes BE16 type|
|Frames emitted per feed|256|Fail and invalidate parser if exceeded; caller must bound batches|
|Active partial channels|8|Channel ID space0..255; control0 is not allocatable as a service|
|Fragments per reassembled message|256|Counts actual envelopes including empty continuations; fail/clear at257|
|Aggregate partial reservation|524288 bytes|Exact advertised-length arrays, no growing buffer that can exceed reservations|
|Protobuf input/output|65536 bytes|Length checked before field copies/output growth|
|Fields per protobuf object|256|Bounded list; repeated singular fields still count|
|Services|16|Registry and decoded descriptor list bounded; serializer supports one video and optional one input|
|Video configurations|8|Bounded per video service/model|
|Identity strings|256 UTF8 bytes|Strict decoding; local synthetic encoding; no private identity lookup|
|Input logical dimensions|1..65535|Independent from video; physical dimensions1..1000mm local bounds|
|DPI|1..1000|Local subset bound, not phone-discovered|
|Fake conversation messages|128|Counts completed incoming messages, not transport chunks|
|Fake input batch|65536 bytes|Checked before frame iteration|
|Abstract encoded access unit|1048576 bytes|Explicit sink seam only; no decoder or wire-media parser|
|Unacknowledged abstract access units|1..32 configured|No queue retained by the boundary; synchronous fake callback; bounded count|

Core parsing nesting is structurally fixed: discovery→service→sink→video, or discovery→service→input→touchpad (four message objects deep). ProtoWire does not recursively parse arbitrary unknown blobs. Each object is bounded; transient copies/object overhead mean reservation bytes are **not a total JVM heap measurement**. Reassembly uses exact-sized arrays; completed messages and immutable frame copies temporarily add bounded copies. A frame-feed result list can retain up to256 frame copies (roughly4MiB body data under default bounds); tests run with JVM heap capped128MiB.

Public parser/assembler constructors also cap configurable maxima (message16MiB; aggregate32MiB). Default protocol limits above remain far smaller. No external length leads to unchecked signed casts, oversized allocation or recursion. Runtime OOM is not swallowed or labeled successful rejection.

## Error policy

Parser/assembler malformed input clears partial arrays/reservations, latches failure and requires explicit reset. Core malformed input clears parsers and enters ERROR; no automatic resync or retry. Unknown outer channels are structurally valid but registry-aware core rejects them. Unsupported encrypted bytes require a real future decryption adapter; they are not guessed plaintext. Truncated frame/message EOF fails.

Abstract ControlStateMachine rejects invalid/duplicate transitions while preserving its prior state; HeadUnitProtocolCore converts rejected incoming protocol events into ERROR. No automatic external transition occurs in any constructor. READY means the fake model accepted the configured channel-open events, **not that a real phone, decoder or projection stream is ready**.

Per-feed frame quota is deliberately batch-dependent: chunking invariance holds for inputs within that quota. A batch over256 frames fails even if delivering it in smaller calls would succeed. This is explicit local denial-of-service policy, not a claim of universal chunk invariance. Same-channel fragment reorder that preserves total size is not inherently detectable by a protocol without sequence numbers; tests detect unexpected/overlapping/mismatched/underflow/overflow sequences, not arbitrary semantic corruption.

## Test families

* Original67 foundation checks retained unchanged in FoundationTests.
* ProtocolCoreTests: literal independent envelopes/protobuf/capture payloads; zero/type/extension/truncation flags; known-wire full discovery; malformed/required/unknown fields; scalar/UTF8/uint32/ZigZag/int64 bounds; channel/service allocation/reset/unknowns; state progression/error/stop; explicit fake conversations; video sink callback/backpressure only.
* Random properties use fixed seed23156093377450019: every split of a literal mixed transcript,1000 arbitrary multi-split partitions,1000 separate writer/parser roundtrips,1000 randomized8-channel fragment completion orders,10000 bounded random framing byte arrays,2000 bounded random protobuf arrays. Assertion totals include per-channel/per-case checks, so they exceed iteration counts. Garbage may reject/wait/produce structurally valid bounded frames. No broad catch hides index errors, AssertionError or OOM.
* Maximum-minus-one/max/plus-one cover frame body, message total, partial channels, fragment count, aggregate reservations, per-feed frames, registry/service count, video configs, protobuf bytes/fields/strings, input dimensions, DPI, access-unit size and acknowledgment backlog. Additional signed/uint64/uint32/ID/flag/length tests reject overflow and malformed conversions.
* Fake scenarios A–F: conservative discovery; opt-in fullscreen; one-byte delivery; concatenated channel-open messages; malformed ERROR/reset; unknown service retained by inspector and unknown channel rejected by core. Version response, HU AuthComplete direction, ping echo and stop are byte-array events. FakeTlsAdapter is identity-copy with no security and is **test-only, excluded from library JAR/DEX**.

No host test opens a USB device, enumerates inventory, performs AOA/TLS/GAL, allocates MediaCodec, starts a thread or communicates with Android. No real phone compatibility is claimed. Future external evidence is still required for encryption/fragment association, media timestamps/acks/focus, actual phone-version policy, omitted-service acceptance, SPS/crop and input mapping.

## Independent validation continuation, 2026-10-23

Current total329 deterministic/43295 property assertions. Separate batch oracle/golden tests compare5000 valid and2500 malformed generated cases; prior suites remain unchanged. The whole-session invalidation policy is explicitly tested: one malformed channel releases all partial buffers, not an unproved attempt to recover other channels silently.100 repeated empty-fragment attacks reach the256-envelope limit and clear reservations. A silent peer can retain bounded data until explicit reset/EOF; future active adapters need an injected idle deadline.

ProtoWire now retains each supported raw field alongside its parsed representation; DiscoveryCodec.Decoded retains original advertisement bytes. This adds bounded input-sized copies at fixed schema depth. Reservations are still not a total heap measure; exact passthrough at65536 bytes and defensive immutability are tested. Unknown byte retention grants no meaning or permission to forward unknown request fields. Details: [current validation report](OFFLINE-PROTOCOL-VALIDATION.md).
