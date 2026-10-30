package com.rdx.fullscreen.clean;
/** Local safety policy, not phone-discovered protocol maxima. */
public final class ProtocolLimits {
 public static final int FRAME_BODY=16384, MESSAGE=65536, FRAMES_PER_FEED=256;
 public static final int PARTIAL_CHANNELS=8, RESERVED_BYTES=524288;
 public static final int FRAGMENTS_PER_MESSAGE=256;
 public static final int PROTO_BYTES=65536, PROTO_FIELDS=256, SERVICES=16, VIDEO_CONFIGS=8;
 public static final int STRING_BYTES=256, CONVERSATION_STEPS=128, ACCESS_UNIT=1048576;
 private ProtocolLimits(){}
}
