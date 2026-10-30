package com.rdx.fullscreen.clean;
import java.util.*;
/** Local service identity and wire channel are explicit, separate columns. Control is implicit channel 0. */
public final class AaServiceRegistry {
 public enum Kind { VIDEO, INPUT, AUDIO, SENSOR }
 public static final class Entry {
  public final int serviceId,channel;public final Kind kind;
  private Entry(int s,int c,Kind k){serviceId=s;channel=c;kind=k;}
 }
 private final Map<Integer,Entry> services=new LinkedHashMap<Integer,Entry>();
 private final Map<Integer,Entry> channels=new LinkedHashMap<Integer,Entry>();
 private final int maximum;
 public AaServiceRegistry(){this(16);}
 public AaServiceRegistry(int max){if(max<1||max>255)throw new IllegalArgumentException("Registry limit");maximum=max;}
 /** Compatibility API: explicit identity mapping, not automatic equivalence in the protocol. */
 public void register(int channel,Kind kind){register(channel,channel,kind);}
 public void register(int serviceId,int channel,Kind kind){
  if(serviceId<1||serviceId>65535||channel<1||channel>255||kind==null||services.size()>=maximum||services.containsKey(serviceId)||channels.containsKey(channel))throw new IllegalArgumentException("Reserved/duplicate/invalid service or channel");
  Entry e=new Entry(serviceId,channel,kind);services.put(serviceId,e);channels.put(channel,e);
 }
 public int allocate(int serviceId,Kind kind){for(int c=1;c<=255;c++)if(!channels.containsKey(c)){register(serviceId,c,kind);return c;}throw new IllegalStateException("No channel available");}
 public Entry service(int id){Entry e=services.get(id);if(e==null)throw new IllegalArgumentException("Unknown service");return e;}
 public Entry channel(int id){Entry e=channels.get(id);if(e==null)throw new IllegalArgumentException("Unknown service channel (0 is control)");return e;}
 public List<Entry> entries(){return Collections.unmodifiableList(new ArrayList<Entry>(services.values()));}
 public Map<Integer,Kind> snapshot(){Map<Integer,Kind> out=new LinkedHashMap<Integer,Kind>();for(Entry e:channels.values())out.put(e.channel,e.kind);return Collections.unmodifiableMap(out);}
 public void reset(){services.clear();channels.clear();}
}
