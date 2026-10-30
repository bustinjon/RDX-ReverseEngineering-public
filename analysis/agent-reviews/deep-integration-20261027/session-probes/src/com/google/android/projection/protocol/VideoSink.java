package com.google.android.projection.protocol;
public class VideoSink {
 public interface Listener{void config(int i,int w,int h,int aw,int ah,int dpi);void codecConfig(byte[] b);void codecSetup();void frame(int s,long t,java.nio.ByteBuffer b);void focus(int m,int r);}
 public int destroys; public VideoSink(Listener l){}public void initialize(long h,int dpi){}public void requestVideo(){}
 public void ack(int s){}public void answerVideoFocus(int m){}public void destroy(){destroys++;}
}
