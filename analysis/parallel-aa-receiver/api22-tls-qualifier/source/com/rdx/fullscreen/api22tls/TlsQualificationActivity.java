package com.rdx.fullscreen.api22tls;
import android.app.Activity;
import android.os.Bundle;
import android.os.Build;
import android.widget.TextView;
import android.util.Log;
import java.io.*;

/** No boot/startup receiver/service. Only explicit RUN_API22_TLS action starts a bounded worker. */
public final class TlsQualificationActivity extends Activity {
 public void onCreate(Bundle b){super.onCreate(b);final TextView view=new TextView(this);setContentView(view);
  final String id=getIntent().getStringExtra("run_id");
  boolean emulator=Build.HARDWARE.equals("goldfish")||Build.HARDWARE.equals("ranchu");
  if(!"RUN_API22_TLS".equals(getIntent().getAction())||id==null||!id.matches("[A-Za-z0-9_-]{1,64}")||Build.VERSION.SDK_INT!=22||!emulator){view.setText("REFUSED: explicit action, fresh run id and API22 goldfish/ranchu emulator required");return;}
  final File directory=new File(new File(getFilesDir(),"runs"),id);if(directory.exists()||!directory.mkdirs()){view.setText("REFUSED: fresh private result directory required");return;}
  view.setText("Bounded memory TLS qualification running. No network or device operations.");
  final String hash=getIntent().getStringExtra("apk_sha256");
  new Thread(new Runnable(){public void run(){try{
   QualifierCore.Assets assets=new QualifierCore.Assets(){public byte[] load(String name)throws Exception{InputStream in=getAssets().open(name);try{return QualifierCore.readBounded(in,1048576);}finally{in.close();}}};
   QualifierCore core=new QualifierCore(assets,directory);core.mechanicsLimit=getIntent().getIntExtra("mechanics_cases",500);core.combinedLimit=getIntent().getIntExtra("combined_cases",200);core.metadata.put("androidAPI",Integer.valueOf(Build.VERSION.SDK_INT));core.metadata.put("release",Build.VERSION.RELEASE);core.metadata.put("fingerprint",Build.FINGERPRINT);core.metadata.put("abi",Build.CPU_ABI);core.metadata.put("hardware",Build.HARDWARE);core.metadata.put("runId",id);core.metadata.put("apkSHA256",hash==null?"UNAVAILABLE":hash);Log.i("RDX.Api22TLS","Explicit bounded run="+id);core.run();Log.i("RDX.Api22TLS","Durable completion run="+id);
  }catch(Throwable e){Log.e("RDX.Api22TLS","Bounded qualifier failure run="+id,e);try{QualifierCore.write(new File(directory,"failure-details.txt"),e.getClass().getName()+": "+String.valueOf(e.getMessage()));}catch(Exception ignored){}}
  runOnUiThread(new Runnable(){public void run(){view.setText("Qualification ended. Retrieve app-private results with emulator-only runner.");}});
  }},"ExplicitApi22TlsQualifier").start();
 }
}
