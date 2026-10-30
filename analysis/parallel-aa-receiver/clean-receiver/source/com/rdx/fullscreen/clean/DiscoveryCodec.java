package com.rdx.fullscreen.clean;
import java.util.*;
/** Small Honda-compatible schema subset, independently encoded. No generated/copied upstream code. */
public final class DiscoveryCodec {
 private DiscoveryCodec(){}
 public static byte[] video(VideoConfig v){
  return new ProtoWire.Writer().uint32(1,v.nominalWidth==1280?2:3)
   .uint32(2,v.fps==60?1:2).uint32(3,v.marginWidth).uint32(4,v.marginHeight).uint32(5,v.dpi).finish();
 }
 public static VideoConfig video(byte[] b){ProtoWire.Message m=ProtoWire.parse(b);int resolution=ProtoWire.boundedInt(m.scalar(1,true,0),2,3),rate=ProtoWire.boundedInt(m.scalar(2,true,0),1,2);
  return new VideoConfig(resolution==2?1280:1920,resolution==2?720:1080,integer(m,3,0,1919),integer(m,4,0,1079),integer(m,5,1,1000),rate==1?60:30);
 }
 private static int integer(ProtoWire.Message m,int f,int min,int max){return ProtoWire.boundedInt(m.scalar(f,true,0),min,max);}
 public static byte[] touchpad(InputConfig i){return new ProtoWire.Writer().uint32(1,i.width).uint32(2,i.height).scalar(3,i.uiNavigation?1:0).uint32(4,i.physicalWidthMm).uint32(5,i.physicalHeightMm).scalar(6,i.uiAbsolute?1:0).finish();}
 public static InputConfig touchpad(byte[] b){ProtoWire.Message m=ProtoWire.parse(b);return new InputConfig(integer(m,1,1,65535),integer(m,2,1,65535),integer(m,4,1,1000),integer(m,5,1,1000),integer(m,3,0,1)!=0,integer(m,6,0,1)!=0);}
 public static byte[] encode(AaServiceDiscovery model,AaServiceRegistry registry){
  ProtoWire.Writer response=new ProtoWire.Writer();int videoCount=0,inputCount=0;
  for(AaServiceRegistry.Entry e:registry.entries()){
   ProtoWire.Writer service=new ProtoWire.Writer().uint32(1,e.serviceId);
   if(e.kind==AaServiceRegistry.Kind.VIDEO){if(++videoCount>1)throw new IllegalArgumentException("One video service supported");ProtoWire.Writer sink=new ProtoWire.Writer().uint32(1,3);for(VideoConfig v:model.video)sink.bytes(4,video(v));service.bytes(3,sink.finish());}
   else if(e.kind==AaServiceRegistry.Kind.INPUT){if(++inputCount>1||model.input==null)throw new IllegalArgumentException("Input not configured");service.bytes(4,new ProtoWire.Writer().bytes(3,touchpad(model.input)).finish());}
   else throw new IllegalArgumentException("Service outside minimal advertisement");
   response.bytes(1,service.finish());
  }
  if(videoCount!=1||(model.input!=null&&inputCount!=1))throw new IllegalArgumentException("Registry/model mismatch");
  // Explicit synthetic identity. No VIN, proprietary credential or device lookup.
  response.text(2,"RDX research").text(3,"Offline core").text(4,"2021").text(5,"").scalar(6,0)
   .text(7,"Independent").text(8,"Pure Java").text(9,"offline").text(10,"0.3-protocol").scalar(11,0);
  return response.finish();
 }
 public static final class Decoded {
  public final List<VideoConfig> video;public final InputConfig input;public final int videoServiceId,inputServiceId;public final List<Integer> unknownServices;private final byte[] original;
  private Decoded(List<VideoConfig> v,InputConfig i,int vs,int is,List<Integer> unknown,byte[] bytes){video=Collections.unmodifiableList(v);input=i;videoServiceId=vs;inputServiceId=is;unknownServices=Collections.unmodifiableList(unknown);original=bytes.clone();}
  /** Immutable original advertisement, including nested unknown fields. Not a reconfigured advertisement. */
  public byte[] originalEncoding(){return original.clone();}
 }
 /** Unknown service kinds are retained as IDs, not advertised or opened. Known unsupported codecs fail. */
 public static Decoded decode(byte[] bytes){
  ProtoWire.Message root=ProtoWire.parse(bytes);List<byte[]> services=root.repeatedBytes(1,ProtocolLimits.SERVICES);
  for(int f=2;f<=10;f++)if(f!=6)ProtoWire.text(root.bytes(f,true));integer(root,6,0,3);integer(root,11,0,1);
  List<VideoConfig> video=new ArrayList<VideoConfig>();InputConfig input=null;int vs=-1,is=-1;List<Integer> unknown=new ArrayList<Integer>();Set<Integer> seen=new HashSet<Integer>();
  for(byte[] s:services){ProtoWire.Message service=ProtoWire.parse(s);int id=integer(service,1,1,65535);if(!seen.add(id))throw new IllegalArgumentException("Duplicate discovery service");
   if(service.has(3)&&service.has(4))throw new IllegalArgumentException("Ambiguous service kind");
   if(service.has(3)){if(vs!=-1)throw new IllegalArgumentException("Duplicate video service");ProtoWire.Message sink=ProtoWire.parse(service.bytes(3,true));if(integer(sink,1,1,7)!=3)throw new IllegalArgumentException("Only H264 baseline video supported");for(byte[] v:sink.repeatedBytes(4,ProtocolLimits.VIDEO_CONFIGS))video.add(video(v));if(video.isEmpty())throw new IllegalArgumentException("No video configurations");vs=id;}
   else if(service.has(4)){if(is!=-1)throw new IllegalArgumentException("Duplicate input service");ProtoWire.Message config=ProtoWire.parse(service.bytes(4,true));input=touchpad(config.bytes(3,true));is=id;}
   else unknown.add(id);
  }
  return new Decoded(video,input,vs,is,unknown,bytes);
 }
}
