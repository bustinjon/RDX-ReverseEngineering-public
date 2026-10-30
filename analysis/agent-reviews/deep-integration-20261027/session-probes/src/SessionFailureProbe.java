import com.rdx.fullscreen.usbhelper.*;
import com.rdx.fullscreen.projection.*;
import com.google.android.projection.protocol.*;
import android.hardware.usb.*;
import android.content.Intent;
import android.os.Handler;
import android.view.Surface;
import java.lang.reflect.*;

public final class SessionFailureProbe {
 private static int assertions;
 private static void require(boolean value,String label){assertions++;if(!value)throw new AssertionError(label);}
 private static Field field(String name)throws Exception{Field f=AaSessionService.class.getDeclaredField(name);f.setAccessible(true);return f;}
 private static void put(AaSessionService s,String n,Object value)throws Exception{field(n).set(s,value);}
 private static Object get(AaSessionService s,String n)throws Exception{return field(n).get(s);}
 private static void invoke(AaSessionService s,String n)throws Exception{Method m=AaSessionService.class.getDeclaredMethod(n);m.setAccessible(true);m.invoke(s);}
 private static AaSessionService create(){AaSessionService s=new AaSessionService();s.onCreate();return s;}
 private static void transportFailureDoesNotCleanUp()throws Exception{
  AaSessionService s=create();GalReceiver r=new GalReceiver(s);VideoSink v=new VideoSink(s);InputSource i=new InputSource();
  VideoDecoder d=new VideoDecoder(s);UsbBulkTransport t=new UsbBulkTransport(new UsbManager(),new UsbDevice());
  put(s,"receiver",r);put(s,"videoSink",v);put(s,"inputSource",i);put(s,"decoder",d);put(s,"transport",t);
  put(s,"running",true);put(s,"protocolInitialized",true);invoke(s,"readLoop");
  require(!(Boolean)get(s,"running"),"abort clears running");require(t.closes==1&&r.prepares==1,"I/O abort happened");
  require(d.stops==0&&r.destroys==0&&v.destroys==0&&i.destroys==0,"native/decoder resources retained");
  require(!s.startedActions.contains("aa.overlay.STOP"),"overlay stop absent");
  s.onDestroy();require(d.stops==0&&r.destroys==0,"onDestroy skips cleanup after abort");
  System.out.println("OBSERVED transport_failure: running=false transport_closed=1 receiver_prepared=1 decoder_stops=0 native_destroys=0 overlay_stop=false; onDestroy_does_not_repair=true");
 }
 private static void pendingInitializationSurvivesStop()throws Exception{
  AaSessionService s=create();put(s,"pendingDevice",new UsbDevice());s.onSurfaceReady(new Surface(),1920,720);
  Handler h=(Handler)get(s,"handler");require(h.queued.size()==1,"initialization queued");
  invoke(s,"shutdown");require(h.queued.size()==1,"shutdown leaves initialization runnable queued");
  require(get(s,"pendingDevice")==null&&!(Boolean)get(s,"protocolInitialized"),"shutdown removed device and reopened initialization flag");
  require(s.stopCalls==1,"stopSelf requested");
  h.queued.clear();
  System.out.println("OBSERVED stop_race: pending_initialization=1 after_shutdown_pending_device=null protocol_initialized=false; stale_runnable_not_cancelled");
 }
 private static void existingOverlayWithoutSurfaceHasNoTimeout()throws Exception{
  AaSessionService s=create();AaOverlayService.instance=new AaOverlayService();
  Intent intent=new Intent(s,AaSessionService.class).setAction("aa.session.START").putExtra(UsbManager.EXTRA_DEVICE,new UsbDevice());
  s.onStartCommand(intent,0,1);Handler h=(Handler)get(s,"handler");require(h.queued.size()==1,"overlay lookup scheduled");
  h.runNext();require(AaOverlayService.instance.surfaceListener==s,"listener registered");
  require(h.queued.isEmpty(),"no surface timeout/retry scheduled once service exists");
  require(s.stopCalls==0&&!(Boolean)get(s,"running"),"session neither active nor stopped");
  AaOverlayService.instance=null;
  System.out.println("OBSERVED surface_never_ready: overlay_exists=true surface_ready=false pending_handlers=0 stop_requests=0 running=false");
 }
 public static void main(String[] args)throws Exception{
  transportFailureDoesNotCleanUp();pendingInitializationSurvivesStop();existingOverlayWithoutSurfaceHasNoTimeout();
  System.out.println("COUNTEREXAMPLES_CONFIRMED=3 ASSERTIONS="+assertions+"; actual coordinator, synthetic dependencies, no assets/native/USB execution");
 }
}
