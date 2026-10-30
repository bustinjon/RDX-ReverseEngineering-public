package com.rdx.fullscreen.clean;
import java.util.*;
/** Local bounded credit model. Tokens/generation do NOT exist in Honda wire ACKs. */
public final class MediaAccountingWindow {
 public static final int MAX=32;
 public static final class Token {public final int session;public final long generation,serial;private Token(int s,long g,long n){session=s;generation=g;serial=n;}}
 private static final class Item {Token token;long time;boolean completed;}
 private final LinkedHashMap<Long,Item> pending=new LinkedHashMap<Long,Item>();private final int limit;private int session;private long generation,serial;
 public MediaAccountingWindow(int max,int id){if(max<1||max>MAX||id<0)throw new IllegalArgumentException("Window policy");limit=max;session=id;}
 public int outstanding(){return pending.size();}public int limit(){return limit;}
 public Token issue(long now){if(now<0||serial==Long.MAX_VALUE)throw new IllegalArgumentException("Clock/serial");if(pending.size()==limit)return null;Item item=new Item();item.token=new Token(session,generation,++serial);item.time=now;pending.put(serial,item);return item.token;}
 public boolean complete(Token t){if(t==null||t.session!=session||t.generation!=generation)return false;Item item=pending.get(t.serial);if(item==null||item.token!=t||item.completed)return false;item.completed=true;return true;}
 public int drainCompleted(){int count=0;Iterator<Item> it=pending.values().iterator();while(it.hasNext()){Item item=it.next();if(!item.completed)break;it.remove();count++;}return count;}
 /** Count-only duplicates are UNDETECTABLE if enough debt remains. No false idempotence claim. */
 public boolean applyCountAck(int id,int count){if(id!=session||count<1||count>pending.size())return false;Iterator<Long> it=pending.keySet().iterator();for(int i=0;i<count;i++){it.next();it.remove();}return true;}
 public boolean expired(long now,long deadline){if(now<0||deadline<1)throw new IllegalArgumentException("Deadline");for(Item i:pending.values())if(now<i.time||now-i.time>=deadline)return true;return false;}
 public void reset(int id){if(id<0||generation==Long.MAX_VALUE)throw new IllegalArgumentException("Generation/session");pending.clear();session=id;generation++;serial=0;}
}
