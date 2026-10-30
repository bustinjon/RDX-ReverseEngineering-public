import java.io.*;
import java.security.*;
import java.security.cert.*;
import java.util.*;
/** Explicit export of newly generated PUBLIC TEST MATERIAL only, never vehicle credentials. */
public final class ExportTestCredentials {
 public static void main(String[] args)throws Exception{
  File input=new File(args[0]),output=new File(args[1]);if(!new File(input,"TEST-ONLY.txt").isFile())throw new SecurityException("TEST marker required");output.mkdirs();
  PrintWriter metadata=new PrintWriter(new File(output,"PUBLIC-TEST-MATERIAL.txt"),"UTF-8");metadata.println("PUBLIC DISPOSABLE TEST KEYS. NO SECURITY VALUE. NO HONDA IDENTITIES. PKCS8 DER + X509 DER; never use outside isolated test harness.");
  for(String name:new String[]{"root","other-root","server","client","expired","future","other-client"}){
   KeyStore ks=KeyStore.getInstance("PKCS12");InputStream in=new FileInputStream(new File(input,name+".p12"));try{ks.load(in,"disposable-test-only".toCharArray());}finally{in.close();}
   String alias=name.equals("root")||name.equals("other-root")?name:"leaf";X509Certificate cert=(X509Certificate)ks.getCertificate(alias);
   save(new File(output,name+".cer"),cert.getEncoded());if(!name.equals("root")&&!name.equals("other-root"))save(new File(output,name+".pk8"),ks.getKey(alias,"disposable-test-only".toCharArray()).getEncoded());
   metadata.println(name+" subject="+cert.getSubjectX500Principal()+" issuer="+cert.getIssuerX500Principal()+" notBefore="+cert.getNotBefore()+" notAfter="+cert.getNotAfter()+" key="+cert.getPublicKey().getAlgorithm()+" SAN="+cert.getSubjectAlternativeNames()+" certificateSHA256="+hex(MessageDigest.getInstance("SHA-256").digest(cert.getEncoded())));
  }metadata.close();
 }
 static void save(File file,byte[] data)throws Exception{OutputStream out=new FileOutputStream(file);try{out.write(data);}finally{out.close();}}
 static String hex(byte[] b){StringBuilder out=new StringBuilder();for(byte x:b){out.append("0123456789abcdef".charAt((x&255)>>>4));out.append("0123456789abcdef".charAt(x&15));}return out.toString();}
}
