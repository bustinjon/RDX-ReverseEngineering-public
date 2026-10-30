package com.rdx.fullscreen.clean;
import java.util.*;
public final class FoundationTests {
 private static int passed;private static final AaFrameWriter WRITER=new AaFrameWriter();
 private static void check(String name,boolean yes){if(!yes)throw new AssertionError(name);passed++;System.out.println("PASS "+name);}
 private static void rejects(String name,Runnable action){boolean bad=false;try{action.run();}catch(RuntimeException expected){bad=true;}check(name,bad);}
 private static AaFrameParser parser(){return new AaFrameParser(16384,65536,256);}
 private static AaMessageAssembler assembler(){return new AaMessageAssembler(65536,8,524288);}
 private static AaFrame frame(int channel,int flags,int total,int... values){byte[] b=new byte[values.length];for(int i=0;i<b.length;i++)b[i]=(byte)values[i];return new AaFrame(channel,flags,total,b);}
 private static byte[] join(byte[]... arrays){int n=0;for(byte[] a:arrays)n+=a.length;byte[] b=new byte[n];int p=0;for(byte[] a:arrays){System.arraycopy(a,0,b,p,a.length);p+=a.length;}return b;}
 public static void main(String[] args){
  AaFrame complete=frame(2,3,-1,0x12,0x34,5,6);byte[] wire=WRITER.encode(complete);
  List<AaFrame> one=parser().feed(wire);check("single-frame envelope",one.size()==1&&one.get(0).channel==2&&Arrays.equals(one.get(0).body(),complete.body()));
  check("message type big-endian",assembler().accept(one.get(0)).type==0x1234);
  AaFrameParser bytes=parser();List<AaFrame> got=new ArrayList<AaFrame>();for(byte b:wire)got.addAll(bytes.feed(new byte[]{b}));bytes.endOfInput();check("one-byte USB chunks",got.size()==1);
  AaFrameParser partial=parser();check("partial header buffered",partial.feed(Arrays.copyOfRange(wire,0,2)).isEmpty()&&partial.hasPartialFrame());check("partial payload buffered",partial.feed(Arrays.copyOfRange(wire,2,5)).isEmpty());check("remaining payload completes",partial.feed(Arrays.copyOfRange(wire,5,wire.length)).size()==1);
  check("multiple envelopes one buffer",parser().feed(join(wire,wire,wire)).size()==3);
  AaFrame first=frame(2,1,6,0x12),middle=frame(2,0,-1,0x34,5),last=frame(2,2,-1,6,7,8);
  AaMessageAssembler a=assembler();check("first fragment no delivery",a.accept(first)==null);check("middle no repeated type",a.accept(middle)==null);check("last reassembles split type",Arrays.equals(a.accept(last).bytes(),new byte[]{0x12,0x34,5,6,7,8})&&a.activeChannels()==0);
  List<AaFrame> fragmentedWire=parser().feed(join(WRITER.encode(first),WRITER.encode(middle),WRITER.encode(last)));AaMessageAssembler fullWire=assembler();AaMessageAssembler.Message assembled=null;for(AaFrame f:fragmentedWire)assembled=fullWire.accept(f);check("fragmented wire writer/parser/reassembly",fragmentedWire.size()==3&&assembled!=null&&assembled.bytes().length==6);
  check("first total BE32 serialized",WRITER.encode(first)[7]==6&&fragmentedWire.get(0).totalPlaintextLength==6);
  AaMessageAssembler interleave=assembler();interleave.accept(frame(1,1,3,0));interleave.accept(frame(2,1,3,0));check("channel separation A",interleave.accept(frame(1,2,-1,1,9)).channel==1);check("channel separation B",interleave.accept(frame(2,2,-1,2,8)).type==2);
  check("control flag preserved",assembler().accept(frame(0,7,-1,0,1)).flags==7);
  AaMessageAssembler encrypted=assembler();AaFrame cipher=frame(2,11,-1,99,98,97);final AaFrame encryptedFrame=cipher;
  rejects("encrypted body cannot bypass TLS",new Runnable(){public void run(){assembler().accept(encryptedFrame);}});
  check("explicit post-TLS plaintext seam",encrypted.acceptDecoded(cipher,new byte[]{0,7}).type==7);
  AaMessageAssembler shortTail=assembler();shortTail.accept(frame(2,1,3,0,1));check("legal one-byte continuation",shortTail.accept(frame(2,2,-1,2)).bytes().length==3);
  AaMessageAssembler emptyTail=assembler();emptyTail.accept(frame(2,1,2,0,1));check("legal empty final continuation",emptyTail.accept(frame(2,2,-1)).type==1);
  AaMessageAssembler emptyFirst=assembler();emptyFirst.accept(frame(2,1,2));check("empty first fragment",emptyFirst.accept(frame(2,2,-1,0,1)).type==1);
  final byte[] oversize=WRITER.encode(frame(2,3,-1,0,1,2,3,4));rejects("oversized frame body",new Runnable(){public void run(){new AaFrameParser(4,32,8).feed(oversize);}});
  final byte[] huge={2,1,0,0,(byte)255,(byte)255,(byte)255,(byte)255};rejects("unsigned total overflow rejected",new Runnable(){public void run(){parser().feed(huge);}});
  rejects("reserved flag rejected",new Runnable(){public void run(){parser().feed(new byte[]{2,16,0,0});}});
  rejects("invalid writer flags",new Runnable(){public void run(){frame(2,16,-1,0,1);}});
  rejects("continuation without first",new Runnable(){public void run(){assembler().accept(frame(2,2,-1,0,1));}});
  rejects("overlapping fragments",new Runnable(){public void run(){AaMessageAssembler x=assembler();x.accept(frame(2,1,4,0));x.accept(frame(2,3,-1,0,1));}});
  rejects("fragment flag mismatch",new Runnable(){public void run(){AaMessageAssembler x=assembler();x.accept(frame(2,5,4,0));x.accept(frame(2,2,-1,1,2,3));}});
  rejects("message overflow",new Runnable(){public void run(){AaMessageAssembler x=assembler();x.accept(frame(2,1,2,0));x.accept(frame(2,2,-1,1,2));}});
  rejects("message underflow",new Runnable(){public void run(){AaMessageAssembler x=assembler();x.accept(frame(2,1,4,0));x.accept(frame(2,2,-1,1));}});
  rejects("message type missing",new Runnable(){public void run(){assembler().accept(frame(2,3,-1,1));}});
  rejects("active channel bound",new Runnable(){public void run(){AaMessageAssembler x=new AaMessageAssembler(8,1,8);x.accept(frame(1,1,4,0));x.accept(frame(2,1,4,0));}});
  rejects("aggregate reservation bound",new Runnable(){public void run(){AaMessageAssembler x=new AaMessageAssembler(8,8,8);x.accept(frame(1,1,6,0));x.accept(frame(2,1,6,0));}});
  rejects("frames-per-feed bound",new Runnable(){public void run(){byte[] b=WRITER.encode(frame(1,3,-1,0,1));new AaFrameParser(16,32,1).feed(join(b,b));}});
  rejects("truncated input EOF",new Runnable(){public void run(){AaFrameParser p=parser();p.feed(new byte[]{1,3,0});p.endOfInput();}});
  AaFrameParser reset=parser();reset.feed(new byte[]{1});reset.reset();check("explicit local reset",reset.feed(wire).size()==1);
  byte[] source={0,1};AaFrame immutable=new AaFrame(1,3,-1,source);source[0]=9;byte[] copy=immutable.body();copy[0]=8;check("immutable frame body",immutable.body()[0]==0);
  VideoConfig stock=VideoConfig.conservative(),full=VideoConfig.fullscreenExperiment();check("conservative capability",stock.activeWidth()==1280&&stock.activeHeight()==688&&stock.dpi==229&&stock.fps==60);
  check("fullscreen active arithmetic",full.nominalWidth==1920&&full.nominalHeight==1080&&full.marginHeight==360&&full.activeWidth()==1920&&full.activeHeight()==720&&full.dpi==229&&full.fps==30);
  check("crop placement unspecified",full.placement==VideoConfig.Placement.UNSPECIFIED);check("fullscreen not default",AaServiceDiscovery.conservativeOnly().video.get(0).nominalWidth==1280);
  check("both modes expressible",new AaServiceDiscovery(Arrays.asList(stock,full),InputConfig.hondaReference()).video.size()==2);
  rejects("invalid margins",new Runnable(){public void run(){new VideoConfig(1920,1080,0,1080,229,30);}});
  final AaServiceRegistry registry=new AaServiceRegistry();registry.register(2,AaServiceRegistry.Kind.VIDEO);registry.register(7,AaServiceRegistry.Kind.INPUT);
  check("explicit channel registry",registry.snapshot().get(7)==AaServiceRegistry.Kind.INPUT);rejects("channel zero reserved",new Runnable(){public void run(){registry.register(0,AaServiceRegistry.Kind.AUDIO);}});rejects("duplicate channel",new Runnable(){public void run(){registry.register(2,AaServiceRegistry.Kind.INPUT);}});
  final AndroidUsbTransport transport=new AndroidUsbTransport();final AoaNegotiator aoa=new AoaNegotiator();final AaTlsSession tls=new AaTlsSession();final AaControlChannel control=new AaControlChannel();
  check("AOA compile-time disabled",!AoaNegotiator.EXECUTION_ENABLED);check("AOA UTF8 NUL encoding",Arrays.equals(aoa.identificationBytes("A"),new byte[]{65,0}));check("AOA multibyte length",aoa.identificationBytes("\u00e9").length==3);
  AoaRequestPlan query=aoa.planQuery(),start=aoa.planStart();check("AOA query metadata only",query.requestType==0xC0&&query.request==51&&query.value==0&&query.index==0&&query.expectedResponseBytes==2);check("AOA start metadata only",start.requestType==0x40&&start.request==53&&start.value==0&&start.index==0&&start.payload().length==0);
  for(int i=0;i<6;i++){AoaRequestPlan p=aoa.planIdentity(i,"Android");check("AOA identity index "+i,p.request==52&&p.requestType==0x40&&p.value==0&&p.index==i&&p.payload()[p.payload().length-1]==0);}
  rejects("AOA identity index bound",new Runnable(){public void run(){aoa.planIdentity(6,"A");}});
  rejects("AOA embedded NUL",new Runnable(){public void run(){aoa.identificationBytes("a\u0000b");}});
  rejects("AOA query disabled",new Runnable(){public void run(){aoa.queryVersion(transport);}});rejects("AOA identity disabled",new Runnable(){public void run(){aoa.sendIdentity(transport,new String[6]);}});rejects("AOA start disabled",new Runnable(){public void run(){aoa.start(transport);}});
  rejects("transport open disabled",new Runnable(){public void run(){transport.open(new DeviceIdentity("synthetic",1,2,false));}});rejects("TLS disabled",new Runnable(){public void run(){tls.start(transport);}});rejects("control startup disabled",new Runnable(){public void run(){control.performVersionExchange();}});
  final int[] calls={0};AaVideoDecoder fake=new AaVideoDecoder(){public void configure(VideoConfig c){calls[0]++;}public void submit(byte[] b,long pts){calls[0]++;}public void stop(){calls[0]++;}};
  final AaVideoChannel video=new AaVideoChannel(stock,fake);check("video constructor does not allocate",calls[0]==0);rejects("video startup disabled",new Runnable(){public void run(){video.open();}});check("video gate made no calls",calls[0]==0);
  System.out.println("RESULT PASS tests="+passed+"; SYNTHETIC HOST DATA ONLY; no USB, ADB, TLS, decoder or vehicle used");
 }
}
