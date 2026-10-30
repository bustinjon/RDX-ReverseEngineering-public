package com.rdx.fullscreen.usbhelper;

import android.app.Service;
import android.content.Intent;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.PixelFormat;
import android.graphics.Typeface;
import android.os.Handler;
import android.os.IBinder;
import android.util.Log;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.View;
import android.view.WindowManager;

/**
 * Tests whether TYPE_SYSTEM_OVERLAY / TYPE_SYSTEM_ALERT windows can draw
 * over the full 1280x720 screen, bypassing Honda's B-zone (1280x688) limit.
 *
 * Triggered via: am startservice -a overlay.test.TYPE_SYSTEM_OVERLAY com.rdx.fullscreen.usbhelper/.OverlayTestService
 * Actions:
 *   overlay.test.TYPE_SYSTEM_OVERLAY  — test TYPE_SYSTEM_OVERLAY (2006)
 *   overlay.test.TYPE_SYSTEM_ALERT    — test TYPE_SYSTEM_ALERT (2003)
 *   overlay.test.TYPE_SYSTEM_ERROR    — test TYPE_SYSTEM_ERROR (2010)
 *   overlay.test.TYPE_PHONE           — test TYPE_PHONE (2002)
 *   overlay.test.TOUCH                — TYPE_SYSTEM_ERROR with touch enabled, logs coordinates
 *   overlay.test.DISMISS              — remove overlay and stop
 *
 * Each overlay auto-dismisses after 30 seconds (60 for touch test).
 */
public final class OverlayTestService extends Service {
    private static final String TAG = "RDX.OVERLAY";
    private WindowManager wm;
    private View overlayView;
    private Handler handler;
    private int touchCount;
    private float lastTouchX = -1, lastTouchY = -1;
    private String lastTouchAction = "";

    @Override
    public void onCreate() {
        super.onCreate();
        wm = (WindowManager) getSystemService(WINDOW_SERVICE);
        handler = new Handler();
        Log.i(TAG, "OverlayTestService created");
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        String action = intent != null ? intent.getAction() : null;
        Log.i(TAG, "onStartCommand action=" + action);

        if ("overlay.test.DISMISS".equals(action)) {
            removeOverlay();
            stopSelf();
            return START_NOT_STICKY;
        }

        int windowType;
        String typeName;
        boolean touchEnabled = false;

        if ("overlay.test.TOUCH".equals(action)) {
            windowType = WindowManager.LayoutParams.TYPE_SYSTEM_ERROR;
            typeName = "TOUCH TEST (TYPE_SYSTEM_ERROR)";
            touchEnabled = true;
        } else if ("overlay.test.TYPE_SYSTEM_ALERT".equals(action)) {
            windowType = WindowManager.LayoutParams.TYPE_SYSTEM_ALERT;
            typeName = "TYPE_SYSTEM_ALERT (2003)";
        } else if ("overlay.test.TYPE_SYSTEM_ERROR".equals(action)) {
            windowType = WindowManager.LayoutParams.TYPE_SYSTEM_ERROR;
            typeName = "TYPE_SYSTEM_ERROR (2010)";
        } else if ("overlay.test.TYPE_PHONE".equals(action)) {
            windowType = WindowManager.LayoutParams.TYPE_PHONE;
            typeName = "TYPE_PHONE (2002)";
        } else {
            windowType = WindowManager.LayoutParams.TYPE_SYSTEM_OVERLAY;
            typeName = "TYPE_SYSTEM_OVERLAY (2006)";
        }

        removeOverlay();
        testOverlay(windowType, typeName, touchEnabled);
        return START_NOT_STICKY;
    }

    private void testOverlay(final int windowType, final String typeName, final boolean touchEnabled) {
        Log.i(TAG, "Creating overlay: " + typeName + " touch=" + touchEnabled + " at MATCH_PARENT x MATCH_PARENT");
        touchCount = 0;
        lastTouchX = -1;
        lastTouchY = -1;
        lastTouchAction = "";

        final Paint textPaint = new Paint(Paint.ANTI_ALIAS_FLAG);
        textPaint.setColor(Color.WHITE);
        textPaint.setTextSize(36);
        textPaint.setTypeface(Typeface.DEFAULT_BOLD);
        textPaint.setTextAlign(Paint.Align.CENTER);

        final Paint smallPaint = new Paint(Paint.ANTI_ALIAS_FLAG);
        smallPaint.setColor(Color.WHITE);
        smallPaint.setTextSize(20);
        smallPaint.setTypeface(Typeface.MONOSPACE);
        smallPaint.setTextAlign(Paint.Align.CENTER);

        final Paint borderPaint = new Paint();
        borderPaint.setColor(Color.RED);
        borderPaint.setStyle(Paint.Style.STROKE);
        borderPaint.setStrokeWidth(4);

        final Paint dotPaint = new Paint(Paint.ANTI_ALIAS_FLAG);
        dotPaint.setColor(Color.CYAN);

        overlayView = new View(this) {
            @Override
            protected void onDraw(Canvas canvas) {
                int w = getWidth();
                int h = getHeight();

                canvas.drawColor(Color.argb(160, 0, 80, 0));
                canvas.drawRect(2, 2, w - 2, h - 2, borderPaint);

                Paint corner = new Paint();
                corner.setColor(Color.RED);
                int cs = 30;
                canvas.drawRect(0, 0, cs, cs, corner);
                canvas.drawRect(w - cs, 0, w, cs, corner);
                canvas.drawRect(0, h - cs, cs, h, corner);
                canvas.drawRect(w - cs, h - cs, w, h, corner);

                Paint linePaint = new Paint();
                linePaint.setColor(Color.YELLOW);
                linePaint.setStrokeWidth(3);
                canvas.drawLine(0, 32, w, 32, linePaint);

                float cx = w / 2f;
                if (touchEnabled) {
                    canvas.drawText("TOUCH TEST", cx, h / 2f - 80, textPaint);
                    canvas.drawText(typeName, cx, h / 2f - 30, smallPaint);
                    canvas.drawText("View: " + w + "x" + h + "  Touches: " + touchCount, cx, h / 2f + 10, smallPaint);
                    if (lastTouchX >= 0) {
                        canvas.drawText("Last: (" + (int) lastTouchX + ", " + (int) lastTouchY + ") " + lastTouchAction, cx, h / 2f + 40, smallPaint);
                        canvas.drawCircle(lastTouchX, lastTouchY, 20, dotPaint);
                    } else {
                        canvas.drawText("Tap anywhere on the touchpad", cx, h / 2f + 40, smallPaint);
                    }
                    canvas.drawText("Auto-dismiss in 60s", cx, h / 2f + 80, smallPaint);
                } else {
                    canvas.drawText("OVERLAY TEST", cx, h / 2f - 60, textPaint);
                    canvas.drawText(typeName, cx, h / 2f - 10, smallPaint);
                    canvas.drawText("View size: " + w + "x" + h, cx, h / 2f + 30, smallPaint);
                    canvas.drawText("Yellow line = y=32 (status bar bottom)", cx, h / 2f + 60, smallPaint);
                    canvas.drawText("Red corners should be at screen edges", cx, h / 2f + 90, smallPaint);
                    canvas.drawText("Auto-dismiss in 15s", cx, h / 2f + 130, smallPaint);
                }

                Log.i(TAG, "onDraw: " + typeName + " view=" + w + "x" + h
                    + " screenLocation=(" + getLeft() + "," + getTop() + ")");
            }

            @Override
            public boolean onTouchEvent(MotionEvent event) {
                lastTouchX = event.getX();
                lastTouchY = event.getY();
                int act = event.getActionMasked();
                if (act == MotionEvent.ACTION_DOWN) lastTouchAction = "DOWN";
                else if (act == MotionEvent.ACTION_MOVE) lastTouchAction = "MOVE";
                else if (act == MotionEvent.ACTION_UP) lastTouchAction = "UP";
                else lastTouchAction = "action=" + act;

                if (act == MotionEvent.ACTION_DOWN) touchCount++;

                Log.i(TAG, "TOUCH #" + touchCount + " " + lastTouchAction
                    + " x=" + (int) lastTouchX + " y=" + (int) lastTouchY
                    + " rawX=" + (int) event.getRawX() + " rawY=" + (int) event.getRawY()
                    + " pointers=" + event.getPointerCount());
                invalidate();
                return true;
            }
        };

        int flags;
        if (touchEnabled) {
            flags = WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
                    | WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN
                    | WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS
                    | WindowManager.LayoutParams.FLAG_FULLSCREEN;
        } else {
            flags = WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
                    | WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE
                    | WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN
                    | WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS
                    | WindowManager.LayoutParams.FLAG_FULLSCREEN;
        }

        try {
            WindowManager.LayoutParams params = new WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.MATCH_PARENT,
                windowType,
                flags,
                PixelFormat.TRANSLUCENT
            );
            params.gravity = Gravity.TOP | Gravity.LEFT;
            params.x = 0;
            params.y = 0;

            wm.addView(overlayView, params);
            Log.i(TAG, "Overlay added successfully: " + typeName + " touch=" + touchEnabled);

            long dismissMs = touchEnabled ? 60000 : 15000;
            handler.postDelayed(new Runnable() {
                @Override
                public void run() {
                    Log.i(TAG, "Auto-dismissing overlay: " + typeName);
                    removeOverlay();
                    stopSelf();
                }
            }, dismissMs);

        } catch (Exception e) {
            Log.e(TAG, "Failed to add overlay: " + e.getClass().getSimpleName() + ": " + e.getMessage());
        }
    }

    private void removeOverlay() {
        if (overlayView != null) {
            try {
                wm.removeView(overlayView);
            } catch (Exception ignored) { }
            overlayView = null;
            Log.i(TAG, "Overlay removed");
        }
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    @Override
    public void onDestroy() {
        removeOverlay();
        handler.removeCallbacksAndMessages(null);
        Log.i(TAG, "OverlayTestService destroyed");
        super.onDestroy();
    }
}
