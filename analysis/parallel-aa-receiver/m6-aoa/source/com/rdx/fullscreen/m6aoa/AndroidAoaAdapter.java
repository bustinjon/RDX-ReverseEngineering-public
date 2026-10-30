package com.rdx.fullscreen.m6aoa;
import android.app.PendingIntent;import android.content.*;import android.hardware.usb.*;import android.os.SystemClock;import java.util.*;
/** Inert constructor. Every actionable method independently enforces the frozen live block. */
public final class AndroidAoaAdapter implements AndroidUsbEnvironment {
 private final Context context;private final UsbManager manager;private final String callbackAction;private final HashMap<String,UsbIdentity> seen=new HashMap<String,UsbIdentity>();private long generation;private UsbDeviceConnection connection;private UsbIdentity selected;private int count,starts;private boolean opened;
 public AndroidAoaAdapter(Context c,UsbManager m,String action){context=c;manager=m;callbackAction=action;}
 public void attachmentEvent(UsbDevice d){if(d!=null)seen.remove(d.getDeviceName());}
 public long now(){return SystemClock.elapsedRealtime();}public long wall(){return System.currentTimeMillis();}
 public UsbIdentity[] inventory(){LiveExecutionPolicy.requireReviewedActivation();HashMap<String,UsbIdentity> next=new HashMap<String,UsbIdentity>();for(UsbDevice d:manager.getDeviceList().values()){if(next.size()>=32)throw new IllegalStateException("Inventory policy");UsbIdentity old=seen.get(d.getDeviceName());long gen=old!=null&&old.vendorId==d.getVendorId()&&old.productId==d.getProductId()&&old.deviceId==d.getDeviceId()?old.generation:++generation;int n=d.getInterfaceCount();if(n>32)throw new IllegalStateException("Interfaces");StringBuilder b=new StringBuilder();for(int i=0;i<n;i++){UsbInterface f=d.getInterface(i);b.append(i).append(':').append(f.getInterfaceClass()).append(':').append(f.getEndpointCount()).append(',');}next.put(d.getDeviceName(),new UsbIdentity(d.getVendorId(),d.getProductId(),d.getDeviceId(),d.getDeviceName(),n,b.toString(),"-",gen,now()));}seen.clear();seen.putAll(next);return next.values().toArray(new UsbIdentity[next.size()]);}
 private UsbDevice device(UsbIdentity id){LiveExecutionPolicy.requireReviewedActivation();inventory();UsbIdentity current=seen.get(id.path);if(!id.sameAttachment(current))throw new SecurityException("Attachment changed");UsbDevice d=manager.getDeviceList().get(id.path);if(d==null||d.getDeviceId()!=id.deviceId||d.getVendorId()!=id.vendorId||d.getProductId()!=id.productId)throw new SecurityException("Device changed");return d;}
 public boolean hasPermission(UsbIdentity d){LiveExecutionPolicy.requireReviewedActivation();return manager.hasPermission(device(d));}
 public void requestPermission(UsbIdentity id,String nonce){LiveExecutionPolicy.requireReviewedActivation();UsbDevice d=device(id);Intent callback=new Intent(callbackAction).setPackage(context.getPackageName()).putExtra("nonce",nonce);PendingIntent pi=PendingIntent.getBroadcast(context,0,callback,PendingIntent.FLAG_ONE_SHOT|PendingIntent.FLAG_CANCEL_CURRENT);manager.requestPermission(d,pi);}
 public void open(UsbIdentity id){LiveExecutionPolicy.requireReviewedActivation();if(opened||id.kind()!=UsbIdentity.Kind.NORMAL_PHONE)throw new SecurityException("Open once normal only");UsbDevice d=device(id);if(!manager.hasPermission(d))throw new SecurityException("Own UID permission");opened=true;selected=id;connection=manager.openDevice(d);if(connection==null)throw new SecurityException("Open refused");}
 public Result transfer(AoaRequest r){LiveExecutionPolicy.requireReviewedActivation();if(connection==null||selected==null||!hasPermission(selected)||count++>=8||r.value!=0)throw new SecurityException("Transfer gate");byte[] b=r.payload();int result;long started=now();
  if(r.code==51&&r.type==192&&r.index==0&&r.length==2&&b.length==2){result=connection.controlTransfer(192,51,0,0,b,2,1000);}
  else if(r.code==52&&r.type==64&&r.index>=0&&r.index<=5&&r.length==b.length&&b.length>=1&&b.length<=256&&b[b.length-1]==0){result=connection.controlTransfer(64,52,0,r.index,b,b.length,1000);}
  else if(r.code==53&&r.type==64&&r.index==0&&r.length==0&&b.length==0&&starts++==0){result=connection.controlTransfer(64,53,0,0,null,0,1000);}
  else throw new SecurityException("Only AOA51/52/53 allowed");
  return new Result(result==r.length?Status.ACCEPTED:Status.ERROR,result,r.code==51&&result==2?b:new byte[0],now()-started);
 }
 public void close(){if(connection!=null){connection.close();connection=null;}}
}
