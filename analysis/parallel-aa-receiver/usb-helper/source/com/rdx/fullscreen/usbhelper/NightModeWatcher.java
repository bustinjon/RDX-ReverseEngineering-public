package com.rdx.fullscreen.usbhelper;

import android.os.IBinder;
import android.os.Parcel;
import android.util.Log;
import java.lang.reflect.Method;

/**
 * Reads the head unit's day/night display mode with the same read-only binder call stock
 * HondaLCDManager.getLCDMode() makes ("lcd_service", transaction 6), and reports changes.
 * Never calls a setter. If the service cannot be reached, it logs once and reports nothing.
 */
final class NightModeWatcher {
    /** Returns true when the value was delivered; false is retried on the next poll. */
    interface Listener { boolean onNightMode(boolean night); }

    static final String SERVICE = "lcd_service";
    static final String DESCRIPTOR = "com.honda.auto.lcd.IHondaLCDManagerService";
    static final int TRANSACTION_GET_LCD_MODE = 6;
    static final int DAY = 0, NIGHT = 1, SCREEN_OFF = 2;
    private static final long POLL_MS = 5000;
    private static final String TAG = "RDX.NIGHT";

    private final Listener listener;
    private volatile boolean running;
    private Thread thread;
    /** Last reported value: -1 none yet. SCREEN_OFF keeps the previous day/night value. */
    private int reported = -1;

    NightModeWatcher(Listener listener) { this.listener = listener; }

    /** Maps an LCD mode ordinal to the value to report, or -1 to report nothing. */
    static int nightValue(int ordinal, int previous) {
        if (ordinal == DAY) return 0;
        if (ordinal == NIGHT) return 1;
        return previous >= 0 ? previous : -1;
    }

    synchronized void start() {
        if (running) return;
        running = true;
        thread = new Thread(new Runnable() { public void run() { loop(); } }, "RDX-night");
        thread.start();
    }

    /** Returns true when the polling thread has ended. Reports after stop are refused by SensorSource. */
    boolean stop() {
        Thread t;
        synchronized (this) { running = false; t = thread; thread = null; }
        if (t != null) {
            t.interrupt();
            try { t.join(1000); } catch (InterruptedException ignored) { Thread.currentThread().interrupt(); }
            if (t.isAlive()) { Log.w(TAG, "NIGHT_MODE_THREAD_STILL_RUNNING"); return false; }
        }
        return true;
    }

    private void loop() {
        IBinder binder = lookup();
        if (binder == null) { Log.w(TAG, "NIGHT_MODE_UNAVAILABLE service=" + SERVICE); return; }
        Log.i(TAG, "NIGHT_MODE_WATCHING service=" + SERVICE);
        while (running) {
            int ordinal = read(binder);
            if (!running) return; // stop() may have timed out while the binder read was in flight
            int value = ordinal < 0 ? -1 : nightValue(ordinal, reported);
            if (value >= 0 && value != reported) {
                boolean delivered = listener.onNightMode(value == 1);
                Log.i(TAG, "NIGHT_MODE_REPORT night=" + (value == 1) + " lcdMode=" + ordinal + " delivered=" + delivered);
                if (delivered) reported = value;
            }
            try { Thread.sleep(POLL_MS); } catch (InterruptedException e) { return; }
        }
    }

    private static IBinder lookup() {
        try {
            Method get = Class.forName("android.os.ServiceManager").getMethod("getService", String.class);
            return (IBinder) get.invoke(null, SERVICE);
        } catch (Exception e) {
            Log.w(TAG, "NIGHT_MODE_LOOKUP_FAILED " + e.getClass().getSimpleName());
            return null;
        }
    }

    private static int read(IBinder binder) {
        Parcel data = Parcel.obtain(), reply = Parcel.obtain();
        try {
            data.writeInterfaceToken(DESCRIPTOR);
            binder.transact(TRANSACTION_GET_LCD_MODE, data, reply, 0);
            reply.readException();
            return reply.readInt();
        } catch (Exception e) {
            Log.w(TAG, "NIGHT_MODE_READ_FAILED " + e.getClass().getSimpleName());
            return -1;
        } finally {
            reply.recycle();
            data.recycle();
        }
    }
}
