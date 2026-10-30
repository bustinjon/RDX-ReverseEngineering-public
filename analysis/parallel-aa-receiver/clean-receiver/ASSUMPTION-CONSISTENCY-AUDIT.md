# Assumption and dependency consistency — 2026-10-25

Current authority is [the freeze status](../OFFLINE-FOUNDATION-FREEZE.md) and PROJECT-STATE.json. Historical analysis/implementation reports describe what was known then; they are not silently rewritten into current conclusions.

The machine audit checks11 current source invariants, inventories57 modules/53 states and19 bound rows, and records regex hits with path/line/context. Regex hits are **review candidates**, not proof of a stale claim. Negated warnings and historical before/after reports are false positives or explicitly historical. Exact final counts/classifications are in `../offline-freeze-20261025-015031-430/consistency-audit/`.

|Issue reviewed|Classification / resolution|
|---|---|
|TLS wraps whole AA stream|FALSE POSITIVE where negated. Current architecture encrypts only fragmented bodies; visible headers retain context|
|Message type plaintext outside encrypted body|No current production contradiction found; version/handshake/AuthResponse are explicit exceptions, not generic post-TLS plaintext|
|Media success0 / Setup configuration-index label|Current target types correctly separate codec3, Config WAIT1/READY2 and Start configuration index. Legacy MediaControlMessages is an inspection shim, not the authoritative target codec|
|ACK displayed/decoder success|Current data/accounting models and tests explicitly reject this equivalence|
|Start implies MEDIA_RUNNING|No such state exists in target media path; main/media/data-plane axes documented separately|
|Crop180/180 or touch180|Only warnings/unknowns; experimental placement and touch transform stay UNSPECIFIED|
|M5 failure / simultaneous laptop+phone|Original M5 remains timing-INCONCLUSIVE. New kit strictly separates ARM/swap/reconnect and uses300seconds total|
|M6 enabled / M7 implicitly authorized|Compile-time AOA execution false; documentation and scripts have no automatic progression|
|API22 target qualified|Runtime unavailable. Qualifier build, desktop success and static API references are distinct labels|
|Handshake result/destination mismatch suspicion|Current conformance wording corrected: sink.position is a read cursor; internally generated output may emerge through later wrap|
|Stale “TLS not implemented” design reports|Supersession notes point to implemented desktop backend while preserving the earlier design text|
|Source/artifact/live fingerprint identity|Saved system build168 differs from raw M4 live build14. Provider identity/hash must not be assumed current on the car|
|M5 journal retrieval using run-as|Avoided: frozen M5 is not debuggable. Kit uses its existing DUMP_RESULTS and verified chunk reconstruction|
|M5 private journal boundary suspicion|Independent host probe of unchanged source returns8 files, rejects ninth and refuses same-id replay; suspected regex issue was disproven, not reported as a defect|

## Module/dependency decisions

ACTIVE: framing/assembler, registry/discovery, typed Honda media, data/accounting/H264 contracts, immutable outer metadata, body pipeline and real memory TLS pumps. Current TLS implementation is explicit-initialize and host qualified only.

KEEP: FakeSecureBodyAdapter and typed fault pump in tests; PlaintextVideoBridge is a production-library **synthetic convenience seam**, not real transport. Keep disabled USB/AOA/decoder contracts inert. A public boundary with zero textual references is not automatically dead code.

DEPRECATE FOR NEW CALLERS, KEEP FOR REGRESSION: legacy ControlStateMachine/TlsAdapter/DisabledTlsAdapter/AaTlsSession and MediaControlMessages inspection path. Older test modes preserve deliberate uncertainty; HondaMediaMessages/HondaMediaFlow are authoritative for target semantics. No aggressive deletion or behavior change was made. No host test class leaks into receiver DEX; qualifier has only a reviewed pure26-module subset plus its own test core/Activity.

## Bound classification

16128 plaintext fragment is target-evidenced.65535 ciphertext follows the visible BE16 field plus clean policy.1MiB logical messages,2MiB reservations,2 active fragmented channels,32-credit video cap,256 compatibility drains and131072 real decrypt steps are **clean policy**, not claimed phone maxima.18437/16384 are saved provider constants, not measured API22 runtime allocation peaks. Legacy16384 frame/8-channel defaults coexist with explicit secure-path bounds. MP4 fixture32MiB and qualifier600seconds/256 trace entries are host/test policy only.

All166 receiver external references and all frozen qualifier references are checked against saved API22 definitions, separately from provider runtime. Static class/method availability does not validate native behavior, target firmware parity, trust acceptance or provider residue.
