import com.rdx.fullscreen.usbhelper.InputEvents;
import java.io.BufferedReader;
import java.io.FileReader;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/** Recorded single-pointer contact invariants; no Android or device dependency. */
public final class HoverContactReplayTest {
    private static int checks;
    private static void check(boolean value,String message){
        checks++;
        if(!value)throw new AssertionError(message);
    }
    private static void scenarios(){
        InputEvents.HoverContact contact=new InputEvents.HoverContact();
        check(contact.action(9)==0,"First enter must start contact");
        check(contact.action(9)==-1,"Duplicate enter must not start a second contact");
        check(contact.action(7)==2,"Movement must survive duplicate enter");
        check(contact.action(8)==-1,"Unknown action must remain rejected");
        check(contact.action(9)==-1,"Unknown action must not end contact");
        check(contact.action(10)==1,"Exit must remain paired");
        check(contact.action(9)==0,"New contact must survive prior duplicate");
        check(contact.action(10)==1,"Second contact must release");
        // This candidate deliberately preserves previously forwarded orphan MOVE/EXIT.
        check(contact.action(7)==2,"Idle move behavior must remain unchanged");
        check(contact.action(10)==1,"Idle exit behavior must remain unchanged");
        check(contact.action(9)==0,"Start before overlay recreation");
        contact=new InputEvents.HoverContact();
        check(contact.action(9)==0,"New overlay must have independent contact state");
        check(contact.action(10)==1,"New overlay releases normally");
        // Recorded click pattern: hover EXIT, Select DOWN/UP, repeated hover ENTER.
        InputEvents.SelectPress select=new InputEvents.SelectPress();
        for(int click=0;click<3;click++){
            check(contact.action(9)==0,"Hover before click");
            check(contact.action(10)==1,"Hover exits before click");
            check(select.action(0)==1,"Select DOWN unchanged");
            check(select.action(2)==-1,"Select movement remains ignored");
            check(select.action(1)==0,"Select UP unchanged");
            check(contact.action(9)==0,"Hover reentry after click survives");
            check(contact.action(9)==-1,"Second reentry after click is suppressed");
            check(contact.action(7)==2,"Movement after click survives");
            check(contact.action(10)==1,"Contact after click releases");
        }
    }
    public static void main(String[] args)throws Exception{
        if(args.length!=4)throw new IllegalArgumentException("capture.log pid expectedDuplicates expectedEvents");
        scenarios();
        int expectedDuplicates=Integer.parseInt(args[2]);
        int expectedEvents=Integer.parseInt(args[3]);
        Pattern owner=Pattern.compile("\\s"+Pattern.quote(args[1])+"\\s");
        Pattern event=Pattern.compile("RDX\\.AAOVERLAY: TOUCH #\\d+ (DOWN|MOVE|UP) raw=");
        InputEvents.HoverContact contact=new InputEvents.HoverContact();
        int inputEvents=0,inputDown=0,inputMoves=0,inputUp=0;
        int outputDown=0,outputMoves=0,outputUp=0,suppressed=0;
        boolean held=false;
        BufferedReader reader=new BufferedReader(new FileReader(args[0]));
        try{
            String line;
            while((line=reader.readLine())!=null){
                if(!owner.matcher(line).find())continue;
                Matcher match=event.matcher(line);
                if(!match.find())continue;
                inputEvents++;
                String action=match.group(1);
                int hover;
                if("DOWN".equals(action)){inputDown++;hover=9;}
                else if("MOVE".equals(action)){inputMoves++;hover=7;}
                else{inputUp++;hover=10;}
                int forwarded=contact.action(hover);
                if(forwarded<0){
                    check(hover==9,"Only ENTER may be suppressed in recorded stream");
                    suppressed++;
                }else if(forwarded==0){
                    check(!held,"Forwarded duplicate DOWN");
                    held=true;outputDown++;
                }else if(forwarded==2){
                    check(hover==7,"Move action changed");
                    outputMoves++;
                }else{
                    check(held,"Forwarded orphan UP");
                    held=false;outputUp++;
                }
            }
        }finally{reader.close();}
        check(inputEvents==expectedEvents,"Fixture event count differs");
        check(suppressed==expectedDuplicates,"Unexpected suppressed contacts");
        check(outputDown==inputDown-expectedDuplicates,"First contact DOWN lost");
        check(outputUp==inputUp,"Recorded release lost");
        check(outputMoves==inputMoves,"Recorded movement lost");
        check(outputDown==outputUp && !held,"Output does not end with balanced contacts");
        System.out.println("PASS: "+checks+" checks; input="+inputEvents+
            " suppressed="+suppressed+" outputDown="+outputDown+
            " moves="+outputMoves+" outputUp="+outputUp);
    }
}
