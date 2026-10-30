package com.rdx.fullscreen.clean;
public interface UsbTransport { void open(DeviceIdentity device); int read(byte[] output,int timeoutMs); int write(byte[] input,int timeoutMs); void close(); }
