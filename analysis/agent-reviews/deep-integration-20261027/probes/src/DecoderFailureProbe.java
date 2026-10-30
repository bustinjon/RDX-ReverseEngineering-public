import android.media.MediaCodec;
import android.view.Surface;
import com.rdx.fullscreen.projection.VideoDecoder;
import java.lang.reflect.Field;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

/** Runs the unmodified repository VideoDecoder against a synthetic Android API seam. */
public final class DecoderFailureProbe {
    private static int assertions;
    private static final class Events implements VideoDecoder.Listener {
        final CountDownLatch workerError=new CountDownLatch(1);
        final AtomicInteger failureEvents=new AtomicInteger();
        public void event(String text) {
            if(text.startsWith("Decoder failed:")) failureEvents.incrementAndGet();
            if(text.startsWith("Decoder worker stopped:")) workerError.countDown();
        }
        public void format(int w,int h) { }
        public void rendered() { }
    }
    private static void require(boolean condition,String name) {
        assertions++; if(!condition) throw new AssertionError(name);
    }
    private static Thread worker(VideoDecoder d) throws Exception {
        Field f=VideoDecoder.class.getDeclaredField("worker"); f.setAccessible(true); return (Thread)f.get(d);
    }
    private static Runnable ack(final CountDownLatch latch) { return new Runnable(){ public void run(){latch.countDown();} }; }
    private static VideoDecoder start(Events e) {
        VideoDecoder d=new VideoDecoder(e); d.surface(new Surface()); d.start(); return d;
    }
    private static void creationFailureStillAcknowledged() throws Exception {
        MediaCodec.reset(); MediaCodec.failCreate=true; Events e=new Events(); VideoDecoder d=start(e);
        try {
            CountDownLatch acknowledged=new CountDownLatch(2);
            require(d.frame(new byte[]{11},ack(acknowledged)),"first frame accepted");
            require(d.frame(new byte[]{12},ack(acknowledged)),"second frame accepted");
            require(acknowledged.await(2,TimeUnit.SECONDS),"both frames acknowledged despite failed decoder");
            require(MediaCodec.createCalls.get()==1,"broken decoder never retries construction");
            require(MediaCodec.submissions.isEmpty(),"zero packets submitted to a codec");
            require(e.failureEvents.get()==1,"only one decoder failure event");
            require(worker(d).isAlive(),"worker continues consuming after failure");
            System.out.println("OBSERVED create_failure: accepted=2 acknowledged=2 codec_submissions=0 construction_attempts=1 worker_alive=true");
        } finally { require(d.stop(),"first worker stopped"); }
    }
    private static void lateConfigurationIsNotSubmitted() throws Exception {
        MediaCodec.reset(); Events e=new Events(); VideoDecoder d=new VideoDecoder(e); d.surface(new Surface());
        d.config(new byte[]{1}); d.start();
        try {
            CountDownLatch first=new CountDownLatch(1);
            require(d.frame(new byte[]{11},ack(first)),"first config-case frame accepted");
            require(first.await(2,TimeUnit.SECONDS),"first config-case frame acknowledged");
            d.config(new byte[]{2});
            CountDownLatch second=new CountDownLatch(1);
            require(d.frame(new byte[]{22},ack(second)),"second config-case frame accepted");
            require(second.await(2,TimeUnit.SECONDS),"second config-case frame acknowledged");
            require(MediaCodec.submissions.size()==3,"only initial config plus two frames submitted");
            require(MediaCodec.submissions.get(0).firstByte==1 && MediaCodec.submissions.get(0).flags==2,"initial config delivered");
            require(MediaCodec.submissions.get(1).firstByte==11 && MediaCodec.submissions.get(2).firstByte==22,"late config omitted");
            System.out.println("OBSERVED late_config: submitted=[config:1,frame:11,frame:22] replacement_config:2_absent");
        } finally { require(d.stop(),"second worker stopped"); }
    }
    private static void deadWorkerStillAcceptsFrames() throws Exception {
        MediaCodec.reset(); MediaCodec.failDrain=true; Events e=new Events(); VideoDecoder d=start(e);
        try {
            CountDownLatch first=new CountDownLatch(1);
            require(d.frame(new byte[]{11},ack(first)),"output-failure frame accepted");
            require(e.workerError.await(2,TimeUnit.SECONDS),"output failure observed");
            Thread t=worker(d); t.join(2000); require(!t.isAlive(),"worker has terminated before further submissions");
            final AtomicInteger lateAcks=new AtomicInteger(); Runnable a=new Runnable(){public void run(){lateAcks.incrementAndGet();}};
            int accepted=0; for(int i=0;i<25;i++) if(d.frame(new byte[]{33},a)) accepted++;
            require(accepted==24,"dead worker still accepts its full queue");
            require(lateAcks.get()==0,"accepted post-failure frames have no consumer");
            System.out.println("OBSERVED output_failure: worker_alive=false subsequently_accepted=24 subsequently_acknowledged=0 next_enqueue=false");
        } finally { require(d.stop(),"third worker stopped"); }
    }
    public static void main(String[] args) throws Exception {
        creationFailureStillAcknowledged(); lateConfigurationIsNotSubmitted(); deadWorkerStillAcceptsFrames();
        System.out.println("COUNTEREXAMPLES_CONFIRMED=3 ASSERTIONS="+assertions+"; synthetic host API, no Android/USB/native execution");
    }
}
