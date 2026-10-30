package com.rdx.fullscreen.clean;
import java.io.ByteArrayOutputStream;
import java.io.UnsupportedEncodingException;
import java.nio.ByteBuffer;
import java.nio.charset.*;
import java.util.*;
/** Independently authored bounded protobuf wire subset (0/1/2/5). Groups explicitly unsupported. */
public final class ProtoWire {
 private ProtoWire(){}
 public static final class Field {
  public final int number,wire;public final long value;private final byte[] data,encoded;
  private Field(int n,int w,long v,byte[] b,byte[] raw){number=n;wire=w;value=v;data=b;encoded=raw;}
  public byte[] bytes(){if(wire!=2)throw new IllegalArgumentException("Expected length-delimited field");return data.clone();}
  public byte[] encoded(){return encoded.clone();}
 }
 public static final class Message {
  private final List<Field> fields;
  private Message(List<Field> f){fields=Collections.unmodifiableList(f);}
  public List<Field> fields(){return fields;}
  /** Lossless supported-wire passthrough, including unknown fields/order/nonminimal varints. */
  public byte[] encoded(){ByteArrayOutputStream out=new ByteArrayOutputStream();for(Field f:fields)out.write(f.encoded,0,f.encoded.length);return out.toByteArray();}
  /** Explicit codec adapters may retain unknowns without pretending to understand their semantics. */
  public byte[] unknownFields(int... known){ByteArrayOutputStream out=new ByteArrayOutputStream();for(Field f:fields){boolean matched=false;for(int n:known)if(f.number==n){matched=true;break;}if(!matched)out.write(f.encoded,0,f.encoded.length);}return out.toByteArray();}
  public boolean has(int n){for(Field f:fields)if(f.number==n)return true;return false;}
  /** Singular protobuf fields use the last occurrence. Wrong wire types are rejected by this strict subset. */
  public Field field(int n,int wire,boolean required){Field out=null;for(Field f:fields)if(f.number==n){if(f.wire!=wire)throw new IllegalArgumentException("Wrong known-field wire type");out=f;}if(out==null&&required)throw new IllegalArgumentException("Missing required field "+n);return out;}
  public long scalar(int n,boolean required,long fallback){Field f=field(n,0,required);return f==null?fallback:f.value;}
  public byte[] bytes(int n,boolean required){Field f=field(n,2,required);return f==null?null:f.bytes();}
  public List<byte[]> repeatedBytes(int n,int max){List<byte[]> out=new ArrayList<byte[]>();for(Field f:fields)if(f.number==n){if(f.wire!=2||out.size()>=max)throw new IllegalArgumentException("Repeated field type/count");out.add(f.bytes());}return out;}
 }
 private static long varint(byte[] b,int[] p){long out=0;for(int i=0;i<10;i++){if(p[0]>=b.length)throw new IllegalArgumentException("Truncated varint");int v=b[p[0]++]&255;if(i==9&&(v&254)!=0)throw new IllegalArgumentException("Varint overflow");out|=(long)(v&127)<<(i*7);if((v&128)==0)return out;}throw new IllegalArgumentException("Unterminated varint");}
 public static Message parse(byte[] b){
  if(b==null||b.length>ProtocolLimits.PROTO_BYTES)throw new IllegalArgumentException("Protobuf byte limit");
  List<Field> fields=new ArrayList<Field>();int[] p={0};
  while(p[0]<b.length){
   if(fields.size()>=ProtocolLimits.PROTO_FIELDS)throw new IllegalArgumentException("Protobuf field limit");
   int start=p[0];long key=varint(b,p);if(key<8||key>0xffffffffL)throw new IllegalArgumentException("Invalid field tag");int n=(int)(key>>>3),w=(int)(key&7);long v=0;byte[] data=null;
   if(w==0)v=varint(b,p);
   else if(w==2){long length=varint(b,p);if(length<0||length>b.length-p[0])throw new IllegalArgumentException("Length overflow/truncation");data=Arrays.copyOfRange(b,p[0],p[0]+(int)length);p[0]+=(int)length;}
   else if(w==1||w==5){int length=w==1?8:4;if(length>b.length-p[0])throw new IllegalArgumentException("Truncated fixed field");for(int i=0;i<length;i++)v|=(long)(b[p[0]++]&255)<<(i*8);}
   else throw new IllegalArgumentException("Unsupported group/invalid wire type");
   fields.add(new Field(n,w,v,data,Arrays.copyOfRange(b,start,p[0])));
  }
  return new Message(fields);
 }
 public static int boundedInt(long v,int min,int max){if(v<min||v>max)throw new IllegalArgumentException("Integer range");return (int)v;}
 public static String text(byte[] bytes){if(bytes==null||bytes.length>ProtocolLimits.STRING_BYTES)throw new IllegalArgumentException("String length");try{return Charset.forName("UTF-8").newDecoder().onMalformedInput(CodingErrorAction.REPORT).onUnmappableCharacter(CodingErrorAction.REPORT).decode(ByteBuffer.wrap(bytes)).toString();}catch(CharacterCodingException e){throw new IllegalArgumentException("Invalid UTF8",e);}}
 public static final class Writer {
  private final ByteArrayOutputStream out=new ByteArrayOutputStream();private int fields;
  private void octet(int v){if(out.size()>=ProtocolLimits.PROTO_BYTES)throw new IllegalArgumentException("Protobuf output limit");out.write(v);}
  private void rawVarint(long value){do{int b=(int)(value&127);value>>>=7;octet(b|(value!=0?128:0));}while(value!=0);}
  private void tag(int field,int wire){if(field<1||field>0x1fffffff||fields>=ProtocolLimits.PROTO_FIELDS)throw new IllegalArgumentException("Field/count limit");fields++;rawVarint(((long)field<<3)|wire);}
  public Writer scalar(int field,long value){tag(field,0);rawVarint(value);return this;}
  public Writer uint32(int field,long value){if(value<0||value>0xffffffffL)throw new IllegalArgumentException("uint32 range");return scalar(field,value);}
  public Writer sint32(int field,int value){return scalar(field,((long)value<<1 ^ (value>>31))&0xffffffffL);}
  public Writer bytes(int field,byte[] value){if(value==null||value.length>ProtocolLimits.PROTO_BYTES)throw new IllegalArgumentException("Bytes limit");tag(field,2);rawVarint(value.length);if(value.length>ProtocolLimits.PROTO_BYTES-out.size())throw new IllegalArgumentException("Protobuf output limit");out.write(value,0,value.length);return this;}
  public Writer text(int field,String value){if(value==null)throw new IllegalArgumentException("Null string");try{byte[] b=value.getBytes("UTF-8");if(b.length>ProtocolLimits.STRING_BYTES)throw new IllegalArgumentException("String limit");return bytes(field,b);}catch(UnsupportedEncodingException e){throw new IllegalStateException(e);}}
  public byte[] finish(){return out.toByteArray();}
 }
}
