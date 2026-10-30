package com.rdx.fullscreen.clean;
import java.util.*;
/** HOST ONLY. Prefix padding/identity copies, NO CRYPTO. Programmable drain/failure behavior. */
public final class FakeSecureBodyAdapter implements SecureBodyAdapter {
 public int padding,chunkSize=4096,batchChunks=1,zeroDrains,failAt=-1,closeAt=-1;public long wrongContext;
 public boolean needMore,residual,endless,throwOnBegin,renegotiate;public int encryptCalls,decryptCalls,drainCalls,handshakeCalls,resets,closes;
 public byte[] nextHandshakeOutput;private byte[] pending;private int cursor,zeros,round;private long id;
 public Result pumpHandshake(byte[] b){handshakeCalls++;if(nextHandshakeOutput!=null){byte[] value=nextHandshakeOutput;nextHandshakeOutput=null;return new Result(0,Outcome.PROGRESS,Collections.singletonList(value),0);}return Result.empty(0,Outcome.NO_OUTPUT_YET);}
 public Result encryptBody(OuterFrameContext c,byte[] plain){encryptCalls++;if(padding<0||padding>65535)throw new IllegalArgumentException("Fake padding");byte[] out=new byte[plain.length+padding];Arrays.fill(out,0,padding,(byte)0xA5);System.arraycopy(plain,0,out,padding,plain.length);List<byte[]> chunks=new ArrayList<byte[]>();for(int p=0;p<out.length;p+=65535)chunks.add(Arrays.copyOfRange(out,p,Math.min(out.length,p+65535)));return new Result(c.sequence,Outcome.BODY_COMPLETE,chunks,0);}
 public Result beginDecrypt(OuterFrameContext c,byte[] cipher){decryptCalls++;if(throwOnBegin)throw new IllegalStateException("Injected exception");if(pending!=null)throw new IllegalStateException("Unexpected residual fake context");if(cipher.length<padding)throw new IllegalArgumentException("Incomplete fake prefix");for(int i=0;i<padding;i++)if(cipher[i]!=(byte)0xA5)throw new IllegalArgumentException("Fake prefix mismatch");pending=Arrays.copyOfRange(cipher,padding,cipher.length);cursor=0;zeros=zeroDrains;round=0;id=c.sequence;return next();}
 public Result drainDecrypt(OuterFrameContext c){drainCalls++;if(c.sequence!=id||pending==null)throw new IllegalStateException("Fake ownership");return next();}
 private Result next(){
  int r=round++;long context=id+wrongContext;
  if(needMore)return Result.empty(context,Outcome.NEED_MORE_CIPHERTEXT);
  if(renegotiate)return Result.empty(context,Outcome.UNSUPPORTED_RENEGOTIATION);
  if(r==failAt)return Result.empty(context,Outcome.FATAL_ERROR);
  if(r==closeAt)return Result.empty(context,Outcome.CLEAN_CLOSE);
  if(endless||zeros-->0)return Result.empty(context,Outcome.NO_OUTPUT_YET);
  if(chunkSize<1||batchChunks<1)throw new IllegalStateException("Fake chunks");List<byte[]> out=new ArrayList<byte[]>();
  for(int k=0;k<batchChunks&&cursor<pending.length;k++){int end=Math.min(pending.length,cursor+chunkSize);out.add(Arrays.copyOfRange(pending,cursor,end));cursor=end;}
  boolean done=cursor==pending.length;if(done)pending=null;
  return new Result(context,done?Outcome.BODY_COMPLETE:Outcome.PROGRESS,out,residual&&done?1:0);
 }
 public void reset(){pending=null;cursor=zeros=round=0;resets++;}public void close(){reset();closes++;}
}

