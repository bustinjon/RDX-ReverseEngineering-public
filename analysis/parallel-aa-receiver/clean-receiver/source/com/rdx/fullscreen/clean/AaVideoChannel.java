package com.rdx.fullscreen.clean;
public final class AaVideoChannel {
 private final AaVideoDecoder decoder;public final VideoConfig config;
 public AaVideoChannel(VideoConfig c,AaVideoDecoder d){config=c;decoder=d;}
 public void open(){throw new UnsupportedOperationException("Video startup disabled");}
}
