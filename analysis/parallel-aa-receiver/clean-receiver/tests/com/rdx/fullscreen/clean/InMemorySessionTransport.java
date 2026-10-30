package com.rdx.fullscreen.clean;
import java.util.*;
/** Test-only byte transport and fake clock; no sockets/Android/threads/sleeps. */
public final class InMemorySessionTransport {
 public static final class Clock implements SessionPolicy.Clock { public long time;public long now(){return time;} }
 private static final class Delivery {long at,order;byte[] bytes;Delivery(long t,long n,byte[] b){at=t;order=n;bytes=b;}}
 public final Clock clock;public SimulatedSessionEngine engine;
 private final List<Delivery> queued=new ArrayList<Delivery>();private final List<byte[]> captured=new ArrayList<byte[]>();private long serial;private int queuedBytes;
 public InMemorySessionTransport(Clock c,SimulatedSessionEngine e){clock=c;engine=e;}
 public void inject(byte[] bytes,int size,long delay){
  if(bytes==null||size<1||delay<0||delay>1000000||bytes.length>65536||clock.time<0||delay>Long.MAX_VALUE-clock.time)throw new IllegalArgumentException("Synthetic transport bounds");
  int count=(bytes.length+size-1)/size;if(queued.size()+count>256||bytes.length>1048576-queuedBytes)throw new IllegalArgumentException("Queue bound");queuedBytes+=bytes.length;
  for(int p=0;p<bytes.length;p+=size)queued.add(new Delivery(clock.time+delay,serial++,Arrays.copyOfRange(bytes,p,Math.min(bytes.length,p+size))));
 }
 private void sort(){Collections.sort(queued,new Comparator<Delivery>(){public int compare(Delivery a,Delivery b){return a.at<b.at?-1:a.at>b.at?1:a.order<b.order?-1:a.order>b.order?1:0;}});}
 public void dropNext(){sort();if(!queued.isEmpty())queuedBytes-=queued.remove(0).bytes.length;}
 public void duplicateNext(){sort();if(!queued.isEmpty()){Delivery d=queued.get(0);if(queued.size()>=256||d.bytes.length>1048576-queuedBytes)throw new IllegalArgumentException("Queue bound");queued.add(new Delivery(d.at,serial++,d.bytes.clone()));queuedBytes+=d.bytes.length;}}
 public void reorderFirstTwo(){sort();if(queued.size()>1){Delivery a=queued.get(0),b=queued.get(1);long order=a.order,time=a.at;a.order=b.order;b.order=order;a.at=b.at;b.at=time;}}
 public void capture(){for(byte[] b:engine.drainOutbound()){if(captured.size()>=128)throw new IllegalStateException("Capture bound");captured.add(b);}}
 public void advanceTo(long time){
  if(time<clock.time)throw new IllegalArgumentException("Monotonic fake time required");sort();
  while(!queued.isEmpty()&&queued.get(0).at<=time){Delivery d=queued.remove(0);queuedBytes-=d.bytes.length;clock.time=d.at;engine.receive(d.bytes);capture();sort();}
  clock.time=time;engine.tick();capture();
 }
 public List<byte[]> outbound(){return Collections.unmodifiableList(captured);}
 public void eof(){engine.eof();capture();}
 public void reset(){queued.clear();queuedBytes=0;captured.clear();engine=engine.resetForNewSession();}
}
