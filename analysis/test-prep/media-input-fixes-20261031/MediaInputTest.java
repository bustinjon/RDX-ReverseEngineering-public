package com.rdx.fullscreen.usbhelper;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public final class MediaInputTest {
    private static int checks;
    private static final List<String> events=new ArrayList<String>();
    private static final InputEvents.KeyConsumer consumer=new InputEvents.KeyConsumer(){
        public void send(int code,boolean down){events.add(code+":"+down);}
    };
    private static void check(boolean ok,String why){checks++;if(!ok)throw new AssertionError(why);}
    private static void empty(){check(events.isEmpty(),"Unexpected event "+events);}
    private static void pair(int code){
        check(events.equals(Arrays.asList(code+":true",code+":false")),"Bad balanced pair "+events);
        events.clear();
    }
    private static boolean key(InputEvents.MediaButtons media,int code,int scan,int source,int device,int action,int repeat,boolean canceled){
        return media.dispatch(code,scan,source,device,action,repeat,canceled,consumer);
    }
    private static void press(InputEvents.MediaButtons media,int code,int scan,int device,int mapped){
        check(key(media,code,scan,257,device,0,0,false),"Press not consumed");empty();
        check(key(media,code,scan,257,device,1,0,false),"Release not consumed");pair(mapped);
    }
    public static void main(String[] args){
        int[][] navigation={{146,93},{152,92},{148,122},{150,123},{66,23},{4,4}};
        for(int[] key:navigation){
            check(InputEvents.dispatchKey(key[0],0,consumer),"Navigation down");
            check(InputEvents.dispatchKey(key[0],1,consumer),"Navigation up");pair(key[1]);
        }
        check(!InputEvents.dispatchKey(146,2,consumer),"Unknown action accepted");empty();
        check(!InputEvents.dispatchKey(146,0,null),"Null consumer accepted");
        check(!InputEvents.key(19)&&!InputEvents.key(20)&&!InputEvents.key(21)&&!InputEvents.key(22),"Arrows advertised");
        check(InputEvents.key(87)&&InputEvents.key(88),"Media keys not advertised");
        InputEvents.MediaButtons media=new InputEvents.MediaButtons();
        press(media,138,66,1,88);press(media,139,67,1,87);
        press(media,87,0,-1,87);press(media,88,0,-1,88);
        check(key(media,139,67,257,1,0,0,false),"Initial next");
        check(key(media,139,67,257,1,0,1,false),"Repeat consumed");
        check(key(media,139,67,257,1,0,5,false),"Later repeat consumed");empty();
        key(media,139,67,257,1,1,0,false);pair(87);
        key(media,139,67,257,1,1,0,false);empty();
        key(media,138,66,257,1,0,0,false);
        key(media,138,66,257,1,1,0,true);empty();
        press(media,138,66,1,88);
        key(media,139,67,257,1,0,3,false);
        key(media,139,67,257,1,1,0,false);empty();
        check(!key(media,138,67,257,1,0,0,false),"Wrong scan captured");
        check(!key(media,139,67,4098,1,0,0,false),"Wrong source captured");
        check(!key(media,139,67,257,-1,0,0,false),"Unidentified OEM device captured");
        check(!key(media,24,115,257,1,0,0,false),"Volume captured as media");
        check(!key(media,139,67,257,1,2,0,false),"Invalid action captured");
        check(!media.dispatch(139,67,257,1,0,0,false,null),"Null media consumer accepted");empty();
        key(media,138,66,257,1,0,0,false);
        key(media,138,66,257,2,1,0,false);empty();
        key(media,88,0,257,1,1,0,false);empty();
        key(media,138,66,257,1,1,0,false);pair(88);
        key(media,138,66,257,1,0,0,false);media.reset();
        key(media,138,66,257,1,1,0,false);empty();
        key(media,138,66,257,1,0,0,false);key(media,139,67,257,1,0,0,false);
        key(media,139,67,257,1,1,0,false);pair(87);
        key(media,138,66,257,1,1,0,false);pair(88);
        InputEvents.SelectPress select=new InputEvents.SelectPress();
        check(select.action(0)==1&&select.action(0)==-1&&select.action(1)==0,"Select down/up changed");
        check(select.action(0)==1&&select.action(3)==0&&select.action(1)==-1,"Select cancel changed");
        InputEvents.HoverContact hover=new InputEvents.HoverContact();
        check(hover.action(9)==0&&hover.action(9)==-1&&hover.action(7)==2&&hover.action(10)==1,"Hover mapping changed");
        VolumeFeedback volume=new VolumeFeedback();
        check(volume.level()==-1,"Invented initial level");
        check(!volume.update(-1)&&volume.level()==-1,"Negative volume accepted");
        check(!volume.update(128)&&volume.level()==-1,"Invalid byte accepted");
        check(volume.update(12)&&volume.level()==12,"OEM level not stored");
        check(!volume.update(12)&&volume.level()==12,"Duplicate level treated as change");
        check(volume.update(0)&&volume.level()==0,"Zero volume rejected");
        check(volume.update(127)&&volume.level()==127,"Valid byte rejected");
        check(!volume.update(Integer.MAX_VALUE)&&volume.level()==127,"Bad value replaced actual level");
        volume.reset();check(volume.level()==-1&&volume.update(12),"Volume lifecycle reset failed");
        check(VolumeFeedback.DISPLAY_MS==3000,"HUD display interval mismatch");
        System.out.println("PASS "+checks+" checks: media sequencing/cancellation, navigation/Select/hover regression, OEM volume feedback");
    }
}
