> SUPERSESSION 2026-10-25: this is the pre-implementation design/evidence snapshot. Real desktop memory TLS is now implemented; API22 runtime remains unqualified. Use [current freeze](../OFFLINE-FOUNDATION-FREEZE.md) and [qualifier record](API22-TLS-QUALIFIER-FROZEN.md). The dated design below is preserved, not a current claim that no TLS implementation exists.

# Real TLS adapter contract — local evidence/design, 2026-10-24

Status: specification for a future implementation, NOT implemented or cryptographically tested. M4 PASS; original M5 timing-INCONCLUSIVE; frozen M5 retry READY; next LIVE M5 RETRY ONLY; M6 disabled; M7 offline foundation.

## Evidence and preservation

Workspace create/read/delete passed. Current source/test hashes match the completed build, 53 modules and DEX EC20A465C63A184450424F5264E720A1850BF137192E4A0A034A6B63913FF180. Prior recorded results remain 72,211 deterministic checks and 7,077,158 property assertions; the suite was deliberately NOT rerun. See real-tls-contract-evidence/artifact-verification.json. No production or test code was changed.

Native citations below refer to the existing tls-association-evidence/libautoreceiver_jni.so.*.resolved.txt files, corresponding .hex and original library. Addresses identify actual instructions, not literal-pool pseudo-instructions. Companion API22 review uses a newly decompiled, already-saved target conscrypt.jar. No target code was executed. Confidence labels: CONFIRMED = direct static call/branch; STRONGLY SUPPORTED = call-chain interpretation; POLICY = proposed clean behavior; UNKNOWN = unresolved.

## 1. Current API inventory and adequacy

**Adequate for the completed fake association tests; insufficient as the direct real-engine API.** Keep the proven outer-frame types and association rules. Revise pumping and lifecycle before plugging in cryptography.

|Current member|Input/output, ownership|Precondition/effect|Zero output/pending|Assessment|
|---|---|---|---|---|
|pumpHandshake(byte[])|Carrier bytes excluding AA type; Result chunks mean outbound handshake bytes|Simulation requires HANDSHAKING; no real completion inference|Zero legal; wrapper currently insists residual=0|UNDER-SPECIFIED: no consumed count, crypto completion, verification or bidirectional output distinction|
|encryptBody(context,byte[])|One plaintext fragment; Result chunks ciphertext, cloned|Established; pipeline insists BODY_COMPLETE in ONE call|Zero ciphertext rejected; no resumable encryption path|OVER-SPECIFIED for real provider progress; atomic convenience wrapper can remain ABOVE a pump|
|beginDecrypt(context,byte[])|Complete ciphertext body; Result chunks plaintext|Established; acquires one retained context|Zero legal for PROGRESS/NO_OUTPUT; subsequent drains|SUFFICIENT association; UNDER-SPECIFIED consumption and control output|
|drainDecrypt(context)|No new ciphertext, same identity; plaintext chunks|Existing context only|Up to256 continuations; NEED_MORE terminal|SUFFICIENT safe policy; ambiguous normal read exhaustion versus partial record|
|Result|contextId, Outcome, residualBytes, List<byte[]>; defensive copies|<=1024 chunks, <=1MiB aggregate constructor, <=65535/chunk; stage further restricts|residualBytes <=65535|AMBIGUOUS: which input/output/internal residue? No provider-state evidence|
|Outcome|PROGRESS, NO_OUTPUT_YET, BODY_COMPLETE, NEED_MORE_CIPHERTEXT, CLEAN_CLOSE, FATAL_ERROR, UNSUPPORTED_RENEGOTIATION|Pipeline interprets terminal outcomes explicitly|No null semantics|Useful outer outcomes; insufficient engine status dimensions|
|reset()/close()|void; no output returned|Simulation invalidates old contexts|Cannot report close bytes or abort versus graceful completion|UNDER-SPECIFIED; split abort/dispose from close pumping|
|CredentialInputs|Three <=64-character slot labels only|No loading or credential ownership|No secret bytes|SUFFICIENT placeholder, not a credential provider|

Concrete integration gap: SecureSessionSimulation.receive(type0003) rejects any returned output chunks; its separate explicit pump accepts output. A real handshake commonly consumes a carrier AND produces a response in that same call. Replace this restriction; never feed the same input twice to work around it. decrypt also cannot return TLS-generated outbound control bytes, and encrypt cannot report partial consumption.

## 2. Honda mapping and exact progress findings

|Operation/address|Input/call/return and BIO state|Honda next action|Clean mapping / confidence|
|---|---|---|---|
|init CB8F8|PEM root/client/key parsed via temporary BIOs; TLSv1_2_client_method; SSL_CTX_new/SSL_new; two BIO_s_mem; SSL_set_bio; SSL_set_connect_state|Separate trust store receives root|Explicit client engine creation/credential lease; CONFIRMED|
|handshake CBC20–CBC3E|Optional BIO_write(input), return not checked; SSL_do_handshake then SSL_get_error|ret1 success; otherwise error2 OR3 handled|Consumed-input plus outbound-output plus next-action result; CONFIRMED|
|handshake CBC92–CBCDC|WANT_READ/WRITE branch: BIO_ctrl(writeBIO,10,0,0), one pending query; if positive allocate pending+2, prefix 00 03, one BIO_read|One logical carrier output buffer from this pump; no repeated pending loop or exact-read check visible|Drain all output with bounded progress; CONFIRMED target, stricter POLICY|
|handshake CBC62–CBC90|ret1 sets wrapper state3 and logs version/cipher|Success branch bypasses the pending-output drain branch|Clean completion must drain final handshake output even when crypto completes; CONFIRMED target branch|
|Controller CD58C / CD7B2–CD7CE|Dispatches handshake; ret1 calls verifyPeer; return0 installs wrapper and sends AuthResponse|Ordinary encrypted traffic enabled after verification|Separate CRYPTO_COMPLETE, VERIFY_PENDING, TRUSTED; CONFIRMED|
|encrypt CBE2C–CBE78|Mutex around SSL_write. Any positive result accepted, no requested-length equality check; <=0 logs/fails, no SSL_get_error here|Queries pending write BIO via command10; returns pending size|Track actual consumed count; retry safely, not blind replay; CONFIRMED|
|cipher drain CBE88 / encode CDBF2|One BIO_read for requested pending bytes; negative fails; nonnegative accepted without equality check|Header length comes from earlier pending size|Header only after exact collected ciphertext known; CONFIRMED|
|decrypt feed CBEB0|One BIO_write; requires return == supplied length; no retry, no empty-input-BIO precheck, no lock here|false on short write|Explicit accepted versus retained bytes; never lose unconsumed suffix; CONFIRMED|
|decrypt drain CBEE0–CBF50|Mutex around SSL_read. ret>=0 returned directly. Only ret<0 calls SSL_get_error; error2 maps to0, all other errors to-1|ChannelManager repeatedly reads until0, accumulating into current frame|Distinguish exhaustion, underflow, closure and fatal; CONFIRMED|
|shutdown CBB6C–CBC10|SSL_free when allocated (owns BIOs); otherwise frees orphan BIOs; frees context, store, certs/key, global cleanup|No SSL_shutdown or output drain in this function|Target path destroys state, not evidenced graceful TLS close; CONFIRMED|

### WANT_READ, WANT_WRITE and zero

Handshake explicitly accepts errors2 and3 (WANT_READ/WANT_WRITE) and can produce output while needing further input. Initial null-input call can generate ClientHello; peer carrier input can produce one output carrier containing multiple TLS records. Repeated calls can emit multiple carriers. One carrier is NOT one TLS record. Pending input may survive in BIO/SSL; Honda does not inspect it. Empty handshake output is normal. No source-supported hard maximum for that native pending+2 allocation was found; do not copy its unbounded allocation.

Application read: WANT_READ becomes zero drain, including the ordinary condition that no more application plaintext is available after a successful body. This is NOT evidence that the target intentionally carries incomplete records across outer contexts. WANT_WRITE is not special-cased here; it fails. Application write does not classify either WANT condition. This is **NOT HANDLED BY HONDA**, not impossible.

SSL_read==0 bypasses SSL_get_error entirely. Thus Honda's wrapper cannot reliably distinguish close_notify, EOF, retry exhaustion or other zero outcomes from its return alone. Clean native backend must call SSL_get_error for every nonpositive SSL result immediately, on the same serialized execution path, before unrelated calls change the thread error queue. Error code6/zero-return means peer orderly close; transport EOF without close_notify is truncation/abort policy, not a clean TLS close. SSLEngine backend must normalize Status, HandshakeStatus AND actual buffer deltas; it must not translate every BUFFER_UNDERFLOW to BODY_COMPLETE.

### Partial writes and BIO ownership

No partial-write/moving-buffer enablement call is identified in reviewed wrapper setup; the observed SSL_CTX_ctrl command32 with0x071A0000 is an options call, not evidence of SSL_MODE_ENABLE_PARTIAL_WRITE. Do not infer short writes impossible. For native retry: preserve the original stable input buffer/length after WANT conditions unless the chosen backend's documented mode permits otherwise; advance offset only by an explicitly successful positive consumed count. Fresh output from an SSL_read can be protocol control output; it must not be silently included in the NEXT unrelated channel's encryption.

One shared SSL connection owns all channels. SSL/BIO ownership belongs to one adapter session, never one per AA channel. One active BODY transaction globally; reassembly remains per channel after decryption.

## 3. Critical completion rule: pending=0 is NOT proof

BIO input empty can mean SSL has buffered an incomplete record internally. SSL_pending==0 (where available) reports available application plaintext, not absence of incomplete ciphertext. Therefore neither one empty drain nor a collection of zero pending counters proves context completion.

POLICY: add a bounded **TLS1.2 record-envelope completeness ledger** at the real-adapter boundary, separate from AA parsing. It reads only the standard five-byte TLS record header/type/version/length and counts received record bytes; it does not decrypt/authenticate or infer AA message boundaries. Validate version/content type under the selected TLS1.2 backend profile; exact record-limit constants must be checked against that backend before implementation. An application AA body must consist of complete attributable records in the initial strict profile. A record split across AA bodies remains BODY_DECRYPT_INCOMPLETE and aborts. Handshake carriers may split/coalesce records across carriers under separate bounded handshake state.

The ledger is NECESSARY, not alone sufficient: require successful backend authentication, fully accounted consumption, complete plaintext drainage and no unknown provider residual. An opaque provider unable to establish these properties must return COMPLETION_UNPROVEN and fail closed. No later frame may be tried as a source of missing ciphertext. This preserves current attribution safety and narrows a future backend conformance requirement; it is not a claim Honda uses such a ledger.

Inbound BODY_COMPLETE certificate requires ALL:

1. Context identity unchanged; supplied bytes equal declared ciphertext length.
2. All caller bytes accepted/accounted; no unconsumed suffix or incomplete record.
3. Successful backend processing; every attributable plaintext byte drained within16128.
4. Backend is quiescent at a record/application boundary; no plaintext residual or hidden residual whose state is UNKNOWN.
5. No pending TLS control output requiring an undefined AA routing decision; no renegotiation, closure or fatal error.
6. Staged plaintext is committed only now. Fragment totals are validated AFTER decryption, never using ciphertext size.

A normal WANT_READ after authenticated complete records and fully drained plaintext may satisfy quiescence. WANT_READ with partial ledger, unknown internal state, no defensible completion, or outstanding generated control output cannot. Empty application plaintext is not sufficient proof; ordinary typed AA messages still require type bytes after reassembly.

Outbound complete requires all plaintext consumed exactly once, all attributable ciphertext drained, no unexplained preexisting output, no pending input/handshake/close demand, complete record envelope and <=65535 total bytes. Only THEN form visible AA header using actual ciphertext length. FIRST logical total remains plaintext total. The SSL record count may differ from the AA fragment count.

## 4. Proposed v2 API (DESIGN ONLY)

Use separate phase interfaces owned by ONE session/backend: HandshakePump, EstablishedBodyPump, ClosePump. A session facade controls phase capabilities. Java7 classes/enums; no sealed types, streams or modern Android APIs. Constructors store configuration only; explicit initialize/begin allocates an engine. Handshake must finish and verification approve before a caller receives EstablishedBodyPump.

Shared small metadata:

[Code block omitted from public report; see authored source where available.]

Use operation-specific immutable results rather than one giant bag:

* HandshakeStep: sessionEpoch, inputConsumed, outboundTlsChunks, nextAction, cryptoComplete, retainedHandshakeInput, error. Output and NEED_INPUT/VERIFY_PEER may coexist. The byte count refers to the supplied slice, not all bytes previously buffered.
* EncryptStep: epoch/contextId, plaintextConsumed, ciphertextChunks, nextAction, boundary, residualSnapshot, error.
* DecryptStep: epoch/contextId, ciphertextConsumed, plaintextChunks, separate controlOutputChunks, nextAction, boundary, residualSnapshot, error.
* CloseStep: epoch, outboundCloseOrAlertChunks, peerCloseSeen, localOutputDrained, nextAction, error.
* ResidualSnapshot: callerInputRemaining, adapterInputQueued, recordBytesMissing, plaintextQueued, ciphertextOutputQueued, providerResidualKnown. Counts are nonnegative and bounded; UNKNOWN is an explicit known=false, never fabricated zero. For providers lacking exact internals, boundary proof is backed by documented backend invariants plus ledger and conformance tests.

Results own immutable output copies; caller input remains caller-owned and stable until accepted, or adapter explicitly copies bounded retained bytes. No asynchronous callbacks into transport. Every output byte has one owner, kind and epoch/context. Application plaintext and TLS-generated control bytes cannot share an untyped chunks list. Return at most bounded chunks per pump; continuation cursor remains inside adapter, no unbounded caller queue.

Proposed operations: beginClient(credentialsLease), pumpHandshake(inputSlice), verifyPeer(evidence,policy), installVerifiedApplicationPhase(), beginEncrypt(context,input), continueEncrypt(context), beginDecrypt(context,input), continueDecrypt(context), beginClose(), pumpClose(inputSlice), abort(reason), dispose(). Continuations never accept another frame. New session/epoch needed after any abort/reset. Current pipeline may retain synchronous convenience methods that internally run this bounded pump, but it must not simulate completion by discarding incomplete results.

State: NEW -> HANDSHAKING -> CRYPTO_COMPLETE_VERIFY_PENDING -> VERIFIED -> APPLICATION -> LOCAL_CLOSE_REQUESTED/PEER_CLOSE_RECEIVED -> CLOSED; any failure -> ABORTED. Crypto completion can still have final handshake output to drain; installation requires that output handled too. Established renegotiation is UNSUPPORTED -> controlled abort. No resumption in first adapter profile.

## 5. Verification and credential policy

Target client role CONFIRMED by TLSv1_2_client_method and SSL_set_connect_state, not naming inference. nativeSetCreds builds temporary native strings, Controller::setClientCreds delegates to wrapper init; temporary BIOs parse X509/key objects synchronously. Parsed objects live with wrapper until shutdown; temporary strings are cleaned afterward. Reconnect must initialize a fresh engine/credential lease; exact full Java receiver reconnect reuse is not proved by these calls alone. No raw keys/certificates were loaded or reproduced in this review.

verifyPeer CBD08 retrieves peer certificate, extracts subject NID17 into20-byte buffer, compares CarService, then initializes X509_STORE_CTX with configured root and peer chain, optional time override and X509_verify_cert. No SSL_CTX_set_verify callback was identified in this wrapper init. Controller separately gates installation on verifier return0.

**New static caution:** the name-mismatch branch at CBD4A–CBD70 logs the mismatch, sets r5=0 at CBD54, cleans up and returns r5 at CBDFA. Controller treats0 as success at CD7BE. Raw .hex agrees with those instructions. This is a strongly supported target fail-open branch, not evidence that identity matching is safely enforced. Preserve as an analysis finding; do not reproduce or exploit it. The clean verifier MUST fail closed on wrong identity, missing peer, chain/signature failure, or invalid validity policy. Do not describe the historical implementation's mere strcmp as proof of enforced name validation.

CredentialVerifier owns a reviewed trust policy; backend owns parsing/cryptographic verification mechanics and immutable peer evidence. For SSLEngine a custom TrustManager will execute DURING handshake; perform real trust checks there, retain verification evidence, and maintain the separate application-installation gate afterward. Do not install an accept-all TrustManager merely to mimic native timing. Subject-CN CarService policy is not ordinary HTTPS DNS hostname verification; define its exact encoding/canonicalization and certificate constraints before phone work. No arbitrary date override or validation weakening is authorized.

CredentialProvider future contract: explicit per-session lease with root trust anchors, client chain, private-key handle/format and identity metadata; bounded loads, no logs/serialization of key bytes, release on abort/close. Prefer parsed handles with immutable public metadata. Java cannot promise perfect key erasure; native secrets need audited cleanup. APK signing identity is unrelated.

## 6. Policy, ownership, concurrency and close

|Traffic|Channel/direction|Policy|
|---|---|---|
|Version0001/0002|0, HU request/phone response|Plaintext pre-handshake only|
|Handshake0003|0, both|Plaintext AA carrier of TLS bytes during HANDSHAKING; do not reuse automatically for post-auth alerts/rekey|
|AuthResponse0004|0, HU->phone|Explicit plaintext after verified handshake; once|
|Discovery and ordinary control/media|Mapped channel|Encrypted body after AuthResponse; visible outer metadata|
|Framing errorFFFF|0, HU->phone|Target direct queueOutgoing(channel0,control=false,2-byte FF FF,encrypt=false), then unrecoverable error; documentation only|
|TLS alert/close output during application|UNKNOWN AA routing policy|Typed output may be represented by backend; initial AA binding aborts rather than assigns bytes to arbitrary channel|

Framing error CE238–CE278 disables normal incoming, queues FF FF, calls unrecoverableError(-251). Payload/channel/plaintext are strongly established; normal single-fragment framing is inferred from existing encoder. Do not add emission now: error-loop avoidance, lower transport availability and live usefulness remain unvalidated.

Layer ownership: PhysicalTransport only ordered bytes/EOF; AaOuterFramer only visible headers/body bounds; TlsAdapter only phase/TLS bytes/context identity; FragmentReassembler only decrypted fragment totals/per-channel state; SessionEngine only message/state policy and explicit routing. No adapter opens USB or knows USB packets. Session engine handles carrier construction, not crypto engine.

Honda serializes SSL_read/write with one GalMutex but BIO enqueue/dequeue and handshake are not enclosed in that same whole-transaction lock in reviewed functions. Library-global OpenSSL locking callbacks also exist. This does NOT prove arbitrary concurrent operations safe. Clean policy: one thread-affine serialized session executor, one active body globally, no reentrant adapter calls or transport callbacks under backend operations. Provider trust/key callbacks must be bounded local policy only; no network/reentry. A lock alone around separate read/write calls is insufficient to preserve attribution.

Shutdown: reviewed wrapper frees state without SSL_shutdown/close drain. Application Goodbye/transport shutdown is separate from TLS close. No application renegotiation or session-cache/resumption calls found in saved wrapper/controller resolved-call coverage; embedded/system libraries contain those symbols, which is not application use. Library defaults may still process tickets; do not claim disabled. Initial clean policy requires fresh session context, no cached-session reuse and rejection of established renegotiation. Resumption-control details are provider-specific.

Clean close: request local close, pump/output bytes, await peer close under a deadline, then dispose; peer close distinct from physical EOF; transport loss/fatal error abort immediately, drop staged body output and invalidate all state. Target AA carrier routing for post-auth close output remains UNKNOWN. Future loopback can fully test close semantics without claiming it can yet be sent over AA. Current void close() cannot support that distinction.

## 7. Bounds and liveness

Retain current65535 ciphertext/frame,16128 plaintext/fragment,1MiB logical,2MiB reassembly reservations,2 fragmented channels and256 drain continuations. These are clean policy bounds, not all native limits. TLS plaintext record capacity may be16384; therefore backend scratch must be able to receive a full record and then reject an AA plaintext fragment above16128, rather than looping forever on too-small output buffers. Saved provider reports16384 application and18437 packet buffers; wrap also checks a16709 minimum. All fit65535. Read actual session buffer requirements bounded by policy, never blindly allocate arbitrary sizes.

Proposed handshake limits for future TEST profile:64KiB retained input/output per queue,1MiB aggregate handshake traffic,256 progress steps per turn and explicit fake-clock total deadline. These are policy proposals requiring certificate-chain stress tests, not Honda constants. Existing carrier output cap16/chunk65533 is a simulation bound. No fixed production timeout is inferred here. Output backpressure must suspend the same transaction; it cannot silently discard bytes.

Every continuation must consume bytes, produce bytes, change a meaningful state, or request a concrete external action. Repeated identical zero-progress states hit bounded NO_PROGRESS. Waiting for NEW bytes during complete-body decrypt is BODY_DECRYPT_INCOMPLETE, not permission to poll indefinitely or consume next frame.

## 8. Future pseudocode (not executed)

[Code block omitted from public report; see authored source where available.]

## 9. Central remaining constraint

The real adapter cannot certify delayed plaintext ownership from counters alone. A TLS1.2 record-completeness policy, backend-specific quiescence proof and conformance tests are required. Post-auth generated control/close output has no established target AA routing policy. Keep both explicitly unresolved rather than making the fake contract's completion flag an assertion without evidence. See API22-TLS-OPTIONS-REVIEW.md and REAL-TLS-SOL-IMPLEMENTATION-PLAN.md for backend selection and exact handoff.
