package com.rdx.fullscreen.clean;
import java.io.*;
import java.util.*;
/** HOST ONLY. Batch DataInput/DataOutput reference, independent of all production codecs/constants. */
public final class ReferenceWireOracle {
 public static final class Frame {
  public final int channel,flags,total;public final byte[] body;
  public Frame(int c,int f,int t,byte[] b){channel=c;flags=f;total=t;body=b.clone();}
 }
 public static final class Message {
  public final int channel,flags;public final byte[] body;
  Message(int c,int f,byte[] b){channel=c;flags=f;body=b;}
 }
 private static final class Partial {int total,flags,count;ByteArrayOutputStream bytes=new ByteArrayOutputStream();}
 private ReferenceWireOracle(){}
 public static byte[] encode(List<Frame> frames){
  try{ByteArrayOutputStream memory=new ByteArrayOutputStream();DataOutputStream out=new DataOutputStream(memory);
   for(Frame f:frames){out.writeByte(f.channel);out.writeByte(f.flags);out.writeShort(f.body.length);if((f.flags&3)==1)out.writeInt(f.total);out.write(f.body);}out.flush();return memory.toByteArray();
  }catch(IOException e){throw new AssertionError(e);}
 }
 public static List<Frame> parse(byte[] wire){
  if(wire==null)throw new IllegalArgumentException("Null oracle input");
  try{DataInputStream in=new DataInputStream(new ByteArrayInputStream(wire));List<Frame> frames=new ArrayList<Frame>();
   while(in.available()>0){if(in.available()<4)throw new IllegalArgumentException("Truncated oracle header");int c=in.readUnsignedByte(),f=in.readUnsignedByte(),n=in.readUnsignedShort(),total=-1;
    if((f&0xf0)!=0||n>16384||frames.size()>=256)throw new IllegalArgumentException("Oracle frame bounds");
    if((f&3)==1){if(in.available()<4)throw new IllegalArgumentException("Truncated oracle extension");long unsigned=in.readInt()&0xffffffffL;if(unsigned<2||unsigned>65536)throw new IllegalArgumentException("Oracle total");total=(int)unsigned;}
    if(n>in.available())throw new IllegalArgumentException("Truncated oracle body");byte[] b=new byte[n];in.readFully(b);frames.add(new Frame(c,f,total,b));
   }return frames;
  }catch(IOException e){throw new IllegalArgumentException("Oracle IO over in-memory bytes",e);}
 }
 public static List<Message> reassemble(List<Frame> frames){
  Map<Integer,Partial> pending=new TreeMap<Integer,Partial>();List<Message> out=new ArrayList<Message>();int reservations=0;
  for(Frame f:frames){if((f.flags&8)!=0)throw new IllegalArgumentException("Oracle requires plaintext");int kind=f.flags&3;Partial p=pending.get(f.channel);
   switch(kind){
    case 3:if(p!=null||f.body.length<2)throw new IllegalArgumentException("Oracle overlap/type");out.add(new Message(f.channel,f.flags&12,f.body.clone()));continue;
    case 1:if(p!=null||pending.size()>=8||f.total>524288-reservations)throw new IllegalArgumentException("Oracle partial limits");p=new Partial();p.total=f.total;p.flags=f.flags&12;pending.put(f.channel,p);reservations+=p.total;break;
    case 0:case 2:if(p==null)throw new IllegalArgumentException("Oracle unexpected continuation");break;
    default:throw new AssertionError("Two-bit enum");
   }
   if(++p.count>256||p.flags!=(f.flags&12)||f.body.length>p.total-p.bytes.size())throw new IllegalArgumentException("Oracle fragment state/bounds");
   p.bytes.write(f.body,0,f.body.length);
   if(kind==2){if(p.bytes.size()!=p.total)throw new IllegalArgumentException("Oracle underflow");pending.remove(f.channel);reservations-=p.total;out.add(new Message(f.channel,p.flags,p.bytes.toByteArray()));}
  }
  if(!pending.isEmpty())throw new IllegalArgumentException("Oracle incomplete logical message");return out;
 }
 public static List<Frame> fragment(int channel,int state,byte[] body,int[] lengths){
  List<Frame> frames=new ArrayList<Frame>();int offset=0;
  for(int i=0;i<lengths.length;i++){int n=lengths[i];if(n<0||n>body.length-offset)throw new IllegalArgumentException("Oracle fragment plan");int flag=lengths.length==1?3:(i==0?1:(i==lengths.length-1?2:0));frames.add(new Frame(channel,state|flag,i==0&&lengths.length>1?body.length:-1,Arrays.copyOfRange(body,offset,offset+n)));offset+=n;}
  if(offset!=body.length)throw new IllegalArgumentException("Oracle plan incomplete");return frames;
 }
}
