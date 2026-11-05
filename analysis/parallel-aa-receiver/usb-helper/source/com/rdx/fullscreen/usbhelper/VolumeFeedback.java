package com.rdx.fullscreen.usbhelper;

/** Actual head-unit master volume as reported by Android; never estimates or changes volume. */
public final class VolumeFeedback {
    // Honda's own amplifier broadcast needs a system permission; Android's master-volume broadcast
    // mirrors the knob (seen 14..18 while turning it, 2026-11-04) and has no receiver permission.
    public static final String ACTION="android.media.MASTER_VOLUME_CHANGED_ACTION";
    public static final String EXTRA="android.media.EXTRA_MASTER_VOLUME_VALUE";
    public static final long DISPLAY_MS=3000;
    private int level=-1;
    public boolean update(int received) {
        if(received<0 || received>127)return false;
        boolean changed=received!=level;
        level=received;
        return changed;
    }
    public int level() { return level; }
    public void reset() { level=-1; }
}
