package com.rdx.fullscreen.clean;
/** Pure host math for the future SurfaceRenderer. No Android dependency; no decoder/display access. */
public final class SurfaceViewport {
 private SurfaceViewport(){}
 public static final class Rect{
  public final int left,top,width,height;
  public Rect(int l,int t,int w,int h){left=l;top=t;width=w;height=h;}
  public boolean equals(Object o){if(!(o instanceof Rect))return false;Rect r=(Rect)o;return left==r.left&&top==r.top&&width==r.width&&height==r.height;}
  public int hashCode(){return ((left*31+top)*31+width)*31+height;}
  public String toString(){return "Rect("+left+","+top+" "+width+"x"+height+")";}
 }
 /**
  * Mirrors Honda's own DimensionUtils.makeViewport exactly (same rounding, same centering): aspect-fit
  * videoW x videoH into containerW x containerH. This reproduces the EXACT numbers in the captured logs
  * (1920x720 container, Honda's negotiated 1280x688 -> Rect(290,0 1340x720)) when given the same inputs.
  *
  * The caller MUST pass the ACTIVE (margin-subtracted) video dimensions, not the nominal/advertised ones.
  * Passing nominal dimensions here silently reproduces Honda's narrow-box bug in our own receiver: see
  * fitActive() and the regression test "nominal dims misused instead of active dims letterboxes" in
  * SurfaceViewportTests.java.
  */
 public static Rect fit(int containerW,int containerH,int videoW,int videoH){
  if(containerW<=0||containerH<=0||videoW<=0||videoH<=0)throw new IllegalArgumentException("Viewport dimensions");
  double r=Math.min((double)containerW/videoW,(double)containerH/videoH);
  int w=Math.min(containerW,2*(Math.round((float)(videoW*r))/2));
  int h=Math.min(containerH,2*(Math.round((float)(videoH*r))/2));
  int left=(containerW-w)/2,top=(containerH-h)/2;
  return new Rect(left,top,w,h);
 }
 /** Correct call shape for a real session: uses VideoConfig.activeWidth()/activeHeight(), never nominal. */
 public static Rect fitActive(int containerW,int containerH,VideoConfig video){
  return fit(containerW,containerH,video.activeWidth(),video.activeHeight());
 }
}
