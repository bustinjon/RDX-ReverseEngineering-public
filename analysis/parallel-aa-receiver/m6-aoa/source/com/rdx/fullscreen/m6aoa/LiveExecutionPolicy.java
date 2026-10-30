package com.rdx.fullscreen.m6aoa;
/** This frozen release is never a live AOA tool. No intent/flag/environment override. */
public final class LiveExecutionPolicy {
 public static final boolean EXECUTION_ENABLED=false;
 private LiveExecutionPolicy(){}
 public static void requireReviewedActivation(){if(!EXECUTION_ENABLED)throw new SecurityException("M6_LIVE_DISABLED_FROZEN_RELEASE");}
}
