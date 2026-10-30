import java.io.*;
import java.util.*;
import com.rdx.fullscreen.clean.*;
/** Extracts bounded opaque data from existing synthetic MP4s; no decoding/regeneration. */
public final class ExportQualifierFixtures {
 public static void main(String[] a)throws Exception{File project=new File(a[0]),clips=new File(a[1]),out=new File(a[2]);out.mkdirs();
  String[][] names={{"discovery","discovery-request"},{"setup","media-setup"},{"start","media-start"}};
  for(String[] n:names){byte[] raw=read(new File(project,"test-fixtures/session/"+n[1]+".bin"));byte[] body=new AaFrameParser(65535,1048576,128).feed(raw).get(0).body();if(n[0].equals("setup")){byte[] extra=new ProtoWire.Writer().bytes(190,new byte[]{9,8,7}).finish();body=join(body,extra);}save(new File(out,n[0]+".bin"),body);}
  for(String[] n:new String[][]{{"config","config-ready-one"},{"ack","ack-one"},{"focus","focus-projected"}}){byte[] raw=read(new File(project,"test-fixtures/honda-media-v1/"+n[1]+".bin"));save(new File(out,n[0]+".bin"),new AaFrameParser(65535,1048576,128).feed(raw).get(0).body());}
  byte[] largest=null;for(String[] pair:new String[][]{{"conservative","grid-1280x688-60.mp4"},{"experimental","grid-1920x720-30.mp4"}}){File path=new File(clips,pair[1]);if(!path.isFile())throw new FileNotFoundException(path.toString());Mp4FixtureReader mp4=new Mp4FixtureReader(path);save(new File(out,pair[0]+"-codec.bin"),typed(1,mp4.configuration()));save(new File(out,pair[0]+"-media.bin"),typed(0,MediaPayload.encodeData(new MediaPayload.Timestamp(mp4.timestampUs(0)),mp4.accessUnit(0))));for(int i=0;i<mp4.count();i++){byte[] sample=mp4.accessUnit(i);if(largest==null||sample.length>largest.length)largest=sample;}}
  save(new File(out,"codec.bin"),read(new File(out,"conservative-codec.bin")));save(new File(out,"media.bin"),read(new File(out,"conservative-media.bin")));if(largest.length<65536)throw new IllegalStateException("Existing large sample required");save(new File(out,"large-media.bin"),typed(0,MediaPayload.encodeData(new MediaPayload.Timestamp(123456),largest)));
 }
 static byte[] typed(int id,byte[] p){byte[] b=new byte[p.length+2];b[0]=(byte)(id>>>8);b[1]=(byte)id;System.arraycopy(p,0,b,2,p.length);return b;}
 static byte[] join(byte[] a,byte[] b){byte[] r=Arrays.copyOf(a,a.length+b.length);System.arraycopy(b,0,r,a.length,b.length);return r;}
 static byte[] read(File f)throws Exception{DataInputStream in=new DataInputStream(new FileInputStream(f));byte[] b=new byte[(int)f.length()];try{in.readFully(b);}finally{in.close();}return b;}
 static void save(File f,byte[] b)throws Exception{OutputStream o=new FileOutputStream(f);try{o.write(b);}finally{o.close();}}
}
