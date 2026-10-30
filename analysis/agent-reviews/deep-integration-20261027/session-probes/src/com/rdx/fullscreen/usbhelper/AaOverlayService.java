package com.rdx.fullscreen.usbhelper;
public class AaOverlayService {
 public interface SurfaceReadyListener{void onSurfaceReady(android.view.Surface s,int w,int h);void onSurfaceLost();}
 public interface TouchListener{void onAaTouch(int action,float rx,float ry,float ax,float ay,long t);}
 public static AaOverlayService instance;
 public static AaOverlayService getInstance(){return instance;}
 public boolean ready;public SurfaceReadyListener surfaceListener;public TouchListener touchListener;
 public void setSurfaceReadyListener(SurfaceReadyListener l){surfaceListener=l;}
 public void setTouchListener(TouchListener l){touchListener=l;}
 public boolean isSurfaceReady(){return ready;}public android.view.Surface getVideoSurface(){return new android.view.Surface();}
}
