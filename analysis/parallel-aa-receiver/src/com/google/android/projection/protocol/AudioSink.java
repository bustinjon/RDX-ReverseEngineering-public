package com.google.android.projection.protocol;

import android.util.Log;
import android.content.Context;
import android.media.AudioTrack;
import android.media.AudioFormat;
import android.media.AudioManager;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.TimeUnit;

/**
 * JNI facade for the native AudioSink in libautoreceiver_jni.so.
 * Bounded PCM16 playback via public AudioTrack; hardware routing requires validation.
 */
public final class AudioSink {
    private static final String TAG = "RDX.AUDIO";

    @SuppressWarnings("unused") // set by native code
    private long mNativeAudioSink;
    private volatile boolean created, stopping, focusAllowed=true;
    private volatile boolean focusHeld;
    private volatile boolean focusRequesting;
    private volatile boolean focusSuspended;
    private long nextFocusAttempt;
    private int sampleRate, channels, audioType;
    private volatile int activeSession=-1, stoppedSession=Integer.MIN_VALUE;
    /** Guidance session whose already-received audio is still playing out after the phone said stop. */
    private volatile int drainingSession=Integer.MIN_VALUE;
    private AudioManager manager;
    private volatile AudioTrack player;
    private Thread worker;
    private long received, played, dropped;
    public interface FocusObserver { void changed(int androidChange); }
    private FocusObserver focusObserver;
    public void focusObserver(FocusObserver observer) { focusObserver=observer; }
    public int requestProtocolFocus(int request) {
        int gain=AudioFocusPolicy.gain(request);
        if(gain==0){
            focusSuspended=true;focusAllowed=false;focusHeld=false;frames.clear();
            AudioTrack track=player;try{if(track!=null){track.pause();track.flush();}}catch(IllegalStateException ignored){}
            if(manager!=null)manager.abandonAudioFocus(focus);
            Log.i(TAG,"AUDIO_FOCUS_REQUEST id="+serviceId+" request="+request+" releaseOrUnsupported=true");
            return 3;
        }
        boolean granted=manager!=null && manager.requestAudioFocus(focus,AudioManager.STREAM_MUSIC,gain)==AudioManager.AUDIOFOCUS_REQUEST_GRANTED;
        focusAllowed=granted;focusHeld=granted;focusSuspended=!granted;
        Log.i(TAG,"AUDIO_FOCUS_REQUEST id="+serviceId+" request="+request+" granted="+granted);
        return AudioFocusPolicy.reply(request,granted);
    }
    private final ArrayBlockingQueue<Frame> frames=new ArrayBlockingQueue<Frame>(16);
    private static final class Frame {
        final int session; final byte[] data;
        Frame(int session,byte[] data){this.session=session;this.data=data;}
    }
    private final AudioManager.OnAudioFocusChangeListener focus=new AudioManager.OnAudioFocusChangeListener(){
        public void onAudioFocusChange(int change){
            focusAllowed=change==AudioManager.AUDIOFOCUS_GAIN || change==AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK;
            if(change==AudioManager.AUDIOFOCUS_LOSS){focusHeld=false;focusSuspended=true;}
            if(change==AudioManager.AUDIOFOCUS_GAIN){focusHeld=true;focusSuspended=false;}
            AudioTrack track=player;
            try { if(track!=null){if(!focusAllowed)track.pause();else track.setStereoVolume(change==AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK?0.25f:1f,change==AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK?0.25f:1f);} } catch(IllegalStateException ignored){}
            Log.i(TAG,"AUDIO_FOCUS id="+serviceId+" change="+change);
            if(focusObserver!=null && !stopping)focusObserver.changed(change);
        }
    };
    public void context(Context context){manager=(AudioManager)context.getApplicationContext().getSystemService(Context.AUDIO_SERVICE);}
    private int serviceId;

    private native int nativeInit(int i, long j) throws IllegalStateException;
    private native void nativeAddSupportedConfiguration(int i, int i2, int i3);
    private native void nativeSetAudioType(int i);
    private native void nativeSetCodecType(int i);
    private native void nativeSetMaxUnackedFrames(int i);
    private native void nativeAckFrames(int i, int i2);
    private native void nativeShutdown();

    public void initialize(int serviceId, long receiverHandle,
                           int samplingRate, int bits, int channels,
                           int audioType, int codecType) {
        this.serviceId = serviceId;
        if(bits!=16 || channels<1 || channels>2 || codecType!=1)throw new IllegalArgumentException("Only PCM16 mono/stereo supported");
        this.sampleRate=samplingRate;this.channels=channels;this.audioType=audioType;
        if (nativeInit(serviceId, receiverHandle) != 0) {
            throw new IllegalStateException("AudioSink nativeInit rejected id=" + serviceId);
        }
        created = true;
        nativeSetMaxUnackedFrames(16);
        nativeAddSupportedConfiguration(samplingRate, bits, channels);
        nativeSetAudioType(audioType);
        nativeSetCodecType(codecType);
        worker=new Thread(new Runnable(){public void run(){playLoop();}},"RDX-audio-"+serviceId);
        worker.start();
        Log.i(TAG, "AudioSink initialized id=" + serviceId
            + " " + samplingRate + "/" + bits + "/" + channels
            + " type=" + audioType + " codec=" + codecType);
    }

    public long handle() { return mNativeAudioSink; }

    /** True while this sink holds Android focus or is still playing out a stopped guidance session. */
    public boolean holdsFocus() { return focusHeld || focusRequesting || drainingSession!=Integer.MIN_VALUE; }

    public void destroy() {
        if (created) {
            created = false;
            stopping=true;frames.clear();
            AudioTrack track=player;
            try{if(track!=null)track.pause();}catch(IllegalStateException ignored){}
            if(worker!=null){worker.interrupt();try{worker.join(2000);}catch(InterruptedException e){Thread.currentThread().interrupt();}}
            if(worker!=null && worker.isAlive())Log.e(TAG,"AUDIO_WORKER_NOT_STOPPED id="+serviceId);
            nativeShutdown();
            Log.i(TAG, "AudioSink destroyed id=" + serviceId);
        }
    }

    @SuppressWarnings("unused") // called by native code
    public void dataAvailableCallback(int sessionId, long timestamp, byte[] data) {
        if(!created)return;
        try{
            received++;
            if(stopping){dropped++;return;}
            if(sessionId==stoppedSession){dropped++;return;}
            if(activeSession!=sessionId)focusSuspended=false;
            activeSession=sessionId;
            if(!frames.offer(new Frame(sessionId,PcmFrames.copy(data,channels))))dropped++;
            if(received==1 || received%250==0)Log.i(TAG,"PCM id="+serviceId+" received="+received+" playedBytes="+played+" dropped="+dropped);
        }catch(IllegalArgumentException e){dropped++;Log.w(TAG,"PCM rejected id="+serviceId+": "+e.getMessage());}
        finally{if(created)nativeAckFrames(sessionId,1);}
    }

    @SuppressWarnings("unused")
    public int codecConfigCallback(byte[] data) {
        Log.i(TAG, "Audio codec config id=" + serviceId + " len=" + data.length);
        return 0;
    }

    @SuppressWarnings("unused")
    public int setupCallback(int mediaCodecType) {
        Log.i(TAG, "Audio setup id=" + serviceId + " codec=" + mediaCodecType);
        return 0;
    }

    @SuppressWarnings("unused")
    public void playbackStartCallback(int sessionId) {
        stoppedSession=Integer.MIN_VALUE;activeSession=sessionId;focusSuspended=false;
        if(drainingSession==sessionId)drainingSession=Integer.MIN_VALUE;
        Log.i(TAG, "Audio playback start id=" + serviceId + " session=" + sessionId);
    }

    @SuppressWarnings("unused")
    public void playbackStopCallback(int sessionId) {
        if(audioType==1 && sessionId==activeSession && !stopping){
            // The phone sends guidance faster than real time and says stop when sending ends.
            // Keep queued frames and the track buffer; the play loop releases focus once drained.
            stoppedSession=sessionId;drainingSession=sessionId;activeSession=-1;
            Log.i(TAG, "Audio playback stop id=" + serviceId + " session=" + sessionId + " draining=" + frames.size());
            return;
        }
        stoppedSession=sessionId;activeSession=-1;frames.clear();
        focusHeld=false;focusAllowed=false;
        if(manager!=null)manager.abandonAudioFocus(focus);
        AudioTrack track=player;try{if(track!=null){track.pause();track.flush();}}catch(IllegalStateException ignored){}
        Log.i(TAG, "Audio playback stop id=" + serviceId + " session=" + sessionId);
    }

    /** Queue empty after a guidance stop: let the track play its buffer out, then give focus back. */
    private void finishDrain(){
        int session=drainingSession;drainingSession=Integer.MIN_VALUE;
        AudioTrack track=player;try{if(track!=null)track.stop();}catch(IllegalStateException ignored){}
        focusHeld=false;focusAllowed=false;
        if(manager!=null)manager.abandonAudioFocus(focus);
        Log.i(TAG,"Audio guidance drained id="+serviceId+" session="+session+" playedBytes="+played);
    }

    private void playLoop(){
        try{
            while(!stopping){
                final Frame frame=frames.poll(100,TimeUnit.MILLISECONDS);
                if(frame==null){if(drainingSession!=Integer.MIN_VALUE && activeSession==-1)finishDrain();continue;}
                if(frame.session!=activeSession && frame.session!=drainingSession){dropped++;continue;}
                if(focusSuspended){dropped++;continue;}
                if(manager!=null && !focusHeld){
                    long now=android.os.SystemClock.elapsedRealtime();
                    if(now<nextFocusAttempt){dropped++;continue;}
                    nextFocusAttempt=now+1000;
                    focusRequesting=true; // the other sink's focus callback may arrive before this returns
                    try{
                        focusAllowed=manager.requestAudioFocus(focus,AudioManager.STREAM_MUSIC,audioType==1?AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK:AudioManager.AUDIOFOCUS_GAIN)==AudioManager.AUDIOFOCUS_REQUEST_GRANTED;
                        focusHeld=focusAllowed;
                    }finally{focusRequesting=false;}
                }
                if(player==null){
                    if(!focusAllowed){dropped++;continue;}
                    int mask=channels==2?AudioFormat.CHANNEL_OUT_STEREO:AudioFormat.CHANNEL_OUT_MONO;
                    int minimum=AudioTrack.getMinBufferSize(sampleRate,mask,AudioFormat.ENCODING_PCM_16BIT);
                    if(minimum<=0)throw new IllegalStateException("Unsupported AudioTrack format");
                    player=new AudioTrack(AudioManager.STREAM_MUSIC,sampleRate,mask,AudioFormat.ENCODING_PCM_16BIT,Math.max(minimum,sampleRate*channels*2/5),AudioTrack.MODE_STREAM);
                    if(player.getState()!=AudioTrack.STATE_INITIALIZED)throw new IllegalStateException("AudioTrack initialization failed");
                    Log.i(TAG,"AUDIO_TRACK_READY id="+serviceId+" session="+player.getAudioSessionId());
                }
                if(!focusAllowed){dropped++;continue;}
                player.play();
                boolean complete=PcmFrames.write(new PcmFrames.Writer(){public int write(byte[] data,int offset,int count){
                    if(stopping || !focusAllowed || (frame.session!=activeSession && frame.session!=drainingSession))return -1;
                    int written=player.write(data,offset,count);if(written>0)played+=written;return written;
                }},frame.data);
                if(!complete){dropped++;Log.w(TAG,"PCM write incomplete id="+serviceId);}
            }
        }catch(InterruptedException e){Thread.currentThread().interrupt();}
        catch(Exception e){Log.e(TAG,"AUDIO_PLAYBACK_FAILED id="+serviceId+": "+e);}
        finally{
            stopping=true;frames.clear();
            AudioTrack track=player;player=null;
            if(track!=null){try{track.stop();}catch(IllegalStateException ignored){}track.release();}
            if(manager!=null)manager.abandonAudioFocus(focus);
            Log.i(TAG,"AUDIO_SUMMARY id="+serviceId+" received="+received+" playedBytes="+played+" dropped="+dropped);
        }
    }
}
