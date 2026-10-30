package com.rdx.fullscreen.clean;
/** Narrow payload inspection only. Setup field1 semantics/direction remain disputed. */
public final class MediaControlMessages {
 public static final int SETUP=0x8000,START=0x8001,STOP=0x8002,SETUP_RESPONSE=0x8003,ACK=0x8004,FOCUS_REQUEST=0x8007,FOCUS_INDICATION=0x8008;
 private MediaControlMessages(){}
 public static final class Value {
  public final int type;public final long field1,field2;public final boolean hasField1;private final byte[] raw;
  private Value(int t,long a,long b,boolean present,byte[] bytes){type=t;field1=a;field2=b;hasField1=present;raw=bytes.clone();}
  public byte[] encode(){return raw.clone();}
 }
 public static Value parse(int type,byte[] bytes){
  ProtoWire.Message m=ProtoWire.parse(bytes);long a=-1,b=-1;boolean has=m.has(1);
  if(type==SETUP){a=m.scalar(1,false,-1);if(has)ProtoWire.boundedInt(a,0,Integer.MAX_VALUE);}
  else if(type==START){a=m.scalar(1,true,0);b=m.scalar(2,true,0);ProtoWire.boundedInt(a,0,Integer.MAX_VALUE);ProtoWire.boundedInt(b,0,ProtocolLimits.VIDEO_CONFIGS-1);}
  else if(type==ACK){a=m.scalar(1,true,0);b=m.scalar(2,true,0);ProtoWire.boundedInt(a,0,Integer.MAX_VALUE);ProtoWire.boundedInt(b,1,32);}
  else if(type!=STOP)throw new IllegalArgumentException("UNKNOWN_MEDIA_PAYLOAD; not guessed");
  return new Value(type,a,b,has,bytes);
 }
 public static byte[] start(int session,int config){byte[] b=new ProtoWire.Writer().uint32(1,session).uint32(2,config).finish();parse(START,b);return b;}
 public static byte[] ack(int session,int count){byte[] b=new ProtoWire.Writer().uint32(1,session).uint32(2,count).finish();parse(ACK,b);return b;}
}
