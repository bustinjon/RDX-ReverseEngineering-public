package com.rdx.fullscreen.clean;
/** Target-generation HU policy. CONTROL is an independent routing flag, not channel0. */
public final class SecureStartupPolicy {
 private SecureStartupPolicy(){}
 public static boolean outgoingEncrypted(int channel,int type,SyntheticTlsState.State state,boolean authSent){
  if(channel==0&&type==1){if(state!=SyntheticTlsState.State.NOT_STARTED)throw new IllegalStateException("Version state");return false;}
  if(channel==0&&type==3){if(state!=SyntheticTlsState.State.HANDSHAKING)throw new IllegalStateException("Handshake state");return false;}
  if(channel==0&&type==4){if(state!=SyntheticTlsState.State.ESTABLISHED_SYNTHETIC||authSent)throw new IllegalStateException("Auth exception state");return false;}
  if(state!=SyntheticTlsState.State.ESTABLISHED_SYNTHETIC||!authSent)throw new IllegalStateException("Application state");return true;
 }
 public static void incoming(int channel,int type,boolean encrypted,SyntheticTlsState.State state,boolean authSent){
  if(channel==0&&type==2&&state==SyntheticTlsState.State.NOT_STARTED&&!encrypted)return;
  if(channel==0&&type==3&&state==SyntheticTlsState.State.HANDSHAKING&&!encrypted)return;
  if(channel==0&&(type==1||type==2||type==3||type==4))throw new IllegalStateException("Unexpected startup/direction");
  if(!encrypted||state!=SyntheticTlsState.State.ESTABLISHED_SYNTHETIC||!authSent)throw new IllegalStateException("Encrypted established application required");
 }
}
