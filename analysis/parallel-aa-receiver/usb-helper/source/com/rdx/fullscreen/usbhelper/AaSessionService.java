package com.rdx.fullscreen.usbhelper;

import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.hardware.usb.UsbDevice;
import android.hardware.usb.UsbManager;
import android.os.Handler;
import android.os.IBinder;
import android.os.SystemClock;
import android.util.Log;
import android.view.Surface;

import com.google.android.projection.protocol.AudioSink;
import com.google.android.projection.protocol.AudioSource;
import com.google.android.projection.protocol.GalReceiver;
import com.google.android.projection.protocol.InputSource;
import com.google.android.projection.protocol.SensorSource;
import com.google.android.projection.protocol.VideoSink;
import com.google.android.projection.common.BufferPool;
import com.rdx.fullscreen.projection.VideoDecoder;
import com.rdx.fullscreen.projection.UsbBulkTransport;

import java.io.DataInputStream;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * AA session coordinator. Wires:
 *   UsbHelperService (USB permission) → AaOverlayService (Surface + touch)
 *   → GalReceiver + VideoSink + InputSource + VideoDecoder + UsbBulkTransport
 *
 * Lifecycle: phone plugs in → USB permission → overlay → Surface ready →
 *   protocol init → transport threads → video plays → phone unplugs → cleanup
 */
public final class AaSessionService extends Service
        implements GalReceiver.Listener, VideoSink.Listener, VideoDecoder.Listener,
                   AaOverlayService.SurfaceReadyListener, AaOverlayService.TouchListener {

    private static final String TAG = "RDX.SESSION";
    private static final int DPI = 229;

    private Handler handler;
    private UsbManager usbManager;

    // Protocol stack
    private GalReceiver receiver;
    private VideoSink videoSink;
    private InputSource inputSource;
    private AudioSink audioSinkMedia, audioSinkGuidance;
    private AudioSource audioSource;
    private SensorSource sensorSource;
    private NightModeWatcher nightModeWatcher;
    private VideoDecoder decoder;
    private UsbBulkTransport transport;

    // Threads
    private Thread readerThread, writerThread, pingThread;
    private final AtomicBoolean stopping = new AtomicBoolean(false);
    private volatile boolean running;
    private boolean selected, firstFrame;

    // State
    private UsbDevice pendingDevice;
    private boolean protocolInitialized;
    private boolean sessionActive;

    @Override
    public void onCreate() {
        super.onCreate();
        usbManager = (UsbManager) getSystemService(USB_SERVICE);
        handler = new Handler();
        log("AaSessionService created");
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        String action = intent != null ? intent.getAction() : null;
        log("onStartCommand action=" + action);

        if ("aa.session.START".equals(action)) {
            if (sessionActive) {
                log("Ignoring duplicate START — session already active");
                return START_NOT_STICKY;
            }
            UsbDevice device = intent.getParcelableExtra(UsbManager.EXTRA_DEVICE);
            if (device == null) {
                log("ERROR: START without UsbDevice extra");
                stopSelf();
                return START_NOT_STICKY;
            }
            if (!usbManager.hasPermission(device)) {
                log("ERROR: No USB permission for " + device.getDeviceName());
                stopSelf();
                return START_NOT_STICKY;
            }
            sessionActive = true;
            pendingDevice = device;
            log("USB device ready: " + device.getDeviceName()
                + " vid=" + Integer.toHexString(device.getVendorId())
                + " pid=" + Integer.toHexString(device.getProductId()));
            startOverlay();
            return START_NOT_STICKY;
        }

        if ("aa.session.STOP".equals(action)) {
            shutdown();
            return START_NOT_STICKY;
        }

        if ("aa.session.DIAG".equals(action)) {
            runDiagnostics();
            return START_NOT_STICKY;
        }

        return START_NOT_STICKY;
    }

    private static final long SURFACE_TIMEOUT_MS = 10000;
    private Runnable surfaceTimeoutRunnable;

    private void startOverlay() {
        log("Starting AaOverlayService (VIDEO mode)...");
        Intent overlayIntent = new Intent(this, AaOverlayService.class);
        overlayIntent.setAction("aa.overlay.VIDEO");
        startService(overlayIntent);

        handler.postDelayed(new Runnable() {
            int attempts = 0;
            @Override
            public void run() {
                if (stopping.get()) return;
                AaOverlayService overlay = AaOverlayService.getInstance();
                if (overlay != null) {
                    log("Overlay instance acquired");
                    overlay.setSurfaceReadyListener(AaSessionService.this);
                    overlay.setTouchListener(AaSessionService.this);
                    if (overlay.isSurfaceReady()) {
                        onSurfaceReady(overlay.getVideoSurface(), 1920, 720);
                    } else {
                        surfaceTimeoutRunnable = new Runnable() {
                            @Override public void run() {
                                if (!protocolInitialized && !stopping.get()) {
                                    log("ERROR: Surface not ready after " + SURFACE_TIMEOUT_MS + "ms");
                                    shutdown();
                                }
                            }
                        };
                        handler.postDelayed(surfaceTimeoutRunnable, SURFACE_TIMEOUT_MS);
                    }
                } else if (++attempts < 20) {
                    handler.postDelayed(this, 100);
                } else {
                    log("ERROR: Overlay instance not available after 2s");
                    shutdown();
                }
            }
        }, 100);
    }

    // --- SurfaceReadyListener ---

    @Override
    public void onSurfaceReady(final Surface surface, int width, int height) {
        log("Surface ready: " + width + "x" + height);
        if (pendingDevice == null) {
            log("ERROR: Surface ready but no pending USB device");
            return;
        }
        if (protocolInitialized) {
            log("Protocol already initialized, ignoring duplicate Surface callback");
            return;
        }
        handler.post(new Runnable() {
            @Override
            public void run() {
                initializeProtocol(surface);
            }
        });
    }

    @Override
    public void onSurfaceLost() {
        log("Surface lost — stopping protocol");
        shutdown();
    }

    // --- TouchListener ---
    @Override public void onAaKey(int code, boolean down, long timestampMs) {
        if (running && inputSource != null && InputEvents.key(code)) {
            try { inputSource.sendKey(code,down,timestampMs); }
            catch (Exception e) { log("Key send failed: "+e); }
        }
    }

    @Override
    public void onAaTouch(int action, float rawX, float rawY,
                          float aaX, float aaY, long timestampMs) {
        if (inputSource == null || !running) return;

        // Stock InputSource passes MotionEvent action codes directly (0=DOWN, 1=UP, 2=MOVE)
        if (action != android.view.MotionEvent.ACTION_DOWN
                && action != android.view.MotionEvent.ACTION_UP
                && action != android.view.MotionEvent.ACTION_MOVE) return;

        int x = Math.max(0, Math.min((int) rawX, 1324));
        int y = Math.max(0, Math.min((int) rawY, 719));
        try {
            inputSource.sendTouchPad(action, x, y, timestampMs);
        } catch (Exception e) {
            log("Touch send failed: " + e);
        }
    }

    // --- Diagnostics (no USB device needed) ---

    private void runDiagnostics() {
        log("=== DIAGNOSTICS START ===");

        // Step 1: Native library load
        try {
            System.loadLibrary("autoreceiver_jni");
            log("DIAG [1/5] PASS: libautoreceiver_jni.so loaded");
        } catch (UnsatisfiedLinkError e) {
            log("DIAG [1/5] FAIL: native lib load: " + e.getMessage());
            stopSelf();
            return;
        }

        // Step 2: Credentials
        try {
            String[] creds = loadCredentials();
            log("DIAG [2/5] PASS: credentials loaded, " + creds.length + " entries");
        } catch (Exception e) {
            log("DIAG [2/5] FAIL: credentials: " + e);
            stopSelf();
            return;
        }

        // Step 3: GalReceiver construction
        GalReceiver testReceiver = null;
        try {
            testReceiver = new GalReceiver(this);
            log("DIAG [3/5] PASS: GalReceiver created");
        } catch (Throwable e) {
            log("DIAG [3/5] FAIL: GalReceiver: " + e);
            stopSelf();
            return;
        }

        // Step 4: GalReceiver.initialize with credentials
        try {
            testReceiver.initialize(loadCredentials());
            log("DIAG [4/5] PASS: GalReceiver initialized, handle=" + testReceiver.handle());
        } catch (Throwable e) {
            log("DIAG [4/5] FAIL: GalReceiver.initialize: " + e);
            stopSelf();
            return;
        }

        // Step 5: InputSource construction + initialize
        try {
            InputSource testInput = new InputSource();
            log("DIAG [5a] PASS: InputSource created");
            testInput.initialize(2, testReceiver.handle());
            log("DIAG [5b] PASS: InputSource.initialize(2, handle)");
            testInput.registerTouchPad(1325, 720, 60, 40, true, true);
            log("DIAG [5c] PASS: InputSource.registerTouchPad");
            testInput.destroy();
            log("DIAG [5/5] PASS: InputSource full lifecycle OK");
        } catch (Throwable e) {
            log("DIAG [5/5] FAIL: InputSource: " + e);
        }

        // Cleanup
        try {
            testReceiver.destroy();
        } catch (Throwable ignored) {}

        log("=== DIAGNOSTICS END ===");
        stopSelf();
    }

    // --- Protocol initialization ---

    private void initializeProtocol(Surface surface) {
        if (protocolInitialized) return;
        protocolInitialized = true;
        log("Initializing AA protocol stack...");

        try {
            // Load native library and credentials
            receiver = new GalReceiver(this);
            receiver.initialize(loadCredentials());

            // Video service (ID 1) — 1920x1080 nominal with 360px margin = 1920x720 active
            videoSink = new VideoSink(this);
            videoSink.initialize(receiver.handle(), DPI);
            receiver.register(videoSink);

            // Input service (ID 2) — touchpad 1325x720, 60x40mm
            inputSource = new InputSource();
            inputSource.initialize(2, receiver.handle());
            inputSource.registerTouchPad(1325, 720, 60, 40, true, false);
            receiver.register(inputSource);

            // Sensor service (ID 3) — Honda defaults: 15 sensor types, RAW_GPS_ONLY
            sensorSource = new SensorSource();
            sensorSource.initialize(3, receiver.handle());
            receiver.register(sensorSource);

            // Audio media sink (ID 4) — 48000/16/2, stream=MEDIA(3), codec=PCM(1)
            audioSinkMedia = new AudioSink();
            audioSinkMedia.context(this);
            audioSinkMedia.focusObserver(new AudioSink.FocusObserver(){
                // Our guidance stream ducking our media stream is internal: telling the phone it lost
                // focus made it stop the prompt, which restarted and ducked again (choppy prompts).
                private boolean ownDuck;
                public void changed(final int change){handler.post(new Runnable(){public void run(){
                    if(change==-3 && audioSinkGuidance!=null && audioSinkGuidance.holdsFocus()){ownDuck=true;log("AUDIO_FOCUS_INTERNAL_DUCK not forwarded");return;}
                    if(change==1 && ownDuck){ownDuck=false;log("AUDIO_FOCUS_INTERNAL_RESTORE not forwarded");return;}
                    ownDuck=false;
                    if(running && receiver!=null)receiver.answerAudioFocus(com.google.android.projection.protocol.AudioFocusPolicy.change(change),true);
                }});}
            });
            audioSinkMedia.initialize(4, receiver.handle(), 48000, 16, 2, 3, 1);
            receiver.register(audioSinkMedia);

            // Audio guidance sink (ID 5) — 16000/16/1, stream=GUIDANCE(1), codec=PCM(1)
            audioSinkGuidance = new AudioSink();
            audioSinkGuidance.context(this);
            audioSinkGuidance.initialize(5, receiver.handle(), 16000, 16, 1, 1, 1);
            receiver.register(audioSinkGuidance);
            receiver.audioFocusListener(new GalReceiver.AudioFocusListener(){
                public void request(final int request){handler.post(new Runnable(){public void run(){
                    if(running && receiver!=null && audioSinkMedia!=null)receiver.answerAudioFocus(audioSinkMedia.requestProtocolFocus(request),false);
                }});}
            });

            // Audio source / mic (ID 7) — PCM(1), 16000/16/1
            audioSource = new AudioSource();
            audioSource.initialize(7, receiver.handle(), 1, 16000, 16, 1);
            receiver.register(audioSource);

            // Video decoder — outputs to overlay Surface
            decoder = new VideoDecoder(this);
            decoder.surface(surface);

            log("Protocol stack initialized: receiver + video + input + sensors + 2×audio + mic + decoder");
            log("LOCAL_CONFIG index0 enum3 1920x1080 margins0/360 active1920x720 dpi229 fps60");

            // Open USB transport (force-claims, clears endpoint halts, drains stale data)
            transport = new UsbBulkTransport(usbManager, pendingDevice);
            log("USB transport opened: " + pendingDevice.getDeviceName());

            // Let phone's USB stack settle after we took the interface from Honda
            try { Thread.sleep(500); } catch (InterruptedException ignored) {}
            log("Post-claim settle complete, starting protocol");

            decoder.start();
            receiver.startProtocol();
            running = true;
            sensorSource.reportInitialState();
            final SensorSource nightSink = sensorSource;
            nightModeWatcher = new NightModeWatcher(new NightModeWatcher.Listener() {
                public boolean onNightMode(boolean night) { return nightSink.reportNightMode(night); }
            });
            nightModeWatcher.start();

            readerThread = new Thread(new Runnable() {
                public void run() { readLoop(); }
            }, "RDX-GAL-read");
            writerThread = new Thread(new Runnable() {
                public void run() { writeLoop(); }
            }, "RDX-GAL-write");
            pingThread = new Thread(new Runnable() {
                public void run() { pingLoop(); }
            }, "RDX-GAL-ping");

            readerThread.start();
            writerThread.start();
            pingThread.start();
            log("Transport threads started — waiting for phone handshake (write timeout=30s, retries=10)");

        } catch (Exception e) {
            log("Protocol initialization failed: " + e);
            shutdown();
        }
    }

    private String[] loadCredentials() throws IOException {
        DataInputStream input = new DataInputStream(
            getAssets().open("private-test-material/platform.creds"));
        try {
            String[] result = new String[3];
            for (int i = 0; i < result.length; i++) {
                int length = input.readInt();
                if (length < 1 || length > 32768)
                    throw new IOException("Invalid credential container");
                byte[] data = new byte[length];
                input.readFully(data);
                result[i] = new String(data, "UTF-8");
            }
            return result;
        } finally {
            input.close();
        }
    }

    // --- Transport loops (same pattern as ProjectionSession) ---

    private void readLoop() {
        byte[] data = new byte[65544];
        int frameCount = 0;
        try {
            while (running) {
                transport.readFully(data, 0, 4);
                int length = receiver.remaining(data);
                if (length < 0 || length > data.length - 4)
                    throw new IOException("Invalid GAL frame length=" + length);
                transport.readFully(data, 4, length);
                frameCount++;
                if (frameCount <= 20)
                    log("READ frame#" + frameCount + " len=" + (length + 4)
                        + " hdr=" + String.format("%02x%02x%02x%02x", data[0], data[1], data[2], data[3]));
                receiver.incoming(data, length + 4);
            }
        } catch (Exception e) {
            if (running) {
                log("Transport read ended after " + frameCount + " frames: " + e);
                abortIo();
            }
        }
    }

    private void writeLoop() {
        byte[] data = new byte[65544];
        int frameCount = 0;
        try {
            while (running) {
                int n = receiver.outgoing(data);
                if (n <= 0) break;
                if (n > data.length)
                    throw new IOException("Native output length invalid");
                frameCount++;
                if (frameCount <= 20)
                    log("WRITE frame#" + frameCount + " len=" + n
                        + " hdr=" + String.format("%02x%02x%02x%02x", data[0], data[1], data[2], data[3]));
                transport.write(data, n);
                if (frameCount <= 20)
                    log("WRITE frame#" + frameCount + " sent OK");
            }
        } catch (Exception e) {
            if (running) {
                log("Transport write ended after " + frameCount + " frames: " + e);
                abortIo();
            }
        }
    }

    private void pingLoop() {
        try {
            while (running) {
                Thread.sleep(1000);
                if (running) receiver.ping(SystemClock.elapsedRealtime());
            }
        } catch (Exception e) {
            if (running) log("Ping stopped: " + e);
        }
    }

    private void abortIo() {
        running = false;
        if (transport != null) transport.close();
        if (receiver != null) receiver.prepare();
        handler.post(new Runnable() {
            @Override public void run() { shutdown(); }
        });
    }

    // --- GalReceiver.Listener ---

    @Override
    public void event(String text) { log("GAL: " + text); }

    @Override
    public void discovery() {
        if (!running) return;
        // Defer to handler thread — calling nativeSetVideoFocus from inside
        // nativeQueueIncoming callback may deadlock or silently fail (reentrancy)
        handler.post(new Runnable() {
            public void run() { doRequestVideo("discovery"); }
        });
    }

    private void doRequestVideo(String reason) {
        if (!running) return;
        VideoSink vs = videoSink;
        if (vs != null) {
            log("Requesting video focus (reason=" + reason + ")");
            vs.requestVideo();
            // Retry once if phone doesn't respond in 2 seconds
            if (!selected) {
                handler.postDelayed(new Runnable() {
                    public void run() {
                        if (running && !selected) {
                            doRequestVideo("retry-2s");
                        }
                    }
                }, 2000);
            }
        }
    }

    @Override
    public void byeBye() {
        abortIo();
        log("Phone requested session end");
    }

    // --- VideoSink.Listener ---

    @Override
    public void config(int index, int codecWidth, int codecHeight,
                       int activeWidth, int activeHeight, int dpi) {
        if (!running) return;
        selected = true;
        log("VIDEO SELECTED index=" + index + " codec=" + codecWidth + "x" + codecHeight
            + " active=" + activeWidth + "x" + activeHeight + " dpi=" + dpi);
        VideoDecoder d = decoder;
        if (d != null) d.dimensions(codecWidth, codecHeight);
        AaOverlayService overlay = AaOverlayService.getInstance();
        if (overlay != null) overlay.setVideoGeometry(codecWidth, codecHeight, activeWidth, activeHeight);
    }

    @Override
    public void codecConfig(byte[] data) {
        if (!running) return;
        VideoDecoder d = decoder;
        if (d != null) d.config(data);
        log("Codec configuration received");
    }

    @Override
    public void codecSetup() {
        log("Video codec setup callback");
    }

    @Override
    public void frame(int session, long timestamp, ByteBuffer data) {
        if (!running) { BufferPool.returnBuffer(data); return; }
        try {
            byte[] copy = new byte[data.remaining()];
            data.get(copy);
            final int s = session;
            final VideoSink vs = videoSink;
            final VideoDecoder d = decoder;
            if (d == null || !d.frame(copy, new Runnable() {
                public void run() {
                    if (vs != null) vs.ack(s);
                }
            })) {
                log("Video queue full/unavailable");
                abortIo();
            }
        } finally {
            BufferPool.returnBuffer(data);
        }
    }

    @Override
    public void focus(int mode, int reason) {
        if (!running) return;
        log("Video focus request=" + mode + " reason=" + reason);
        VideoSink vs = videoSink;
        if (mode >= 1 && mode <= 3 && vs != null)
            vs.answerVideoFocus(mode);
    }

    // --- VideoDecoder.Listener ---

    @Override
    public void format(int width, int height) {
        log("Decoder output crop: " + width + "x" + height);
        AaOverlayService overlay = AaOverlayService.getInstance();
        if (overlay != null) overlay.setDecodedVisibleSize(width, height);
    }

    @Override
    public void rendered() {
        if (!firstFrame) {
            firstFrame = true;
            log("FIRST FRAME RENDERED — AA video is live on overlay! selected=" + selected);
        }
    }

    // --- Shutdown ---

    private void shutdown() {
        if (!stopping.compareAndSet(false, true)) return;
        log("Shutting down AA session...");

        handler.removeCallbacksAndMessages(null);
        if (surfaceTimeoutRunnable != null) {
            surfaceTimeoutRunnable = null;
        }

        running = false;
        if (transport != null) transport.close();
        if (receiver != null) receiver.prepare();

        boolean stopped = true;
        for (Thread t : new Thread[]{readerThread, writerThread, pingThread}) {
            if (t != null) {
                try { t.join(2000); } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
                if (t.isAlive()) stopped = false;
            }
        }

        if (nightModeWatcher != null) { nightModeWatcher.stop(); nightModeWatcher = null; }
        if (decoder != null && !decoder.stop()) stopped = false;

        if (stopped && audioSource != null && !audioSource.destroy()) {
            stopped = false; // capture thread alive: keep receiver and every child object
            log("Mic capture did not stop: native objects retained");
        }
        if (stopped) {
            if (audioSinkMedia != null) audioSinkMedia.destroy();
            if (audioSinkGuidance != null) audioSinkGuidance.destroy();
            if (sensorSource != null) sensorSource.destroy();
            if (inputSource != null) inputSource.destroy();
            if (videoSink != null) videoSink.destroy();
            if (receiver != null) receiver.destroy();
            log("Protocol resources released cleanly");
        } else {
            log("Workers not confirmed stopped: native objects retained");
        }

        // Remove overlay
        Intent overlayStop = new Intent(this, AaOverlayService.class);
        overlayStop.setAction("aa.overlay.STOP");
        startService(overlayStop);

        protocolInitialized = false;
        sessionActive = false;
        pendingDevice = null;
        running = false;
        stopping.set(false);

        log("AA session shutdown complete");
        stopSelf();
    }

    private void log(String msg) {
        Log.i(TAG, SystemClock.elapsedRealtime() + " " + msg);
    }

    @Override
    public IBinder onBind(Intent intent) { return null; }

    @Override
    public void onDestroy() {
        if (running) shutdown();
        log("AaSessionService destroyed");
        super.onDestroy();
    }
}
