package com.google.android.projection.protocol;
public final class PcmFrames {
    private PcmFrames() {}
    public interface Writer { int write(byte[] data,int offset,int count); }
    public static byte[] copy(byte[] data,int channels) {
        if (data==null || channels<1 || channels>2 || data.length==0 || data.length>65536
                || data.length%(channels*2)!=0) throw new IllegalArgumentException("Invalid PCM16 frame");
        return data.clone();
    }
    public static boolean write(Writer writer,byte[] data) {
        int offset=0;
        while(offset<data.length) {
            int count=writer.write(data,offset,data.length-offset);
            if(count<=0 || count>data.length-offset) return false;
            offset+=count;
        }
        return true;
    }
}
