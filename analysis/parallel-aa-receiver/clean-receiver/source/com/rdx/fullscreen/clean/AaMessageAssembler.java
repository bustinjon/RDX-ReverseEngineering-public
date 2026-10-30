package com.rdx.fullscreen.clean;
import java.util.*;
/** Reassembly is AFTER decryption. No TLS records are treated as plaintext messages. */
public final class AaMessageAssembler {
 public static final class Message {
  public final int channel,flags,type;private final byte[] bytes;
  Message(int c,int f,byte[] b){if(b.length<2)throw new IllegalArgumentException("Missing message type");channel=c;flags=f;bytes=b.clone();type=((b[0]&255)<<8)|(b[1]&255);}
  public byte[] bytes(){return bytes.clone();}
 }
 private static final class Pending {int expected,flags,used,fragments;byte[] bytes;}
 private final Map<Integer,Pending> pending=new HashMap<Integer,Pending>();private final int maxMessage,maxChannels,maxReserved;private int reserved;
 private boolean failed;
 public AaMessageAssembler(int m,int channels,int memory){if(m<2||m>16777216||channels<1||channels>256||memory<m||memory>33554432)throw new IllegalArgumentException("Limits");maxMessage=m;maxChannels=channels;maxReserved=memory;}
 public Message accept(AaFrame f){if(f==null||(f.flags&AaFrame.ENCRYPTED)!=0){reset();failed=true;throw new IllegalArgumentException("Non-null plaintext frame/TLS adapter required");}return acceptDecoded(f,f.body());}
 public Message acceptDecoded(AaFrame f,byte[] plaintext){
  if(failed)throw new IllegalStateException("Assembler failed; explicit reset required");
  try{return acceptChecked(f,plaintext);}catch(RuntimeException e){reset();failed=true;throw e;}
 }
 private Message acceptChecked(AaFrame f,byte[] plaintext){
  if(f==null||plaintext==null)throw new IllegalArgumentException("Null frame/plaintext");
  boolean first=(f.flags&AaFrame.FIRST)!=0,last=(f.flags&AaFrame.LAST)!=0;Pending p=pending.get(f.channel);
  if(first){
   if(p!=null)throw new IllegalArgumentException("Overlapping first/complete frame");
   if(last){if(plaintext.length>maxMessage)throw new IllegalArgumentException("Message limit");return new Message(f.channel,f.flags,plaintext);}
   if(f.totalPlaintextLength>maxMessage||pending.size()>=maxChannels||f.totalPlaintextLength>maxReserved-reserved)throw new IllegalArgumentException("Reassembly limits");
   p=new Pending();p.expected=f.totalPlaintextLength;p.flags=f.flags&12;p.bytes=new byte[p.expected];pending.put(f.channel,p);reserved+=p.expected;
  }else if(p==null)throw new IllegalArgumentException("Continuation without first");
  if(++p.fragments>ProtocolLimits.FRAGMENTS_PER_MESSAGE)throw new IllegalArgumentException("Fragment count limit");
  if((f.flags&12)!=p.flags)throw new IllegalArgumentException("Fragment flag mismatch");
  if(plaintext.length>p.expected-p.used)throw new IllegalArgumentException("Reassembly overflow");
  System.arraycopy(plaintext,0,p.bytes,p.used,plaintext.length);p.used+=plaintext.length;
  if(!last)return null;
  if(p.used!=p.expected)throw new IllegalArgumentException("Reassembly underflow");
  pending.remove(f.channel);reserved-=p.expected;return new Message(f.channel,p.flags,p.bytes);
 }
 public int activeChannels(){return pending.size();}
 public int reservedBytes(){return reserved;}
 public boolean isFailed(){return failed;}
 public void endOfInput(){if(failed)throw new IllegalStateException("Assembler failed");if(!pending.isEmpty()){reset();failed=true;throw new IllegalArgumentException("Truncated message");}}
 public void reset(){pending.clear();reserved=0;failed=false;}
}
