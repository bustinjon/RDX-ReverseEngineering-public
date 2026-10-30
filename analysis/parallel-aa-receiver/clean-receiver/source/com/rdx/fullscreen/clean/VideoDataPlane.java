package com.rdx.fullscreen.clean;
import java.util.*;
/** Pure bounded HOST simulation after a typed control selection. NO default packet-to-AU assumption. */
public final class VideoDataPlane {
 public enum BoundaryPolicy { UNKNOWN,HOST_ONE_MESSAGE_PER_MP4_ACCESS_UNIT }
 public enum State { NEW,MEDIA_DATA_ACCEPTING,ABSTRACT_INPUT_ACCEPTED,STOPPED,ERROR }
 private static final class Queued {H264.AccessUnit unit;MediaPayload.Timestamp timestamp;Long pts;MediaAccountingWindow.Token token;}
 private final SimulatedSessionEngine control;private final VideoDecoderContract decoder;private final BoundaryPolicy boundary;
 private final ArrayDeque<Queued> queue=new ArrayDeque<Queued>();private final ArrayDeque<String> events=new ArrayDeque<String>();
 private final int windowSize;private MediaAccountingWindow window;private State state=State.NEW;private int queuedBytes,maxQueue,maxBytes,maxOutstanding,session=-1;private long accepted,rejected,accounted;private H264.Configuration configuration;
 public VideoDataPlane(SimulatedSessionEngine gate,VideoDecoderContract sink,int max,BoundaryPolicy policy){if(gate==null||sink==null||policy==null||max<1||max>32)throw new IllegalArgumentException("Data plane policy");control=gate;decoder=sink;windowSize=max;boundary=policy;}
 public State state(){return state;}public int queueDepth(){return queue.size();}public int bufferedBytes(){return queuedBytes;}public int outstanding(){return window==null?0:window.outstanding();}
 public int maxQueueDepth(){return maxQueue;}public int maxBufferedBytes(){return maxBytes;}public int maxOutstanding(){return maxOutstanding;}public long accepted(){return accepted;}public long rejected(){return rejected;}public long accounted(){return accounted;}
 public boolean hasConfiguration(){return configuration!=null;}
 public List<String> events(){return Collections.unmodifiableList(new ArrayList<String>(events));}
 private void log(String s){if(events.size()==128)events.removeFirst();events.addLast(s);}
 private boolean live(){if(state==State.ERROR||state==State.STOPPED)return false;if(control.terminal()){fail("CONTROL_TERMINAL");return false;}if(control.mediaState()!=HondaMediaFlow.State.MEDIA_CONFIGURATION_SELECTED){log("REJECT_DATA_BEFORE_SELECTION");return false;}return true;}
 public String accept(int channel,MediaPayload packet,long now,Long explicitFixturePtsUs){
  if(!live())return "REJECT_NOT_SELECTED_OR_TERMINAL";
  if(channel!=control.selectedVideoChannel()){fail("WRONG_MEDIA_CHANNEL");return "WRONG_MEDIA_CHANNEL";}
  if(boundary==BoundaryPolicy.UNKNOWN){log("UNKNOWN_PACKET_TO_AU_BOUNDARY");return "UNKNOWN_PACKET_TO_AU_BOUNDARY";}
  try{
   if(packet.type==MediaPayload.CONFIG){
    if(configuration!=null){log("RECONFIGURATION_UNKNOWN");return "RECONFIGURATION_UNKNOWN";}
    H264.Configuration candidate=new H264.Configuration(packet.bytes());
    VideoDecoderContract.Outcome result=decoder.configure(new VideoDecoderContract.Format(candidate));
    if(result!=VideoDecoderContract.Outcome.ACCEPTED){fail("CONFIGURATION_REJECTED_OR_RESET");return "CONFIGURATION_REJECTED";}
    if(decoder.start()!=VideoDecoderContract.Outcome.ACCEPTED){fail("START_REJECTED");return "START_REJECTED";}
    configuration=candidate;session=control.selectedMediaSession();window=new MediaAccountingWindow(windowSize,session);state=State.MEDIA_DATA_ACCEPTING;log("SYNTHETIC_ANNEXB_CONFIGURATION_ACCEPTED; NO_DECODE");return "CONFIGURED_ABSTRACT";
   }
   if(configuration==null){log("NO_ACCESS_UNIT_BEFORE_CONFIG");return "MISSING_CONFIGURATION";}
   if(explicitFixturePtsUs!=null&&explicitFixturePtsUs.longValue()<0)throw new IllegalArgumentException("Explicit PTS policy");
   byte[] bytes=packet.bytes();if(bytes.length==0)throw new IllegalArgumentException("Empty synthetic AU");
   // Admission BEFORE AU copies/queue growth. Caller may pause/retry; no implicit retransmission.
   if(window.outstanding()>=windowSize||queue.size()>=windowSize||bytes.length>H264.MAX-queuedBytes){log("BOUNDED_BACKPRESSURE");return "BACKPRESSURE";}
   H264.AccessUnit unit=new H264.AccessUnit(bytes);MediaAccountingWindow.Token token=window.issue(now);if(token==null)return "BACKPRESSURE";
   Queued q=new Queued();q.unit=unit;q.timestamp=packet.timestamp;q.pts=explicitFixturePtsUs;q.token=token;queue.addLast(q);queuedBytes+=unit.size();
   maxQueue=Math.max(maxQueue,queue.size());maxBytes=Math.max(maxBytes,queuedBytes);maxOutstanding=Math.max(maxOutstanding,window.outstanding());pump();return "ENQUEUED_ABSTRACT";
  }catch(IllegalArgumentException x){fail("MALFORMED_MEDIA_SUBSET");return "MALFORMED_MEDIA_SUBSET";}
 }
 public void pump(){if(!live()||configuration==null)return;while(!queue.isEmpty()){
  Queued q=queue.peekFirst();VideoDecoderContract.Outcome outcome=decoder.queue(q.unit,q.timestamp,q.pts);
  if(outcome==VideoDecoderContract.Outcome.BACKPRESSURE){log("DECODER_BACKPRESSURE");return;}
  if(outcome==VideoDecoderContract.Outcome.RESET_REQUIRED||outcome==VideoDecoderContract.Outcome.CONFIGURATION_REJECTED){fail("DECODER_RESET_REQUIRED");return;}
  queue.removeFirst();queuedBytes-=q.unit.size();window.complete(q.token);if(outcome==VideoDecoderContract.Outcome.ACCEPTED){accepted++;state=State.ABSTRACT_INPUT_ACCEPTED;}else rejected++;
  log("ACCOUNTABLE "+outcome+"; ACK_NOT_DISPLAY");
 }}
 /** Explicit synthetic completion-to-credit policy; native output timing remains UNKNOWN. */
 public HondaMediaMessages.MediaAck takeAccountingAck(){if(!live()||window==null)return null;int count=window.drainCompleted();if(count==0)return null;accounted+=count;log("COUNT_ACK "+count+"; SYNTHETIC_COMPLETION_POLICY");return HondaMediaMessages.MediaAck.accounting(session,count);}
 public void tick(long now,long injectedTimeout){if(live()&&window!=null&&window.expired(now,injectedTimeout))fail("MISSING_ACK_OR_CONSUMPTION_TIMEOUT_POLICY");}
 private void release(){queue.clear();queuedBytes=0;configuration=null;if(window!=null)window.reset(Math.max(0,session));session=-1;decoder.flush();decoder.stop();}
 public void fail(String reason){if(state==State.ERROR||state==State.STOPPED)return;state=State.ERROR;release();log(reason);}
 public void stop(){if(state==State.ERROR||state==State.STOPPED)return;state=State.STOPPED;release();log("ORDERLY_ABSTRACT_STOP");}
 public void stopOnChannel(int channel){if(!live())return;if(channel!=control.selectedVideoChannel())fail("WRONG_MEDIA_CHANNEL");else stop();}
 /** Requires a NEW control/plane instance; this terminal object never resurrects. */
 public void discontinuity(){stop();}
}
