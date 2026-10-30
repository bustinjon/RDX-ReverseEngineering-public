package com.rdx.fullscreen.clean;
import java.util.*;
/** Abstract local sequencing policy. No transport/authentication action is performed. */
public final class ControlStateMachine {
 public enum State { DISCONNECTED,TRANSPORT_READY,VERSION_NEGOTIATING,TLS_REQUIRED,TLS_ESTABLISHED,SERVICE_DISCOVERY,SERVICES_ADVERTISED,CHANNELS_OPENING,READY,STOPPING,STOPPED,ERROR }
 private State state=State.DISCONNECTED;private final Set<Integer> opened=new HashSet<Integer>();private int expectedChannels;
 public ControlStateMachine(){}
 public State state(){return state;}
 private void require(State s){if(state!=s)throw new IllegalStateException("Expected "+s+", got "+state);}
 public void transportReady(){require(State.DISCONNECTED);state=State.TRANSPORT_READY;}
 public void versionSent(){require(State.TRANSPORT_READY);state=State.VERSION_NEGOTIATING;}
 public void versionAccepted(){require(State.VERSION_NEGOTIATING);state=State.TLS_REQUIRED;}
 /** Evidence is supplied by a future real adapter; host tests use a clearly labeled fake. */
 public void tlsEstablished(){require(State.TLS_REQUIRED);state=State.TLS_ESTABLISHED;}
 public void authenticationComplete(){require(State.TLS_ESTABLISHED);state=State.SERVICE_DISCOVERY;}
 public void servicesAdvertised(){require(State.SERVICE_DISCOVERY);state=State.SERVICES_ADVERTISED;}
 public void channelOpened(int channel,int requiredChannels){if(state!=State.SERVICES_ADVERTISED&&state!=State.CHANNELS_OPENING)throw new IllegalStateException("Channel open too early/late");if(channel<1||channel>255||requiredChannels<1||requiredChannels>ProtocolLimits.SERVICES||(expectedChannels!=0&&requiredChannels!=expectedChannels)||opened.size()>=requiredChannels||!opened.add(channel))throw new IllegalArgumentException("Channel count/duplicate");expectedChannels=requiredChannels;state=opened.size()==requiredChannels?State.READY:State.CHANNELS_OPENING;}
 public void beginStop(){if(state==State.DISCONNECTED||state==State.STOPPED||state==State.STOPPING||state==State.ERROR)throw new IllegalStateException("Cannot stop in "+state);state=State.STOPPING;}
 public void stopped(){require(State.STOPPING);state=State.STOPPED;}
 public void fatal(){state=State.ERROR;opened.clear();expectedChannels=0;}
 public void reset(){state=State.DISCONNECTED;opened.clear();expectedChannels=0;}
}
