package com.rdx.fullscreen.m6aoa;
/** Host-testable boundary. Constructors must not enumerate, open or request permission. */
public interface AndroidUsbEnvironment {
 enum Status {ACCEPTED,REJECTED,TIMEOUT,ERROR}
 final class Result {
  public final Status status;public final int returned;public final long durationMs;private final byte[] data;
  public Result(Status s,int n,byte[] b,long d){if(s==null||b==null||b.length>256||d<0)throw new IllegalArgumentException("Transfer result");status=s;returned=n;data=b.clone();durationMs=d;}
  public byte[] data(){return data.clone();}
 }
 long now();long wall();UsbIdentity[] inventory()throws Exception;
 boolean hasPermission(UsbIdentity d)throws Exception;
 void requestPermission(UsbIdentity d,String nonce)throws Exception;
 void open(UsbIdentity d)throws Exception;
 Result transfer(AoaRequest request)throws Exception;
 void close();
}
