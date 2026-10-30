package com.rdx.fullscreen.m5permission;
import android.app.*;
import android.content.*;
import android.hardware.usb.*;
import android.os.*;
import android.util.Log;
import java.io.*;
import java.util.*;

/** One permission request only. No device handle or transport exists in this application. */
public final class PermissionService extends Service {
 private UsbManager manager; private UsbDevice selected;
 private boolean active,registered,attempted; private PendingIntent pending;
 private String nonce,expectedName; private int vid,pid,samples; private FileWriter output;
 private final Handler handler=new Handler();
 private final String action="com.rdx.fullscreen.m5permission.RESULT";
 private void record(String text){
  String line="wall="+System.currentTimeMillis()+" elapsed="+SystemClock.elapsedRealtime()+" "+text;
  Log.i("RDX.M5",line);
  if(output!=null)try{output.write(line+"\n");output.flush();}catch(IOException e){Log.e("RDX.M5","Result write failed",e);}
 }
 private void finish(String reason){record(reason);active=false;stopSelf();}
 private final Runnable timeout=new Runnable(){public void run(){finish("TIMEOUT; no retry");}};
 private final Runnable poll=new Runnable(){public void run(){
  if(!active||attempted)return;
  try{
   HashMap<String,UsbDevice> devices=manager.getDeviceList(); UsbDevice match=null;int count=0;
   if(devices!=null)for(UsbDevice d:devices.values()){
    record("OBSERVE sample="+samples+" path="+d.getDeviceName()+" vid="+d.getVendorId()+" pid="+d.getProductId()+" hasPermission="+manager.hasPermission(d));
    if(d.getVendorId()==vid&&d.getProductId()==pid&&(expectedName==null||expectedName.equals(d.getDeviceName()))){match=d;count++;}
   }
   samples++;
   if(count>1){finish("REFUSED: ambiguous target; no request");return;}
   if(match==null){record("WAITING sample="+samples+" exactVIDPID="+vid+":"+pid);handler.postDelayed(this,1000);return;}
   selected=match;
   record("PINNED path="+selected.getDeviceName()+" vid="+vid+" pid="+pid+" beforePermission="+manager.hasPermission(selected));
   if(manager.hasPermission(selected)){finish("ALREADY_AUTHORIZED; no request issued");return;}
   attempted=true;
   registerReceiver(result,new IntentFilter(action));registered=true;
   nonce=UUID.randomUUID().toString();
   Intent callback=new Intent(action).setPackage(getPackageName()).putExtra("request_nonce",nonce);
   pending=PendingIntent.getBroadcast(PermissionService.this,1,callback,PendingIntent.FLAG_ONE_SHOT|PendingIntent.FLAG_CANCEL_CURRENT);
   record("REQUEST_ONCE path="+selected.getDeviceName()+"; SystemUI may resume; no open or transfer follows");
   manager.requestPermission(selected,pending);
  }catch(RuntimeException e){record("ERROR "+e.toString());finish("STOP; no retry");}
 }};
 private final BroadcastReceiver result=new BroadcastReceiver(){public void onReceive(Context c,Intent i){
  if(!action.equals(i.getAction())||!active||nonce==null||!nonce.equals(i.getStringExtra("request_nonce")))return;
  try{
   UsbDevice returned=(UsbDevice)i.getParcelableExtra(UsbManager.EXTRA_DEVICE);
   boolean same=returned!=null&&selected!=null&&selected.getDeviceName().equals(returned.getDeviceName())&&selected.getVendorId()==returned.getVendorId()&&selected.getProductId()==returned.getProductId();
   boolean grant=same&&manager.hasPermission(selected);
   record("RESULT sameDevice="+same+" callbackGranted="+i.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED,false)+" verifiedPermission="+grant+" path="+(returned==null?"null":returned.getDeviceName()));
   finish("COMPLETE; no open/claim/transfer performed");
  }catch(RuntimeException e){record("ERROR callback "+e.toString());finish("STOP; no retry");}
 }};
 @Override public IBinder onBind(Intent i){return null;}
 @Override public int onStartCommand(Intent i,int flags,int id){
  if(active){record("Duplicate invocation ignored");return START_NOT_STICKY;}
  if(attempted){stopSelf();return START_NOT_STICKY;}
  if(i==null||!"REQUEST_ONCE_AFTER_M4_PASS".equals(i.getAction())||!i.getBooleanExtra("m4_pass_confirmed",false)){Log.w("RDX.M5","REFUSED: M4 PASS gate missing");stopSelf();return START_NOT_STICKY;}
  vid=i.getIntExtra("vendor_id",-1);pid=i.getIntExtra("product_id",-1);expectedName=i.getStringExtra("device_name");
  // Deferred matching requires an additional explicit gate and the one M4-observed identity.
  if(vid<0||vid>65535||pid<0||pid>65535||(expectedName==null&&(!i.getBooleanExtra("wait_for_target",false)||vid!=0x18d1||pid!=0x2d01))){Log.w("RDX.M5","REFUSED: target identity gate missing");stopSelf();return START_NOT_STICKY;}
  try{
   File dir=getExternalFilesDir(null);
   if(dir==null)throw new IOException("Own external files unavailable");
   output=new FileWriter(new File(dir,"m5-last-run.txt"),false);
  }catch(IOException e){Log.e("RDX.M5","REFUSED: durable results unavailable",e);stopSelf();return START_NOT_STICKY;}
  record("START uid="+android.os.Process.myUid()+" pid="+android.os.Process.myPid()+" nativeLibraryDir="+getApplicationInfo().nativeLibraryDir+" target="+vid+":"+pid+" totalTimeoutMs=180000");
  manager=(UsbManager)getSystemService(USB_SERVICE);
  if(manager==null){finish("STOP: USB service unavailable");return START_NOT_STICKY;}
  active=true;handler.postDelayed(timeout,180000);handler.post(poll);
  return START_NOT_STICKY;
 }
 @Override public void onDestroy(){active=false;handler.removeCallbacksAndMessages(null);if(pending!=null)pending.cancel();if(registered)unregisterReceiver(result);record("END; permission-only; no open/claim/transfer performed");if(output!=null)try{output.close();}catch(IOException e){Log.e("RDX.M5","Close result failed",e);}output=null;super.onDestroy();}
}
