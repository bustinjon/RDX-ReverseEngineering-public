package com.rdx.fullscreen.clean;
public final class DeviceIdentity {
 public final String path;public final int vid,pid;public final boolean permission;
 public DeviceIdentity(String p,int vendor,int product,boolean authorized){if(p==null||p.length()==0||vendor<0||vendor>65535||product<0||product>65535)throw new IllegalArgumentException("Device identity");path=p;vid=vendor;pid=product;permission=authorized;}
}
