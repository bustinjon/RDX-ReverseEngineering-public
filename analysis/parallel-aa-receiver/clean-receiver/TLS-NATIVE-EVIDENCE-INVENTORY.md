# Native TLS evidence inventory

Primary local binary: analysis/parallel-aa-receiver/libs/armeabi-v7a/libautoreceiver_jni.so; SHA256 031797DD4B0AECCA007A3AD7AF31C365BA3D47BEBDA8C94BFF13C5289F464C50. Never executed.

Saved evidence directory: tls-association-evidence/. disassemble.ps1 uses local RdxElf.cs/LLVM; resolve.ps1 resolves Thumb calls/PC-relative strings. *.hex, *.asm, *.annotated.txt, *.resolved.txt, calls-resolved.json and relocations preserve source-level provenance. Literal pools are sometimes printed as instructions; warnings after real function returns must NOT be treated as code. Veneers switch Thumb->ARM; resolve those explicitly rather than interpreting ARM words as Thumb.

|Address|Function|Use|
|---|---|---|
|CDF42|ChannelManager::messageToFrames|Plaintext fragment size and flag construction|
|CDB70|ChannelManager::encodeFrame|Body encryption; plaintext outer header|
|CDD7C|ChannelManager::decodeFrame|Retained metadata; repeated body plaintext drain|
|CE6C0|ChannelManager::queueIncoming|Decryption precedes routing/reassembly|
|CE37E|ChannelManager::checkFragment|Per-channel fragment state; nonzero service channels require ENCRYPTED|
|CE544|ChannelManager::framesToMessage|Aggregate plaintext length checks|
|CBE2C/CBE88|SslWrapper encryption enqueue/dequeue|SSL_write / BIO_read|
|CBEB0/CBEE0|SslWrapper decryption enqueue/dequeue|BIO_write / SSL_read, WANT_READ mapping|
|CBC18|SslWrapper::handshake|Memory BIO handshake carrier0003|
|CBD08|SslWrapper::verifyPeer|Separate certificate verification|
|CD7B2-CD7CE|Controller handshake completion|Verify then install shared wrapper, send auth|
|CCDE0 /17ECB0|Unencrypted send helper/veneer|Resolves AD6E8 queueOutgoingUnencrypted|
|CD16C|Controller::sendAuthResponse|Type0004 -> explicit unencrypted helper|
|CC43A / C5A5C|Ordinary outgoing helper|Encrypted body path|
|CE238|ChannelManager::sendFramingError|Terminal framing notification/callback|

Java: decompiled/AndroidAuto-current/sources/com/google/android/projection/protocol/InputOutputThreads.java reads4 header bytes, obtains remaining size, queues a whole outer frame; GalReceiver.java nativeSetCreds and callback/stop chain. Public references are the saved offline-followup/public AASDK046b3b3, OpenHeadunit e9377ff and OpenAndroidAuto61eab61. References used as behavioral comparison only; no AGPL/GPL implementation copied.

The final helper/veneer validation and saved-log comparison continued read-only after interruption; those conclusions are now persisted in the companion review. No additional broad native investigation was needed for this implementation.
