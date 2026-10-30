package android.app;
import android.content.*;
import android.os.IBinder;
import java.util.ArrayList;
public class Service extends Context {
 public static final int START_NOT_STICKY=2;
 public final ArrayList<String> startedActions=new ArrayList<String>();public int stopCalls;
 public void onCreate(){}public void onDestroy(){}
 public int onStartCommand(Intent i,int flags,int id){return 2;}
 public IBinder onBind(Intent i){return null;}
 public void stopSelf(){stopCalls++;}
 @Override public Object startService(Intent intent){startedActions.add(intent.getAction());return null;}
}
