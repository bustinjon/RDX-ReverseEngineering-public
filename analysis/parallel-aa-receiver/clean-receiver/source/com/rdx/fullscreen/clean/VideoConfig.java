package com.rdx.fullscreen.clean;
public final class VideoConfig {
 public enum Placement { UNSPECIFIED }
 public final int nominalWidth,nominalHeight,marginWidth,marginHeight,dpi,fps;
 public final Placement placement=Placement.UNSPECIFIED;
 public VideoConfig(int w,int h,int mw,int mh,int density,int rate){
  if(!((w==1280&&h==720)||(w==1920&&h==1080))||mw<0||mh<0||mw>=w||mh>=h||density<1||density>1000||(rate!=30&&rate!=60))throw new IllegalArgumentException("Video configuration");
  nominalWidth=w;nominalHeight=h;marginWidth=mw;marginHeight=mh;dpi=density;fps=rate;
 }
 public int activeWidth(){return nominalWidth-marginWidth;}
 public int activeHeight(){return nominalHeight-marginHeight;}
 public static VideoConfig conservative(){return new VideoConfig(1280,720,0,32,229,60);}
 public static VideoConfig fullscreenExperiment(){return new VideoConfig(1920,1080,0,360,229,30);}
}
