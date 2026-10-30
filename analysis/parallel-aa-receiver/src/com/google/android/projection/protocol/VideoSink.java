package com.google.android.projection.protocol;
import java.nio.ByteBuffer;

/** Native service1 facade; numeric configuration fields are traced from stock construction. */
public final class VideoSink {
    private long mNativeVideoSink;
    private final Listener listener;
    private boolean created;
    public interface Listener {
        void config(int index,int codecWidth,int codecHeight,int activeWidth,int activeHeight,int dpi);
        void codecConfig(byte[] data); void codecSetup();
        void frame(int session,long timestamp,ByteBuffer data);
        void focus(int mode,int reason);
    }
    private native int nativeInit(int id,long receiver,boolean autoStart);
    private native void nativeSetMaxUnackedFrames(int count);
    private native void nativeAddSupportedConfiguration(int resolution,int fps,int widthMargin,int heightMargin,int dpi,int realDpi,int depth,int pixelAspectE4);
    private native void nativeSetCodecType(int codec);
    private native void nativeSetVideoFocus(int focus,boolean unsolicited);
    private native void nativeAckFrames(int session,int count);
    private native void nativeShutdown();
    public VideoSink(Listener listener) { this.listener=listener; }
    public void initialize(long receiver,int realDpi) {
        if(nativeInit(1,receiver,false)!=0) throw new IllegalStateException("Video nativeInit rejected");
        created=true; nativeSetMaxUnackedFrames(16);
        // Candidate A, index0: VIDEO_1920x1080 enum3, active1920x720, total height margin360.
        nativeAddSupportedConfiguration(3,60,0,360,229,realDpi,0,10000);
        // Unchanged stock fallback, index1: VIDEO_800x480 enum1, active800x430.
        nativeAddSupportedConfiguration(1,60,0,50,143,realDpi,0,10000);
        nativeSetCodecType(3); // MEDIA_CODEC_VIDEO_H264_BP
    }
    public long handle() { return mNativeVideoSink; }
    public void requestVideo() { nativeSetVideoFocus(1,true); }
    public void answerVideoFocus(int mode) { nativeSetVideoFocus(mode,false); }
    public void ack(int session) { if(created) nativeAckFrames(session,1); }
    public void destroy() { if(created) { created=false; nativeShutdown(); } }
    public void dataAvailableCallback(int session,long timestamp,ByteBuffer data) { listener.frame(session,timestamp,data); }
    public int codecConfigCallback(byte[] data) { listener.codecConfig(data); return 0; }
    public int setupCallback(int codec) { listener.codecSetup(); return 0; }
    public void playbackStartCallback(int session) { }
    public void playbackStopCallback(int session) { }
    public void sourceVideoConfigCallback(int index) {
        if(index==0) listener.config(0,1920,1080,1920,720,229);
        else if(index==1) listener.config(1,800,480,800,430,143);
        else throw new IllegalArgumentException("Unexpected video config index="+index);
    }
    public void videoFocusCallback(int mode,int reason) { listener.focus(mode,reason); }
}
