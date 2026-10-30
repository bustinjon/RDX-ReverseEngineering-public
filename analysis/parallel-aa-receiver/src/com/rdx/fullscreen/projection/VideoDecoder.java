package com.rdx.fullscreen.projection;
import android.media.*;
import android.view.Surface;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.TimeUnit;

/** Normal public MediaCodec API; no Honda display or media service. */
public final class VideoDecoder {
    public interface Listener { void event(String text); void format(int width,int height); void rendered(); }
    private final Listener listener;
    private final ArrayBlockingQueue<Packet> queue=new ArrayBlockingQueue<Packet>(24);
    private volatile boolean stopping;
    private Thread worker;
    private MediaCodec codec;
    private volatile Surface surface;
    private volatile int width=1920,height=1080;
    private byte[] config;
    private boolean configFed;
    private int dropCount;
    private static final class Packet {
        final byte[] data; final boolean config; final Runnable ack;
        Packet(byte[] data,boolean config,Runnable ack) { this.data=data; this.config=config; this.ack=ack; }
    }
    public VideoDecoder(Listener listener) { this.listener=listener; }
    public void surface(Surface surface) { this.surface=surface; }
    public void dimensions(int width,int height) { this.width=width; this.height=height; }
    public void start() {
        if(worker!=null) return;
        worker=new Thread(new Runnable(){public void run(){loop();}},"RDX-video-decoder"); worker.start();
    }
    public void config(byte[] data) { config=data.clone(); configFed=false; }
    public boolean frame(byte[] data,Runnable ack) { return queue.offer(new Packet(data,false,ack)); }
    private void createCodec() throws Exception {
        Surface target=surface;
        if(target==null||!target.isValid()) throw new IllegalStateException("Surface unavailable");
        MediaCodec mc=MediaCodec.createByCodecName("OMX.TI.DUCATI1.VIDEO.DECODER");
        try {
            MediaFormat format=MediaFormat.createVideoFormat("video/avc",width,height);
            mc.configure(format,target,null,0); mc.start();
        } catch(Exception e) { mc.release(); throw e; }
        codec=mc;
        listener.event("Decoder started with declared codec raster "+width+"x"+height+"; SPS/output crop still authoritative");
    }
    private boolean ensureConfig() {
        if(configFed) return true;
        byte[] header=config;
        if(header==null) return true;
        try {
            feed(header,true);
            configFed=true;
            listener.event("Codec config fed ("+header.length+" bytes)");
            return true;
        } catch(Exception e) {
            if(dropCount<=2||dropCount%100==0) listener.event("Config feed deferred: "+e.getMessage());
            return false;
        }
    }
    private void feed(byte[] data,boolean isConfig) throws Exception {
        int index=codec.dequeueInputBuffer(isConfig?500000:50000);
        if(index<0) throw new IllegalStateException("No decoder input buffer");
        java.nio.ByteBuffer input=codec.getInputBuffer(index);
        if(input==null||input.capacity()<data.length) {
            codec.queueInputBuffer(index,0,0,0,0);
            throw new IllegalStateException("Access unit exceeds decoder input capacity");
        }
        input.clear(); input.put(data);
        codec.queueInputBuffer(index,0,data.length,android.os.SystemClock.elapsedRealtime()*1000L,isConfig?MediaCodec.BUFFER_FLAG_CODEC_CONFIG:0);
    }
    private void drain() {
        MediaCodec.BufferInfo info=new MediaCodec.BufferInfo();
        for(int attempt=0;attempt<8;attempt++) {
            int index=codec.dequeueOutputBuffer(info,0);
            if(index==MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                MediaFormat format=codec.getOutputFormat();
                int w=format.getInteger(MediaFormat.KEY_WIDTH),h=format.getInteger(MediaFormat.KEY_HEIGHT);
                if(format.containsKey("crop-left")&&format.containsKey("crop-right")) w=format.getInteger("crop-right")-format.getInteger("crop-left")+1;
                if(format.containsKey("crop-top")&&format.containsKey("crop-bottom")) h=format.getInteger("crop-bottom")-format.getInteger("crop-top")+1;
                listener.event("Decoder output format="+format+" visibleCrop="+w+"x"+h); listener.format(w,h);
            } else if(index>=0) { codec.releaseOutputBuffer(index,true); listener.rendered(); }
            else break;
        }
    }
    private void loop() {
        boolean broken=false;
        try {
            while(!stopping) {
                Packet packet=queue.poll(20,TimeUnit.MILLISECONDS);
                if(packet!=null) {
                    try {
                        if(!broken) {
                            if(codec==null) createCodec();
                            if(ensureConfig()) {
                                feed(packet.data,packet.config);
                                dropCount=0;
                            } else {
                                dropCount++;
                                if(dropCount==1||dropCount%100==0) listener.event("Dropping frame (config not fed) count="+dropCount);
                            }
                        }
                    } catch(IllegalStateException e) {
                        dropCount++;
                        if(dropCount<=3||dropCount%100==0) listener.event("Decoder drop #"+dropCount+": "+e.getMessage());
                        if(codec==null) broken=true;
                    } catch(Exception e) { broken=true; listener.event("Decoder fatal: "+e); }
                    finally { if(packet.ack!=null) packet.ack.run(); }
                }
                if(codec!=null&&!broken) drain();
            }
        } catch(Exception e) { listener.event("Decoder worker stopped: "+e); }
        finally {
            Packet packet; while((packet=queue.poll())!=null) if(packet.ack!=null) packet.ack.run();
            if(codec!=null) { try{codec.stop();}catch(Exception ignored){} codec.release(); codec=null; }
        }
    }
    public boolean stop() {
        stopping=true;
        if(worker==null) return true;
        try { worker.join(2000); } catch(InterruptedException e) { Thread.currentThread().interrupt(); }
        return !worker.isAlive();
    }
}
