import com.rdx.fullscreen.m6aoa.*;import java.io.*;import java.util.*;
/** Independent evidence accounting; host only, not a second USB implementation. */
public final class M6EvidenceTool {
 static String value(String details,String key){for(String p:details.split(","))if(p.startsWith(key+"="))return p.substring(key.length()+1);throw new IllegalArgumentException("Missing "+key);}
 public static void main(String[] a)throws Exception{
  Properties summary=new Properties();FileInputStream in=new FileInputStream(a[1]);try{summary.load(in);}finally{in.close();}String run=summary.getProperty("run");M6Journal journal=new M6Journal(run,new M6Journal.Disk(new File(a[0])));journal.load();
  int intents=0,returns=0,startIntents=0,startReturns=0,stringIndex=0;boolean protocol=false,permission=false,accessory=false,detached=false,gate=false,synthetic=false;String last=null;int expectedLength=0;
  for(String line:journal.entries()){String[] p=line.split("\\|",-1);String event=p[6],d=p[7];if(event.equals("M5_GATE")){synthetic=d.equals("SYNTHETIC_HOST_TEST");gate=synthetic||d.matches("LIVE_REVIEWED_HASH_[0-9a-f]{64}");}if(event.equals("PERMISSION_VERIFIED"))permission=true;
   if(event.equals("PROTOCOL"))protocol=d.equals("version=1")||d.equals("version=2");
   if(event.equals("START_INTENT")){if(!permission||!protocol||stringIndex!=6||returns!=7)throw new IllegalArgumentException("Premature START intent");startIntents++;}
   if(event.equals("TRANSFER_INTENT")){if(last!=null||!gate||!permission)throw new IllegalArgumentException("Transfer ordering/gate");int code=Integer.parseInt(value(d,"code")),index=Integer.parseInt(value(d,"index"));if(intents==0){if(code!=51||index!=0)throw new IllegalArgumentException("Query first");}else if(intents<=6){if(code!=52||index!=stringIndex||!protocol)throw new IllegalArgumentException("Indexed string order");stringIndex++;}else if(intents==7){if(code!=53||startIntents!=1)throw new IllegalArgumentException("START once last");}else throw new IllegalArgumentException("Transfer count");expectedLength=Integer.parseInt(value(d,"length"));last=Integer.toString(code);intents++;}
   if(event.equals("TRANSFER_RETURN")){if(last==null||!value(d,"code").equals(last))throw new IllegalArgumentException("Unmatched return");if(!value(d,"status").equals("ACCEPTED")||Integer.parseInt(value(d,"returned"))!=expectedLength){last=null;continue;}last=null;returns++;}
   if(event.equals("START_RETURN"))startReturns++;if(event.equals("DETACH"))detached=true;if(event.equals("ACCESSORY_REENUM")){String[] identity=d.split(":",5);int pid=Integer.parseInt(identity[1]);accessory=detached&&Integer.parseInt(identity[0])==6353&&UsbIdentity.accessoryPid(pid);}
  }
  if(startIntents>1||startReturns>1||intents>8)throw new IllegalArgumentException("Exactly-once invariant");boolean pass=summary.getProperty("verdict","").equals("PASS")&&gate&&permission&&protocol&&intents==8&&returns==8&&startIntents==1&&startReturns==1&&accessory&&last==null;
  String verdict=pass?(synthetic?"SYNTHETIC_PASS_NOT_LIVE_M6":"PASS_CANDIDATE_REQUIRES_REVIEW"):"INCONCLUSIVE_OR_RECORDED_REJECTION_REVIEW";
  PrintWriter output=new PrintWriter(new File(a[2]),"UTF-8");try{output.println("{\"schema\":1,\"verdict\":\""+verdict+"\",\"gate\":"+gate+",\"synthetic\":"+synthetic+",\"controlIntents\":"+intents+",\"acceptedReturns\":"+returns+",\"startIntents\":"+startIntents+",\"startReturns\":"+startReturns+",\"accessoryObserved\":"+accessory+",\"causation\":\"ASSOCIATION_ONLY_NOT_EXCLUSIVE\",\"automaticM7\":false}");}finally{output.close();}
  System.out.println(verdict);
 }
}
