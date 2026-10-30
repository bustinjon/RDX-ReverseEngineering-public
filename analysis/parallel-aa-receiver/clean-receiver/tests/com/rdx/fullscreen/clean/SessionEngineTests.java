package com.rdx.fullscreen.clean;
import java.io.*;
import java.util.*;

public final class SessionEngineTests {
 private static File fixtures,out;private static int deterministic,properties,transcripts;
 private static final Map<String,byte[]> CACHE=new HashMap<String,byte[]>();
 private static final long SEED=0x4d375345535349L;
 private static byte[] f(String name){byte[] saved=CACHE.get(name);if(saved!=null)return saved.clone();try{File file=new File(fixtures,name+".bin");if(file.length()>65536)throw new IOException("Fixture bound");byte[] b=new byte[(int)file.length()];DataInputStream in=new DataInputStream(new FileInputStream(file));try{in.readFully(b);}finally{in.close();}CACHE.put(name,b);return b.clone();}catch(IOException e){throw new IllegalStateException(e);}}
 private static void check(boolean v,String s){deterministic++;if(!v)throw new AssertionError(s);}
 private static void prop(boolean v,String s){properties++;if(!v)throw new AssertionError(s+" seed="+SEED+" assertion="+properties);}
 private static byte[] join(byte[] a,byte[] b){byte[] c=Arrays.copyOf(a,a.length+b.length);System.arraycopy(b,0,c,a.length,b.length);return c;}
 private static byte[] payload(String name){byte[] wire=f(name);return Arrays.copyOfRange(wire,6,wire.length);}
 private static SessionPolicy policy(){return new SessionPolicy(10,20,100,1000);}
 private static List<SessionCatalog.Binding> mappings(){return Arrays.asList(new SessionCatalog.Binding(1,1,AaServiceRegistry.Kind.VIDEO),new SessionCatalog.Binding(2,2,AaServiceRegistry.Kind.INPUT));}
 private static InMemorySessionTransport rig(SessionCatalog catalog){InMemorySessionTransport.Clock clock=new InMemorySessionTransport.Clock();return new InMemorySessionTransport(clock,new SimulatedSessionEngine(clock,policy(),catalog));}
 private static InMemorySessionTransport rig(){return rig(SessionCatalog.conservative());}
 private static void incoming(InMemorySessionTransport t,String fixture){byte[] b=f(fixture);t.inject(b,b.length,0);t.advanceTo(t.clock.time);}
 private static void version(InMemorySessionTransport t){t.engine.transportReady();t.engine.beginVersion();t.capture();incoming(t,"version-response");}
 private static void discovery(InMemorySessionTransport t){version(t);t.engine.enterPlaintextSimulation();incoming(t,"discovery-request");}
 private static void video(InMemorySessionTransport t){discovery(t);incoming(t,"open-video");}
 private static void setup(InMemorySessionTransport t){video(t);incoming(t,"media-setup");}
 private static void save(String id,InMemorySessionTransport t,String label){
  try{PrintWriter writer=new PrintWriter(new OutputStreamWriter(new FileOutputStream(new File(out,id+".txt")),"UTF-8"));try{writer.println(label);for(String row:t.engine.transcript())writer.println(row);writer.println("FINAL="+t.engine.state()+" OUTCOME="+t.engine.outcome());}finally{writer.close();}transcripts++;}catch(IOException e){throw new IllegalStateException(e);}
 }
 private static void scenarios(){
  InMemorySessionTransport t=rig();check(t.engine.state()==SimulatedSessionEngine.State.NEW&&t.engine.transcript().isEmpty()&&t.engine.drainOutbound().isEmpty(),"constructor inert");
  setup(t);check(t.engine.state()==SimulatedSessionEngine.State.MEDIA_SETUP_PENDING,"conservative supported extent");
  check(Arrays.equals(t.outbound().get(0),f("version-request")),"independent exact outbound version fixture");
  check(t.engine.outcome().equals("UNKNOWN_MEDIA_TRANSITION"),"unknown media progression explicit");
  check(Arrays.equals(DiscoveryCodec.video(DiscoveryCodec.decode(f("discovery-conservative")).video.get(0)),f("video-conservative")),"conservative exact vector");
  boolean same=false;for(byte[] wire:t.outbound())if(wire.length>6&&wire[5]==6)same=Arrays.equals(Arrays.copyOfRange(wire,6,wire.length),f("discovery-conservative"));
  check(same,"independent full HU discovery bytes match");save("01-conservative",t,"SUCCESSFUL SYNTHETIC PROGRESSION THROUGH MEDIA_SETUP_PENDING; real security bypass explicit; MEDIA_READY UNKNOWN");
  t=rig(SessionCatalog.experimental());setup(t);check(t.engine.state()==SimulatedSessionEngine.State.MEDIA_SETUP_PENDING&&t.engine.experimentalOptIn(),"experimental extent explicit");
  check(Arrays.equals(DiscoveryCodec.video(DiscoveryCodec.decode(f("discovery-experimental")).video.get(0)),f("video-experimental")),"experimental exact vector");
  check(DiscoveryCodec.decode(f("discovery-experimental")).video.get(0).placement==VideoConfig.Placement.UNSPECIFIED,"no crop placement assumption");
  save("02-experimental",t,"SUCCESSFUL SYNTHETIC PROGRESSION THROUGH MEDIA_SETUP_PENDING; OPT-IN, crop UNSPECIFIED");
  t=rig();t.engine.transportReady();t.engine.beginVersion();incoming(t,"unsupported-version");check(t.engine.outcome().equals("UNSUPPORTED_VERSION"),"unsupported version");save("03-unsupported-version",t,"NEGATIVE: supported-profile rejection");
  byte[] malformed=Arrays.copyOf(f("discovery-conservative"),f("discovery-conservative").length-1);
  t=rig(new SessionCatalog(malformed,mappings(),false));discovery(t);check(t.engine.outcome().equals("MALFORMED_WIRE"),"malformed local discovery");save("04-malformed-discovery",t,"NEGATIVE: local HU advertisement wire; not fictional phone advertisement");
  t=rig(new SessionCatalog(f("discovery-unknown-service"),mappings(),false));discovery(t);check(t.engine.registrySize()==2&&t.engine.state()==SimulatedSessionEngine.State.SERVICES_ADVERTISED,"unknown service isolated");save("05-unknown-service",t,"C unsupported service99 isolated; known services unaffected");
  List<SessionCatalog.Binding> duplicate=Arrays.asList(new SessionCatalog.Binding(1,1,AaServiceRegistry.Kind.VIDEO),new SessionCatalog.Binding(2,1,AaServiceRegistry.Kind.INPUT));
  t=rig(new SessionCatalog(f("discovery-conservative"),duplicate,false));discovery(t);check(t.engine.outcome().equals("LOCAL_DISCOVERY_MAPPING_ERROR")&&t.engine.registrySize()==0,"duplicate channel atomic rollback");save("06-duplicate-channel",t,"NEGATIVE: explicit local binding error");
  t=rig();t.engine.transportReady();t.engine.beginVersion();incoming(t,"first-fragment");t.advanceTo(20);check(t.engine.outcome().equals("D_TIMEOUT_FRAGMENT")&&t.engine.reservationBytes()==0,"fragment deadline frees reservation");save("07-fragment-timeout",t,"D timeout: FIRST then silence");
  t=rig();t.engine.transportReady();t.engine.beginVersion();t.advanceTo(100);check(t.engine.outcome().equals("D_TIMEOUT_CONTROL_RESPONSE"),"control timeout");save("08-control-timeout",t,"D version request without response");
  t=rig();t.engine.transportReady();t.engine.beginVersion();t.eof();check(t.engine.outcome().equals("EOF_PENDING_CONTROL"),"EOF negotiation");save("09-eof-negotiation",t,"EOF pending control invalidates session");
  t=rig();discovery(t);incoming(t,"ping-unknown");check(Arrays.equals(t.engine.preservedUnknown(),payload("ping-unknown")),"unknown control fields exact bytes retained");save("10-unknown-protobuf",t,"Unknown field99 retained; response intentionally not an unknown-field echo");
  t=rig();video(t);incoming(t,"media-start");check(t.engine.outcome().equals("PROTOCOL_STATE_ERROR"),"illegal media start cannot advance");save("11-illegal-media",t,"START before setup rejected; no invented decoder lifecycle");
  t=rig();t.engine.transportReady();incoming(t,"malformed-frame");SimulatedSessionEngine old=t.engine;StringBuilder priorFailure=new StringBuilder();for(String row:old.transcript())priorFailure.append(row).append("\n");t.reset();check(t.engine.state()==SimulatedSessionEngine.State.NEW&&old.state()==SimulatedSessionEngine.State.ERROR,"reset creates new session object");setup(t);check(t.engine.state()==SimulatedSessionEngine.State.MEDIA_SETUP_PENDING,"clean new session after error");save("12-reset-new-session",t,"PRIOR TERMINAL SESSION\n"+priorFailure+"EXPLICIT RESET: NEW ENGINE INSTANCE; old ERROR object remains terminal\nSUCCESSFUL SYNTHETIC PROGRESSION THROUGH MEDIA_SETUP_PENDING after explicit NEW session");
  t=rig();version(t);incoming(t,"malformed-frame");check(t.engine.state()==SimulatedSessionEngine.State.ERROR,"malformed frame invalidates");save("13-malformed-frame",t,"A malformed framing invalidates whole session");
  t=rig(new SessionCatalog(f("discovery-unknown-service"),mappings(),false));discovery(t);incoming(t,"open-input");incoming(t,"open-video");check(t.engine.registrySize()==2&&t.engine.state()==SimulatedSessionEngine.State.VIDEO_SERVICE_AVAILABLE,"unsupported service does not corrupt other opens");save("14-service-isolation",t,"C unsupported99; input/video registry intact");
  t=rig();t.engine.transportReady();t.engine.beginVersion();incoming(t,"partial-frame");t.advanceTo(10);check(t.engine.outcome().equals("D_TIMEOUT_INCOMPLETE_FRAME")&&t.engine.partialFrameBytes()==0,"partial frame deadline clears bytes");save("15-frame-timeout",t,"D header then silence");
  t=rig();setup(t);incoming(t,"media-start");check(t.engine.state()==SimulatedSessionEngine.State.MEDIA_SETUP_PENDING&&t.engine.outcome().equals("UNKNOWN_MEDIA_TRANSITION"),"valid start does not manufacture MEDIA_RUNNING");incoming(t,"media-stop");check(t.engine.state()==SimulatedSessionEngine.State.MEDIA_SETUP_PENDING,"stop progression not guessed");save("16-unknown-media",t,"Valid media payloads inspected losslessly; transition UNKNOWN");
  t=rig();discovery(t);t.engine.beginStop();incoming(t,"shutdown-response");check(t.engine.state()==SimulatedSessionEngine.State.CLOSED&&t.engine.registrySize()==0,"orderly local shutdown");save("17-orderly-stop",t,"Orderly synthetic shutdown; no device operation");
  t=rig();discovery(t);incoming(t,"shutdown-request");check(t.engine.state()==SimulatedSessionEngine.State.CLOSED,"peer shutdown");
  t=rig();version(t);t.engine.enterPlaintextSimulation();t.inject(f("discovery-request"),1,5);t.advanceTo(5);check(t.engine.state()==SimulatedSessionEngine.State.SERVICES_ADVERTISED,"one-byte transport delivery");save("18-one-byte-transport",t,"Arbitrary chunking at one fake timestamp");
  t=rig();version(t);t.engine.enterPlaintextSimulation();byte[] concatenated=join(f("discovery-request"),f("open-video"));t.inject(concatenated,concatenated.length,1);t.advanceTo(1);check(t.engine.state()==SimulatedSessionEngine.State.VIDEO_SERVICE_AVAILABLE,"several messages one chunk");
  t=rig();t.engine.transportReady();t.engine.beginVersion();t.inject(f("version-response"),100,5);t.duplicateNext();t.advanceTo(5);check(t.engine.state()==SimulatedSessionEngine.State.ERROR,"duplicate version state error");
  t=rig();t.engine.transportReady();t.engine.beginVersion();t.inject(f("version-response"),100,1);t.dropNext();t.advanceTo(100);check(t.engine.outcome().equals("D_TIMEOUT_CONTROL_RESPONSE"),"dropped message timeout");
  t=rig();t.engine.transportReady();t.engine.beginVersion();t.inject(f("version-response"),100,1);t.inject(f("discovery-request"),100,1);t.reorderFirstTwo();t.advanceTo(1);check(t.engine.state()==SimulatedSessionEngine.State.ERROR,"reordered control rejected");
  t=rig();t.engine.transportReady();t.advanceTo(1000);check(t.engine.outcome().equals("D_TIMEOUT_INACTIVITY"),"separate inactivity timeout");
  t=rig();discovery(t);byte[] unknown=IndependentFixtures.hex("630300020001");t.engine.receive(unknown);check(t.engine.registrySize()==2&&t.engine.outcome().equals("B_UNKNOWN_CHANNEL_REJECTED"),"B unknown channel isolated");
  byte[] opaque=IndependentFixtures.hex("000b0003aabbcc");t.engine.receive(opaque);check(t.engine.outcome().equals("B_OPAQUE_ENCRYPTED")&&Arrays.equals(t.engine.preservedUnknown(),IndependentFixtures.hex("aabbcc")),"opaque encrypted never decrypted");
 }
 private static InMemorySessionTransport at(SimulatedSessionEngine.State state){
  InMemorySessionTransport t=rig();if(state==SimulatedSessionEngine.State.NEW)return t;t.engine.transportReady();if(state==SimulatedSessionEngine.State.TRANSPORT_READY)return t;
  if(state==SimulatedSessionEngine.State.ERROR){incoming(t,"malformed-frame");return t;}
  t.engine.beginVersion();if(state==SimulatedSessionEngine.State.VERSION_PENDING)return t;incoming(t,"version-response");if(state==SimulatedSessionEngine.State.VERSION_ESTABLISHED)return t;
  t.engine.enterPlaintextSimulation();if(state==SimulatedSessionEngine.State.DISCOVERY_PENDING)return t;incoming(t,"discovery-request");if(state==SimulatedSessionEngine.State.SERVICES_ADVERTISED)return t;
  if(state==SimulatedSessionEngine.State.STOPPING){t.engine.beginStop();return t;}
  if(state==SimulatedSessionEngine.State.CLOSED){t.eof();return t;}
  incoming(t,"open-video");if(state==SimulatedSessionEngine.State.VIDEO_SERVICE_AVAILABLE)return t;incoming(t,"media-setup");return t;
 }
 private static void matrix(){
  for(SimulatedSessionEngine.State state:SimulatedSessionEngine.State.values())for(int event=0;event<4;event++){
   InMemorySessionTransport t=at(state);boolean terminal=t.engine.terminal();
   boolean legal=event==0&&state==SimulatedSessionEngine.State.NEW||event==1&&state==SimulatedSessionEngine.State.TRANSPORT_READY||event==2&&state==SimulatedSessionEngine.State.VERSION_ESTABLISHED||event==3&&state==SimulatedSessionEngine.State.DISCOVERY_PENDING;
   if(event==0)t.engine.transportReady();else if(event==1)t.engine.beginVersion();else if(event==2)t.engine.enterPlaintextSimulation();else incoming(t,"discovery-request");
   check(terminal?t.engine.state()==state:legal?t.engine.state()!=SimulatedSessionEngine.State.ERROR:t.engine.state()==SimulatedSessionEngine.State.ERROR,"state/event matrix "+state+"/"+event);
  }
  for(String name:new String[]{"media-setup","media-start","media-stop","media-ack"}){
   int type=name.equals("media-setup")?0x8000:name.equals("media-start")?0x8001:name.equals("media-stop")?0x8002:0x8004;
   byte[] payload=payload(name);check(Arrays.equals(MediaControlMessages.parse(type,payload).encode(),payload),"independent media fixture "+name);
   byte[] extra=join(payload,IndependentFixtures.hex("980607"));check(Arrays.equals(MediaControlMessages.parse(type,extra).encode(),extra),"media unknown fields "+name);
  }
  check(Arrays.equals(MediaControlMessages.start(1,0),payload("media-start")),"start encoder golden bytes");
  check(Arrays.equals(MediaControlMessages.ack(1,1),payload("media-ack")),"ack encoder golden bytes");
  boolean bad=false;try{MediaControlMessages.parse(0x8001,IndependentFixtures.hex("0801"));}catch(IllegalArgumentException e){bad=true;}check(bad,"malformed start missing config");
  bad=false;try{MediaControlMessages.parse(0x8004,IndependentFixtures.hex("08011000"));}catch(IllegalArgumentException e){bad=true;}check(bad,"invalid zero ack count");
  check(MediaControlMessages.parse(0x8000,new byte[0]).hasField1==false,"do not invent proto3 default semantics");
  InMemorySessionTransport t=rig(new SessionCatalog(f("discovery-experimental"),mappings(),false));discovery(t);check(t.engine.state()==SimulatedSessionEngine.State.ERROR,"no accidental experimental selection");
 }
 private static void hardening(){
  byte[] base=f("discovery-conservative");
  byte[][] malformedCatalogs={join(base,Arrays.copyOfRange(base,0,21)),join(base,IndependentFixtures.hex("0a0108")),Arrays.copyOf(base,base.length-2)};
  for(int n=0;n<malformedCatalogs.length;n++){InMemorySessionTransport t=rig(new SessionCatalog(malformedCatalogs[n],mappings(),false));discovery(t);check(t.engine.outcome().equals("MALFORMED_WIRE")&&t.engine.registrySize()==0,"duplicate/malformed/missing required discovery "+n);}
  byte[] tooMany=base;for(int id=100;id<115;id++)tooMany=join(tooMany,new byte[]{10,2,8,(byte)id});
  InMemorySessionTransport t=rig(new SessionCatalog(tooMany,mappings(),false));discovery(t);check(t.engine.outcome().equals("MALFORMED_WIRE"),"excessive service count17");
  List<SessionCatalog.Binding> zero=Arrays.asList(new SessionCatalog.Binding(1,0,AaServiceRegistry.Kind.VIDEO),new SessionCatalog.Binding(2,2,AaServiceRegistry.Kind.INPUT));
  t=rig(new SessionCatalog(base,zero,false));discovery(t);check(t.engine.outcome().equals("LOCAL_DISCOVERY_MAPPING_ERROR"),"channel zero misuse");
  t=rig();t.engine.transportReady();incoming(t,"open-video");check(t.engine.state()==SimulatedSessionEngine.State.ERROR,"service channel before discovery");
  t=rig();discovery(t);incoming(t,"open-input");t.engine.receive(IndependentFixtures.hex("0203000480000803"));check(t.engine.state()==SimulatedSessionEngine.State.ERROR,"media sent to wrong input service");
  t=rig();discovery(t);incoming(t,"open-video");incoming(t,"open-video");check(t.engine.state()==SimulatedSessionEngine.State.ERROR,"duplicate channel open");
  t.reset();video(t);check(t.engine.state()==SimulatedSessionEngine.State.VIDEO_SERVICE_AVAILABLE,"channel reused only after new session");
  AaServiceRegistry registry=new AaServiceRegistry(16);for(int id=1;id<=16;id++)registry.register(id,id,AaServiceRegistry.Kind.SENSOR);
  boolean rejected=false;try{registry.register(17,17,AaServiceRegistry.Kind.SENSOR);}catch(IllegalArgumentException e){rejected=true;}check(rejected&&registry.entries().size()==16,"registry maximum16 refuses17");
  t=rig();t.engine.transportReady();t.engine.beginVersion();incoming(t,"malformed-version");check(t.engine.outcome().equals("MALFORMED_WIRE"),"malformed version base payload");
  t=rig();version(t);incoming(t,"version-response");check(t.engine.state()==SimulatedSessionEngine.State.ERROR,"duplicate version after establishment");
  t=rig();discovery(t);incoming(t,"discovery-request");check(t.engine.state()==SimulatedSessionEngine.State.ERROR,"repeated discovery state error");
  t=rig();video(t);t.engine.receive(IndependentFixtures.hex("0103000580000a0101"));check(t.engine.outcome().equals("MALFORMED_WIRE"),"setup known field wrong wire");
  t=rig();setup(t);t.engine.receive(IndependentFixtures.hex("0103000480010801"));check(t.engine.outcome().equals("MALFORMED_WIRE"),"malformed start missing config while legal inspection state");
  byte[] extended=join(base,IndependentFixtures.hex("980607"));SessionCatalog c=new SessionCatalog(extended,mappings(),false);
  check(Arrays.equals(c.prepare().decoded.originalEncoding(),extended),"discovery nested/root unknown lossless");
  check(DiscoveryCodec.decode(base).input.width==DiscoveryCodec.decode(f("discovery-experimental")).input.width&&DiscoveryCodec.decode(base).input.height==720,"video profile cannot silently alter input geometry");
  t=rig();t.engine.transportReady();t.engine.beginVersion();t.engine.receive(IndependentFixtures.hex("0003000b0002000100010000980607"));check(t.engine.outcome().equals("UNKNOWN_VERSION_EXTENSION")&&Arrays.equals(t.engine.preservedUnknown(),IndependentFixtures.hex("000100010000980607")),"version is raw not protobuf; unknown suffix retained but not invented or labeled malformed");
  t=rig();discovery(t);t.engine.receive(IndependentFixtures.hex("000300047fff0800"));check(t.engine.outcome().equals("B_VALID_ENVELOPE_UNSUPPORTED_MESSAGE")&&t.engine.registrySize()==2,"B unsupported control preserves other service state");incoming(t,"open-video");check(t.engine.state()==SimulatedSessionEngine.State.VIDEO_SERVICE_AVAILABLE,"valid later message after B rejection");
  t=rig();t.engine.transportReady();t.clock.time=-1;t.engine.tick();check(t.engine.outcome().equals("CLOCK_ERROR"),"fake monotonic reversal fails closed");
  int edges=0,errors=0;for(SimulatedSessionEngine.State from:SimulatedSessionEngine.State.values())for(SimulatedSessionEngine.State to:SimulatedSessionEngine.State.values())if(SimulatedSessionEngine.legalEdge(from,to)){if(to==SimulatedSessionEngine.State.ERROR)errors++;else edges++;check(SimulatedSessionEngine.edgeConfidence(from,to)!=SimulatedSessionEngine.Confidence.UNKNOWN,"edge confidence explicit");}
  check(edges==18&&errors==9,"central graph18 non-error edges plus9 invalidation edges");
  t=rig();discovery(t);for(int n=0;n<33;n++)t.engine.receive(f("ping-unknown"));check(t.engine.outcome().equals("BOUNDS_OUTBOUND")&&t.engine.drainOutbound().isEmpty(),"outbound queue bound clears pending output");
  t=rig();discovery(t);byte[] opaque=new byte[16388];opaque[1]=11;opaque[2]=64;
  for(int n=0;n<32&&!t.engine.terminal();n++)t.engine.receive(opaque);
  int chars=0;for(String row:t.engine.transcript())chars+=row.length();check(t.engine.outcome().equals("BOUNDS_TRANSCRIPT")&&chars<=1048576&&t.engine.transcript().size()<=1024,"transcript raw-byte retention bounded");
  t=rig();discovery(t);for(int n=0;n<129;n++)t.engine.receive(IndependentFixtures.hex("000300027fff"));check(t.engine.outcome().equals("BOUNDS_STEPS")&&t.engine.registrySize()==0,"conversation step bound");
  t=rig();t.engine.transportReady();t.engine.receive(new byte[65537]);check(t.engine.outcome().equals("BOUNDS_INPUT_BATCH"),"incoming batch max+1");
 }
 private static void property(){
  Random random=new Random(SEED);final int sequences=15000,events=24;
  for(int n=0;n<sequences;n++){
   InMemorySessionTransport t=rig();prop(t.engine.state()==SimulatedSessionEngine.State.NEW&&t.engine.transcript().isEmpty(),"constructor no progression");
   for(int k=0;k<events;k++){
    SimulatedSessionEngine.State before=t.engine.state();boolean ended=t.engine.terminal();int action=random.nextInt(12);
    switch(action){case 0:t.engine.transportReady();break;case 1:t.engine.beginVersion();break;case 2:incoming(t,"version-response");break;case 3:t.engine.enterPlaintextSimulation();break;case 4:incoming(t,"discovery-request");break;case 5:incoming(t,"open-video");break;case 6:incoming(t,"media-setup");break;case 7:incoming(t,"media-start");break;case 8:t.advanceTo(t.clock.time+random.nextInt(1100));break;case 9:t.eof();break;case 10:incoming(t,"ping-unknown");break;default:incoming(t,"malformed-frame");}
    prop(!ended||t.engine.state()==before,"terminal cannot resurrect");prop(t.engine.registrySize()<=16,"registry bound");prop(!t.engine.experimentalOptIn(),"conservative default fixed");
    byte[] unknown=payload("ping-unknown");prop(Arrays.equals(ProtoWire.parse(unknown).encoded(),unknown),"unknown bytes preserved");
    if(t.engine.terminal()&&random.nextInt(8)==0){SimulatedSessionEngine old=t.engine;t.reset();prop(t.engine.state()==SimulatedSessionEngine.State.NEW&&t.engine.registrySize()==0&&old.terminal(),"explicit new reset clean");}
   }
  }
  System.out.println("SESSION_PROPERTY sequences="+sequences+" events="+events+" seed="+SEED);
 }
 public static void main(String[] args)throws Exception{fixtures=new File(args[0]);out=new File(args[1]);if(!out.mkdir())throw new IOException("Fresh transcript directory required");scenarios();matrix();hardening();property();System.out.println("RESULT PASS deterministic="+deterministic+" propertyChecks="+properties+" sequences=15000 seed="+SEED+" transcripts="+transcripts);}
}
