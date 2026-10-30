package com.rdx.fullscreen.decodertest;
import android.content.res.AssetFileDescriptor;
import android.content.res.AssetManager;
import android.media.*;
import android.os.SystemClock;
import android.util.Log;
import android.view.Surface;
import java.nio.ByteBuffer;

/** Only the exact named TI component is used, after explicit START. */
public final class DecodeWorker extends Thread {
 public interface Listener { void completed(String result); }
 public static final String CODEC="OMX.TI.DUCATI1.VIDEO.DECODER";
 private final AssetManager assets; private final String clip; private final Surface surface; private final Listener listener;
 private volatile boolean cancelled;
 private MediaExtractor extractor; private MediaCodec codec; private AssetFileDescriptor asset;
 private ByteBuffer[] inputs; private final MediaCodec.BufferInfo info=new MediaCodec.BufferInfo();
 private boolean started,inEos,outEos; private int queued,received,released;
 private long begin,firstPts=-1,clockStart; private String result="STOP";
 public DecodeWorker(AssetManager a,String c,Surface s,Listener l) { super("RdxDecodeWorker");assets=a;clip=c;surface=s;listener=l; }
 public void cancel() { cancelled=true;interrupt(); }
 private void log(String s) { Log.i("RDX.DECODER",s); }
 @Override public void run() {
  begin=SystemClock.elapsedRealtime();
  try { setup(); pump(); result=cancelled?"CANCELLED":outEos?"EOS":"TIMEOUT; STOP further testing"; }
  catch(InterruptedException e) { result="CANCELLED";Thread.currentThread().interrupt(); }
  catch(Exception e) { result="ERROR; STOP: "+e;Log.e("RDX.DECODER",result,e); }
  finally { cleanup(); }
  String summary=result+" inputQueued="+queued+" outputReceived="+received+" outputReleased="+released
   +" durationMs="+(SystemClock.elapsedRealtime()-begin)+"; counts do not prove displayed frames";
  log("END "+summary);listener.completed(summary);
 }
 private void setup() throws Exception {
  log("BEGIN clip="+clip+" requestedCodec="+CODEC+" wallMs="+System.currentTimeMillis());
  asset=assets.openFd("clips/"+clip);
  extractor=new MediaExtractor();extractor.setDataSource(asset.getFileDescriptor(),asset.getStartOffset(),asset.getLength());
  int track=-1;MediaFormat format=null;
  for(int i=0;i<extractor.getTrackCount();i++) {
   MediaFormat f=extractor.getTrackFormat(i);
   if("video/avc".equals(f.getString(MediaFormat.KEY_MIME))) { track=i;format=f;break; }
  }
  if(track<0)throw new IllegalStateException("No H264 video track");
  extractor.selectTrack(track);log("INPUT_FORMAT "+format);
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
  if(index==MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) { log("OUTPUT_FORMAT "+codec.getOutputFormat());return; }
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
  log("CLEANUP_BEGIN");
  if(codec!=null) {
   try { if(started)codec.stop(); } catch(Exception e) { log("STOP_ERROR "+e);result="CLEANUP_ERROR; STOP"; }
   try { codec.release(); } catch(Exception e) { log("RELEASE_ERROR "+e);result="CLEANUP_ERROR; STOP"; }
  }
  if(extractor!=null)try { extractor.release(); } catch(Exception e) { log("EXTRACTOR_RELEASE_ERROR "+e);result="CLEANUP_ERROR; STOP"; }
  if(asset!=null)try { asset.close(); } catch(Exception e) { log("ASSET_CLOSE_ERROR "+e);result="CLEANUP_ERROR; STOP"; }
 }
}
