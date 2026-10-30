package com.rdx.fullscreen.projection;
import android.app.Activity;
import android.os.Bundle;
import android.os.Build;
import android.util.DisplayMetrics;
import android.util.Log;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Point;
import android.graphics.Rect;
import android.graphics.SurfaceTexture;
import android.view.Display;
import android.view.Gravity;
import android.view.Surface;
import android.view.TextureView;
import android.view.View;
import android.view.WindowManager;
import android.widget.Button;
import android.widget.FrameLayout;
import android.widget.TextView;
/** Synthetic-only revision. No native loader, JNI, GAL, USB, codec or OEM API. */
public final class ReceiverActivity extends Activity implements TextureView.SurfaceTextureListener {
  private static final String TAG="RDX.ParallelAA";
  private TextureView texture;
  private Surface surface;
  private boolean frameLogged;
  private void log(String value){Log.i(TAG,value);}
  public void onCreate(Bundle saved){
    super.onCreate(saved);
    getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN,WindowManager.LayoutParams.FLAG_FULLSCREEN);
    getWindow().getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_FULLSCREEN|View.SYSTEM_UI_FLAG_HIDE_NAVIGATION|View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY);
    FrameLayout root=new FrameLayout(this);
    texture=new TextureView(this);texture.setSurfaceTextureListener(this);root.addView(texture,new FrameLayout.LayoutParams(-1,-1));
    TextView text=new TextView(this);text.setText("RDX Parallel AA 0.1.1 — SYNTHETIC ONLY\nNo GAL / USB / decoder / native loading");text.setTextSize(20);text.setTextColor(Color.WHITE);text.setBackgroundColor(0xAA103040);
    root.addView(text,new FrameLayout.LayoutParams(-1,-2,Gravity.TOP));
    Button exit=new Button(this);exit.setText("EXIT SYNTHETIC TEST");exit.setOnClickListener(new View.OnClickListener(){public void onClick(View v){log("Exit button: finish only our Activity");finish();}});
    FrameLayout.LayoutParams button=new FrameLayout.LayoutParams(360,64,Gravity.TOP|Gravity.RIGHT);button.topMargin=72;root.addView(exit,button);
    setContentView(root);
    log("M1 onCreate uid="+android.os.Process.myUid()+" pid="+android.os.Process.myPid()+" SDK="+Build.VERSION.SDK_INT+" ABI="+Build.CPU_ABI+" version=0.1.1-live02-synthetic");
    log("ApplicationInfo nativeLibraryDir="+getApplicationInfo().nativeLibraryDir+" sourceDir="+getApplicationInfo().sourceDir);
    metrics("onCreate");
  }
  private String metricsString(DisplayMetrics m){return m.widthPixels+"x"+m.heightPixels+" densityDpi="+m.densityDpi+" density="+m.density+" scaledDensity="+m.scaledDensity+" xdpi="+m.xdpi+" ydpi="+m.ydpi;}
  private void metrics(String stage){
    Display d=getWindowManager().getDefaultDisplay();DisplayMetrics app=new DisplayMetrics(),real=new DisplayMetrics();d.getMetrics(app);d.getRealMetrics(real);
    Point size=new Point(),realSize=new Point();d.getSize(size);d.getRealSize(realSize);
    log("METRICS "+stage+" resources="+metricsString(getResources().getDisplayMetrics()));
    log("METRICS "+stage+" displayApp="+metricsString(app)+" displayReal="+metricsString(real));
    log("DISPLAY "+stage+" size="+size.x+"x"+size.y+" realSize="+realSize.x+"x"+realSize.y+" rotation="+d.getRotation()+" orientation="+getResources().getConfiguration().orientation+" refreshHz="+d.getRefreshRate());
    Rect bounds=new Rect();getWindow().getDecorView().getWindowVisibleDisplayFrame(bounds);
    log("WINDOW "+stage+" decor="+getWindow().getDecorView().getWidth()+"x"+getWindow().getDecorView().getHeight()+" visibleFrame="+bounds.toShortString());
  }
  public void onSurfaceTextureAvailable(SurfaceTexture t,int width,int height){
    surface=new Surface(t);log("M1 Surface available="+width+"x"+height+" valid="+surface.isValid());metrics("surfaceAvailable");
    Canvas c=texture.lockCanvas();
    if(c==null){log("M1 Canvas unavailable; no render success claimed");return;}
    c.drawColor(Color.rgb(10,35,55));Paint p=new Paint();p.setColor(Color.CYAN);p.setStrokeWidth(4);p.setStyle(Paint.Style.STROKE);c.drawRect(2,2,width-2,height-2,p);p.setStyle(Paint.Style.FILL);p.setTextSize(28);p.setColor(Color.WHITE);
    c.drawText("SYNTHETIC SURFACE — NOT PHONE VIDEO",30,height-80,p);c.drawText("Actual Surface "+width+" x "+height,30,height-35,p);
    texture.unlockCanvasAndPost(c);log("M1 synthetic Canvas posted");
  }
  public void onSurfaceTextureUpdated(SurfaceTexture t){if(!frameLogged){frameLogged=true;log("M1 synthetic texture update observed");}}
  public void onSurfaceTextureSizeChanged(SurfaceTexture t,int w,int h){log("M2 Surface resized="+w+"x"+h);metrics("surfaceResize");}
  public boolean onSurfaceTextureDestroyed(SurfaceTexture t){log("Surface destroyed");if(surface!=null){surface.release();surface=null;}return true;}
  public void onWindowFocusChanged(boolean focused){super.onWindowFocusChanged(focused);if(focused)metrics("windowFocus");}
  public void onBackPressed(){log("Back: finish only our Activity");super.onBackPressed();}
  protected void onResume(){super.onResume();log("Activity onResume");}
  protected void onPause(){log("Activity onPause");super.onPause();}
  protected void onDestroy(){log("Activity onDestroy");super.onDestroy();}
}
