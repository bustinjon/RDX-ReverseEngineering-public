package com.rdx.fullscreen.clean;
import java.util.*;
/** Offline plaintext conversation model ONLY. Not an active receiver, TLS adapter or transport. */
public final class HeadUnitProtocolCore {
 private final AaFrameParser parser=new AaFrameParser(ProtocolLimits.FRAME_BODY,ProtocolLimits.MESSAGE,ProtocolLimits.FRAMES_PER_FEED);
 private final AaMessageAssembler assembler=new AaMessageAssembler(ProtocolLimits.MESSAGE,ProtocolLimits.PARTIAL_CHANNELS,ProtocolLimits.RESERVED_BYTES);
 private final ControlStateMachine state=new ControlStateMachine();private final AaServiceRegistry registry=new AaServiceRegistry();
 private final byte[] advertisement;private int steps;
 public HeadUnitProtocolCore(AaServiceDiscovery model,AaServiceRegistry mapping){
  if(model==null||mapping==null)throw new IllegalArgumentException("Model/mapping required");
  for(AaServiceRegistry.Entry e:mapping.entries())registry.register(e.serviceId,e.channel,e.kind);
  advertisement=DiscoveryCodec.encode(model,registry);
 }
 public ControlStateMachine.State state(){return state.state();}
 /** Pure raw-version request fixture. No transport is opened or written. */
 public byte[] begin(){state.transportReady();state.versionSent();return envelope(0,ControlMessages.VERSION_REQUEST,new ControlMessages.Version(1,1,0,false).encode());}
 /** Caller-supplied handshake evidence seam. Fake adapter exists in tests only. No real TLS here. */
 public void recordTlsEstablished(TlsAdapter adapter){if(adapter==null||!adapter.established())throw new IllegalStateException("No TLS establishment evidence");state.tlsEstablished();}
 /** Reference direction: HU emits plaintext AuthComplete AFTER TLS, phone then requests discovery. */
 public byte[] authenticationCompleteNotification(){state.authenticationComplete();return envelope(0,ControlMessages.AUTH_COMPLETE,new ControlMessages.Status(0).encode());}
 /** Synthetic unencrypted envelopes at a post-TLS seam; encrypted input explicitly rejected. */
 public List<byte[]> acceptPlaintextEnvelope(byte[] bytes){
  if(state.state()==ControlStateMachine.State.ERROR||state.state()==ControlStateMachine.State.STOPPED)throw new IllegalStateException("Session ended");
  try{
   if(bytes==null||bytes.length>ProtocolLimits.MESSAGE)throw new IllegalArgumentException("Input batch limit");List<byte[]> out=new ArrayList<byte[]>();
   for(AaFrame f:parser.feed(bytes)){
    if(f.channel!=0)registry.channel(f.channel);
    AaMessageAssembler.Message m=assembler.accept(f);if(m==null)continue;
    if(++steps>ProtocolLimits.CONVERSATION_STEPS)throw new IllegalArgumentException("Conversation step limit");
    byte[] response=handle(m);if(response!=null)out.add(response);
   }
   return out;
  }catch(RuntimeException e){parser.reset();assembler.reset();state.fatal();throw e;}
 }
 private byte[] handle(AaMessageAssembler.Message m){
  byte[] payload=Arrays.copyOfRange(m.bytes(),2,m.bytes().length);int type=m.type;
  if(type==ControlMessages.CHANNEL_OPEN_REQUEST){
   if(m.channel==0)throw new IllegalArgumentException("Model expects channel-open on its explicit service channel");
   ControlMessages.Open open=ControlMessages.Open.parse(payload);AaServiceRegistry.Entry e=registry.channel(m.channel);
   if(open.serviceId!=e.serviceId)throw new IllegalArgumentException("Channel/service mismatch");state.channelOpened(m.channel,registry.entries().size());
   return envelope(m.channel,ControlMessages.CHANNEL_OPEN_RESPONSE,new ControlMessages.Status(0).encode());
  }
  if(m.channel!=0)throw new IllegalArgumentException("Unsupported service message");
  switch(type){
   case ControlMessages.VERSION_RESPONSE:
    ControlMessages.Version v=ControlMessages.Version.parse(payload,true);if(v.major!=1||v.minor!=1||v.status!=0)throw new IllegalArgumentException("Offline fixture version mismatch");state.versionAccepted();return null;
   case ControlMessages.DISCOVERY_REQUEST:
    ControlMessages.DiscoveryRequest.parse(payload);state.servicesAdvertised();return envelope(0,ControlMessages.DISCOVERY_RESPONSE,advertisement);
   case ControlMessages.PING_REQUEST:
    ControlStateMachine.State current=state.state();if(current!=ControlStateMachine.State.SERVICE_DISCOVERY&&current!=ControlStateMachine.State.SERVICES_ADVERTISED&&current!=ControlStateMachine.State.CHANNELS_OPENING&&current!=ControlStateMachine.State.READY)throw new IllegalStateException("Ping before authentication");return envelope(0,ControlMessages.PING_RESPONSE,ControlMessages.Ping.parse(payload).encode());
   case ControlMessages.STOP_REQUEST:
    ControlMessages.Stop.parse(payload);state.beginStop();state.stopped();return envelope(0,ControlMessages.STOP_RESPONSE,new byte[0]);
   default:throw new IllegalArgumentException("Unknown/unsupported control message");
  }
 }
 public void endOfInput(){try{parser.endOfInput();assembler.endOfInput();}catch(RuntimeException e){state.fatal();throw e;}}
 public void reset(){parser.reset();assembler.reset();state.reset();steps=0;}
 private static byte[] envelope(int channel,int type,byte[] payload){byte[] b=ControlMessages.typed(type,payload);if(b.length>ProtocolLimits.FRAME_BODY)throw new IllegalArgumentException("Response frame limit");return new AaFrameWriter().encode(new AaFrame(channel,channel==0?3:7,-1,b));}
}
