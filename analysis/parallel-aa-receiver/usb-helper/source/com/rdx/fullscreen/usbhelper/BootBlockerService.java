package com.rdx.fullscreen.usbhelper;

import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.graphics.Color;
import android.graphics.PixelFormat;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;
import android.util.Log;
import android.view.Gravity;
import android.view.View;
import android.view.WindowManager;

/**
 * Temporary boot-time blocker. Waits SHOW_DELAY_MS after start, then draws a black
 * TYPE_SYSTEM_ERROR overlay (above the detector's TYPE_SYSTEM_ALERT) for SHOW_DURATION_MS,
 * then removes it and stops itself. Covers roughly boot+8s .. boot+16s.
 */
public class BootBlockerService extends Service {
    private static final String TAG = "RdxBootBlocker";
    private static final long SHOW_DELAY_MS = 8000L;
    private static final long SHOW_DURATION_MS = 8000L;

    private final Handler handler = new Handler(Looper.getMainLooper());
    private WindowManager windowManager;
    private View overlayView;
    private boolean scheduled;

    private final Runnable showRunnable = new Runnable() {
        @Override
        public void run() {
            showOverlay();
            handler.postDelayed(finishRunnable, SHOW_DURATION_MS);
        }
    };

    private final Runnable finishRunnable = new Runnable() {
        @Override
        public void run() {
            removeOverlay();
            stopSelf();
        }
    };

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (!scheduled) {
            scheduled = true;
            windowManager = (WindowManager) getSystemService(Context.WINDOW_SERVICE);
            handler.postDelayed(showRunnable, SHOW_DELAY_MS);
            Log.i(TAG, "scheduled overlay in " + SHOW_DELAY_MS + " ms");
        }
        return START_NOT_STICKY;
    }

    private void showOverlay() {
        if (overlayView != null || windowManager == null) {
            return;
        }
        try {
            View v = new View(this);
            v.setBackgroundColor(Color.BLACK);
            WindowManager.LayoutParams lp = new WindowManager.LayoutParams(
                    WindowManager.LayoutParams.MATCH_PARENT,
                    WindowManager.LayoutParams.MATCH_PARENT,
                    WindowManager.LayoutParams.TYPE_SYSTEM_ERROR,
                    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
                            | WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE
                            | WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
                    PixelFormat.TRANSLUCENT);
            lp.gravity = Gravity.TOP | Gravity.LEFT;
            windowManager.addView(v, lp);
            overlayView = v;
            Log.i(TAG, "overlay shown");
        } catch (Throwable t) {
            Log.e(TAG, "failed to show overlay", t);
        }
    }

    private void removeOverlay() {
        if (overlayView != null && windowManager != null) {
            try {
                windowManager.removeView(overlayView);
                Log.i(TAG, "overlay removed");
            } catch (Throwable t) {
                Log.e(TAG, "failed to remove overlay", t);
            }
        }
        overlayView = null;
    }

    @Override
    public void onDestroy() {
        handler.removeCallbacks(showRunnable);
        handler.removeCallbacks(finishRunnable);
        removeOverlay();
        super.onDestroy();
    }
}
