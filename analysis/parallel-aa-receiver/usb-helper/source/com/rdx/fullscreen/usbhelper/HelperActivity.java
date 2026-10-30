package com.rdx.fullscreen.usbhelper;

import android.app.Activity;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.graphics.Color;
import android.graphics.Typeface;
import android.hardware.usb.UsbDevice;
import android.hardware.usb.UsbManager;
import android.os.Bundle;
import android.os.Handler;
import android.os.IBinder;
import android.os.SystemClock;
import android.util.Log;
import android.view.Gravity;
import android.view.WindowManager;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.lang.reflect.Method;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.HashMap;
import java.util.Locale;
import java.util.Set;

/**
 * USB permission helper v2. Adds: detach listener, reflection grant, full callback dump.
 */
public final class HelperActivity extends Activity {
    private static final String TAG = "RDX.USB";
    private static final int VID = 0x18d1, PID = 0x2d01;
    private static final long STABLE_MS = 5000;
    private static final int MAX_RETRIES = 5;
    private static final long POLL_MS = 500;

    private static final int WAITING = 0, STABILIZING = 1, REQUESTING = 2, GRANTED = 3, FAILED = 4;

    private UsbManager usbManager;
    private Handler handler;
    private TextView statusView, detailView, logView;
    private ScrollView logScroll;

    private int phase = WAITING;
    private long targetStableSince;
    private String targetPath;
    private int attempts;
    private boolean receiverRegistered;
    private boolean detachReceiverRegistered;
    private int detachCount;
    private int attachCount;
    private final StringBuilder logBuffer = new StringBuilder();
    private FileOutputStream logFile;

    private final BroadcastReceiver usbEventReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context ctx, Intent intent) {
            String action = intent.getAction();
            UsbDevice device = (UsbDevice) intent.getParcelableExtra(UsbManager.EXTRA_DEVICE);
            String path = device != null ? device.getDeviceName() : "null";
            int vid = device != null ? device.getVendorId() : -1;
            int pid = device != null ? device.getProductId() : -1;
            if ("android.hardware.usb.action.USB_DEVICE_DETACHED".equals(action)) {
                detachCount++;
                logLine("*** USB_DEVICE_DETACHED #" + detachCount + " path=" + path
                    + " vid=" + Integer.toHexString(vid) + " pid=" + Integer.toHexString(pid));
            } else if ("android.hardware.usb.action.USB_DEVICE_ATTACHED".equals(action)) {
                attachCount++;
                logLine("*** USB_DEVICE_ATTACHED #" + attachCount + " path=" + path
                    + " vid=" + Integer.toHexString(vid) + " pid=" + Integer.toHexString(pid));
            }
        }
    };

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN,
            WindowManager.LayoutParams.FLAG_FULLSCREEN);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);

        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setBackgroundColor(Color.rgb(20, 20, 30));
        root.setPadding(40, 32, 40, 32);

        statusView = new TextView(this);
        statusView.setTextSize(32);
        statusView.setTextColor(Color.WHITE);
        statusView.setGravity(Gravity.CENTER);
        statusView.setPadding(0, 16, 0, 8);
        root.addView(statusView);

        detailView = new TextView(this);
        detailView.setTextSize(18);
        detailView.setTextColor(Color.rgb(180, 180, 200));
        detailView.setGravity(Gravity.CENTER);
        detailView.setPadding(0, 0, 0, 24);
        root.addView(detailView);

        logScroll = new ScrollView(this);
        logView = new TextView(this);
        logView.setTextSize(11);
        logView.setTextColor(Color.rgb(100, 200, 100));
        logView.setTypeface(Typeface.MONOSPACE);
        logView.setPadding(8, 8, 8, 8);
        logScroll.addView(logView);
        logScroll.setBackgroundColor(Color.rgb(10, 10, 15));
        root.addView(logScroll, new LinearLayout.LayoutParams(-1, 0, 1f));

        setContentView(root);

        usbManager = (UsbManager) getSystemService(USB_SERVICE);
        handler = new Handler();

        try {
            File f = new File(getFilesDir(), "usb-helper-log.txt");
            logFile = new FileOutputStream(f, true);
        } catch (IOException ignored) { }

        IntentFilter usbFilter = new IntentFilter();
        usbFilter.addAction("android.hardware.usb.action.USB_DEVICE_DETACHED");
        usbFilter.addAction("android.hardware.usb.action.USB_DEVICE_ATTACHED");
        registerReceiver(usbEventReceiver, usbFilter);
        detachReceiverRegistered = true;

        logLine("=== Session started v2 " +
            new SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.US).format(new Date()) +
            " uid=" + android.os.Process.myUid() +
            " pid=" + android.os.Process.myPid() + " ===");

        updateStatus();
        handler.post(pollRunnable);
    }

    private final Runnable pollRunnable = new Runnable() {
        @Override
        public void run() {
            if (phase == GRANTED || phase == FAILED) return;
            tick();
            handler.postDelayed(this, POLL_MS);
        }
    };

    private void tick() {
        HashMap<String, UsbDevice> devices;
        try {
            devices = usbManager.getDeviceList();
        } catch (RuntimeException e) {
            logLine("ERROR getDeviceList: " + e);
            return;
        }

        UsbDevice target = null;
        for (UsbDevice d : devices.values()) {
            if (d.getVendorId() == VID && d.getProductId() == PID) {
                target = d;
                break;
            }
        }

        long now = SystemClock.elapsedRealtime();

        if (target == null) {
            if (phase == STABILIZING) {
                logLine("Device disconnected during stabilization");
                phase = WAITING;
                targetPath = null;
                updateStatus();
            } else if (phase == REQUESTING) {
                logLine("Device disconnected while permission request pending");
            }
            return;
        }

        String path = target.getDeviceName();

        if (phase == WAITING) {
            targetStableSince = now;
            targetPath = path;
            phase = STABILIZING;
            logLine("AOAP device detected: vid=18d1 pid=2d01 path=" + path);
            updateStatus();
            return;
        }

        if (phase == STABILIZING) {
            if (!path.equals(targetPath)) {
                logLine("Re-enumeration detected: " + targetPath + " -> " + path);
                targetStableSince = now;
                targetPath = path;
                updateStatus();
                return;
            }
            long stable = now - targetStableSince;
            if (stable >= STABLE_MS) {
                if (usbManager.hasPermission(target)) {
                    phase = GRANTED;
                    logLine("Already has permission for " + path);
                    updateStatus();
                    return;
                }
                attempts++;
                logLine("Connection stable " + stable + "ms. Requesting permission (attempt "
                    + attempts + "/" + MAX_RETRIES + ") for " + path
                    + " detachCount=" + detachCount + " attachCount=" + attachCount);
                doRequest(target);
            } else {
                detailView.setText("Stable " + (stable / 1000) + "s / "
                    + (STABLE_MS / 1000) + "s needed\nPath: " + targetPath);
            }
        }
    }

    private void doRequest(UsbDevice device) {
        phase = REQUESTING;
        updateStatus();

        if (receiverRegistered) {
            try { unregisterReceiver(resultReceiver); } catch (Exception ignored) { }
            receiverRegistered = false;
        }

        String action = getPackageName() + ".USB_PERM." + SystemClock.elapsedRealtime();
        registerReceiver(resultReceiver, new IntentFilter(action));
        receiverRegistered = true;

        Intent cb = new Intent(action);
        cb.setPackage(getPackageName());
        PendingIntent pi = PendingIntent.getBroadcast(this, 0, cb,
            PendingIntent.FLAG_ONE_SHOT | PendingIntent.FLAG_CANCEL_CURRENT);

        logLine("Calling UsbManager.requestPermission for " + device.getDeviceName());
        usbManager.requestPermission(device, pi);
        logLine("requestPermission returned; dialog should be visible — waiting for ADB tap or user");
    }

    private void tryDirectGrant(UsbDevice device) {
        logLine("Attempting direct grantDevicePermission via reflection...");
        try {
            Class<?> smClass = Class.forName("android.os.ServiceManager");
            Method getService = smClass.getMethod("getService", String.class);
            IBinder binder = (IBinder) getService.invoke(null, "usb");
            if (binder == null) {
                logLine("  ServiceManager.getService('usb') returned null");
                return;
            }
            Class<?> stubClass = Class.forName("android.hardware.usb.IUsbManager$Stub");
            Method asInterface = stubClass.getMethod("asInterface", IBinder.class);
            Object service = asInterface.invoke(null, binder);

            Method grant = service.getClass().getMethod("grantDevicePermission",
                UsbDevice.class, int.class);
            grant.invoke(service, device, android.os.Process.myUid());
            logLine("  grantDevicePermission call returned (no exception!)");

            if (usbManager.hasPermission(device)) {
                logLine("  DIRECT GRANT SUCCEEDED — hasPermission=true");
                phase = GRANTED;
                updateStatus();
            } else {
                logLine("  Call returned but hasPermission still false");
            }
        } catch (Exception e) {
            logLine("  Direct grant failed: " + e.getClass().getSimpleName() + ": " + e.getMessage());
        }
    }

    private final BroadcastReceiver resultReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context ctx, Intent intent) {
            if (receiverRegistered) {
                try { unregisterReceiver(this); } catch (Exception ignored) { }
                receiverRegistered = false;
            }

            boolean granted = intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false);
            UsbDevice device = (UsbDevice) intent.getParcelableExtra(UsbManager.EXTRA_DEVICE);
            boolean verified = device != null && usbManager.hasPermission(device);

            StringBuilder extras = new StringBuilder();
            Bundle b = intent.getExtras();
            if (b != null) {
                Set<String> keys = b.keySet();
                for (String key : keys) {
                    extras.append(key).append("=").append(b.get(key)).append(" ");
                }
            }
            logLine("Permission callback: granted=" + granted + " verified=" + verified
                + (device != null ? " path=" + device.getDeviceName() : " device=null")
                + " detachCount=" + detachCount + " attachCount=" + attachCount);
            logLine("  All extras: " + extras.toString().trim());

            if (granted && verified) {
                phase = GRANTED;
                logLine("SUCCESS: USB permission granted on attempt " + attempts);
            } else if (attempts >= MAX_RETRIES) {
                phase = FAILED;
                logLine("FAILED after " + MAX_RETRIES + " attempts.");
                if (device != null) {
                    tryDirectGrant(device);
                }
            } else {
                logLine("Denied. detachCount=" + detachCount + " (0 = NOT re-enumeration)."
                    + " Resetting stability timer...");
                phase = WAITING;
                targetPath = null;
            }
            updateStatus();
        }
    };

    private void updateStatus() {
        switch (phase) {
            case WAITING:
                statusView.setText("Waiting for phone...");
                statusView.setTextColor(Color.WHITE);
                if (attempts > 0) {
                    detailView.setText("Attempt " + attempts + " denied. Watching for phone...\n"
                        + "detach events: " + detachCount);
                } else {
                    detailView.setText("Plug your phone into the car USB.\n"
                        + "USB mode must be 'Car Play' (set in Diagnostics).");
                }
                break;
            case STABILIZING:
                statusView.setText("Phone detected");
                statusView.setTextColor(Color.YELLOW);
                detailView.setText("Waiting for stable connection...\nPath: " + targetPath);
                break;
            case REQUESTING:
                statusView.setText("DIALOG OPEN");
                statusView.setTextColor(Color.rgb(80, 180, 255));
                detailView.setText("Permission dialog should be visible.\n"
                    + "ADB auto-tap or press OK on screen.\n"
                    + "Attempt " + attempts + " of " + MAX_RETRIES);
                break;
            case GRANTED:
                statusView.setText("GRANTED");
                statusView.setTextColor(Color.rgb(50, 255, 50));
                detailView.setText("USB permission acquired in " + attempts + " attempt(s).\n"
                    + "You can return to Honda Home.");
                break;
            case FAILED:
                statusView.setText("FAILED");
                statusView.setTextColor(Color.RED);
                detailView.setText("Could not get USB permission after " + MAX_RETRIES
                    + " attempts.\ndetach events: " + detachCount
                    + "\nConnect ADB for logs.");
                break;
        }
    }

    private void logLine(String msg) {
        long mono = SystemClock.elapsedRealtime();
        String line = mono + " " + msg;
        Log.i(TAG, line);
        logBuffer.append(line).append('\n');
        if (logView != null) {
            logView.setText(logBuffer.toString());
            logScroll.post(new Runnable() {
                @Override
                public void run() { logScroll.fullScroll(ScrollView.FOCUS_DOWN); }
            });
        }
        if (logFile != null) {
            try {
                logFile.write((line + "\n").getBytes("UTF-8"));
                logFile.flush();
            } catch (IOException ignored) { }
        }
    }

    @Override
    public void onDestroy() {
        handler.removeCallbacksAndMessages(null);
        if (receiverRegistered) {
            try { unregisterReceiver(resultReceiver); } catch (Exception ignored) { }
            receiverRegistered = false;
        }
        if (detachReceiverRegistered) {
            try { unregisterReceiver(usbEventReceiver); } catch (Exception ignored) { }
            detachReceiverRegistered = false;
        }
        logLine("=== Session ended ===");
        if (logFile != null) {
            try { logFile.close(); } catch (IOException ignored) { }
            logFile = null;
        }
        super.onDestroy();
    }
}
