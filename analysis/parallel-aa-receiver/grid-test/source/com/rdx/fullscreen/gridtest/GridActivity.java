package com.rdx.fullscreen.gridtest;
import android.app.Activity;
import android.os.Bundle;
import android.graphics.*;
import android.util.*;
import android.view.*;
import android.widget.*;

public final class GridActivity extends Activity {
 private SurfaceView grid;
 @Override public void onCreate(Bundle state) {
  super.onCreate(state);
  getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, WindowManager.LayoutParams.FLAG_FULLSCREEN);
  FrameLayout root = new FrameLayout(this);
  grid = new SurfaceView(this);
  root.addView(grid, new FrameLayout.LayoutParams(-1,-1));
  Button exit = new Button(this); exit.setText("EXIT GRID");
  FrameLayout.LayoutParams button = new FrameLayout.LayoutParams(160,65,Gravity.RIGHT|Gravity.BOTTOM);
  root.addView(exit,button);
  exit.setOnClickListener(new View.OnClickListener(){public void onClick(View v){finish();}});
  setContentView(root);
  grid.getHolder().addCallback(new SurfaceHolder.Callback(){
   public void surfaceCreated(SurfaceHolder h){}
   public void surfaceChanged(SurfaceHolder h,int format,int w,int height){drawGrid(h,w,height);}
   public void surfaceDestroyed(SurfaceHolder h){}
  });
 }
 private void drawGrid(SurfaceHolder holder,int w,int h){
  DisplayMetrics real=new DisplayMetrics(); getWindowManager().getDefaultDisplay().getRealMetrics(real);
  DisplayMetrics app=new DisplayMetrics(); getWindowManager().getDefaultDisplay().getMetrics(app);
  Rect window=new Rect(); getWindow().getDecorView().getWindowVisibleDisplayFrame(window);
  String info="Surface="+w+"x"+h+" physical="+real.widthPixels+"x"+real.heightPixels
   +" appDisplay="+app.widthPixels+"x"+app.heightPixels+" densityDpi="+app.densityDpi
   +" xdpi="+app.xdpi+" ydpi="+app.ydpi+" Hz="+getWindowManager().getDefaultDisplay().getRefreshRate()
   +" orientation="+getResources().getConfiguration().orientation+" view="+grid.getWidth()+"x"+grid.getHeight()
   +" decor="+getWindow().getDecorView().getWidth()+"x"+getWindow().getDecorView().getHeight()+" visibleFrame="+window;
  Log.i("RDX.GRID",info);
  Canvas c=null;
  try{
   c=holder.lockCanvas(); if(c==null)return;
   c.drawColor(Color.rgb(10,20,35)); Paint p=new Paint(Paint.ANTI_ALIAS_FLAG); p.setTextSize(23);
   for(int x=0;x<=1900;x+=100){p.setColor(Color.GRAY);c.drawLine(x,0,x,h,p);p.setColor(Color.WHITE);c.drawText("x="+x,x+3,110,p);}
   for(int y=0;y<h;y+=100){p.setColor(Color.GRAY);c.drawLine(0,y,w,y,p);p.setColor(Color.WHITE);c.drawText("y="+y,8,y+25,p);}
   int[] markers={1338,1339,1919};int[] colors={Color.YELLOW,Color.RED,Color.CYAN};
   for(int i=0;i<markers.length;i++){p.setColor(colors[i]);c.drawLine(markers[i],0,markers[i],h,p);c.drawText("x="+markers[i],markers[i]-110,160+i*32,p);}
   p.setColor(Color.WHITE);c.drawText("RDX 0.1.0 GRID | Surface "+w+"x"+h+" | Physical "+real.widthPixels+"x"+real.heightPixels,12,30,p);
   c.drawText("density="+app.densityDpi+" x/y dpi="+app.xdpi+"/"+app.ydpi+" Hz="+getWindowManager().getDefaultDisplay().getRefreshRate(),12,58,p);
   c.drawText("View "+grid.getWidth()+"x"+grid.getHeight()+" Window "+window+" orientation="+getResources().getConfiguration().orientation,12,86,p);
  }finally{if(c!=null)holder.unlockCanvasAndPost(c);}
 }
}
