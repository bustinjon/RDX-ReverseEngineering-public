package com.google.android.projection.protocol;

import android.os.SystemClock;
import android.util.Log;

/**
 * JNI facade for the native InputSource in libautoreceiver_jni.so.
 * Signatures verified against stock smali (Codex deep-integration review 2026-10-27).
 *
 * IMPORTANT: nativeSendTouchPadEvent array order is (pointerId, x, y) NOT (x, y, pointerId).
 * Action is passed as int param after the arrays, not before them.
 * All send methods return int (status), not void.
 * Timestamps are elapsedRealtimeNanos(), not milliseconds.
 */
public final class InputSource {
    private static final String TAG = "RDX.INPUT";

    @SuppressWarnings("unused") // set by native code
    private long mNativeInputSource;
    private boolean created;

    // Stock signature: (IJ)I — no autoStart boolean
    private native int nativeInit(int serviceId, long receiver) throws IllegalStateException;

    // Stock signature: (IIZIIZZ)V — 3rd param is boolean, 4th/5th are int
    private native void nativeRegisterTouchPad(int width, int height,
        boolean uiNavigation, int physicalWidthMm, int physicalHeightMm,
        boolean uiAbsolute, boolean tapAsSelect);

    private native void nativeRegisterTouchScreen(int width, int height, int type);
    private native void nativeRegisterKeyCodes(int[] keyCodes);
    private native void nativeRegisterFeedbackEvents(int[] events);

    // Stock signature: (J[I[I[III)I — arrays are (pointerId, x, y), returns int
    private native int nativeSendTouchPadEvent(long timestamp,
        int[] pointerIds, int[] xCoords, int[] yCoords,
        int action, int actionIndex);

    private native int nativeSendTouchEvent(long timestamp,
        int[] pointerIds, int[] xCoords, int[] yCoords,
        int action, int actionIndex);

    private native int nativeSendAbsoluteEvent(long timestamp, int keycode, int value);
    private native int nativeSendRelativeEvent(long timestamp, int keycode, int delta);
    private native int nativeSendKeyEvent(long timestamp, int keyCode, boolean down, int metaState);
    private native int nativeSendKeyLongEvent(long timestamp, int keyCode, int metaState);
    private native void nativeShutdown();

    public void initialize(int serviceId, long receiverHandle) {
        if (nativeInit(serviceId, receiverHandle) != 0) {
            throw new IllegalStateException("InputSource nativeInit rejected");
        }
        created = true;
        Log.i(TAG, "InputSource initialized serviceId=" + serviceId);
    }

    public long handle() { return mNativeInputSource; }

    public void registerTouchPad(int width, int height,
            int physicalWidthMm, int physicalHeightMm,
            boolean uiNavigation, boolean uiAbsolute) {
        nativeRegisterTouchPad(width, height, uiNavigation,
            physicalWidthMm, physicalHeightMm, uiAbsolute, false);
        Log.i(TAG, "Touchpad registered: " + width + "x" + height
            + " phys=" + physicalWidthMm + "x" + physicalHeightMm + "mm"
            + " nav=" + uiNavigation + " abs=" + uiAbsolute);
    }

    /**
     * Send a single-pointer touchpad event.
     * Coordinates in touchpad space (0-width, 0-height).
     * Array order matches stock: pointerIds, x, y.
     * Timestamp is elapsedRealtimeNanos.
     */
    public void sendTouchPad(int action, int x, int y, long eventTimeMs) {
        long timestampNs = SystemClock.elapsedRealtimeNanos();
        int result = nativeSendTouchPadEvent(timestampNs,
            new int[]{0}, new int[]{x}, new int[]{y}, action, 0);
        if (result != 0) {
            Log.w(TAG, "sendTouchPad returned " + result);
        }
    }

    public void sendKey(int keyCode, boolean down, long eventTimeMs) {
        long timestampNs = SystemClock.elapsedRealtimeNanos();
        nativeSendKeyEvent(timestampNs, keyCode, down, 0);
    }

    public void destroy() {
        if (created) {
            created = false;
            nativeShutdown();
            Log.i(TAG, "InputSource destroyed");
        }
    }

    @SuppressWarnings("unused")
    public void onInputFeedback(int event) {
        Log.i(TAG, "Input feedback event=" + event);
    }
}
