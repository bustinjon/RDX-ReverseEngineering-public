package android.content;
import java.util.HashMap;
public class Intent {
 private String action;private HashMap<String,Object> extras=new HashMap<String,Object>();
 public Intent(Context c,Class<?> type){}
 public Intent setAction(String a){action=a;return this;}
 public String getAction(){return action;}
 public Intent putExtra(String key,Object value){extras.put(key,value);return this;}
 @SuppressWarnings("unchecked") public <T>T getParcelableExtra(String key){return (T)extras.get(key);}
}
