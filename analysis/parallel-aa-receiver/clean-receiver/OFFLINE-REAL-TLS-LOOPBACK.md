# Host-local real TLS loopback — 2026-10-24

Scope: actual TLS cryptography with newly generated disposable TEST credentials, SSLEngine and bounded in-memory queues on the development PC. No sockets, Android Auto phone, Honda credentials, vehicle, USB, JNI, decoder or display. This is a HOST-LOCAL REAL-TLS SYNTHETIC AA SESSION result, not an Android Auto runtime milestone.

M4 PASS; original M5 timing-INCONCLUSIVE; frozen M5 retry READY; next LIVE M5 RETRY ONLY; M6 disabled; M7 offline foundation only.

## Baseline and implementation

Workspace create/read/delete passed. Baseline rebuilt before edits in build/20261024-105454-795:53 modules,72,211 deterministic checks,7,077,158 property assertions,115 independent fixtures,52 prior transcripts. DEX EC20A465C63A184450424F5264E720A1850BF137192E4A0A034A6B63913FF180 reproduced exactly. Old source/tests were preserved, not weakened. Diagnostic builds/logs remain historical; final two builds are identified by first-build.txt/second-build.txt in latest-real-tls-session.txt's directory.

Four production modules added (57 total):

|Module|Role|
|---|---|
|TlsPumpResults|Separate immutable HandshakeResult,EncryptResult,DecryptResult,CloseResult; exact offered/consumed/produced, action, status, phase, retained input and completion boundary|
|TlsRecordLedger|Independent TLS1.2 visible envelope check: five-byte record header, complete app records, bounded lengths/count. Does not decrypt or authenticate|
|MemoryTlsEngine|Explicit SSLEngine initialization, serialized owner, handshake/tasks/trust/application/close states, actual buffer-delta validation and bounded event trace|
|RealTlsBodyAdapter|Atomic compatibility facade over typed pumps for AA body transactions. Keeps context until complete; no transport ownership|

Old FakeSecureBodyAdapter and PlaintextVideoBridge remain unchanged. New host FakeTlsPump tests partial consumption+output, final flight, unproven completion with no visible residue, typed close output and terminal behavior. The ambiguous old pumpHandshake method deliberately rejects on the real facade; real handshake uses typed MemoryTlsEngine operations and explicit carrier handling. SecureSessionSimulation remains a historical fake integration harness. The new host Rig drives the existing SimulatedSessionEngine using real decrypted bytes; its verified-simulation seam is entered ONLY after real local handshake, trust and identity gates succeed. The historical seam name/log does not make phone authentication real.

## Exact progress and completion semantics

Every SSLEngine wrap/unwrap records source/destination positions before and after, bytes offered, consumed and produced, status and handshake status. Counts must equal provider result counts or the operation fails. Trace retains128 events; counters aggregate all calls. No assumption of full consumption. Handshake/decrypt operations accept caller bytes into a bounded owned queue; result offered/consumed refer to the actual queued engine input, which may include previously retained bytes. Callers never replay an already accepted carrier. Retained input is explicit.

RUN_LOCAL_TASK is exposed; the caller invokes runTasks on the owner thread. No worker threads are created. A pump can consume peer bytes and emit response bytes in the same call; output is retained even with NEED_INPUT or VERIFY_PEER. Crypto completion enters CRYPTO_COMPLETE_VERIFY_PENDING; custom TrustManager validates chains during handshake, and a separate SAN DNS/validity identity gate is required before VERIFIED then APPLICATION.

**Raw wrap/unwrap results ALWAYS report COMPLETION_UNPROVEN.** They cannot certify an AA frame from an empty buffer. RealTlsBodyAdapter additionally requires complete TLS1.2 application-record envelopes, full consumption, bounded complete output and an empty-input drain. Only the explicitly qualified desktop SunJSSE profile can then issue PROVEN_QUIESCENT. Other providers remain COMPLETION_UNPROVEN and AA transactions fail closed. This is a backend-specific profile supported by this corpus, not proof for arbitrary SSLEngine implementations or API22 Conscrypt internals.

Outbound: plaintext AA logical message ->16128-byte fragments -> real wrap pumping and complete ciphertext drain -> record validation -> actual ciphertext length -> visible AA header. Header is never encrypted. FIRST total remains plaintext logical total.

Inbound: reconstruct outer frame -> retain immutable metadata -> validate entire ciphertext record envelope -> feed ONLY body -> repeated real unwrap/empty-input drainage -> proven fragment -> existing per-channel reassembly -> logical message. Complete AA body containing a partial TLS record aborts as BODY_DECRYPT_INCOMPLETE. Another frame cannot supply the remainder, even on the same channel. TLS control/handshake records in established bodies are unsupported; never routed into a different channel.

Real adapter internal one-byte input tests may require up to131072 bounded pump steps per body; the existing compatibility pipeline's256 external drain limit remains unchanged because this facade completes its bounded internal transaction atomically. This distinction is intentional; one-byte input delivery is progress, not256 iterations of unproductive polling. Handshake queue65535, output65535/pump,64 steps/pump,64 tasks/run and10000 harness turns are explicit. Normal input/output scratch18437; maximum allowed65535. AA bounds remain16128 plaintext,65535 ciphertext,1MiB logical,2MiB reassembly reservations,2 active fragmented channels. Exact observed maxima are in final-validation.json/test-results.txt.

## Test credentials and trust

scripts/New-RdxLoopbackCredentials.ps1 generates new RSA2048 test root, unrelated root, client/server, expired2020, future2035 and wrong-root client material using local JDK keytool. DNS identities are rdx-test.invalid and rdx-client.invalid; no Honda identity or credential is used. Chains use appropriate serverAuth/clientAuth usages. Test password is a public disposable-harness constant, not a production secret. Key loading and trust setup are host-test code, excluded from library/JAR/DEX.

Positive tests require mutual authentication. Seven negative scenarios: wrong trusted root, wrong expected DNS name, expired server, future server, missing required client key, client signed by wrong root, and injected trust-callback failure. None can enter APPLICATION. No accept-all verifier exists. Public certificate metadata and file hashes are retained; private-key contents are never printed, logged, serialized into reports or embedded in fixtures. Private-key containers are deleted after final validation; see credential-cleanup.json. Reproduction must generate a new credential directory.

## Corpus and actual host progression

TLS1.2 negotiated with TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256 under desktop SunJSSE. No session context is reused across pairs. The TLS provider may emit tickets during an initial handshake; no resumption/cache integration is implemented or assumed. Fresh contexts prevent reuse of prior session state. There is no established renegotiation route: non-application records or unexpected handshake status fail/abort. This is tested as policy/envelope rejection, not a live renegotiation experiment.

Handshake carrier tests use actual TLS bytes inside visible plaintext channel0/type0003. TLS record stream segmentation and AA outer segmentation are varied independently; handshake records can span many carriers. The last flight must be delivered before both endpoints finish. Tests cover1/2/3/7/random carrier payload pieces and whole output. All input and generated output are queued locally.

Application tests cover empty raw-engine wrap,1,15,16,17,255,1024,16127,16128,16129,32768,65534 and262144 bytes. Empty typed AA logical messages remain invalid. Force wrap and unwrap BUFFER_OVERFLOW with tiny buffers, retry without duplicate consumption, demonstrate partial positive consumption of32768 input, and recover exact plaintext. BUFFER_UNDERFLOW from partial headers/records remains distinct from close and frame completion.

10,000 seeded mechanics cases and10,000 separate combined AA/TLS cases. Seeds23727818689957712 (0x544c534c4f4f50) and18367703799771442 (0x4141544c533132). Seeded payloads/chunks are reproducible; cryptographic keys, records and session randomness are intentionally not golden byte sequences. Failure messages include case index for combined sequences. No claim of automatic minimal-failure shrinking.

Combined matrix:6 AA transport modes (whole,1,2,3,7,random) ×5 TLS-body feed modes (1,2,3,7,whole) ×2 output-buffer modes (forced resize/full) =60 real large-AU cases, plus a1MiB logical-message roundtrip. Generated cases vary channels, CONTROL independently, sizes, direction, fragmentation, resizing and chunking. Body metadata and exact logical bytes must match. Unknown protobuf fields survive actual encrypted Setup parse/re-encode.

Independent oracle: the test server's raw JDK SSLEngine directly unwraps client ciphertext and wraps reverse-direction plaintext without using production body adapter/framer/reassembler.200 bidirectional cases compare exact bytes. This tests application mechanics against a structurally separate raw-engine path; it is not a second TLS implementation. Existing independent framing oracle continues unchanged.

Five new independently authored malformed-envelope fixtures in test-fixtures/real-tls-v1 (120 independent fixtures total): partial header, partial record, handshake/renegotiation record, zero record and oversized record. They are NOT authenticated ciphertext. Real generated ciphertext corruption is separately rejected by authentication, and cross-frame incomplete-body attempts terminalize the adapter.

## Full synthetic service/media sessions

Version plaintext -> real test mutual TLS via0003 -> trust/identity -> plaintext0004 AuthResponse -> encrypted discovery -> encrypted channel control ->8000 codec Setup ->8003 READY2 -> optional8008 Focus ->8001 configuration selection ->0001 CSD ->0000 timestamped media ->8004 accounting ACK -> fake decoder input -> explicit abstract stream stop and real loopback close.

Conservative1280x688/229dpi/60 uses the existing1280x688@60 MP4 five times:3000 access units, periodic injected fake backpressure. Experimental nominal1920x1080/margins0,360/229dpi/30 explicitly opts in, uses existing1920x720@30 fixture:300 units. Exact AU order/data/raw timestamp digest verified at fake sink. Actual transmitted body is8-byte timestamp plus opaque fixture AU; synthetic MP4 AU mapping and microsecond fixture timestamps do not establish phone packet boundaries or wire units. No decode is performed. Advertised nominal geometry, coded dimensions and crop remain separate; AA crop placement UNSPECIFIED.

ACK remains accounting only; acceptance by fake queue is not displayed-frame evidence. The old rejection-path ACK tests remain unchanged and pass. Long run maximum queue depth1, maximum outstanding accounting1; final queue/debt0. Exact bytes/maxima are recorded in transcript and final result. Total traffic also includes20,000 generated messages; no desktop throughput claim for TI/API22 follows.

## Closure, faults and backend choice

Real close_notify bytes are captured in both directions before disposal. Both loopback engines reach CLOSED. Handshake EOF, application EOF and mid-record EOF become FAILED/truncation, never clean close. Failed objects cannot enter application again. Provider cryptographic errors are exceptions plus terminal state, not boolean success. TLS-generated post-auth close/control routing over real AA remains UNKNOWN: the loopback has an explicit local close route, not a claimed target route. Compatibility close() preserves a previously proven CLOSED state and otherwise aborts; reset aborts. Graceful closure uses CloseResult methods.

Java desktop backend: PASS WITH LIMITATIONS. It satisfies the exercised memory/body contract, so a native prototype was not justified in this run. Target backend decision remains DEFER until API22 provider conformance. Direct system OpenSSL1.0.1j linking and Honda JNI remain unnecessary. See JAVA-TLS-CONFORMANCE.md and TLS-BACKEND-SELECTION.md.

## State, builds and reproducibility

Furthest offline state: REAL_TLS_ABSTRACT_INPUT_ACCEPTED. Guarantees real local TLS and test mutual trust, exact AA body transformation/reassembly, selected synthetic profile, and bytes accepted by fake decoder input. Does NOT establish phone authorization, Honda credential acceptance, USB/AOA ownership, API22 provider behavior, TI decode, rendering, display, fullscreen negotiation or TTI.

Java7 source/target, D8min22 and saved actual API22 method definitions are checked. The build reference policy now permits memory TLS APIs but continues rejecting sockets, network/USB/shell/native-loading/MediaCodec methods. Host key-store setup, test password, oracle and fake classes cannot leak into library. Constructors create bounded RAM state only; SSLContext/SSLEngine creation/handshake are explicit actions. No threads or socket code added.

Final machine counts, hashes, method audit, preservation and two-build comparisons live under latest-real-tls-session.txt. Compare DEX/JAR-entry payloads and semantic transcripts, not crypto ciphertext or random key bytes. Ordinary JAR ZIP timestamps may differ. Exact current run inventory lists all created/modified files and generated build payloads separately. Final completion appendix supplies concrete build paths/results.

Reproduce: generate fresh test credentials with New-RdxLoopbackCredentials.ps1; run Build-RdxCleanFoundation.ps1; run Test-RdxRealTlsLoopback.ps1 with explicit Build/Credentials/Output; repeat clean build; Compare-RdxProtocolBuilds.ps1; Validate-RdxRealTlsLoopback.ps1. These scripts perform no device commands. The local saved platform directory is named adb; reading its JAR files is not invoking ADB.

Next recommended OFFLINE branch: qualify the API22 provider's completion/close behavior against the same contract, under separately appropriate host/emulated-runtime scope. This run does not execute that branch. Next LIVE **M5 RETRY ONLY**; M6 **DISABLED**.


## Final validation results

- Final production modules57; old source/tests unchanged.
- Deterministic110,478 =72,211 prior +38,267 new; property assertions7,137,182 =7,077,158 prior +60,024 new.
- New generated cases10,000 TLS mechanics +10,000 combined AA/TLS; seeds23727818689957712 and18367703799771442. Mechanics RNG reset independently of certificate/handshake lengths. Overall132,500 historical/generated cases;120 independent fixtures;52 prior transcripts +2 full new media transcripts and separate conformance summary.
- Actual main corpus:16 successful handshake progressions,7 negative trust cases,65 explicit delegated tasks,17 simultaneous-consumption/output events,17 final-flight-output events. Certificate failures verified as SSLHandshakeException/CertificateException rather than missing-fixture errors. One earlier metadata-only helper separately recorded provider buffer sizes.
- Underflows2,667,271; overflows902; partial-consumption events107. Session packet/application sizes16,709/16,680; maximum allocated scratch18,437/18,437. Maximum handshake queue3,628; AA reassembly1,048,576; video queue1; video bytes75,858; outstanding accounting1; final queues/debt0.
- Synthetic streams3,300 AUs /47,649,547 media bytes; generated mechanics/AA payload9,518,084 bytes separately counted. Torture/handshake duplicates are not included in that sum.
- Host JDK17.0.20.1 SunJSSE; TLSv1.2 / TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256. Empirical completion qualification applies this tested runtime; future SunJSSE versions must be retested even though provider name is the hard exclusion gate. API22 Conscrypt remains unqualified.
- Java7/D8min22 PASS;166 external API22 methods PASS against saved definitions. API22 provider runtime UNTESTED.
- First final build: C:/Users/REDACTED\Desktop\RDX-ReverseEngineering\analysis\parallel-aa-receiver\clean-receiver\build\20261024-150637-783
- Second final build: C:/Users/REDACTED\Desktop\RDX-ReverseEngineering\analysis\parallel-aa-receiver\clean-receiver\build\20261024-150737-369
- Identical DEX SHA256 2FDBC63F2F9D63B764697D311AF89D460AE6B8E14B0FADABA9C9339F7FE7C235. JAR/class entry payloads identical; ordinary ZIP timestamps differ. Four final semantic transcript/results files identical; random TLS ciphertext not compared.
- Final exact-byte assertions cover both discovery/control directions in addition to the generated corpus. See final-first-transcripts/ and final-second-transcripts/. Earlier diagnostic runs remain saved.
- Two disposable credential hierarchies were generated in this session. All18 PKCS12 containers removed (14 private-key containers,4 trust stores). Public certificate metadata/hashes retained. No secret contents in reports or library. Cleanup evidence credential-cleanup.json and credential-cleanup-final.json.
- Frozen M5 A22E96490B9557AFF022893A8B8B7A08BB13CEC236E52704CDDAFA90A8EE8F40 unchanged; historical APKs, live reports, fixtures and original clips preserved.

Evidence: C:/Users/REDACTED\Desktop\RDX-ReverseEngineering\analysis\parallel-aa-receiver\clean-receiver\real-tls-loopback-20261024-105609-389
NO ADB, vehicle, phone, USB hardware, Honda credentials/JNI, MediaCodec, installation or socket/network transport. Real cryptography occurred only in disposable-test host-memory testing. Next LIVE M5 RETRY ONLY; M6 disabled. No later task executed.
