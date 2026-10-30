package com.rdx.fullscreen.clean;
/** Explicit LOCAL policy. No production timeout values are asserted. */
public final class SessionPolicy {
 public interface Clock { long now(); }
 public final long frameMs,fragmentMs,responseMs,inactivityMs;
 public SessionPolicy(long frame,long fragment,long response,long inactivity){
  if(frame<1||fragment<1||response<1||inactivity<1)throw new IllegalArgumentException("Explicit synthetic deadlines required; production POLICY_UNSPECIFIED");
  frameMs=frame;fragmentMs=fragment;responseMs=response;inactivityMs=inactivity;
 }
}
