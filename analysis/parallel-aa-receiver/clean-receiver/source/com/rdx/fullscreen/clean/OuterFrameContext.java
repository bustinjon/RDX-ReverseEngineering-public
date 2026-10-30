package com.rdx.fullscreen.clean;
/** Immutable metadata parsed OUTSIDE TLS. sequence is a LOCAL attribution identity, never a wire field. */
public final class OuterFrameContext {
 /** ciphertextBodyLength=-1 is an outbound pre-encryption intent ONLY; RawAaFrame forbids it. */
 public final long sequence;public final int channel,flags,ciphertextBodyLength,logicalTotal;
 public OuterFrameContext(long id,int channel,int flags,int ciphertextLength,int total){
  if(id<0||channel<0||channel>255||flags<0||(flags&~15)!=0||ciphertextLength< -1||ciphertextLength>65535)throw new IllegalArgumentException("Outer bounds");
  boolean extension=(flags&3)==1;if(extension?total<2||total>1048576:total!=-1)throw new IllegalArgumentException("Logical total");
  sequence=id;this.channel=channel;this.flags=flags;ciphertextBodyLength=ciphertextLength;logicalTotal=total;
 }
 public boolean encrypted(){return (flags&8)!=0;}public boolean first(){return (flags&1)!=0;}public boolean last(){return (flags&2)!=0;}public boolean control(){return (flags&4)!=0;}
}

