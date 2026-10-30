package com.rdx.fullscreen.clean;
import java.util.*;import java.io.*;
public final class SecureBodyTests {
 private static int checks,properties,cases,transcripts;private static final long SEED=0x534543424f4459L;private static File project,output,clips;
 private static void check(boolean b,String why){checks++;if(!b)throw new AssertionError(why);}private static void prop(boolean b,String why){properties++;if(!b)throw new AssertionError("seed="+SEED+" case="+cases+" "+why);}
 private interface Action {void run();}private static void rejects(Action a,String why){boolean rejected=false;try{a.run();}catch(IllegalArgumentException e){rejected=true;}catch(IllegalStateException e){rejected=true;}check(rejected,why);}
 private static byte[] typed(int type,byte[] body){if(body.length>1048574)throw new IllegalArgumentException("Synthetic media bound");byte[] out=new byte[body.length+2];out[0]=(byte)(type>>>8);out[1]=(byte)type;System.arraycopy(body,0,out,2,body.length);return out;}
 private static byte[] hex(String h){return IndependentFixtures.hex(h);}private static byte[] logical(int n){byte[] b=new byte[n];for(int i=0;i<n;i++)b[i]=(byte)(i*37+11);if(n>0)b[0]=(byte)0x80;if(n>1)b[1]=0;return b;}
 private static SyntheticTlsState established(){SyntheticTlsState s=new SyntheticTlsState();s.begin();s.handshakeSucceeded();s.verify(true);return s;}
 private static SecureBodyPipeline pipeline(FakeSecureBodyAdapter f){return new SecureBodyPipeline(f,established());}
 private static byte[] join(List<byte[]> frames){ByteArrayOutputStream b=new ByteArrayOutputStream();for(byte[] f:frames)b.write(f,0,f.length);return b.toByteArray();}
 private static List<AaMessageAssembler.Message> deliver(SecureBodyPipeline p,byte[] wire,int chunk,Random random){List<AaMessageAssembler.Message> result=new ArrayList<AaMessageAssembler.Message>();for(int off=0;off<wire.length;){int n=Math.min(wire.length-off,chunk==0?wire.length:chunk<0?1+random.nextInt(137):chunk);result.addAll(p.receive(Arrays.copyOfRange(wire,off,off+n)));off+=n;}return result;}
 private static void same(List<byte[]> a,List<byte[]> b){check(a.size()==b.size(),"oracle frame count");for(int i=0;i<a.size();i++)check(Arrays.equals(a.get(i),b.get(i)),"oracle exact frame"+i);}
 private static void basics(){
  FakeSecureBodyAdapter f=new FakeSecureBodyAdapter();SyntheticTlsState tls=new SyntheticTlsState();SecureBodyPipeline p=new SecureBodyPipeline(f,tls);check(tls.state()==SyntheticTlsState.State.NOT_STARTED&&f.encryptCalls+f.decryptCalls+f.handshakeCalls==0,"constructors inert");
  byte[] b=hex("80000803");OuterFrameContext c=new OuterFrameContext(1,5,11,4,-1);RawAaFrame raw=new RawAaFrame(c,b);b[0]=0;check(raw.body()[0]==(byte)128,"raw immutable");byte[] got=raw.body();got[0]=0;check(raw.body()[0]==(byte)128,"raw accessor copy");
  rejects(new Action(){public void run(){new RawAaFrame(new OuterFrameContext(1,1,11,5,-1),new byte[4]);}},"declared cipher mismatch");
  rejects(new Action(){public void run(){new RawAaFrame(new OuterFrameContext(1,1,11,-1,-1),new byte[0]);}},"outbound unknown ciphertext size cannot form raw frame");
  rejects(new Action(){public void run(){new OuterFrameContext(-1,1,3,0,-1);}},"negative identity");
  rejects(new Action(){public void run(){new OuterFrameContext(0,256,3,0,-1);}},"channel bound");
  rejects(new Action(){public void run(){new OuterFrameContext(0,1,16,0,-1);}},"reserved flag");
  rejects(new Action(){public void run(){new OuterFrameContext(0,1,1,0,1048577);}},"logical max+1");
  final SyntheticTlsState badState=tls;rejects(new Action(){public void run(){badState.verify(true);}},"no verify before handshake");
  tls.begin();check(tls.state()==SyntheticTlsState.State.HANDSHAKING,"explicit begin");tls.handshakeSucceeded();check(!tls.established(),"handshake alone insufficient");tls.verify(false);check(tls.state()==SyntheticTlsState.State.FAILED,"verify fail");rejects(new Action(){public void run(){badState.begin();}},"no terminal revival");
  SyntheticTlsState good=established();good.beginShutdown();good.cleanClose();check(good.state()==SyntheticTlsState.State.CLOSED,"orderly synthetic shutdown");
  check(!SecureStartupPolicy.outgoingEncrypted(0,4,SyntheticTlsState.State.ESTABLISHED_SYNTHETIC,false),"AUTH EXPLICIT PLAINTEXT");
  check(SecureStartupPolicy.outgoingEncrypted(0,6,SyntheticTlsState.State.ESTABLISHED_SYNTHETIC,true),"discovery encrypted");
  rejects(new Action(){public void run(){SecureStartupPolicy.incoming(0,5,false,SyntheticTlsState.State.ESTABLISHED_SYNTHETIC,true);}},"plaintext discovery prohibited");
  rejects(new Action(){public void run(){SecureStartupPolicy.incoming(0,4,true,SyntheticTlsState.State.ESTABLISHED_SYNTHETIC,true);}},"encrypted/wrong-direction auth prohibited");
  for(int flags=0;flags<16;flags++){
   FakeSecureBodyAdapter ff=new FakeSecureBodyAdapter();SecureBodyPipeline pp=pipeline(ff);final int mask=flags;final SecureBodyPipeline path=pp;
   boolean ctrl=(flags&4)!=0,complete=(flags&3)==3;
   if(ctrl&&!complete){rejects(new Action(){public void run(){path.decrypt(new RawAaFrame(new OuterFrameContext(1,9,mask,2,(mask&3)==1?4:-1),hex("8000")));}},"CONTROL requires FIRST LAST");continue;}
   DecryptedAaFragment d=pp.decrypt(new RawAaFrame(new OuterFrameContext(1,9,flags,2,(flags&3)==1?4:-1),hex("8000")));
   check(d.context.channel==9&&d.context.flags==flags&&d.context.control()==ctrl&&d.context.encrypted()==((flags&8)!=0),"all flag combinations independently retained");check(ff.decryptCalls==((flags&8)!=0?1:0),"plaintext bypasses adapter");
  }
  // A low-level empty fragment is representable, but an empty logical message has no BE16 type.
  p=pipeline(new FakeSecureBodyAdapter());check(p.decrypt(new RawAaFrame(new OuterFrameContext(0,1,3,0,-1),new byte[0])).plaintextLength()==0,"zero raw plaintext where legal");
  final SecureBodyPipeline zero=pipeline(new FakeSecureBodyAdapter());rejects(new Action(){public void run(){zero.encode(1,0,new byte[0],true);}},"zero logical rejected");
  for(int n:new int[]{2,16127,16128,16129,32256,32257,1048576}){
   FakeSecureBodyAdapter ff=new FakeSecureBodyAdapter();ff.padding=19;byte[] data=logical(n);SecureBodyPipeline send=pipeline(ff);List<byte[]> frames=send.encode(237,0,data,true);same(frames,SecureBodyOracle.frames(237,0,data,19,true));check(frames.size()==(n+16127)/16128,"0x3F00 threshold "+n);
   FakeSecureBodyAdapter recv=new FakeSecureBodyAdapter();recv.padding=19;List<AaMessageAssembler.Message> m=deliver(pipeline(recv),join(frames),7,new Random(1));check(m.size()==1&&m.get(0).channel==237&&Arrays.equals(m.get(0).bytes(),data),"threshold full roundtrip "+n);
  }
  final SecureBodyPipeline one=pipeline(new FakeSecureBodyAdapter());check(one.decrypt(new RawAaFrame(new OuterFrameContext(0,1,11,1,-1),new byte[]{1})).plaintextLength()==1,"one-byte fragment valid below logical layer");
 }
 private static void expansionAndDrain(){
  for(int padding:new int[]{0,1,32,49000})for(int chunks:new int[]{1,2,5,100}){
   byte[] data=logical(chunks==100?100:1000);FakeSecureBodyAdapter send=new FakeSecureBodyAdapter();send.padding=padding;List<byte[]> frames=pipeline(send).encode(12,0,data,true);int body=(frames.get(0)[2]&255)*256+(frames.get(0)[3]&255);check(body==data.length+padding,"actual cipher body length");
   FakeSecureBodyAdapter receive=new FakeSecureBodyAdapter();receive.padding=padding;receive.chunkSize=(data.length+chunks-1)/chunks;receive.zeroDrains=3;
   List<AaMessageAssembler.Message> messages=pipeline(receive).receive(join(frames));check(messages.size()==1&&Arrays.equals(messages.get(0).bytes(),data),"multidrain exact "+chunks);check(receive.drainCalls>=3,"zero intermediate output explicitly drained");
  }
  FakeSecureBodyAdapter f=new FakeSecureBodyAdapter();f.batchChunks=5;f.chunkSize=2;check(pipeline(f).receive(hex("010b000a80000803010203040506")).size()==1,"many chunks in ONE result");
  final FakeSecureBodyAdapter huge=new FakeSecureBodyAdapter();huge.padding=65535;final SecureBodyPipeline p=pipeline(huge);rejects(new Action(){public void run(){p.encode(1,0,logical(2),true);}},"cipher expansion max+1");
  FakeSecureBodyAdapter max=new FakeSecureBodyAdapter();max.padding=49407;List<byte[]> frames=pipeline(max).encode(1,0,logical(16128),true);check(frames.get(0).length==65539,"cipher bound65535 accepted");
  FakeSecureBodyAdapter limit=new FakeSecureBodyAdapter();limit.zeroDrains=256;SecureBodyPipeline limited=pipeline(limit);check(limited.receive(hex("010b00028000")).size()==1&&limited.maxDrainCalls()==256,"max drain256 accepted");
  final FakeSecureBodyAdapter over=new FakeSecureBodyAdapter();over.zeroDrains=257;final SecureBodyPipeline tooMany=pipeline(over);rejects(new Action(){public void run(){tooMany.receive(hex("010b00028000"));}},"drain257 rejected");check(tooMany.reason().equals("DECRYPT_DRAIN_LIMIT"),"exact drain disposition");
 }
 private static void attributionAndFailures(){
  for(int mode=0;mode<9;mode++){
   FakeSecureBodyAdapter f=new FakeSecureBodyAdapter();if(mode==0)f.needMore=true;if(mode==1)f.failAt=1;if(mode==2)f.closeAt=1;if(mode==3)f.residual=true;if(mode==4)f.wrongContext=1;if(mode==5)f.endless=true;if(mode==6)f.throwOnBegin=true;if(mode==7)f.renegotiate=true;if(mode==8)f.chunkSize=1;
   if(mode==1||mode==2)f.chunkSize=1;
   final SecureBodyPipeline p=pipeline(f);final int kind=mode;
   if(mode==8){rejects(new Action(){public void run(){p.receive(join(SecureBodyOracle.frames(1,0,logical(16129),0,true)));}},"too many tiny drains");}
   else rejects(new Action(){public void run(){p.receive(hex("010b000480000803"));}},"injected outcome "+kind);
   int before=f.decryptCalls;for(final byte[] later:new byte[][]{hex("020b000480010800"),hex("010b000480010800"),hex("020f000400080800"),hex("010a00028001")})rejects(new Action(){public void run(){p.receive(later);}},"no cross-frame attribution "+kind);
   check(f.decryptCalls==before&&p.reservedBytes()==0&&p.partialBytes()==0,"no late plaintext migration; buffers clear "+kind);
  }
  final SecureBodyPipeline missing=new SecureBodyPipeline(null,established());rejects(new Action(){public void run(){missing.receive(hex("010b00028000"));}},"missing adapter");
  final SecureBodyPipeline tooLong=pipeline(new FakeSecureBodyAdapter());rejects(new Action(){public void run(){tooLong.decrypt(new RawAaFrame(new OuterFrameContext(0,1,11,16129,-1),logical(16129)));}},"decrypted max+1");
  final SecureBodyPipeline wrongTotal=pipeline(new FakeSecureBodyAdapter());rejects(new Action(){public void run(){wrongTotal.receive(hex("01090002000000038000010a00020803"));}},"aggregate overflow");
  final SecureBodyPipeline shortTotal=pipeline(new FakeSecureBodyAdapter());rejects(new Action(){public void run(){shortTotal.receive(hex("01090002000000058000010a000108"));}},"aggregate underflow");
  final SecureBodyPipeline reserved=pipeline(new FakeSecureBodyAdapter());reserved.receive(hex("01090002001000008000"));reserved.receive(hex("02090002001000008000"));check(reserved.reservedBytes()==2097152,"session reservation max2MiB");rejects(new Action(){public void run(){reserved.receive(hex("03090002000000048000"));}},"third fragmented channel rejected/cleared");check(reserved.reservedBytes()==0,"reservation reset on fail");
  SecureBodyPipeline inter=pipeline(new FakeSecureBodyAdapter());List<AaMessageAssembler.Message> m=inter.receive(hex("01090002000000048000020b00028003010a00020803"));check(m.size()==2&&m.get(0).channel==2&&m.get(1).channel==1&&Arrays.equals(m.get(1).bytes(),hex("80000803")),"Honda per-channel interleaving retained");
  SecureBodyPipeline plain=new SecureBodyPipeline(null,new SyntheticTlsState());check(plain.receive(hex("00030006000100010001")).size()==1,"plaintext without TLS adapter");plain.endOfInput();check(plain.state()==SecureBodyPipeline.State.CLOSED,"clean EOF");
  final SecureBodyPipeline partial=pipeline(new FakeSecureBodyAdapter());partial.receive(new byte[]{1,11,0});rejects(new Action(){public void run(){partial.endOfInput();}},"partial frame EOF");
  SecureBodyPipeline reset=pipeline(new FakeSecureBodyAdapter());reset.receive(hex("01090002000000048000"));reset.reset();check(reset.reservedBytes()==0&&reset.state()==SecureBodyPipeline.State.CLOSED,"pending reset terminal");
  final SecureBodyPipeline empty=pipeline(new FakeSecureBodyAdapter());rejects(new Action(){public void run(){empty.receive(hex("010b0000"));}},"empty message lacks type");
 }
 private static void roundTrips()throws Exception{
  for(String h:new String[]{"80000803","8003080210101800","800108011000","800408011001","800808011001","00010000000167420020","00000000000000000001418884"}){
   byte[] b=hex(h);FakeSecureBodyAdapter f=new FakeSecureBodyAdapter();f.padding=32;List<byte[]> frames=pipeline(f).encode(19,0,b,true);FakeSecureBodyAdapter receive=new FakeSecureBodyAdapter();receive.padding=32;receive.chunkSize=1;List<AaMessageAssembler.Message> m=pipeline(receive).receive(join(frames));check(m.size()==1&&m.get(0).channel==19&&Arrays.equals(b,m.get(0).bytes()),"media/control exact encrypted roundtrip "+h.substring(0,4));
  }
  // Known protobuf discovery bytes plus independently appended unknown field survives many fragments.
  byte[] discovery=SessionCatalog.conservative().bytes();byte[] logical=typed(6,discovery);
  FakeSecureBodyAdapter f=new FakeSecureBodyAdapter();f.padding=47;List<byte[]> frames=pipeline(f).encode(0,0,logical,true);FakeSecureBodyAdapter receive=new FakeSecureBodyAdapter();receive.padding=47;receive.zeroDrains=5;receive.chunkSize=37;byte[] result=pipeline(receive).receive(join(frames)).get(0).bytes();check(Arrays.equals(logical,result),"known discovery exact");DiscoveryCodec.decode(Arrays.copyOfRange(result,2,result.length));
  
  // One bounded unknown length-delimited field, not trailing invalid zero tags.
  ProtoWire.Writer unknown=new ProtoWire.Writer();byte[] extras=unknown.bytes(190,new byte[20000]).finish();byte[] payload=new byte[discovery.length+extras.length];System.arraycopy(discovery,0,payload,0,discovery.length);System.arraycopy(extras,0,payload,discovery.length,extras.length);
  byte[] big=typed(6,payload);FakeSecureBodyAdapter g=new FakeSecureBodyAdapter();List<byte[]> wire=pipeline(g).encode(0,0,big,true);byte[] decoded=pipeline(new FakeSecureBodyAdapter()).receive(join(wire)).get(0).bytes();check(Arrays.equals(big,decoded),"multi-fragment discovery unknown-field bytes preserved");DiscoveryCodec.decode(Arrays.copyOfRange(decoded,2,decoded.length));
 }
 private static void randomized(){
  Random random=new Random(SEED);
  for(int i=0;i<25000;i++){
   cases++;int n=i%1000==0?16127+random.nextInt(60000):2+random.nextInt(1200),channel=random.nextInt(256),semantic=random.nextBoolean()&&n<=16128?4:0,padding=random.nextInt(129);byte[] data=new byte[n];random.nextBytes(data);data[0]=(byte)128;
   FakeSecureBodyAdapter send=new FakeSecureBodyAdapter();send.padding=padding;List<byte[]> actual=pipeline(send).encode(channel,semantic,data,true),expected=SecureBodyOracle.frames(channel,semantic,data,padding,true);prop(actual.size()==expected.size(),"oracle frame count");
   for(int j=0;j<actual.size();j++){prop(Arrays.equals(actual.get(j),expected.get(j)),"oracle encoded bytes");byte[] f=actual.get(j);prop((f[0]&255)==channel,"channel");prop((f[1]&8)!=0,"encrypted independent");prop(((f[1]&4)!=0)==(semantic==4),"control independent");}
   prop(Arrays.equals(SecureBodyOracle.decode(actual,padding),data),"independent decoder exact");
   FakeSecureBodyAdapter receive=new FakeSecureBodyAdapter();receive.padding=padding;receive.zeroDrains=random.nextInt(4);receive.batchChunks=1+random.nextInt(5);receive.chunkSize=Math.max(1,(Math.min(16128,n)+99)/100);
   SecureBodyPipeline path=pipeline(receive);List<AaMessageAssembler.Message> m=deliver(path,join(actual),i%4==0?-1:0,random);prop(m.size()==1&&Arrays.equals(m.get(0).bytes(),data),"random transport/drain orthogonality");prop(m.get(0).channel==channel,"reassembled retained channel");prop(path.reservedBytes()==0&&path.partialBytes()==0,"zero final buffered state");prop(path.maxPlaintext()<=16128&&path.maxCiphertext()<=65535&&path.maxDrainCalls()<=256,"bounds");
   prop(!SessionCatalog.conservative().experimentalOptIn,"experiment never default");
  }
  for(int i=0;i<5000;i++){
   cases++;FakeSecureBodyAdapter f=new FakeSecureBodyAdapter();int mode=i%5;if(mode==0)f.needMore=true;if(mode==1)f.wrongContext=1;if(mode==2)f.failAt=0;if(mode==3)f.residual=true;if(mode==4)f.endless=true;SecureBodyPipeline path=pipeline(f);boolean rejected=false;try{path.receive(hex("010b00028000"));}catch(RuntimeException expected){rejected=true;}prop(rejected&&path.state()==SecureBodyPipeline.State.ERROR,"malformed/attribution deterministic failure");int calls=f.decryptCalls;try{path.receive(hex("020b00028001"));}catch(RuntimeException expected){}prop(f.decryptCalls==calls&&path.reservedBytes()==0,"terminal cannot acquire next context");
  }
 }

 private static byte[] read(File file)throws Exception{byte[] b=new byte[(int)file.length()];DataInputStream in=new DataInputStream(new FileInputStream(file));try{in.readFully(b);}finally{in.close();}return b;}
 private static byte[] oldLogical(String name)throws Exception{byte[] raw=read(new File(project,"test-fixtures/session/"+name+".bin"));return new AaFrameParser(65535,1048576,128).feed(raw).get(0).body();}
 private static final class Rig {
  final InMemorySessionTransport.Clock clock=new InMemorySessionTransport.Clock();final SimulatedSessionEngine core;final FakeVideoDecoder decoder=new FakeVideoDecoder();final VideoDataPlane video;final FakeSecureBodyAdapter fake=new FakeSecureBodyAdapter(),peerFake=new FakeSecureBodyAdapter();final SecureSessionSimulation session;final SecureBodyPipeline peer;
  Rig(boolean experiment){core=new SimulatedSessionEngine(clock,new SessionPolicy(10,20,100,1000),experiment?SessionCatalog.experimental():SessionCatalog.conservative(),true);fake.padding=37;fake.zeroDrains=2;fake.chunkSize=257;fake.batchChunks=3;peerFake.padding=37;peer=pipeline(peerFake);session=new SecureSessionSimulation(core,fake);video=new VideoDataPlane(core,decoder,16,VideoDataPlane.BoundaryPolicy.HOST_ONE_MESSAGE_PER_MP4_ACCESS_UNIT);session.attachVideo(video);}
  List<byte[]> incoming(int channel,int semantic,byte[] logical,boolean encrypted){return peer.encode(channel,semantic,logical,encrypted);}
  void send(int channel,int semantic,byte[] logical,boolean encrypted){session.receive(join(incoming(channel,semantic,logical,encrypted)));}
  void startup()throws Exception{
   List<byte[]> version=session.beginVersion();check((version.get(0)[1]&8)==0,"version plaintext");send(0,0,oldLogical("version-response"),false);
   fake.nextHandshakeOutput=hex("112233");List<byte[]> handshake=session.beginHandshake(new byte[0]);check(handshake.size()==1&&(handshake.get(0)[1]&8)==0&&handshake.get(0)[4]==0&&handshake.get(0)[5]==3,"handshake carrier plaintext0003");send(0,0,hex("00034455"),false);
   session.handshakeSucceeded();check(session.tlsState()==SyntheticTlsState.State.VERIFYING_PEER,"verify gate");List<byte[]> auth=session.verifyPeer(true);check(auth.size()==1&&(auth.get(0)[1]&8)==0&&auth.get(0)[5]==4,"post TLS AuthResponse explicitly plaintext");
   send(0,0,oldLogical("discovery-request"),true);List<byte[]> advert=session.drainControl();check(!advert.isEmpty()&&(advert.get(0)[1]&8)!=0,"discovery encrypted");byte[] ad=peer.receive(join(advert)).get(0).bytes();DiscoveryCodec.decode(Arrays.copyOfRange(ad,2,ad.length));
   send(1,4,oldLogical("open-video"),true);List<byte[]> open=session.drainControl();check((open.get(0)[1]&12)==12,"CONTROL on service channel encrypted, not channel0");
   send(1,0,oldLogical("media-setup"),true);core.advertiseMediaConfig(HondaMediaMessages.MediaConfig.create(MediaConfigStatus.STATUS_READY,Long.valueOf(16),Collections.singletonList(new HondaMediaMessages.VideoConfigurationIndex(0))));List<byte[]> config=session.drainControl();check(peer.receive(join(config)).get(0).type==0x8003,"encrypted READY2 config");
   core.optionalProjectedFocus(true);List<byte[]> focus=session.drainControl();check(peer.receive(join(focus)).get(0).type==0x8008,"optional focus roundtrip");send(1,0,oldLogical("media-start"),true);check(core.mediaState()==HondaMediaFlow.State.MEDIA_CONFIGURATION_SELECTED,"selected configuration after encryptedStart");
  }
 }
 private static void fullClip(String name,boolean experiment)throws Exception{
  Mp4FixtureReader mp4=new Mp4FixtureReader(new File(clips,name));Rig r=new Rig(experiment);r.startup();StringBuilder ledger=new StringBuilder();for(String line:r.core.transcript())ledger.append(line).append('\n');for(String line:r.session.events())ledger.append(line).append('\n');
  byte[] config=typed(1,mp4.configuration());r.send(1,0,config,true);check(r.video.hasConfiguration(),"encrypted config CSD accepted by explicit fake boundary");long digestExpected=1469598103934665603L;
  for(int i=0;i<mp4.count();i++){
   byte[] au=mp4.accessUnit(i);long pts=mp4.timestampUs(i);byte[] logical=typed(0,MediaPayload.encodeData(new MediaPayload.Timestamp(pts),au));List<byte[]> frames=r.incoming(1,0,logical,true);
   check(Arrays.equals(SecureBodyOracle.decode(frames,37),logical),"all clip bytes independent oracle "+name+"/"+i);
   // Transport segmentation is independent of fake plaintext chunking. Selected prefix torture; whole bodies thereafter.
   byte[] wire=join(frames);int step=i==0?7:wire.length;for(int off=0;off<wire.length;off+=step)r.session.receive(Arrays.copyOfRange(wire,off,Math.min(wire.length,off+step)));
   for(byte b:au)digestExpected=(digestExpected^(b&255))*1099511628211L;digestExpected^=pts;
   List<byte[]> ack=r.session.accountingAck();check(!ack.isEmpty()&&r.peer.receive(join(ack)).get(0).type==0x8004,"encrypted accounting ACK only "+i);
   ledger.append("AU ").append(i).append(" fixturePtsUs=").append(pts).append(" bytes=").append(au.length).append(" rawWireUnit=UNKNOWN state=").append(r.video.state()).append('\n');
  }
  check(r.decoder.digest==digestExpected&&r.video.accepted()==mp4.count()&&r.video.accounted()==mp4.count(),"full exact AU order/bytes/timestamps fake sink "+name);
  check(r.core.experimentalOptIn()==experiment,"profile opt-in stable");
  ledger.append("FURTHEST=ABSTRACT_INPUT_ACCEPTED; no decode/display; crop placement UNSPECIFIED; advertised nominal/margins separate from SPS\n");
  r.send(1,0,hex("8002"),true);r.session.shutdown();check(r.video.bufferedBytes()==0&&r.video.outstanding()==0&&r.session.tlsState()==SyntheticTlsState.State.CLOSED,"orderly synthetic cleanup");
  ledger.append("END CLOSED; digest=").append(r.decoder.digest).append(" maxDrains=").append(r.session.bodies().maxDrainCalls()).append(" maxPlain=").append(r.session.bodies().maxPlaintext()).append(" maxCipher=").append(r.session.bodies().maxCiphertext()).append(" maxReserved=").append(r.session.bodies().maxReserved()).append('\n');
  PrintWriter out=new PrintWriter(new OutputStreamWriter(new FileOutputStream(new File(output,name+".txt")),"UTF-8"));try{out.println("FULL OFFLINE ENCRYPTION-BOUNDARY SESSION SIMULATION; prefix/identity fake; NO CRYPTO; no phone or decoder pass");out.print(ledger);}finally{out.close();}transcripts++;
 }
 private static void torture()throws Exception{
  Mp4FixtureReader reader=new Mp4FixtureReader(new File(clips,"grid-1920x720-30.mp4"));int largest=0;for(int i=1;i<reader.count();i++)if(reader.sampleBytes(i)>reader.sampleBytes(largest))largest=i;byte[] large=typed(0,MediaPayload.encodeData(new MediaPayload.Timestamp(123),reader.accessUnit(largest)));check(large.length>65535,"real large IDR fixture >64KiB");
  for(int transport:new int[]{0,1,2,3,7,-1})for(int drain:new int[]{1,2,3}){
   FakeSecureBodyAdapter send=new FakeSecureBodyAdapter();send.padding=61;byte[] raw=join(pipeline(send).encode(1,0,large,true));FakeSecureBodyAdapter recv=new FakeSecureBodyAdapter();recv.padding=61;recv.chunkSize=drain==1?257:drain==2?173:100;recv.batchChunks=drain;recv.zeroDrains=drain*3;
   SecureBodyPipeline path=pipeline(recv);List<AaMessageAssembler.Message> messages=deliver(path,raw,transport,new Random(777));check(messages.size()==1&&Arrays.equals(messages.get(0).bytes(),large),"large media transport/drain orthogonal "+transport+"/"+drain);
  }
  byte[] small=typed(1,reader.configuration());byte[] raw=join(SecureBodyOracle.frames(1,0,small,5,true));for(int cut=0;cut<=raw.length;cut++){
   FakeSecureBodyAdapter recv=new FakeSecureBodyAdapter();recv.padding=5;recv.chunkSize=1;SecureBodyPipeline path=pipeline(recv);List<AaMessageAssembler.Message> messages=new ArrayList<AaMessageAssembler.Message>();messages.addAll(path.receive(Arrays.copyOfRange(raw,0,cut)));messages.addAll(path.receive(Arrays.copyOfRange(raw,cut,raw.length)));check(messages.size()==1&&Arrays.equals(messages.get(0).bytes(),small),"every header/config split"+cut);
  }
  List<byte[]> many=SecureBodyOracle.frames(1,0,large,5,true);byte[] wire=join(many);int offset=0;for(byte[] f:many){for(int h=1;h<=((f[1]&3)==1?8:4);h++){FakeSecureBodyAdapter recv=new FakeSecureBodyAdapter();recv.padding=5;SecureBodyPipeline path=pipeline(recv);List<AaMessageAssembler.Message> m=new ArrayList<AaMessageAssembler.Message>();int cut=offset+h;m.addAll(path.receive(Arrays.copyOfRange(wire,0,cut)));m.addAll(path.receive(Arrays.copyOfRange(wire,cut,wire.length)));check(m.size()==1&&Arrays.equals(m.get(0).bytes(),large),"each FIRST total/header split");}offset+=f.length;}
  // One-byte TLS drain with <=100byte plaintext is separately tested; large one-byte drains must hit the bounded policy.
 }
 private static void corpus()throws Exception{
  String[] ids={"missing-adapter","truncated-ciphertext","first-total-underflow","first-total-excess","last-total-mismatch","wrong-continuation","control-fragment","reserved-flags","empty-logical","encrypted-before-established"};
  for(final String name:ids){final byte[] wire=read(new File(project,"test-fixtures/secure-body-v1/"+name+".bin"));final SecureBodyPipeline path=name.equals("missing-adapter")?new SecureBodyPipeline(null,established()):name.equals("encrypted-before-established")?new SecureBodyPipeline(new FakeSecureBodyAdapter(),new SyntheticTlsState()):pipeline(new FakeSecureBodyAdapter());rejects(new Action(){public void run(){path.receive(wire);path.endOfInput();}},"independent malformed corpus "+name);check(path.state()==SecureBodyPipeline.State.ERROR,"corpus terminal "+name);}
  for(String name:new String[]{"version-request","version-response","handshake-carrier","auth-plaintext"}){FakeSecureBodyAdapter f=new FakeSecureBodyAdapter();SecureBodyPipeline path=new SecureBodyPipeline(f,new SyntheticTlsState());check(path.receive(read(new File(project,"test-fixtures/secure-body-v1/"+name+".bin"))).size()==1&&f.decryptCalls==0,"plaintext independent fixture bypass "+name);}
  check(pipeline(new FakeSecureBodyAdapter()).receive(read(new File(project,"test-fixtures/secure-body-v1/control-service-channel.bin"))).get(0).channel==2,"CONTROL fixture on service channel");
  Rig failed=new Rig(false);failed.session.beginVersion();failed.send(0,0,oldLogical("version-response"),false);failed.session.beginHandshake(new byte[0]);failed.session.handshakeSucceeded();check(failed.session.verifyPeer(false).isEmpty()&&failed.session.tlsState()==SyntheticTlsState.State.FAILED&&failed.fake.encryptCalls==0,"verification failure no adapter application install");
  final Rig bad=new Rig(false);bad.startup();rejects(new Action(){public void run(){bad.send(0,0,hex("0005"),false);}},"plaintext discovery after secure state fails session");check(bad.session.tlsState()==SyntheticTlsState.State.FAILED,"policy fail containment");
 }
 private static void extraBounds()throws Exception{
  FakeSecureBodyAdapter f=new FakeSecureBodyAdapter();f.padding=4;check(pipeline(f).receive(read(new File(project,"test-fixtures/secure-body-v1/discovery-encrypted.bin"))).get(0).type==5,"independent expanded discovery fixture");
  for(final String id:new String[]{"drain-bound","delayed-context"}){FakeSecureBodyAdapter a=new FakeSecureBodyAdapter();if(id.equals("drain-bound"))a.endless=true;else a.needMore=true;final SecureBodyPipeline path=pipeline(a);final byte[] raw=read(new File(project,"test-fixtures/secure-body-v1/"+id+".bin"));rejects(new Action(){public void run(){path.receive(raw);}},"scripted independent adapter corpus "+id);check(path.reason().equals(id.equals("drain-bound")?"DECRYPT_DRAIN_LIMIT":"BODY_DECRYPT_INCOMPLETE"),"exact exceptional disposition");}
  final SecureBodyPipeline input=pipeline(new FakeSecureBodyAdapter());rejects(new Action(){public void run(){input.receive(new byte[2097153]);}},"batch max+1 before parsing");
  SecureBodyPipeline pending=pipeline(new FakeSecureBodyAdapter());pending.receive(hex("01090002000000048000"));pending.cleanClose();check(pending.state()==SecureBodyPipeline.State.ERROR&&pending.reservedBytes()==0,"close with incomplete logical message distinct from clean EOF");
  byte[] prefix=hex("010900010000012c80"),middle=hex("0108000100");final SecureBodyPipeline fragments=pipeline(new FakeSecureBodyAdapter());fragments.receive(prefix);boolean failed=false;for(int i=0;i<256;i++)try{fragments.receive(middle);}catch(RuntimeException e){failed=true;break;}check(failed&&fragments.reservedBytes()==0,"fragment-count policy bound preserved through decrypt");
  final Rig malformed=new Rig(false);malformed.startup();rejects(new Action(){public void run(){malformed.send(1,0,hex("80000880"),true);}},"malformed encrypted protobuf reaches core validation");check(malformed.session.tlsState()==SyntheticTlsState.State.FAILED,"malformed decrypted control containment");
  Rig rejected=new Rig(false);rejected.startup();Mp4FixtureReader clip=new Mp4FixtureReader(new File(clips,"grid-1280x688-60.mp4"));rejected.send(1,0,typed(1,clip.configuration()),true);rejected.decoder.next=VideoDecoderContract.Outcome.INPUT_REJECTED;rejected.send(1,0,typed(0,MediaPayload.encodeData(new MediaPayload.Timestamp(1),clip.accessUnit(0))),true);List<byte[]> accounting=rejected.session.accountingAck();check(rejected.video.accepted()==0&&rejected.video.rejected()==1&&!accounting.isEmpty()&&rejected.peer.receive(join(accounting)).get(0).type==0x8004,"encrypted ACK after fake input rejection; no display metric or running transition");
  byte[] expansion=read(new File(project,"test-fixtures/secure-body-v1/expansion-bound.bin"));final byte[] expansionLogical=new AaFrameParser(65535,1048576,128).feed(expansion).get(0).body();FakeSecureBodyAdapter oversized=new FakeSecureBodyAdapter();oversized.padding=65535;final SecureBodyPipeline expansionPath=pipeline(oversized);rejects(new Action(){public void run(){expansionPath.encode(1,0,expansionLogical,true);}},"independent output-expansion corpus");check(expansionPath.reason().equals("CIPHERTEXT_BODY_BOUND"),"expansion corpus disposition");
  SecureBodyAdapter decompressor=new SecureBodyAdapter(){int left;public Result pumpHandshake(byte[] b){return Result.empty(0,Outcome.NO_OUTPUT_YET);}public Result encryptBody(OuterFrameContext c,byte[] b){throw new IllegalStateException();}public Result beginDecrypt(OuterFrameContext c,byte[] b){if(c.first())left=c.logicalTotal;int n=Math.min(16128,left);left-=n;byte[] plain=new byte[n];if(c.first())plain[0]=(byte)128;return new Result(c.sequence,Outcome.BODY_COMPLETE,Collections.singletonList(plain),0);}public Result drainDecrypt(OuterFrameContext c){throw new IllegalStateException();}public void reset(){left=0;}public void close(){}};
  ByteArrayOutputStream bomb=new ByteArrayOutputStream();for(int i=0;i<33;i++){bomb.write(hex("010900010001000000"));for(int k=0;k<3;k++)bomb.write(hex("0108000100"));bomb.write(hex("010a000100"));}final byte[] bombWire=bomb.toByteArray();final SecureBodyPipeline bytesBound=pipelineFor(decompressor);rejects(new Action(){public void run(){bytesBound.receive(bombWire);}},"aggregate result bytes bounded under hostile output expansion");check(bytesBound.reason().equals("MESSAGE_BATCH_BYTES_BOUND")&&bytesBound.reservedBytes()==0,"aggregate result byte cap2MiB");
  // Outbound fake-output context errors are rejected before an outer header can be emitted.
  SecureBodyAdapter evil=new SecureBodyAdapter(){public Result pumpHandshake(byte[] b){return Result.empty(0,Outcome.NO_OUTPUT_YET);}public Result beginDecrypt(OuterFrameContext c,byte[] b){return Result.empty(c.sequence,Outcome.BODY_COMPLETE);}public Result drainDecrypt(OuterFrameContext c){return Result.empty(c.sequence,Outcome.BODY_COMPLETE);}public Result encryptBody(OuterFrameContext c,byte[] b){return new Result(c.sequence+1,Outcome.BODY_COMPLETE,Collections.singletonList(b),0);}public void reset(){}public void close(){}};
  final SecureBodyPipeline wrong=pipelineFor(evil);rejects(new Action(){public void run(){wrong.encode(1,0,hex("8000"),true);}},"outbound context mismatch");
  SecureBodyAdapter.CredentialInputs slots=new SecureBodyAdapter.CredentialInputs("root-slot","client-slot","private-key-slot");check(slots.rootCertificateSlot.equals("root-slot"),"credential metadata only, no bytes loaded");
 }
 private static SecureBodyPipeline pipelineFor(SecureBodyAdapter a){return new SecureBodyPipeline(a,established());}
 public static void main(String[] args)throws Exception{
  project=new File(args[0]);clips=new File(args[1]);output=new File(args[2]);if(!output.isDirectory()&&!output.mkdirs())throw new IOException("output");
  basics();expansionAndDrain();attributionAndFailures();roundTrips();corpus();extraBounds();torture();randomized();
  for(String name:new String[]{"grid-1280x720-30.mp4","grid-1280x688-60.mp4","grid-1920x720-30.mp4","grid-1920x720-60.mp4","grid-1920x1080-30.mp4","grid-1920x1080-60.mp4"})fullClip(name,name.contains("1920"));
  System.out.println("RESULT PASS deterministic="+checks+" propertyChecks="+properties+" validCases=25000 malformedCases=5000 seed="+SEED+" transcripts="+transcripts+" clips=6 samples=2700; FAKE BODY TRANSFORM ONLY; NO CRYPTO/HARDWARE");
 }
}






