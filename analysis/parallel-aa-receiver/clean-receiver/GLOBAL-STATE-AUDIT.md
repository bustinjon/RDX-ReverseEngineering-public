# Global state/ownership audit — 2026-10-25

The machine-readable inventory lists53 state names across7 owners in the current source. These are **separate axes**, not53 successive protocol stages. The main session can remain MEDIA_SETUP_PENDING while its typed HondaMediaFlow substate is MEDIA_CONFIGURATION_SELECTED and the separate host VideoDataPlane reports ABSTRACT_INPUT_ACCEPTED. No MEDIA_RUNNING or displayed-frame state exists.

All states inherit this non-guarantee: **no actual phone acceptance, USB ownership, TI decode, rendering, display or fullscreen acceptance**. Construction initializes local state only. Events, not construction, drive every progression. Explicit reset semantics vary by owner as recorded below; legacy abstract reset is not an implicit revival of a current real TLS/session object.

|Owner / states|Legal incoming events and outgoing effects|Guarantee / terminal/reset|
|---|---|---|
|SimulatedSessionEngine NEW|transportReady|Local explicit simulated transport event only|
|TRANSPORT_READY|beginVersion → Version Request|No real transport owner|
|VERSION_PENDING|supported Version Response; tick/EOF/error|Version fields validated, not TLS|
|VERSION_ESTABLISHED|explicit plaintext simulation or injected verified-secure seam → AuthResponse/discovery wait|Seam is synthetic; real TLS wrapper is external|
|DISCOVERY_PENDING|Discovery Request → HU response|Bounded catalog serialization, not phone acceptance|
|SERVICES_ADVERTISED|valid service Open → response|Registry exists; no media eligibility yet|
|VIDEO_SERVICE_AVAILABLE|valid incoming Setup → setup callback/substate|Video channel routable, not decoder configured|
|MEDIA_SETUP_PENDING|typed Config policy input; valid Start; focus/accounting under substate gates|Consult HondaMediaFlow, not parent name, for media progression|
|STOPPING|Stop Response → orderly close|Pending protocol shutdown only|
|CLOSED / ERROR|No application progression; new explicit reset/session construction required|Parser/reassembly/channel state cleared; preserved outbound close bytes are intentional|
|HondaMediaFlow IDLE|valid codec3 Setup|onMediaSetup is a bounded recorded event, no decoder|
|MEDIA_SETUP_RECEIVED|explicit advertise WAIT/READY|Callback precedes Config serialization|
|MEDIA_CONFIG_WAIT_ADVERTISED|explicit synthetic policy may advertise again|Start is rejected; actual WAIT→READY trigger remains UNKNOWN|
|MEDIA_CONFIG_ADVERTISED|optional focus; valid advertised Start index|READY2, not general success0; focus cannot bypass setup|
|MEDIA_CONFIGURATION_SELECTED|flow accounting; parent close|Selected session/config; ACK never implies decoding/display|
|CLOSED|No Setup restart; new owner|Advertised set/session/events cleared|
|MemoryTlsEngine NEW|explicit initialize|No engine/provider/credentials from construction|
|HANDSHAKING|handshake pump and controlled tasks|Consumes/produces with exact accounting; no application eligibility|
|CRYPTO_COMPLETE_VERIFY_PENDING|verifyPeer|Crypto completion separate from explicit identity acceptance|
|VERIFIED|enterApplication|Explicit verification gate passed in exercised backend only|
|APPLICATION|wrap/unwrap; body boundary probe; local/peer close|Raw results never certify a body; AndroidOpenSSL profile unqualified|
|LOCAL_CLOSING|drainClose / receiveClose|Local close requested; returned output accounted if available, not a promise every provider exposes close bytes|
|PEER_CLOSED|beginClose|Current public-result mapping observed peer close; inboundDone-only mapping risk remains|
|CLOSED / FAILED|No reuse; construct fresh engine|Terminal. transportEof always aborts, even if provider closeInbound is quiet|
|SecureBodyPipeline OPEN|plaintext bypass or context-bound transform then assembly; explicit encode|Distinct ciphertext/plaintext/logical lengths; encrypted traffic needs established adapter|
|CLOSED / ERROR|No receive/encode resurrection; fresh pipeline|Buffers/reservations cleared; reset closes rather than revives|
|SyntheticTlsState NOT_STARTED|begin|Only explicit synthetic events|
|HANDSHAKING|handshakeSucceeded|No crypto implied|
|VERIFYING_PEER|verify(true/false)|Injected policy evidence only|
|ESTABLISHED_SYNTHETIC|body eligibility / beginShutdown|Not real TLS trust; external real harness may separately justify the injected seam|
|SHUTTING_DOWN|cleanClose|No actual close_notify guarantee|
|CLOSED / FAILED|No begin/verify again; fresh owner|reset closes; terminal object not reused|
|VideoDataPlane NEW|selected control + codec config|No default packet=AU assumption; UNKNOWN boundary policy rejects intake|
|MEDIA_DATA_ACCEPTING|bounded data enqueue, pump, ACK accounting|Config present; bytes opaque downstream, not decoded|
|ABSTRACT_INPUT_ACCEPTED|further bounded enqueue/pump/accounting/stop|At least one injected sink ACCEPTED; no success beyond abstract input|
|STOPPED / ERROR|No further enqueue; fresh plane|Queue/config/debt cleared; reconfiguration remains explicit UNKNOWN|
|Legacy ControlStateMachine DISCONNECTED|transportReady|Older sequencing policy, not active TLS owner|
|TRANSPORT_READY|versionSent|Abstract event only|
|VERSION_NEGOTIATING|versionAccepted|Moves to TLS_REQUIRED, no handshake itself|
|TLS_REQUIRED|tlsEstablished evidence|Injected event, not authentication proof|
|TLS_ESTABLISHED|authenticationComplete|Separate abstract gate|
|SERVICE_DISCOVERY|servicesAdvertised|Abstract catalog event|
|SERVICES_ADVERTISED / CHANNELS_OPENING|channelOpened bounded unique set|READY only when declared count reached|
|READY|beginStop|No playback or phone acceptance implied|
|STOPPING|stopped|Explicit stop event|
|STOPPED / ERROR|Explicit reset → DISCONNECTED|Legacy reset is public policy; clears opened channels. It is not used to revive MemoryTlsEngine|

Every current production state name is included above, with grouped terminal names where behavior is parallel. Invalid state/channel/media events are covered by existing deterministic and generated tests. ACK bookkeeping tokens are clean internal identities, not invented wire fields. Unknown focus prerequisites, real start/data ordering and reconfiguration stay unresolved.

See `../offline-freeze-20261025-015031-430/consistency-audit/state-inventory.csv` for exact owner/name inventory and `bounds.csv` for limits. The static audit is not a full formal reachability proof; executed regression remains the behavioral evidence.
