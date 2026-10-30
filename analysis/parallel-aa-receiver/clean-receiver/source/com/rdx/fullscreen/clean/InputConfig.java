package com.rdx.fullscreen.clean;
/** Input geometry is independent of video geometry. No automatic touch transform. */
public final class InputConfig {
 public final int width,height,physicalWidthMm,physicalHeightMm;public final boolean uiNavigation,uiAbsolute;
 public InputConfig(int w,int h,int mmw,int mmh,boolean nav,boolean absolute){if(w<1||w>65535||h<1||h>65535||mmw<1||mmw>1000||mmh<1||mmh>1000)throw new IllegalArgumentException("Input dimensions");width=w;height=h;physicalWidthMm=mmw;physicalHeightMm=mmh;uiNavigation=nav;uiAbsolute=absolute;}
 public static InputConfig hondaReference(){return new InputConfig(1325,720,60,40,true,true);}
}
