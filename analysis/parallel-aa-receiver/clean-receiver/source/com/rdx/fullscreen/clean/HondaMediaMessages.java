package com.rdx.fullscreen.clean;
import java.util.*;
/** Target-specific bounded wire facts. Parsing retains original bytes/unknowns; no I/O. */
public final class HondaMediaMessages {
 private HondaMediaMessages(){}
 private static long u32(long v){if(v<0||v>0xffffffffL)throw new IllegalArgumentException("uint32");return v;}
 public static final class CodecType {
  public static final CodecType H264_BASELINE=new CodecType(3);
  public final long wire;
  private CodecType(long v){wire=u32(v);}
  public static CodecType fromWire(long v){return new CodecType(v);}
  public boolean supportedVideo(){return wire==3;}
 }
 /** Configuration index is NOT a codec type, even when numeric values coincide. */
 public static final class VideoConfigurationIndex {
  public final long value;
  public VideoConfigurationIndex(long v){value=u32(v);}
 }
 public static final class MediaSetup {
  public final CodecType codec;private final byte[] raw;
  private MediaSetup(CodecType c,byte[] b){codec=c;raw=b.clone();}
  public static MediaSetup parse(byte[] b){ProtoWire.Message m=ProtoWire.parse(b);return new MediaSetup(CodecType.fromWire(m.scalar(1,true,0)),m.encoded());}
  public static MediaSetup create(CodecType c){if(c==null)throw new IllegalArgumentException("codec");return parse(new ProtoWire.Writer().uint32(1,c.wire).finish());}
  public byte[] encode(){return raw.clone();}
 }
 public static final class MediaConfig {
  public final MediaConfigStatus status;public final long rawStatus,maxUnacked;public final boolean hasMaxUnacked;
  private final List<VideoConfigurationIndex> indices;private final byte[] raw;
  private MediaConfig(long s,long w,boolean present,List<VideoConfigurationIndex> i,byte[] b){rawStatus=s;status=MediaConfigStatus.fromWire(s);maxUnacked=w;hasMaxUnacked=present;indices=Collections.unmodifiableList(i);raw=b.clone();}
  public List<VideoConfigurationIndex> indices(){return indices;}
  public boolean permits(VideoConfigurationIndex index){for(VideoConfigurationIndex i:indices)if(i.value==index.value)return true;return false;}
  public static MediaConfig parse(byte[] b){
   ProtoWire.Message m=ProtoWire.parse(b);long s=u32(m.scalar(1,true,0));boolean present=m.has(2);long w=present?u32(m.scalar(2,true,0)):-1;
   List<VideoConfigurationIndex> list=new ArrayList<VideoConfigurationIndex>();
   for(ProtoWire.Field f:m.fields())if(f.number==3){if(f.wire!=0||list.size()>=ProtocolLimits.VIDEO_CONFIGS)throw new IllegalArgumentException("Config index type/count");list.add(new VideoConfigurationIndex(f.value));}
   return new MediaConfig(s,w,present,list,m.encoded());
  }
  /** Unknown/zero status is retained for inspection, never accepted for advertisement. */
  public void validateAdvertisement(int catalogCount){
   if(status==null)throw new IllegalArgumentException("Unsupported Config status");
   if(catalogCount<1||catalogCount>ProtocolLimits.VIDEO_CONFIGS)throw new IllegalArgumentException("catalog count");
   if(hasMaxUnacked&&maxUnacked==0)throw new IllegalArgumentException("Local positive window policy");
   Set<Long> seen=new HashSet<Long>();for(VideoConfigurationIndex i:indices)if(i.value>=catalogCount||!seen.add(i.value))throw new IllegalArgumentException("Invalid/duplicate advertised index");
   // Empty list is preserved; it advertises no selectable configuration in this model.
  }
  public static MediaConfig create(MediaConfigStatus s,Long max,List<VideoConfigurationIndex> indices){
   if(s==null||indices==null||indices.size()>ProtocolLimits.VIDEO_CONFIGS)throw new IllegalArgumentException("Config args");
   ProtoWire.Writer w=new ProtoWire.Writer().uint32(1,s.wire);if(max!=null)w.uint32(2,max.longValue());
   for(VideoConfigurationIndex i:indices){if(i==null)throw new IllegalArgumentException("index");w.uint32(3,i.value);}return parse(w.finish());
  }
  public byte[] encode(){return raw.clone();}
 }
 public static final class MediaStart {
  public final int session;public final VideoConfigurationIndex configuration;private final byte[] raw;
  private MediaStart(int s,VideoConfigurationIndex c,byte[] b){session=s;configuration=c;raw=b.clone();}
  public static MediaStart parse(byte[] b){ProtoWire.Message m=ProtoWire.parse(b);int s=ProtoWire.boundedInt(m.scalar(1,true,0),0,Integer.MAX_VALUE);return new MediaStart(s,new VideoConfigurationIndex(m.scalar(2,true,0)),m.encoded());}
  public static MediaStart create(int session,VideoConfigurationIndex c){if(c==null)throw new IllegalArgumentException("index");return parse(new ProtoWire.Writer().uint32(1,session).uint32(2,c.value).finish());}
  public byte[] encode(){return raw.clone();}
 }
 public static final class MediaAck {
  public final int session,count;private final byte[] raw;
  private MediaAck(int s,int n,byte[] b){session=s;count=n;raw=b.clone();}
  public static MediaAck parse(byte[] b){ProtoWire.Message m=ProtoWire.parse(b);return new MediaAck(ProtoWire.boundedInt(m.scalar(1,true,0),0,Integer.MAX_VALUE),ProtoWire.boundedInt(m.scalar(2,true,0),1,32),m.encoded());}
  public static MediaAck accounting(int session,int count){return parse(new ProtoWire.Writer().uint32(1,session).uint32(2,count).finish());}
  public byte[] encode(){return raw.clone();}
 }
 /** Narrow confirmed projected-focus indication only, no peer prerequisites inferred. */
 public static final class ProjectedFocus {
  private final byte[] raw;private ProjectedFocus(byte[] b){raw=b.clone();}
  public static ProjectedFocus parse(byte[] b){ProtoWire.Message m=ProtoWire.parse(b);if(m.scalar(1,true,0)!=1||m.scalar(2,true,0)!=1)throw new IllegalArgumentException("Only projected/unsolicited supported");return new ProjectedFocus(m.encoded());}
  public static ProjectedFocus create(){return parse(new byte[]{8,1,16,1});}
  public byte[] encode(){return raw.clone();}
 }
}
