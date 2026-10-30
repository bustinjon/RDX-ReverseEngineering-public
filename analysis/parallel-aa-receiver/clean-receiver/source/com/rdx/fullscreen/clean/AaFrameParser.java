package com.rdx.fullscreen.clean;
import java.util.*;
/** Incremental outer-envelope parser. TLS bodies remain opaque. Discard parser on error. */
public final class AaFrameParser {
 private final int maxBody,maxMessage,maxFrames;private final byte[] header=new byte[8];
 private int have,need=4,bodyHave,channel,flags,total=-1;private byte[] body;private boolean failed;
 public AaFrameParser(int b,int m,int frames){if(b<1||b>65535||m<2||m>16777216||frames<1||frames>4096)throw new IllegalArgumentException("Limits");maxBody=b;maxMessage=m;maxFrames=frames;}
 public List<AaFrame> feed(byte[] input){return feed(input,0,input==null?0:input.length);}
 public List<AaFrame> feed(byte[] input,int offset,int length){
  if(failed)throw new IllegalStateException("Parser failed; explicit reset required");
  try{return feedChecked(input,offset,length);}catch(RuntimeException e){reset();failed=true;throw e;}
 }
 private List<AaFrame> feedChecked(byte[] input,int offset,int length){
  if(input==null||offset<0||length<0||offset>input.length-length)throw new IllegalArgumentException("Input bounds");
  List<AaFrame> result=new ArrayList<AaFrame>();int cursor=offset,end=offset+length;
  while(cursor<end){
   if(body==null){int n=Math.min(need-have,end-cursor);System.arraycopy(input,cursor,header,have,n);have+=n;cursor+=n;if(have<need)continue;
    if(need==4){channel=header[0]&255;flags=header[1]&255;if((flags&~15)!=0)throw new IllegalArgumentException("Reserved flags");int size=((header[2]&255)<<8)|(header[3]&255);if(size>maxBody)throw new IllegalArgumentException("Frame body limit");
     if((flags&AaFrame.FIRST)!=0&&(flags&AaFrame.LAST)==0){need=8;continue;}
    }
    if(need==8){long totalValue=0;for(int i=4;i<8;i++)totalValue=(totalValue<<8)|(header[i]&255);if(totalValue<2||totalValue>maxMessage)throw new IllegalArgumentException("Message length limit");total=(int)totalValue;}
    body=new byte[((header[2]&255)<<8)|(header[3]&255)];bodyHave=0;
   }
   int n=Math.min(body.length-bodyHave,end-cursor);System.arraycopy(input,cursor,body,bodyHave,n);bodyHave+=n;cursor+=n;
   if(bodyHave==body.length){if(result.size()>=maxFrames)throw new IllegalArgumentException("Frames/feed limit");result.add(new AaFrame(channel,flags,total,body));clearFrame();}
  }
  return result;
 }
 public boolean hasPartialFrame(){return have!=0||body!=null;}
 public boolean isFailed(){return failed;}
 public int bufferedBytes(){return have+bodyHave;}
 public void endOfInput(){if(failed)throw new IllegalStateException("Parser failed");if(hasPartialFrame()){reset();failed=true;throw new IllegalArgumentException("Truncated frame");}}
 private void clearFrame(){have=0;need=4;body=null;bodyHave=0;total=-1;}
 public void reset(){clearFrame();failed=false;}
}
