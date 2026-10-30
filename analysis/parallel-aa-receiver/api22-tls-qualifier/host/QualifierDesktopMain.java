import java.io.*;
import com.rdx.fullscreen.api22tls.QualifierCore;
/** Functional test of the SAME qualifier core; never labelled Android provider evidence. */
public final class QualifierDesktopMain {
 public static void main(String[] a)throws Exception{final File assets=new File(a[0]);QualifierCore q=new QualifierCore(new QualifierCore.Assets(){public byte[] load(String name)throws Exception{InputStream in=new FileInputStream(new File(assets,name));try{return QualifierCore.readBounded(in,1048576);}finally{in.close();}}},new File(a[1]));q.metadata.put("hostJava",System.getProperty("java.version"));q.run();}
}
