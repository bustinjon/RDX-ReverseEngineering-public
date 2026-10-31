import com.rdx.fullscreen.usbhelper.InputEvents;
import java.io.BufferedReader;
import java.io.FileReader;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public final class BZoneSwipeTest {
    private static int checks;
    private static void check(boolean value,String message){
        checks++;if(!value)throw new AssertionError(message);
    }
    private static final class Sink implements InputEvents.KeyConsumer {
        final List<String> events=new ArrayList<String>();
        public void send(int code,boolean down){events.add(code+":"+down);}
        void pair(int start,int code){
            check(events.size()==start+2,"Expected exactly one pair");
            check(events.get(start).equals(code+":true"),"Expected mapped DOWN");
            check(events.get(start+1).equals(code+":false"),"Expected mapped UP");
        }
    }
    private static void scenarios(){
        Sink sink=new Sink();InputEvents.BZoneSwipe swipe=new InputEvents.BZoneSwipe();
        check(!swipe.dispatch(38,36,0,1,0,0,sink),"Reject wrong source");
        check(!swipe.dispatch(38,0,257,1,0,0,sink),"Reject missing scan");
        check(!swipe.dispatch(38,37,257,1,0,0,sink),"Reject swapped scan");
        check(!swipe.dispatch(39,36,257,1,0,0,sink),"Reject swapped top scan");
        check(!swipe.dispatch(38,36,257,-1,0,0,sink),"Reject virtual device");
        check(!swipe.dispatch(38,36,257,1,2,0,sink),"Reject non-key action");
        check(!swipe.dispatch(38,36,257,1,0,0,null),"No dispatch without consumer");
        for(int key:new int[]{4,19,20,21,22,23,66,146,148,150,152,87})
            check(!swipe.dispatch(key,36,257,1,0,0,sink),"Adapter must not capture primary/media keys");
        check(sink.events.isEmpty(),"Rejected inputs must not send");
        check(swipe.dispatch(38,36,257,11,1,0,sink),"Consume orphan release");
        check(sink.events.isEmpty(),"Orphan release must not trigger command");
        check(swipe.dispatch(38,36,257,11,0,0,sink),"Accept bottom DOWN");
        check(sink.events.isEmpty(),"Do not send until release");
        check(swipe.dispatch(38,36,257,11,0,1,sink),"Consume repeat");
        check(swipe.dispatch(38,36,257,11,0,0,sink),"Consume duplicate DOWN");
        check(swipe.dispatch(38,36,257,12,1,0,sink),"Consume foreign release");
        check(sink.events.isEmpty(),"Foreign release must not complete another device");
        check(swipe.dispatch(38,36,257,11,1,0,sink),"Complete owned release");sink.pair(0,20);
        check(swipe.dispatch(38,36,257,11,1,0,sink),"Consume duplicate release");
        check(sink.events.size()==2,"No second pair on duplicate release");
        int before=sink.events.size();
        check(swipe.dispatch(39,37,257,29,0,0,sink),"New device ID accepted per gesture");
        check(swipe.dispatch(39,37,257,29,1,0,sink),"Top release accepted");sink.pair(before,19);
        before=sink.events.size();
        swipe=new InputEvents.BZoneSwipe();
        check(swipe.dispatch(38,36,257,11,0,0,sink),"Start old overlay gesture");
        swipe=new InputEvents.BZoneSwipe();
        check(swipe.dispatch(38,36,257,11,1,0,sink),"New overlay sees orphan release");
        check(sink.events.size()==before,"New overlay must not retain prior held state");
        // The global primary filter remains unchanged, including rejecting J/K by default.
        check(!InputEvents.key(38)&&!InputEvents.key(39),"Default mapping must remain off");
        check(InputEvents.keyCode(38)==38&&InputEvents.keyCode(39)==39,"No global J/K remap");
        for(int code:new int[]{4,19,20,21,22,23})check(InputEvents.key(code),"Existing registered key lost");
    }
    public static void main(String[] args)throws Exception{
        if(args.length!=1)throw new IllegalArgumentException("capture.log");
        scenarios();
        Pattern raw=Pattern.compile("INPUT_RAW_KEY code=(38|39) scan=(\\d+) flags=\\d+ repeat=(\\d+) source=(\\d+) device=(\\d+)");
        BufferedReader reader=new BufferedReader(new FileReader(args[0]));int fixtureDowns=0;
        try{
            String line;
            while((line=reader.readLine())!=null){
                if(!line.matches(".*\\s8808\\s.*"))continue;
                Matcher m=raw.matcher(line);if(!m.find())continue;
                int code=Integer.parseInt(m.group(1)),scan=Integer.parseInt(m.group(2));
                int repeat=Integer.parseInt(m.group(3)),source=Integer.parseInt(m.group(4)),device=Integer.parseInt(m.group(5));
                InputEvents.BZoneSwipe swipe=new InputEvents.BZoneSwipe();Sink sink=new Sink();
                check(swipe.dispatch(code,scan,source,device,0,repeat,sink),"Recorded DOWN signature rejected");
                check(sink.events.isEmpty(),"Recorded DOWN must not emit pair");
                // Historical capture logs only raw DOWN here; this UP is synthetic.
                check(swipe.dispatch(code,scan,source,device,1,0,sink),"Synthetic release rejected");
                sink.pair(0,code==38?20:19);fixtureDowns++;
            }
        }finally{reader.close();}
        check(fixtureDowns>0,"No recorded B-zone signatures found");
        System.out.println("PASS: "+checks+" B-zone checks; recorded DOWN signatures="+fixtureDowns+
            "; fixture UP events synthetic, hardware release delivery UNVERIFIED");
    }
}
