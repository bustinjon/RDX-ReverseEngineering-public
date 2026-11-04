package com.google.android.projection.protocol;

import android.media.AudioRecord;
import android.util.Log;
import java.util.concurrent.Semaphore;
import java.util.concurrent.TimeUnit;

/**
 * JNI facade for the native AudioSource (microphone) in libautoreceiver_jni.so.
 * T11 experiment: captures 16 kHz mono PCM with the public recorder, following the stock
 * open/pause/send/ack flow. Unlike stock it cannot switch the car's mic mode (privileged
 * OEM service), so the car's own noise/echo processing state is unknown.
 */
public final class AudioSource {
    private static final String TAG = "RDX.AUDIOSRC";
    private static final int SAMPLE_RATE = 16000, CHANNEL_IN_MONO = 16, PCM_16BIT = 2, SOURCE_MIC = 1;
    private static final int BUFFER = Math.max(AudioRecord.getMinBufferSize(SAMPLE_RATE, CHANNEL_IN_MONO, PCM_16BIT), 4096);
    private static final int MAX_RETRY = 15, MAX_READ_ERRORS = 3;
    private static final long ACK_TIMEOUT_MS = 800, JOIN_MS = 1500;

    @SuppressWarnings("unused") // set by native code
    private long mNativeAudioSource;
    private boolean created;
    private volatile boolean shuttingDown;
    private volatile Semaphore unacked = new Semaphore(1);
    private int sessionId;
    /** Session id of the currently open mic request; acks for older sessions are ignored. */
    private volatile int openSession = -1;
    private int staleAckLogs;
    private Capture capture;

    private native int nativeInit(int i, long j, int i2) throws IllegalStateException;
    private native void nativeSend(long j, byte[] bArr);
    private native void nativeSetConfig(int i, int i2, int i3);
    private native void nativeShutdown();

    public void initialize(int serviceId, long receiverHandle, int codecType,
                           int samplingRate, int bits, int channels) {
        if (nativeInit(serviceId, receiverHandle, codecType) != 0) {
            throw new IllegalStateException("AudioSource nativeInit rejected id=" + serviceId);
        }
        created = true;
        nativeSetConfig(samplingRate, bits, channels);
        Log.i(TAG, "AudioSource initialized id=" + serviceId
            + " codec=" + codecType + " " + samplingRate + "/" + bits + "/" + channels + " mic=EXPERIMENT buffer=" + BUFFER);
    }

    public long handle() { return mNativeAudioSource; }

    /** Returns false when the capture thread survived; the caller must then retain every native object. */
    public boolean destroy() {
        if (created) {
            created = false;
            shuttingDown = true;
            Capture c;
            synchronized (this) { c = capture; capture = null; }
            if (c != null && !c.shutdown()) {
                // Never destroy the native object under a live capture thread; retain it instead.
                Log.e(TAG, "MIC_THREAD_STUCK native AudioSource retained");
                return false;
            }
            nativeShutdown();
            Log.i(TAG, "AudioSource destroyed");
        }
        return true;
    }

    @SuppressWarnings("unused") // called by native code
    public void ackCallback(int session, int ack) {
        // Stock releases every ack regardless of session; keep that, but record mismatches as evidence.
        if (session != openSession && staleAckLogs < 5) { staleAckLogs++; Log.w(TAG, "MIC_ACK_SESSION_MISMATCH session=" + session + " open=" + openSession); }
        if (ack > 0) unacked.release(ack);
    }

    @SuppressWarnings("unused") // called by native code
    public int microphoneRequestCallback(boolean open, boolean ancEnabled,
                                         boolean ecEnabled, int maxUnacked) {
        Log.i(TAG, "MIC_REQUEST open=" + open + " anc=" + ancEnabled + " ec=" + ecEnabled + " maxUnacked=" + maxUnacked);
        synchronized (this) {
            int id = sessionId++;
            if (open && !shuttingDown) {
                unacked = new Semaphore(Math.max(1, maxUnacked));
                openSession = id;
                if (capture == null) { capture = new Capture(); capture.start(); }
                capture.resumeCapture();
            } else {
                openSession = -1;
                if (capture != null) capture.pauseCapture();
            }
            return id;
        }
    }

    private void send(byte[] data) {
        if (!shuttingDown) nativeSend(0L, data);
    }

    private final class Capture extends Thread {
        private final Object pauseLock = new Object();
        private volatile boolean paused = true, finished;
        private AudioRecord record;

        Capture() { super("RDX-mic"); }

        private boolean prepare() {
            for (int attempt = 1; record == null && attempt <= MAX_RETRY && !paused && !finished; attempt++) {
                AudioRecord r = null;
                try {
                    r = new AudioRecord(SOURCE_MIC, SAMPLE_RATE, CHANNEL_IN_MONO, PCM_16BIT, BUFFER);
                    if (r.getState() != AudioRecord.STATE_INITIALIZED) {
                        Log.w(TAG, "MIC_CREATE_FAILED attempt=" + attempt + " state=" + r.getState());
                        r.release();
                    } else {
                        r.startRecording();
                        if (r.getRecordingState() == AudioRecord.RECORDSTATE_RECORDING) {
                            record = r;
                            Log.i(TAG, "MIC_RECORDING attempt=" + attempt);
                        } else {
                            Log.w(TAG, "MIC_START_FAILED attempt=" + attempt);
                            r.release();
                        }
                    }
                } catch (RuntimeException e) {
                    Log.w(TAG, "MIC_CREATE_ERROR attempt=" + attempt + " " + e.getClass().getSimpleName());
                    if (r != null && record != r) { try { r.release(); } catch (RuntimeException ignored) { } }
                }
                if (record == null) sleepQuietly(100);
            }
            return record != null;
        }

        @Override public void run() {
            while (!finished) {
                int opensSeen;
                synchronized (pauseLock) { opensSeen = opens; }
                if (!paused && record == null && !prepare() && !finished) {
                    // Bounded failure: stop retrying until the phone opens the mic again,
                    // unless a newer open arrived while preparing.
                    synchronized (pauseLock) {
                        if (opens == opensSeen) { paused = true; Log.w(TAG, "MIC_UNAVAILABLE after " + MAX_RETRY + " attempts; waiting for next open"); }
                    }
                }
                int frames = 0, readErrors = 0, dropped = 0;
                long sumSquares = 0, samples = 0;
                while (!paused && !finished && record != null && readErrors < MAX_READ_ERRORS) {
                    byte[] buf = new byte[BUFFER];
                    int filled = 0;
                    while (filled < BUFFER && !paused && !finished) {
                        int len = record.read(buf, filled, BUFFER - filled);
                        if (len <= 0) {
                            Log.w(TAG, "MIC_READ_ERROR code=" + len);
                            readErrors++;
                            sleepQuietly(100);
                            break;
                        }
                        filled += len;
                    }
                    if (finished) break;
                    for (int i = 0; i + 1 < filled; i += 2) {
                        int s = (short) ((buf[i] & 0xff) | (buf[i + 1] << 8));
                        sumSquares += (long) s * s; samples++;
                    }
                    boolean slot;
                    try { slot = unacked.tryAcquire(ACK_TIMEOUT_MS, TimeUnit.MILLISECONDS); }
                    catch (InterruptedException e) { if (finished) break; slot = false; }
                    if (!slot) { dropped++; if (dropped % 20 == 1) Log.w(TAG, "MIC_ACK_TIMEOUT dropped=" + dropped + " frames=" + frames); continue; }
                    send(buf);
                    frames++;
                    if (frames % 40 == 1) Log.i(TAG, "MIC_FRAMES sent=" + frames + " rms=" + (samples == 0 ? 0 : (int) Math.sqrt(sumSquares / (double) samples)));
                }
                release(frames);
                synchronized (pauseLock) {
                    while (paused && !finished) {
                        try { pauseLock.wait(); } catch (InterruptedException ignored) { }
                    }
                }
            }
            release(0);
            Log.i(TAG, "MIC_THREAD_END");
        }

        private synchronized void release(int frames) {
            if (record != null) {
                try { record.stop(); } catch (RuntimeException ignored) { }
                record.release();
                record = null;
                Log.i(TAG, "MIC_STOPPED frames=" + frames);
            }
        }

        private int opens;

        void resumeCapture() {
            synchronized (pauseLock) { opens++; paused = false; pauseLock.notifyAll(); }
        }

        void pauseCapture() {
            synchronized (pauseLock) { paused = true; }
        }

        /** Returns true only when the capture thread has really ended. */
        boolean shutdown() {
            finished = true;
            paused = true;
            interrupt();
            synchronized (pauseLock) { pauseLock.notifyAll(); }
            try { join(JOIN_MS); } catch (InterruptedException ignored) { Thread.currentThread().interrupt(); }
            return !isAlive();
        }
    }

    private static void sleepQuietly(long ms) {
        try { Thread.sleep(ms); } catch (InterruptedException ignored) { }
    }
}
