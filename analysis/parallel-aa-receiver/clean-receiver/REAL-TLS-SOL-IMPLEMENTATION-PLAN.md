# GPT-6.1 Sol High handoff — real TLS contract preparation

2026-10-24. PLAN ONLY, not automatically authorized for execution. Read REAL-TLS-ADAPTER-CONTRACT.md and API22-TLS-OPTIONS-REVIEW.md first. Production/source/tests unchanged in the analysis run. M4 PASS; original M5 timing-INCONCLUSIVE; M5 retry READY/FROZEN; next LIVE M5 RETRY ONLY; M6 disabled; M7 offline foundation only.

## Scope and decision

First implement the normalized progress contract and fake tests WITHOUT real TLS. Then, only in a separately requested implementation session allowing cryptography, build an entirely in-memory test-credential loopback. No phone, Honda credentials, ADB, USB, socket, APK or decoder is needed. Passing host TLS does not authorize M6/M7 live work.

Backend recommendation C: staged Java candidate first and clean-native candidate evaluation before final target choice. The saved API22 provider is substantial evidence of feasibility, with unresolved close/residual quirks. Do not turn this into a generic TLS library or full Android Auto receiver.

## Exact change plan

1. Preserve all existing fixtures/tests and frozen APKs. Reproduce the current53-module build when implementation begins; expected DEX EC20A465C63A184450424F5264E720A1850BF137192E4A0A034A6B63913FF180. Record actual result before edits.
2. Add separate operation result models HandshakeStep, EncryptStep, DecryptStep, CloseStep, ResidualSnapshot and session epoch. Keep OuterFrameContext, RawAaFrame, DecryptedAaFragment and all three length domains.
3. Introduce inert session facade plus phase-specific interfaces. Explicit initialization allocates a backend; construction does not instantiate SSLContext/SSLEngine/native provider. One serialized owner, no synchronous transport reentry.
4. Adapt FakeSecureBodyAdapter with consumed counts, independently typed TLS control output, partial encrypted-output drain, verification evidence and close events. Preserve old scenarios through an explicit compatibility shim where useful; do not weaken existing assertions.
5. Add bounded TLS1.2 record-envelope ledger with independent manually specified five-byte header fixtures. Header validation is not authentication. Handshake permits retained stream input across carriers; established AA body requires complete attributable records. Test hidden-residual UNKNOWN; it must not become zero.
6. Refactor SecureBodyPipeline.encode to run a bounded encryption transaction before writing the header. Handle actual consumed counts, output space and exact final ciphertext. Refactor decrypt to require a documented completion certificate; normal quiescent exhaustion versus BODY_DECRYPT_INCOMPLETE remain separate.
7. Refactor SecureSessionSimulation.receive(0003): a single input may produce outbound carrier bytes, even while requesting further input. Do not replay the input by calling a separate method. Queue captured output explicitly; no real transport. Handshake cryptoComplete does not imply trusted or fully drained final flight.
8. Preserve plaintext AuthResponse after verification. Reject established TLS control output whose AA route is unknown. Add typed route-policy failures instead of silently assigning it to the current or next channel. Keep FFFF notification documentation-only until separately justified.
9. Split close from abort/dispose. New close pump returns outbound bytes and peer-close state; old reset remains terminal. EOF without close evidence is abort/truncation. Never retry failed context using a later frame.
10. Run old tests plus new fake/ledger corpus; Java7, D8min22 and saved API22 method-reference validation; two clean builds. Keep PlaintextVideoBridge as historical synthetic harness. Write a new implementation report, not overwrite this evidence analysis.

## Fake gap / test matrix

|Real requirement|Current support|Missing test/design|Sol change|
|---|---|---|---|
|Output before handshake input|Explicit pump can return bytes|Client-first engine event, exact consumption0|Add|
|One input consumes and emits output|Interface can hold chunks; receive rejects them|Single inbound carrier creates reply without replay|Fix integration|
|Final handshake output plus cryptoComplete|Injected success separate|Do not install before final flight drained|Add explicit result/gate|
|WANT_READ with output|NO_OUTPUT/NEED_MORE too coarse|Quiescent complete record versus incomplete buffered record|Ledger + result mapping|
|WANT_WRITE/output-capacity demand|Absent|Repeated drain with no new input, bounded zero progress|Add|
|Partial SSL_write consumption|encrypt insists one complete return|Stable retry buffer, no duplicate plaintext|Add pump|
|Partial ciphertext drain|Only returned chunk list|Output remains owned by same context until empty|Add continuation|
|Consumed but internally retained input|One residual count|Separate caller, adapter, record and unknown provider residual|Add snapshot|
|Plaintext + outbound TLS control from read|No separate output kind|Reject unknown AA route; never conflate outputs|Add|
|Verification failure|Injected fake event exists|Crypto complete does not install; trust callback failure supported|Extend|
|Clean peer close|Fake outcome exists|Different from empty read and physical EOF|Extend|
|Local close output|void close|Close bytes drained before release; peer response/deadline|Add|
|Fatal with generated alert|Fatal only|Typed alert captured, not sent through guessed AA path|Add|
|Renegotiation|Explicit unsupported|NEED_WRAP/NEED_UNWRAP after established must be classified|Extend|
|Provider tasks|Absent|Bounded tasks cannot reenter transport or spawn uncontrolled threads|Add|
|Session resumption|No design|Fresh context/session, no cached credentials/state leakage|Add|
|Context attribution|Extensive existing coverage|Consumed-all but internally-partial record adversary|Extend; retain terminal rule|

Independent fixtures must be authored without production serializers. Include fragmented TLS record header/payload, multiple records in one AA body, complete record with multiple drains, zero-length application output, alert/handshake record inside established data, wrong epoch, duplicated carrier, output after close and unknown-residual state. TLS envelope fixtures are synthetic and unauthenticated; do not label them valid cryptographic records.

Use fixed seeds and report cases/assertions. Add generated state sequences combining partial input/partial output/task/close/error, and maintain request-context identity through all events. No millions of tests are necessary just to check docs; substantial tests are required when implementing the new contract.

## Future first real-TLS milestone: host-only mechanics

Name: HOST MEMORY-TLS ADAPTER CONFORMANCE, not Android Auto authentication.

After explicit authorization for real local crypto:

* Create two independently configured engines, client and test server, connected ONLY by bounded in-memory byte queues. No Socket/SSLSocket/server port, no network fallback.
* Generate a new TEST-ONLY CA, client certificate/key and server certificate/key with a local tool such as JDK keytool in a dedicated ignored test-output directory. Use a clear test identity and ordinary validity range, not Honda certificates. Commit generation instructions and public metadata; keep test keys segregated/labelled disposable. Random key/ciphertext bytes need not be deterministic; assertions/transcript event shape can be.
* Configure mutual authentication for a positive case, explicit TLSv1.2 and the observed GCM suite when both providers support it. A negative suite result is capability evidence, not automatic permission to weaken policy.
* No permissive TrustManager: test CA only, expected test identity, key usage/chain/validity checks. Negative cases: unknown CA, wrong identity, expired/not-yet-valid cert, missing client certificate, key mismatch. Full verification evidence required before application phase.
* Drive NEED_WRAP/NEED_UNWRAP/NEED_TASK from one fake-clock scheduler, measure actual ByteBuffer position deltas and status independently. Both directions can emit output while consuming input. Bound queues, steps, certificate sizes and logs.
* For application tests, take plaintext AA fragments -> engine -> capture all ciphertext -> outer header -> second engine on retained frame context. Exercise1/2/3/7/random queue segmentation BELOW outer framing separately from TLS drain segmentation. Never split TLS record ownership across AA frames just because the queue fragments it.
* Compare exact plaintext bytes and context metadata, not encrypted bytes across fresh sessions. Cover16127/16128/16129 logical boundaries and ciphertext expansion, cross-channel interleaving, final-flight output, partial wrap/unwrap, internal residual, close_notify and EOF truncation.
* Full close test: engine A closeOutbound -> drain to B -> B observes close -> B closes/drains -> A observes -> dispose. Also local timeout and abrupt transport loss. This proves loopback routing only; AA post-auth close-carrier mapping remains unresolved.
* Save provider/JDK versions, supported/enabled protocols/ciphers, counts, queue maxima, normalized traces and failure causes. Do not log secrets. Snapshot baseline source/APK hashes before and after.

Desktop pass permits continuing backend investigation, not a phone test. The Android provider must separately pass buffer/handshake/verification/close conformance. Do not compile saved Conscrypt implementation into the clean app or call hidden NativeCrypto methods to bypass a public API limitation. If Java cannot prove frame completion or safely close, build a minimal clean native candidate with a pinned, reviewed library and the same tests.

## Native candidate plan (conditional, not executed)

Select a maintained source/version only after authorized dependency/license review. Build an isolated ARMv7/API21-22 library with explicit memory BIO and per-session ownership; no system-private dynamic link or Honda JNI. Export a small JNI pump returning consumed counts, distinct output kinds and terminal causes. Error classification must be immediate on the owner thread. Avoid global cleanup that affects unrelated library users. Explicit key/chain lease cleanup, state destruction and ABI tests are mandatory. Measure actual binary size rather than predict it. Host-native tests and ARMv7 cross-build do not prove device loading or behavior.

## Future M7 entry criteria — all remain gated

1. Live M5 standard permission PASS under separate authorization.
2. Separately authorized M6 controlled AOA-only result and USB ownership/contention understood; no force-claim or Honda suppression.
3. Bounded real adapter host conformance, API22 compatibility and provider runtime evidence.
4. Reviewed credential provenance/format, fail-closed trust policy, client role and protocol-version policy; real phone acceptance still a measured result, never assumed.
5. Version/carrier/AuthResponse/discovery ordering and encrypted-body routing tested; failures/reset/cleanup bounded; no unresolved control-output event silently transmitted.
6. Separate explicit live M7 authorization and concise observation/stop/cleanup plan. No decoder/fullscreen/input escalation from handshake success.

## Remaining investigations

Most important: backend-specific proof of record completion and attribution despite hidden TLS buffering; post-auth TLS control/close-output AA routing; target Java close/drain behavior. Honda wrapper name-mismatch return-path finding must NOT become a permissive clean trust policy. Real phone credential acceptance, service behavior, media boundaries and TI decoding remain separate unknowns.

No Sol implementation plan step was executed in this analysis session. Next LIVE remains **M5 RETRY ONLY**. M6 remains **DISABLED**.
