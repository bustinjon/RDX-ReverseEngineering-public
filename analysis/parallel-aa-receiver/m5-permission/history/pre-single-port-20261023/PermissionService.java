package com.rdx.fullscreen.m5permission;
import android.app.*;
import android.content.*;
import android.hardware.usb.*;
import android.os.*;
import android.util.Log;

/** SOURCE ONLY: gate acknowledgment is not evidence of M4 PASS; operator must verify it. */
public final class PermissionService extends Service {
 private UsbManager manager;private UsbDevice selected;private boolean active,registered,attempted;private PendingIntent pending;private String nonce;
 private final Handler handler=new Handler();
 private final String action="com.rdx.fullscreen.m5permission.RESULT";
 private final Runnable timeout=new Runnable(){public void run(){active=false;Log.w("RDX.M5","TIMEOUT; no retry");stopSelf();}};
 private final BroadcastReceiver result=new BroadcastReceiver(){public void onReceive(Context c,Intent i){
  if(!action.equals(i.getAction())||!active||!nonce.equals(i.getStringExtra("request_nonce")))return;
  UsbDevice returned=(UsbDevice)i.getParcelableExtra(UsbManager.EXTRA_DEVICE);
  boolean same=returned!=null&&selected!=null&&selected.getDeviceName().equals(returned.getDeviceName())&&selected.getVendorId()==returned.getVendorId()&&selected.getProductId()==returned.getProductId();
  boolean grant=same&&manager.hasPermission(selected);
  Log.i("RDX.M5","RESULT sameDevice="+same+" callbackGranted="+i.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED,false)+" verifiedPermission="+grant);
  active=false;stopSelf();
 }};
 @Override public IBinder onBind(Intent i){return null;}
 @Override public int onStartCommand(Intent i,int flags,int id){
  if(active){Log.w("RDX.M5","Duplicate invocation ignored");return START_NOT_STICKY;}
  if(attempted){Log.w("RDX.M5","One-shot request already used; no retry");stopSelf();return START_NOT_STICKY;}
  if(i==null||!"REQUEST_ONCE_AFTER_M4_PASS".equals(i.getAction())||!i.getBooleanExtra("m4_pass_confirmed",false)){Log.w("RDX.M5","REFUSED: M4 PASS gate missing");stopSelf();return START_NOT_STICKY;}
  manager=(UsbManager)getSystemService(USB_SERVICE);
  if(manager==null){Log.w("RDX.M5","STOP: USB service unavailable");stopSelf();return START_NOT_STICKY;}
  String name=i.getStringExtra("device_name");java.util.HashMap<String,UsbDevice> devices=manager.getDeviceList();selected=devices==null?null:devices.get(name);
  if(selected==null||selected.getVendorId()!=i.getIntExtra("vendor_id",-1)||selected.getProductId()!=i.getIntExtra("product_id",-1)){Log.w("RDX.M5","REFUSED: exact device identity mismatch");stopSelf();return START_NOT_STICKY;}
  if(manager.hasPermission(selected)){Log.i("RDX.M5","Already authorized; no request issued");stopSelf();return START_NOT_STICKY;}
  active=true;attempted=true;registerReceiver(result,new IntentFilter(action));registered=true;nonce=java.util.UUID.randomUUID().toString();
  Intent callback=new Intent(action).setPackage(getPackageName()).putExtra("request_nonce",nonce);
  pending=PendingIntent.getBroadcast(this,1,callback,PendingIntent.FLAG_ONE_SHOT|PendingIntent.FLAG_CANCEL_CURRENT);
  handler.postDelayed(timeout,45000);
  Log.i("RDX.M5","REQUEST_ONCE; SystemUI may resume; no open or transfer follows");
  try{manager.requestPermission(selected,pending);}catch(RuntimeException e){active=false;Log.e("RDX.M5","STOP: permission request failed; no retry",e);stopSelf();}
  return START_NOT_STICKY;
 }
 @Override public void onDestroy(){active=false;handler.removeCallbacksAndMessages(null);if(pending!=null)pending.cancel();if(registered)unregisterReceiver(result);super.onDestroy();}
}
