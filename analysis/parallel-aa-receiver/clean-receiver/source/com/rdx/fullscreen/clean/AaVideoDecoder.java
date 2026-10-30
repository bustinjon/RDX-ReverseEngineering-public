package com.rdx.fullscreen.clean;
public interface AaVideoDecoder { void configure(VideoConfig config); void submit(byte[] accessUnit,long ptsUs); void stop(); }
