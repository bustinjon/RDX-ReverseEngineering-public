package com.rdx.fullscreen.clean;
public final class AaFrame {
 public static final int FIRST=1,LAST=2,CONTROL=4,ENCRYPTED=8;
 public final int channel,flags,totalPlaintextLength;private final byte[] body;
 public AaFrame(int c,int f,int total,byte[] b){
  if(c<0||c>255||(f&~15)!=0||f<0||b==null||b.length>65535)throw new IllegalArgumentException("Frame bounds/flags");
  boolean needs=(f&FIRST)!=0&&(f&LAST)==0;
  if(needs?total<2:total!=-1)throw new IllegalArgumentException("First-fragment total field");
  channel=c;flags=f;totalPlaintextLength=total;body=b.clone();
 }
 public byte[] body(){return body.clone();}
 public int bodyLength(){return body.length;}
}
