package org.rdxresearch.diagnostics;

import android.app.Activity;
import android.os.Bundle;
import android.os.Handler;
import android.os.SystemClock;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.media.AudioManager;
import android.media.ToneGenerator;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.view.KeyEvent;
import android.view.MotionEvent;
import android.view.View;
import android.view.WindowManager;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import java.util.ArrayDeque;

/** Standalone foreground diagnostics. No USB/native/protocol/network/storage access. */
public final class DiagnosticActivity extends Activity {
    private final Handler handler = new Handler();
    private final ArrayDeque<String> events = new ArrayDeque<String>();
    private long started;
    private TextView status;
    private LinearLayout root;
    private PatternView pattern;
    private View content;
    private AudioManager audio;
    private ToneGenerator tone;
    private boolean focusHeld;
    private final AudioManager.OnAudioFocusChangeListener focus = new AudioManager.OnAudioFocusChangeListener() {
        public void onAudioFocusChange(int change) {
            record("audio focus change=" + change);
            if(change < 0) stopTone();
        }
    };
    private final Runnable releaseTone = new Runnable() { public void run() { stopTone(); } };

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        started=SystemClock.elapsedRealtime();
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN,WindowManager.LayoutParams.FLAG_FULLSCREEN);
        audio=(AudioManager)getSystemService(Context.AUDIO_SERVICE);
        root=new LinearLayout(this);root.setOrientation(LinearLayout.VERTICAL);root.setBackgroundColor(Color.rgb(16,20,26));
        TextView title=new TextView(this);title.setText("Head Unit Diagnostics 0.1.0 — local tests; no Android Auto session");title.setTextColor(Color.WHITE);title.setTextSize(17);root.addView(title);
        LinearLayout buttons=new LinearLayout(this);
        button(buttons,"Pattern / Input",new Runnable(){public void run(){showPattern();}});
        button(buttons,"350 ms tone",new Runnable(){public void run(){playTone();}});
        button(buttons,"Report",new Runnable(){public void run(){showReport();}});
        button(buttons,"Copy report",new Runnable(){public void run(){
            ((ClipboardManager)getSystemService(Context.CLIPBOARD_SERVICE)).setPrimaryClip(ClipData.newPlainText("Head unit diagnostics",report()));
            record("report copied on user request");
        }});
        button(buttons,"Exit",new Runnable(){public void run(){finish();}});
        root.addView(buttons);
        status=new TextView(this);status.setTextColor(Color.YELLOW);status.setTextSize(14);root.addView(status);
        setContentView(root);
        record("API="+android.os.Build.VERSION.SDK_INT+" density="+getResources().getDisplayMetrics().density);
        showPattern();
        handler.postDelayed(new Runnable(){public void run(){finish();}},120000);
    }

    private void button(LinearLayout parent,String label,final Runnable action) {
        Button button=new Button(this);button.setText(label);button.setTextSize(12);
        button.setOnClickListener(new View.OnClickListener(){public void onClick(View view){action.run();}});
        parent.addView(button,new LinearLayout.LayoutParams(0,LinearLayout.LayoutParams.WRAP_CONTENT,1));
    }
    private void replaceContent(View next) {
        if(content!=null)root.removeView(content);
        content=next;root.addView(next,new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT,0,1));
    }
    private void showPattern() {
        if(pattern==null)pattern=new PatternView();
        replaceContent(pattern);pattern.requestFocus();
        record("pattern/input active; touchpad may report hover, touch, or keys");
    }
    private void showReport() {
        TextView text=new TextView(this);text.setTextColor(Color.WHITE);text.setTextSize(14);text.setText(report());text.setTextIsSelectable(true);
        ScrollView scroll=new ScrollView(this);scroll.addView(text);replaceContent(scroll);
    }
    private void record(String text) {
        if(events.size()>=120)events.removeFirst();
        events.addLast((SystemClock.elapsedRealtime()-started)+"ms "+text);
        if(status!=null)status.setText(text+"  | exits automatically after 120 seconds");
    }
    private String report() {
        StringBuilder b=new StringBuilder("Head Unit Diagnostics 0.1.0\nNo serial, VIN, account, Bluetooth address or device fingerprint collected.\n");
        b.append("API=").append(android.os.Build.VERSION.SDK_INT).append(" density=").append(getResources().getDisplayMetrics().density).append('\n');
        if(pattern!=null)b.append("Pattern view=").append(pattern.getWidth()).append('x').append(pattern.getHeight()).append(" px (excludes controls)\n");
        b.append("Tone success means API accepted the request, not proof of audible routing.\n");
        for(String e:events)b.append(e).append('\n');
        return b.toString();
    }
    @Override public boolean dispatchKeyEvent(KeyEvent event) {
        if(event.getAction()==KeyEvent.ACTION_DOWN || event.getAction()==KeyEvent.ACTION_UP)
            record("key code="+event.getKeyCode()+" scan="+event.getScanCode()+" action="+event.getAction());
        // Preserve ordinary Back, navigation, volume and accessibility behavior.
        return super.dispatchKeyEvent(event);
    }
    private void playTone() {
        stopTone();
        try {
            focusHeld=audio.requestAudioFocus(focus,AudioManager.STREAM_MUSIC,AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)==AudioManager.AUDIOFOCUS_REQUEST_GRANTED;
            record("tone focus granted="+focusHeld);
            if(!focusHeld)return;
            tone=new ToneGenerator(AudioManager.STREAM_MUSIC,15);
            boolean accepted=tone.startTone(ToneGenerator.TONE_PROP_BEEP,350);
            record("local tone requested accepted="+accepted+"; user must report audibility");
            handler.postDelayed(releaseTone,500);
        } catch(RuntimeException error) {record("tone error="+error.getClass().getSimpleName());stopTone();}
    }
    private void stopTone() {
        handler.removeCallbacks(releaseTone);
        if(tone!=null){tone.stopTone();tone.release();tone=null;}
        if(focusHeld){focusHeld=false;audio.abandonAudioFocus(focus);}
    }
    @Override public void onPause(){stopTone();super.onPause();}
    @Override public void onDestroy(){handler.removeCallbacksAndMessages(null);stopTone();super.onDestroy();}

    private final class PatternView extends View {
        private final Paint paint=new Paint(Paint.ANTI_ALIAS_FLAG);
        private float lastX=-1,lastY=-1;
        PatternView(){super(DiagnosticActivity.this);setFocusable(true);setFocusableInTouchMode(true);}
        @Override protected void onSizeChanged(int w,int h,int oldW,int oldH){record("pattern view="+w+"x"+h+" px");}
        @Override protected void onDraw(Canvas canvas){
            int w=getWidth(),h=getHeight();canvas.drawColor(Color.rgb(12,18,26));
            paint.setColor(Color.rgb(55,80,100));paint.setStrokeWidth(1);
            for(int i=1;i<8;i++){canvas.drawLine(i*w/8f,0,i*w/8f,h,paint);canvas.drawLine(0,i*h/8f,w,i*h/8f,paint);}
            paint.setStyle(Paint.Style.STROKE);paint.setStrokeWidth(4);paint.setColor(Color.CYAN);
            canvas.drawRect(2,2,Math.max(2,w-2),Math.max(2,h-2),paint);
            canvas.drawCircle(w/2f,h/2f,Math.min(w,h)/4f,paint);
            paint.setStyle(Paint.Style.FILL);paint.setTextSize(22);canvas.drawText("Circle should look round. Border should be visible.",16,32,paint);
            canvas.drawText("Move, press, release, then open Report.",16,62,paint);
            if(lastX>=0){paint.setColor(Color.YELLOW);canvas.drawCircle(lastX,lastY,10,paint);}
        }
        private boolean motion(MotionEvent event,String kind){
            lastX=event.getX();lastY=event.getY();
            record(kind+" action="+event.getActionMasked()+" xy="+(int)lastX+","+(int)lastY+" pointers="+event.getPointerCount()+" buttons="+event.getButtonState());
            invalidate();return true;
        }
        @Override public boolean onTouchEvent(MotionEvent event){return motion(event,"touch");}
        @Override public boolean onHoverEvent(MotionEvent event){return motion(event,"hover");}
        @Override public boolean onGenericMotionEvent(MotionEvent event){return motion(event,"generic");}
    }
}
