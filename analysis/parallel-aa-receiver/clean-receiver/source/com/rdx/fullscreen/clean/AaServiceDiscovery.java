package com.rdx.fullscreen.clean;
import java.util.*;
/** Immutable capabilities. Wire serialization is explicit through DiscoveryCodec; never transmits. */
public final class AaServiceDiscovery {
 public final List<VideoConfig> video;public final InputConfig input;
 public AaServiceDiscovery(List<VideoConfig> configurations,InputConfig i){if(configurations==null||configurations.isEmpty()||configurations.size()>8)throw new IllegalArgumentException("Video list");for(VideoConfig v:configurations)if(v==null)throw new IllegalArgumentException("Null video");video=Collections.unmodifiableList(new ArrayList<VideoConfig>(configurations));input=i;}
 public static AaServiceDiscovery conservativeOnly(){return new AaServiceDiscovery(Collections.singletonList(VideoConfig.conservative()),null);}
}
