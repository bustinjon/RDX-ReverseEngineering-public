package com.rdx.fullscreen.clean;
import java.util.*;
/** Independent HOST oracle. No production parser/writer/body-stage/constants/adapter imports. */
public final class SecureBodyOracle {
 public static List<byte[]> frames(int channel,int semantic,byte[] logical,int padding,boolean encrypted){
  List<byte[]> result=new ArrayList<byte[]>();int offset=0;
  while(offset<logical.length){int n=Math.min(16128,logical.length-offset),flags=semantic+(encrypted?8:0)+(offset==0?1:0)+(offset+n==logical.length?2:0);boolean ext=(flags&3)==1;int body=n+(encrypted?padding:0),head=ext?8:4;
   if(body>65535)throw new IllegalArgumentException("Oracle body");byte[] raw=new byte[head+body];raw[0]=(byte)channel;raw[1]=(byte)flags;raw[2]=(byte)(body/256);raw[3]=(byte)body;
   if(ext){long total=logical.length;raw[4]=(byte)(total/16777216L);raw[5]=(byte)(total/65536L);raw[6]=(byte)(total/256L);raw[7]=(byte)total;}
   int dest=head;if(encrypted){for(int i=0;i<padding;i++)raw[dest++]=(byte)165;}for(int i=0;i<n;i++)raw[dest+i]=logical[offset+i];offset+=n;result.add(raw);
  }return result;
 }
 public static byte[] decode(List<byte[]> frames,int padding){
  java.io.ByteArrayOutputStream out=new java.io.ByteArrayOutputStream();int channel=-1,total=-1;boolean ended=false;
  for(int i=0;i<frames.size();i++){byte[] f=frames.get(i);if(f.length<4)throw new IllegalArgumentException("Oracle header");int c=f[0]&255,flags=f[1]&255,body=(f[2]&255)*256+(f[3]&255),head=(flags&3)==1?8:4;
   if(f.length!=head+body||channel>=0&&c!=channel||ended)throw new IllegalArgumentException("Oracle framing");channel=c;
   if(i==0&&(flags&1)==0||i>0&&(flags&1)!=0)throw new IllegalArgumentException("Oracle fragment order");
   if(head==8)total=(f[4]&255)*16777216+(f[5]&255)*65536+(f[6]&255)*256+(f[7]&255);
   int prefix=(flags&8)!=0?padding:0;if(body<prefix)throw new IllegalArgumentException("Oracle short body");for(int p=0;p<prefix;p++)if((f[head+p]&255)!=165)throw new IllegalArgumentException("Oracle prefix");
   out.write(f,head+prefix,body-prefix);ended=(flags&2)!=0;
  }
  if(!ended||total!=-1&&total!=out.size())throw new IllegalArgumentException("Oracle aggregate");return out.toByteArray();
 }
}
