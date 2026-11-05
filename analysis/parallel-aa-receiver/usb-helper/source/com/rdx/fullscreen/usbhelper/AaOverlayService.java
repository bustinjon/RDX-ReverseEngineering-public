package com.rdx.fullscreen.usbhelper;

import android.app.Service;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.IntentFilter;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Matrix;
import android.graphics.Paint;
import android.graphics.PixelFormat;
import android.graphics.SurfaceTexture;
import android.os.Handler;
import android.os.IBinder;
import android.os.SystemClock;
import android.util.Log;
import android.view.Gravity;
import android.view.KeyEvent;
import android.view.MotionEvent;
import android.view.Surface;
import android.view.TextureView;
import android.view.View;
import android.view.ViewGroup;
import android.view.WindowManager;
import android.widget.FrameLayout;
import android.widget.TextView;
import android.widget.TextView;

/**
 * Fullscreen AA overlay using TYPE_SYSTEM_ERROR.
 *
 * Creates a 1920x720 overlay covering the entire physical framebuffer.
 * Contains a TextureView whose Surface is reserved for MediaCodec video
 * output — never locked for Canvas drawing (F8 fix). Test-mode diagnostics
 * render to a sibling View on top.
 *
 * Touch input from the car's touchpad (0-1325 x 0-720) is scaled to the
 * AA video coordinate space. The AA protocol negotiates 1920x1080 nominal
 * with 360px height margin, producing 1920x720 active video area.
 *
 * Actions:
 *   aa.overlay.START  — show overlay with test pattern (60s auto-dismiss)
 *   aa.overlay.VIDEO  — show overlay without test pattern (for live video)
 *   aa.overlay.STOP   — remove overlay and stop service
 */
public final class AaOverlayService extends Service {
    private static final String TAG = "RDX.AAOVERLAY";

    private static final int OVERLAY_W = 1920;
    private static final int OVERLAY_H = 720;

    // Touchpad range measured on car 2026-10-27 (6 DOWN samples, x max=1324)
    // InputConfig.hondaReference() uses 1325x720
    private static final float TOUCHPAD_X_MAX = 1325f;
    private static final float TOUCHPAD_Y_MAX = 720f;

    // Active video area after margin removal.
    // Protocol sends 1920x1080 nominal (VideoConfig.fullscreenExperiment)
    // with 360px height margin → 1920x720 active content.
    private static final int VIDEO_W = 1920;
    private static final int VIDEO_H = 720;

    private static final long TEST_DISMISS_MS = 60000;

    private WindowManager wm;
    private FrameLayout container;
    private TextureView textureView;
    private View diagnosticView;
    private Handler handler;
    private Surface videoSurface;
    private boolean testMode;
    private boolean surfaceReady;
    // Accessed only on the service/UI thread. Producer callbacks post changes here.
    private VideoGeometry videoGeometry;
    private VideoGeometry.Projection projection;
    private int decodedWidth, decodedHeight;
    private boolean destroyed;
    private boolean captureNextSession;
    private boolean bZoneNextSession;
    private FocusCapture focusCapture;

    private static volatile AaOverlayService instance;

    private int touchCount;
    private int ignoredHoverCount;
    private final InputEvents.SelectPress selectPress = new InputEvents.SelectPress();
    private final VolumeFeedback volumeFeedback = new VolumeFeedback();
    private TextView volumeHud;
    private boolean volumeReceiverRegistered;
    private final Runnable hideVolumeHud = new Runnable() {
        public void run() { if(volumeHud!=null)volumeHud.setVisibility(View.GONE); }
    };
    private final BroadcastReceiver volumeReceiver = new BroadcastReceiver() {
        @Override public void onReceive(Context context,Intent intent) {
            if(intent==null || !VolumeFeedback.ACTION.equals(intent.getAction()) || destroyed || container==null)return;
            try {
                if(!intent.hasExtra(VolumeFeedback.EXTRA))return;
                int received=intent.getIntExtra(VolumeFeedback.EXTRA,-1);
                boolean changed=volumeFeedback.update(received);
                Log.i(TAG,"VOLUME_FEEDBACK_RECEIVED level="+received+" changed="+changed);
                if(changed)showVolumeFeedback();
            }catch(RuntimeException error){
                Log.w(TAG,"VOLUME_FEEDBACK_REJECTED type="+error.getClass().getSimpleName());
            }
        }
    };
    private final InputEvents.MediaButtons mediaButtons = new InputEvents.MediaButtons();
    // T22: Home minimizes; the window and its video surface stay alive while hidden.
    private final HomeToggle homeToggle = new HomeToggle();
    private final HomeToggle.BackHold backHold = new HomeToggle.BackHold();
    private WindowManager.LayoutParams overlayParams;
    private TextView restoreButton;
    /** Called by PermissionClickService when it observes a side-panel (Guide) button release. */
    static void onObservedSidePanel() {
        final AaOverlayService s = instance;
        if (s == null) return;
        s.handler.post(new Runnable() { public void run() {
            if (s.container == null || s.testMode) return;
            int decision = s.homeToggle.onSidePanel();
            Log.i(TAG, "SIDE_PANEL_KEY decision=" + decision);
            if (decision == HomeToggle.RESTORE) s.restoreOverlay("side-panel");
        }});
    }

    /** Called by PermissionClickService (same process) when it observes a Home key release. */
    static void onObservedHome() {
        final AaOverlayService s = instance;
        if (s == null) return;
        s.handler.post(new Runnable() { public void run() {
            if (s.container == null || s.testMode) return;
            int decision = s.homeToggle.onHome(SystemClock.uptimeMillis());
            Log.i(TAG, "HOME_KEY decision=" + decision + " minimized=" + s.homeToggle.minimized());
            if (decision == HomeToggle.MINIMIZE) s.minimizeOverlay();

        }});
    }
    private float lastTouchAaX = -1, lastTouchAaY = -1;
    private TouchListener touchListener;
    private SurfaceReadyListener surfaceReadyListener;

    public static AaOverlayService getInstance() { return instance; }

    public interface TouchListener {
        void onAaKey(int code, boolean down, long timestampMs);
        void onAaTouch(int action, float rawX, float rawY,
                       float aaX, float aaY, long timestampMs);
    }

    public interface SurfaceReadyListener {
        void onSurfaceReady(Surface surface, int width, int height);
        void onSurfaceLost();
    }

    @Override
    public void onCreate() {
        super.onCreate();
        wm = (WindowManager) getSystemService(WINDOW_SERVICE);
        handler = new Handler();
        instance = this;
        Log.i(TAG, "AaOverlayService created");
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        String action = intent != null ? intent.getAction() : null;
        Log.i(TAG, "onStartCommand action=" + action);

        if("aa.overlay.BZONE_ARM_ONCE".equals(action)){
            if(container!=null){Log.w(TAG,"BZONE_ARM_REJECTED activeOverlay");return START_NOT_STICKY;}
            bZoneNextSession=true;
            Log.i(TAG,"BZONE_ARMED_ONCE source=257 scans=36,37 releasePairs=true");
            return START_NOT_STICKY;
        }

        if("aa.overlay.CAPTURE_ARM_ONCE".equals(action)){
            if(container!=null){Log.w(TAG,"FOCUS_CAPTURE_ARM_REJECTED activeOverlay");return START_NOT_STICKY;}
            captureNextSession=true;
            Log.i(TAG,"FOCUS_CAPTURE_ARMED_ONCE max=12 noUpload=true");
            return START_NOT_STICKY;
        }

        if ("aa.overlay.STOP".equals(action)) {
            removeOverlay();
            stopSelf();
            return START_NOT_STICKY;
        }

        if ("aa.overlay.START".equals(action)) {
            testMode = true;
            removeOverlay();
            createOverlay();
            return START_NOT_STICKY;
        }

        if ("aa.overlay.VIDEO".equals(action)) {
            testMode = false;
            removeOverlay();
            if(captureNextSession){
                captureNextSession=false;
                try{focusCapture=new FocusCapture(this,handler);}
                catch(RuntimeException error){Log.w(TAG,"FOCUS_CAPTURE_UNAVAILABLE type="+error.getClass().getSimpleName());}
            }
            createOverlay();
            return START_NOT_STICKY;
        }

        return START_NOT_STICKY;
    }

    private void createOverlay() {
        Log.i(TAG, "Creating AA overlay " + OVERLAY_W + "x" + OVERLAY_H
            + " video=" + VIDEO_W + "x" + VIDEO_H + " testMode=" + testMode);

        final InputEvents.HoverContact hoverContact = new InputEvents.HoverContact();
        final boolean bZoneEnabled = !testMode && bZoneNextSession;
        if(!testMode)bZoneNextSession=false;
        final InputEvents.BZoneSwipe bZoneSwipe = new InputEvents.BZoneSwipe();
        container = new FrameLayout(this) {
            private boolean bZoneDeviceLogged;
            @Override public boolean dispatchKeyEvent(final KeyEvent event) {
                if (!testMode && event.getAction()==KeyEvent.ACTION_DOWN) Log.i(TAG,"INPUT_RAW_KEY code="+event.getKeyCode()+" scan="+event.getScanCode()+" flags="+event.getFlags()+" repeat="+event.getRepeatCount()+" source="+event.getSource()+" device="+event.getDeviceId());
                if(!testMode && (event.getKeyCode()==87 || event.getKeyCode()==88 || event.getKeyCode()==138 || event.getKeyCode()==139))
                    Log.i(TAG,"INPUT_MEDIA_RAW code="+event.getKeyCode()+" scan="+event.getScanCode()+" action="+event.getAction()+" repeat="+event.getRepeatCount()+" source="+event.getSource()+" device="+event.getDeviceId()+" canceled="+event.isCanceled()+" heldMs="+(event.getEventTime()-event.getDownTime()));
                if(!testMode && touchListener!=null){
                    int media=mediaButtons.dispatch(
                            event.getKeyCode(),event.getScanCode(),event.getSource(),event.getDeviceId(),
                            event.getAction(),event.getRepeatCount(),event.isCanceled(),
                            event.getAction()==KeyEvent.ACTION_UP?event.getEventTime()-event.getDownTime():0,
                            new InputEvents.KeyConsumer(){
                        public void send(final int mappedCode,boolean down){
                            Log.i(TAG,"INPUT_MEDIA_KEY raw="+event.getKeyCode()+" mapped="+mappedCode+" down="+down);
                            if(down){touchListener.onAaKey(mappedCode,true,event.getEventTime());return;}
                            // Stock sends the release 100 ms after the press.
                            handler.postDelayed(new Runnable(){public void run(){
                                if(touchListener!=null)touchListener.onAaKey(mappedCode,false,android.os.SystemClock.uptimeMillis());
                            }},100);
                        }
                    });
                    if(media==0 && event.getAction()==KeyEvent.ACTION_UP)Log.i(TAG,"INPUT_MEDIA_NOT_SENT raw="+event.getKeyCode()+" heldMs="+(event.getEventTime()-event.getDownTime()));
                    if(media>=0)return true;
                }
                if(!testMode && (event.getKeyCode()==38 || event.getKeyCode()==39)){
                    if(!bZoneDeviceLogged){
                        bZoneDeviceLogged=true;
                        android.view.InputDevice inputDevice=event.getDevice();
                        Log.i(TAG,"INPUT_BZONE_DEVICE "+(inputDevice==null?"unavailable":
                            "name="+inputDevice.getName()+" descriptor="+inputDevice.getDescriptor()+" vendor="+inputDevice.getVendorId()+" product="+inputDevice.getProductId()));
                    }
                    Log.i(TAG,"INPUT_BZONE_RAW code="+event.getKeyCode()+" scan="+event.getScanCode()+" action="+event.getAction()+" repeat="+event.getRepeatCount()+" source="+event.getSource()+" device="+event.getDeviceId()+" enabled="+bZoneEnabled);
                    if(bZoneEnabled && touchListener!=null && bZoneSwipe.dispatch(
                            event.getKeyCode(),event.getScanCode(),event.getSource(),event.getDeviceId(),
                            event.getAction(),event.getRepeatCount(),new InputEvents.KeyConsumer(){
                        public void send(int mappedCode,boolean down){
                            Log.i(TAG,"INPUT_BZONE_KEY raw="+event.getKeyCode()+" mapped="+mappedCode+" down="+down);
                            if(focusCapture!=null)focusCapture.key(event.getKeyCode(),mappedCode,down);
                            touchListener.onAaKey(mappedCode,down,event.getEventTime());
                        }
                    }))return true;
                }
                if (!testMode && touchListener != null && event.getKeyCode()==KeyEvent.KEYCODE_BACK) {
                    // Honda consumes Home while this window has focus, so a long Back is the way out.
                    int back=backHold.onKey(event.getAction(),event.getRepeatCount(),event.isCanceled(),event.getEventTime()-event.getDownTime());
                    if(back==HomeToggle.BackHold.SHORT){
                        Log.i(TAG,"INPUT_KEY code=4 mapped=4 shortBackPair");
                        touchListener.onAaKey(4,true,event.getEventTime());
                        touchListener.onAaKey(4,false,event.getEventTime());
                    }else if(back==HomeToggle.BackHold.MINIMIZE){
                        Log.i(TAG,"BACK_LONG_PRESS minimize");
                        homeToggle.minimizedByBack();
                        minimizeOverlay();
                    }
                    return true;
                }
                if (!testMode && touchListener != null) {
                    boolean consumed=InputEvents.dispatchKey(event.getKeyCode(),event.getAction(),new InputEvents.KeyConsumer(){
                        public void send(int mappedCode,boolean down){
                            Log.i(TAG,"INPUT_KEY code="+event.getKeyCode()+" mapped="+mappedCode+" action="+event.getAction());
                            if(focusCapture!=null)focusCapture.key(event.getKeyCode(),mappedCode,down);
                            touchListener.onAaKey(mappedCode,down,event.getEventTime());
                        }
                    });
                    if(consumed)return true;
                }
                return super.dispatchKeyEvent(event);
            }
            @Override public boolean dispatchHoverEvent(MotionEvent event) {
                int action=InputEvents.hoverAction(event.getActionMasked());
                if (!testMode && touchListener != null && action>=0) {
                    action=hoverContact.action(event.getActionMasked());
                    if(action<0){
                        Log.i(TAG,"INPUT_HOVER_DUPLICATE_ENTER_DROPPED");
                        return true;
                    }
                    MotionEvent mapped=MotionEvent.obtain(event);
                    try { mapped.setAction(action); return handleTouch(mapped); }
                    finally { mapped.recycle(); }
                }
                return super.dispatchHoverEvent(event);
            }
        };
        if(!testMode){
            Log.i(TAG,"INPUT_HOVER_DEDUP_V1 hoverForwarded=true directionalKeysUnchanged=true");
            Log.i(TAG,"INPUT_BZONE_RELEASE_V1 enabled="+bZoneEnabled+" primaryKeysUnchanged=true");
        }
        container.setFocusable(!testMode);
        container.setFocusableInTouchMode(!testMode);
        container.setDescendantFocusability(ViewGroup.FOCUS_BLOCK_DESCENDANTS);
        container.setOnFocusChangeListener(new View.OnFocusChangeListener() {
            public void onFocusChange(View view,boolean focused) { Log.i(TAG,"INPUT_FOCUS="+focused); }
        });
        container.setBackgroundColor(Color.BLACK);
        container.setClipChildren(true);

        // TextureView — reserved for MediaCodec, never locked for Canvas
        textureView = new TextureView(this);
        textureView.setOpaque(false);
        textureView.setSurfaceTextureListener(new TextureView.SurfaceTextureListener() {
            @Override
            public void onSurfaceTextureAvailable(SurfaceTexture st, int width, int height) {
                Log.i(TAG, "TextureView surface available: " + width + "x" + height);
                applyVideoTransform();
                videoSurface = new Surface(st);
                surfaceReady = true;
                if (surfaceReadyListener != null) {
                    surfaceReadyListener.onSurfaceReady(videoSurface, width, height);
                }
            }

            @Override
            public void onSurfaceTextureSizeChanged(SurfaceTexture st, int width, int height) {
                Log.i(TAG, "TextureView surface resized: " + width + "x" + height);
                applyVideoTransform();
            }

            @Override
            public boolean onSurfaceTextureDestroyed(SurfaceTexture st) {
                Log.i(TAG, "TextureView surface destroyed — keeping SurfaceTexture for decoder drain");
                surfaceReady = false;
                if (surfaceReadyListener != null) {
                    surfaceReadyListener.onSurfaceLost();
                }
                videoSurface = null;
                return false;
            }

            @Override
            public void onSurfaceTextureUpdated(SurfaceTexture st) { if(focusCapture!=null)focusCapture.firstTextureUpdate(textureView); }
        });

        container.addView(textureView, new FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT));

        // Diagnostic overlay view — drawn ON TOP of TextureView, doesn't touch its Surface
        if (testMode) {
            diagnosticView = new View(this) {
                @Override
                protected void onDraw(Canvas canvas) {
                    drawTestPatternToCanvas(canvas);
                    if (lastTouchAaX >= 0) {
                        Paint dot = new Paint(Paint.ANTI_ALIAS_FLAG);
                        dot.setColor(Color.CYAN);
                        canvas.drawCircle(lastTouchAaX, lastTouchAaY, 15, dot);
                        Paint label = new Paint(Paint.ANTI_ALIAS_FLAG);
                        label.setColor(Color.CYAN);
                        label.setTextSize(16);
                        canvas.drawText("(" + (int) lastTouchAaX + "," + (int) lastTouchAaY + ")",
                            lastTouchAaX + 20, lastTouchAaY - 5, label);
                    }
                }
            };
            container.addView(diagnosticView, new FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT));
        }

        container.setOnTouchListener(new View.OnTouchListener() {
            @Override
            public boolean onTouch(View v, MotionEvent event) {
                if(testMode)return handleTouch(event);
                int action=event.getActionMasked();
                Log.i(TAG,"INPUT_PAD_PRESS action="+action+" pointers="+event.getPointerCount()+" buttons="+event.getButtonState());
                sendSelectTransition(selectPress.action(action),event.getEventTime());
                return true;
            }
        });

        int windowFlags = (testMode ? WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE : WindowManager.LayoutParams.FLAG_ALT_FOCUSABLE_IM)
                | WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN
                | WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS
                | WindowManager.LayoutParams.FLAG_FULLSCREEN
                | WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED;

        WindowManager.LayoutParams params = new WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.TYPE_SYSTEM_ERROR,
            windowFlags,
            PixelFormat.TRANSLUCENT
        );
        params.gravity = Gravity.TOP | Gravity.LEFT;
        params.x = 0;
        params.y = 0;

        try {
            wm.addView(container, params);
            if (!testMode) Log.i(TAG,"INPUT_FOCUS_REQUEST="+container.requestFocus());
            overlayParams = params;

            Log.i(TAG, "Overlay added: TYPE_SYSTEM_ERROR " + OVERLAY_W + "x" + OVERLAY_H);
        } catch (Exception e) {
            Log.e(TAG, "Failed to add overlay: " + e);
            return;
        }

        if(!testMode)startVolumeFeedback();

        if (testMode) {
            handler.postDelayed(new Runnable() {
                @Override
                public void run() {
                    Log.i(TAG, "Test mode auto-dismiss after " + TEST_DISMISS_MS + "ms");
                    removeOverlay();
                    stopSelf();
                }
            }, TEST_DISMISS_MS);
        }
    }

    private void sendSelectTransition(int transition,long eventTime) {
        if(transition<0)return;
        Log.i(TAG,"INPUT_PAD_SELECT down="+(transition==1));
        if(touchListener!=null)touchListener.onAaKey(23,transition==1,eventTime);
    }

    private boolean handleTouch(MotionEvent event) {
        float rawX = event.getX();
        float rawY = event.getY();

        float aaX = rawX * (VIDEO_W / TOUCHPAD_X_MAX);
        float aaY = rawY * (VIDEO_H / TOUCHPAD_Y_MAX);
        if (projection != null) {
            aaX = projection.viewToActiveX(rawX * projection.viewWidth / TOUCHPAD_X_MAX);
            aaY = projection.viewToActiveY(rawY * projection.viewHeight / TOUCHPAD_Y_MAX);
        }

        if (aaX < 0) aaX = 0;
        int activeW = videoGeometry != null ? videoGeometry.activeWidth : VIDEO_W;
        int activeH = videoGeometry != null ? videoGeometry.activeHeight : VIDEO_H;
        if (aaX >= activeW) aaX = activeW - 1;
        if (aaY < 0) aaY = 0;
        if (aaY >= activeH) aaY = activeH - 1;

        int act = event.getActionMasked();
        String actName;
        if (act == MotionEvent.ACTION_DOWN) {
            actName = "DOWN";
            touchCount++;
        } else if (act == MotionEvent.ACTION_MOVE) {
            actName = "MOVE";
        } else if (act == MotionEvent.ACTION_UP) {
            actName = "UP";
        } else {
            actName = "action=" + act;
        }

        Log.i(TAG, "TOUCH #" + touchCount + " " + actName
            + " raw=(" + (int) rawX + "," + (int) rawY + ")"
            + " aa=(" + (int) aaX + "," + (int) aaY + ")"
            + " coordinateMode=" + (projection == null ? "legacy-diagnostic" : "active-geometry")
            + " nativePad=raw");

        if (touchListener != null) {
            touchListener.onAaTouch(act, rawX, rawY, aaX, aaY, event.getEventTime());
        }

        if (testMode && diagnosticView != null) {
            lastTouchAaX = aaX;
            lastTouchAaY = aaY;
            diagnosticView.invalidate();
        }

        return true;
    }

    private void drawTestPatternToCanvas(Canvas canvas) {
        int w = canvas.getWidth();
        int h = canvas.getHeight();

        canvas.drawColor(Color.argb(200, 0, 0, 0));

        Paint gridPaint = new Paint();
        gridPaint.setColor(Color.argb(60, 0, 255, 0));
        gridPaint.setStrokeWidth(1);
        for (int x = 0; x <= w; x += 100) canvas.drawLine(x, 0, x, h, gridPaint);
        for (int y = 0; y <= h; y += 100) canvas.drawLine(0, y, w, y, gridPaint);

        Paint majorPaint = new Paint();
        majorPaint.setColor(Color.argb(120, 0, 255, 0));
        majorPaint.setStrokeWidth(2);
        for (int x = 0; x <= w; x += 320) canvas.drawLine(x, 0, x, h, majorPaint);
        for (int y = 0; y <= h; y += 180) canvas.drawLine(0, y, w, y, majorPaint);

        // Touchpad right boundary
        Paint touchBound = new Paint();
        touchBound.setColor(Color.YELLOW);
        touchBound.setStrokeWidth(3);
        canvas.drawLine(1325, 0, 1325, h, touchBound);

        // Status bar line
        Paint statusPaint = new Paint();
        statusPaint.setColor(Color.RED);
        statusPaint.setStrokeWidth(2);
        canvas.drawLine(0, 32, w, 32, statusPaint);

        // 1280x720 reference box
        Paint videoBound = new Paint();
        videoBound.setColor(Color.CYAN);
        videoBound.setStrokeWidth(2);
        videoBound.setStyle(Paint.Style.STROKE);
        canvas.drawRect(0, 0, 1280, 720, videoBound);

        // Corners
        Paint corner = new Paint();
        corner.setColor(Color.WHITE);
        int cs = 20;
        canvas.drawRect(0, 0, cs, cs, corner);
        canvas.drawRect(w - cs, 0, w, cs, corner);
        canvas.drawRect(0, h - cs, cs, h, corner);
        canvas.drawRect(w - cs, h - cs, w, h, corner);

        Paint text = new Paint(Paint.ANTI_ALIAS_FLAG);
        text.setColor(Color.WHITE);
        text.setTextSize(28);
        text.setTextAlign(Paint.Align.CENTER);

        Paint smallText = new Paint(Paint.ANTI_ALIAS_FLAG);
        smallText.setColor(Color.WHITE);
        smallText.setTextSize(18);
        smallText.setTextAlign(Paint.Align.CENTER);

        float cx = w / 2f;
        canvas.drawText("AA OVERLAY — SURFACE TEST", cx, h / 2f - 60, text);
        canvas.drawText("Overlay: " + w + "x" + h + "  Active video: " + VIDEO_W + "x" + VIDEO_H, cx, h / 2f - 20, smallText);
        canvas.drawText("Protocol: 1920x1080 nominal, 360px margin = 1920x720 active", cx, h / 2f + 5, smallText);
        canvas.drawText("Yellow = touchpad edge (x=1325)  |  Red = status bar (y=32)", cx, h / 2f + 30, smallText);
        canvas.drawText("Cyan rect = 1280x720 reference  |  White corners = overlay edges", cx, h / 2f + 55, smallText);
        canvas.drawText("Touch: raw * " + String.format("%.3f", VIDEO_W / TOUCHPAD_X_MAX)
            + " in X (touchpad to full width)", cx, h / 2f + 80, smallText);
        canvas.drawText("TextureView surface reserved for MediaCodec (not Canvas-locked)", cx, h / 2f + 105, smallText);
        canvas.drawText("Auto-dismiss in 60s  |  Tap to see scaled coordinate", cx, h / 2f + 135, smallText);
    }

    public Surface getVideoSurface() {
        return surfaceReady ? videoSurface : null;
    }

    public void setVideoGeometry(final int codecW, final int codecH, final int activeW, final int activeH) {
        handler.post(new Runnable() {
            public void run() {
                if (destroyed) return;
                try {
                    VideoGeometry next = new VideoGeometry(codecW, codecH, activeW, activeH);
                    if (videoGeometry != null && (videoGeometry.codecWidth != codecW
                            || videoGeometry.codecHeight != codecH || videoGeometry.activeWidth != activeW
                            || videoGeometry.activeHeight != activeH)) decodedWidth = decodedHeight = 0;
                    videoGeometry = next;
                    applyVideoTransform();
                } catch (IllegalArgumentException e) {
                    videoGeometry = null;
                    decodedWidth = decodedHeight = 0;
                    rejectVideoTransform(e);
                }
            }
        });
    }

    public void setDecodedVisibleSize(final int width, final int height) {
        handler.post(new Runnable() {
            public void run() {
                if (destroyed) return;
                decodedWidth = width; decodedHeight = height;
                applyVideoTransform();
            }
        });
    }

    private void rejectVideoTransform(IllegalArgumentException reason) {
        projection = null;
        if (textureView != null) textureView.setTransform(new Matrix());
        Log.e(TAG, "VIDEO_GEOMETRY_REJECTED: " + reason.getMessage());
    }

    private void applyVideoTransform() {
        if (testMode || textureView == null || videoGeometry == null
                || textureView.getWidth() <= 0 || textureView.getHeight() <= 0) return;
        try {
            int width = decodedWidth == 0 ? videoGeometry.codecWidth : decodedWidth;
            int height = decodedHeight == 0 ? videoGeometry.codecHeight : decodedHeight;
            projection = videoGeometry.project(width, height, textureView.getWidth(), textureView.getHeight());
            Matrix matrix = new Matrix();
            matrix.setValues(projection.matrixValues());
            textureView.setTransform(matrix);
            textureView.invalidate();
            Log.i(TAG, "VIDEO_GEOMETRY_V1 mode=" + projection.mode
                + " visible=" + width + "x" + height
                + " active=" + videoGeometry.activeWidth + "x" + videoGeometry.activeHeight
                + " view=" + projection.viewWidth + "x" + projection.viewHeight
                + " sourceOffset=" + projection.sourceLeft + "," + projection.sourceTop
                + " transform=" + projection.scaleX + "," + projection.scaleY
                + "," + projection.translateX + "," + projection.translateY
                + " decodedFormatConfirmed=" + (decodedWidth != 0));
        } catch (IllegalArgumentException e) { rejectVideoTransform(e); }
    }

    public boolean isSurfaceReady() {
        return surfaceReady;
    }

    public void setTouchListener(TouchListener listener) {
        this.touchListener = listener;
    }

    public void setSurfaceReadyListener(SurfaceReadyListener listener) {
        this.surfaceReadyListener = listener;
    }

    /** Hide AA without ending it: transparent, not touchable, not focusable; small AA button shown. */
    private void minimizeOverlay() {
        if (container == null || overlayParams == null) return;
        sendSelectTransition(selectPress.action(MotionEvent.ACTION_CANCEL), SystemClock.uptimeMillis());
        mediaButtons.reset();
        backHold.reset();
        overlayParams.flags |= WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE | WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE;
        overlayParams.alpha = 0f;
        try { wm.updateViewLayout(container, overlayParams); }
        catch (RuntimeException e) { Log.w(TAG, "OVERLAY_MINIMIZE_FAILED " + e.getClass().getSimpleName()); homeToggle.reset(); overlayParams.flags &= ~(WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE | WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE); overlayParams.alpha = 1f; return; }
        showRestoreButton();
        Log.i(TAG, "OVERLAY_MINIMIZED session continues; press the side-panel button to return");
    }

    private void restoreOverlay(String how) {
        if (container == null || overlayParams == null) { removeRestoreButton(); homeToggle.reset(); return; }
        int oldFlags = overlayParams.flags;
        overlayParams.flags &= ~(WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE | WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE);
        overlayParams.alpha = 1f;
        try { wm.updateViewLayout(container, overlayParams); }
        catch (RuntimeException e) {
            // Stay minimized with the button available.
            overlayParams.flags = oldFlags; overlayParams.alpha = 0f;
            homeToggle.minimizedByBack();
            Log.w(TAG, "OVERLAY_RESTORE_FAILED " + e.getClass().getSimpleName()); return;
        }
        removeRestoreButton();
        homeToggle.restored();
        Log.i(TAG, "OVERLAY_RESTORED via=" + how + " INPUT_FOCUS_REQUEST=" + container.requestFocus());
    }

    private void showRestoreButton() {
        if (restoreButton != null) return;
        TextView button = new TextView(this);
        button.setText("AA");
        button.setTextSize(24);
        button.setTextColor(Color.WHITE);
        button.setGravity(Gravity.CENTER);
        button.setBackgroundColor(0xE61A73E8);
        button.setOnClickListener(new View.OnClickListener() {
            @Override public void onClick(View v) { restoreOverlay("button"); }
        });
        WindowManager.LayoutParams p = new WindowManager.LayoutParams(120, 64,
            WindowManager.LayoutParams.TYPE_SYSTEM_ERROR,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE | WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT);
        p.gravity = Gravity.BOTTOM | Gravity.LEFT;
        p.x = 16;
        p.y = 16;
        try { wm.addView(button, p); restoreButton = button; }
        catch (RuntimeException e) { Log.w(TAG, "RESTORE_BUTTON_UNAVAILABLE " + e.getClass().getSimpleName()); }
    }

    private void removeRestoreButton() {
        if (restoreButton == null) return;
        try { wm.removeView(restoreButton); restoreButton = null; }
        catch (RuntimeException e) { Log.w(TAG, "RESTORE_BUTTON_REMOVE_FAILED " + e.getClass().getSimpleName()); }
    }

    private void startVolumeFeedback() {
        volumeHud=new TextView(this);
        volumeHud.setTextColor(Color.WHITE);
        volumeHud.setBackgroundColor(0xE6202020);
        volumeHud.setTextSize(22);
        volumeHud.setGravity(Gravity.CENTER);
        volumeHud.setFocusable(false);
        volumeHud.setFocusableInTouchMode(false);
        volumeHud.setClickable(false);
        volumeHud.setLongClickable(false);
        volumeHud.setImportantForAccessibility(View.IMPORTANT_FOR_ACCESSIBILITY_NO);
        volumeHud.setVisibility(View.GONE);
        FrameLayout.LayoutParams layout=new FrameLayout.LayoutParams(280,64,Gravity.TOP|Gravity.CENTER_HORIZONTAL);
        layout.topMargin=12;
        container.addView(volumeHud,layout);
        try {
            registerReceiver(volumeReceiver,new IntentFilter(VolumeFeedback.ACTION));
            volumeReceiverRegistered=true;
            Log.i(TAG,"VOLUME_FEEDBACK_REGISTERED source=ANDROID_MASTER_VOLUME");
        }catch(RuntimeException error){
            Log.w(TAG,"VOLUME_FEEDBACK_UNAVAILABLE type="+error.getClass().getSimpleName());
        }
    }

    private void showVolumeFeedback() {
        if(destroyed || volumeHud==null || volumeFeedback.level()<0)return;
        volumeHud.setText("Volume "+volumeFeedback.level());
        volumeHud.setVisibility(View.VISIBLE);
        volumeHud.bringToFront();
        handler.removeCallbacks(hideVolumeHud);
        handler.postDelayed(hideVolumeHud,VolumeFeedback.DISPLAY_MS);
        Log.i(TAG,"VOLUME_FEEDBACK_SHOWN level="+volumeFeedback.level());
    }

    private void removeOverlay() {
        if(volumeReceiverRegistered){
            try{unregisterReceiver(volumeReceiver);}catch(IllegalArgumentException ignored){}
            volumeReceiverRegistered=false;
        }
        volumeFeedback.reset();
        volumeHud=null;
        removeRestoreButton();
        restoreButton = null; // overlay teardown: drop the reference even if removal failed
        homeToggle.reset();
        backHold.reset();
        overlayParams = null;
        mediaButtons.reset();
        if(focusCapture!=null){focusCapture.close();focusCapture=null;}
        sendSelectTransition(selectPress.action(MotionEvent.ACTION_CANCEL),android.os.SystemClock.uptimeMillis());
        handler.removeCallbacksAndMessages(null);
        surfaceReady = false;
        projection = null;
        videoGeometry = null;
        decodedWidth = decodedHeight = 0;
        if (container != null) {
            try {
                wm.removeView(container);
            } catch (Exception ignored) { }
            container = null;
            textureView = null;
            diagnosticView = null;
            Log.i(TAG, "Overlay removed");
        }
        if (videoSurface != null) {
            videoSurface.release();
            videoSurface = null;
        }
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    @Override
    public void onDestroy() {
        destroyed = true;
        removeOverlay();
        instance = null;
        Log.i(TAG, "AaOverlayService destroyed");
        super.onDestroy();
    }
}
