import com.rdx.fullscreen.usbhelper.InputEvents;
import com.google.android.projection.protocol.PcmFrames;
import com.google.android.projection.protocol.AudioFocusPolicy;
public final class InputPcmTest {
    private static int checks;
    private static void check(boolean ok){checks++;if(!ok)throw new AssertionError("Check "+checks);}
    private static void reject(byte[] data,int channels){boolean rejected=false;try{PcmFrames.copy(data,channels);}catch(IllegalArgumentException e){rejected=true;}check(rejected);}
    public static void main(String[] args){
        check(InputEvents.hoverAction(9)==0);check(InputEvents.hoverAction(7)==2);check(InputEvents.hoverAction(10)==1);check(InputEvents.hoverAction(8)==-1);
        for(int key=0;key<200;key++)check(InputEvents.key(key)==(key==4 || key==19 || key==20 || key==21 || key==22 || key==23 || key==66));
        check(InputEvents.keyCode(66)==23);check(InputEvents.keyCode(23)==23);check(InputEvents.keyCode(4)==4);
        InputEvents.SelectPress press=new InputEvents.SelectPress();
        check(press.action(1)==-1);check(press.action(3)==-1);
        check(press.action(0)==1);check(press.action(0)==-1);check(press.action(2)==-1);
        check(press.action(5)==-1);check(press.action(6)==-1);check(press.action(1)==0);check(press.action(1)==-1);
        check(press.action(0)==1);check(press.action(3)==0);check(press.action(1)==-1);
        check(press.action(0)==1);check(press.action(1)==0);
        for(int hover:new int[]{9,7,10})check(press.action(hover)==-1);
        for(int request=-1;request<=6;request++){
            boolean valid=request>=1 && request<=3;
            check(AudioFocusPolicy.gain(request)==(valid?request:0));
            check(AudioFocusPolicy.reply(request,false)==3);
            check(AudioFocusPolicy.reply(request,true)==(!valid?3:request==1?1:2));
        }
        check(AudioFocusPolicy.change(1)==1);check(AudioFocusPolicy.change(-1)==3);
        check(AudioFocusPolicy.change(-2)==5);check(AudioFocusPolicy.change(-3)==4);check(AudioFocusPolicy.change(0)==3);
        reject(null,2);reject(new byte[0],2);reject(new byte[3],2);reject(new byte[65540],2);reject(new byte[4],3);
        byte[] original={1,2,3,4};byte[] copied=PcmFrames.copy(original,2);original[0]=9;check(copied[0]==1);
        for(int size=4;size<=400;size+=4){
            final byte[] expected=new byte[size];for(int i=0;i<size;i++)expected[i]=(byte)i;
            final int[] consumed={0};
            check(PcmFrames.write(new PcmFrames.Writer(){public int write(byte[] data,int offset,int count){
                check(offset==consumed[0]);int n=Math.min(4,count);for(int i=0;i<n;i++)check(data[offset+i]==expected[offset+i]);consumed[0]+=n;return n;
            }},PcmFrames.copy(expected,2)));
            check(consumed[0]==size);
        }
        final int[] calls={0};check(!PcmFrames.write(new PcmFrames.Writer(){public int write(byte[] d,int o,int n){calls[0]++;return 0;}},copied));check(calls[0]==1);
        check(!PcmFrames.write(new PcmFrames.Writer(){public int write(byte[] d,int o,int n){return -1;}},copied));
        check(!PcmFrames.write(new PcmFrames.Writer(){public int write(byte[] d,int o,int n){return n+1;}},copied));
        System.out.println("PASS: "+checks+" input/PCM checks");
    }
}
