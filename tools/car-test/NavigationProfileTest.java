import com.rdx.fullscreen.usbhelper.InputEvents;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

/** Contract tests for coherent page/move declarations and event delivery. */
public final class NavigationProfileTest {
    private static int checks;
    private static void check(boolean ok,String reason){checks++;if(!ok)throw new AssertionError(reason);}
    private static final class Sink implements InputEvents.KeyConsumer {
        final List<String> events=new ArrayList<String>();
        public void send(int code,boolean down){events.add(code+":"+down);}
    }
    private static void pair(int raw,int mapped){
        Sink sink=new Sink();
        check(InputEvents.dispatchKey(raw,0,sink),"Physical DOWN must be consumed");
        check(InputEvents.dispatchKey(raw,1,sink),"Physical UP must be consumed");
        check(sink.events.equals(Arrays.asList(mapped+":true",mapped+":false")),"Wrong or duplicate native pair");
        boolean declared=false;for(int code:InputEvents.supportedKeyCodes())if(code==mapped)declared=true;
        check(declared,"Emitted key must be declared");
    }
    public static void main(String[] args){
        if(args.length!=1)throw new IllegalArgumentException("arrows|padonly");
        boolean arrows=args[0].equals("arrows");
        check(arrows||args[0].equals("padonly"),"Unknown profile");
        int[] expected=arrows?new int[]{4,19,20,21,22,23,92,93,122,123}:new int[]{4,23,92,93,122,123};
        check(Arrays.equals(InputEvents.supportedKeyCodes(),expected),"Wrong advertised profile");
        pair(146,93);pair(152,92);pair(148,122);pair(150,123);
        pair(66,23);pair(23,23);pair(4,4);
        for(int raw:new int[]{19,20,21,22}){
            check(InputEvents.key(raw)==arrows,"Arrow acceptance must match declaration");
            Sink sink=new Sink();
            check(InputEvents.dispatchKey(raw,0,sink)==arrows,"Arrow dispatch must match declaration");
            check(sink.events.size()==(arrows?1:0),"Undeclared arrow leaked");
        }
        for(int code:new int[]{38,39,87,88,84,209,65536}){
            Sink sink=new Sink();
            check(!InputEvents.dispatchKey(code,0,sink),"Unrelated input accepted");
            check(sink.events.isEmpty(),"Unrelated input emitted");
        }
        check(!InputEvents.dispatchKey(146,2,new Sink()),"Reject non-key action");
        check(!InputEvents.dispatchKey(146,0,null),"Reject missing sink");
        InputEvents.SelectPress select=new InputEvents.SelectPress();
        check(select.action(1)==-1,"Orphan touch release must not select");
        check(select.action(0)==1,"Select DOWN missing");
        check(select.action(0)==-1,"Duplicate Select DOWN");
        check(select.action(2)==-1,"Movement must not select");
        check(select.action(1)==0,"Select UP missing");
        check(select.action(1)==-1,"Duplicate Select UP");
        check(select.action(0)==1,"Second press missing");
        check(select.action(3)==0,"Cancel must release Select");
        check(select.action(1)==-1,"No second release after cancel");
        InputEvents.HoverContact hover=new InputEvents.HoverContact();
        check(hover.action(9)==0,"Hover ENTER missing");
        check(hover.action(9)==-1,"Duplicate hover ENTER forwarded");
        check(hover.action(7)==2,"Hover MOVE lost");
        check(hover.action(10)==1,"Hover EXIT lost");
        check(hover.action(9)==0,"Next contact lost");
        System.out.println("PASS: "+checks+" navigation/Select/Back/hover contract checks, profile="+args[0]);
    }
}
