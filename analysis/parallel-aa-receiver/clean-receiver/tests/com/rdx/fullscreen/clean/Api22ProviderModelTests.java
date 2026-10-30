package com.rdx.fullscreen.clean;

import java.io.ByteArrayOutputStream;
import java.lang.reflect.*;
import java.nio.ByteBuffer;
import java.util.*;
import javax.net.ssl.*;
import com.rdx.fullscreen.clean.TlsPumpResults.*;

/** Evidence-derived semantic models ONLY. Does not load Android code/native libraries or perform TLS.
 * Provenance and limitations: API22-PROVIDER-DIFFERENTIAL.md. A PASS is NOT provider qualification.
 */
public final class Api22ProviderModelTests {
 private static int checks, properties;
 private static boolean generated;
 private static final long SEED=0x22C05C7A20261024L;
 private static void check(boolean b,String name){if(generated)properties++;else checks++;if(!b)throw new AssertionError(name);}
 private static void field(Object o,String name,Object v)throws Exception{Field f=MemoryTlsEngine.class.getDeclaredField(name);f.setAccessible(true);f.set(o,v);}
 private static MemoryTlsEngine driver(Script e,MemoryTlsEngine.State state)throws Exception{
  MemoryTlsEngine d=new MemoryTlsEngine();field(d,"engine",e);field(d,"state",state);field(d,"owner",Thread.currentThread());field(d,"provider","AndroidOpenSSL-MODEL-NOT-RUNTIME");return d;
 }
 /** BIOSink.position is a read cursor. Writing output does not increment it. */
 private static final class Sink {
  final ByteArrayOutputStream bytes=new ByteArrayOutputStream();int cursor;
  int available(){return bytes.size()-cursor;}
  void write(byte[] b){bytes.write(b,0,b.length);}
  byte[] drain(int n){n=Math.min(n,available());byte[] b=Arrays.copyOfRange(bytes.toByteArray(),cursor,cursor+n);cursor+=n;if(cursor==bytes.size()){bytes.reset();cursor=0;}return b;}
 }
 /** Scripted public SSLEngine return patterns extracted from saved Java/DEX, NOT Conscrypt execution. */
 private static final class Script extends SSLEngine {
  enum Mode { HANDSHAKE, BUFFERED_PLAINTEXT, PEER_CLOSE, LOCAL_CLOSE, GETTER_FINISHED }
  final Mode mode;final Sink sink=new Sink();boolean inputSeen,done,inDone,outDone,freed;int closeInboundCalls;
  Script(Mode m){mode=m;}
  private SSLEngineResult r(SSLEngineResult.Status s,int c,int p,SSLEngineResult.HandshakeStatus h){return new SSLEngineResult(s,h,c,p);}
  public SSLEngineResult.HandshakeStatus getHandshakeStatus(){
   if(mode==Mode.GETTER_FINISHED&&!done){done=true;return SSLEngineResult.HandshakeStatus.FINISHED;}
   if(mode!=Mode.HANDSHAKE||done)return SSLEngineResult.HandshakeStatus.NOT_HANDSHAKING;
   return sink.available()>0?SSLEngineResult.HandshakeStatus.NEED_WRAP:SSLEngineResult.HandshakeStatus.NEED_UNWRAP;
  }
  public SSLEngineResult wrap(ByteBuffer[] srcs,int offset,int length,ByteBuffer dst){
   if(dst.remaining()<16709)return r(SSLEngineResult.Status.BUFFER_OVERFLOW,0,0,getHandshakeStatus());
   if(outDone)return r(SSLEngineResult.Status.CLOSED,0,0,getHandshakeStatus());
   if(mode==Mode.HANDSHAKE){byte[] b=sink.drain(dst.remaining());dst.put(b);done=inputSeen&&sink.available()==0;return r(SSLEngineResult.Status.OK,0,b.length,done?SSLEngineResult.HandshakeStatus.FINISHED:getHandshakeStatus());}
   return r(SSLEngineResult.Status.OK,0,0,getHandshakeStatus());
  }
  public SSLEngineResult unwrap(ByteBuffer src,ByteBuffer[] dsts,int offset,int length){
   if(mode==Mode.HANDSHAKE){int c=src.remaining();src.position(src.limit());inputSeen=true;sink.write(new byte[]{4,5,6});return r(SSLEngineResult.Status.OK,c,0,getHandshakeStatus());}
   if(mode==Mode.BUFFERED_PLAINTEXT){if(dsts[offset].remaining()==0)return r(SSLEngineResult.Status.BUFFER_OVERFLOW,0,0,getHandshakeStatus());dsts[offset].put((byte)42);return r(SSLEngineResult.Status.BUFFER_UNDERFLOW,0,1,getHandshakeStatus());}
   if(mode==Mode.PEER_CLOSE){int c=src.remaining();src.position(src.limit());inDone=true;return r(c>0?SSLEngineResult.Status.OK:SSLEngineResult.Status.BUFFER_UNDERFLOW,c,0,getHandshakeStatus());}
   return r(SSLEngineResult.Status.BUFFER_UNDERFLOW,0,0,getHandshakeStatus());
  }
  public void closeOutbound(){sink.write(new byte[]{21,3,3,0,1,0});freed=true;outDone=true;}
  public void closeInbound(){closeInboundCalls++;inDone=true;}
  public boolean isInboundDone(){return inDone;} public boolean isOutboundDone(){return outDone;}
  public Runnable getDelegatedTask(){return null;} public void beginHandshake(){}
  public SSLSession getSession(){return (SSLSession)Proxy.newProxyInstance(SSLSession.class.getClassLoader(),new Class<?>[]{SSLSession.class},new InvocationHandler(){public Object invoke(Object p,Method m,Object[] a){if(m.getName().equals("getPacketBufferSize"))return Integer.valueOf(18437);if(m.getName().equals("getApplicationBufferSize"))return Integer.valueOf(16384);throw new UnsupportedOperationException(m.getName());}});}
  public String[] getSupportedCipherSuites(){return new String[]{"TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256"};}public String[] getEnabledCipherSuites(){return getSupportedCipherSuites();}public void setEnabledCipherSuites(String[] a){}
  public String[] getSupportedProtocols(){return new String[]{"TLSv1.2"};}public String[] getEnabledProtocols(){return getSupportedProtocols();}public void setEnabledProtocols(String[] a){}
  public void setUseClientMode(boolean b){}public boolean getUseClientMode(){return true;}public void setNeedClientAuth(boolean b){}public boolean getNeedClientAuth(){return true;}public void setWantClientAuth(boolean b){}public boolean getWantClientAuth(){return false;}public void setEnableSessionCreation(boolean b){}public boolean getEnableSessionCreation(){return true;}
 }
 private static void deterministic()throws Exception{
  Sink sink=new Sink();sink.write(new byte[]{1,2,3,4,5});check(sink.cursor==0&&sink.available()==5,"write does not move read cursor");check(Arrays.equals(sink.drain(2),new byte[]{1,2}),"partial output drain");check(sink.cursor==2&&sink.available()==3,"partial residue accounted");sink.drain(99);check(sink.cursor==0&&sink.available()==0,"full drain resets read cursor");
  Script hs=new Script(Script.Mode.HANDSHAKE);MemoryTlsEngine h=driver(hs,MemoryTlsEngine.State.HANDSHAKING);HandshakeResult r=h.handshake(new byte[]{1,2});check(r.consumed==2&&r.produced==3,"same logical pump consumes input and drains staged output");check(r.cryptoComplete&&r.action==Action.VERIFY_PEER,"final flight preserved before verify gate");check(h.state()==MemoryTlsEngine.State.CRYPTO_COMPLETE_VERIFY_PENDING,"no application before verification");check(Arrays.equals(r.output(),new byte[]{4,5,6}),"exact final flight");check(h.tasks==0,"target no delegated tasks model");
  MemoryTlsEngine u=driver(new Script(Script.Mode.BUFFERED_PLAINTEXT),MemoryTlsEngine.State.APPLICATION);DecryptResult ur=u.unwrap(11,new byte[0],1);check(ur.consumed==0&&ur.produced==1,"underflow plus plaintext retained");check(ur.status.equals("BUFFER_UNDERFLOW")&&ur.output()[0]==42,"underflow does not discard plaintext");check(ur.boundary==Boundary.COMPLETION_UNPROVEN,"raw underflow never certifies frame");check(u.proveBodyBoundary(new byte[]{23,3,3,0,1,1},true)==Boundary.COMPLETION_UNPROVEN,"Android provider profile NOT auto-qualified");
  MemoryTlsEngine ov=driver(new Script(Script.Mode.LOCAL_CLOSE),MemoryTlsEngine.State.APPLICATION);EncryptResult or=ov.wrap(12,new byte[]{1},0,1,16708);check(or.consumed==0&&or.produced==0&&or.status.equals("BUFFER_OVERFLOW"),"16709 minimum preserves source on overflow");
  Script peer=new Script(Script.Mode.PEER_CLOSE);MemoryTlsEngine pd=driver(peer,MemoryTlsEngine.State.APPLICATION);DecryptResult pr=pd.unwrap(13,new byte[]{1},10);check(peer.isInboundDone()&&!pr.peerClosed,"STATIC GAP: current wrapper does not normalize inboundDone with OK");check(pd.state()==MemoryTlsEngine.State.APPLICATION,"gap exposed; not target qualification");
  Script local=new Script(Script.Mode.LOCAL_CLOSE);MemoryTlsEngine ld=driver(local,MemoryTlsEngine.State.APPLICATION);CloseResult cr=ld.beginClose();check(local.freed&&local.sink.available()>0,"STATIC CONFLICT: close can retain unreachable output after free");check(cr.produced==0&&cr.outboundClosed,"closed wrap cannot drain staged close model");check(ld.state()==MemoryTlsEngine.State.LOCAL_CLOSING,"no fabricated clean completion");
  Script eof=new Script(Script.Mode.LOCAL_CLOSE);MemoryTlsEngine ed=driver(eof,MemoryTlsEngine.State.APPLICATION);boolean rejected=false;try{ed.transportEof();}catch(SSLException e){rejected=e.getMessage().contains("TRUNCATED");}check(rejected&&ed.state()==MemoryTlsEngine.State.FAILED&&eof.closeInboundCalls==1,"quiet platform closeInbound cannot relabel EOF clean");
  MemoryTlsEngine fg=driver(new Script(Script.Mode.GETTER_FINISHED),MemoryTlsEngine.State.HANDSHAKING);boolean getterGap=false;try{fg.handshake(new byte[0]);}catch(SSLException e){getterGap=true;}check(getterGap&&fg.state()==MemoryTlsEngine.State.FAILED,"out-of-band getter FINISHED is conservative failure; normal result FINISHED passed");
  ByteBuffer[] a={ByteBuffer.allocate(0),ByteBuffer.allocate(1)};int targetIndex=-1;for(int i=1;i<1;i++)if(a[i].remaining()>0)targetIndex=i;check(targetIndex==-1&&a[1].remaining()==1,"saved nonzero-offset loop misses destination; current adapter avoids array overload");
 }
 private static byte[] record(Random random,int n){byte[] b=new byte[n+5];random.nextBytes(b);b[0]=23;b[1]=3;b[2]=3;b[3]=(byte)(n>>>8);b[4]=(byte)n;return b;}
 private static void corpus(){generated=true;Random random=new Random(SEED);
  for(int sequence=0;sequence<10000;sequence++){
   int records=1+random.nextInt(4);ByteArrayOutputStream wire=new ByteArrayOutputStream();Sink sink=new Sink();
   for(int i=0;i<records;i++){byte[] b=record(random,1+random.nextInt(1024));wire.write(b,0,b.length);}
   byte[] all=wire.toByteArray();check(TlsRecordLedger.completeApplicationRecords(all)==records,"independent complete record expectation sequence="+sequence);
   int drained=0;sink.write(all);check(sink.cursor==0,"generated output independent of cursor");ByteArrayOutputStream recovered=new ByteArrayOutputStream();
   while(sink.available()>0){byte[] out=sink.drain(1+random.nextInt(127));recovered.write(out,0,out.length);drained+=out.length;check(drained<=all.length&&sink.available()==all.length-drained,"bounded drain accounting");}
   check(Arrays.equals(all,recovered.toByteArray())&&sink.cursor==0,"exact bytes after arbitrary drains");
   // Every selected truncated tail is inside the final record body, never a complete preceding-record boundary.
   int cut=all.length-1;
   boolean reject=false;try{TlsRecordLedger.completeApplicationRecords(Arrays.copyOf(all,cut));}catch(IllegalArgumentException e){reject=true;}check(reject,"partial record cannot prove body complete");
   for(int n=1;n<5;n++){byte[] partial=Arrays.copyOf(all,all.length+n);partial[all.length]=23;boolean bad=false;try{TlsRecordLedger.completeApplicationRecords(partial);}catch(IllegalArgumentException e){bad=true;}check(bad,"record plus partial next header rejected");}
  }
  generated=false;
 }
 public static void main(String[] args)throws Exception{deterministic();corpus();System.out.println("RESULT PASS deterministic="+checks+" propertyChecks="+properties+" modelSequences=10000 seed="+SEED+" api22RuntimeCases=0; STATIC-EVIDENCE MODEL ONLY; no Android provider/native/crypto/network/ADB");}
}
