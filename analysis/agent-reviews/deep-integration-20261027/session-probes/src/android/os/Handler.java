package android.os;
import java.util.ArrayList;
public class Handler {
 public final ArrayList<Runnable> queued=new ArrayList<Runnable>();
 public boolean post(Runnable r){queued.add(r);return true;}
 public boolean postDelayed(Runnable r,long delay){queued.add(r);return true;}
 public void removeCallbacksAndMessages(Object token){queued.clear();}
 public void runNext(){queued.remove(0).run();}
}
