package com.rdx.fullscreen.usbhelper;
/** Strict per-session privacy budget; no device/UI dependencies. */
public final class FocusCaptureBudget {
    public static final int MAX_CAPTURES=12;
    public static final long INTERVAL_MS=10000, WINDOW_MS=120000;
    private final long start;
    private long last=-1;
    private int used;
    private boolean closed;
    public FocusCaptureBudget(long start){this.start=start;}
    public synchronized int reserve(long now){
        if(finished(now) || now<start || (last>=0 && now-last<INTERVAL_MS))return -1;
        last=now;return ++used;
    }
    public synchronized boolean finished(long now){return closed || used>=MAX_CAPTURES || now-start>=WINDOW_MS;}
    public synchronized void close(){closed=true;}
}
