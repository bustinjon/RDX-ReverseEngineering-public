import java.nio.file.*;
import java.security.*;
import java.security.cert.*;
public class InspectUpdateRoot {
 public static void main(String[] args) throws Exception {
  try (var input=Files.newInputStream(Path.of(args[0]))) {
   var cert=(X509Certificate)CertificateFactory.getInstance("X.509").generateCertificate(input);
   cert.verify(cert.getPublicKey());
   System.out.println("Root certificate self-signature verifies locally: true");
   System.out.println("Subject: "+cert.getSubjectX500Principal());
   System.out.println("Issuer: "+cert.getIssuerX500Principal());
   System.out.println("Signature: "+cert.getSigAlgName()+" / "+cert.getSigAlgOID());
   System.out.println("Certificate SHA256: "+java.util.HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(cert.getEncoded())));
   System.out.println("SPKI SHA256: "+java.util.HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(cert.getPublicKey().getEncoded())));
   System.out.println("No network chain/revocation lookup performed; no payload signature tested.");
  }
 }
}
