package com.rdx.fullscreen.projection;
public class UsbBulkTransport {
 public int closes;public UsbBulkTransport(android.hardware.usb.UsbManager m,android.hardware.usb.UsbDevice d){}
 public void readFully(byte[] b,int offset,int count)throws java.io.IOException{throw new java.io.IOException("injected disconnect");}
 public void write(byte[] b,int n){}public void close(){closes++;}
}
