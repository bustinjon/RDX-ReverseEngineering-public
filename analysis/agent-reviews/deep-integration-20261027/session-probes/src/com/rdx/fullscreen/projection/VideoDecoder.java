package com.rdx.fullscreen.projection;
public class VideoDecoder {
 public interface Listener {void event(String t);void format(int w,int h);void rendered();}
 public int stops;public VideoDecoder(Listener l){}public void surface(android.view.Surface s){}public void start(){}
 public void dimensions(int w,int h){}public void config(byte[] b){}
 public boolean frame(byte[] b,Runnable ack){return true;}public boolean stop(){stops++;return true;}
}
