package com.rdx.fullscreen.decodertest;
import android.content.res.AssetFileDescriptor;
import android.content.res.AssetManager;
import android.media.*;
import android.os.SystemClock;
import android.util.Log;
import android.view.Surface;
import java.nio.ByteBuffer;
import java.io.InputStreamReader;
import org.json.*;

/** Only the exact named TI component is used, after explicit START. */
public final class DecodeWorker extends Thread {
 public interface Listener { void completed(String result); void progress(String status); }
 public static final String CODEC="OMX.TI.DUCATI1.VIDEO.DECODER";
 private final AssetManager assets; private final String clip; private final Surface surface; private final Listener listener;
 private volatile boolean cancelled;
 private MediaExtractor extractor; private MediaCodec codec; private AssetFileDescriptor asset;
 private ByteBuffer[] inputs; private final MediaCodec.BufferInfo info=new MediaCodec.BufferInfo();
 private boolean started,inEos,outEos; private int queued,received,released;
 private long begin,firstPts=-1,clockStart; private String result="STOP";
 private volatile long cleanupBeginMs;private long lastProgress;
 public DecodeWorker(AssetManager a,String c,Surface s,Listener l) { super("RdxDecodeWorker");assets=a;clip=c;surface=s;listener=l; }
 public void cancel() { cancelled=true;interrupt(); }
 public long cleanupBeginMs(){return cleanupBeginMs;}
 private void log(String s) { Log.i("RDX.DECODER",s);long now=SystemClock.elapsedRealtime();if(now-lastProgress>=1000||s.startsWith("CREATED")||s.startsWith("CONFIGURED")||s.startsWith("OUTPUT_FORMAT")){lastProgress=now;listener.progress(s);} }
 @Override public void run() {
  begin=SystemClock.elapsedRealtime();
  try { setup(); pump(); result=cancelled?"CANCELLED":outEos?"EOS":"TIMEOUT; STOP further testing"; }
  catch(InterruptedException e) { result="CANCELLED";Thread.currentThread().interrupt(); }
  catch(Exception e) { result="ERROR; STOP: "+e;Log.e("RDX.DECODER",result,e); }
  finally { cleanup(); }
  String summary=result+" inputQueued="+queued+" outputReceived="+received+" outputReleased="+released
   +" durationMs="+(SystemClock.elapsedRealtime()-begin)+"; counts do not prove displayed frames";
  log("END wallMs="+System.currentTimeMillis()+" "+summary);listener.completed(summary);
 }
 private void setup() throws Exception {
  log("BEGIN clip="+clip+" requestedCodec="+CODEC+" wallMs="+System.currentTimeMillis());
  logHostSps();
  asset=assets.openFd("clips/"+clip);
  extractor=new MediaExtractor();extractor.setDataSource(asset.getFileDescriptor(),asset.getStartOffset(),asset.getLength());
  int track=-1;MediaFormat format=null;
  for(int i=0;i<extractor.getTrackCount();i++) {
   MediaFormat f=extractor.getTrackFormat(i);
   if("video/avc".equals(f.getString(MediaFormat.KEY_MIME))) { track=i;format=f;break; }
  }
  if(track<0)throw new IllegalStateException("No H264 video track");
  extractor.selectTrack(track);log("INPUT_FORMAT "+format);
  fields("INPUT",format);
  if(cancelled)throw new InterruptedException();
  codec=MediaCodec.createByCodecName(CODEC);log("CREATED "+codec.getName());
  codec.configure(format,surface,null,0);log("CONFIGURED");
  codec.start();started=true;inputs=codec.getInputBuffers();log("STARTED");
 }
 private void pump() throws Exception {
  while(!cancelled&&!outEos&&SystemClock.elapsedRealtime()-begin<20000) {
   if(!inEos) queueOne();
   drainOne();
  }
 }
 private void queueOne() {
  int index=codec.dequeueInputBuffer(2000);if(index<0)return;
  ByteBuffer buffer=inputs[index];buffer.clear();int size=extractor.readSampleData(buffer,0);
  if(size<0) { codec.queueInputBuffer(index,0,0,0,MediaCodec.BUFFER_FLAG_END_OF_STREAM);inEos=true;return; }
  long pts=extractor.getSampleTime();codec.queueInputBuffer(index,0,size,pts,0);queued++;
  log("INPUT n="+queued+" ptsUs="+pts+" bytes="+size);extractor.advance();
 }
 private void drainOne() throws InterruptedException {
  int index=codec.dequeueOutputBuffer(info,2000);
  if(index==MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) { MediaFormat f=codec.getOutputFormat();log("OUTPUT_FORMAT "+f);fields("OUTPUT",f);return; }
  if(index<0)return;
  received++;
  boolean render=(info.flags&MediaCodec.BUFFER_FLAG_CODEC_CONFIG)==0
   && ((info.flags&MediaCodec.BUFFER_FLAG_END_OF_STREAM)==0||info.size>0);
  if(render) {
   if(firstPts<0) { firstPts=info.presentationTimeUs;clockStart=SystemClock.elapsedRealtime(); }
   long due=clockStart+(info.presentationTimeUs-firstPts)/1000;
   while(!cancelled&&SystemClock.elapsedRealtime()<due&&SystemClock.elapsedRealtime()-begin<20000)Thread.sleep(2);
  }
  codec.releaseOutputBuffer(index,render&&!cancelled);released++;
  log("OUTPUT n="+received+" ptsUs="+info.presentationTimeUs+" bytes="+info.size+" flags="+info.flags
   +" renderRequested="+(render&&!cancelled)+" elapsedMs="+(SystemClock.elapsedRealtime()-begin));
  outEos=(info.flags&MediaCodec.BUFFER_FLAG_END_OF_STREAM)!=0;
 }
 private void cleanup() {
  cleanupBeginMs=SystemClock.elapsedRealtime();
  log("CLEANUP_BEGIN");
  if(codec!=null) {
   try { if(started)codec.stop(); } catch(Exception e) { log("STOP_ERROR "+e);result="CLEANUP_ERROR; STOP"; }
   try { codec.release(); } catch(Exception e) { log("RELEASE_ERROR "+e);result="CLEANUP_ERROR; STOP"; }
  }
  if(extractor!=null)try { extractor.release(); } catch(Exception e) { log("EXTRACTOR_RELEASE_ERROR "+e);result="CLEANUP_ERROR; STOP"; }
  if(asset!=null)try { asset.close(); } catch(Exception e) { log("ASSET_CLOSE_ERROR "+e);result="CLEANUP_ERROR; STOP"; }
 }
 private void fields(String kind,MediaFormat format){
  String[] keys={"mime","width","height","frame-rate","profile","level","crop-left","crop-right","crop-top","crop-bottom","stride","slice-height"};
  for(String key:keys)log(kind+"_FIELD "+key+"="+field(format,key));
 }
 private String field(MediaFormat f,String key){if(!f.containsKey(key))return "UNAVAILABLE";try{return "mime".equals(key)?f.getString(key):String.valueOf(f.getInteger(key));}catch(ClassCastException e){try{return String.valueOf(f.getFloat(key));}catch(RuntimeException other){return "TYPE_UNAVAILABLE; see raw format";}}}
 private void logHostSps() throws Exception {
  InputStreamReader reader=new InputStreamReader(assets.open("clip-catalog.json"),"UTF-8");StringBuilder text=new StringBuilder();
  try{char[] chars=new char[2048];int n;while((n=reader.read(chars))!=-1){text.append(chars,0,n);if(text.length()>65536)throw new IllegalStateException("Metadata bound");}}finally{reader.close();}
  JSONArray entries=new JSONObject(text.toString()).getJSONArray("clips");
  for(int i=0;i<entries.length();i++){JSONObject e=entries.getJSONObject(i);if(clip.equals(e.getString("file"))){log("HOST_VERIFIED_INPUT_SPS "+e.getJSONObject("SPS")+" expectedAssetSHA256="+e.getString("sha256"));return;}}
  throw new IllegalStateException("Clip missing from independently inspected catalog");
 }
}
