# Java TLS conformance — desktop result and API22 gap

2026-10-24. **PASS WITH LIMITATIONS** for the qualified SunJSSE desktop profile. Actual TLS1.2, TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256, mutual disposable-test authentication and memory-only transport executed. No vehicle/phone/Honda credentials/USB/decoder involved. Exact observed counts are in latest-real-tls-session.txt -> final-validation.json and final-second-transcripts/test-results.txt.

|Requirement|Desktop result|API22 public surface|Saved API22 provider evidence|Remaining uncertainty|
|---|---|---|---|---|
|wrap / exact consumption|PASS; partial consumption and overflow tested|Available, method audit|OpenSSLEngineImpl wraps through BIO|Internal buffering/drain certification needs runtime tests|
|unwrap / exact production|PASS; position deltas checked on every call|Available|BIO-based read loop|Internally generated output may be delivered by later NEED_WRAP; actual caller byte deltas remain authoritative|
|TLS1.2|Negotiated PASS|Protocol selection available|NativeCrypto supports TLSv1.2|No target engine instantiated|
|Observed GCM suite|Negotiated PASS|Cipher selection available|Suite in saved mapping/default list|No target negotiation performed|
|Delegated tasks|Explicitly executed; counted|Available|Saved getDelegatedTask returns null|Desktop task behavior not portable expectation|
|Client certificate|Mutual auth PASS; missing/wrong-root client rejected|KeyManager APIs available|Engine alias/key callbacks implemented|Actual target key format/provider support untested|
|Peer chain/identity|Fail-closed chain/validity + SAN gate PASS|X509/TrustManager APIs available|Trust validation occurs during handshake|Actual phone trust policy not implemented|
|Underflow|Partial header/payload/handshake tested|BUFFER_UNDERFLOW available|Saved engine has underflow path|Cannot assume empty provider input means complete frame|
|Overflow|Both wrap/unwrap forced, resized/retried|BUFFER_OVERFLOW available|Saved wrap minimum16709, session packet18437|Target retry/close details need conformance|
|Final handshake flight|Retained/delivered PASS|FINISHED/status APIs available|Saved sink forces NEED_WRAP|Saved successful handshake branch differs from Honda native wrapper|
|Close outbound|Actual close_notify output preserved|Available|Saved closeOutbound/free path is concerning|Target drain safety unproved|
|Close inbound|Authenticated peer closure distinguished from EOF|Available|Saved Java path mostly state update|Target truncation behavior unproved|
|Buffer sizing|Bounded18437 scratch observed; tiny buffers tested|SSLSession sizes available|Saved app16384 / packet18437|No whole-heap bound or target native memory measurement claimed|
|Completion|Ledger + authentication + exact consumption + empty drain + qualified profile|APIs exist, internals opaque|No general pending-state proof|SunJSSE qualification MUST NOT silently enable Conscrypt|
|Renegotiation|Unsupported/control-record rejection|Backend can expose HS changes|No Honda application design found|No live rekey behavior established|
|Resumption|Fresh SSLContext per pair; no reuse/cache added|Context/session APIs available|Saved provider can use cached sessions|Default ticket emission not equivalent to actual reuse|

Operation-specific results separate handshake ciphertext, application ciphertext, application plaintext and close bytes by type. No result uses null as progress. Raw engine calls return COMPLETION_UNPROVEN; the atomic body facade certifies only with complete record evidence and tested provider profile. Unexpected application handshake/control output is rejected rather than silently attached to a channel.

Negative cases: wrong root, wrong SAN DNS expectation, expired2020, not-yet-valid2035, missing client certificate, wrong-root client and explicitly failing trust callback. Seven failures, zero application-phase entries. Malformed envelope and corrupted authenticated record tests are separate from trust decisions.

Current limitations: production transport not implemented; all credentials/test names are host-only; target trust policy absent; application control/alert output has no target AA carrier policy; close() compatibility facade preserves already-proven closure and otherwise aborts; typed close pump is required for graceful closure. No indefinite renegotiation, asynchronous provider tasks or uncontrolled threads. Ownership is serialized per initialized session.

No native prototype is required to fix a demonstrated desktop Java contract failure: none was found in the exercised subset. API22 provider uncertainty remains a separate qualification gate, not proof of Java failure or proof that native is necessary.


