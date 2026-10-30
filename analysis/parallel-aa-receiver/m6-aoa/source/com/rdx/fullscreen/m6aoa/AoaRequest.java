package com.rdx.fullscreen.m6aoa;
import java.io.UnsupportedEncodingException;
/** Immutable endpoint-zero requests only. No transfer submission or configurable opcode. */
public final class AoaRequest {
 public final int type,code,value,index,length; private final byte[] bytes;
 private AoaRequest(int t,int c,int i,byte[] b,int n){type=t;code=c;value=0;index=i;bytes=b.clone();length=n;}
 public static AoaRequest protocol(){return new AoaRequest(192,51,0,new byte[2],2);}
 public static AoaRequest start(){return new AoaRequest(64,53,0,new byte[0],0);}
 public static AoaRequest string(int index,String text){
  if(index<0||index>5||text==null||text.indexOf(0)>=0)throw new IllegalArgumentException("AOA string");
  for(int p=0;p<text.length();p++){char c=text.charAt(p);if(Character.isHighSurrogate(c)){if(++p>=text.length()||!Character.isLowSurrogate(text.charAt(p)))throw new IllegalArgumentException("Unicode");}else if(Character.isLowSurrogate(c))throw new IllegalArgumentException("Unicode");}
  try{byte[] b=text.getBytes("UTF-8");if(b.length>255)throw new IllegalArgumentException("String policy255");byte[] n=new byte[b.length+1];System.arraycopy(b,0,n,0,b.length);return new AoaRequest(64,52,index,n,n.length);}catch(UnsupportedEncodingException e){throw new IllegalStateException(e);}
 }
 public byte[] payload(){return bytes.clone();}
 public static String[] identity(String run){if(!run.matches("[A-Za-z0-9_-]{8,64}"))throw new IllegalArgumentException("Run id");String[] a={"RDX Research","Clean Receiver","Bounded AOA M6 Test","M6-0.1","",run};validateIdentity(a);return a;}
 public static void validateIdentity(String[] values){if(values==null||values.length!=6)throw new IllegalArgumentException("Exactly six indexed strings");for(int i=0;i<6;i++){if(values[i]==null||i!=4&&values[i].length()==0)throw new IllegalArgumentException("Missing local required string");string(i,values[i]);}}
 public static int version(byte[] response,int returned){if(response==null||returned!=2||response.length!=2)throw new IllegalArgumentException("Protocol reply length");return (response[0]&255)|((response[1]&255)<<8);}
}
