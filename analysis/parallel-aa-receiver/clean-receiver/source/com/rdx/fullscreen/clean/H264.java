package com.rdx.fullscreen.clean;
import java.util.*;
import java.io.ByteArrayOutputStream;
/** Bounded AnnexB inspection. NOT a decoder or arbitrary slice-to-AU assembler. */
public final class H264 {
 private H264(){}
 public static final int MAX=1048576,MAX_NALS=256;
 public static final class Nal {
  public final int type;private final byte[] raw;
  private Nal(byte[] b){if(b.length==0||(b[0]&128)!=0)throw new IllegalArgumentException("NAL header");raw=b.clone();type=b[0]&31;if(type==0||type>23)throw new IllegalArgumentException("Unsupported NAL type");}
  public byte[] bytes(){return raw.clone();}
 }
 private static int start(byte[] b,int p){if(p+3<=b.length&&b[p]==0&&b[p+1]==0){if(b[p+2]==1)return 3;if(p+4<=b.length&&b[p+2]==0&&b[p+3]==1)return 4;}return 0;}
 public static List<Nal> annexB(byte[] b){
  if(b==null||b.length==0||b.length>MAX||start(b,0)==0)throw new IllegalArgumentException("AnnexB bound/start");
  List<Nal> out=new ArrayList<Nal>();int p=0;
  while(p<b.length){int n=start(b,p);if(n==0)throw new IllegalArgumentException("Start code");int a=p+n,end=a;while(end<b.length&&start(b,end)==0)end++;
   if(out.size()>=MAX_NALS||end==a)throw new IllegalArgumentException("NAL count/empty");out.add(new Nal(Arrays.copyOfRange(b,a,end)));p=end;
  }return Collections.unmodifiableList(out);
 }
 public static byte[] fromLengthPrefixed(byte[] b,int size){
  if(b==null||b.length>MAX||size<1||size>4)throw new IllegalArgumentException("AVCC bounds");
  ByteArrayOutputStream out=new ByteArrayOutputStream();int p=0,count=0;
  while(p<b.length){if(b.length-p<size||++count>MAX_NALS)throw new IllegalArgumentException("NAL prefix/count");long len=0;for(int i=0;i<size;i++)len=(len<<8)|(b[p++]&255L);
   if(len<1||len>b.length-p||len>MAX-out.size()-4)throw new IllegalArgumentException("NAL length");out.write(0);out.write(0);out.write(0);out.write(1);out.write(b,p,(int)len);p+=(int)len;
  }byte[] result=out.toByteArray();annexB(result);return result;
 }
 private static final class Bits {
  private final byte[] b;private int bit;
  Bits(byte[] nal){ByteArrayOutputStream out=new ByteArrayOutputStream();int zeros=0;for(int i=1;i<nal.length;i++){int v=nal[i]&255;if(zeros>=2&&v==3){if(i+1>=nal.length||(nal[i+1]&255)>3)throw new IllegalArgumentException("RBSP escape");zeros=0;continue;}out.write(v);zeros=v==0?zeros+1:0;}b=out.toByteArray();}
  int read(int n){if(n<0||n>31||n>b.length*8-bit)throw new IllegalArgumentException("Truncated RBSP");int v=0;while(n-->0){v=(v<<1)|((b[bit/8]>>(7-bit%8))&1);bit++;}return v;}
  int ue(){int zeros=0;while(read(1)==0)if(++zeros>24)throw new IllegalArgumentException("ExpGolomb bound");return (1<<zeros)-1+read(zeros);}
  int se(){int v=ue();return (v&1)==0?-(v/2):(v+1)/2;}
 }
 public static final class Sps {
  public final int id,profile,level,codedWidth,codedHeight,width,height,cropLeft,cropRight,cropTop,cropBottom;
  private Sps(int i,int p,int l,int w,int h,int left,int right,int top,int bottom){id=i;profile=p;level=l;codedWidth=w;codedHeight=h;cropLeft=left;cropRight=right;cropTop=top;cropBottom=bottom;width=w-left-right;height=h-top-bottom;if(width<1||height<1)throw new IllegalArgumentException("SPS crop");}
 }
 public static Sps sps(Nal nal){
  if(nal.type!=7)throw new IllegalArgumentException("Not SPS");Bits b=new Bits(nal.raw);int profile=b.read(8);b.read(8);int level=b.read(8),id=b.ue();
  if(profile!=66&&profile!=77&&profile!=88)throw new IllegalArgumentException("High-profile SPS explicitly unsupported");
  if(id>31||b.ue()>12)throw new IllegalArgumentException("SPS IDs/frame number");int poc=b.ue();if(poc==0){if(b.ue()>12)throw new IllegalArgumentException("POC");}else if(poc==1){b.read(1);b.se();b.se();int n=b.ue();if(n>255)throw new IllegalArgumentException("POC count");for(int i=0;i<n;i++)b.se();}else if(poc!=2)throw new IllegalArgumentException("POC type");
  b.ue();b.read(1);int wm=b.ue()+1,hm=b.ue()+1;if(wm>512||hm>512)throw new IllegalArgumentException("SPS dimension bound");int frame=b.read(1);if(frame==0)b.read(1);b.read(1);
  int left=0,right=0,top=0,bottom=0;if(b.read(1)!=0){left=b.ue()*2;right=b.ue()*2;top=b.ue()*2*(2-frame);bottom=b.ue()*2*(2-frame);}b.read(1); // VUI presence only; no timing/colour inference.
  return new Sps(id,profile,level,wm*16,hm*16*(2-frame),left,right,top,bottom);
 }
 public static final class Configuration {
  public final Sps sps;private final byte[] bytes;
  public Configuration(byte[] annex){List<Nal> ns=annexB(annex);Sps selected=null;int ppsSps=-1;boolean hasPps=false;
   for(Nal n:ns){if(n.type==7){if(selected!=null)throw new IllegalArgumentException("Multiple SPS subset UNKNOWN");selected=sps(n);}else if(n.type==8){if(hasPps)throw new IllegalArgumentException("Multiple PPS subset UNKNOWN");Bits b=new Bits(n.raw);if(b.ue()>255)throw new IllegalArgumentException("PPS ID");ppsSps=b.ue();b.read(1);b.read(1);hasPps=true;}else if(n.type==1||n.type==5)throw new IllegalArgumentException("Slices in config subset");}
   if(selected==null||!hasPps||ppsSps!=selected.id)throw new IllegalArgumentException("SPS/PPS association");sps=selected;bytes=annex.clone();
  }
  public byte[] bytes(){return bytes.clone();}
 }
 public static final class AccessUnit {
  public final boolean keyframe;private final byte[] bytes;
  /** Call only when a separate source/adapter supplies the AU boundary. */
  public AccessUnit(byte[] annex){boolean slice=false,key=false;for(Nal n:annexB(annex)){slice|=n.type==1||n.type==5;key|=n.type==5;}if(!slice)throw new IllegalArgumentException("No VCL slice");bytes=annex.clone();keyframe=key;}
  public byte[] bytes(){return bytes.clone();}public int size(){return bytes.length;}
 }
}
