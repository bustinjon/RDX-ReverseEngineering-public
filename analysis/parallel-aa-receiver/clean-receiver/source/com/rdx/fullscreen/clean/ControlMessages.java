package com.rdx.fullscreen.clean;
/** Pure control payloads. Type is a BE16 prefix outside protobuf. Version is raw BE16 fields. */
public final class ControlMessages {
 public static final int VERSION_REQUEST=1,VERSION_RESPONSE=2,TLS_HANDSHAKE=3,AUTH_COMPLETE=4,DISCOVERY_REQUEST=5,DISCOVERY_RESPONSE=6,CHANNEL_OPEN_REQUEST=7,CHANNEL_OPEN_RESPONSE=8,CHANNEL_CLOSE=9,PING_REQUEST=11,PING_RESPONSE=12,STOP_REQUEST=15,STOP_RESPONSE=16;
 private ControlMessages(){}
 public static byte[] typed(int type,byte[] payload){if(type<0||type>65535||payload==null||payload.length>ProtocolLimits.MESSAGE-2)throw new IllegalArgumentException("Typed message limit");byte[] b=new byte[payload.length+2];b[0]=(byte)(type>>>8);b[1]=(byte)type;System.arraycopy(payload,0,b,2,payload.length);return b;}
 public static final class Version {
  public final int major,minor,status;public final boolean response;
  public Version(int ma,int mi,int st,boolean reply){if(ma<0||ma>65535||mi<0||mi>65535||st<0||st>65535)throw new IllegalArgumentException("Version range");major=ma;minor=mi;status=st;response=reply;}
  public byte[] encode(){byte[] b=new byte[response?6:4];b[0]=(byte)(major>>>8);b[1]=(byte)major;b[2]=(byte)(minor>>>8);b[3]=(byte)minor;if(response){b[4]=(byte)(status>>>8);b[5]=(byte)status;}return b;}
  public static Version parse(byte[] b,boolean response){if(b==null||b.length!=(response?6:4))throw new IllegalArgumentException("Only base raw version supported; options deferred");return new Version(((b[0]&255)<<8)|(b[1]&255),((b[2]&255)<<8)|(b[3]&255),response?((b[4]&255)<<8)|(b[5]&255):0,response);}
 }
 public static final class Ping {
  public final long timestamp;public Ping(long t){timestamp=t;}
  public byte[] encode(){return new ProtoWire.Writer().scalar(1,timestamp).finish();}
  public static Ping parse(byte[] b){return new Ping(ProtoWire.parse(b).scalar(1,true,0));}
 }
 public static final class Status {
  public final int code;public Status(int c){if(c<0||c>1)throw new IllegalArgumentException("Only OK/FAIL supported");code=c;}
  public byte[] encode(){return new ProtoWire.Writer().uint32(1,code).finish();}
  public static Status parse(byte[] b){return new Status(ProtoWire.boundedInt(ProtoWire.parse(b).scalar(1,true,0),0,1));}
 }
 public static final class Open {
  public final int priority,serviceId;
  public Open(int p,int s){if(s<1||s>65535)throw new IllegalArgumentException("Service id");priority=p;serviceId=s;}
  public byte[] encode(){return new ProtoWire.Writer().sint32(1,priority).uint32(2,serviceId).finish();}
  public static Open parse(byte[] b){ProtoWire.Message m=ProtoWire.parse(b);long z=m.scalar(1,true,0);if(z<0||z>0xffffffffL)throw new IllegalArgumentException("ZigZag overflow");int p=(int)((z>>>1)^-(z&1));return new Open(p,ProtoWire.boundedInt(m.scalar(2,true,0),1,65535));}
 }
 public static final class DiscoveryRequest {
  public final String phone,brand;
  public DiscoveryRequest(String p,String b){phone=p;brand=b;encode();}
  public byte[] encode(){return new ProtoWire.Writer().text(4,phone).text(5,brand).finish();}
  public static DiscoveryRequest parse(byte[] b){ProtoWire.Message m=ProtoWire.parse(b);return new DiscoveryRequest(ProtoWire.text(m.bytes(4,true)),ProtoWire.text(m.bytes(5,true)));}
 }
 public static final class Stop {
  public final int reason;public Stop(int r){if(r<1||r>5)throw new IllegalArgumentException("Stop reason");reason=r;}
  public byte[] encode(){return new ProtoWire.Writer().uint32(1,reason).finish();}
  public static Stop parse(byte[] b){return new Stop(ProtoWire.boundedInt(ProtoWire.parse(b).scalar(1,true,0),1,5));}
 }
 /** Close payload is deliberately not guessed. Control type9 is inventoried but not serialized. */
}
