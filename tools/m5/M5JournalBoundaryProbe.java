import java.io.*;
import com.rdx.fullscreen.m5permission.PrivateJournal;
/** Host-only probe of unchanged frozen-source storage, not USB/permission execution. */
public final class M5JournalBoundaryProbe {
 public static void main(String[] args)throws Exception{File directory=new File(args[0]);if(!directory.mkdirs())throw new IOException("Fresh host directory required");PrivateJournal j=new PrivateJournal(directory);for(int i=0;i<8;i++)j.create("run"+i).close();int count=j.list().length;boolean ninth=false,replay=false;try{j.create("run8").close();ninth=true;}catch(IOException e){}try{j.create("run0").close();}catch(IOException e){replay=true;}System.out.println("HOST SOURCE PROBE ONLY actualFiles="+directory.list().length+" journalListCountAfterEight="+count+" ninthRunAllowed="+ninth+" sameRunReplayRefused="+replay);if(!replay)throw new AssertionError("One-shot file replay protection changed");}
}
