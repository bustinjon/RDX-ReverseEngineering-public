package com.rdx.fullscreen.clean;
import java.util.*;
/** Explicit pure media sub-state object. Parent engine owns framing/control/terminal state.
 * Callback events are bounded data records, not executable decoder/application callbacks. */
public final class HondaMediaFlow {
 public enum State { IDLE,MEDIA_SETUP_RECEIVED,MEDIA_CONFIG_WAIT_ADVERTISED,MEDIA_CONFIG_ADVERTISED,MEDIA_CONFIGURATION_SELECTED,CLOSED }
 public enum AccountingReason { CODEC_CONFIG_ACCOUNTED,INPUT_FAILURE_ACCOUNTED,OUTPUT_ACCOUNTED }
 private State state=State.IDLE;private HondaMediaMessages.MediaConfig advertised;private int session=-1;
 private final List<String> events=new ArrayList<String>();
 public HondaMediaFlow(){}
 public State state(){return state;}public int session(){return session;}
 private void event(String s){if(events.size()>=64)throw new IllegalArgumentException("Media event bound");events.add(s);}
 public List<String> drainEvents(){List<String> out=new ArrayList<String>(events);events.clear();return out;}
 public String setup(HondaMediaMessages.MediaSetup setup){
  if(state!=State.IDLE)return "B_DUPLICATE_OR_ILLEGAL_SETUP";
  if(!setup.codec.supportedVideo())return "B_UNSUPPORTED_VIDEO_CODEC";
  state=State.MEDIA_SETUP_RECEIVED;event("onMediaSetup codec=3; NO_DECODER");return "MEDIA_SETUP_RECEIVED";
 }
 public byte[] advertise(HondaMediaMessages.MediaConfig config,int count){
  if(state!=State.MEDIA_SETUP_RECEIVED&&state!=State.MEDIA_CONFIG_WAIT_ADVERTISED)throw new IllegalStateException("Config requires Setup; reconfiguration UNKNOWN");
  config.validateAdvertisement(count);byte[] bytes=config.encode();
  event("ConfigSerialized status="+config.rawStatus+"; EXPLICIT_SYNTHETIC_READINESS_POLICY; WAIT_TO_READY_TRIGGER_UNKNOWN");
  advertised=config;state=config.status==MediaConfigStatus.STATUS_READY?State.MEDIA_CONFIG_ADVERTISED:State.MEDIA_CONFIG_WAIT_ADVERTISED;return bytes;
 }
 public String start(HondaMediaMessages.MediaStart start){
  if(state!=State.MEDIA_CONFIG_ADVERTISED)return "B_START_REQUIRES_READY_CONFIG";
  if(!advertised.permits(start.configuration))return "B_UNADVERTISED_CONFIGURATION";
  session=start.session;event("onConfigurationSelected index="+start.configuration.value);
  event("onMediaStartObserved session="+session+"; NO_PLAYBACK_CLAIM");state=State.MEDIA_CONFIGURATION_SELECTED;return "MEDIA_CONFIGURATION_SELECTED";
 }
 public byte[] optionalFocus(boolean policyAllows){
  if(!policyAllows)return null;
  if(state!=State.MEDIA_CONFIG_ADVERTISED)throw new IllegalStateException("Optional focus after READY Config only");
  event("OPTIONAL_PROJECTED_FOCUS; NO_PEER_PREREQUISITE_ASSUMED");return HondaMediaMessages.ProjectedFocus.create().encode();
 }
 public byte[] account(int count,AccountingReason reason){
  if(state!=State.MEDIA_CONFIGURATION_SELECTED||reason==null)throw new IllegalStateException("Accounting requires observed session");
  byte[] bytes=HondaMediaMessages.MediaAck.accounting(session,count).encode();
  event("FLOW_CONTROL_ACCOUNTING reason="+reason+" count="+count+"; NOT_DISPLAY_OR_DECODE_SUCCESS");return bytes;
 }
 public void close(){state=State.CLOSED;advertised=null;session=-1;events.clear();}
}
