package com.rdx.fullscreen.usbhelper;
public final class InputEvents {
    private InputEvents() {}
    public static int hoverAction(int action) { return action==9?0:action==7?2:action==10?1:-1; }
    public static int keyCode(int code) {
        switch(code) {
            case 66: return 23;
            case 146: return 93; // PAGE_DOWN; consume raw key so no framework fallback is needed.
            case 148: return 122; // MOVE_HOME
            case 150: return 123; // MOVE_END
            case 152: return 92; // PAGE_UP
            default: return code;
        }
    }
    public static boolean key(int code) {
        int mapped=keyCode(code);
        for(int supported:supportedKeyCodes())if(mapped==supported)return true;
        return false;
    }
    public static int[] supportedKeyCodes() { return new int[]{4,23,92,93,122,123}; }
    public interface KeyConsumer { void send(int mappedCode,boolean down); }
    /** True means the overlay must consume this event, preventing synthetic fallback. */
    public static boolean dispatchKey(int rawCode,int action,KeyConsumer consumer) {
        if(consumer==null || !key(rawCode) || (action!=0 && action!=1))return false;
        if(rawCode==146)return true; // Down motion probe: consume both phases without an extra key pulse.
        consumer.send(keyCode(rawCode),action==0);
        return true;
    }
    /** Opt-in test adapter: verified B-zone key signatures, one pair on release. */
    public static final class BZoneSwipe {
        private int bottomDevice=-1, topDevice=-1;
        private int mapped(int code,int scan,int source,int device) {
            if(source!=257 || device<0)return -1;
            if(code==38 && scan==36)return 20;
            if(code==39 && scan==37)return 19;
            return -1;
        }
        /** Matching DOWN is consumed; matching UP emits one balanced AA pair. */
        public boolean dispatch(int code,int scan,int source,int device,
                                int action,int repeat,KeyConsumer consumer) {
            int key=mapped(code,scan,source,device);
            if(consumer==null || key<0 || (action!=0 && action!=1))return false;
            int owner=code==38?bottomDevice:topDevice;
            if(action==0){
                if(repeat==0 && owner<0){
                    if(code==38)bottomDevice=device;else topDevice=device;
                }
                return true;
            }
            if(owner==device){
                if(code==38)bottomDevice=-1;else topDevice=-1;
                consumer.send(key,true);
                consumer.send(key,false);
            }
            return true;
        }
    }
    /** Per-overlay pad contact; suppress only repeated ENTER before EXIT. */
    public static final class HoverContact {
        private boolean active;
        /** Map hover to pad actions, or -1 for unknown/duplicate ENTER. */
        public int action(int hover) {
            int mapped=hoverAction(hover);
            if(mapped==0){
                if(active)return -1;
                active=true;
            } else if(mapped==1){
                active=false;
            }
            return mapped;
        }
    }
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
