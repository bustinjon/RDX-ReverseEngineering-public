import com.rdx.fullscreen.usbhelper.InputEvents;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public final class DownMotionOnlyTest {
    private static int checks;
    private static void check(boolean ok,String why){checks++;if(!ok)throw new AssertionError(why);}
    private static final class Sink implements InputEvents.KeyConsumer {
        final List<String> events=new ArrayList<String>();
        public void send(int code,boolean down){events.add(code+":"+down);}
    }
    private static void pair(int raw,int mapped){
        Sink sink=new Sink();
        check(InputEvents.dispatchKey(raw,0,sink),"Existing DOWN not consumed");
        check(InputEvents.dispatchKey(raw,1,sink),"Existing UP not consumed");
        check(sink.events.equals(Arrays.asList(mapped+":true",mapped+":false")),"Existing pair changed");
    }
    public static void main(String[] args){
        check(Arrays.equals(InputEvents.supportedKeyCodes(),new int[]{4,23,92,93,122,123}),"Capability profile changed");
        check(InputEvents.keyCode(146)==93&&InputEvents.key(146),"Down mapping/declaration must remain intact");
        Sink sink=new Sink();
        check(InputEvents.dispatchKey(146,0,sink),"Raw Down press must be consumed");
        check(sink.events.isEmpty(),"Raw Down leaked native command");
        check(InputEvents.dispatchKey(146,0,sink),"Repeated press must stay consumed");
        check(InputEvents.dispatchKey(146,1,sink),"Raw Down release must be consumed");
        check(InputEvents.dispatchKey(146,1,sink),"Duplicate release must stay consumed");
        check(sink.events.isEmpty(),"Down repeat/release must not emit PageDown or fallback DPAD");
        check(!InputEvents.dispatchKey(146,2,sink),"Invalid action accepted");
        check(!InputEvents.dispatchKey(146,0,null),"Inactive sink must retain prior rejection");
        pair(152,92);pair(148,122);pair(150,123);pair(4,4);pair(66,23);pair(23,23);
        pair(93,93); // The source-specific probe does not remove native PageDown capability.
        for(int raw:new int[]{19,20,21,22,38,39,87,88,65536}){
            Sink rejected=new Sink();
            check(!InputEvents.dispatchKey(raw,0,rejected),"Unrelated/undeclared input accepted");
            check(rejected.events.isEmpty(),"Unrelated native event emitted");
        }
        Sink interleaved=new Sink();
        InputEvents.dispatchKey(146,0,interleaved);
        InputEvents.dispatchKey(23,0,interleaved);InputEvents.dispatchKey(23,1,interleaved);
        InputEvents.dispatchKey(146,1,interleaved);
        check(interleaved.events.equals(Arrays.asList("23:true","23:false")),"Suppressed Down interfered with Select");
        InputEvents.SelectPress select=new InputEvents.SelectPress();
        check(select.action(0)==1,"Select press missing");check(select.action(0)==-1,"Select duplicate");
        check(select.action(2)==-1,"Move created select");check(select.action(3)==0,"Cancel did not release");
        check(select.action(1)==-1,"Release duplicated after cancel");
        InputEvents.HoverContact hover=new InputEvents.HoverContact();
        check(hover.action(9)==0,"Pad DOWN missing");check(hover.action(9)==-1,"Duplicate pad DOWN");
        check(hover.action(7)==2,"Pad MOVE missing");check(hover.action(10)==1,"Pad UP missing");
        System.out.println("PASS: "+checks+" Down-only suppression and preserved-control checks");
    }
}
