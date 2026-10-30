# Honda TLS/plaintext association — completed synthesis, saved 2026-10-24

M4 PASS. Original M5 timing-INCONCLUSIVE. Frozen M5 retry READY; next LIVE is M5 RETRY ONLY. M6 disabled. M7 offline foundation only.

CONFIRMED target path: outbound logical plaintext message -> plaintext fragments -> encrypt BODY -> plaintext AA header -> transport. Inbound plaintext outer header -> body decryption with retained metadata -> plaintext fragment reassembly -> message dispatch. TLS does not wrap the whole AA header stream.

ChannelManager::messageToFrames 0xCDF42 splits at 0x3F00 plaintext bytes, assigns FIRST/LAST, CONTROL and ENCRYPTED independently. encodeFrame 0xCDB70 invokes encryptionPipelineEnqueue and drains BIO ciphertext before writing channel, flags, BE16 ciphertext length and optional BE32 logical plaintext total. decodeFrame 0xCDD7C reads this metadata, feeds only the body to the shared SslWrapper, repeatedly drains plaintext and updates the internal plaintext length. queueIncoming 0xCE6C0 decrypts before checkFragment/reassembly. framesToMessage 0xCE544 checks the aggregate against FIRST's plaintext total.

One normal outbound fragment invokes one SSL_write; this is NOT a guarantee of one TLS record. A received body can produce multiple SSL_read outputs. Cross-outer-frame incomplete TLS-record attribution is UNKNOWN: memory BIO retention alone does not preserve ownership of delayed plaintext. The future clean adapter must reject/classify incomplete body attribution rather than move output to a later channel/frame.

Startup: plaintext Version Request/Response -> HU TLS client handshake via plaintext channel0 type0003 -> SSL_do_handshake=1 -> separate verifyPeer -> install wrapper -> plaintext type0004 AuthResponse -> encrypted ordinary discovery. AuthResponse uses the unnamed helper0xCCDE0 and veneer0x17ECB0 resolving to MessageRouter::queueOutgoingUnencrypted. Therefore 'everything after handshake is encrypted' is incorrect for this target.

Credentials: Java constructor passes root/client/key strings -> nativeSetCreds -> Controller::setClientCreds -> SslWrapper::init; TLSv1_2_client_method, memory BIOs, certificate/key loading. verifyPeer checks CarService name and chain. No credential bytes are reproduced or loaded here. APK signer and protocol credentials are distinct.

Saved runtime corroboration: m5-live-20261023-173401-872/20261023-174820-196-final-logcat.stdout.txt:27985 onward:17:42:59.837 version1.7; .873 handshake success and TLSv1.2/ECDHE-RSA-AES128-GCM-SHA256; .874 verify ok; .878 discovery callback. Internal SSLv3 state labels do not mean negotiated SSLv3. No packet boundaries can be inferred from these logs.

Failure: WANT_READ becomes zero drain; other negative SSL_read and nonpositive SSL_write fail. Framing failure disables normal incoming processing, queues plaintext FFFF notification and calls unrecoverableError. Reviewed shutdown frees resources; graceful close_notify, rekey/renegotiation and robust cross-frame underflow recovery remain UNKNOWN. A clean implementation should distinguish CLEAN_CLOSE, NEED_MORE, NO_OUTPUT and ERROR even where Honda conflates zero results.

AASDK agrees on header visibility and encrypt-after-fragmentation; its interwoven-channel prohibition is stricter than Honda's per-channel incoming state. Open Headunit agrees on multiple unwraps per body but explicitly rejects underflow inside a received body. That is a clean policy, not proof of Honda semantics. Saved Open Android Auto docs contain header/flag and post-handshake encryption simplifications contradicted by Honda code.

The old PlaintextVideoBridge remains a synthetic whole-frame harness. Real TLS plaintext must enter after outer parsing, with retained metadata, before reassembly. No live transport, phone compatibility, real authentication, decoder or display result follows from this analysis.
