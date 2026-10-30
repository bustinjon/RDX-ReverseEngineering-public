# Secure body implementation plan and evidence boundary

1. Immutable outer metadata, raw ciphertext and decrypted-fragment types.
2. Bounded SecureBodyAdapter contract: synthetic handshake pumping, body encryption/decryption progress, terminal close/error, reset.
3. Parse outer first. Keep channel/flags/logical total independent of ciphertext length. Drain only within the same retained context. NEED_MORE_CIPHERTEXT for a completely received body terminates as BODY_DECRYPT_INCOMPLETE (local conservative policy; Honda recovery UNKNOWN).
4. Reassemble only plaintext fragments. Preserve per-channel concurrency. CONTROL requires FIRST+LAST. Outbound split plaintext at16128 before transformation, encode actual transformed body length afterward.
5. Explicit synthetic handshake, verification and installation states. Plaintext startup0001/0002/0003 and confirmed0004 exception. Ordinary established application traffic encrypted.
6. Host fake adapter and independent oracle. Expansion, delayed zero output, multiple chunks, closure, failure, residual and renegotiation scenarios. No crypto or credentials.
7. Integrate existing host discovery/media engine and fake decoder through explicit seams; old plaintext harness retained. No phone/AU/decoder acceptance claims.
8. Java7, D8min22, savedAPI22 reference audit, two clean build comparisons and protected-artifact verification.

Still UNKNOWN: cross-frame record attribution/recovery, real adapter WANT_WRITE/output/control handling, target renegotiation/closure, credential acceptance, actual phone packet/AU boundaries and runtime transport ownership. Those gaps must not be filled by successful fake transformations.
