package android.media;
import android.view.Surface;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;

/** Deliberately synthetic API seam. It performs no decoding and loads no native code. */
public final class MediaCodec {
    public static final int BUFFER_FLAG_CODEC_CONFIG=2, INFO_OUTPUT_FORMAT_CHANGED=-2;
    public static volatile boolean failCreate, failDrain;
    public static final AtomicInteger createCalls=new AtomicInteger();
    public static final List<Submission> submissions=Collections.synchronizedList(new ArrayList<Submission>());
    public static final class BufferInfo { }
    public static final class Submission {
        public final int flags, firstByte;
        public Submission(int flags,int firstByte) { this.flags=flags; this.firstByte=firstByte; }
    }
    private final ByteBuffer input=ByteBuffer.allocate(1024);
    private MediaFormat format;
    public static void reset() { failCreate=false; failDrain=false; createCalls.set(0); submissions.clear(); }
    public static MediaCodec createByCodecName(String name) throws IOException {
        createCalls.incrementAndGet(); if(failCreate) throw new IOException("injected create failure"); return new MediaCodec();
    }
    public void configure(MediaFormat f,Surface s,Object crypto,int flags) { format=f; }
    public void start() { }
    public int dequeueInputBuffer(long timeout) { return 0; }
    public ByteBuffer getInputBuffer(int index) { return input; }
    public void queueInputBuffer(int index,int offset,int length,long time,int flags) {
        submissions.add(new Submission(flags,length==0?-1:input.get(offset)&255));
    }
    public int dequeueOutputBuffer(BufferInfo info,long timeout) {
        if(failDrain) throw new IllegalStateException("injected output failure"); return -1;
    }
    public MediaFormat getOutputFormat() { return format; }
    public void releaseOutputBuffer(int index,boolean render) { }
    public void stop() { }
    public void release() { }
}
