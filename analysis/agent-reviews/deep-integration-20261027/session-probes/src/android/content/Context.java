package android.content;
import android.content.res.AssetManager;
public class Context {
 public static final String USB_SERVICE="usb";
 public Object getSystemService(String key){return new android.hardware.usb.UsbManager();}
 public AssetManager getAssets(){return new AssetManager();}
 public Object startService(Intent intent){return null;}
}
