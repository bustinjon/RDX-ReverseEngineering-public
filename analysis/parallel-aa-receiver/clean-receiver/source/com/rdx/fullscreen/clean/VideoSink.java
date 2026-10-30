package com.rdx.fullscreen.clean;
/** Already-demultiplexed access units, not arbitrary USB/TLS/fragments. No MediaCodec dependency. */
public interface VideoSink {
 void configurationSelected(int index,VideoConfig configuration);
 void encodedAccessUnit(byte[] bytes,long presentationTimeUs);
 void streamStopped();
}
