package com.rdx.fullscreen.clean;
import java.io.*;
import java.util.*;
/** HOST fixture reader only: bounded non-fragmented single AVC track, no edit/composition shifts. */
public final class Mp4FixtureReader {
 private final byte[] file;private final long[] offsets,ticks;private final int[] sizes;private final boolean[] sync;private final int lengthSize,timescale;private final byte[] config;
 private static final class Box {int start,size,data,end;String type;}
 private long u32(int p){if(p<0||p>file.length-4)throw new IllegalArgumentException("MP4 uint32");return ((file[p]&255L)<<24)|((file[p+1]&255L)<<16)|((file[p+2]&255L)<<8)|(file[p+3]&255L);}
 private int small(int p,int max){long v=u32(p);if(v>max)throw new IllegalArgumentException("MP4 count/bound");return (int)v;}
 private List<Box> boxes(int from,int to){List<Box> out=new ArrayList<Box>();int p=from;while(p<to){if(to-p<8||out.size()>10000)throw new IllegalArgumentException("MP4 boxes");long size=u32(p);if(size<8||size>to-p)throw new IllegalArgumentException("MP4 box size; extended unsupported");Box b=new Box();b.start=p;b.size=(int)size;b.data=p+8;b.end=p+b.size;try{b.type=new String(file,p+4,4,"US-ASCII");}catch(Exception e){throw new IllegalStateException(e);}out.add(b);p=b.end;}return out;}
 private Box one(int from,int to,String type){Box found=null;for(Box b:boxes(from,to))if(b.type.equals(type)){if(found!=null)throw new IllegalArgumentException("Duplicate box "+type);found=b;}if(found==null)throw new IllegalArgumentException("Missing box "+type);return found;}
 private Box child(Box b,String type){return one(b.data,b.end,type);}
 private void span(Box b,int p,long n){if(n<0||p<b.data||n>b.end-p)throw new IllegalArgumentException("MP4 table extent");}
 public Mp4FixtureReader(File path)throws IOException{
  if(path.length()<8||path.length()>33554432)throw new IllegalArgumentException("MP4 file bound");file=new byte[(int)path.length()];DataInputStream in=new DataInputStream(new FileInputStream(path));try{in.readFully(file);}finally{in.close();}
  Box moov=one(0,file.length,"moov"),trak=child(moov,"trak"),mdia=child(trak,"mdia"),mdhd=child(mdia,"mdhd");if(file[mdhd.data]!=0)throw new IllegalArgumentException("Only mdhd v0");timescale=small(mdhd.data+12,1000000000);if(timescale<1)throw new IllegalArgumentException("Timescale");
  // Known generated clips may have identity edit list. Reject non-identity media offset.
  for(Box b:boxes(trak.data,trak.end))if(b.type.equals("edts")){Box edit=child(b,"elst");if(file[edit.data]!=0||u32(edit.data+4)!=1||u32(edit.data+12)!=0)throw new IllegalArgumentException("Nonidentity edit unsupported");}
  Box stbl=child(child(mdia,"minf"),"stbl"),stsd=child(stbl,"stsd");if(u32(stsd.data+4)!=1)throw new IllegalArgumentException("sample descriptions");Box avc1=one(stsd.data+8,stsd.end,"avc1"),avcc=one(avc1.start+86,avc1.end,"avcC");
  span(avcc,avcc.data,7);if(file[avcc.data]!=1)throw new IllegalArgumentException("avcC version");lengthSize=(file[avcc.data+4]&3)+1;int p=avcc.data+5,spsCount=file[p++]&31;ByteArrayOutputStream csd=new ByteArrayOutputStream();
  for(int group=0;group<2;group++){int count=group==0?spsCount:(file[p++]&255);if(count<1||count>8)throw new IllegalArgumentException("avcC config count");for(int i=0;i<count;i++){span(avcc,p,2);int n=((file[p]&255)<<8)|(file[p+1]&255);p+=2;span(avcc,p,n);csd.write(new byte[]{0,0,0,1});csd.write(file,p,n);p+=n;}}config=csd.toByteArray();
  Box stsz=child(stbl,"stsz");int fixed=small(stsz.data+4,H264.MAX),count=small(stsz.data+8,10000);if(count<1)throw new IllegalArgumentException("sample count");sizes=new int[count];if(fixed==0)span(stsz,stsz.data+12,4L*count);for(int i=0;i<count;i++)sizes[i]=fixed!=0?fixed:small(stsz.data+12+i*4,H264.MAX);
  Box stco=child(stbl,"stco");int chunks=small(stco.data+4,10000);span(stco,stco.data+8,4L*chunks);Box stsc=child(stbl,"stsc");int entries=small(stsc.data+4,10000);span(stsc,stsc.data+8,12L*entries);if(entries==0||u32(stsc.data+8)!=1)throw new IllegalArgumentException("stsc first chunk");
  offsets=new long[count];int entry=0,sample=0;for(int chunk=1;chunk<=chunks;chunk++){while(entry+1<entries&&u32(stsc.data+8+(entry+1)*12)<=chunk)entry++;int n=small(stsc.data+12+entry*12,10000);if(u32(stsc.data+16+entry*12)!=1)throw new IllegalArgumentException("description index");long off=u32(stco.data+8+(chunk-1)*4);for(int i=0;i<n;i++){if(sample>=count||off>file.length-sizes[sample])throw new IllegalArgumentException("sample extent");offsets[sample]=off;off+=sizes[sample++];}}if(sample!=count)throw new IllegalArgumentException("sample coverage");
  Box stts=child(stbl,"stts");int nt=small(stts.data+4,10000);span(stts,stts.data+8,8L*nt);ticks=new long[count];sample=0;long time=0;for(int i=0;i<nt;i++){int n=small(stts.data+8+i*8,10000),delta=small(stts.data+12+i*8,1000000000);for(int k=0;k<n;k++){if(sample>=count)throw new IllegalArgumentException("time count");ticks[sample++]=time;time+=delta;}}if(sample!=count)throw new IllegalArgumentException("time coverage");
  sync=new boolean[count];Arrays.fill(sync,true);for(Box b:boxes(stbl.data,stbl.end)){if(b.type.equals("stss")){Arrays.fill(sync,false);int n=small(b.data+4,10000);span(b,b.data+8,4L*n);for(int i=0;i<n;i++){int idx=small(b.data+8+i*4,count)-1;if(idx<0)throw new IllegalArgumentException("sync index");sync[idx]=true;}}if(b.type.equals("ctts")){int n=small(b.data+4,10000);span(b,b.data+8,8L*n);for(int i=0;i<n;i++)if(u32(b.data+12+i*8)!=0)throw new IllegalArgumentException("Nonzero composition offset unsupported");}}
 }
 public int count(){return sizes.length;}public int sampleBytes(int i){return sizes[i];}public long timestampUs(int i){return ticks[i]*1000000L/timescale;}public long timestampTicks(int i){return ticks[i];}public int timescale(){return timescale;}public boolean keyframe(int i){return sync[i];}
 public byte[] configuration(){return config.clone();}
 public byte[] accessUnit(int i){return H264.fromLengthPrefixed(Arrays.copyOfRange(file,(int)offsets[i],(int)offsets[i]+sizes[i]),lengthSize);}
}
