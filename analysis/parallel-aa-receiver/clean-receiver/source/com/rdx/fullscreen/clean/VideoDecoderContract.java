package com.rdx.fullscreen.clean;
/** No implementation in production. Input acceptance is NEVER display success. */
public interface VideoDecoderContract {
 enum Outcome { ACCEPTED,INPUT_REJECTED,BACKPRESSURE,CONFIGURATION_REJECTED,RESET_REQUIRED }
 final class Format {
  public final String mime="video/avc";public final H264.Configuration configuration;
  public Format(H264.Configuration c){if(c==null)throw new IllegalArgumentException("config");configuration=c;}
 }
 interface OutputObserver {void outputFormat(Format format);void error(String code);}
 void setOutputObserver(OutputObserver observer);
 Outcome configure(Format format);Outcome start();
 Outcome queue(H264.AccessUnit unit,MediaPayload.Timestamp rawTimestamp,Long explicitPresentationUs);
 void flush();void stop();
}
