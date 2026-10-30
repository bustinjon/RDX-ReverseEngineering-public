package com.google.android.projection.protocol;
public class InputSource {
 public static final int ACTION_DOWN=0,ACTION_UP=1,ACTION_MOVE=2;public int destroys;
 public void initialize(int id,long h){}public void registerTouchPad(int w,int h,int pw,int ph,boolean nav,boolean abs){}
 public void sendTouchPad(int action,int x,int y,long t){}public void destroy(){destroys++;}
}
