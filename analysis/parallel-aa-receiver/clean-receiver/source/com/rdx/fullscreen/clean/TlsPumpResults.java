package com.rdx.fullscreen.clean;
/** Operation-specific immutable pump metadata. Output is copied; no transport or automatic work. */
public final class TlsPumpResults {
 private TlsPumpResults(){}
 public enum Action { CONTINUE, NEED_INPUT, DRAIN_OUTPUT, RUN_LOCAL_TASK, VERIFY_PEER, COMPLETE, PEER_CLOSED, FAILED, UNSUPPORTED }
 public enum Boundary { IN_PROGRESS, PROVEN_QUIESCENT, COMPLETION_UNPROVEN }
 public static class Accounting {
  public final int offered,consumed,produced;public final String status,handshake;public final Action action;private final byte[] output;
  Accounting(int o,int c,byte[] b,String s,String h,Action a){if(o<0||o>1048576||c<0||c>o||b==null||b.length>65535||a==null||s==null||h==null||s.length()>64||h.length()>64)throw new IllegalArgumentException("Pump accounting");offered=o;consumed=c;produced=b.length;output=b.clone();status=s;handshake=h;action=a;}
  public byte[] output(){return output.clone();}
 }
 public static final class HandshakeResult extends Accounting {
  public final boolean cryptoComplete;public final int retainedInput,tasks;
  public HandshakeResult(int o,int c,byte[] b,String s,String h,Action a,boolean done,int pending,int t){super(o,c,b,s,h,a);if(pending<0||pending>65535||t<0||t>64)throw new IllegalArgumentException("Handshake residue/tasks");cryptoComplete=done;retainedInput=pending;tasks=t;}
 }
 public static final class EncryptResult extends Accounting {
  public final long context;public final Boundary boundary;
  public EncryptResult(long id,int o,int c,byte[] b,String s,String h,Action a,Boundary q){super(o,c,b,s,h,a);if(id<0||q==null)throw new IllegalArgumentException("Encrypt context/boundary");context=id;boundary=q;}
 }
 public static final class DecryptResult extends Accounting {
  public final long context;public final Boundary boundary;public final int retainedInput;public final boolean peerClosed;
  public DecryptResult(long id,int o,int c,byte[] b,String s,String h,Action a,Boundary q,int retained,boolean closed){super(o,c,b,s,h,a);if(id<0||q==null||retained<0||retained>65535)throw new IllegalArgumentException("Decrypt context/residue");context=id;boundary=q;retainedInput=retained;peerClosed=closed;}
 }
 public static final class CloseResult extends Accounting {
  public final boolean inboundClosed,outboundClosed;
  public CloseResult(int o,int c,byte[] b,String s,String h,Action a,boolean in,boolean out){super(o,c,b,s,h,a);inboundClosed=in;outboundClosed=out;}
 }
}
