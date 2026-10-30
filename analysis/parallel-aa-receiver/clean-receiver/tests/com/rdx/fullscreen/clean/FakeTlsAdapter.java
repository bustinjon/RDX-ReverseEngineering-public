package com.rdx.fullscreen.clean;
/** HOST TEST ONLY: identity transform, NO SECURITY and no TLS records. Never shipped in library. */
public final class FakeTlsAdapter implements TlsAdapter {
 private boolean active;
 public void startHandshake(){if(active)throw new IllegalStateException("Duplicate fake handshake");active=true;}
 public byte[] wrap(byte[] bytes){if(!active)throw new IllegalStateException("Fake not active");return bytes.clone();}
 public byte[] unwrap(byte[] bytes){return wrap(bytes);}
 public void close(){active=false;}public boolean established(){return active;}
}
