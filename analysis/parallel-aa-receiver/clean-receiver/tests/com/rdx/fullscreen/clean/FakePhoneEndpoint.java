package com.rdx.fullscreen.clean;
import java.util.*;
/** Byte arrays only: no IO, clock, threads, USB, TLS implementation or Android objects. */
public final class FakePhoneEndpoint {
 private final AaFrameWriter writer=new AaFrameWriter();
 public byte[] message(int channel,int type,byte[] payload){return writer.encode(new AaFrame(channel,channel==0?3:7,-1,ControlMessages.typed(type,payload)));}
 public void establishFakeSession(HeadUnitProtocolCore core){
  core.begin();core.acceptPlaintextEnvelope(IndependentFixtures.hex("000300080002000100010000"));
  FakeTlsAdapter fake=new FakeTlsAdapter();fake.startHandshake();core.recordTlsEstablished(fake);
  if(!Arrays.equals(core.authenticationCompleteNotification(),IndependentFixtures.hex("0003000400040800")))throw new AssertionError("HU AuthComplete direction/bytes");fake.close();
 }
 public DiscoveryCodec.Decoded discovery(HeadUnitProtocolCore core,boolean oneByte){
  byte[] request=message(0,5,new ControlMessages.DiscoveryRequest("Synthetic phone","Host fixture").encode());
  List<byte[]> reply=new ArrayList<byte[]>();if(oneByte)for(byte b:request)reply.addAll(core.acceptPlaintextEnvelope(new byte[]{b}));else reply=core.acceptPlaintextEnvelope(request);
  if(reply.size()!=1)throw new AssertionError("Discovery response count");
  AaMessageAssembler.Message m=new AaMessageAssembler(65536,8,524288).accept(new AaFrameParser(16384,65536,256).feed(reply.get(0)).get(0));
  if(m.type!=6)throw new AssertionError("Wrong discovery response type");return DiscoveryCodec.decode(Arrays.copyOfRange(m.bytes(),2,m.bytes().length));
 }
}
