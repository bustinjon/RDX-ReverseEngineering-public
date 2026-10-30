package com.rdx.fullscreen.clean;
/** HOST fake: no decoding, no retained unbounded AU arrays or presentation count. */
public final class FakeVideoDecoder implements VideoDecoderContract {
 private OutputObserver observer;
 public void setOutputObserver(OutputObserver value){observer=value;}
 public void emitOutputFormatForTest(Format value){if(observer!=null)observer.outputFormat(value);}
 public void emitErrorForTest(String value){if(observer!=null)observer.error(value);}
 public Outcome configureResult=Outcome.ACCEPTED,next=Outcome.ACCEPTED;public int pressureCalls,configureCalls,startCalls,flushCalls,stopCalls,queueCalls,accepted,rejected;public long digest=1469598103934665603L;public Format format;
 public Outcome configure(Format f){configureCalls++;format=f;return configureResult;}public Outcome start(){startCalls++;return Outcome.ACCEPTED;}
 public Outcome queue(H264.AccessUnit unit,MediaPayload.Timestamp timestamp,Long pts){queueCalls++;if(pressureCalls>0){pressureCalls--;return Outcome.BACKPRESSURE;}Outcome result=next;next=Outcome.ACCEPTED;if(result==Outcome.ACCEPTED||result==Outcome.INPUT_REJECTED){for(byte b:unit.bytes())digest=(digest^(b&255))*1099511628211L;digest^=timestamp.unsignedBits;if(pts!=null)digest^=pts.longValue();if(result==Outcome.ACCEPTED)accepted++;else rejected++;}return result;}
 public void flush(){flushCalls++;}public void stop(){stopCalls++;format=null;}
}
