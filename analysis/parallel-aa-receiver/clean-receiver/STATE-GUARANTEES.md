# Host state guarantees — 2026-10-23 video continuation

## 2026-10-24 API22 qualification boundary

**API22 RUNTIME TEST UNAVAILABLE; STATIC EVIDENCE ONLY.** Existing production states and source are unchanged. The new provider models run with scripted public SSLEngine results, never Android native code. A passing expected-gap test does not fix or qualify the provider.

|State / result|Guarantees|Does NOT guarantee|
|---|---|---|
|MemoryTlsEngine NEW|Only clean local fields/buffer allocated; no provider initialized|Handshake/provider selection, credentials or network|
|HANDSHAKING|Explicit initialization started the selected engine|AndroidOpenSSL behavior tested; trusted application phase|
|CRYPTO_COMPLETE_VERIFY_PENDING|Driver observed completion and preserved output in the exercised backend/model|Application identity accepted; all possible providers qualified|
|VERIFIED / APPLICATION|Explicit verification/application gates accepted in that instance|Android body attribution proved; real phone accepted; USB or decoder/display|
|PROVEN_QUIESCENT|Current qualified desktop profile and full record/consumption/drain conditions passed|A universal SSLEngine guarantee; saved AndroidOpenSSL qualification|
|COMPLETION_UNPROVEN for AndroidOpenSSL|The caller must retain/reject unresolved frame attribution|Safe advancement to another frame or channel|
|LOCAL_CLOSING / PEER_CLOSED|Only the driver's exercised public return mapping and close progress|Saved Android close output can be drained; all inboundDone-only peer closes detected|
|CLOSED|The exercised driver object is terminal|Honda/Android graceful close runtime proved|
|FAILED|Fresh instance required, pending caller input cleared|A demonstrated Android platform failure rather than local policy/model failure|

No API22_CONSCRYPT_QUALIFIED profile was created. No API22-specific completion shortcut or close workaround was introduced. Source/DEX alone do not resolve native residue. See [provider differential](API22-PROVIDER-DIFFERENTIAL.md) for close and peer-close limitations; [foundation status](OFFLINE-FOUNDATION-STATUS.md) remains NOT FINALIZED. Next LIVE M5 RETRY ONLY;M6disabled.

These are implementation states, not Honda's recovered internal enum. No state proves a real AA session, TLS authentication, actual decoder allocation, decoding, rendering or display. Data-plane states additionally require an explicit HOST packet/AU policy. Constructor instantiation never advances a state.

|Owner / state|Guarantees|Does NOT guarantee|
|---|---|---|
|Control NEW|Only local fields initialized|Transport ready or any bytes sent|
|TRANSPORT_READY|Explicit simulated transport event occurred|A real USB/socket exists|
|VERSION_PENDING|Supported raw version request queued locally|Peer response or compatible phone|
|VERSION_ESTABLISHED|Supported base1.1 response accepted|Security/TLS complete|
|DISCOVERY_PENDING|Explicit plaintext-simulation bypass entered|Authentication or encrypted media association|
|SERVICES_ADVERTISED|Validated local HU catalog/registry and captured response|Phone acceptance or interface ownership|
|VIDEO_SERVICE_AVAILABLE|Known video mapping opened in simulation|Codec configured or Start accepted|
|MEDIA_SETUP_PENDING|Parent container for media subflow|Readiness by itself; consult mediaState|
|STOPPING|Explicit shutdown progression|Decoder drained or phone stopped|
|CLOSED|Parent is terminal; registry/partial state cleared|Factory/device state changed|
|ERROR|Parent invalidated; no silent revival|A particular physical runtime restriction|
|HondaMediaFlow IDLE|No accepted typed Setup yet|Stream can accept data|
|MEDIA_SETUP_RECEIVED|Supported codec3 observed; abstract setup event recorded|Config advertised or decoder allocated|
|MEDIA_CONFIG_WAIT_ADVERTISED|WAIT1 advertised under explicit policy|READY, failure, or known production WAIT→READY trigger|
|MEDIA_CONFIG_ADVERTISED|READY2/config list advertised|Peer selected a configuration or sent data|
|MEDIA_CONFIGURATION_SELECTED|Valid advertised index/session accepted; ordered selection/start-observed records|TLS media received, decoder configured, AU received/accepted/decoded/rendered/displayed|
|HondaMediaFlow CLOSED|Media model terminal/reset data cleared|Data-plane attachment was a real decoder|
|VideoDataPlane NEW|No accepted synthetic config|NAL/AU format known from Honda wire|
|MEDIA_DATA_ACCEPTING|Selected control gate; synthetic AnnexB SPS/PPS parsed; fake configure/start accepted|Real codec configured, picture accepted, phone's actual packetization or SPS dimensions|
|ABSTRACT_INPUT_ACCEPTED|At least one known-source AU received ACCEPTED from the injected sink|H264 decoded, rendered/displayed, queue drained, or ongoing health|
|VideoDataPlane STOPPED|Explicit stop/discontinuity cleared config/queue/debt and called abstract flush/stop|Native Honda Stop always drains a decoder or a real device stopped|
|VideoDataPlane ERROR|Local wire/media/policy fault; config/queue/debt cleared|Actual phone failure or media service failure|

ACK is not a state transition into successful decoding/display. An INPUT_REJECTED result can generate synthetic count credit. No displayed-frame metric exists. Terminal data objects require a new selected-control/plane/bridge instance; reset does not revive the old object. Historical scalar counters remain diagnostics on the old object, not state inherited by a new instance.

## 2026-10-24 secure-body continuation

The existing control DISCOVERY_PENDING state can now also be reached by the explicit enterVerifiedSecureSimulation seam. That path records injected handshake/verification success; the historical plaintext bypass remains available and clearly labeled for old tests. Neither path establishes real security.

|Owner/state|Guarantees|Does NOT guarantee|
|---|---|---|
|SyntheticTlsState NOT_STARTED|Only fields initialized|Handshake or any bytes sent|
|HANDSHAKING|Explicit synthetic begin occurred; plaintext0003 carrier permitted|Real TLS handshake running|
|VERIFYING_PEER|Injected handshake-success event accepted|X509 verification or certificate acceptance|
|ESTABLISHED_SYNTHETIC|Both injected handshake success and VERIFY_OK accepted|Real crypto; real authentication; phone acceptance; USB transport|
|SHUTTING_DOWN|Explicit simulated close requested|TLS close_notify sent/received|
|CLOSED|Terminal object; cannot begin/verify again|Honda graceful-close semantics proven|
|FAILED|Terminal failure; application-data eligibility absent|A demonstrated real platform restriction|
|SecureBodyPipeline OPEN|Local parser/reassembler initialized; explicit events permitted|Adapter established or decryption successful|
|SecureBodyPipeline CLOSED|Explicit close/reset; parser/reservations cleared; no resurrection|Real transport or remote peer stopped|
|SecureBodyPipeline ERROR|Failure classified; parser/reservations reset; TLS state invalidated where applicable|Honda uses identical exceptional recovery|
|VideoDataPlane ABSTRACT_INPUT_ACCEPTED via secure simulation|At least one exact known-source AU passed retained-context fake transformation and fake input acceptance|Real TLS; real phone packetization; decoder allocation; decoding; rendering; display; TI performance|

SecureBodyPipeline reset requires NEW session/state/adapter construction. Decrypt underflow never borrows a later frame context. NEED_MORE_CIPHERTEXT is terminal BODY_DECRYPT_INCOMPLETE for a complete application body. NO_OUTPUT_YET is an explicitly bounded drain continuation on the SAME context. CLEAN_CLOSE is distinct from fatal error; close with pending outer/logical data is an error. These are intentional clean implementation policies; target exceptional recovery remains UNKNOWN.
# 2026-10-24 real host memory-TLS states

These states belong to MemoryTlsEngine. They do not replace historical synthetic state meanings. No state proves Android Auto phone acceptance or target API22 provider behavior.

|State|Guarantees|Does NOT guarantee|
|---|---|---|
|NEW|Only bounded RAM configuration; no provider/engine initialized|Handshake, trust, I/O or credentials|
|HANDSHAKING|Explicitly initialized SSLEngine, owner thread and bounded memory pumping|Cryptographic completion, trust or application eligibility|
|CRYPTO_COMPLETE_VERIFY_PENDING|Local test cryptographic handshake reached completion; output remains explicitly accounted|Separate SAN/identity approval or application entry|
|VERIFIED|Test chain was validated by TrustManager; explicit peer DNS/validity gate accepted|Phone/Honda trust or application data already processed|
|APPLICATION|Explicit verified phase installed; real memory TLS operations permitted|AA BODY completion from one operation, USB, real phone, decode or display|
|LOCAL_CLOSING|Local close requested; returned output accounted when available|Peer received bytes or clean bidirectional closure|
|PEER_CLOSED|Authenticated peer-close event observed|Local close output already delivered|
|CLOSED|Host loopback directions completed clean close under typed close pumping|Vehicle/phone cleanup or AA close-carrier compatibility|
|FAILED|Further application work forbidden; state/queue invalidated; fresh session required|Automatic retry/recovery|
|REAL_TLS_ABSTRACT_INPUT_ACCEPTED (host result)|Actual local TLS and disposable mutual trust; exact synthetic AA media reached fake decoder input|Real AA authentication, Honda credentials, M5/M6/USB ownership, target TLS runtime, TI decode, rendering, display or fullscreen acceptance|

Raw pump result boundary remains COMPLETION_UNPROVEN even when one wrap/unwrap succeeds. Only the complete-record/consumption/empty-drain qualified desktop profile may certify PROVEN_QUIESCENT for an AA body. Compatibility close preserves an already-proven closed engine and otherwise aborts; reset aborts. Graceful closure uses CloseResult. No target routing for spontaneous established TLS control/close bytes is claimed.


