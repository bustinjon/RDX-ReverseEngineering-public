package com.rdx.fullscreen.clean;
import java.io.*;
import java.util.*;
/** Independent fixture and deterministic host-event tests; no Android objects instantiated. */
public final class HondaMediaTests {
 private static File fixtures,oldFixtures,out;private static int checks,properties,transcripts;
 private static final long SEED=0x484f4e44414d37L;
 private static final Map<String,byte[]> cache=new HashMap<String,byte[]>();
 private static void check(boolean ok,String why){checks++;if(!ok)throw new AssertionError(why);}
 private static void prop(boolean ok,String why){properties++;if(!ok)throw new AssertionError(why+" seed="+SEED+" assertion="+properties);}
 private static byte[] read(File root,String id){String key=root+"/"+id;byte[] b=cache.get(key);if(b==null)try{File f=new File(root,id+".bin");if(f.length()>65536)throw new IOException("fixture bound");b=new byte[(int)f.length()];DataInputStream in=new DataInputStream(new FileInputStream(f));try{in.readFully(b);}finally{in.close();}cache.put(key,b);}catch(IOException x){throw new IllegalStateException(x);}return b.clone();}
 private static byte[] f(String id){return read(fixtures,id);}private static byte[] p(String id){byte[] b=f(id);return Arrays.copyOfRange(b,6,b.length);}
 private static byte[] h(String hex){return IndependentFixtures.hex(hex);}
 private static byte[] wire(int channel,int type,byte[] payload){byte[] b=new byte[6+payload.length];b[0]=(byte)channel;b[1]=3;b[2]=(byte)((payload.length+2)>>>8);b[3]=(byte)(payload.length+2);b[4]=(byte)(type>>>8);b[5]=(byte)type;System.arraycopy(payload,0,b,6,payload.length);return b;}
 private interface Action {void run();}
 private static void rejects(Action a,String why){boolean rejected=false;try{a.run();}catch(IllegalArgumentException x){rejected=true;}check(rejected,why);}
 private static HondaMediaMessages.MediaConfig config(String id){return HondaMediaMessages.MediaConfig.parse(p(id));}
 private static final class Rig {
  final InMemorySessionTransport.Clock clock=new InMemorySessionTransport.Clock();
  SimulatedSessionEngine e;
  Rig(boolean experimental){e=new SimulatedSessionEngine(clock,new SessionPolicy(10,20,100,1000),experimental?SessionCatalog.experimental():SessionCatalog.conservative(),true);}
  void old(String id){e.receive(read(oldFixtures,id));}
  void input(String id){e.receive(f(id));}
  void video(){e.transportReady();e.beginVersion();old("version-response");e.enterPlaintextSimulation();old("discovery-request");old("open-video");}
  void setup(){video();input("setup-h264");}
  void ready(){setup();e.advertiseMediaConfig(config("config-ready-one"));}
  void selected(){ready();input("start-one");}
 }
 private static void save(String id,Rig r)throws Exception{PrintWriter w=new PrintWriter(new OutputStreamWriter(new FileOutputStream(new File(out,id+".txt")),"UTF-8"));try{w.println("SYNTHETIC ONLY; plaintext security bypass; no decode/render/phone acceptance");for(String s:r.e.transcript())w.println(s);w.println("CONTROL="+r.e.state()+" MEDIA="+r.e.mediaState()+" FURTHEST="+r.e.progression()+" OUTCOME="+r.e.outcome());}finally{w.close();}transcripts++;}
 private static boolean lastWire(Rig r,String fixture){List<byte[]> b=r.e.drainOutbound();return !b.isEmpty()&&Arrays.equals(b.get(b.size()-1),f(fixture));}
 private static void codecs(){
  check(HondaMediaMessages.MediaSetup.parse(p("setup-h264")).codec.supportedVideo(),"codec3 H264");
  check(Arrays.equals(HondaMediaMessages.MediaSetup.create(HondaMediaMessages.CodecType.H264_BASELINE).encode(),p("setup-h264")),"independent Setup encoder");
  rejects(new Action(){public void run(){HondaMediaMessages.MediaSetup.parse(p("setup-missing"));}},"required codec");
  rejects(new Action(){public void run(){HondaMediaMessages.MediaSetup.parse(p("setup-wrongwire"));}},"codec wire type");
  check(!HondaMediaMessages.MediaSetup.parse(p("setup-unknown")).codec.supportedVideo(),"unknown codec bounded/retained");
  check(HondaMediaMessages.MediaSetup.parse(p("setup-duplicate")).codec.supportedVideo(),"duplicate singular uses protobuf last value");
  check(Arrays.equals(HondaMediaMessages.MediaSetup.parse(p("setup-duplicate")).encode(),p("setup-duplicate")),"duplicate original bytes retained");
  check(Arrays.equals(HondaMediaMessages.MediaSetup.parse(p("setup-unknownfield")).encode(),p("setup-unknownfield")),"Setup unknown field lossless");
  rejects(new Action(){public void run(){HondaMediaMessages.MediaSetup.parse(new byte[65537]);}},"excessive Setup");
  check(MediaConfigStatus.STATUS_WAIT.wire==1&&MediaConfigStatus.STATUS_READY.wire==2&&MediaConfigStatus.fromWire(0)==null,"separate status domain");
  for(String id:new String[]{"config-ready-one","config-ready-two","config-wait","config-no-window","config-empty","config-unknownfield"}){
   HondaMediaMessages.MediaConfig c=config(id);c.validateAdvertisement(2);check(Arrays.equals(c.encode(),p(id)),"Config original bytes "+id);
   List<HondaMediaMessages.VideoConfigurationIndex> indices=c.indices();
   byte[] fresh=HondaMediaMessages.MediaConfig.create(c.status,c.hasMaxUnacked?Long.valueOf(c.maxUnacked):null,indices).encode();
   if(!id.equals("config-unknownfield"))check(Arrays.equals(fresh,p(id)),"independent Config encoding "+id);
  }
  check(config("config-wait").status==MediaConfigStatus.STATUS_WAIT,"WAIT not failure or READY");
  check(!config("config-no-window").hasMaxUnacked,"Honda max-unacked optional");
  check(config("config-empty").indices().isEmpty(),"empty index list accepted, selects nothing");
  for(final String id:new String[]{"config-zero","config-unknown"}){check(config(id).status==null,"unknown status inspectable "+id);check(Arrays.equals(config(id).encode(),p(id)),"unknown enum raw preserved");rejects(new Action(){public void run(){config(id).validateAdvertisement(1);}},"unknown status not advertisable "+id);}
  for(final String raw:new String[]{"1010","080210801800","0a0102","0802101018001800","080210001800","088080808080808080808002"})rejects(new Action(){public void run(){HondaMediaMessages.MediaConfig.parse(h(raw)).validateAdvertisement(1);}},"Config malformed/local invalid "+raw);
  rejects(new Action(){public void run(){ProtoWire.Writer w=new ProtoWire.Writer().uint32(1,2);for(int i=0;i<9;i++)w.uint32(3,i);HondaMediaMessages.MediaConfig.parse(w.finish());}},"excessive index count");
  List<HondaMediaMessages.VideoConfigurationIndex> max=new ArrayList<HondaMediaMessages.VideoConfigurationIndex>();for(int i=0;i<8;i++)max.add(new HondaMediaMessages.VideoConfigurationIndex(i));
  HondaMediaMessages.MediaConfig.create(MediaConfigStatus.STATUS_READY,null,max).validateAdvertisement(8);check(true,"max8 valid");
  for(int count:new int[]{7,8}){List<HondaMediaMessages.VideoConfigurationIndex> indices=max.subList(0,count);check(HondaMediaMessages.MediaConfig.create(MediaConfigStatus.STATUS_READY,Long.valueOf(16),indices).indices().size()==count,"index max-1/max");}
  check(HondaMediaMessages.CodecType.H264_BASELINE.wire==3&&new HondaMediaMessages.VideoConfigurationIndex(3).value==3,"separate Java types despite equal number");
  for(String id:new String[]{"start-one","start-unknownfield"})check(Arrays.equals(HondaMediaMessages.MediaStart.parse(p(id)).encode(),p(id)),"Start lossless "+id);
  check(Arrays.equals(HondaMediaMessages.MediaStart.create(1,new HondaMediaMessages.VideoConfigurationIndex(0)).encode(),p("start-one")),"Start encoder independent");
  rejects(new Action(){public void run(){HondaMediaMessages.MediaStart.parse(h("0801"));}},"Start missing index");
  rejects(new Action(){public void run(){HondaMediaMessages.MediaStart.parse(h("0801120100"));}},"Start wrong wire");
  rejects(new Action(){public void run(){HondaMediaMessages.MediaStart.parse(h("08ffffffffffffffffff011000"));}},"negative session outside narrow target subset");
  for(String id:new String[]{"ack-one","ack-unknownfield"})check(Arrays.equals(HondaMediaMessages.MediaAck.parse(p(id)).encode(),p(id)),"Ack lossless "+id);
  check(Arrays.equals(HondaMediaMessages.MediaAck.accounting(1,1).encode(),p("ack-one")),"ACK independent encoder");
  for(final int n:new int[]{0,33})rejects(new Action(){public void run(){HondaMediaMessages.MediaAck.accounting(1,n);}},"ACK local count bound "+n);
  check(HondaMediaMessages.MediaAck.accounting(1,31).count==31&&HondaMediaMessages.MediaAck.accounting(1,32).count==32,"ACK max-1/max");
  check(Arrays.equals(HondaMediaMessages.ProjectedFocus.create().encode(),p("focus-projected")),"focus literal match");
  byte[] unknown=h("08011001980607");check(Arrays.equals(HondaMediaMessages.ProjectedFocus.parse(unknown).encode(),unknown),"focus unknown field retained");
  rejects(new Action(){public void run(){HondaMediaMessages.ProjectedFocus.parse(h("0801"));}},"focus required flag narrow subset");
 }
 private static void scenarios()throws Exception{
  Rig r=new Rig(false);check(r.e.state()==SimulatedSessionEngine.State.NEW&&r.e.mediaState()==HondaMediaFlow.State.IDLE&&r.e.transcript().isEmpty()&&r.e.drainOutbound().isEmpty(),"constructor inert");
  r.ready();check(lastWire(r,"config-ready-one"),"READY exact outbound wire");r.input("start-one");check(r.e.mediaState()==HondaMediaFlow.State.MEDIA_CONFIGURATION_SELECTED,"conservative selection");check(!r.e.experimentalOptIn(),"conservative default");save("A-conservative",r);
  int setup=-1,serialized=-1,select=-1,start=-1;List<String> rows=r.e.transcript();for(int i=0;i<rows.size();i++){String s=rows.get(i);if(s.contains("onMediaSetup"))setup=i;if(s.contains("ConfigSerialized"))serialized=i;if(s.contains("onConfigurationSelected"))select=i;if(s.contains("onMediaStartObserved"))start=i;}
  check(setup>=0&&setup<serialized&&serialized<select&&select<start,"callback order setup before serialization; select before start observation");
  r=new Rig(true);r.selected();check(r.e.experimentalOptIn()&&r.e.progression().equals("MEDIA_CONFIGURATION_SELECTED"),"experimental explicit selection");check(DiscoveryCodec.decode(SessionCatalog.experimental().bytes()).video.get(0).placement==VideoConfig.Placement.UNSPECIFIED,"crop unspecified");save("B-experimental",r);
  r=new Rig(false);r.setup();r.e.advertiseMediaConfig(config("config-wait"));check(lastWire(r,"config-wait"),"WAIT exact wire");r.input("start-one");check(r.e.mediaState()==HondaMediaFlow.State.MEDIA_CONFIG_WAIT_ADVERTISED&&r.e.outcome().equals("B_START_REQUIRES_READY_CONFIG"),"WAIT cannot Start");save("C-wait",r);
  r.e.advertiseMediaConfig(config("config-ready-one"));r.input("start-one");check(r.e.mediaState()==HondaMediaFlow.State.MEDIA_CONFIGURATION_SELECTED,"explicit synthetic policy WAIT to READY");save("C2-explicit-readiness-policy",r);
  r=new Rig(false);r.video();r.input("setup-unknown");check(r.e.mediaState()==HondaMediaFlow.State.IDLE&&!r.e.terminal()&&r.e.registrySize()==2,"unknown codec isolates message");r.input("setup-h264");check(r.e.mediaState()==HondaMediaFlow.State.MEDIA_SETUP_RECEIVED,"valid later setup after unknown codec");save("D-bad-codec",r);
  r=new Rig(false);r.ready();r.input("start-bad");check(r.e.mediaState()==HondaMediaFlow.State.MEDIA_CONFIG_ADVERTISED&&r.e.outcome().equals("B_UNADVERTISED_CONFIGURATION"),"codec value3 not allowed config index");save("E-bad-index",r);
  r=new Rig(false);r.setup();r.input("setup-h264");check(r.e.mediaState()==HondaMediaFlow.State.MEDIA_SETUP_RECEIVED&&r.e.outcome().equals("B_DUPLICATE_OR_ILLEGAL_SETUP"),"duplicate Setup no callback repetition");save("F-duplicate-setup",r);
  r=new Rig(false);r.setup();r.input("start-one");check(r.e.mediaState()==HondaMediaFlow.State.MEDIA_SETUP_RECEIVED&&r.e.outcome().equals("B_START_REQUIRES_READY_CONFIG"),"Start before Config");save("G-start-before-config",r);
  r=new Rig(false);r.ready();r.e.optionalProjectedFocus(true);check(lastWire(r,"focus-projected"),"optional focus exact wire");r.input("start-one");check(r.e.mediaState()==HondaMediaFlow.State.MEDIA_CONFIGURATION_SELECTED,"optional focus no extra prerequisite");save("H-optional-focus",r);
  r=new Rig(false);r.selected();r.e.drainOutbound();HondaMediaFlow.State before=r.e.mediaState();r.e.accountMedia(1,HondaMediaFlow.AccountingReason.INPUT_FAILURE_ACCOUNTED);check(lastWire(r,"ack-one")&&r.e.mediaState()==before,"failure accounting ACK no running/display transition");save("I-input-failure-accounting",r);
  for(HondaMediaFlow.AccountingReason reason:HondaMediaFlow.AccountingReason.values()){r.e.accountMedia(1,reason);check(r.e.mediaState()==before,"ACK all reasons no progression "+reason);}
  r=new Rig(false);r.ready();r.input("start-one");r.e.drainOutbound();r.input("start-one");check(r.e.drainOutbound().isEmpty()&&r.e.outcome().equals("B_START_REQUIRES_READY_CONFIG"),"duplicate Start no reselect/send");
  r=new Rig(false);r.video();r.input("start-one");check(r.e.mediaState()==HondaMediaFlow.State.IDLE,"Start before Setup no advance");
  r=new Rig(false);r.setup();r.e.optionalProjectedFocus(true);check(r.e.mediaState()==HondaMediaFlow.State.MEDIA_SETUP_RECEIVED&&r.e.outcome().equals("B_OPTIONAL_FOCUS_WRONG_STATE"),"focus cannot bypass config");
  r=new Rig(false);r.ready();r.e.drainOutbound();r.e.optionalProjectedFocus(false);check(r.e.drainOutbound().isEmpty(),"focus false produces no bytes");
  r=new Rig(false);r.setup();r.e.advertiseMediaConfig(config("config-empty"));r.input("start-one");check(r.e.outcome().equals("B_UNADVERTISED_CONFIGURATION"),"empty allowed list selects nothing");
  for(String id:new String[]{"config-zero","config-unknown"}){r=new Rig(false);r.setup();r.e.drainOutbound();r.e.advertiseMediaConfig(config(id));check(r.e.drainOutbound().isEmpty()&&r.e.mediaState()==HondaMediaFlow.State.MEDIA_SETUP_RECEIVED,"invalid status no ready "+id);}
  for(String id:new String[]{"setup-missing","setup-wrongwire"}){r=new Rig(false);r.video();r.input(id);check(r.e.state()==SimulatedSessionEngine.State.ERROR,"malformed Setup invalidates "+id);}
  r=new Rig(false);r.video();r.e.receive(wire(2,0x8000,h("0803")));check(r.e.terminal(),"wrong service Setup");
  r=new Rig(false);r.video();r.e.receive(wire(0,0x8000,h("0803")));check(r.e.terminal(),"wrong control Setup");
  r=new Rig(false);r.setup();r.e.receive(wire(2,0x8001,h("08011000")));check(r.e.terminal(),"wrong channel Start");
  r=new Rig(false);r.video();r.e.receive(wire(1,0x8001,h("0801")));check(r.e.outcome().equals("MALFORMED_WIRE"),"malformed Start invalidates");
  for(String id:new String[]{"config-ready-one","ack-one","focus-projected"}){r=new Rig(false);r.video();r.input(id);check(r.e.outcome().equals("B_WRONG_MEDIA_DIRECTION")&&r.e.mediaState()==HondaMediaFlow.State.IDLE,"wrong inbound direction "+id);}
  r=new Rig(false);r.setup();r.e.accountMedia(1,HondaMediaFlow.AccountingReason.INPUT_FAILURE_ACCOUNTED);check(r.e.outcome().equals("B_ACCOUNTING_WRONG_STATE"),"ACK not Start response");
  r=new Rig(false);r.selected();SimulatedSessionEngine old=r.e;r.e.eof();r.e=old.resetForNewSession();check(old.terminal()&&r.e.mediaState()==HondaMediaFlow.State.IDLE&&r.e.state()==SimulatedSessionEngine.State.NEW,"reset clears selected media session");
  r=new Rig(false);r.video();r.input("setup-unknownfield");check(Arrays.equals(r.e.preservedUnknown(),p("setup-unknownfield")),"engine Setup unknown raw");r.e.advertiseMediaConfig(config("config-unknownfield"));check(lastWire(r,"config-unknownfield"),"unknown Config survives outbound");r.input("start-unknownfield");check(Arrays.equals(r.e.preservedUnknown(),p("start-unknownfield")),"engine Start unknown raw");
 }
 private static void additional()throws Exception{
  Rig r=new Rig(false);r.e.receive(f("setup-h264"));check(r.e.terminal(),"Setup illegal before discovery");
  r=new Rig(false);r.ready();r.input("setup-h264");check(r.e.mediaState()==HondaMediaFlow.State.MEDIA_CONFIG_ADVERTISED,"duplicate Setup after READY cannot reset");
  r=new Rig(false);r.selected();r.input("setup-h264");check(r.e.mediaState()==HondaMediaFlow.State.MEDIA_CONFIGURATION_SELECTED,"duplicate Setup after selection cannot reset");
  r=new Rig(false);r.setup();r.e.advertiseMediaConfig(null);check(r.e.outcome().equals("B_INVALID_LOCAL_MEDIA_CONFIG")&&!r.e.terminal(),"null local config rejected");
  r=new Rig(false);r.ready();r.e.drainOutbound();r.input("start-one");check(r.e.drainOutbound().isEmpty(),"Start sends no automatic ACK or success message");
  r=new Rig(false);r.selected();r.e.beginStop();r.e.receive(read(oldFixtures,"shutdown-response"));r.e.accountMedia(1,HondaMediaFlow.AccountingReason.INPUT_FAILURE_ACCOUNTED);check(r.e.state()==SimulatedSessionEngine.State.CLOSED&&r.e.mediaState()==HondaMediaFlow.State.CLOSED,"closed accounting cannot revive");
  r=new Rig(false);r.video();byte[] unknown=h("0803980607");for(byte octet:wire(1,0x8000,unknown))r.e.receive(new byte[]{octet});check(r.e.mediaState()==HondaMediaFlow.State.MEDIA_SETUP_RECEIVED&&Arrays.equals(r.e.preservedUnknown(),unknown),"new typed Setup across one-byte host chunks");
  rejects(new Action(){public void run(){HondaMediaMessages.MediaConfig.parse(new byte[65537]);}},"Config max payload+1");
  rejects(new Action(){public void run(){HondaMediaMessages.MediaConfig.parse(h("080210ffffffff1f"));}},"Config uint32 overflow");
  rejects(new Action(){public void run(){new HondaMediaMessages.VideoConfigurationIndex(-1);}},"negative index");
  rejects(new Action(){public void run(){new HondaMediaMessages.VideoConfigurationIndex(0x100000000L);}},"index uint32 overflow");
  HondaMediaMessages.MediaSetup nonminimal=HondaMediaMessages.MediaSetup.parse(h("088300"));check(nonminimal.codec.supportedVideo()&&Arrays.equals(nonminimal.encode(),h("088300")),"nonminimal supported protobuf varint preserved");
  check(Arrays.equals(config("config-ready-two").encode(),h("0802101018001801")),"two-config literal wire independent");
  AaServiceRegistry registry=new AaServiceRegistry();registry.register(1,1,AaServiceRegistry.Kind.VIDEO);registry.register(2,2,AaServiceRegistry.Kind.INPUT);
  AaServiceDiscovery caps=new AaServiceDiscovery(Arrays.asList(VideoConfig.conservative(),new VideoConfig(1280,720,0,32,229,30)),InputConfig.hondaReference());
  SessionCatalog catalog=new SessionCatalog(DiscoveryCodec.encode(caps,registry),Arrays.asList(new SessionCatalog.Binding(1,1,AaServiceRegistry.Kind.VIDEO),new SessionCatalog.Binding(2,2,AaServiceRegistry.Kind.INPUT)),false);
  r=new Rig(false);r.e=new SimulatedSessionEngine(r.clock,new SessionPolicy(10,20,100,1000),catalog,true);r.setup();r.e.advertiseMediaConfig(config("config-ready-two"));check(lastWire(r,"config-ready-two"),"two actual discovery configs advertised");
  r.e.receive(wire(1,0x8001,h("08011001")));check(r.e.mediaState()==HondaMediaFlow.State.MEDIA_CONFIGURATION_SELECTED,"Start index1 selects second offered config");save("J-two-config-selection",r);
  r=new Rig(false);r.e=new SimulatedSessionEngine(r.clock,new SessionPolicy(10,20,100,1000),catalog,true);r.setup();
  HondaMediaMessages.MediaConfig subset=HondaMediaMessages.MediaConfig.create(MediaConfigStatus.STATUS_READY,Long.valueOf(16),Collections.singletonList(new HondaMediaMessages.VideoConfigurationIndex(1)));r.e.advertiseMediaConfig(subset);r.input("start-one");check(r.e.outcome().equals("B_UNADVERTISED_CONFIGURATION"),"Start index0 rejected when only index1 advertised despite catalog containing0");
  r.e.receive(wire(1,0x8001,h("08011001")));check(r.e.mediaState()==HondaMediaFlow.State.MEDIA_CONFIGURATION_SELECTED,"allowed subset index1 accepted");
  r=new Rig(false);r.setup();r.e.advertiseMediaConfig(config("config-no-window"));check(lastWire(r,"config-no-window"),"optional window absent session path");r.input("start-one");check(r.e.mediaState()==HondaMediaFlow.State.MEDIA_CONFIGURATION_SELECTED,"missing optional window does not invent protocol requirement");
  for(String id:new String[]{"setup-h264","setup-missing","setup-wrongwire","setup-unknown","setup-duplicate","setup-unknownfield","config-wait","config-ready-one","config-ready-two","config-zero","config-unknown","config-no-window","config-empty","start-one","start-bad","ack-one","focus-projected","config-unknownfield","start-unknownfield","ack-unknownfield"}){
   byte[] b=f(id);check(((b[2]&255)*256+(b[3]&255))==b.length-4,"all literal fixture lengths "+id);
  }
 }
 private static void property(){
  Random random=new Random(SEED);
  for(int n=0;n<15000;n++){
   Rig r=new Rig(false);int initial=random.nextInt(5);r.video();if(initial>0)r.input("setup-h264");if(initial==2)r.e.advertiseMediaConfig(config("config-wait"));if(initial>=3)r.e.advertiseMediaConfig(config("config-ready-one"));if(initial==4)r.input("start-one");
   for(int k=0;k<20;k++){
    boolean ended=r.e.terminal();SimulatedSessionEngine.State parent=r.e.state();HondaMediaFlow.State before=r.e.mediaState();int event=random.nextInt(14);
    switch(event){case 0:r.input("setup-h264");break;case 1:r.input("setup-unknown");break;case 2:r.e.advertiseMediaConfig(config("config-wait"));break;case 3:r.e.advertiseMediaConfig(config("config-ready-one"));break;case 4:r.input("start-one");break;case 5:r.input("start-bad");break;case 6:r.e.optionalProjectedFocus(true);break;case 7:r.e.accountMedia(1,HondaMediaFlow.AccountingReason.INPUT_FAILURE_ACCOUNTED);break;case 8:r.e.advertiseMediaConfig(config("config-zero"));break;case 9:r.e.advertiseMediaConfig(config("config-unknown"));break;case 10:r.input("setup-unknownfield");break;case 11:r.e.receive(h("0103000480010801"));break;case 12:r.e.eof();break;default:r.e.optionalProjectedFocus(false);}
    HondaMediaFlow.State after=r.e.mediaState();
    prop(!ended||r.e.state()==parent,"terminal parent cannot resurrect");
    prop(!ended||after==before,"terminal media cannot resurrect");
    prop(!r.e.experimentalOptIn(),"experimental never default");
    prop((event!=8&&event!=9)||after==before,"status0/unknown cannot change readiness");
    prop(after!=HondaMediaFlow.State.MEDIA_CONFIGURATION_SELECTED||before==after||(event==4&&before==HondaMediaFlow.State.MEDIA_CONFIG_ADVERTISED),"only Start allowed index can select");
    prop((event!=5&&event!=6&&event!=7)||after==before,"bad index/focus/ACK cannot advance");
    prop(r.e.registrySize()<=16,"registry bounded");
    prop(Arrays.equals(HondaMediaMessages.MediaSetup.parse(p("setup-unknownfield")).encode(),p("setup-unknownfield")),"lossless unknown fields");
    r.e.drainOutbound();
   }
   SimulatedSessionEngine old=r.e;SimulatedSessionEngine next=old.resetForNewSession();prop(next.state()==SimulatedSessionEngine.State.NEW&&next.mediaState()==HondaMediaFlow.State.IDLE,"explicit reset clean");
  }
 }
 public static void main(String[] args)throws Exception{fixtures=new File(args[0]);oldFixtures=new File(fixtures.getParentFile(),"session");out=new File(args[1]);if(!out.mkdir())throw new IOException("Fresh transcripts required");codecs();scenarios();additional();property();System.out.println("RESULT PASS deterministic="+checks+" propertyChecks="+properties+" sequences=15000 events=20 seed="+SEED+" transcripts="+transcripts);}
}

