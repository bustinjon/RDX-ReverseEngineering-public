# API22 TLS options — saved target evidence, 2026-10-24

Static analysis only. No TLS engine instantiated, credentials loaded, handshake/cryptographic session performed, or device contacted. This report does not certify runtime compatibility. Current production/tests remain unchanged.

## Evidence inventory

New local analysis output: real-tls-contract-evidence/conscrypt/sources/com/android/org/conscrypt/, generated from the already-pulled adb/RDX-Audit/full-system/framework/conscrypt.jar with existing local JADX1.5.6. Initial sandboxed invocation failed reading Java security configuration; the explicitly approved retry succeeded. The tool's Windows utility native library is a decompiler dependency, not Honda JNI or a TLS session. Decompilation is review material, not copied implementation.

real-tls-contract-evidence/api22-tls-methods.json records319 defined methods selected from saved core-libart.jar and conscrypt.jar. This is static definition evidence, not a new compile/run test. Native library versions/symbols/ABI/hashes are in native-library-inventory.json. Java decompilation warns about reconstructed exception/control flow in unwrap; qualify suspicious branches until bytecode/runtime confirmation. No web research was used.

|Local artifact|Evidence|
|---|---|
|Saved core-libart.jar|javax.net.ssl engine/context/result/key/trust APIs and java.nio.ByteBuffer definitions|
|Saved conscrypt.jar|Actual OpenSSLEngineImpl, NativeCrypto, SSLParametersImpl, OpenSSLContextImpl, OpenSSLSessionImpl, key managers|
|Saved system libssl.so|ELF32 little-endian ARM; version string OpenSSL1.0.1j15Oct2014; SHA B614E58AC44CC06277E378F7835A32E466B42613FD61C6AF8121CD6FBDB4A518|
|Saved system libcrypto.so|Same ABI/version string; SHA272A5B81A910255A07C7D36603E13B44B74AB154FA01530CCFFF1F3518ED22C2|
|Honda receiver library|Same version string; SSL/BIO symbols DEFINED internally, not just imports. SHA031797DD4B0AECCA007A3AD7AF31C365BA3D47BEBDA8C94BFF13C5289F464C50|

## Java SSLEngine feasibility

**Memory-buffer, caller-managed transport TLS is implemented in the saved platform, not merely declared by an SDK stub.** It is a viable candidate with material provider risks.

* OpenSSLContextImpl.engineCreateSSLEngine creates OpenSSLEngineImpl without a socket. It initially sets client mode false; explicitly call setUseClientMode(true) before beginHandshake.
* beginHandshake allocates native SSL, configures key/trust parameters and connect/accept state, creates handshake BIO sink. Constructors also create a BIO sink: keep backend creation behind an explicit initialize action; an inert clean-receiver constructor must not instantiate the provider.
* wrap/unwrap use ByteBuffer sources and memory BIO sinks; no USB/socket is required. Use heap buffers and single-buffer overloads initially.
* NativeCrypto.DEFAULT_PROTOCOLS includes SSLv3,TLSv1,TLSv1.1,TLSv1.2. Explicitly enable TLSv1.2 only for the target profile; do not inherit old defaults. DEFAULT_X509_CIPHER_SUITES includes TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256.
* KeyManager/TrustManager/KeyStore and X509 key/trust interfaces exist. OpenSSLEngineImpl.chooseClientAlias supports X509ExtendedKeyManager.chooseEngineClientAlias and older X509KeyManager fallback. SSLParametersImpl.chooseClientCertificate obtains the chain and private key. This supports supplied credentials in principle; actual PEM/key encoding compatibility remains a test requirement.
* verifyCertificateChain invokes the configured X509TrustManager during handshake. It is not a passive post-handshake certificate export only. Require proper trust validation there, then an explicit application readiness gate; never a permissive TrustManager.
* getDelegatedTask returns null in this target implementation; portable wrapper must still handle NEED_TASK for desktop/other providers. Run bounded local tasks on the serialized owner, no automatic executor/thread pool.

## Provider-specific concerns requiring conformance tests

|Location in new decompilation|Observed behavior|Consequence / confidence|
|---|---|---|
|OpenSSLEngineImpl.java:403–430|Handshake unwrap passes input BIO and handshakeSink; reports bytesWritten from handshakeSink.position in result, although output is held for a later wrap|Do not treat result.bytesProduced as app plaintext or network bytes delivered to caller. Track actual destination position and NEED_WRAP. STRONGLY SUPPORTED, unwrap has decompiler warnings|
|getHandshakeStatus:217–247|Handshake sink output forces NEED_WRAP; FINISHED occurs only when sink empty; querying status can move READY state|Observe FINISHED event and preserve own session gate. Do not infer completion from nonnull session or cut-through state|
|wrap:522|Requires dst.remaining >=16709 before normal handling|Small output buffers can report overflow even for small input. Allocate bounded session packet buffer, do not spin|
|OpenSSLSessionImpl:85–92|Application buffer16384; packet buffer18437|Do not use16128 as scratch receive capacity; enforce AA limit after extraction|
|wrap:576 onward|Writes source buffers into SSL/BIO, then drains only min(sink.available,dst.remaining)|Partial consumption/drain possible; repeat with no new application input until same body's output exhausted|
|unwrap:456 onward|Duplicate source tracks consumption; loops SSL_read_BIO into destination; status based on consumed count|BUFFER_UNDERFLOW can coexist with provider-internal state. Actual byte deltas plus record ledger required|
|wrap array loop / getNextAvailableByteBuffer|Decompiled loops appear inconsistent with supplied offset/length bounds|Avoid scatter/gather/nonzero offsets initially; targeted bytecode and runtime tests before supporting them; do not declare a proven exploitable bug from decompilation alone|
|closeOutbound:132–145; shutdownAndFree:685|Calls shutdown/free, marks closed, then shutdown again; wrap returns CLOSED before drain path|Close output visibility and pointer lifecycle need verification. Cannot assume Java API semantics guarantee flushable close_notify on this provider|
|closeInbound:119–129|Visible Java path marks state, no explicit close_notify validation|Caller transport EOF must not be relabeled peer-clean-close solely on successful closeInbound|
|SSLParametersImpl.getSessionToReuse:226|Session cache lookup then SSL_set_session if found|No app resumption design does NOT mean provider cannot resume. Fresh context/no persistent cache; verify full handshake in first tests|
|NativeCrypto/SSLParametersImpl|Provider uses callbacks/native state; handshake cut-through states exist|No application sends until explicit completed-handshake + trust approval; do not use early data/cut-through eligibility|

The provider source is not run on the desktop: it depends on Android native interfaces. No confirmed eventual compatibility claim follows from these static findings. A modern desktop JDK can validate the wrapper mechanics but will not reproduce these exact implementation details.

## Cipher and version evidence

Honda init uses TLSv1_2_client_method (CONFIRMED configuration). Saved runtime log previously identified TLSv1.2 / ECDHE-RSA-AES128-GCM-SHA256 (OBSERVED negotiation). The Java name is TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256, present in saved provider mapping/default list. This is a required compatibility test vector, not proof it is the only acceptable suite. No explicit SSL_CTX_set_cipher_list call was found in reviewed Honda wrapper/controller calls. Embedded OpenSSL contains the function; presence is not configuration. Effective Honda default list and phone acceptance of alternatives remain UNKNOWN. Do not add TLS1.3 to the first target profile.

## Native alternatives

|Option|API22/ARMv7 and mechanics|Costs/risks|Recommendation|
|---|---|---|---|
|Platform SSLEngine|Java API present; saved implementation supports memory BIO transport, client keys/trust,TLS1.2/GCM|Provider-specific completion, close and residual behavior; Java API hides internal buffers|First low-cost host mechanics prototype, then API22 provider conformance gate|
|Direct system libssl/libcrypto|Saved ARMv7 exports read/write/do_handshake/set_bio, memory BIO calls, shutdown and session operations|Private native ABI, ancient target version, vendor symbol/build coupling, poor portability; system libraries are not stable public NDK contract|Plausible for a device-specific experiment but NOT preferred production dependency|
|Bundled clean TLS native library|Explicit memory BIO/control/pending access and deterministic backend version possible|New pinned source/license review, NDK ARMv7/API21-22 build, JNI lifetime/error/locking, binary size, updates and duplicate crypto risk|Parallel candidate after pure-contract tests; use isolated symbols and clean wrapper, not Honda code|
|Honda JNI/SslWrapper reuse|Target behavior available|Coupled receiver lifecycle/global cleanup and unneeded OEM dependencies|Not required by current evidence; retain deferred fallback only|

No new bundled library release was acquired or evaluated; current upstream support, sizes, supported NDKs and license terms cannot be certified from this offline collection. Older OpenSSL uses OpenSSL/SSLeay licensing; newer releases differ; BoringSSL has its own mixed notices and no stable API promise. Pin and review the exact selected source before reuse. Do not copy the Open Headunit AGPL implementation or assume schemas exempt implementation copying. Existing native library version strings do not justify deploying that old build.

**Choice C: prototype both viable backend candidates before final deployment selection**, in stages rather than building both now. Start with Java SSLEngine for the test-only host loopback and normalized pump contract. Validate the actual API22 provider's residual/close behavior; if it cannot satisfy completion/ownership without hidden APIs, use a clean bundled native backend. Native offers better observability but creates a maintenance/build burden. No final backend is selected by desktop success.

## API22 portability gates

1. Keep production interfaces Java7 and public API22; check every new method against saved core-libart/framework definitions. Avoid Android-internal Conscrypt calls, Java9 ALPN/handshake APIs, NEED_UNWRAP_AGAIN assumptions and modern convenience APIs.
2. Use SSLContext/SSLEngine with explicit client role, TLSv1.2, bounded heap ByteBuffers and custom fail-closed trust/key providers. Prefer X.509 DER chains and PKCS8 private-key input in the test harness; confirm actual backend key formats separately. Do not assume platform KeyStore can directly import arbitrary PEM text or PKCS1 bytes.
3. Separate wrapper tests on desktop from an eventual separately authorized non-car API22 provider test. Check zero/partial progress, output generated during unwrap, final flight, record residue, close and trust callbacks on that provider.
4. No automatic target-device test, emulator installation or live phone handshake is authorized here. If target verification is unavailable, report API22 runtime status UNKNOWN while continuing host contract work.
5. Android provider internals, target system OpenSSL and Honda's embedded OpenSSL are separate implementations even when version strings overlap. Do not infer one tested stack validates the others.

## Authentication dependencies

[Code block omitted from public report; see authored source where available.]

APK signing does not establish TLS key possession or phone authorization. A successful locally trusted loopback proves mechanics and test credential handling only. It leaves M5 permission, M6/ownership, real phone trust/version policy, credential validity, post-auth control routing, service acceptance, real media/AU behavior and real decoder/display unproved. **HONDA TLS JNI REUSE NOT REQUIRED BY CURRENT EVIDENCE.**
