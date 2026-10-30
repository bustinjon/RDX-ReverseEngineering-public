package com.rdx.fullscreen.clean;
import java.io.ByteArrayOutputStream;
import java.util.*;
/** Pure metadata-preserving BODY seam. No transport owner, clock, TLS implementation or automatic I/O. */
public final class SecureBodyPipeline {
 public static final int PLAINTEXT_FRAGMENT=16128,CIPHERTEXT_BODY=65535,LOGICAL_MESSAGE=1048576,RESERVED=2097152,ACTIVE_CHANNELS=2,MAX_DRAINS=256,MAX_BATCH_MESSAGES=128,MAX_BATCH_BYTES=2097152,MAX_INPUT=2097152;
 public enum State { OPEN,CLOSED,ERROR }
 private final SecureBodyAdapter adapter;private final SyntheticTlsState tls;
 private final AaFrameParser parser=new AaFrameParser(CIPHERTEXT_BODY,LOGICAL_MESSAGE,4096);
 private final AaMessageAssembler assembler=new AaMessageAssembler(LOGICAL_MESSAGE,ACTIVE_CHANNELS,RESERVED);
 private State state=State.OPEN;private String reason="NONE";private long nextId=1;private int maxDrains,maxPlain,maxCipher,maxReserved,maxParser;
 public SecureBodyPipeline(SecureBodyAdapter a,SyntheticTlsState t){if(t==null)throw new IllegalArgumentException("TLS state required");adapter=a;tls=t;}
 public State state(){return state;}public String reason(){return reason;}public int reservedBytes(){return assembler.reservedBytes();}public int partialBytes(){return parser.bufferedBytes();}
 public int maxDrainCalls(){return maxDrains;}public int maxPlaintext(){return maxPlain;}public int maxCiphertext(){return maxCipher;}public int maxReserved(){return maxReserved;}public int maxPartial(){return maxParser;}
 private void requireOpen(){if(state!=State.OPEN)throw new IllegalStateException("Terminal secure pipeline");}
 private long identity(){if(nextId==Long.MAX_VALUE)throw new IllegalStateException("Context exhausted");return nextId++;}
 private void fail(String why){reason=why;state=State.ERROR;parser.reset();assembler.reset();tls.fail();if(adapter!=null)try{adapter.reset();}catch(RuntimeException ignored){}}
 private IllegalArgumentException error(String why){fail(why);return new IllegalArgumentException(why);}
 public DecryptedAaFragment decrypt(RawAaFrame raw){
  requireOpen();if(raw==null)throw error("NULL_FRAME");OuterFrameContext c=raw.context;
  if(c.control()&&(!c.first()||!c.last()))throw error("CONTROL_FRAGMENTATION");
  maxCipher=Math.max(maxCipher,raw.bodyLength());
  if(!c.encrypted()){if(raw.bodyLength()>PLAINTEXT_FRAGMENT)throw error("PLAINTEXT_FRAGMENT_BOUND");return new DecryptedAaFragment(c,raw.body());}
  if(adapter==null||!tls.established())throw error("TLS_ADAPTER_NOT_ESTABLISHED");
  ByteArrayOutputStream plain=new ByteArrayOutputStream();
  try{
   SecureBodyAdapter.Result r=adapter.beginDecrypt(c,raw.body());int drains=0;
   while(true){
    if(r==null||r.contextId!=c.sequence)throw error("DECRYPT_CONTEXT_MISMATCH");
    for(byte[] b:r.chunks()){if(b.length>PLAINTEXT_FRAGMENT-plain.size())throw error("PLAINTEXT_FRAGMENT_BOUND");plain.write(b,0,b.length);}
    maxPlain=Math.max(maxPlain,plain.size());
    if(r.outcome==SecureBodyAdapter.Outcome.BODY_COMPLETE){if(r.residualBytes!=0)throw error("UNEXPECTED_RESIDUAL_STATE");return new DecryptedAaFragment(c,plain.toByteArray());}
    if(r.outcome==SecureBodyAdapter.Outcome.NEED_MORE_CIPHERTEXT)throw error("BODY_DECRYPT_INCOMPLETE");
    if(r.outcome==SecureBodyAdapter.Outcome.CLEAN_CLOSE){cleanClose();throw new IllegalStateException("CLEAN_CLOSE_DURING_BODY");}
    if(r.outcome==SecureBodyAdapter.Outcome.FATAL_ERROR)throw error("TLS_BODY_FATAL");
    if(r.outcome==SecureBodyAdapter.Outcome.UNSUPPORTED_RENEGOTIATION)throw error("RENEGOTIATION_UNSUPPORTED");
    if(++drains>MAX_DRAINS)throw error("DECRYPT_DRAIN_LIMIT");maxDrains=Math.max(maxDrains,drains);r=adapter.drainDecrypt(c);
   }
  }catch(RuntimeException ex){if(state==State.OPEN)fail("ADAPTER_EXCEPTION");throw ex;}
 }
 public List<AaMessageAssembler.Message> receive(byte[] input){
  requireOpen();if(input==null||input.length>MAX_INPUT)throw error("INPUT_BATCH_BOUND");List<AaMessageAssembler.Message> result=new ArrayList<AaMessageAssembler.Message>();int resultBytes=0;
  try{for(int off=0;off<input.length;off+=16384){int n=Math.min(16384,input.length-off);
   List<AaFrame> frames=parser.feed(input,off,n);maxParser=Math.max(maxParser,parser.bufferedBytes());
   for(AaFrame f:frames){OuterFrameContext c=new OuterFrameContext(identity(),f.channel,f.flags,f.bodyLength(),f.totalPlaintextLength);DecryptedAaFragment p=decrypt(new RawAaFrame(c,f.body()));
    AaMessageAssembler.Message m=assembler.acceptDecoded(p.metadataCarrier(),p.plaintext());maxReserved=Math.max(maxReserved,assembler.reservedBytes());
    if(m!=null){if(result.size()==MAX_BATCH_MESSAGES)throw error("MESSAGE_BATCH_BOUND");int bytes=m.bytes().length;if(bytes>MAX_BATCH_BYTES-resultBytes)throw error("MESSAGE_BATCH_BYTES_BOUND");resultBytes+=bytes;result.add(m);}
   }
  }return result;}catch(RuntimeException ex){if(state==State.OPEN)fail("FRAMING_OR_PLAINTEXT_ERROR");throw ex;}
 }
 public List<byte[]> encode(int channel,int semanticFlags,byte[] logical,boolean encrypted){
  requireOpen();if(channel<0||channel>255||(semanticFlags&~4)!=0||logical==null||logical.length<2||logical.length>LOGICAL_MESSAGE)throw error("OUTBOUND_LOGICAL_BOUNDS");
  if((semanticFlags&4)!=0&&logical.length>PLAINTEXT_FRAGMENT)throw error("CONTROL_FRAGMENTATION");
  if(encrypted&&(adapter==null||!tls.established()))throw error("TLS_ADAPTER_NOT_ESTABLISHED");
  List<byte[]> frames=new ArrayList<byte[]>();
  try{for(int offset=0;offset<logical.length;){int n=Math.min(PLAINTEXT_FRAGMENT,logical.length-offset);int flags=semanticFlags|(encrypted?8:0)|(offset==0?1:0)|(offset+n==logical.length?2:0);int total=(flags&3)==1?logical.length:-1;
   byte[] plain=Arrays.copyOfRange(logical,offset,offset+n),body=plain;
   if(encrypted){long id=identity();OuterFrameContext request=new OuterFrameContext(id,channel,flags,-1,total);SecureBodyAdapter.Result r=adapter.encryptBody(request,plain);
    if(r==null||r.contextId!=id||r.outcome!=SecureBodyAdapter.Outcome.BODY_COMPLETE||r.residualBytes!=0)throw error("ENCRYPT_BODY_INCOMPLETE");
    ByteArrayOutputStream encryptedBytes=new ByteArrayOutputStream();for(byte[] chunk:r.chunks()){if(chunk.length>CIPHERTEXT_BODY-encryptedBytes.size())throw error("CIPHERTEXT_BODY_BOUND");encryptedBytes.write(chunk,0,chunk.length);}body=encryptedBytes.toByteArray();if(body.length==0)throw error("EMPTY_ENCRYPTED_BODY");
   }
   maxPlain=Math.max(maxPlain,n);maxCipher=Math.max(maxCipher,body.length);
   frames.add(new AaFrameWriter().encode(new AaFrame(channel,flags,total,body)));offset+=n;
  }return frames;}catch(RuntimeException ex){if(state==State.OPEN)fail("ADAPTER_EXCEPTION");throw ex;}
 }
 public void endOfInput(){requireOpen();try{parser.endOfInput();assembler.endOfInput();cleanClose();}catch(RuntimeException ex){if(state==State.OPEN)fail("TRUNCATED_EOF");throw ex;}}
 public void cleanClose(){if(state!=State.OPEN)return;boolean pending=parser.hasPartialFrame()||assembler.activeChannels()!=0;parser.reset();assembler.reset();if(pending){fail("CLOSE_WITH_INCOMPLETE_FRAME_OR_MESSAGE");return;}state=State.CLOSED;reason="CLEAN_CLOSE";tls.cleanClose();if(adapter!=null)try{adapter.close();}catch(RuntimeException ex){state=State.ERROR;reason="ADAPTER_CLOSE_ERROR";tls.fail();}}
 public void reset(){if(adapter!=null)try{adapter.reset();}catch(RuntimeException ignored){}parser.reset();assembler.reset();if(state==State.OPEN){state=State.CLOSED;reason="EXPLICIT_RESET_REQUIRES_NEW_SESSION";tls.reset();}}
}


