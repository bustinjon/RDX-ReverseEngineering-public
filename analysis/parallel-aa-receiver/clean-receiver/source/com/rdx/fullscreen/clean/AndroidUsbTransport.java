package com.rdx.fullscreen.clean;
/** Deliberately disabled: no openDevice/claim/transfer implementation before ownership evidence. */
public final class AndroidUsbTransport implements UsbTransport {
 public AndroidUsbTransport(){}
 public void open(DeviceIdentity d){throw new UnsupportedOperationException("USB ownership stage disabled");}
 public int read(byte[] b,int timeout){throw new UnsupportedOperationException("Transport disabled");}
 public int write(byte[] b,int timeout){throw new UnsupportedOperationException("Transport disabled");}
 public void close(){}
}
