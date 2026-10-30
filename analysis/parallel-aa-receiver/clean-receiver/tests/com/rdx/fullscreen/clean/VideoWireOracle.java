package com.rdx.fullscreen.clean;
import java.io.ByteArrayOutputStream;
/** Independent test oracle: explicit BE64 envelope, no production parser/constants imported. */
public final class VideoWireOracle {
 /** Structurally independent count-only sender model, no production window/token imports. */
 public static final class CreditOracle {
  private final int capacity;private int debt;
  public CreditOracle(int cap){capacity=cap;}
  public int debt(){return debt;}
  public boolean offer(){if(debt==capacity)return false;debt++;return true;}
  public boolean ack(int count){if(count<=0||count>debt)return false;debt-=count;return true;}
 }
 public static final class Value {public int type;public long timestamp;public byte[] body;}
 public static Value decode(byte[] logical){if(logical==null||logical.length<2||logical.length>1048578)throw new IllegalArgumentException();Value v=new Value();v.type=(logical[0]&255)*256+(logical[1]&255);int skip=v.type==0?10:v.type==1?2:-1;if(skip<0||logical.length<skip)throw new IllegalArgumentException();if(v.type==0)for(int i=2;i<10;i++)v.timestamp=v.timestamp*256+(logical[i]&255L);v.body=new byte[logical.length-skip];System.arraycopy(logical,skip,v.body,0,v.body.length);return v;}
 public static byte[] packet(int type,long bits,byte[] data){ByteArrayOutputStream out=new ByteArrayOutputStream();out.write(type/256);out.write(type%256);if(type==0)for(int i=7;i>=0;i--)out.write((int)(bits>>>(i*8))&255);out.write(data,0,data.length);return out.toByteArray();}
 /** Manually encoded AAP fragments, independent of production writer/parser. */
 public static byte[] framed(int channel,byte[] logical,int fragment){if(channel<1||channel>255||fragment<2||fragment>16000)throw new IllegalArgumentException();ByteArrayOutputStream out=new ByteArrayOutputStream();int pos=0;while(pos<logical.length){int n=Math.min(fragment,logical.length-pos);boolean first=pos==0,last=pos+n==logical.length;int flags=(first?1:0)|(last?2:0);out.write(channel);out.write(flags);out.write(n/256);out.write(n%256);if(first&&!last)for(int i=3;i>=0;i--)out.write((logical.length>>>(8*i))&255);out.write(logical,pos,n);pos+=n;}return out.toByteArray();}
}
