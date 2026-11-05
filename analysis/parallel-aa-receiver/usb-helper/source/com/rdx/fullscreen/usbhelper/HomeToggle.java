package com.rdx.fullscreen.usbhelper;

/**
 * Decides what a Honda Home press does to the AA overlay. Pure logic, host-tested.
 * Visible + Home: minimize (Honda screens usable, AA session and audio keep running).
 * Minimized + Home: nothing (Home always means Honda Home; user preference 2026-11-04).
 * Minimized + side-panel button: restore AA.
 */
final class HomeToggle {
    static final int NONE = 0, MINIMIZE = 1, RESTORE = 2;
    static final long DOUBLE_MS = 1200;

    private boolean minimized;
    private long lastHomeMs = Long.MIN_VALUE;

    boolean minimized() { return minimized; }

    int onHome(long nowMs) {
        lastHomeMs = nowMs;
        if (minimized) return NONE;
        minimized = true;
        return MINIMIZE;
    }

    /** Side-panel button release: brings AA back only when it is minimized. */
    int onSidePanel() {
        if (!minimized) return NONE;
        minimized = false;
        lastHomeMs = Long.MIN_VALUE;
        return RESTORE;
    }

    /** Restore by another route (on-screen button). */
    void restored() { minimized = false; lastHomeMs = Long.MIN_VALUE; }

    /** Minimized by a long Back press (Honda consumes Home while our overlay has focus). */
    void minimizedByBack() { minimized = true; lastHomeMs = Long.MIN_VALUE; }

    void reset() { minimized = false; lastHomeMs = Long.MIN_VALUE; }

    /**
     * Back key while AA is visible: a short press is sent to the phone as Back on release;
     * holding it for LONG_MS minimizes instead (fires once, on the repeat or on release).
     */
    static final class BackHold {
        static final int CONSUME = 0, SHORT = 1, MINIMIZE = 2;
        static final long LONG_MS = 800;
        private boolean down, fired;

        int onKey(int action, int repeat, boolean canceled, long heldMs) {
            if (action == 0) {
                if (repeat == 0) { down = true; fired = false; return CONSUME; }
                if (down && !fired && !canceled && heldMs >= LONG_MS) { fired = true; return MINIMIZE; }
                return CONSUME;
            }
            if (action != 1) return CONSUME;
            boolean wasDown = down, wasFired = fired;
            down = false; fired = false;
            if (!wasDown || wasFired || canceled) return CONSUME;
            return heldMs >= LONG_MS ? MINIMIZE : SHORT;
        }

        void reset() { down = false; fired = false; }
    }
}
