package android.media;
import java.util.HashMap;
public final class MediaFormat {
    public static final String KEY_WIDTH="width", KEY_HEIGHT="height";
    private final HashMap<String,Integer> values=new HashMap<String,Integer>();
    public static MediaFormat createVideoFormat(String mime,int width,int height) {
        MediaFormat f=new MediaFormat(); f.values.put(KEY_WIDTH,width); f.values.put(KEY_HEIGHT,height); return f;
    }
    public int getInteger(String key) { return values.get(key); }
    public boolean containsKey(String key) { return values.containsKey(key); }
}
