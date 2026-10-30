package com.google.android.projection.protocol;
public class GalReceiver {
 public interface Listener{void event(String t);void discovery();void byeBye();}
 public int prepares,destroys;
 public GalReceiver(Listener l){} public void initialize(String[] s){}public long handle(){return 1;}
 public void register(VideoSink v){}public void register(InputSource v){}public void startProtocol(){}
 public int remaining(byte[] b){return 0;}public void incoming(byte[] b,int n){}
 public int outgoing(byte[] b){return 0;}public void ping(long t){}
 public void prepare(){prepares++;}public void destroy(){destroys++;}
}
