package com.rdx.fullscreen.clean;
/** Retained outer identity plus plaintext. Ciphertext length is NEVER overwritten with plaintext length. */
public final class DecryptedAaFragment {
 public final OuterFrameContext context;private final byte[] plaintext;
 public DecryptedAaFragment(OuterFrameContext c,byte[] b){if(c==null||b==null||b.length>16128)throw new IllegalArgumentException("Plaintext fragment bounds");context=c;plaintext=b.clone();}
 public byte[] plaintext(){return plaintext.clone();}public int plaintextLength(){return plaintext.length;}
 AaFrame metadataCarrier(){return new AaFrame(context.channel,context.flags,context.logicalTotal,new byte[0]);}
}
