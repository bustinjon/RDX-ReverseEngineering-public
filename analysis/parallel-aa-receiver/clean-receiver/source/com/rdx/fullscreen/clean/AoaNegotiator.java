package com.rdx.fullscreen.clean;
import java.io.UnsupportedEncodingException;
/** Pure request planning/encoding, execution permanently disabled in this revision. */
public final class AoaNegotiator {
 public static final boolean EXECUTION_ENABLED=false;
 public static final int QUERY=51,IDENTIFY=52,START=53,QUERY_TYPE=0xC0,OUT_TYPE=0x40;
 public AoaNegotiator(){}
 public AoaRequestPlan planQuery(){return new AoaRequestPlan(QUERY_TYPE,QUERY,0,0,2,new byte[0]);}
 public AoaRequestPlan planIdentity(int index,String value){if(index<0||index>5)throw new IllegalArgumentException("Identity index");return new AoaRequestPlan(OUT_TYPE,IDENTIFY,0,index,0,identificationBytes(value));}
 public AoaRequestPlan planStart(){return new AoaRequestPlan(OUT_TYPE,START,0,0,0,new byte[0]);}
 public byte[] identificationBytes(String value){if(value==null||value.indexOf(0)>=0)throw new IllegalArgumentException("Invalid identity string");try{byte[] b=value.getBytes("UTF-8");if(b.length>255)throw new IllegalArgumentException("Identity too long");byte[] nul=new byte[b.length+1];System.arraycopy(b,0,nul,0,b.length);return nul;}catch(UnsupportedEncodingException e){throw new IllegalStateException(e);}}
 public int queryVersion(UsbTransport t){throw new UnsupportedOperationException("AOA execution disabled");}
 public void sendIdentity(UsbTransport t,String[] identity){throw new UnsupportedOperationException("AOA execution disabled");}
 public void start(UsbTransport t){throw new UnsupportedOperationException("AOA execution disabled");}
}
