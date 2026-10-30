package com.rdx.fullscreen.decodertest;
import android.app.Activity;
import android.os.*;
import android.view.*;
import android.widget.*;
import android.util.Log;

public final class DecoderTestActivity extends Activity {
 private DecodeWorker worker;private SurfaceView surface;private TextView status;private Spinner clips;
 private final Handler handler=new Handler();private boolean failed,destroyed;private int pending=-1,expectedW,expectedH;
 private final Runnable watchdog=new Runnable(){public void run(){if(worker!=null&&worker.isAlive()){failed=true;worker.cancel();status.setText("STOP: worker exceeded 25 seconds. Do not restart media services.");Log.e("RDX.DECODER","WATCHDOG; process may be blocked in media Binder call; stop further tests");}}};
 @Override public void onCreate(Bundle b){super.onCreate(b);
  getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN,WindowManager.LayoutParams.FLAG_FULLSCREEN);
  LinearLayout root=new LinearLayout(this);root.setOrientation(LinearLayout.VERTICAL);
  LinearLayout controls=new LinearLayout(this);clips=new Spinner(this);clips.setAdapter(new ArrayAdapter<String>(this,android.R.layout.simple_spinner_dropdown_item,ClipCatalog.FILES));controls.addView(clips,new LinearLayout.LayoutParams(0,65,1));
  Button start=new Button(this);start.setText("START ONE CLIP");controls.addView(start);Button stop=new Button(this);stop.setText("STOP");controls.addView(stop);Button exit=new Button(this);exit.setText("EXIT");controls.addView(exit);root.addView(controls);
  status=new TextView(this);status.setText("EXPERIMENTAL 0.1.0 | No decoder allocated. Select a packaged clip and press START.");root.addView(status);
  final FrameLayout frame=new FrameLayout(this);surface=new SurfaceView(this);frame.addView(surface,new FrameLayout.LayoutParams(-1,-1,Gravity.CENTER));root.addView(frame,new LinearLayout.LayoutParams(-1,0,1));setContentView(root);
  surface.getHolder().addCallback(new SurfaceHolder.Callback(){public void surfaceCreated(SurfaceHolder h){} public void surfaceChanged(SurfaceHolder h,int f,int w,int height){Log.i("RDX.DECODER","Surface="+w+"x"+height);startPending();}public void surfaceDestroyed(SurfaceHolder h){if(worker!=null)worker.cancel();}});
  start.setOnClickListener(new View.OnClickListener(){public void onClick(View v){
   if(failed){status.setText("STOP: previous failure requires review; no further allocation in this Activity.");return;}
   if(pending>=0||(worker!=null&&worker.isAlive())){status.setText("Worker/start still active; no second decoder permitted.");return;}
   if(!surface.getHolder().getSurface().isValid()){status.setText("Surface unavailable");return;}
   final int index=clips.getSelectedItemPosition();int w=frame.getWidth(),h=frame.getHeight();float scale=Math.min((float)w/ClipCatalog.WIDTH[index],(float)h/ClipCatalog.HEIGHT[index]);
   if(w<=0||h<=0){status.setText("Layout unavailable");return;}
   expectedW=(int)(ClipCatalog.WIDTH[index]*scale);expectedH=(int)(ClipCatalog.HEIGHT[index]*scale);pending=index;
   surface.setLayoutParams(new FrameLayout.LayoutParams(expectedW,expectedH,Gravity.CENTER));
   status.setText("Waiting for Surface layout: "+ClipCatalog.FILES[index]);
   surface.post(new Runnable(){public void run(){startPending();}});
  }});
  stop.setOnClickListener(new View.OnClickListener(){public void onClick(View v){cancel();}});exit.setOnClickListener(new View.OnClickListener(){public void onClick(View v){cancel();finish();}});
 }
 private void startPending(){
  if(destroyed||pending<0||!surface.getHolder().getSurface().isValid())return;
  if(surface.getHolder().getSurfaceFrame().width()!=expectedW||surface.getHolder().getSurfaceFrame().height()!=expectedH)return;
  final int index=pending;pending=-1;status.setText("Running "+ClipCatalog.FILES[index]);
  worker=new DecodeWorker(getAssets(),ClipCatalog.FILES[index],surface.getHolder().getSurface(),new DecodeWorker.Listener(){public void completed(final String s){handler.post(new Runnable(){public void run(){if(destroyed)return;handler.removeCallbacks(watchdog);if(s.startsWith("ERROR")||s.startsWith("TIMEOUT")||s.startsWith("CLEANUP_ERROR"))failed=true;status.setText(s);}});}});
  worker.start();handler.postDelayed(watchdog,25000);
 }
 private void cancel(){pending=-1;if(worker!=null)worker.cancel();}
 @Override protected void onPause(){cancel();super.onPause();}
 @Override protected void onDestroy(){destroyed=true;cancel();handler.removeCallbacksAndMessages(null);super.onDestroy();}
}
