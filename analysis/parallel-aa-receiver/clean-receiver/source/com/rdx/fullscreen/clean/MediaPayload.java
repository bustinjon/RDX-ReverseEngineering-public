package com.rdx.fullscreen.clean;
import java.util.Arrays;
/** Confirmed Honda envelope only; no AU/NAL/clock-unit assumptions. */
public final class MediaPayload {
 public static final int DATA=0,CONFIG=1,MAX=1048574; // 1MiB logical message less BE16 type
 public static final class Timestamp {
  public final long unsignedBits;public final String unit="UNKNOWN";
  public Timestamp(long bits){unsignedBits=bits;}
 }
 public final int type;public final Timestamp timestamp;private final byte[] data;
 private MediaPayload(int t,Timestamp ts,byte[] b){type=t;timestamp=ts;data=b.clone();}
 public byte[] bytes(){return data.clone();}
 public static MediaPayload parse(int type,byte[] payload){
  if(payload==null||payload.length>MAX)throw new IllegalArgumentException("Media bound");
  if(type==CONFIG)return new MediaPayload(type,null,payload);
  if(type!=DATA||payload.length<8)throw new IllegalArgumentException("Unknown/truncated media envelope");
  long bits=0;for(int i=0;i<8;i++)bits=(bits<<8)|(payload[i]&255L);
  return new MediaPayload(type,new Timestamp(bits),Arrays.copyOfRange(payload,8,payload.length));
 }
 public static byte[] encodeData(Timestamp t,byte[] opaque){
  if(t==null||opaque==null||opaque.length>MAX-8)throw new IllegalArgumentException("Media bound");
  byte[] b=new byte[8+opaque.length];long bits=t.unsignedBits;for(int i=7;i>=0;i--){b[i]=(byte)bits;bits>>>=8;}System.arraycopy(opaque,0,b,8,opaque.length);return b;
 }
}
