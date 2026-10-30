package com.rdx.fullscreen.projection;
import android.content.Context;
import android.hardware.usb.*;
import android.os.SystemClock;
import android.view.Surface;
import com.google.android.projection.protocol.GalReceiver;
import com.google.android.projection.protocol.VideoSink;
import com.google.android.projection.common.BufferPool;
import java.io.DataInputStream;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.util.concurrent.atomic.AtomicBoolean;

/** Local native setup and transport are deliberately separate manual milestones. */
final class ProjectionSession implements GalReceiver.Listener,VideoSink.Listener,VideoDecoder.Listener {
    interface Listener { void event(String text); void geometry(int width,int height); }
    private final Listener listener;
    private GalReceiver receiver;
    private VideoSink video;
    private VideoDecoder decoder;
    private UsbBulkTransport transport;
    private Thread reader,writer,ping;
    private final AtomicBoolean stopping=new AtomicBoolean(false);
    private volatile boolean running;
    private boolean selected,firstFrame;
    ProjectionSession(Listener listener) { this.listener=listener; }
    private String[] credentials(Context context) throws IOException {
        DataInputStream input=new DataInputStream(context.getAssets().open("private-test-material/platform.creds"));
        try {
            String[] result=new String[3];
            for(int i=0;i<result.length;i++) {
                int length=input.readInt();
                if(length<1||length>32768) throw new IOException("Invalid local credential container");
                byte[] data=new byte[length]; input.readFully(data); result[i]=new String(data,"UTF-8");
            }
            return result;
        } finally { input.close(); }
    }
    void initialize(Context context,Surface surface,int realDpi) throws Exception {
        receiver=new GalReceiver(this);
        receiver.initialize(credentials(context));
        video=new VideoSink(this); video.initialize(receiver.handle(),realDpi); receiver.register(video);
        decoder=new VideoDecoder(this); decoder.surface(surface);
        event("L2 native receiver + SSL credentials + local video service initialized. NOT a phone handshake.");
        event("LOCAL_CONFIG index0 enum3 1920x1080 margins0/360 active1920x720 dpi229 fps60; fallback index1 800x430 dpi143");
    }
    void startUsb(UsbManager manager,UsbDevice device) throws Exception {
        if(receiver==null||video==null||stopping.get()) throw new IllegalStateException("Initialize a fresh L2 session first");
        transport=new UsbBulkTransport(manager,device);
        event("L3 USB FD opened and interface0 claimed without force. Transport acquired; no handshake claim yet.");
        decoder.start(); receiver.startProtocol(); running=true;
        reader=new Thread(new Runnable(){public void run(){readLoop();}},"RDX-GAL-read");
        writer=new Thread(new Runnable(){public void run(){writeLoop();}},"RDX-GAL-write");
        ping=new Thread(new Runnable(){public void run(){
            try { while(running) { Thread.sleep(1000); if(running) receiver.ping(SystemClock.elapsedRealtime()); } }
            catch(Exception e) { if(running) event("Ping stopped: "+e); }
        }},"RDX-GAL-ping");
        reader.start(); writer.start(); ping.start();
    }
    private void readLoop() {
        byte[] data=new byte[65544];
        try {
            while(running) {
                transport.readFully(data,0,4);
                int length=receiver.remaining(data);
                if(length<0||length>data.length-4) throw new IOException("Invalid GAL frame length");
                transport.readFully(data,4,length); receiver.incoming(data,length+4);
            }
        } catch(Exception e) { if(running) { event("Transport read ended: "+e); abortIo(); } }
    }
    private void writeLoop() {
        byte[] data=new byte[65544];
        try {
            while(running) { int n=receiver.outgoing(data); if(n<=0) break; if(n>data.length) throw new IOException("Native output length invalid"); transport.write(data,n); }
        } catch(Exception e) { if(running) { event("Transport write ended: "+e); abortIo(); } }
    }
    private void abortIo() { running=false; if(transport!=null) transport.close(); if(receiver!=null) receiver.prepare(); }
    boolean stop() {
        if(!stopping.compareAndSet(false,true)) return true;
        abortIo();
        boolean stopped=true;
        for(Thread thread:new Thread[]{reader,writer,ping}) if(thread!=null) {
            try { thread.join(2000); } catch(InterruptedException e) { Thread.currentThread().interrupt(); }
            if(thread.isAlive()) stopped=false;
        }
        if(decoder!=null&&!decoder.stop()) stopped=false;
        if(stopped) {
            if(video!=null) video.destroy();
            if(receiver!=null) receiver.destroy();
            event("Session resources closed; no USB reset, stock-package operation or property change.");
        } else event("Workers not confirmed stopped: native objects retained to avoid use-after-free. Exit/uninstall this test package before another attempt.");
        return stopped;
    }
    public void event(String text) { listener.event(text); }
    public void discovery() { if(video!=null) video.requestVideo(); }
    public void byeBye() { abortIo(); event("Phone requested session end; use Stop/Exit."); }
    public void config(int index,int codecWidth,int codecHeight,int activeWidth,int activeHeight,int dpi) {
        selected=true; event("L5 SELECTED index="+index+" codec="+codecWidth+"x"+codecHeight+" active="+activeWidth+"x"+activeHeight+" dpi="+dpi);
        if(decoder!=null) decoder.dimensions(codecWidth,codecHeight);
        listener.geometry(activeWidth,activeHeight);
    }
    public void codecConfig(byte[] data) { if(decoder!=null) decoder.config(data); event("Codec configuration received (payload not logged)"); }
    public void codecSetup() { event("Video codec setup callback"); }
    public void frame(final int session,long timestamp,ByteBuffer data) {
        try {
            byte[] copy=new byte[data.remaining()]; data.get(copy);
            if(decoder==null||!decoder.frame(copy,new Runnable(){public void run(){if(video!=null) video.ack(session);}})) {
                event("Video queue full/unavailable; stop session rather than unbounded buffering"); abortIo();
            }
        } finally { BufferPool.returnBuffer(data); }
    }
    public void focus(int mode,int reason) { event("Video focus request="+mode+" reason="+reason); if(mode>=1&&mode<=3&&video!=null) video.answerVideoFocus(mode); }
    public void format(int width,int height) { listener.geometry(width,height); }
    public void rendered() { if(!firstFrame) { firstFrame=true; event("L6 first decoder output rendered; selectedCallbackObserved="+selected+". Inspect crop/geometry before fullscreen claims."); } }
}
