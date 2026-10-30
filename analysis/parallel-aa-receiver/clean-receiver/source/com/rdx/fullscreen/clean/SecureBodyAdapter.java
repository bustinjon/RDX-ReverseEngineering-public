package com.rdx.fullscreen.clean;
import java.util.*;
/** Contract only. No implementation/crypto/credentials. One established BODY context at a time. */
public interface SecureBodyAdapter {
 enum Outcome { PROGRESS,NO_OUTPUT_YET,BODY_COMPLETE,NEED_MORE_CIPHERTEXT,CLEAN_CLOSE,FATAL_ERROR,UNSUPPORTED_RENEGOTIATION }
 final class Result {
  public final long contextId;public final Outcome outcome;public final int residualBytes;private final List<byte[]> chunks;
  public Result(long id,Outcome status,List<byte[]> output,int residual){
   if(id<0||status==null||output==null||output.size()>1024||residual<0||residual>65535)throw new IllegalArgumentException("Adapter result bounds");
   List<byte[]> copy=new ArrayList<byte[]>();int total=0;for(byte[] b:output){if(b==null||b.length>65535||b.length>1048576-total)throw new IllegalArgumentException("Adapter output bound");total+=b.length;copy.add(b.clone());}
   contextId=id;outcome=status;residualBytes=residual;chunks=Collections.unmodifiableList(copy);
  }
  public List<byte[]> chunks(){List<byte[]> copy=new ArrayList<byte[]>();for(byte[] b:chunks)copy.add(b.clone());return Collections.unmodifiableList(copy);}
  public static Result empty(long id,Outcome s){return new Result(id,s,Collections.<byte[]>emptyList(),0);}
 }
 /** Placeholder identifiers ONLY, no certificate/key bytes or signing identity. */
 final class CredentialInputs {public final String rootCertificateSlot,clientCertificateSlot,privateKeySlot;
  public CredentialInputs(String root,String client,String key){if(root==null||client==null||key==null||root.length()>64||client.length()>64||key.length()>64)throw new IllegalArgumentException("Metadata slots");rootCertificateSlot=root;clientCertificateSlot=client;privateKeySlot=key;}
 }
 Result pumpHandshake(byte[] carrierBody);
 Result encryptBody(OuterFrameContext context,byte[] plaintext);
 Result beginDecrypt(OuterFrameContext context,byte[] ciphertext);
 Result drainDecrypt(OuterFrameContext context);
 void reset();void close();
}
