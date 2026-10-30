> 2026-10-25 continuation: verdict D remains; deep local search found no runnable API22 runtime. A standalone test-only qualifier and emulator-only runner are now frozen, with additional static shadow coverage. [Current freeze](../OFFLINE-FOUNDATION-FREEZE.md), [qualifier](API22-TLS-QUALIFIER-FROZEN.md). Earlier counts/results below are the2026-10-24 snapshot.

# API22 TLS qualification — 2026-10-24

**Verdict D: API22 RUNTIME TEST UNAVAILABLE; STATIC EVIDENCE ONLY.**

No installed API22 system image, emulator executable, AVD or usable Android test VM was found in the inventoried local locations. No API22 handshake, provider enumeration or Android application execution occurred. No target-provider PASS or FAIL can be assigned. The offline receiver foundation is **not finalized for the next live gate** on the strength of this analysis.

This session followed the explicitly requested fallback: reproduce the desktop baseline, review the actual saved target provider, verify important paths in DEX, and test evidence-derived return patterns against the current driver. Nothing was downloaded. ADB was not executed at all.

## Baseline reproduced before modification

Baseline build `build/20261024-155015-221` compiled57 production modules, Java7 and D8min-api22 PASS, with DEX SHA256:
`2FDBC63F2F9D63B764697D311AF89D460AE6B8E14B0FADABA9C9339F7FE7C235`.
All original foundation/protocol/session/media/secure-body suites passed unchanged. The complete real desktop TLS suite was then run with a newly generated disposable test hierarchy; historical test credential containers had already been deleted.

Actual starting total **110482 deterministic checks /7137182 property assertions PASS**,120 independent binary fixtures. Expected previous deterministic total was110478. The +4 difference is in the unchanged TLS suite's handshake/carrier byte assertions, which depend on regenerated certificate DER/flight lengths; fixed properties, test-case counts, source hashes, production class payloads and DEX reproduce. A repeat with the same newly generated test hierarchy produced the same38271 new-TLS checks and all same semantic outputs. This is count variability, not an old-test failure or a code/DEX change. Previous reports remain historical.

Desktop baseline and repeat each executed existing10000 mechanics +10000 combined AA/TLS cases, seeds23727818689957712 and18367703799771442. These are **reruns of existing coverage**, not20000 newly added API22 tests. New coverage in this session is the distinct10000-sequence static-provider model corpus.

## Runtime identity and inventory

See [inventory](API22-RUNTIME-INVENTORY.md). Selected path E, not an image that failed to boot. Runtime Android version/API/ABI/fingerprint/provider list are **NOT TESTED**. Saved target artifact metadata says Android5.1.1/API22/armeabi-v7a/fingerprint Acura/gen1CBD_HS/gen1CBD_HS:5.1.1/LMY48P/168:user/release-keys. That is disk provenance only.

Actual Android security-provider ordering, SSLContext, KeyManagerFactory and TrustManagerFactory providers, enabled/supported protocols/ciphers and runtime engine class were not enumerated. Saved code registers AndroidOpenSSL, OpenSSLEngineImpl, TLS/TLSv1.2 and the desired GCM suite; source availability is not runtime qualification.

## Required runtime criteria

|Criterion|API22 runtime result|Strongest result available now|
|---|---|---|
|TLS1.2 + required GCM suite|NOT RUN|Saved code includes both; desktop negotiates both|
|Mutual test authentication|NOT RUN|Key selection/required-client-auth/trust callbacks present; desktop PASS|
|Handshake, iterations and final flight|NOT RUN; no API22 count|Saved sink/state paths support staged output and defer FINISHED until drain; host scripted driver PASS|
|Simultaneous input/output|NOT OBSERVED on API22, not “unsupported”|Code can stage output while consuming input; driver model preserves both in one logical pump|
|Delegated tasks|NOT OBSERVED on API22|Saved getDelegatedTask returns null; desktop uses controlled tasks|
|Underflow|NOT RUN; API22 event count0|Saved status based on consumed input; model preserves positive plaintext with underflow|
|Overflow|NOT RUN; API22 event count0|Saved wrap minimum16709; model confirms exact no-consumption small-buffer result|
|Positive partial consumption|NOT OBSERVED on API22|Exact-accounting code exists; desktop105 events; Android native behavior unresolved|
|Packet/application/scratch buffers|NOT MEASURED|Saved session constants18437 packet /16384 application; current scratch18437 covers stated minima|
|Quiescence / frame-context completion|UNQUALIFIED|Ledger and exact deltas necessary; saved provider hides native residue; AndroidOpenSSL gate remains false|
|Valid/wrong-root/name/date/client trust|NOT RUN on API22|Saved trust callbacks; seven desktop negative tests fail closed|
|Application encrypt/decrypt sizes/chunks|NOT RUN on API22|Desktop exact recovery retained; static memory BIO implementation available|
|Clean local/peer close|NOT RUN on API22|DEX-confirmed close-drain concern and possible peer-close mapping gap; no actual provider failure declared|
|Abrupt EOF|NOT RUN on API22|Driver classifies transport EOF as terminal regardless of quiet closeInbound; model PASS|
|Renegotiation|No API22 attempt|Unsupported/reset remains policy; provider declaration is not a test|
|Resumption|No API22 attempt|Fresh contexts/no intentional cache reuse; saved provider has reuse code|
|Actual real adapter on Android|NOT RUN|Scripted public engine exercises actual driver; no target profile enabled|
|AA visible headers/AuthResponse/discovery/video/media|NOT RUN on API22|Repeated real desktop crypto+existing AA/media pipeline PASS|
|Large media/full profiles/long session|NOT RUN on API22|Desktop conservative+experimental and3300AUs/47649547 bytes PASS again|
|Random mechanics / combined API22 cases|0 /0|10000 new static-model sequences; not substitute runtime cases|

The existing TLS-record completion helper was not reinvented. TlsRecordLedger bounds a body to65535 bytes, rejects incomplete headers/bodies and nonapplication record types, and caps records at256. New independently assembled record envelopes exercise complete one/multiple records and a complete stream followed by an incomplete next record. No crypto or authentication follows from inspecting visible TLS headers.

## Static/provider findings and risk classification

[Differential](API22-PROVIDER-DIFFERENTIAL.md) documents every required area against actual saved code and20 DEX method excerpts.24 anchors were machine checked.

1. **Handshake byte accounting clarified:** handshakeSink.position is a read cursor. Internally generated TLS bytes need not be destination bytesProduced on unwrap; NEED_WRAP exposes them later. The scripted actual driver handles consume+output and preserves the final flight. An earlier suspicion of an inevitable byte-count mismatch is not established.
2. **Underflow is not “no plaintext”:** saved application unwrap bases status on consumed input. The driver already collects positive plaintext before reacting to underflow and does not certify a body from a raw call.
3. **Local close conflict:** actual DEX calls shutdown/free, marks outbound closed and makes subsequent wrap return CLOSED before draining the sink. The next shutdown may see a zero pointer. Native guard/exception behavior remains unknown. This is a static close concern, not a measured Android failure or grounds to discard Java core data handling.
4. **Peer close mapping gap:** native shutdown flags can make isInboundDone true while the Java unwrap result follows the consumed-count status formula. The current driver keys peer close on CLOSED. A script demonstrates the potential missed state; actual API22 behavior must be measured before adapting it.
5. **Quiescence remains unresolved:** no output/empty caller queue does not expose internal SSL residue. The AndroidOpenSSL profile is deliberately not enabled. A future provider test must prove safe frame attribution, not bypass the gate.
6. **Single-buffer scope remains appropriate:** the saved nonzero-offset scatter/gather loops are inconsistent with offset+length semantics. Current adapter uses single heap buffers, avoiding those array paths.

No production module or old test was edited. No provider-specific assumption or workaround was added. Native prototype was not built; no demonstrated core Java runtime contract failure triggers it.

## New model implementation and final builds

New host test `Api22ProviderModelTests` executes22 deterministic checks and288625 properties in10000 generated sequences, seed2504103072413126692. It uses a scripted SSLEngine and sink/record-envelope models, not saved Conscrypt classes. Expected-gap tests explicitly assert that potential limitations are **still exposed**; passing those tests is not a fix or target-provider PASS. Details/provenance are in the differential report.

Final aggregate **57 modules,110504 deterministic checks,7425807 property assertions PASS**,120 independent fixtures unchanged. Keep counts separated: desktop baseline110482/7137182 plus model22/288625; Android runtime0.

Two fresh post-change builds:

- `build/20261024-155830-693`
- `build/20261024-160122-023`

Java7, D8min-api22 and all166 external method references against saved API22 core/framework definitions PASS. DEX identical to baseline and previous release. JAR class/entry payloads identical; ordinary ZIP entry timestamps change container hashes. Fixtures and deterministic transcript payloads are compared separately. TLS ciphertext randomness is not compared byte-for-byte. The final build compiles/runs the new model test automatically but excludes every host-only class from the production library.

## Repeated desktop evidence, explicitly not Android evidence

SunJSSE/TLSv1.2/TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256;16 successful handshake pairs, handshake turns3–7987 depending on one-byte segmentation;17 simultaneous consume/output pumps and17 final flights;65 tasks;2667273 underflows;902 overflows;105 partial-consumption events. All7 wrong-root/name/expired/future/missing-client/wrong-client-root/injected-trust failures have certificate/TLS causes. No negatives passed because of missing fixture files.

Both profiles reach REAL_TLS_ABSTRACT_INPUT_ACCEPTED in a host-only session. The conservative mode remains1280×688/229dpi/60; experimental nominal1920×1080, margins0/360,229dpi/30 remains explicit, crop placement UNSPECIFIED. Long run3300 access units /47649547 media bytes reaches only fake decoder input. Largest observed packet/application scratch18437, AA reservations1048576, video buffered bytes75858, TLS queue3629. No native decoder/display/phone acceptance was tested.

## Cleanup, preservation and next gates

No test APK was built or installed; emulator package/data cleanup is N/A. The newly generated disposable test hierarchy was used only in host-memory TLS. Private-key containers are removed after validation; public certificate files, hashes and reproducible generation script remain. Cleanup and preservation are machine recorded in `qualification-final.json`.

All69 historical APKs, original source/tests and M4/M5 live reports remain unchanged. Frozen M5 SHA256 remains A22E96490B9557AFF022893A8B8B7A08BB13CEC236E52704CDDAFA90A8EE8F40. Production constructors/source remain unchanged; the new model has no Android/native/network/crypto operations. No ADB, vehicle, phone, physical USB, Honda credentials/JNI, MediaCodec, installation or factory software changes occurred. Actual crypto was confined to memory loopback with disposable test credentials.

Next best offline work is a **bounded API22 runtime conformance run once an isolated local image is supplied**, especially completion/close behavior. Additional broad architecture work is not justified now. Do not preemptively implement native TLS or claim finalized foundation. Next LIVE remains **M5 RETRY ONLY**; M6 disabled. Neither is executed by this report.
