package com.rdx.fullscreen.clean;
/** Explicit SYNTHETIC events only. Establishment is no cryptographic or phone acceptance assertion. */
public final class SyntheticTlsState {
 public enum State { NOT_STARTED,HANDSHAKING,VERIFYING_PEER,ESTABLISHED_SYNTHETIC,SHUTTING_DOWN,CLOSED,FAILED }
 private State state=State.NOT_STARTED;
 public State state(){return state;}public boolean established(){return state==State.ESTABLISHED_SYNTHETIC;}
 private void require(State s){if(state!=s)throw new IllegalStateException("Illegal synthetic TLS event: "+state);}
 public void begin(){require(State.NOT_STARTED);state=State.HANDSHAKING;}
 public void handshakeSucceeded(){require(State.HANDSHAKING);state=State.VERIFYING_PEER;}
 public void verify(boolean accepted){require(State.VERIFYING_PEER);state=accepted?State.ESTABLISHED_SYNTHETIC:State.FAILED;}
 public void beginShutdown(){require(State.ESTABLISHED_SYNTHETIC);state=State.SHUTTING_DOWN;}
 public void cleanClose(){if(state==State.FAILED||state==State.CLOSED)return;state=State.CLOSED;}
 public void fail(){if(state!=State.CLOSED)state=State.FAILED;}
 /** Terminal reset does not revive this object: construct a new session/state/adapter. */
 public void reset(){cleanClose();}
}
