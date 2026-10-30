import com.rdx.fullscreen.m6aoa.M5PassProof;
import java.io.*;import java.security.*;import java.security.cert.Certificate;
/** Host-only project review signing. Never packaged. Cannot sign an invalid PASS schema. */
public final class M5ReviewProofTool {
 static byte[] read(File f,int limit)throws IOException{FileInputStream in=new FileInputStream(f);try{ByteArrayOutputStream b=new ByteArrayOutputStream();byte[] c=new byte[4096];int n;while((n=in.read(c))!=-1){b.write(c,0,n);if(b.size()>limit)throw new IOException("Input bound");}return b.toByteArray();}finally{in.close();}}
 public static void main(String[] args)throws Exception{
  if(args.length<4)throw new IllegalArgumentException("verify proof signature bundle certificate OR sign proof signature bundle keystore");
  String mode=args[0];File proof=new File(args[1]),signature=new File(args[2]),bundle=new File(args[3]);byte[] canonical=read(proof,4096);byte[] cert,sig;
  if(mode.equals("verify")){if(args.length!=5)throw new IllegalArgumentException("certificate");cert=read(new File(args[4]),8192);sig=read(signature,512);}
  else if(mode.equals("sign")){if(args.length!=5||signature.exists())throw new IllegalArgumentException("Fresh signature path and project keystore required");KeyStore ks=KeyStore.getInstance("PKCS12");FileInputStream input=new FileInputStream(args[4]);char[] password=System.getenv("RDX_SIGNING_PASSWORD").toCharArray();try{ks.load(input,password);}finally{input.close();}String alias="rdx-parallel-development";Certificate certificate=ks.getCertificate(alias);cert=certificate.getEncoded();Signature s=Signature.getInstance("SHA256withRSA");s.initSign((PrivateKey)ks.getKey(alias,password));s.update(canonical);sig=s.sign();java.util.Arrays.fill(password,'\0');}
  else throw new IllegalArgumentException("Unknown operation");
  FileInputStream evidence=new FileInputStream(bundle);try{M5PassProof.verify(canonical,sig,evidence,cert);}finally{evidence.close();}
  if(mode.equals("sign")){FileOutputStream o=new FileOutputStream(signature);try{o.write(sig);o.flush();o.getFD().sync();}finally{o.close();}}
  System.out.println("PASS: project review signature, frozen M5 identity and evidence hash; no USB or live authorization");
 }
}
