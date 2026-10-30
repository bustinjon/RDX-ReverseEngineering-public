package com.rdx.fullscreen.m6aoa;
/** Observation, not proof of physical continuity. Optional serial is hashed by caller. */
public final class UsbIdentity {
 public enum Kind {NORMAL_PHONE,ACCESSORY,UNKNOWN,NON_TARGET}
 public final int vendorId,productId,deviceId,interfaces;public final String path,endpoints,serialHash;public final long generation,observedAt;
 public UsbIdentity(int v,int p,int id,String name,int count,String summary,String serial,long gen,long time){
  if(v<0||v>65535||p<0||p>65535||id<0||name==null||name.length()>160||!name.matches("[A-Za-z0-9/_:.-]+")||count<0||count>32||summary==null||summary.length()>512||serial==null||!(serial.equals("-")||serial.matches("[0-9a-f]{64}"))||gen<1||time<0)throw new IllegalArgumentException("Device metadata");
  vendorId=v;productId=p;deviceId=id;path=name;interfaces=count;endpoints=summary;serialHash=serial;generation=gen;observedAt=time;
 }
 public Kind kind(){if(vendorId==0x18d1)return accessoryPid(productId)?Kind.ACCESSORY:Kind.UNKNOWN;if(vendorId==0x22d9)return productId==0x2769||productId==0x2765?Kind.NORMAL_PHONE:Kind.UNKNOWN;return Kind.NON_TARGET;}
 public static boolean accessoryPid(int p){return p==0x2d00||p==0x2d01||p==0x2d04||p==0x2d05;}
 public boolean sameAttachment(UsbIdentity d){return d!=null&&vendorId==d.vendorId&&productId==d.productId&&deviceId==d.deviceId&&generation==d.generation&&path.equals(d.path);}
 public String key(){return vendorId+":"+productId+":"+deviceId+":"+generation+":"+path;}
}
