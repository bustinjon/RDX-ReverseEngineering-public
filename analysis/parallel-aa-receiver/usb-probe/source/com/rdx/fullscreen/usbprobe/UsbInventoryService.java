package com.rdx.fullscreen.usbprobe;

import android.app.Service;
import android.content.Intent;
import android.hardware.usb.*;
import android.os.Build;
import android.os.IBinder;
import android.os.Process;
import android.os.SystemClock;
import android.util.Log;
import java.util.HashMap;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;

/** One explicit, cancellable observation window. Duplicate starts never queue windows. */
public final class UsbInventoryService extends Service {
    private static final String TAG = "RDX.M4";
    private static final String ACTION = "com.rdx.fullscreen.usbprobe.SNAPSHOT";
    private volatile boolean cancelled;
    private Thread worker;
    private FileWriter evidence;

    private void record(String message) {
        Log.i(TAG, message);
        if (evidence != null) {
            try {
                evidence.write("wallMs=" + System.currentTimeMillis() + " elapsedMs="
                    + SystemClock.elapsedRealtime() + " " + message + "\n");
                evidence.flush();
            } catch (IOException e) {
                Log.w(TAG, "Own result file unavailable; logcat remains active", e);
                try { evidence.close(); } catch (IOException ignored) { }
                evidence = null;
            }
        }
    }

    @Override public IBinder onBind(Intent intent) { return null; }

    @Override public int onStartCommand(Intent intent, int flags, final int startId) {
        if (intent == null || !ACTION.equals(intent.getAction())) {
            if (worker == null) stopSelf();
            return START_NOT_STICKY;
        }
        if (worker != null) {
            Log.w(TAG, "Already running; duplicate start ignored");
            return START_NOT_STICKY;
        }
        cancelled = false;
        worker = new Thread(new Runnable() {
            @Override public void run() {
                try {
                    try {
                        File directory = getExternalFilesDir(null);
                        if (directory != null) {
                            File result = new File(directory, "m4-last-run.txt");
                            evidence = new FileWriter(result, false);
                            record("RESULT_FILE=" + result.getAbsolutePath()
                                + " version=0.1.2-m4-single-port-300s durationSeconds=300");
                        } else Log.w(TAG, "Own external-files directory unavailable; logcat only");
                    } catch (IOException e) { Log.w(TAG, "Own result file unavailable; logcat only", e); }
                    UsbManager manager = (UsbManager) getSystemService(USB_SERVICE);
                    if (manager == null) { Log.w(TAG, "No UsbManager"); return; }
                    for (int n = 0; n < 301 && !cancelled; n++) {
                        record("SNAPSHOT sample=" + n + " wallMs=" + System.currentTimeMillis()
                            + " elapsedMs=" + SystemClock.elapsedRealtime() + " uid=" + Process.myUid()
                            + " pid=" + Process.myPid() + " api=" + Build.VERSION.SDK_INT
                            + " nativeLibraryDir=" + getApplicationInfo().nativeLibraryDir);
                        snapshot(manager);
                        if (n < 300 && !cancelled) Thread.sleep(1000);
                    }
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                    record("Observation interrupted");
                } catch (RuntimeException e) {
                    Log.e(TAG, "Observation ended with error", e);
                    record("ERROR " + e.toString());
                } finally {
                    record("END; passive enumeration only; no open/claim/permission-request/transfer performed");
                    if (evidence != null) {
                        try { evidence.close(); } catch (IOException e) { Log.w(TAG, "Result close failed", e); }
                        evidence = null;
                    }
                    stopSelf();
                }
            }
        }, "RdxM4Inventory");
        worker.start();
        return START_NOT_STICKY;
    }

    private void snapshot(UsbManager manager) {
        HashMap<String, UsbDevice> devices = manager.getDeviceList();
        record("deviceCount=" + (devices == null ? -1 : devices.size()));
        if (devices == null) return;
        for (UsbDevice d : devices.values()) {
            if (cancelled) return;
            try {
                record("device=" + d.getDeviceName() + " vendorId=" + d.getVendorId()
                    + " productId=" + d.getProductId() + " class=" + d.getDeviceClass()
                    + " subclass=" + d.getDeviceSubclass() + " protocol=" + d.getDeviceProtocol()
                    + " configurationCount=" + d.getConfigurationCount()
                    + " interfaceCount=" + d.getInterfaceCount() + " hasPermission=" + manager.hasPermission(d));
                for (int i = 0; i < d.getInterfaceCount(); i++) {
                    UsbInterface u = d.getInterface(i);
                    record("interface=" + u.getId() + " alternateSetting=" + u.getAlternateSetting()
                        + " class=" + u.getInterfaceClass() + " subclass=" + u.getInterfaceSubclass()
                        + " protocol=" + u.getInterfaceProtocol() + " endpointCount=" + u.getEndpointCount());
                    for (int j = 0; j < u.getEndpointCount(); j++) {
                        UsbEndpoint e = u.getEndpoint(j);
                        record("endpoint=" + e.getAddress() + " direction=" + e.getDirection()
                            + " type=" + e.getType() + " maxPacketSize=" + e.getMaxPacketSize()
                            + " interval=" + e.getInterval());
                    }
                }
            } catch (RuntimeException e) { Log.w(TAG, "Descriptor/permission observation failed", e); record("DESCRIPTOR_ERROR " + e.toString()); }
        }
    }

    @Override public void onDestroy() {
        cancelled = true;
        if (worker != null) worker.interrupt();
        super.onDestroy();
    }
}
