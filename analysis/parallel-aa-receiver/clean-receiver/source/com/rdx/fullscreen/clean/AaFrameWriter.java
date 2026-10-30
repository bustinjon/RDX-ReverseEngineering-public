package com.rdx.fullscreen.clean;
/** Pure byte serialization only: no transport ownership or write. */
public final class AaFrameWriter {
 public byte[] encode(AaFrame f){
  byte[] body=f.body();boolean total=(f.flags&AaFrame.FIRST)!=0&&(f.flags&AaFrame.LAST)==0;
  int header=total?8:4;byte[] out=new byte[header+body.length];out[0]=(byte)f.channel;out[1]=(byte)f.flags;out[2]=(byte)(body.length>>>8);out[3]=(byte)body.length;
  if(total){int n=f.totalPlaintextLength;for(int i=0;i<4;i++)out[4+i]=(byte)(n>>>(24-8*i));}
  System.arraycopy(body,0,out,header,body.length);return out;
 }
}
