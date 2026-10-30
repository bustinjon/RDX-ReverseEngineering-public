package com.google.android.projection.protocol;
/** Wire enum values from the matching stock Protos; Android focus values are distinct. */
public final class AudioFocusPolicy {
    private AudioFocusPolicy() {}
    public static int gain(int request) { return request>=1 && request<=3?request:0; }
    public static int reply(int request,boolean granted) { return !granted || gain(request)==0?3:request==1?1:2; }
    public static int change(int androidChange) { return androidChange==1?1:androidChange==-2?5:androidChange==-3?4:3; }
}
