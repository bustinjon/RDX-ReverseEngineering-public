package com.rdx.fullscreen.projection;
import android.app.*;
import android.content.*;
import android.graphics.*;
import android.hardware.usb.*;
import android.media.*;
import android.os.*;
import android.util.Log;
import android.view.*;
import android.widget.*;
import java.util.concurrent.atomic.AtomicBoolean;

/** No boot/attach receiver, service, Honda API, property setter or system UID. */
public final class ReceiverActivity extends Activity implements TextureView.SurfaceTextureListener,ProjectionSession.Listener {
    private static final String TAG="RDX.ParallelAA",PERMISSION="com.rdx.fullscreen.projection.USB_PERMISSION";
    private final Handler main=new Handler();
    private final AtomicBoolean busy=new AtomicBoolean(false);
    private TextureView texture; private TextView log; private LinearLayout controls;
    private Surface surface; private ProjectionSession session;
    private int contentWidth=1920,contentHeight=720;
    private boolean receiverRegistered,foreground;
    private volatile boolean stopPending,exitPending;
    private final java.util.ArrayList<Surface> retiredSurfaces=new java.util.ArrayList<Surface>();
    private final java.util.ArrayList<SurfaceTexture> retiredTextures=new java.util.ArrayList<SurfaceTexture>();
    private final BroadcastReceiver permissionReceiver=new BroadcastReceiver(){public void onReceive(Context c,Intent intent){
        if(PERMISSION.equals(intent.getAction())) event("USB grant result="+intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED,false)+"; no automatic open/start");
    }};
    @Override public void onCreate(Bundle state) {
        super.onCreate(state); foreground=true;
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN,WindowManager.LayoutParams.FLAG_FULLSCREEN);
        getWindow().getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_FULLSCREEN|View.SYSTEM_UI_FLAG_HIDE_NAVIGATION|View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY);
        FrameLayout root=new FrameLayout(this);
        texture=new TextureView(this); texture.setSurfaceTextureListener(this); root.addView(texture,new FrameLayout.LayoutParams(-1,-1));
        controls=new LinearLayout(this); controls.setOrientation(LinearLayout.VERTICAL); controls.setBackgroundColor(0xDDFFFFFF);
        TextView title=new TextView(this); title.setText("RDX Parallel AA 0.1 — EXPERIMENTAL\nNo phone/native startup is automatic. Factory AA is not controlled."); controls.addView(title);
        LinearLayout row=new LinearLayout(this); controls.addView(row);
        button(row,"L1 inventory",new Runnable(){public void run(){inventory();}});
        button(row,"L1 TI allocate/release",new Runnable(){public void run(){probeDecoder();}});
        button(row,"L2 native only",new Runnable(){public void run(){initialize();}});
        button(row,"L3 USB grant",new Runnable(){public void run(){permission();}});
        LinearLayout second=new LinearLayout(this); controls.addView(second);
        button(second,"L3 start AOAP",new Runnable(){public void run(){startUsb();}});
        button(second,"Stop session",new Runnable(){public void run(){stop(false);}});
        button(second,"Hide overlay",new Runnable(){public void run(){controls.setVisibility(View.GONE);}});
        button(second,"Exit",new Runnable(){public void run(){stop(true);}});
        log=new TextView(this); log.setTextSize(11); controls.addView(log);
        FrameLayout.LayoutParams overlay=new FrameLayout.LayoutParams(-1,-2,Gravity.TOP); root.addView(controls,overlay);
        texture.setOnTouchListener(new View.OnTouchListener(){public boolean onTouch(View view,MotionEvent motion){
            if(motion.getAction()==MotionEvent.ACTION_DOWN) { controls.setVisibility(View.VISIBLE); event("MotionEvent source="+motion.getSource()+" x="+motion.getX()+" y="+motion.getY()+" (not sent to phone)"); }
            return true;
        }});
        texture.setOnHoverListener(new View.OnHoverListener(){public boolean onHover(View view,MotionEvent motion){
            event("Hover source="+motion.getSource()+" action="+motion.getAction()+" x="+motion.getX()+" y="+motion.getY()+" (not sent to phone)");return false;
        }});
        setContentView(root);
        registerReceiver(permissionReceiver,new IntentFilter(PERMISSION)); receiverRegistered=true;
        event("L1 Activity created uid="+android.os.Process.myUid()+" SDK="+Build.VERSION.SDK_INT+" ABI="+Build.CPU_ABI);
        event("Candidate A: active1920x720/229dpi/60fps. No overscan or privileged operations in this APK.");
    }
    private void button(LinearLayout row,String text,final Runnable action) {
        Button button=new Button(this); button.setText(text); button.setTextSize(10);
        row.addView(button,new LinearLayout.LayoutParams(0,-2,1)); button.setOnClickListener(new View.OnClickListener(){public void onClick(View view){action.run();}});
    }
    public void event(final String text) {
        Log.i(TAG,text);
        main.post(new Runnable(){public void run(){ if(log!=null) { String previous=log.getText().toString(); if(previous.length()>5500) previous=previous.substring(previous.length()-3500); log.setText(previous+"\n"+text); } }});
    }
    private void work(final Runnable action) {
        if(!busy.compareAndSet(false,true)) { event("Operation already in progress"); return; }
        new Thread(new Runnable(){public void run(){try{action.run();}catch(Throwable e){event("Operation failed: "+e);}finally{
            busy.set(false);
            if(stopPending) main.post(new Runnable(){public void run(){boolean exit=exitPending;stopPending=false;exitPending=false;stop(exit);}});
        }}},"RDX-manual-stage").start();
    }
    private UsbDevice phone() {
        UsbManager manager=(UsbManager)getSystemService(USB_SERVICE); UsbDevice selected=null;
        for(UsbDevice device:manager.getDeviceList().values()) if(UsbBulkTransport.isAllowedPhone(device)) {
            if(selected!=null) { event("Multiple AOAP phones: abort ambiguous selection"); return null; } selected=device;
        }
        if(selected==null) event("No allowed AOAP phone enumerated. This prototype never switches USB modes or opens hubs/TCU.");
        return selected;
    }
    private void inventory() {
        MediaCodecList codecs=new MediaCodecList(MediaCodecList.ALL_CODECS); boolean found=false;
        for(MediaCodecInfo codec:codecs.getCodecInfos()) if(codec.getName().equals("OMX.TI.DUCATI1.VIDEO.DECODER")) {
            found=true; event("TI decoder listed; encoder="+codec.isEncoder());
            try { MediaCodecInfo.VideoCapabilities caps=codec.getCapabilitiesForType("video/avc").getVideoCapabilities(); event("TI reports supports1920x1080@60="+caps.areSizeAndRateSupported(1920,1080,60)); } catch(Exception e){event("Capability query="+e);}
        }
        event("Decoder inventory only, TI found="+found+"; no codec allocated");
        UsbManager usb=(UsbManager)getSystemService(USB_SERVICE);
        for(UsbDevice device:usb.getDeviceList().values()) if(UsbBulkTransport.isAllowedPhone(device)) event("AOAP phone listed vid="+device.getVendorId()+" pid="+device.getProductId()+" interfaces="+device.getInterfaceCount()+" permission="+usb.hasPermission(device));
    }
    private void probeDecoder() { work(new Runnable(){public void run(){MediaCodec codec=null;try{codec=MediaCodec.createByCodecName("OMX.TI.DUCATI1.VIDEO.DECODER");event("L1 TI codec allocated; no configure/start/feed");}catch(Exception e){event("TI allocation failed: "+e);}finally{if(codec!=null)codec.release();}}}); }
    private void initialize() {
        if(surface==null||!surface.isValid()) { event("Wait for Surface"); return; }
        work(new Runnable(){public void run(){
            if(!foreground) { event("Not foreground; abort initialization"); return; }
            if(session!=null) { event("Stop existing session first"); return; }
            ProjectionSession next=new ProjectionSession(ReceiverActivity.this); session=next;
            try { int dpi=(int)((getResources().getDisplayMetrics().xdpi+getResources().getDisplayMetrics().ydpi)/2.0f); next.initialize(ReceiverActivity.this,surface,dpi); }
            catch(Throwable e) { event("L2 failed: "+e); next.stop(); session=null; }
        }});
    }
    private void permission() {
        UsbDevice device=phone(); if(device==null)return;
        UsbManager manager=(UsbManager)getSystemService(USB_SERVICE);
        if(manager.hasPermission(device)) { event("USB permission already granted; no open"); return; }
        manager.requestPermission(device,PendingIntent.getBroadcast(this,0,new Intent(PERMISSION).setPackage(getPackageName()),PendingIntent.FLAG_UPDATE_CURRENT));
        event("Requested ordinary USB permission; user grant required; no automatic start");
    }
    private void startUsb() {
        final UsbDevice device=phone(); if(device==null)return;
        final UsbManager manager=(UsbManager)getSystemService(USB_SERVICE);
        if(!manager.hasPermission(device)) { event("FIRST_BOUNDARY ordinary USB permission missing; request through L3 grant"); return; }
        work(new Runnable(){public void run(){try{if(session==null)throw new IllegalStateException("L2 session missing");session.startUsb(manager,device);}catch(Exception e){event("L3 stopped: "+e);if(session!=null){session.stop();session=null;}}}});
    }
    private void stop(final boolean exit) {
        if(busy.get()) { stopPending=true;exitPending=exitPending||exit;return; }
        work(new Runnable(){public void run(){
            boolean clean=true;
            if(session!=null) { clean=session.stop();session=null;if(!clean)event("Do not start another session; uninstall/stop only this test package"); }
            if(clean) main.post(new Runnable(){public void run(){
                for(Surface old:retiredSurfaces)old.release();retiredSurfaces.clear();
                for(SurfaceTexture old:retiredTextures)old.release();retiredTextures.clear();
            }});
            if(exit) main.post(new Runnable(){public void run(){finish();}});
        }});
    }
    public void geometry(final int width,final int height) {
        main.post(new Runnable(){public void run(){contentWidth=width;contentHeight=height;transform();}});
    }
    private void transform() {
        int w=texture.getWidth(),h=texture.getHeight(); if(w<1||h<1||contentHeight<1)return;
        float view=(float)w/h,content=(float)contentWidth/contentHeight,sx=1,sy=1;
        if(content>view) sy=view/content; else sx=content/view;
        Matrix matrix=new Matrix();matrix.setScale(sx,sy,w/2f,h/2f);texture.setTransform(matrix);
        event("GEOMETRY surface="+w+"x"+h+" content="+contentWidth+"x"+contentHeight+" fitScale="+sx+","+sy+" (no fixed Honda margins)");
    }
    public void onSurfaceTextureAvailable(SurfaceTexture target,int width,int height) {
        surface=new Surface(target); event("L1 Surface available="+width+"x"+height); transform();
        Canvas canvas=texture.lockCanvas(); if(canvas!=null) { canvas.drawColor(Color.rgb(10,35,55));Paint paint=new Paint();paint.setColor(Color.WHITE);paint.setTextSize(26);canvas.drawText("SYNTHETIC SURFACE — NOT PHONE VIDEO",30,height-40,paint);texture.unlockCanvasAndPost(canvas); }
        String requested=getIntent().getStringExtra("stage");
        if("inventory".equals(requested)) { event("Explicit launch requested inventory stage"); inventory(); }
        else if("native".equals(requested)) { event("Explicit launch requested native-only stage (no USB)"); initialize(); }
    }
    public void onSurfaceTextureSizeChanged(SurfaceTexture target,int width,int height) {event("Surface resize="+width+"x"+height);transform();}
    public boolean onSurfaceTextureDestroyed(SurfaceTexture target) {
        if(surface!=null){retiredSurfaces.add(surface);surface=null;}retiredTextures.add(target);
        stop(false);return false; // release only after decoder teardown, not while it owns the Surface.
    }
    public void onSurfaceTextureUpdated(SurfaceTexture target) { }
    @Override public boolean onGenericMotionEvent(MotionEvent motion) {event("GenericMotion source="+motion.getSource()+" action="+motion.getAction());return super.onGenericMotionEvent(motion);}
    @Override public boolean onKeyDown(int key,KeyEvent event) {if(key!=KeyEvent.KEYCODE_BACK)this.event("Key code="+key+" source="+event.getSource());return super.onKeyDown(key,event);}
    @Override public void onBackPressed() {stop(true);}
    @Override protected void onResume(){super.onResume();foreground=true;}
    @Override protected void onPause(){foreground=false;stop(false);super.onPause();}
    @Override protected void onDestroy(){if(receiverRegistered){unregisterReceiver(permissionReceiver);receiverRegistered=false;}super.onDestroy();}
}
