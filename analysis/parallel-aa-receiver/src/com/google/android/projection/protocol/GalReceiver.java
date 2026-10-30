package com.google.android.projection.protocol;

/** Small API22 JNI facade. Names/field descriptors deliberately match stock JNI ABI. */
public final class GalReceiver {
    private long mNativeGalReceiver;
    private final Listener listener;
    private boolean initialized, prepared, destroyed;
    public interface AudioFocusListener { void request(int request); }
    private AudioFocusListener audioFocusListener;
    public void audioFocusListener(AudioFocusListener listener) { audioFocusListener=listener; }
    public synchronized void answerAudioFocus(int state,boolean unsolicited) {
        if(initialized && !prepared && !destroyed) {
            listener.event("AUDIO_PROTOCOL_REPLY state="+state+" unsolicited="+unsolicited);
            nativeSetAudioFocus(state,unsolicited);
        }
    }
    public interface Listener { void event(String text); void discovery(); void byeBye(); }
    public static final class CarInfo {
        public String manufacturer="Honda", model="RDX", modelYear="2021", vehicleId="";
        public int driverPosition=0;
        public String headUnitMake="RDX Research", headUnitModel="ParallelReceiver";
        public String headUnitSoftwareBuild="D.1.6.4-local-test", headUnitSoftwareVersion="0.1.0-experimental";
        public boolean canPlayNativeMediaDuringVr=false;
        public int sessionConfiguration=0;
        public String displayName="RDX parallel AA test";
    }
    public static final class ConnectedDevice {
        public final String deviceName; public final int deviceId;
        public ConnectedDevice(String name,int id) { deviceName=name; deviceId=id; }
    }
    private native void nativeInit();
    private native boolean nativeSetCreds(String root,String client,String key);
    private native void nativeSetCarInfo(CarInfo info);
    private native boolean nativeRegister(long service);
    private native void nativeStart();
    private native void nativePrepareShutdown();
    private native void nativeShutdown();
    private native int nativeGetAdditionalBytesToRead(byte[] header);
    private native int nativeQueueIncoming(byte[] frame,int length);
    private native int nativeGetEncodedFrame(byte[] frame);
    private native void nativePing(long timestamp,boolean bugreport);
    private native void nativeSetAudioFocus(int state,boolean unsolicited);
    private native void nativeSetNavFocus(int state);
    private native void nativeSendByeByeRequest(int reason);
    private native void nativeSendByeByeResponse();
    public GalReceiver(Listener listener) { this.listener=listener; }
    public void initialize(String[] creds) {
        if(initialized) throw new IllegalStateException("Already initialized");
        System.loadLibrary("autoreceiver_jni");
        nativeInit(); initialized=true;
        if(mNativeGalReceiver==0) throw new IllegalStateException("Native receiver handle is zero");
        if(!nativeSetCreds(creds[0],creds[1],creds[2])) throw new IllegalStateException("Protocol credential initialization rejected");
        nativeSetCarInfo(new CarInfo());
    }
    public long handle() { return mNativeGalReceiver; }
    public void register(VideoSink sink) {
        if(!nativeRegister(sink.handle())) throw new IllegalStateException("Video service registration rejected");
    }
    public void register(InputSource source) {
        if(!nativeRegister(source.handle())) throw new IllegalStateException("Input service registration rejected");
    }
    public void register(AudioSink sink) {
        if(!nativeRegister(sink.handle())) throw new IllegalStateException("AudioSink registration rejected");
    }
    public void register(AudioSource source) {
        if(!nativeRegister(source.handle())) throw new IllegalStateException("AudioSource registration rejected");
    }
    public void register(SensorSource source) {
        if(!nativeRegister(source.handle())) throw new IllegalStateException("SensorSource registration rejected");
    }
    public void startProtocol() { nativeStart(); }
    public int remaining(byte[] header) { return nativeGetAdditionalBytesToRead(header); }
    public void incoming(byte[] data,int length) { nativeQueueIncoming(data,length); }
    public int outgoing(byte[] data) { return nativeGetEncodedFrame(data); }
    public void ping(long timestamp) { nativePing(timestamp,false); }
    public synchronized void prepare() { if(initialized&&!prepared&&!destroyed) { prepared=true; nativePrepareShutdown(); } }
    public synchronized void destroy() { if(initialized&&!destroyed) { destroyed=true; nativeShutdown(); } }
    // Exact names/descriptors expected by ControllerCallbacks in the original native library.
    public void unrecoverableErrorCallback(int error) { listener.event("GAL error="+error); }
    public void serviceDiscoveryRequestCallback(byte[] small,byte[] medium,byte[] large,String label,String deviceName) {
        listener.event("L4 service discovery callback (not proof of selected video)"); listener.discovery();
    }
    public void bugreportRequestCallback(long timestamp) { listener.event("Bugreport request ignored"); }
    public void pingResponseCallback(long timestamp) { listener.event("GAL ping response"); }
    public void navigationFocusCallback(int request) { nativeSetNavFocus(1); }
    public void audioFocusRequestCallback(int request) {
        listener.event("AUDIO_PROTOCOL_REQUEST request="+request);
        if(audioFocusListener!=null)audioFocusListener.request(request);
        else nativeSetAudioFocus(3,false);
    }
    public void byeByeRequestCallback(int reason) { nativeSendByeByeResponse(); listener.byeBye(); }
    public void byeByeResponseCallback() { listener.byeBye(); }
    public void voiceSessionNotificationCallback(int status) { listener.event("Voice session="+status+" (no voice integration)"); }
    public void batteryStatusNotificationCallback(int level,int remaining,boolean critical) { /* no private phone status logging */ }
    public void carConnectedDevicesRequestCallback() { listener.event("Connected-device list unsupported"); }
    public void userSwitchRequestCallback(ConnectedDevice device) { listener.event("User switch unsupported"); }
}
