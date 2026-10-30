> 2026-10-25: Java remains desktop-qualified only; target backend DEFER. Frozen API22 qualifier is build/static/desktop-functional verified, not Android runtime evidence. Saved provider/build168 and last live fingerprint/build14 have unverified parity. Close-only static concerns do not justify automatic native implementation. [Current status](../OFFLINE-FOUNDATION-FREEZE.md).

# TLS backend decision — 2026-10-24

## API22 qualification follow-up

**RUNTIME TEST UNAVAILABLE; STATIC EVIDENCE ONLY. Target backend remains DEFER, not TARGET-QUALIFIED.** No local API22 runtime/image exists in the inventoried locations. [Differential](API22-PROVIDER-DIFFERENTIAL.md) checks24 anchors/20DEX methods and adds10000 host-model sequences. Handshake sink cursor analysis narrows the prior byte-count concern; close output/free ordering and inboundDone-vs-CLOSED mapping remain concerns. Actual AndroidOpenSSL body-completion profile remains disabled. No production workaround or native backend was added. These static close concerns are not a demonstrated core encrypt/decrypt failure and do not by themselves justify replacing Java. Next action is a bounded isolated API22 runtime probe when a local image becomes available. No broad redesign is needed meanwhile.

**JAVA sufficient for current desktop memory-TLS contract; target deployment decision DEFER.** No native prototype built. The conditional native branch was not triggered by a demonstrated desktop contract gap.

|Criterion|Java current evidence|Clean bundled native candidate|
|---|---|---|
|Correctness/contract|Real loopback, negative trust, exact recovery, partial progress, close PASS WITH LIMITATIONS|Not built; cannot award a pass|
|API22/ARMv7|Java7/D8min22 and method surface checked; provider runtime untested; portable bytecode needs no native ABI|Requires pinned source, NDK ARMv7/API21-22 and load tests|
|Buffer/residual visibility|Public engine opaque; strict record ledger and SunJSSE completion profile|Memory BIO/internal controls potentially more visible, still needs tests|
|Close semantics|Desktop close_notify retained; API22 uncertain|Explicit native pump possible, untested|
|Client auth|Disposable mutual auth PASS|Expected capability only until implemented|
|Build/binary/JNI|Existing JDK/public APIs; no extra native library, JNI or measured size claim|New toolchain, native binary size and JNI lifetime burden|
|Licensing/maintenance|No copied provider implementation or new dependency|Exact version/license/update policy must be reviewed|
|Portability|Provider-specific completion qualification remains necessary|Bundled version reduces provider variance but adds platform/ABI work|

Use Java host tests as the common conformance suite before any backend replacement. If saved API22 provider cannot satisfy completion/close without hidden APIs, justify a clean bundled native prototype then. Do not default to old system libssl/libcrypto or Honda JNI merely because symbols exist. No substantial AGPL implementation code was copied.

Real host TLS is not Android Auto authentication. It leaves real phone credentials/trust/version acceptance, M5 permission, M6 AOA/ownership, stock-AA contention, service acceptance, packet/AU boundaries, target decoding and display unproved. Next LIVE M5 RETRY ONLY; M6 disabled; no later task is authorized by this decision.
