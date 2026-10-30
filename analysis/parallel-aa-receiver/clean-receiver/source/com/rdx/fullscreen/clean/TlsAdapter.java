package com.rdx.fullscreen.clean;
/** Boundary only. Caller must associate streaming TLS plaintext with AAP fragment metadata. */
public interface TlsAdapter {
 void startHandshake();byte[] wrap(byte[] plaintext);byte[] unwrap(byte[] ciphertext);void close();boolean established();
}
