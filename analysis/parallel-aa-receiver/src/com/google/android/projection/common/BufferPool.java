package com.google.android.projection.common;
import java.nio.ByteBuffer;
import java.util.ArrayDeque;

/** Exact static JNI signatures; bounded direct-buffer pool, independent of Honda application. */
public final class BufferPool {
    private static final ArrayDeque<ByteBuffer> pool=new ArrayDeque<ByteBuffer>();
    public static synchronized ByteBuffer getBuffer(int size) {
        if(size<0||size>4*1024*1024) throw new IllegalArgumentException("Unexpected native media buffer size");
        ByteBuffer found=null;
        for(ByteBuffer candidate:pool) if(candidate.capacity()>=size) { found=candidate; break; }
        if(found!=null) pool.remove(found); else found=ByteBuffer.allocateDirect(size);
        found.clear(); found.limit(size); return found;
    }
    public static synchronized void returnBuffer(ByteBuffer buffer) {
        if(buffer==null) return;
        if(pool.size()<16) { buffer.clear(); pool.addLast(buffer); }
    }
}
