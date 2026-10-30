package com.rdx.fullscreen.m6aoa;
import java.io.*;
import java.security.MessageDigest;
import java.util.*;
/** Bounded append, flush+fsync, hash-chain replay. Torn final append fails closed. */
public final class M6Journal {
 public interface Store {byte[] read()throws IOException;void append(byte[] line)throws IOException;}
 public static final class Disk implements Store {
  private final File file;
  public Disk(File f){file=f;}
  public byte[] read()throws IOException{if(!file.exists())return new byte[0];if(file.length()>131072)throw new IOException("Journal bound");ByteArrayOutputStream b=new ByteArrayOutputStream();FileInputStream in=new FileInputStream(file);try{byte[] c=new byte[2048];int n;while((n=in.read(c))!=-1){b.write(c,0,n);if(b.size()>131072)throw new IOException("Journal bound");}}finally{in.close();}return b.toByteArray();}
  public void append(byte[] b)throws IOException{if((file.exists()?file.length():0)+b.length>131072)throw new IOException("Journal bound");FileOutputStream out=new FileOutputStream(file,true);try{out.write(b);out.flush();out.getFD().sync();}finally{out.close();}}
 }
 public static final int MAX_ENTRIES=256;public final String run;private final Store store;private final ArrayList<String> entries=new ArrayList<String>();private String previous=zeros();private long last=-1;private boolean loaded;private int byteCount;
 public M6Journal(String r,Store s){if(r==null||!r.matches("[A-Za-z0-9_-]{8,64}")||s==null)throw new IllegalArgumentException("Journal");run=r;store=s;}
 public static String hash(byte[] b){try{MessageDigest m=MessageDigest.getInstance("SHA-256");return hex(m.digest(b));}catch(Exception e){throw new IllegalStateException(e);}}
 public static String hex(byte[] b){StringBuilder s=new StringBuilder();for(byte v:b){int x=v&255;s.append("0123456789abcdef".charAt(x>>>4)).append("0123456789abcdef".charAt(x&15));}return s.toString();}
 public static byte[] unhex(String s){if(s==null||s.length()%2!=0||!s.matches("[0-9a-fA-F]+"))throw new IllegalArgumentException("Hex");byte[] b=new byte[s.length()/2];for(int i=0;i<b.length;i++)b[i]=(byte)Integer.parseInt(s.substring(2*i,2*i+2),16);return b;}
 private static String zeros(){return "0000000000000000000000000000000000000000000000000000000000000000";}
 public void load()throws IOException{if(loaded)throw new IOException("Journal loaded twice");byte[] bytes=store.read();if(bytes.length>131072)throw new IOException("Journal bound");String text=new String(bytes,"UTF-8");if(text.length()>0&&(!text.endsWith("\n")||text.startsWith("\n")||text.contains("\n\n")))throw new IOException("Torn or blank journal");if(!hash(text.getBytes("UTF-8")).equals(hash(bytes)))throw new IOException("Encoding");
  String[] lines=text.split("\n");for(String line:lines){if(line.length()==0)continue;String[] p=line.split("\\|",-1);if(p.length!=10||!p[0].equals("1")||!p[1].equals(run)||!p[2].equals(Integer.toString(entries.size()+1))||!p[8].equals(previous))throw new IOException("Journal schema/order/run");long t;try{t=Long.parseLong(p[3]);Long.parseLong(p[4]);}catch(Exception e){throw new IOException("Time");}if(t<last||entries.size()>=MAX_ENTRIES)throw new IOException("Journal bounds/time");String body=line.substring(0,line.lastIndexOf('|'));String sum=hash(body.getBytes("UTF-8"));if(!sum.equals(p[9]))throw new IOException("Checksum");entries.add(line);previous=sum;last=t;}byteCount=bytes.length;loaded=true;
 }
 public void add(long time,long wall,String state,String event,String detail)throws IOException{if(!loaded)throw new IOException("Load first");if(entries.size()>=MAX_ENTRIES||time<last||time<0||wall<0||state==null||event==null||detail==null||!(state+event+detail).matches("[A-Za-z0-9_:.=, /-]*")||detail.length()>700)throw new IOException("Journal field/bound");String body="1|"+run+"|"+(entries.size()+1)+"|"+time+"|"+wall+"|"+state+"|"+event+"|"+detail+"|"+previous;String sum=hash(body.getBytes("UTF-8"));String line=body+"|"+sum;byte[] encoded=(line+"\n").getBytes("UTF-8");if(byteCount+encoded.length>131072)throw new IOException("Journal byte bound");store.append(encoded);byteCount+=encoded.length;entries.add(line);previous=sum;last=time;}
 public String[] entries(){return entries.toArray(new String[entries.size()]);}
 public int size(){return entries.size();}public long lastTime(){return last;}
}
