import com.rdx.fullscreen.usbhelper.InputEvents;
import com.google.android.projection.protocol.PcmFrames;
import com.google.android.projection.protocol.AudioFocusPolicy;
public final class InputPcmTest {
    private static int checks;
    private static void check(boolean ok){checks++;if(!ok)throw new AssertionError("Check "+checks);}
    private static void reject(byte[] data,int channels){boolean rejected=false;try{PcmFrames.copy(data,channels);}catch(IllegalArgumentException e){rejected=true;}check(rejected);}
    public static void main(String[] args){
        check(InputEvents.hoverAction(9)==0);check(InputEvents.hoverAction(7)==2);check(InputEvents.hoverAction(10)==1);check(InputEvents.hoverAction(8)==-1);
        for(int key=0;key<200;key++)check(InputEvents.key(key)==(key==4 || key==23 || key==66 || key==87 || key==88 || key==92 || key==93 || key==122 || key==123 || key==146 || key==148 || key==150 || key==152));
        check(InputEvents.keyCode(66)==23);check(InputEvents.keyCode(23)==23);check(InputEvents.keyCode(4)==4);
        int[] rawSwipes={146,148,150,152};int[] mappedSwipes={93,122,123,92};
        for(int i=0;i<rawSwipes.length;i++){
            check(InputEvents.key(rawSwipes[i]));check(InputEvents.keyCode(rawSwipes[i])==mappedSwipes[i]);
            check(InputEvents.keyCode(mappedSwipes[i])==mappedSwipes[i]);
        }
        // Exercise the same consume/send helper used by the overlay, not a fabricated raw+fallback list.
        final int[] sends={0};final int[] sentCode={-1};final boolean[] sentDown={false};
        InputEvents.KeyConsumer consumer=new InputEvents.KeyConsumer(){public void send(int code,boolean down){sends[0]++;sentCode[0]=code;sentDown[0]=down;}};
        for(int i=0;i<rawSwipes.length;i++){
            int before=sends[0];check(InputEvents.dispatchKey(rawSwipes[i],0,consumer));
            check(sends[0]==before+1);check(sentCode[0]==mappedSwipes[i]);check(sentDown[0]);
            check(InputEvents.dispatchKey(rawSwipes[i],1,consumer));
            check(sends[0]==before+2);check(sentCode[0]==mappedSwipes[i]);check(!sentDown[0]);
        }
        int beforeInvalid=sends[0];check(!InputEvents.dispatchKey(146,2,consumer));
        check(!InputEvents.dispatchKey(38,0,consumer));check(!InputEvents.dispatchKey(146,0,null));check(sends[0]==beforeInvalid);
        for(int pageKey:new int[]{92,93,122,123})check(InputEvents.dispatchKey(pageKey,0,consumer));
        int[] registered=InputEvents.supportedKeyCodes();check(registered.length==8);
        for(int raw=0;raw<200;raw++)if(InputEvents.key(raw)){
            boolean found=false;for(int supported:registered)if(supported==InputEvents.keyCode(raw))found=true;
            check(found);
        }
        for(int i=0;i<registered.length;i++){
            check(InputEvents.keyCode(registered[i])==registered[i]);
            for(int j=i+1;j<registered.length;j++)check(registered[i]!=registered[j]);
        }
        registered[0]=-1;check(InputEvents.supportedKeyCodes()[0]==4);
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
