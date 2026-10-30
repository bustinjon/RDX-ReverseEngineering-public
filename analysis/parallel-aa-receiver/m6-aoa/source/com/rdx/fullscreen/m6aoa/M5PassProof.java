package com.rdx.fullscreen.m6aoa;
import java.io.*;import java.security.*;import java.security.cert.CertificateFactory;
/** Reviewed M5 evidence, authenticated by the independently pinned project review key. */
public final class M5PassProof {
 public static final String APK="A22E96490B9557AFF022893A8B8B7A08BB13CEC236E52704CDDAFA90A8EE8F40";
 private static final String[] NAMES={"schema_version","m5_apk_sha256","package","version","verdict","permission_request_count","callback_count","callback_validated","has_permission_verified","evidence_bundle_sha256","review_timestamp","reviewed_by_user","provenance"};
 public final String bundleHash,proofHash;public final boolean synthetic;
 private M5PassProof(String b,String p,boolean s){bundleHash=b;proofHash=p;synthetic=s;}
 static M5PassProof synthetic(){return new M5PassProof("synthetic","synthetic",true);}
 public static M5PassProof verify(byte[] canonical,byte[] signature,InputStream bundle,byte[] reviewerCertificate)throws Exception{
  PublicKey key=CertificateFactory.getInstance("X.509").generateCertificate(new ByteArrayInputStream(reviewerCertificate)).getPublicKey();return verifyKey(canonical,signature,bundle,key);
 }
 static M5PassProof verifyKey(byte[] canonical,byte[] signature,InputStream bundle,PublicKey key)throws Exception{
  if(canonical==null||canonical.length>4096||signature==null||signature.length>512||bundle==null)throw new GeneralSecurityException("Proof bound");
  Signature check=Signature.getInstance("SHA256withRSA");check.initVerify(key);check.update(canonical);if(!check.verify(signature))throw new GeneralSecurityException("Review signature");
  String s=new String(canonical,"UTF-8");if(!s.endsWith("\n")||s.indexOf('\r')>=0)throw new GeneralSecurityException("Canonical proof");String[] lines=s.split("\n");if(lines.length!=NAMES.length)throw new GeneralSecurityException("Proof count");String[] v=new String[NAMES.length];for(int i=0;i<lines.length;i++){String prefix=NAMES[i]+"=";if(!lines[i].startsWith(prefix))throw new GeneralSecurityException("Proof order/duplicate");v[i]=lines[i].substring(prefix.length());}
  if(!v[0].equals("1")||!v[1].equals(APK)||!v[2].equals("com.rdx.fullscreen.m5permission")||!v[3].equals("0.2.0-m5-single-port-300s")||!v[4].equals("PASS")||!v[5].equals("1")||!v[6].equals("1")||!v[7].equals("true")||!v[8].equals("true")||!v[9].matches("[0-9a-f]{64}")||!v[10].matches("[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z")||!v[11].equals("true")||!v[12].equals("LIVE_REVIEWED"))throw new GeneralSecurityException("M5 PASS gate");
  MessageDigest md=MessageDigest.getInstance("SHA-256");byte[] b=new byte[8192];int n;long count=0;while((n=bundle.read(b))!=-1){count+=n;if(count>67108864)throw new GeneralSecurityException("Evidence bundle bound64MiB");md.update(b,0,n);}if(!M6Journal.hex(md.digest()).equals(v[9]))throw new GeneralSecurityException("Evidence hash");return new M5PassProof(v[9],M6Journal.hash(canonical),false);
 }
}
