package com.rdx.fullscreen.clean;
import java.util.*;
/** FULL OFFLINE ENCRYPTION-BOUNDARY SESSION SIMULATION. No crypto, real peer or active transport. */
public final class SecureSessionSimulation {
 private final SimulatedSessionEngine core;private final SecureBodyAdapter adapter;private final SyntheticTlsState tls;private final SecureBodyPipeline bodies;
 private boolean authSent;private VideoDataPlane video;private final ArrayDeque<String> events=new ArrayDeque<String>();
 public SecureSessionSimulation(SimulatedSessionEngine engine,SecureBodyAdapter fake){if(engine==null||fake==null)throw new IllegalArgumentException("Explicit core/adapter");core=engine;adapter=fake;tls=new SyntheticTlsState();bodies=new SecureBodyPipeline(adapter,tls);}
 public SyntheticTlsState.State tlsState(){return tls.state();}public SecureBodyPipeline bodies(){return bodies;}
 private void log(String s){if(events.size()==256)events.removeFirst();events.addLast(s);}
 public List<String> events(){return Collections.unmodifiableList(new ArrayList<String>(events));}
 public void attachVideo(VideoDataPlane plane){if(plane==null||video!=null)throw new IllegalStateException("Explicit one-time sink attachment");video=plane;}
 private void invalidate(String why){log("SESSION_INVALID "+why);tls.fail();bodies.reset();core.eof();if(video!=null)video.fail(why);}
 public List<byte[]> beginVersion(){core.transportReady();core.beginVersion();return drainControl();}
 public List<byte[]> beginHandshake(byte[] syntheticInput){
  if(core.state()!=SimulatedSessionEngine.State.VERSION_ESTABLISHED)throw new IllegalStateException("Version first");tls.begin();return pumpHandshake(syntheticInput);
 }
 public List<byte[]> pumpHandshake(byte[] syntheticInput){
  if(tls.state()!=SyntheticTlsState.State.HANDSHAKING||syntheticInput==null||syntheticInput.length>65533)throw new IllegalStateException("Handshake carrier bounds/state");
  try{SecureBodyAdapter.Result r=adapter.pumpHandshake(syntheticInput);if(r==null||r.contextId!=0||r.residualBytes!=0)throw new IllegalArgumentException("Handshake association");
   if(r.outcome!=SecureBodyAdapter.Outcome.PROGRESS&&r.outcome!=SecureBodyAdapter.Outcome.NO_OUTPUT_YET&&r.outcome!=SecureBodyAdapter.Outcome.BODY_COMPLETE)throw new IllegalStateException("Handshake outcome");
   List<byte[]> output=new ArrayList<byte[]>();for(byte[] b:r.chunks()){if(output.size()>=16||b.length>65533)throw new IllegalArgumentException("Handshake output bound");output.addAll(bodies.encode(0,0,ControlMessages.typed(3,b),false));}log("SYNTHETIC_HANDSHAKE_PUMP only; no handshake success inferred from output");return output;
  }catch(RuntimeException e){invalidate("HANDSHAKE_ERROR");throw e;}
 }
 public void handshakeSucceeded(){tls.handshakeSucceeded();log("INJECTED_HANDSHAKE_SUCCESS; VERIFY_PENDING");}
 public List<byte[]> verifyPeer(boolean accepted){tls.verify(accepted);if(!accepted){invalidate("VERIFY_FAIL");return Collections.emptyList();}
  core.enterVerifiedSecureSimulation(tls);log("INJECTED_VERIFY_OK; NO_REAL_AUTHENTICATION");return drainControl();
 }
 public void receive(byte[] wire){
  try{for(AaMessageAssembler.Message m:bodies.receive(wire)){
   SecureStartupPolicy.incoming(m.channel,m.type,(m.flags&8)!=0,tls.state(),authSent);
   log("IN ch="+m.channel+" flags="+m.flags+" type="+m.type+" logicalBytes="+m.bytes().length+" tls="+tls.state());
   if(m.channel==0&&m.type==3){byte[] payload=Arrays.copyOfRange(m.bytes(),2,m.bytes().length);SecureBodyAdapter.Result r=adapter.pumpHandshake(payload);if(r==null||!r.chunks().isEmpty()||r.residualBytes!=0||(r.outcome!=SecureBodyAdapter.Outcome.NO_OUTPUT_YET&&r.outcome!=SecureBodyAdapter.Outcome.BODY_COMPLETE))throw new IllegalStateException("Use explicit pump for outbound handshake carrier");continue;}
   if(video!=null&&m.channel==core.selectedVideoChannel()&&(m.type==0||m.type==1||m.type==0x8002)){
    if(m.type==0x8002)video.stopOnChannel(m.channel);else{MediaPayload p=MediaPayload.parse(m.type,Arrays.copyOfRange(m.bytes(),2,m.bytes().length));String outcome=video.accept(m.channel,p,0,null);if(outcome.equals("BACKPRESSURE"))throw new IllegalStateException("VIDEO_BACKPRESSURE_NO_REPLAY");if(video.state()==VideoDataPlane.State.ERROR)throw new IllegalStateException("VIDEO_ERROR");}continue;
   }
   if(m.bytes().length>65535)throw new IllegalArgumentException("Core message bound");
   core.receive(new AaFrameWriter().encode(new AaFrame(m.channel,(m.flags&4)|3,-1,m.bytes())));
   if(core.terminal())throw new IllegalStateException("CORE_TERMINAL");
  }}catch(RuntimeException e){invalidate("INBOUND_FAILURE:"+e.getMessage());throw e;}
 }
 /** Explicitly transforms the old core's captured plaintext output; never writes to transport. */
 public List<byte[]> drainControl(){
  List<byte[]> output=new ArrayList<byte[]>();try{for(byte[] old:core.drainOutbound()){
   List<AaFrame> f=new AaFrameParser(65535,1048576,128).feed(old);if(f.size()!=1)throw new IllegalArgumentException("Core frame");AaFrame frame=f.get(0);byte[] logical=frame.body();int type=((logical[0]&255)<<8)|(logical[1]&255);
   boolean encrypted=SecureStartupPolicy.outgoingEncrypted(frame.channel,type,tls.state(),authSent);output.addAll(bodies.encode(frame.channel,frame.flags&4,logical,encrypted));if(frame.channel==0&&type==4)authSent=true;
   log("OUT ch="+frame.channel+" type="+type+" encrypted="+encrypted+" logicalBytes="+logical.length);
  }return output;}catch(RuntimeException e){invalidate("OUTBOUND_FAILURE");throw e;}
 }
 public List<byte[]> accountingAck(){if(video==null)throw new IllegalStateException("No sink");HondaMediaMessages.MediaAck ack=video.takeAccountingAck();if(ack==null)return Collections.emptyList();return bodies.encode(core.selectedVideoChannel(),0,ControlMessages.typed(0x8004,ack.encode()),true);}
 public void shutdown(){if(video!=null)video.stop();if(tls.established())tls.beginShutdown();bodies.endOfInput();core.eof();log("ORDERLY_SYNTHETIC_CLOSE; NO close_notify CLAIM");}
}
