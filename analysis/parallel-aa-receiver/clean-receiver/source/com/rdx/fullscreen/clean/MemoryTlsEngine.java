package com.rdx.fullscreen.clean;
import java.nio.ByteBuffer;
import java.io.ByteArrayOutputStream;
import java.util.*;
import java.security.cert.X509Certificate;
import javax.net.ssl.*;
import com.rdx.fullscreen.clean.TlsPumpResults.*;
/** Explicitly driven memory engine. No sockets, thread creation, credentials or engine in constructor. */
public final class MemoryTlsEngine {
 public enum State { NEW,HANDSHAKING,CRYPTO_COMPLETE_VERIFY_PENDING,VERIFIED,APPLICATION,LOCAL_CLOSING,PEER_CLOSED,CLOSED,FAILED }
 private State state=State.NEW;private SSLEngine engine;private ByteBuffer inbound=ByteBuffer.allocate(65535);private Thread owner;private boolean cryptoComplete,profile;
 private final ArrayDeque<String> trace=new ArrayDeque<String>();
 public long wraps,unwraps,tasks,consumed,produced,underflows,overflows,partialConsumes;public int maxPacket,maxApplication,maxPending;public String provider="UNINITIALIZED";
 public MemoryTlsEngine(){}
 public State state(){return state;}public int pending(){return inbound.position();}public boolean application(){return state==State.APPLICATION;}
 public String protocol(){return engine.getSession().getProtocol();}public String cipher(){return engine.getSession().getCipherSuite();}
 public int packetSize(){return engine.getSession().getPacketBufferSize();}public int applicationSize(){return engine.getSession().getApplicationBufferSize();}
 public List<String> trace(){return Collections.unmodifiableList(new ArrayList<String>(trace));}
 private void own(){if(owner!=Thread.currentThread())throw new IllegalStateException("TLS owner/thread");if(state==State.FAILED||state==State.CLOSED)throw new IllegalStateException("Terminal TLS");}
 private void log(String s){if(trace.size()==128)trace.removeFirst();trace.addLast(s);}
 public void initialize(SSLContext context,boolean client,boolean mutual)throws SSLException{
  if(state!=State.NEW||context==null)throw new IllegalStateException("Explicit fresh initialize");owner=Thread.currentThread();provider=context.getProvider().getName();profile=provider.equals("SunJSSE");
  engine=context.createSSLEngine();engine.setUseClientMode(client);engine.setEnabledProtocols(new String[]{"TLSv1.2"});engine.setEnabledCipherSuites(new String[]{"TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256"});if(!client)engine.setNeedClientAuth(mutual);
  engine.beginHandshake();state=State.HANDSHAKING;log("EXPLICIT_BEGIN role="+(client?"CLIENT":"TEST_SERVER")+" provider="+provider);
 }
 private void feed(byte[] b){if(b==null||b.length>inbound.remaining())throw new IllegalArgumentException("TLS input queue bound");inbound.put(b);maxPending=Math.max(maxPending,inbound.position());}
 private Action action(){SSLEngineResult.HandshakeStatus s=engine.getHandshakeStatus();if(s==SSLEngineResult.HandshakeStatus.NEED_TASK)return Action.RUN_LOCAL_TASK;if(s==SSLEngineResult.HandshakeStatus.NEED_WRAP)return Action.DRAIN_OUTPUT;if(s==SSLEngineResult.HandshakeStatus.NEED_UNWRAP)return Action.NEED_INPUT;return cryptoComplete?Action.VERIFY_PEER:Action.CONTINUE;}
 private SSLEngineResult io(boolean wrap,ByteBuffer src,ByteBuffer dst)throws SSLException{
  int offered=src.remaining(),si=src.position(),di=dst.position();SSLEngineResult r=wrap?engine.wrap(src,dst):engine.unwrap(src,dst);
  int c=src.position()-si,p=dst.position()-di;if(c!=r.bytesConsumed()||p!=r.bytesProduced()||c<0||c>offered)throw new SSLException("Provider buffer/result mismatch");
  if(wrap)wraps++;else unwraps++;consumed+=c;produced+=p;if(c>0&&c<offered)partialConsumes++;if(r.getStatus()==SSLEngineResult.Status.BUFFER_UNDERFLOW)underflows++;if(r.getStatus()==SSLEngineResult.Status.BUFFER_OVERFLOW)overflows++;
  if(r.getHandshakeStatus()==SSLEngineResult.HandshakeStatus.FINISHED)cryptoComplete=true;
  if(wrap)maxPacket=Math.max(maxPacket,dst.capacity());else maxApplication=Math.max(maxApplication,dst.capacity());
  log((wrap?"WRAP":"UNWRAP")+" offered="+offered+" consumed="+c+" produced="+p+" srcBefore="+si+" srcAfter="+src.position()+" dstBefore="+di+" dstAfter="+dst.position()+" status="+r.getStatus()+" hs="+r.getHandshakeStatus());return r;
 }
 public int runTasks(){own();if(engine.getHandshakeStatus()!=SSLEngineResult.HandshakeStatus.NEED_TASK)return 0;int n=0;Runnable task;try{while((task=engine.getDelegatedTask())!=null){if(++n>64)throw new IllegalStateException("TLS task bound");task.run();tasks++;}return n;}catch(RuntimeException e){abort();throw e;}}
 public HandshakeResult handshake(byte[] bytes)throws SSLException{
  own();if(state!=State.HANDSHAKING)throw new IllegalStateException("Handshake phase");feed(bytes);int offered=inbound.position(),used=0;ByteArrayOutputStream out=new ByteArrayOutputStream();String status="NO_CALL";
  try{for(int step=0;step<64;step++){
   SSLEngineResult.HandshakeStatus h=engine.getHandshakeStatus();if(h==SSLEngineResult.HandshakeStatus.NEED_TASK)break;
   if(h==SSLEngineResult.HandshakeStatus.NEED_WRAP){ByteBuffer dst=ByteBuffer.allocate(Math.min(65535,Math.max(18437,packetSize())));SSLEngineResult r=io(true,ByteBuffer.allocate(0),dst);status=r.getStatus().toString();if(out.size()+dst.position()>65535)throw new SSLException("Handshake output bound");out.write(dst.array(),0,dst.position());if(r.getStatus()==SSLEngineResult.Status.CLOSED)throw new SSLException("Handshake closed");if(r.bytesProduced()==0&&r.getHandshakeStatus()==h)throw new SSLException("Handshake no wrap progress");continue;}
   if(h==SSLEngineResult.HandshakeStatus.NEED_UNWRAP){if(inbound.position()==0)break;inbound.flip();ByteBuffer dst=ByteBuffer.allocate(Math.min(65535,Math.max(16384,applicationSize())));SSLEngineResult r=io(false,inbound,dst);used+=r.bytesConsumed();inbound.compact();status=r.getStatus().toString();if(dst.position()!=0)throw new SSLException("Application data during handshake");if(r.getStatus()==SSLEngineResult.Status.BUFFER_UNDERFLOW)break;if(r.getStatus()==SSLEngineResult.Status.CLOSED)throw new SSLException("Handshake peer close");continue;}
   if(h==SSLEngineResult.HandshakeStatus.NOT_HANDSHAKING&&cryptoComplete){state=State.CRYPTO_COMPLETE_VERIFY_PENDING;break;}throw new SSLException("Unexpected handshake state");
  }
  if(cryptoComplete&&engine.getHandshakeStatus()==SSLEngineResult.HandshakeStatus.NOT_HANDSHAKING)state=State.CRYPTO_COMPLETE_VERIFY_PENDING;
  return new HandshakeResult(offered,used,out.toByteArray(),status,engine.getHandshakeStatus().toString(),state==State.CRYPTO_COMPLETE_VERIFY_PENDING?Action.VERIFY_PEER:action(),cryptoComplete,inbound.position(),0);
  }catch(SSLException e){abort();throw e;}
 }
 /** TrustManager has already checked chain DURING handshake; this is a separate fail-closed identity gate. */
 public void verifyPeer(String dns)throws Exception{
  own();if(state!=State.CRYPTO_COMPLETE_VERIFY_PENDING||inbound.position()!=0)throw new IllegalStateException("Verification boundary");
  try{X509Certificate cert=(X509Certificate)engine.getSession().getPeerCertificates()[0];cert.checkValidity();boolean found=false;Collection<List<?>> sans=cert.getSubjectAlternativeNames();if(sans!=null)for(List<?> san:sans)if(((Integer)san.get(0)).intValue()==2&&dns.equalsIgnoreCase(String.valueOf(san.get(1))))found=true;if(!found)throw new java.security.cert.CertificateException("TEST DNS identity mismatch");state=State.VERIFIED;}catch(Exception e){abort();throw e;}
 }
 public String peerMetadata()throws SSLPeerUnverifiedException{X509Certificate c=(X509Certificate)engine.getSession().getPeerCertificates()[0];return c.getSubjectX500Principal().getName()+" serial="+c.getSerialNumber()+" notBefore="+c.getNotBefore()+" notAfter="+c.getNotAfter();}
 public void enterApplication(){own();if(state!=State.VERIFIED)throw new IllegalStateException("Trust gate");state=State.APPLICATION;}
 // A raw engine step NEVER certifies AA body completion: internal residue is not directly observable.
 private Boundary quiescence(){return Boundary.COMPLETION_UNPROVEN;}
 /** Qualified desktop TLS1.2 profile only: complete authenticated records, all input and empty drain required. */
 public Boundary proveBodyBoundary(byte[] completeCiphertext,boolean emptyOutputDrain){own();TlsRecordLedger.completeApplicationRecords(completeCiphertext);return profile&&emptyOutputDrain&&pending()==0&&state==State.APPLICATION&&engine.getHandshakeStatus()==SSLEngineResult.HandshakeStatus.NOT_HANDSHAKING?Boundary.PROVEN_QUIESCENT:Boundary.COMPLETION_UNPROVEN;}
 public EncryptResult wrap(long context,byte[] plain,int offset,int length,int capacity)throws SSLException{
  own();if(state!=State.APPLICATION||plain==null||offset<0||length<0||length>plain.length-offset||capacity<0||capacity>65535)throw new IllegalStateException("Application wrap bounds/state");
  ByteBuffer src=ByteBuffer.wrap(plain,offset,length),dst=ByteBuffer.allocate(capacity);try{SSLEngineResult r=io(true,src,dst);if(r.getHandshakeStatus()!=SSLEngineResult.HandshakeStatus.NOT_HANDSHAKING){abort();throw new SSLException("RENEGOTIATION_UNSUPPORTED");}return new EncryptResult(context,length,r.bytesConsumed(),Arrays.copyOf(dst.array(),dst.position()),r.getStatus().toString(),r.getHandshakeStatus().toString(),r.getStatus()==SSLEngineResult.Status.BUFFER_OVERFLOW?Action.DRAIN_OUTPUT:Action.CONTINUE,quiescence());}catch(SSLException e){abort();throw e;}
 }
 public DecryptResult unwrap(long context,byte[] bytes,int capacity)throws SSLException{
  own();if(state!=State.APPLICATION||capacity<0||capacity>65535)throw new IllegalStateException("Application unwrap state/bounds");feed(bytes);int offered=pending();inbound.flip();ByteBuffer dst=ByteBuffer.allocate(capacity);
  try{SSLEngineResult r=io(false,inbound,dst);inbound.compact();boolean closed=r.getStatus()==SSLEngineResult.Status.CLOSED;if(closed)state=State.PEER_CLOSED;
   if(!closed&&r.getHandshakeStatus()!=SSLEngineResult.HandshakeStatus.NOT_HANDSHAKING){abort();throw new SSLException("UNROUTABLE_CONTROL_OR_RENEGOTIATION");}
   return new DecryptResult(context,offered,r.bytesConsumed(),Arrays.copyOf(dst.array(),dst.position()),r.getStatus().toString(),r.getHandshakeStatus().toString(),closed?Action.PEER_CLOSED:r.getStatus()==SSLEngineResult.Status.BUFFER_UNDERFLOW?Action.NEED_INPUT:r.getStatus()==SSLEngineResult.Status.BUFFER_OVERFLOW?Action.DRAIN_OUTPUT:Action.CONTINUE,quiescence(),pending(),closed);
  }catch(SSLException e){inbound.clear();abort();throw e;}
 }
 public CloseResult beginClose()throws SSLException{
  own();if(state!=State.APPLICATION&&state!=State.PEER_CLOSED)throw new IllegalStateException("Close state");engine.closeOutbound();state=State.LOCAL_CLOSING;return drainClose();
 }
 public CloseResult drainClose()throws SSLException{
  own();if(state!=State.LOCAL_CLOSING)throw new IllegalStateException("Closing phase");ByteBuffer dst=ByteBuffer.allocate(Math.min(65535,Math.max(18437,packetSize())));SSLEngineResult r=io(true,ByteBuffer.allocate(0),dst);if(engine.isInboundDone()&&engine.isOutboundDone())state=State.CLOSED;return new CloseResult(0,0,Arrays.copyOf(dst.array(),dst.position()),r.getStatus().toString(),r.getHandshakeStatus().toString(),Action.CONTINUE,engine.isInboundDone(),engine.isOutboundDone());
 }
 public CloseResult receiveClose(byte[] bytes)throws SSLException{
  own();if(state!=State.APPLICATION&&state!=State.LOCAL_CLOSING)throw new IllegalStateException("Close receive state");feed(bytes);int n=pending();inbound.flip();ByteBuffer dst=ByteBuffer.allocate(18437);SSLEngineResult r=io(false,inbound,dst);inbound.compact();if(dst.position()!=0)throw new SSLException("Unexpected app data in close");if(engine.isInboundDone()){state=engine.isOutboundDone()?State.CLOSED:State.PEER_CLOSED;inbound.clear();}return new CloseResult(n,r.bytesConsumed(),new byte[0],r.getStatus().toString(),r.getHandshakeStatus().toString(),engine.isInboundDone()?Action.PEER_CLOSED:Action.NEED_INPUT,engine.isInboundDone(),engine.isOutboundDone());
 }
 public void transportEof()throws SSLException{own();try{engine.closeInbound();}finally{abort();}throw new SSLException("TRUNCATED_EOF_WITHOUT_VERIFIED_CLOSE");}
 public void abort(){state=State.FAILED;inbound.clear();log("ABORT; fresh session required");}
}
