package com.rdx.fullscreen.clean;
import java.util.*;
/** Explicit already-decrypted WHOLE PROTOCOL FRAME simulation seam; NOT streaming TLS. */
public final class PlaintextVideoBridge {
 private final AaFrameParser parser=new AaFrameParser(16384,1048576,256);
 private final AaMessageAssembler assembler=new AaMessageAssembler(1048576,2,2097152);
 private final VideoDataPlane plane;private final boolean syntheticImmediateAccounting;private boolean failed;private long now,partialSince=-1;
 public PlaintextVideoBridge(VideoDataPlane p){this(p,false);}
 /** Synthetic ACK timing policy only, not Honda decoder/output timing. */
 public PlaintextVideoBridge(VideoDataPlane p,boolean drain){if(p==null)throw new IllegalArgumentException("plane");plane=p;syntheticImmediateAccounting=drain;}
 public int reservedBytes(){return assembler.reservedBytes();}public int partialBytes(){return parser.bufferedBytes();}public boolean failed(){return failed;}
 public void acceptAlreadyDecryptedFrames(byte[] bytes,long monotonicNow){
  if(failed||plane.state()==VideoDataPlane.State.ERROR||plane.state()==VideoDataPlane.State.STOPPED)return;
  if(bytes==null||bytes.length>33554432||monotonicNow<now){invalidate("BRIDGE_INPUT_BOUND_OR_CLOCK");return;}now=monotonicNow;
  try{for(int p=0;p<bytes.length;p+=32768){byte[] chunk=Arrays.copyOfRange(bytes,p,Math.min(bytes.length,p+32768));
   for(AaFrame f:parser.feed(chunk)){
    if((f.flags&(AaFrame.ENCRYPTED|AaFrame.CONTROL))!=0)throw new IllegalArgumentException("Opaque encrypted/control bytes cannot bypass plaintext gate");
    AaMessageAssembler.Message m=assembler.accept(f);if(m==null)continue;
    if(m.type==0||m.type==1){byte[] payload=Arrays.copyOfRange(m.bytes(),2,m.bytes().length);String disposition=plane.accept(m.channel,MediaPayload.parse(m.type,payload),now,null);if(disposition.equals("BACKPRESSURE")){invalidate("WIRE_ADMISSION_FULL; upstream pause/retry not implemented");return;}if(syntheticImmediateAccounting)plane.takeAccountingAck();}
    else if(m.type==0x8002){if(m.bytes().length!=2)throw new IllegalArgumentException("Stop subset");plane.stopOnChannel(m.channel);}
    else throw new IllegalArgumentException("UNKNOWN_VIDEO_MESSAGE");
    if(plane.state()==VideoDataPlane.State.ERROR||plane.state()==VideoDataPlane.State.STOPPED){parser.reset();assembler.reset();return;}
   }
  }if(parser.hasPartialFrame()||assembler.activeChannels()>0){if(partialSince<0)partialSince=now;}else partialSince=-1;
  }catch(IllegalArgumentException e){invalidate("MALFORMED_OR_UNSUPPORTED_MEDIA_WIRE");}catch(IllegalStateException e){invalidate("REASSEMBLY_STATE_ERROR");}
 }
 public void tick(long at,long injectedDeadline){if(failed)return;if(at<now||injectedDeadline<1){invalidate("CLOCK_POLICY");return;}now=at;if(partialSince>=0&&at-partialSince>=injectedDeadline)invalidate("PARTIAL_FRAME_OR_FRAGMENT_TIMEOUT");}
 public void opaqueEncryptedBytes(byte[] bytes){invalidate("REAL_TLS_ADAPTER_REQUIRED; opaque bytes not parsed");}
 public void end(){if(failed)return;try{parser.endOfInput();assembler.endOfInput();}catch(RuntimeException e){invalidate("TRUNCATED_MEDIA_WIRE");}}
 public void reset(){failed=true;parser.reset();assembler.reset();plane.discontinuity();}
 private void invalidate(String why){failed=true;parser.reset();assembler.reset();plane.fail(why);}
}
