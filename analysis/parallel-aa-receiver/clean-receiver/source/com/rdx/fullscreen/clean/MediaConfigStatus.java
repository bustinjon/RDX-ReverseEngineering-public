package com.rdx.fullscreen.clean;
/** Honda Config domain, deliberately separate from general control success=0. */
public enum MediaConfigStatus {
 STATUS_WAIT(1), STATUS_READY(2);
 public final int wire;
 MediaConfigStatus(int value){wire=value;}
 public static MediaConfigStatus fromWire(long value){
  return value==1?STATUS_WAIT:value==2?STATUS_READY:null;
 }
}
