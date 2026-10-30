package com.rdx.fullscreen.clean;
/** Production default: never loads credentials, cryptography or a socket. */
public final class DisabledTlsAdapter implements TlsAdapter {
 public DisabledTlsAdapter(){}
 public void startHandshake(){throw new UnsupportedOperationException("Real TLS disabled");}
 public byte[] wrap(byte[] b){throw new UnsupportedOperationException("Real TLS disabled");}
 public byte[] unwrap(byte[] b){throw new UnsupportedOperationException("Real TLS disabled");}
 public void close(){}public boolean established(){return false;}
}
