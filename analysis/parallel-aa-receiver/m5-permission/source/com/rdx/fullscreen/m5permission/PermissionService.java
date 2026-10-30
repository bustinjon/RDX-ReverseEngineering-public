package com.rdx.fullscreen.m5permission;

import android.app.PendingIntent;
import android.app.Service;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.hardware.usb.UsbDevice;
import android.hardware.usb.UsbManager;
import android.os.Handler;
import android.os.IBinder;
import android.os.SystemClock;
import android.util.Base64;
import android.util.Log;
import java.io.IOException;
import java.security.MessageDigest;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

/** Explicitly armed, permission-only API22 adapter; no device handle or transport. */
public final class PermissionService extends Service {
    private static final String TAG = "RDX.M5";
    private final Handler handler = new Handler();
    private PermissionMachine machine;
    private PrivateJournal.Session journal;
    private UsbManager manager;
    private Map<String, UsbDevice> inventory;
    private String nonce, callbackAction, runId;
    private PendingIntent pending;
    private boolean receiverRegistered, armConsumed;

    private void record(String message) throws IOException {
        journal.record(message); // Persist+sync before reporting success or proceeding.
        Log.i(TAG, "run=" + runId + " " + message);
    }
    private final BroadcastReceiver result = new BroadcastReceiver() {
        @Override public void onReceive(Context context, Intent intent) {
            if (machine == null || machine.terminal() || intent == null ||
                !callbackAction.equals(intent.getAction())) return;
            try {
                UsbDevice returned = (UsbDevice) intent.getParcelableExtra(UsbManager.EXTRA_DEVICE);
                PermissionMachine.Device identity = returned == null ? null : describe(returned);
                boolean granted = intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false);
                boolean verified = identity != null && identity.permission;
                machine.callback(SystemClock.elapsedRealtime(), System.currentTimeMillis(),
                    intent.getStringExtra("request_nonce"), identity, granted, verified);
            } catch (RuntimeException error) { machine.fail("callback exception=" + error.toString()); }
            if (machine.terminal()) stopSelf();
        }
    };
    private PermissionMachine.Device describe(UsbDevice device) {
        return new PermissionMachine.Device(device.getDeviceName(), device.getVendorId(),
            device.getProductId(), manager.hasPermission(device));
    }
    private final Runnable pump = new Runnable() {
        @Override public void run() {
            if (machine == null || machine.terminal()) return;
            machine.timeAdvanced(SystemClock.elapsedRealtime(), System.currentTimeMillis());
            if (!machine.terminal()) try {
                HashMap<String, UsbDevice> devices = manager.getDeviceList();
                if (devices == null || devices.size() > PermissionMachine.MAX_DEVICES)
                    throw new IllegalStateException("Inventory unavailable/over bound");
                inventory = devices;
                PermissionMachine.Device[] snapshot = new PermissionMachine.Device[devices.size()];
                int index = 0;
                for (UsbDevice device : devices.values()) snapshot[index++] = describe(device);
                machine.snapshot(SystemClock.elapsedRealtime(), System.currentTimeMillis(), snapshot);
            } catch (RuntimeException error) { machine.fail("inventory exception=" + error.toString()); }
            if (machine.terminal()) stopSelf();
            else handler.postDelayed(this, Math.max(1L, Math.min(1000L, machine.remaining(SystemClock.elapsedRealtime()))));
        }
    };
    private void requestOnce(PermissionMachine.Device identity) throws Exception {
        UsbDevice device = inventory.get(identity.path);
        if (device == null || !identity.same(describe(device)))
            throw new IllegalStateException("Pinned target changed before permission request");
        callbackAction = getPackageName() + ".RESULT." + nonce;
        registerReceiver(result, new IntentFilter(callbackAction)); receiverRegistered = true;
        Intent callback = new Intent(callbackAction).setPackage(getPackageName())
            .putExtra("request_nonce", nonce);
        pending = PendingIntent.getBroadcast(this, 1, callback,
            PendingIntent.FLAG_ONE_SHOT | PendingIntent.FLAG_CANCEL_CURRENT);
        record("wallMs=" + System.currentTimeMillis() + " monoMs=" + SystemClock.elapsedRealtime() +
            " state=" + machine.state() + " event=REQUEST_API_INVOKING " + identity.describe() +
            " requestReserved=true callbackReceived=false; invocation intent, not return evidence");
        // Journal/receiver preparation may take time. Recheck the monotonic deadline at the SDK boundary.
        if (machine.remaining(SystemClock.elapsedRealtime()) == 0) {
            machine.timeAdvanced(SystemClock.elapsedRealtime(), System.currentTimeMillis());
            throw new IllegalStateException("Deadline reached before SDK request");
        }
        manager.requestPermission(device, pending); // ONLY production SDK request callsite.
        record("wallMs=" + System.currentTimeMillis() + " monoMs=" + SystemClock.elapsedRealtime() +
            " state=" + machine.state() + " event=REQUEST_API_RETURNED; no open or transfer follows");
    }
    @Override public IBinder onBind(Intent intent) { return null; }
    @Override public int onStartCommand(Intent intent, int flags, int startId) {
        if (machine != null && !machine.terminal()) {
            Log.w(TAG, "Active run; duplicate start/dump ignored"); return START_NOT_STICKY;
        }
        if (intent != null && ("DUMP_RESULTS".equals(intent.getAction()) || "LIST_RESULTS".equals(intent.getAction()))) {
            dump(intent); stopSelf(); return START_NOT_STICKY;
        }
        if (armConsumed) { stopSelf(); return START_NOT_STICKY; }
        if (intent == null || !"REQUEST_ONCE_AFTER_M4_PASS".equals(intent.getAction()) ||
            !intent.getBooleanExtra("m4_pass_confirmed", false) ||
            !intent.getBooleanExtra("wait_for_target", false) ||
            intent.getIntExtra("vendor_id", -1) != PermissionMachine.VID ||
            intent.getIntExtra("product_id", -1) != PermissionMachine.PID) {
            Log.w(TAG, "REFUSED: explicit M4/action/exact target gates required");
            stopSelf(); return START_NOT_STICKY;
        }
        armConsumed = true;
        try {
            runId = intent.getStringExtra("run_id");
            journal = new PrivateJournal(getFilesDir()).create(runId);
            record("wallMs=" + System.currentTimeMillis() + " monoMs=" + SystemClock.elapsedRealtime() +
                " state=IDLE event=SERVICE_START uid=" + android.os.Process.myUid() +
                " pid=" + android.os.Process.myPid() + " target=18D1:2D01" +
                " nativeLibraryDir=" + getApplicationInfo().nativeLibraryDir);
            manager = (UsbManager) getSystemService(USB_SERVICE);
            if (manager == null) throw new IllegalStateException("USB service absent");
            nonce = UUID.randomUUID().toString();
            machine = new PermissionMachine(new PermissionMachine.Evidence() {
                public void record(String line) throws IOException { PermissionService.this.record(line); }
            }, new PermissionMachine.PermissionRequester() {
                public void request(PermissionMachine.Device device) throws Exception { requestOnce(device); }
            });
            machine.arm(SystemClock.elapsedRealtime(), System.currentTimeMillis(), nonce);
            if (machine.terminal()) stopSelf(); else handler.post(pump);
        } catch (Exception error) {
            Log.e(TAG, "REFUSED/ERROR; no replay or retry", error);
            if (machine != null) machine.fail(error.toString());
            stopSelf();
        }
        return START_NOT_STICKY;
    }
    private void dump(Intent intent) {
        // Explicit local-file dump only. Never obtains UsbManager or arms a machine.
        try {
            PrivateJournal store = new PrivateJournal(getFilesDir());
            if ("LIST_RESULTS".equals(intent.getAction())) {
                for (String name : store.list()) Log.i(TAG, "SAVED_RESULT " + name);
                return;
            }
            String id = intent.getStringExtra("run_id");
            byte[] bytes = store.read(id);
            String token = UUID.randomUUID().toString();
            byte[] digest = MessageDigest.getInstance("SHA-256").digest(bytes);
            StringBuilder hex = new StringBuilder();
            for (byte value : digest) {
                hex.append("0123456789abcdef".charAt((value & 255) >>> 4));
                hex.append("0123456789abcdef".charAt(value & 15));
            }
            Log.i(TAG, "DUMP_BEGIN token=" + token + " run=" + id + " bytes=" + bytes.length + " sha256=" + hex);
            int index = 0;
            for (int offset = 0; offset < bytes.length; offset += 1200) {
                int length = Math.min(1200, bytes.length - offset);
                Log.i(TAG, "DUMP_CHUNK token=" + token + " index=" + index++ + " base64=" +
                    Base64.encodeToString(bytes, offset, length, Base64.NO_WRAP));
            }
            Log.i(TAG, "DUMP_END token=" + token + " chunks=" + index);
        } catch (Exception error) { Log.e(TAG, "DUMP_FAILED; prior private evidence not altered", error); }
    }
    @Override public void onDestroy() {
        handler.removeCallbacksAndMessages(null);
        if (machine != null) machine.stop(SystemClock.elapsedRealtime(), System.currentTimeMillis());
        if (pending != null) pending.cancel();
        if (receiverRegistered) { unregisterReceiver(result); receiverRegistered = false; }
        if (journal != null) {
            try {
                record("wallMs=" + System.currentTimeMillis() + " monoMs=" + SystemClock.elapsedRealtime() +
                    " state=" + (machine == null ? "ERROR" : machine.state()) + " event=SERVICE_END; no replay");
                journal.close();
            } catch (IOException error) { Log.e(TAG, "Evidence close/write error", error);
                try { journal.close(); } catch (IOException ignored) { /* no retry */ }
            }
            journal = null;
        }
        super.onDestroy();
    }
}
