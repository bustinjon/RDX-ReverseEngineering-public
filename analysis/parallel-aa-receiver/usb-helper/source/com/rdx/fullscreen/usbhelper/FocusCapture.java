package com.rdx.fullscreen.usbhelper;

import android.content.Context;
import android.graphics.Bitmap;
import android.os.Handler;
import android.os.SystemClock;
import android.util.Log;
import android.view.TextureView;
import java.io.File;
import java.io.FileOutputStream;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.atomic.AtomicBoolean;

/** Opt-in TextureView sampling only; never captures another app/window or uploads data. */
final class FocusCapture {
    private static final String TAG="RDX.FOCUSCAP";
    private final Handler handler;
    private final File directory;
    private final ExecutorService writer=Executors.newSingleThreadExecutor();
    private final AtomicBoolean busy=new AtomicBoolean(false);
    private FocusCaptureBudget budget;
    private volatile boolean closed;
    private boolean started;
    private long keyOrdinal;
    private String lastKey="none";
    private Runnable tick;

    FocusCapture(Context context,Handler handler){
        this.handler=handler;
        File root=context.getExternalFilesDir("focus-captures");
        if(root==null)throw new IllegalStateException("App-specific external storage unavailable");
        directory=new File(root,"session_"+SystemClock.elapsedRealtime());
        if(!directory.mkdirs())throw new IllegalStateException("Capture directory unavailable");
        Log.i(TAG,"FOCUS_CAPTURE_SESSION dir="+directory.getAbsolutePath()+" max=12 intervalMs=10000 bitmap=960x360");
    }
    void key(int raw,int mapped,boolean down){
        keyOrdinal++;lastKey="ordinal="+keyOrdinal+" raw="+raw+" mapped="+mapped+" down="+down;
    }
    void firstTextureUpdate(final TextureView view){
        if(started || closed)return;
        started=true;budget=new FocusCaptureBudget(SystemClock.elapsedRealtime());
        tick=new Runnable(){public void run(){
            if(closed || budget.finished(SystemClock.elapsedRealtime()))return;
            sample(view);
            if(!closed && !budget.finished(SystemClock.elapsedRealtime()))handler.postDelayed(this,FocusCaptureBudget.INTERVAL_MS);
        }};
        handler.post(tick);
    }
    private void sample(TextureView view){
        if(!view.isAvailable() || !view.isShown() || !busy.compareAndSet(false,true))return;
        final long when=SystemClock.elapsedRealtime();
        final int number=budget.reserve(when);
        if(number<0){busy.set(false);return;}
        Bitmap image=null;
        try{
            long before=SystemClock.elapsedRealtime();
            image=view.getBitmap(960,360);
            if(image==null)throw new IllegalStateException("TextureView returned no bitmap");
            final Bitmap snapshot=image;
            final String key=lastKey;
            final File file=new File(directory,"frame_"+number+"_"+when+".png");
            final long readbackMs=SystemClock.elapsedRealtime()-before;
            writer.execute(new Runnable(){public void run(){
                try{
                    if(closed)return;
                    FileOutputStream output=new FileOutputStream(file);
                    try{if(!snapshot.compress(Bitmap.CompressFormat.PNG,100,output))throw new IllegalStateException("PNG encoding rejected");}
                    finally{output.close();}
                    Log.i(TAG,"FOCUS_CAPTURE_SAVED index="+number+" uptimeMs="+when+" "+key+" readbackMs="+readbackMs+" bytes="+file.length()+" file="+file.getName());
                }catch(Exception error){Log.w(TAG,"FOCUS_CAPTURE_WRITE_FAILED type="+error.getClass().getSimpleName());}
                finally{snapshot.recycle();busy.set(false);}
            }});
        }catch(RuntimeException error){
            if(image!=null)image.recycle();busy.set(false);
            Log.w(TAG,"FOCUS_CAPTURE_READ_FAILED type="+error.getClass().getSimpleName());
        }catch(OutOfMemoryError error){
            if(image!=null)image.recycle();busy.set(false);close();Log.w(TAG,"FOCUS_CAPTURE_DISABLED memory");
        }
    }
    void close(){
        closed=true;if(budget!=null)budget.close();if(tick!=null)handler.removeCallbacks(tick);writer.shutdown();
        Log.i(TAG,"FOCUS_CAPTURE_CLOSED");
    }
}
