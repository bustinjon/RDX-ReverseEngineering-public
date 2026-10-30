package com.rdx.fullscreen.decodertest;
public final class ClipCatalog {
 public static final String[] FILES={"grid-1280x720-30.mp4","grid-1280x688-60.mp4","grid-1920x720-30.mp4","grid-1920x720-60.mp4","grid-1920x1080-30.mp4","grid-1920x1080-60.mp4"};
 public static final int[] WIDTH={1280,1280,1920,1920,1920,1920};
 public static final int[] HEIGHT={720,688,720,720,1080,1080};
 public static final int[] FPS={30,60,30,60,30,60};
 public static String describe(int index){return FILES[index]+" | "+WIDTH[index]+"x"+HEIGHT[index]+" | "+FPS[index]+" FPS | 10 seconds | OMX.TI.DUCATI1.VIDEO.DECODER";}
 private ClipCatalog(){}
}
