package com.rdx.fullscreen.usbhelper;
public final class InputEvents {
    private InputEvents() {}
    public static int hoverAction(int action) { return action==9?0:action==7?2:action==10?1:-1; }
    public static int keyCode(int code) { return code==66?23:code; }
    public static boolean key(int code) { int mapped=keyCode(code); return mapped==4 || (mapped>=19 && mapped<=23); }
    /** Ordinary touch is pad depression; hover remains the independent movement path. */
    public static final class SelectPress {
        private boolean held;
        /** 1 = send select DOWN, 0 = send select UP, -1 = no key transition. */
        public int action(int action) {
            if(action==0 && !held){held=true;return 1;}
            if((action==1 || action==3) && held){held=false;return 0;}
            return -1;
        }
    }
}
