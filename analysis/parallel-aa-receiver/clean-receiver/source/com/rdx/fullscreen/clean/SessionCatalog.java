package com.rdx.fullscreen.clean;
import java.util.*;
/** HU advertisement, NOT a fictional phone discovery response. Decode/commit is explicit. */
public final class SessionCatalog {
 public static final class Binding {
  public final int service,channel; public final AaServiceRegistry.Kind kind;
  public Binding(int s,int c,AaServiceRegistry.Kind k){service=s;channel=c;kind=k;}
 }
 public static final class MappingException extends IllegalArgumentException { public MappingException(String m){super(m);} }
 public static final class Prepared {
  public final DiscoveryCodec.Decoded decoded;public final AaServiceRegistry registry;
  private Prepared(DiscoveryCodec.Decoded d,AaServiceRegistry r){decoded=d;registry=r;}
 }
 private final byte[] wire;private final List<Binding> bindings;public final boolean experimentalOptIn;
 public SessionCatalog(byte[] bytes,List<Binding> mapping,boolean optIn){
  if(bytes==null||bytes.length>ProtocolLimits.PROTO_BYTES||mapping==null||mapping.size()>ProtocolLimits.SERVICES)throw new IllegalArgumentException("Catalog bounds");
  for(Binding b:mapping)if(b==null)throw new IllegalArgumentException("Null binding");
  wire=bytes.clone();bindings=new ArrayList<Binding>(mapping);experimentalOptIn=optIn;
 }
 public static SessionCatalog conservative(){return profile(false);}
 public static SessionCatalog experimental(){return profile(true);}
 private static SessionCatalog profile(boolean experiment){
  AaServiceDiscovery model=new AaServiceDiscovery(Collections.singletonList(experiment?VideoConfig.fullscreenExperiment():VideoConfig.conservative()),InputConfig.hondaReference());
  AaServiceRegistry map=new AaServiceRegistry();map.register(1,1,AaServiceRegistry.Kind.VIDEO);map.register(2,2,AaServiceRegistry.Kind.INPUT);
  return new SessionCatalog(DiscoveryCodec.encode(model,map),Arrays.asList(new Binding(1,1,AaServiceRegistry.Kind.VIDEO),new Binding(2,2,AaServiceRegistry.Kind.INPUT)),experiment);
 }
 public byte[] bytes(){return wire.clone();}
 public Prepared prepare(){
  DiscoveryCodec.Decoded decoded=DiscoveryCodec.decode(wire);AaServiceRegistry registry=new AaServiceRegistry(ProtocolLimits.SERVICES);
  for(VideoConfig video:decoded.video)if(video.nominalWidth==1920&&!experimentalOptIn)throw new MappingException("Experimental capability requires explicit opt-in");
  for(Binding b:bindings){
   boolean known=b.kind==AaServiceRegistry.Kind.VIDEO&&b.service==decoded.videoServiceId||b.kind==AaServiceRegistry.Kind.INPUT&&b.service==decoded.inputServiceId;
   if(!known)throw new MappingException("Binding is not an understood advertised service");
   try{registry.register(b.service,b.channel,b.kind);}catch(IllegalArgumentException e){throw new MappingException("Duplicate/reserved/invalid channel mapping");}
  }
  if(decoded.videoServiceId!=-1&&!has(registry,decoded.videoServiceId)||decoded.inputServiceId!=-1&&!has(registry,decoded.inputServiceId))throw new MappingException("Known service lacks explicit binding");
  return new Prepared(decoded,registry);
 }
 private static boolean has(AaServiceRegistry r,int id){for(AaServiceRegistry.Entry e:r.entries())if(e.serviceId==id)return true;return false;}
}
