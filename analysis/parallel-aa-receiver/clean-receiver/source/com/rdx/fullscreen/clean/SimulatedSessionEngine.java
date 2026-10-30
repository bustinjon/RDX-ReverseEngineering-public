package com.rdx.fullscreen.clean;
import java.util.*;

/** HOST-SIMULATION engine. Queues byte arrays only; never owns a transport, TLS or decoder. */
public final class SimulatedSessionEngine {
 public enum State { NEW,TRANSPORT_READY,VERSION_PENDING,VERSION_ESTABLISHED,DISCOVERY_PENDING,
  SERVICES_ADVERTISED,VIDEO_SERVICE_AVAILABLE,MEDIA_SETUP_PENDING,STOPPING,CLOSED,ERROR }
 public enum Confidence { CONFIRMED,STRONGLY_INFERRED,IMPLEMENTATION_STRUCTURE,UNKNOWN }
 public static final int MAX_TRANSCRIPT_ROWS=1024,MAX_TRANSCRIPT_CHARS=1048576,MAX_OUTBOUND=32;
 private final SessionPolicy.Clock clock;private final SessionPolicy policy;private final SessionCatalog catalog;
 private final AaFrameParser parser=new AaFrameParser(ProtocolLimits.FRAME_BODY,ProtocolLimits.MESSAGE,ProtocolLimits.FRAMES_PER_FEED);
 private final AaMessageAssembler assembler=new AaMessageAssembler(ProtocolLimits.MESSAGE,ProtocolLimits.PARTIAL_CHANNELS,ProtocolLimits.RESERVED_BYTES);
 private AaServiceRegistry registry=new AaServiceRegistry(ProtocolLimits.SERVICES);
 private final Set<Integer> opened=new HashSet<Integer>();private final Map<Integer,Long> fragmentSince=new HashMap<Integer,Long>();
 private final List<byte[]> outbound=new ArrayList<byte[]>();private final List<String> transcript=new ArrayList<String>();
 private final HondaMediaFlow media;private int videoConfigurations,videoChannel=-1;
 private State state=State.NEW;private long now=-1,activityAt=-1,frameAt=-1,responseAt=-1;private int chars,steps,transitions;
 private byte[] lastUnknown=new byte[0];private String outcome="NONE";
 public SimulatedSessionEngine(SessionPolicy.Clock c,SessionPolicy p){this(c,p,SessionCatalog.conservative());}
 public SimulatedSessionEngine(SessionPolicy.Clock c,SessionPolicy p,SessionCatalog caps){
  this(c,p,caps,false);
 }
 /** Explicit Honda profile; false retains historical inspection-only behavior. */
 public SimulatedSessionEngine(SessionPolicy.Clock c,SessionPolicy p,SessionCatalog caps,boolean hondaMedia){
  media=hondaMedia?new HondaMediaFlow():null;
  if(c==null||p==null||caps==null)throw new IllegalArgumentException("Clock/policy/catalog required");clock=c;policy=p;catalog=caps;
 }
 public State state(){return state;} public String outcome(){return outcome;}
 public boolean terminal(){return state==State.ERROR||state==State.CLOSED;}
 public int registrySize(){return registry.entries().size();} public int reservationBytes(){return assembler.reservedBytes();}
 public int partialFrameBytes(){return parser.bufferedBytes();} public int transitionCount(){return transitions;}
 public boolean experimentalOptIn(){return catalog.experimentalOptIn;}
 public byte[] preservedUnknown(){return lastUnknown.clone();}
 public List<String> transcript(){return Collections.unmodifiableList(new ArrayList<String>(transcript));}
 public List<byte[]> drainOutbound(){List<byte[]> out=new ArrayList<byte[]>();for(byte[] b:outbound)out.add(b.clone());outbound.clear();return out;}
 public SimulatedSessionEngine resetForNewSession(){return new SimulatedSessionEngine(clock,policy,catalog,media!=null);}
 public static Confidence stateConfidence(State s){return s==State.MEDIA_SETUP_PENDING?Confidence.STRONGLY_INFERRED:Confidence.IMPLEMENTATION_STRUCTURE;}
 /** Auditable local sequencing graph:18 non-error edges, not a claim of18 protocol messages. */
 public static boolean legalEdge(State a,State b){
  if(b==State.ERROR)return a!=State.ERROR&&a!=State.CLOSED;
  if(b==State.CLOSED)return a==State.NEW||a==State.TRANSPORT_READY||a==State.VERSION_ESTABLISHED||a==State.SERVICES_ADVERTISED||a==State.VIDEO_SERVICE_AVAILABLE||a==State.MEDIA_SETUP_PENDING||a==State.STOPPING;
  return a==State.NEW&&b==State.TRANSPORT_READY||a==State.TRANSPORT_READY&&b==State.VERSION_PENDING||a==State.VERSION_PENDING&&b==State.VERSION_ESTABLISHED||a==State.VERSION_ESTABLISHED&&b==State.DISCOVERY_PENDING||a==State.DISCOVERY_PENDING&&b==State.SERVICES_ADVERTISED||a==State.SERVICES_ADVERTISED&&b==State.VIDEO_SERVICE_AVAILABLE||a==State.VIDEO_SERVICE_AVAILABLE&&b==State.MEDIA_SETUP_PENDING||b==State.STOPPING&&(a==State.DISCOVERY_PENDING||a==State.SERVICES_ADVERTISED||a==State.VIDEO_SERVICE_AVAILABLE||a==State.MEDIA_SETUP_PENDING);
 }
 public static Confidence edgeConfidence(State a,State b){
  if(!legalEdge(a,b))return Confidence.UNKNOWN;
  if(b==State.CLOSED||b==State.ERROR||b==State.TRANSPORT_READY||b==State.VERSION_PENDING||a==State.VERSION_ESTABLISHED)return Confidence.IMPLEMENTATION_STRUCTURE;
  return Confidence.STRONGLY_INFERRED;
 }
 private void row(String direction,int channel,int flags,byte[] raw,String decoded,State before,String result){
  String text="t="+now+" direction="+direction+" channel="+channel+" flags="+flags+" raw="+hex(raw)+
   " decoded="+decoded+" before="+before+" after="+state+" outcome="+result;
  if(transcript.size()>=MAX_TRANSCRIPT_ROWS||text.length()>MAX_TRANSCRIPT_CHARS-chars){
   if(!terminal()){state=State.ERROR;outcome="BOUNDS_TRANSCRIPT";clear();}return;
  }
  transcript.add(text);chars+=text.length();
 }
 private void move(State next,String evidence){if(!legalEdge(state,next)){fault("PROTOCOL_STATE_ERROR_EDGE");return;}State before=state;state=next;transitions++;row("EVENT",-1,-1,new byte[0],evidence,before,"TRANSITION");}
 private void clear(){if(media!=null)media.close();videoChannel=-1;videoConfigurations=0;parser.reset();assembler.reset();registry.reset();opened.clear();fragmentSince.clear();outbound.clear();frameAt=responseAt=-1;}
 private void fault(String category){if(terminal())return;State before=state;state=State.ERROR;outcome=category;clear();row("EVENT",-1,-1,new byte[0],category,before,"A_SESSION_INVALIDATED");}
 private boolean event(){
  if(terminal())return false;
  long t=clock.now();if(t<0||t<now){fault("CLOCK_ERROR");return false;}now=t;
  if(state!=State.NEW){
   if(frameAt>=0&&now-frameAt>=policy.frameMs){fault("D_TIMEOUT_INCOMPLETE_FRAME");return false;}
   for(long first:fragmentSince.values())if(now-first>=policy.fragmentMs){fault("D_TIMEOUT_FRAGMENT");return false;}
   if(responseAt>=0&&now-responseAt>=policy.responseMs){fault("D_TIMEOUT_CONTROL_RESPONSE");return false;}
   if(activityAt>=0&&now-activityAt>=policy.inactivityMs){fault("D_TIMEOUT_INACTIVITY");return false;}
  }
  return true;
 }
 public void tick(){event();}
 private boolean require(State expected){if(state!=expected){fault("PROTOCOL_STATE_ERROR");return false;}return true;}
 public void transportReady(){if(!event()||!require(State.NEW))return;activityAt=now;move(State.TRANSPORT_READY,"EXPLICIT_SIMULATED_TRANSPORT_READY:IMPLEMENTATION_STRUCTURE");}
 public void beginVersion(){if(!event()||!require(State.TRANSPORT_READY))return;move(State.VERSION_PENDING,"VERSION_REQUEST:CONFIRMED_FORMAT");responseAt=now;send(0,ControlMessages.VERSION_REQUEST,new ControlMessages.Version(1,1,0,false).encode());}
 /** Explicit bypass of UNKNOWN real security exchange. NOT a TLS establishment assertion. */
 public void enterPlaintextSimulation(){
  if(!event()||!require(State.VERSION_ESTABLISHED))return;
  move(State.DISCOVERY_PENDING,"PLAINTEXT_SIMULATION_BYPASS; REAL_TLS_UNKNOWN");responseAt=now;
  send(0,ControlMessages.AUTH_COMPLETE,new ControlMessages.Status(0).encode());
 }
 /** Explicit synthetic verification seam; not a real authentication assertion. */
 public void enterVerifiedSecureSimulation(SyntheticTlsState security){
  if(security==null||!security.established())throw new IllegalStateException("Synthetic verification required");
  if(!event()||!require(State.VERSION_ESTABLISHED))return;
  move(State.DISCOVERY_PENDING,"INJECTED_HANDSHAKE_AND_VERIFY_OK; SYNTHETIC_BODY_ADAPTER; NO_CRYPTO");responseAt=now;
  send(0,ControlMessages.AUTH_COMPLETE,new ControlMessages.Status(0).encode());
 }
 private void send(int channel,int type,byte[] payload){
  if(terminal())return;
  if(outbound.size()>=MAX_OUTBOUND){fault("BOUNDS_OUTBOUND");return;}
  byte[] typed=ControlMessages.typed(type,payload);
  if(typed.length>ProtocolLimits.FRAME_BODY){fault("BOUNDS_OUTBOUND_FRAME");return;}
  int flags=channel==0?3:((type<0x8000)?7:3);
  byte[] wire=new AaFrameWriter().encode(new AaFrame(channel,flags,-1,typed));outbound.add(wire);
  row("OUT",channel,flags,wire,"type="+type,state,"CAPTURED_BYTES_ONLY");
 }
 public void receive(byte[] bytes){
  if(terminal())return;if(!event())return;State before=state;
  if(bytes==null||bytes.length>ProtocolLimits.MESSAGE){fault("BOUNDS_INPUT_BATCH");return;}
  if(bytes.length>0)activityAt=now;
  try{
   boolean partial=parser.hasPartialFrame();List<AaFrame> frames=parser.feed(bytes);
   if(parser.hasPartialFrame()){if(!partial||!frames.isEmpty())frameAt=now;}else frameAt=-1;
   for(AaFrame f:frames){
    if(terminal())break;
    if((f.flags&AaFrame.ENCRYPTED)!=0){lastUnknown=f.body();outcome="B_OPAQUE_ENCRYPTED";row("IN_OPAQUE",f.channel,f.flags,f.body(),"ENCRYPTED; requires future streaming TLS adapter",state,"B_MESSAGE_NOT_DECRYPTED");continue;}
    if((f.flags&AaFrame.FIRST)!=0&&(f.flags&AaFrame.LAST)==0)fragmentSince.put(f.channel,now);
    AaMessageAssembler.Message message=assembler.accept(f);
    if((f.flags&AaFrame.LAST)!=0)fragmentSince.remove(f.channel);
    State old=state;
    if(message!=null){if(++steps>ProtocolLimits.CONVERSATION_STEPS){fault("BOUNDS_STEPS");break;}handle(message);}
    row("IN_FRAME",f.channel,f.flags,f.body(),message==null?"PARTIAL_LOGICAL_MESSAGE":"type="+message.type,old,outcome);
   }
   row("IN_CHUNK",-1,-1,bytes,"arbitrary transport chunk",before,outcome);
  }catch(SessionCatalog.MappingException error){fault("LOCAL_DISCOVERY_MAPPING_ERROR");row("IN_REJECTED",-1,-1,bytes,"mapping rejected",before,outcome);}
   catch(IllegalStateException error){fault("PROTOCOL_STATE_ERROR");row("IN_REJECTED",-1,-1,bytes,"state rejected",before,outcome);}
   catch(IllegalArgumentException error){fault("MALFORMED_WIRE");row("IN_REJECTED",-1,-1,bytes,"wire rejected",before,outcome);}
 }
 private void handle(AaMessageAssembler.Message message){
  byte[] payload=Arrays.copyOfRange(message.bytes(),2,message.bytes().length);int type=message.type;outcome="ACCEPTED";
  if(message.channel==0){
   if(type==ControlMessages.VERSION_RESPONSE){
    if(!require(State.VERSION_PENDING))return;
    if(payload.length>6){lastUnknown=payload.clone();fault("UNKNOWN_VERSION_EXTENSION");return;}
    ControlMessages.Version v=ControlMessages.Version.parse(payload,true);
    if(v.major!=1||v.minor!=1||v.status!=0){fault("UNSUPPORTED_VERSION");return;}
    responseAt=-1;move(State.VERSION_ESTABLISHED,"BASE_1_1_SUPPORTED_BY_LOCAL_PROFILE; NOT_ALL_PHONE_VERSIONS");return;
   }
   if(type==ControlMessages.DISCOVERY_REQUEST){
    if(!require(State.DISCOVERY_PENDING))return;ControlMessages.DiscoveryRequest.parse(payload);lastUnknown=ProtoWire.parse(payload).encoded();
    row("LOCAL_DISCOVERY",0,-1,catalog.bytes(),"HU advertisement candidate; not phone-supplied",state,"VALIDATING_LOCAL_CATALOG");
    SessionCatalog.Prepared prepared=catalog.prepare();videoConfigurations=prepared.decoded.video.size();registry=prepared.registry;responseAt=-1;
    move(State.SERVICES_ADVERTISED,"HU_ADVERTISES_NOT_PHONE:CONFIRMED_DIRECTION");send(0,ControlMessages.DISCOVERY_RESPONSE,catalog.bytes());
    for(int unsupported:prepared.decoded.unknownServices)row("EVENT",-1,-1,new byte[0],"unsupportedService="+unsupported,state,"C_UNSUPPORTED_SERVICE_ISOLATED");
    for(VideoConfig v:prepared.decoded.video)row("CAPABILITY",-1,-1,DiscoveryCodec.video(v),"active="+v.activeWidth()+"x"+v.activeHeight()+" placement=UNSPECIFIED",state,"NO_PHONE_ACCEPTANCE_CLAIM");
    return;
   }
   if(type==ControlMessages.PING_REQUEST){
    if(state==State.NEW||state==State.TRANSPORT_READY||state==State.VERSION_PENDING||state==State.VERSION_ESTABLISHED){fault("PROTOCOL_STATE_ERROR");return;}
    ControlMessages.Ping ping=ControlMessages.Ping.parse(payload);lastUnknown=ProtoWire.parse(payload).encoded();send(0,ControlMessages.PING_RESPONSE,ping.encode());return;
   }
   if(type==ControlMessages.STOP_REQUEST){
    if(state!=State.DISCOVERY_PENDING&&state!=State.SERVICES_ADVERTISED&&state!=State.VIDEO_SERVICE_AVAILABLE&&state!=State.MEDIA_SETUP_PENDING){fault("PROTOCOL_STATE_ERROR");return;}
    ControlMessages.Stop.parse(payload);move(State.STOPPING,"PEER_SHUTDOWN:STRONGLY_INFERRED");send(0,ControlMessages.STOP_RESPONSE,new byte[0]);closeKeepingOutput("ORDERLY_PEER_SHUTDOWN");return;
   }
   if(type==ControlMessages.STOP_RESPONSE){if(!require(State.STOPPING))return;ProtoWire.parse(payload);lastUnknown=payload.clone();closeKeepingOutput("ORDERLY_LOCAL_SHUTDOWN");return;}
   if(type==ControlMessages.CHANNEL_OPEN_REQUEST||type>=0x8000){fault("PROTOCOL_STATE_ERROR_WRONG_CONTROL_CHANNEL");return;}
   lastUnknown=payload.clone();outcome="B_VALID_ENVELOPE_UNSUPPORTED_MESSAGE";return;
  }
  if(state!=State.SERVICES_ADVERTISED&&state!=State.VIDEO_SERVICE_AVAILABLE&&state!=State.MEDIA_SETUP_PENDING){fault("PROTOCOL_STATE_ERROR_SERVICE_BEFORE_DISCOVERY");return;}
  AaServiceRegistry.Entry entry=null;for(AaServiceRegistry.Entry e:registry.entries())if(e.channel==message.channel)entry=e;
  if(entry==null){lastUnknown=payload.clone();outcome="B_UNKNOWN_CHANNEL_REJECTED";return;}
  if(type==ControlMessages.CHANNEL_OPEN_REQUEST){
   ControlMessages.Open open=ControlMessages.Open.parse(payload);
   if(open.serviceId!=entry.serviceId||!opened.add(message.channel)){fault("PROTOCOL_STATE_ERROR_CHANNEL_MAPPING");return;}
   send(message.channel,ControlMessages.CHANNEL_OPEN_RESPONSE,new ControlMessages.Status(0).encode());
   if(entry.kind==AaServiceRegistry.Kind.VIDEO){if(state!=State.SERVICES_ADVERTISED){fault("PROTOCOL_STATE_ERROR_VIDEO_OPEN");return;}videoChannel=entry.channel;move(State.VIDEO_SERVICE_AVAILABLE,"VIDEO_CHANNEL_OPEN:STRONGLY_INFERRED");}return;
  }
  if(entry.kind!=AaServiceRegistry.Kind.VIDEO||!opened.contains(entry.channel)||(message.flags&AaFrame.CONTROL)!=0){fault("PROTOCOL_STATE_ERROR_WRONG_SERVICE");return;}
  if(media!=null){
   if(type==MediaControlMessages.SETUP){
    HondaMediaMessages.MediaSetup setup=HondaMediaMessages.MediaSetup.parse(payload);lastUnknown=setup.encode();
    outcome=media.setup(setup);mediaRows();
    if(outcome.equals("MEDIA_SETUP_RECEIVED"))move(State.MEDIA_SETUP_PENDING,"HONDA_MEDIA_SUBSTATE=MEDIA_SETUP_RECEIVED; EXPLICIT_CONFIG_REQUIRED");return;
   }
   if(type==MediaControlMessages.START){HondaMediaMessages.MediaStart start=HondaMediaMessages.MediaStart.parse(payload);lastUnknown=start.encode();outcome=media.start(start);mediaRows();return;}
   if(type==MediaControlMessages.SETUP_RESPONSE||type==MediaControlMessages.ACK||type==MediaControlMessages.FOCUS_INDICATION){lastUnknown=payload.clone();outcome="B_WRONG_MEDIA_DIRECTION";return;}
   lastUnknown=payload.clone();outcome="B_UNKNOWN_MEDIA_TRANSITION";return;
  }
  if(type==MediaControlMessages.SETUP){
   if(!require(State.VIDEO_SERVICE_AVAILABLE))return;
   lastUnknown=MediaControlMessages.parse(type,payload).encode();move(State.MEDIA_SETUP_PENDING,"SETUP_OBSERVED; FIELD1_SEMANTICS_UNKNOWN");outcome="UNKNOWN_MEDIA_TRANSITION";return;
  }
  if(type==MediaControlMessages.START||type==MediaControlMessages.STOP){
   if(!require(State.MEDIA_SETUP_PENDING))return;
   lastUnknown=MediaControlMessages.parse(type,payload).encode();outcome="UNKNOWN_MEDIA_TRANSITION";return;
  }
  lastUnknown=payload.clone();outcome="B_UNSUPPORTED_MEDIA_MESSAGE";
 }
 public void beginStop(){
  if(!event())return;if(state!=State.SERVICES_ADVERTISED&&state!=State.VIDEO_SERVICE_AVAILABLE&&state!=State.MEDIA_SETUP_PENDING){fault("PROTOCOL_STATE_ERROR_STOP");return;}
  move(State.STOPPING,"EXPLICIT_LOCAL_SHUTDOWN:STRONGLY_INFERRED");responseAt=now;send(0,ControlMessages.STOP_REQUEST,new ControlMessages.Stop(1).encode());
 }
 private void closeKeepingOutput(String reason){if(!legalEdge(state,State.CLOSED)){fault("PROTOCOL_STATE_ERROR_CLOSE");return;}State before=state;if(media!=null)media.close();videoChannel=-1;videoConfigurations=0;parser.reset();assembler.reset();registry.reset();opened.clear();fragmentSince.clear();frameAt=responseAt=-1;state=State.CLOSED;transitions++;outcome=reason;row("EVENT",-1,-1,new byte[0],reason,before,"CLOSED_NO_RESURRECTION");}
 public void eof(){if(!event())return;try{parser.endOfInput();assembler.endOfInput();}catch(IllegalArgumentException error){fault("MALFORMED_WIRE_EOF");return;}
  if(state==State.VERSION_PENDING||state==State.DISCOVERY_PENDING||state==State.STOPPING){fault("EOF_PENDING_CONTROL");return;}closeKeepingOutput("EOF_CLOSED");}
 /** Media progression is a single typed sub-state, not parent-control booleans. */
 public HondaMediaFlow.State mediaState(){return media==null?HondaMediaFlow.State.IDLE:media.state();}
 /** Snapshot access for an explicitly attached offline data model; not transport ownership. */
 public int selectedMediaSession(){return media==null?-1:media.session();}
 public int selectedVideoChannel(){return videoChannel;}
 public String progression(){return media!=null&&media.state()!=HondaMediaFlow.State.IDLE&&media.state()!=HondaMediaFlow.State.CLOSED?media.state().name():state.name();}
 private void mediaRows(){if(media!=null)for(String e:media.drainEvents())row("MEDIA_EVENT",videoChannel,-1,new byte[0],e+" mediaState="+media.state(),state,outcome);}
 private boolean mediaEvent(){if(!event())return false;if(media==null||state!=State.MEDIA_SETUP_PENDING||videoChannel<1){outcome="B_MEDIA_POLICY_WRONG_STATE";return false;}return true;}
 /** Explicit local policy input; no production readiness trigger is invented. */
 public void advertiseMediaConfig(HondaMediaMessages.MediaConfig config){
  if(!mediaEvent())return;
  if(config==null){outcome="B_INVALID_LOCAL_MEDIA_CONFIG";return;}
  try{byte[] bytes=media.advertise(config,videoConfigurations);outcome="MEDIA_CONFIG_POLICY_ACCEPTED";mediaRows();send(videoChannel,MediaControlMessages.SETUP_RESPONSE,bytes);}
  catch(IllegalArgumentException error){outcome="B_INVALID_LOCAL_MEDIA_CONFIG";}
  catch(IllegalStateException error){outcome="B_MEDIA_CONFIG_WRONG_STATE";}
 }
 public void optionalProjectedFocus(boolean policyAllows){
  if(!mediaEvent())return;
  try{byte[] bytes=media.optionalFocus(policyAllows);mediaRows();if(bytes!=null)send(videoChannel,MediaControlMessages.FOCUS_INDICATION,bytes);}
  catch(IllegalStateException error){outcome="B_OPTIONAL_FOCUS_WRONG_STATE";}
 }
 public void accountMedia(int count,HondaMediaFlow.AccountingReason reason){
  if(!mediaEvent())return;
  try{byte[] bytes=media.account(count,reason);mediaRows();send(videoChannel,MediaControlMessages.ACK,bytes);}
  catch(IllegalArgumentException error){outcome="B_INVALID_ACCOUNTING";}
  catch(IllegalStateException error){outcome="B_ACCOUNTING_WRONG_STATE";}
 }
 public static String hex(byte[] bytes){StringBuilder b=new StringBuilder();for(byte v:bytes){b.append("0123456789abcdef".charAt((v&255)>>>4));b.append("0123456789abcdef".charAt(v&15));}return b.toString();}
}



