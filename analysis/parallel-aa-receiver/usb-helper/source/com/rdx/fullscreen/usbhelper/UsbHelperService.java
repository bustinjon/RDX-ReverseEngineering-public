package com.rdx.fullscreen.usbhelper;

import android.app.PendingIntent;
import android.app.Service;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.graphics.Color;
import android.graphics.PixelFormat;
import android.hardware.usb.UsbDevice;
import android.hardware.usb.UsbDeviceConnection;
import android.hardware.usb.UsbManager;
import android.os.Bundle;
import android.os.Handler;
import android.os.IBinder;
import android.os.SystemClock;
import android.util.Log;
import android.view.Gravity;
import android.view.View;
import android.view.WindowManager;
import android.widget.TextView;

import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.net.LocalSocket;
import android.net.LocalSocketAddress;
import java.io.IOException;
import java.lang.reflect.Method;
import java.util.HashMap;
import java.util.Set;

import com.rdx.fullscreen.projection.UsbBulkTransport;

/**
 * Headless USB permission service. Not blocked by Lock Task Mode.
 * Shows a passthrough overlay during permission requests to guide taps
 * through Honda's AA UI to the system permission dialog underneath.
 */
public final class UsbHelperService extends Service {
    private static final String TAG = "RDX.USB";
    private static final long STABLE_MS = 1000;
    private static final int MAX_RETRIES = 15;
    private static final long POLL_MS = 500;

    private static final int WAITING = 0, STABILIZING = 1, REQUESTING = 2, GRANTED = 3, FAILED = 4;

    private UsbManager usbManager;
    private WindowManager wm;
    private Handler handler;

    private int phase = WAITING;
    private long targetStableSince;
    private String targetPath;
    private boolean targetIsAoap;
    private int attempts;
    private boolean receiverRegistered;
    private boolean detachReceiverRegistered;
    private int detachCount;
    private int attachCount;
    private boolean forceStopSucceeded;
    private HondaPhonePolicy phonePolicy;
    private boolean startupInitialized;
    private boolean aoapSwitchSent;
    private long aoapSwitchTime;

    private View permissionOverlay;

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
                log("*** USB_DEVICE_DETACHED #" + detachCount + " path=" + path
                    + " vid=" + Integer.toHexString(vid) + " pid=" + Integer.toHexString(pid));
            } else if ("android.hardware.usb.action.USB_DEVICE_ATTACHED".equals(action)) {
                attachCount++;
                log("*** USB_DEVICE_ATTACHED #" + attachCount + " path=" + path
                    + " vid=" + Integer.toHexString(vid) + " pid=" + Integer.toHexString(pid));
            }
        }
    };

    @Override
    public void onCreate() {
        super.onCreate();
        usbManager = (UsbManager) getSystemService(USB_SERVICE);
        wm = (WindowManager) getSystemService(WINDOW_SERVICE);
        handler = new Handler();

        IntentFilter usbFilter = new IntentFilter();
        usbFilter.addAction("android.hardware.usb.action.USB_DEVICE_DETACHED");
        usbFilter.addAction("android.hardware.usb.action.USB_DEVICE_ATTACHED");
        registerReceiver(usbEventReceiver, usbFilter);
        detachReceiverRegistered = true;

        log("=== Service started v5 uid=" + android.os.Process.myUid()
            + " pid=" + android.os.Process.myPid() + " ===");
        log("Transport: writeTimeout=30s retries=10+halt-clear readDeadline=30s drain=yes settle=500ms");

        // Read before any USB/startup side effects, including sticky/null-intent restarts.
        phonePolicy = new HondaPhonePolicy(getSharedPreferences("honda_phone_policy", MODE_PRIVATE)
            .getString("phoneSerial", null));
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        String action = intent != null ? intent.getAction() : null;
        log("onStartCommand phase=" + phase + " action=" + action);

        if ("usb.CONFIGURE_HONDA_NEVER".equals(action) || "usb.CONFIGURE_LEGACY".equals(action)) {
            if (startupInitialized) {
                log("POLICY_REJECTED: stop the helper service before changing policy");
                return START_STICKY;
            }
            String serial = "usb.CONFIGURE_HONDA_NEVER".equals(action)
                ? intent.getStringExtra("phoneSerial") : null;
            if ("usb.CONFIGURE_HONDA_NEVER".equals(action) && !HondaPhonePolicy.isValidSerial(serial)) {
                log("POLICY_REJECTED: explicit valid phoneSerial required");
                stopSelf();
                return START_NOT_STICKY;
            }
            boolean saved = getSharedPreferences("honda_phone_policy", MODE_PRIVATE).edit()
                .putString("phoneSerial", serial).commit();
            if (!saved) {
                log("POLICY_REJECTED: configuration was not persisted");
                stopSelf();
                return START_NOT_STICKY;
            }
            phonePolicy = new HondaPhonePolicy(serial);
        }
        if (!startupInitialized) {
            startupInitialized = true;
            if (phonePolicy.isCooperative()) {
                log("HONDA_PHONE_NEVER_V1: phone-scoped policy loaded; Honda preference is operator asserted");
            } else {
                tryForceStopHonda();
                tryVbusReset("VBUS_DATA_RESET");
            }
            handler.post(pollRunnable);
        }

        if ("usb.HONDA_STOPPED".equals(action)) {
            if (phonePolicy.isCooperative()) {
                log("HONDA_STOPPED ignored in cooperative mode");
                return START_STICKY;
            }
            if (!forceStopSucceeded) {
                forceStopSucceeded = true;
                log("HONDA_STOPPED: user confirmed Honda is force-stopped — Path A active");
            }
            return START_STICKY;
        }

        if ("usb.device.AUTO_GRANTED".equals(action)) {
            UsbDevice device = intent.getParcelableExtra(UsbManager.EXTRA_DEVICE);
            if (device != null && !policyAllows(device)) {
                log("POLICY_REJECTED: attached device identity does not match configured phone");
                return START_STICKY;
            }
            if (device != null && usbManager.hasPermission(device)) {
                if (UsbBulkTransport.isAllowedPhone(device)) {
                    if (phase == GRANTED) {
                        log("AUTO_GRANTED: AOAP device " + device.getDeviceName()
                            + " — session already started, ignoring");
                        return START_STICKY;
                    }
                    log("AUTO_GRANTED: AOAP device " + device.getDeviceName());
                    phase = GRANTED;
                    removePermissionOverlay();
                    startAaSession(device);
                } else if (isNonAoapPhone(device) && rawPolicyAllows(device)) {
                    log("AUTO_GRANTED: non-AOAP phone " + device.getDeviceName()
                        + " vid=" + Integer.toHexString(device.getVendorId())
                        + " — switching to AOAP mode");
                    if (switchToAoap(device)) {
                        phase = WAITING;
                        targetPath = null;
                        aoapSwitchSent = true;
                        aoapSwitchTime = SystemClock.elapsedRealtime();
                    } else {
                        log("AOAP switch failed — staying in poll mode");
                    }
                } else {
                    log("AUTO_GRANTED: unknown device vid="
                        + Integer.toHexString(device.getVendorId()) + " — ignoring");
                }
                return START_STICKY;
            } else {
                log("AUTO_GRANTED: but hasPermission=false, falling back to poll/request");
            }
        }

        return START_STICKY;
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
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
            log("ERROR getDeviceList: " + e);
            return;
        }

        UsbDevice target = null;
        targetIsAoap = false;
        for (UsbDevice d : devices.values()) {
            if (UsbBulkTransport.isAllowedPhone(d) && policyAllows(d)) {
                target = d;
                targetIsAoap = true;
                break;
            }
        }
        if (target == null && !aoapSwitchSent) {
            for (UsbDevice d : devices.values()) {
                if (isNonAoapPhone(d) && rawPolicyAllows(d)) {
                    target = d;
                    targetIsAoap = false;
                    break;
                }
            }
        }

        long now = SystemClock.elapsedRealtime();

        if (target == null) {
            if (aoapSwitchSent && (now - aoapSwitchTime) > 10000) {
                log("AOAP switch timeout — phone did not re-enumerate in 10s, resetting");
                aoapSwitchSent = false;
            }
            if (phase == STABILIZING) {
                log("Device disconnected during stabilization");
                phase = WAITING;
                targetPath = null;
            } else if (phase == REQUESTING) {
                log("Device disconnected while permission request pending");
            }
            return;
        }

        String path = target.getDeviceName();

        if (phase == WAITING) {
            targetStableSince = now;
            targetPath = path;
            phase = STABILIZING;
            log((targetIsAoap ? "AOAP" : "Non-AOAP") + " device detected: vid="
                + Integer.toHexString(target.getVendorId())
                + " pid=" + Integer.toHexString(target.getProductId())
                + " path=" + path);
            return;
        }

        if (phase == STABILIZING) {
            if (!path.equals(targetPath)) {
                log("Re-enumeration detected: " + targetPath + " -> " + path);
                targetStableSince = now;
                targetPath = path;
                return;
            }
            long stable = now - targetStableSince;
            if (stable >= STABLE_MS) {
                if (usbManager.hasPermission(target)) {
                    if (targetIsAoap) {
                        phase = GRANTED;
                        log("Already has permission for AOAP " + path);
                        startAaSession(target);
                    } else {
                        log("Already has permission for non-AOAP " + path + " — AOAP switch");
                        if (switchToAoap(target)) {
                            phase = WAITING;
                            targetPath = null;
                            aoapSwitchSent = true;
                            aoapSwitchTime = SystemClock.elapsedRealtime();
                        } else {
                            log("AOAP switch failed — continuing poll");
                        }
                    }
                    return;
                }
                attempts++;
                log("Connection stable " + stable + "ms. Requesting permission (attempt "
                    + attempts + "/" + MAX_RETRIES + ") for " + path
                    + " detachCount=" + detachCount + " attachCount=" + attachCount);
                doRequest(target);
            }
        }
    }

    private void showPermissionOverlay() {
        if (permissionOverlay != null) return;

        TextView tv = new TextView(this);
        tv.setText("\n\n\n     >>> TAP 'OK' ON THE PERMISSION DIALOG <<<\n\n"
            + "     A USB permission dialog is behind this overlay.\n"
            + "     Your taps pass through to it.\n\n"
            + "     Tap the RIGHT side of the center of the screen.\n\n"
            + "     Attempt " + attempts + " of " + MAX_RETRIES);
        tv.setTextColor(Color.WHITE);
        tv.setTextSize(20);
        tv.setBackgroundColor(Color.argb(180, 0, 0, 0));
        tv.setPadding(40, 0, 40, 0);

        WindowManager.LayoutParams params = new WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.TYPE_SYSTEM_ERROR,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
                | WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE
                | WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        );
        params.gravity = Gravity.TOP | Gravity.LEFT;

        try {
            wm.addView(tv, params);
            permissionOverlay = tv;
            log("Permission assist overlay shown (FLAG_NOT_TOUCHABLE — taps pass through)");
        } catch (Exception e) {
            log("Failed to show permission overlay: " + e);
        }
    }

    private void removePermissionOverlay() {
        if (permissionOverlay != null) {
            try { wm.removeView(permissionOverlay); } catch (Exception ignored) {}
            permissionOverlay = null;
            log("Permission assist overlay removed");
        }
    }

    private void doRequest(UsbDevice device) {
        if (!policyAllows(device)) { log("POLICY_REJECTED: permission request identity"); return; }
        phase = REQUESTING;

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

        showPermissionOverlay();
        log("Calling UsbManager.requestPermission for " + device.getDeviceName());
        usbManager.requestPermission(device, pi);
        log("requestPermission returned; overlay guides tap to OK button");
    }

    private void tryDirectGrant(UsbDevice device) {
        log("Attempting direct grantDevicePermission via reflection...");
        try {
            Class<?> smClass = Class.forName("android.os.ServiceManager");
            Method getService = smClass.getMethod("getService", String.class);
            android.os.IBinder binder = (android.os.IBinder) getService.invoke(null, "usb");
            if (binder == null) {
                log("  ServiceManager.getService('usb') returned null");
                return;
            }
            Class<?> stubClass = Class.forName("android.hardware.usb.IUsbManager$Stub");
            Method asInterface = stubClass.getMethod("asInterface", android.os.IBinder.class);
            Object service = asInterface.invoke(null, binder);

            Method grant = service.getClass().getMethod("grantDevicePermission",
                UsbDevice.class, int.class);
            grant.invoke(service, device, android.os.Process.myUid());
            log("  grantDevicePermission call returned (no exception!)");

            if (usbManager.hasPermission(device)) {
                log("  DIRECT GRANT SUCCEEDED — hasPermission=true");
                phase = GRANTED;
            } else {
                log("  Call returned but hasPermission still false");
            }
        } catch (Exception e) {
            log("  Direct grant failed: " + e.getClass().getSimpleName() + ": " + e.getMessage());
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
            if (device != null && !policyAllows(device)) {
                log("POLICY_REJECTED: permission callback identity");
                phase = WAITING;
                targetPath = null;
                removePermissionOverlay();
                return;
            }
            boolean verified = device != null && usbManager.hasPermission(device);

            StringBuilder extras = new StringBuilder();
            Bundle b = intent.getExtras();
            if (b != null) {
                Set<String> keys = b.keySet();
                for (String key : keys) {
                    extras.append(key).append("=").append(b.get(key)).append(" ");
                }
            }
            log("Permission callback: granted=" + granted + " verified=" + verified
                + (device != null ? " path=" + device.getDeviceName() : " device=null")
                + " detachCount=" + detachCount + " attachCount=" + attachCount);
            log("  All extras: " + extras.toString().trim());

            if (granted && verified) {
                removePermissionOverlay();
                if (UsbBulkTransport.isAllowedPhone(device)) {
                    phase = GRANTED;
                    log("SUCCESS: USB permission for AOAP device on attempt " + attempts);
                    startAaSession(device);
                } else if (isNonAoapPhone(device) && rawPolicyAllows(device)) {
                    log("SUCCESS: USB permission for non-AOAP phone on attempt " + attempts);
                    if (switchToAoap(device)) {
                        phase = WAITING;
                        targetPath = null;
                        aoapSwitchSent = true;
                        aoapSwitchTime = SystemClock.elapsedRealtime();
                    } else {
                        log("AOAP switch failed after permission grant");
                        phase = WAITING;
                    }
                } else {
                    log("Permission granted but " + (isNonAoapPhone(device)
                        ? "Honda not stopped — AOAP switch skipped" : "unknown device") + " — ignoring");
                    phase = WAITING;
                }
            } else if (attempts >= MAX_RETRIES) {
                removePermissionOverlay();
                phase = FAILED;
                log("FAILED after " + MAX_RETRIES + " attempts.");
                if (device != null && !phonePolicy.isCooperative()) {
                    tryDirectGrant(device);
                }
            } else {
                removePermissionOverlay();
                log("Denied (attempt " + attempts + "). Retrying faster...");
                phase = WAITING;
                targetPath = null;
            }
        }
    };

    private void startAaSession(UsbDevice device) {
        if (!policyAllows(device)) { log("POLICY_REJECTED: session identity"); return; }
        log("Handing off to AaSessionService...");
        Intent sessionIntent = new Intent(this, AaSessionService.class);
        sessionIntent.setAction("aa.session.START");
        sessionIntent.putExtra(UsbManager.EXTRA_DEVICE, device);
        startService(sessionIntent);
    }

    private void tryForceStopHonda() {
        String pkg = "com.honda.androidauto.projection.sink";
        log("Attempting am force-stop " + pkg + "...");
        try {
            Process p = Runtime.getRuntime().exec(new String[]{
                "am", "force-stop", pkg});
            int rc = p.waitFor();
            if (rc == 0) {
                forceStopSucceeded = true;
                log("force-stop Honda: SUCCESS from app (rc=0)");
                return;
            }
            log("force-stop Honda: rc=" + rc + " (app likely lacks FORCE_STOP_PACKAGES)");
        } catch (Exception e) {
            log("force-stop Honda: EXCEPTION " + e.getMessage());
        }
        // Fallback: check if Honda was already stopped (user ran force-stop from ADB shell)
        try {
            ApplicationInfo info = getPackageManager().getApplicationInfo(pkg, 0);
            boolean stopped = (info.flags & ApplicationInfo.FLAG_STOPPED) != 0;
            forceStopSucceeded = stopped;
            log("Honda FLAG_STOPPED=" + stopped
                + (stopped ? " (Path A: user force-stopped from ADB)" : " (Path B: Honda active)"));
        } catch (PackageManager.NameNotFoundException e) {
            forceStopSucceeded = true;
            log("Honda package not found — no race possible (Path A)");
        }
    }

    static boolean isNonAoapPhone(UsbDevice device) {
        return device.getVendorId() == 0x22d9;
    }

    private boolean policyAllows(UsbDevice device) {
        if (!phonePolicy.isCooperative()) return true;
        try { return phonePolicy.allows(device.getSerialNumber()); }
        catch (RuntimeException e) { return false; }
    }

    private boolean rawPolicyAllows(UsbDevice device) {
        try {
            return phonePolicy.allowsRaw(forceStopSucceeded,
                phonePolicy.isCooperative() ? device.getSerialNumber() : null);
        } catch (RuntimeException e) { return false; }
    }

    private boolean switchToAoap(UsbDevice device) {
        if (!rawPolicyAllows(device)) { log("POLICY_REJECTED: AOAP switch identity"); return false; }
        log("AOAP mode switch: opening " + device.getDeviceName()
            + " vid=" + Integer.toHexString(device.getVendorId())
            + " pid=" + Integer.toHexString(device.getProductId()));
        UsbDeviceConnection conn = usbManager.openDevice(device);
        if (conn == null) {
            log("AOAP switch: openDevice failed");
            return false;
        }
        try {
            byte[] buf = new byte[2];
            int r = conn.controlTransfer(0xC0, 51, 0, 0, buf, 2, 10000);
            if (r != 2) {
                log("AOAP switch: GET_PROTOCOL failed r=" + r);
                return false;
            }
            int ver = (buf[0] & 0xFF) + ((buf[1] & 0xFF) << 8);
            log("AOAP switch: protocol version=" + ver);
            if (ver < 1) {
                log("AOAP switch: device does not support AOAP (version " + ver + ")");
                return false;
            }
            String[] strings = {"Android", "Android Auto", "Android Auto",
                                "1.0", "http://www.android.com/auto", "0000000012345678"};
            String[] labels = {"manufacturer", "model", "description",
                               "version", "URI", "serial"};
            for (int i = 0; i < strings.length; i++) {
                byte[] strBytes = strings[i].getBytes("UTF-8");
                r = conn.controlTransfer(0x40, 52, 0, i, strBytes, strBytes.length, 10000);
                log("AOAP SEND_STRING[" + i + " " + labels[i] + "]=\""
                    + strings[i] + "\" r=" + r + " expected=" + strBytes.length);
                if (r != strBytes.length) {
                    log("AOAP switch: SEND_STRING incomplete at index " + i
                        + " (got " + r + ", expected " + strBytes.length + ")");
                    return false;
                }
            }
            r = conn.controlTransfer(0x40, 53, 0, 0, null, 0, 10000);
            log("AOAP START_ACCESSORY r=" + r);
            if (r < 0) {
                log("AOAP switch: START_ACCESSORY failed");
                return false;
            }
            log("AOAP switch complete — phone will re-enumerate as vid=18d1 pid=2d00/2d01");
            return true;
        } catch (Exception e) {
            log("AOAP switch: " + e.getClass().getSimpleName() + ": " + e.getMessage());
            return false;
        } finally {
            conn.close();
        }
    }

    /**
     * Try Honda's VBUS reset via their local socket. Causes USB power cycle
     * → phone re-enumerates → clean AOAP session possible.
     * May fail if socket permissions restrict third-party apps.
     */
    private boolean tryVbusReset(String command) {
        log("Attempting VBUS reset via GAL socket: " + command);
        LocalSocket socket = new LocalSocket();
        try {
            LocalSocketAddress addr = new LocalSocketAddress(
                "/data/misc/gal/socket", LocalSocketAddress.Namespace.FILESYSTEM);
            socket.connect(addr);
            socket.setReceiveBufferSize(256);
            socket.setSendBufferSize(256);
            byte[] cmdBytes = command.getBytes();
            socket.getOutputStream().write(cmdBytes.length);
            socket.getOutputStream().write(cmdBytes);
            byte[] buf = new byte[256];
            int n = socket.getInputStream().read(buf);
            if (n > 0) {
                String response = new String(buf, 0, n > 0 && buf[n-1] == 0 ? n - 1 : n);
                log("VBUS reset response: '" + response + "'");
                return "OK".equalsIgnoreCase(response.trim());
            }
            log("VBUS reset: no response");
            return false;
        } catch (IOException e) {
            log("VBUS reset failed (socket access denied?): " + e.getMessage());
            return false;
        } finally {
            try { socket.close(); } catch (IOException ignored) {}
        }
    }

    private void log(String msg) {
        long mono = SystemClock.elapsedRealtime();
        Log.i(TAG, mono + " " + msg);
    }

    @Override
    public void onDestroy() {
        handler.removeCallbacksAndMessages(null);
        removePermissionOverlay();
        if (receiverRegistered) {
            try { unregisterReceiver(resultReceiver); } catch (Exception ignored) { }
        }
        if (detachReceiverRegistered) {
            try { unregisterReceiver(usbEventReceiver); } catch (Exception ignored) { }
        }
        log("=== Service stopped ===");
        super.onDestroy();
    }
}
