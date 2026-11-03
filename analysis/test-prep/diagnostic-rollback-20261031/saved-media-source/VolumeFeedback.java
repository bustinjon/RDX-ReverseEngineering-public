package com.rdx.fullscreen.usbhelper;

/** Actual OEM amplifier level only; never estimates or changes vehicle volume. */
public final class VolumeFeedback {
    public static final String ACTION="com.honda.auto.amplifiermanager.get_main_volume";
    public static final String EXTRA="bundle_key";
    public static final long DISPLAY_MS=3000;
    private int level=-1;
    public boolean update(int received) {
        // OEM payload is a non-negative signed byte, also used by SystemUI.
        if(received<0 || received>127)return false;
        boolean changed=received!=level;
        level=received;
        return changed;
    }
    public int level() { return level; }
    public void reset() { level=-1; }
}
