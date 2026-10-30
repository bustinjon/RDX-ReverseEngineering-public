package com.rdx.fullscreen.clean;
/** Raw outer frame: plaintext metadata and still-transformed body. */
public final class RawAaFrame {
 public final OuterFrameContext context;private final byte[] body;
 public RawAaFrame(OuterFrameContext c,byte[] b){if(c==null||b==null||c.ciphertextBodyLength<0||b.length!=c.ciphertextBodyLength)throw new IllegalArgumentException("Raw declared body mismatch");context=c;body=b.clone();}
 public byte[] body(){return body.clone();}
 public int bodyLength(){return body.length;}
}

