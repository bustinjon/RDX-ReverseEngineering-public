package com.google.android.projection.protocol;

import android.util.Log;

/**
 * JNI facade for the native AudioSource (microphone) in libautoreceiver_jni.so.
 * Stub: registers so service discovery includes mic capability,
 * but denies all microphone open requests.
 */
public final class AudioSource {
    private static final String TAG = "RDX.AUDIOSRC";

    @SuppressWarnings("unused") // set by native code
    private long mNativeAudioSource;
    private boolean created;

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
            + " codec=" + codecType + " " + samplingRate + "/" + bits + "/" + channels);
    }

    public long handle() { return mNativeAudioSource; }

    public void destroy() {
        if (created) {
            created = false;
            nativeShutdown();
            Log.i(TAG, "AudioSource destroyed");
        }
    }

    @SuppressWarnings("unused") // called by native code
    public void ackCallback(int sessionId, int ack) {
    }

    @SuppressWarnings("unused")
    public int microphoneRequestCallback(boolean open, boolean ancEnabled,
                                         boolean ecEnabled, int maxUnacked) {
        Log.i(TAG, "Mic request open=" + open + " — denied (stub)");
        return 0;
    }
}
