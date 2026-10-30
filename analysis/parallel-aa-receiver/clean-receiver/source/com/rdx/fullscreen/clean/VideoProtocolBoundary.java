package com.rdx.fullscreen.clean;
import java.util.*;
/** Pure callback/flow-control seam. Does not parse media headers or allocate a decoder. */
public final class VideoProtocolBoundary {
 private final List<VideoConfig> configs;private final VideoSink sink;private final int maxUnacked;private int selected=-1,unacked;private boolean open;
 public VideoProtocolBoundary(List<VideoConfig> c,VideoSink s,int max){if(c==null||c.isEmpty()||c.size()>8||s==null||max<1||max>32)throw new IllegalArgumentException("Video bounds");for(VideoConfig v:c)if(v==null)throw new IllegalArgumentException("Null config");configs=new ArrayList<VideoConfig>(c);sink=s;maxUnacked=max;}
 public void channelOpened(){if(open)throw new IllegalStateException("Already open");open=true;}
 public void selectConfiguration(int i){if(!open||selected!=-1||i<0||i>=configs.size())throw new IllegalStateException("Configuration selection");sink.configurationSelected(i,configs.get(i));selected=i;}
 public void accessUnit(byte[] bytes,long ptsUs){if(!open||selected<0||bytes==null||bytes.length<1||bytes.length>ProtocolLimits.ACCESS_UNIT||ptsUs<0||unacked>=maxUnacked)throw new IllegalArgumentException("Access-unit state/bounds/backpressure");sink.encodedAccessUnit(bytes.clone(),ptsUs);unacked++;}
 /** Returns the local consumed count; no wire acknowledgment is generated here. */
 public int acknowledge(int count){if(!open||count<1||count>unacked)throw new IllegalArgumentException("Invalid acknowledgment");unacked-=count;return count;}
 public void stop(){if(!open)throw new IllegalStateException("Not open");open=false;selected=-1;unacked=0;sink.streamStopped();}
 public int pendingAcknowledgments(){return unacked;}
}
