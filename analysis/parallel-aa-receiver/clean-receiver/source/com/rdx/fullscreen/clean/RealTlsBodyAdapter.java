package com.rdx.fullscreen.clean;
import java.util.*;
import java.io.ByteArrayOutputStream;
import com.rdx.fullscreen.clean.TlsPumpResults.*;
/** Atomic AA BODY transaction over the explicit real pump. No transport; strict TLS1.2 app-record policy. */
public final class RealTlsBodyAdapter implements SecureBodyAdapter {
 private final MemoryTlsEngine engine;private long active=-1;public int decryptChunk=65535,outputCapacity=18437;public long bodies,records;public int maxCipher,maxPlain,maxIterations;
 public RealTlsBodyAdapter(MemoryTlsEngine e){if(e==null)throw new IllegalArgumentException("Explicit engine");engine=e;}
 private void acquire(long id){if(active!=-1||!engine.application())throw new IllegalStateException("Body ownership/state");active=id;}
 private Result failure(RuntimeException e){engine.abort();active=-1;throw e;}
 public Result pumpHandshake(byte[] b){throw new IllegalStateException("Use typed MemoryTlsEngine handshake API, not ambiguous compatibility method");}
 public Result encryptBody(OuterFrameContext c,byte[] plain){
  acquire(c.sequence);try{if(plain==null||plain.length>16128)throw new IllegalArgumentException("AA plaintext fragment bound");ByteArrayOutputStream out=new ByteArrayOutputStream();int offset=0,cap=outputCapacity,steps=0;Boundary boundary=Boundary.IN_PROGRESS;
   while(offset<plain.length){if(++steps>256)throw new IllegalArgumentException("Encrypt progress bound");EncryptResult r=engine.wrap(c.sequence,plain,offset,plain.length-offset,cap);if(r.status.equals("BUFFER_OVERFLOW")){if(cap>=65535)throw new IllegalArgumentException("TLS output growth bound");cap=Math.min(65535,Math.max(cap*2,engine.packetSize()));continue;}offset+=r.consumed;if(out.size()+r.produced>65535)throw new IllegalArgumentException("Cipher bound");out.write(r.output(),0,r.produced);boundary=r.boundary;if(r.consumed==0&&r.produced==0)throw new IllegalArgumentException("Encrypt no progress");}
   boolean drained=false;while(++steps<=256){EncryptResult tail=engine.wrap(c.sequence,new byte[0],0,0,Math.max(cap,engine.packetSize()));if(out.size()+tail.produced>65535)throw new IllegalArgumentException("Cipher drain bound");out.write(tail.output(),0,tail.produced);if(tail.produced==0){drained=true;break;}}
   byte[] body=out.toByteArray();boundary=engine.proveBodyBoundary(body,drained);if(boundary!=Boundary.PROVEN_QUIESCENT||engine.pending()!=0)throw new IllegalArgumentException("ENCRYPT_COMPLETION_UNPROVEN");records+=TlsRecordLedger.completeApplicationRecords(body);maxCipher=Math.max(maxCipher,body.length);maxPlain=Math.max(maxPlain,plain.length);maxIterations=Math.max(maxIterations,steps);bodies++;active=-1;return new Result(c.sequence,Outcome.BODY_COMPLETE,Collections.singletonList(body),0);
  }catch(Exception e){return failure(new IllegalArgumentException("Encrypt transaction: "+e.getMessage(),e));}
 }
 public Result beginDecrypt(OuterFrameContext c,byte[] ciphertext){
  acquire(c.sequence);try{records+=TlsRecordLedger.completeApplicationRecords(ciphertext);if(engine.pending()!=0)throw new IllegalArgumentException("Preexisting TLS input");ByteArrayOutputStream out=new ByteArrayOutputStream();int offset=0,steps=0;Boundary boundary=Boundary.IN_PROGRESS;int cap=outputCapacity;
   while(true){if(++steps>131072)throw new IllegalArgumentException("Decrypt progress bound");int n=Math.min(Math.max(1,decryptChunk),ciphertext.length-offset);byte[] input=Arrays.copyOfRange(ciphertext,offset,offset+n);offset+=n;DecryptResult r=engine.unwrap(c.sequence,input,cap);
    if(r.peerClosed)throw new IllegalArgumentException("TLS closed during application body");if(out.size()+r.produced>16128)throw new IllegalArgumentException("Plaintext fragment bound");out.write(r.output(),0,r.produced);boundary=r.boundary;
    if(r.status.equals("BUFFER_OVERFLOW")){if(cap>=65535)throw new IllegalArgumentException("TLS scratch bound");cap=Math.min(65535,Math.max(cap*2,engine.applicationSize()));continue;}
    if(offset<ciphertext.length)continue;
    if(engine.pending()!=0){if(r.consumed==0&&r.produced==0)throw new IllegalArgumentException("BODY_DECRYPT_INCOMPLETE");continue;}
    // Mandatory empty-input drain after complete-record input: never infer completion from one unwrap.
    DecryptResult tail=engine.unwrap(c.sequence,new byte[0],cap);if(tail.peerClosed||tail.retainedInput!=0)throw new IllegalArgumentException("Residual/close");if(out.size()+tail.produced>16128)throw new IllegalArgumentException("Plaintext drain bound");out.write(tail.output(),0,tail.produced);
    if(tail.produced!=0)continue;boundary=engine.proveBodyBoundary(ciphertext,true);if(boundary!=Boundary.PROVEN_QUIESCENT)throw new IllegalArgumentException("DECRYPT_COMPLETION_UNPROVEN");break;
   }
   maxCipher=Math.max(maxCipher,ciphertext.length);maxPlain=Math.max(maxPlain,out.size());maxIterations=Math.max(maxIterations,steps);bodies++;active=-1;return new Result(c.sequence,Outcome.BODY_COMPLETE,Collections.singletonList(out.toByteArray()),0);
  }catch(Exception e){return failure(new IllegalArgumentException("Decrypt transaction: "+e.getMessage(),e));}
 }
 public Result drainDecrypt(OuterFrameContext c){throw new IllegalStateException("No pending atomic body; context already completed or aborted");}
 public void reset(){active=-1;engine.abort();}
 public void close(){active=-1;if(engine.state()!=MemoryTlsEngine.State.CLOSED)engine.abort();} // Preserve an already proven typed close; otherwise abort, never fabricate graceful closure.
}
