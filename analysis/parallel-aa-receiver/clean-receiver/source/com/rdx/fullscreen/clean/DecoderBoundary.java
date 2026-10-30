package com.rdx.fullscreen.clean;
/** Future explicit lifecycle contract; no implementation or resource allocation here. */
public interface DecoderBoundary {
 void configure(VideoConfig config); void start(); void queue(byte[] opaqueAccessUnit,long ptsUs); void flush(); void stop();
}
