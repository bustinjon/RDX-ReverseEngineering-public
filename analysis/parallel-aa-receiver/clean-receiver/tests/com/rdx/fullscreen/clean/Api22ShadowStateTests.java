package com.rdx.fullscreen.clean;
import java.util.*;
/** STATIC PROVIDER SHADOW MODEL. Does not execute Conscrypt/TLS/native code.
 * Native residual states are explicit hypothetical inputs, never claimed measured behavior.
 */
public final class Api22ShadowStateTests {
 static final long SEED=0x2251C105E261025L;static long properties;static int checks,riskOffsets,sourceDifferences;
 static void check(boolean b,String s){checks++;if(!b)throw new AssertionError(s);}static void prop(boolean b,String s){properties++;if(!b)throw new AssertionError(s);}
 enum State {NEW,HANDSHAKING,VERIFY_PENDING,APPLICATION,LOCAL_CLOSING,PEER_CLOSED,CLOSED,FAILED}
 static final class Model {
  State state=State.NEW;int epoch,queuedCipher,queuedPlain,pendingOut,drains;long context=-1;boolean outputLost;
  boolean terminal(){return state==State.CLOSED||state==State.FAILED;}
  void fail(){state=State.FAILED;queuedCipher=queuedPlain=pendingOut=0;context=-1;}
  void fresh(){epoch++;state=State.NEW;queuedCipher=queuedPlain=pendingOut=drains=0;context=-1;outputLost=false;}
  void event(int type,int value){
   if(type==9){fresh();return;}if(terminal())return;
   if(type==0){if(state==State.NEW)state=State.HANDSHAKING;return;}
   if(type==1){if(state==State.HANDSHAKING){pendingOut=Math.min(64,pendingOut+value);if(value==0)state=State.VERIFY_PENDING;}return;}
   if(type==2){if(state==State.VERIFY_PENDING&&pendingOut==0)state=value==0?State.FAILED:State.APPLICATION;return;}
   if(type==3){if(state!=State.APPLICATION)return;long id=value%3;if(context!=-1&&context!=id){fail();return;}context=id;queuedCipher=Math.min(64,queuedCipher+1+value);return;}
   if(type==4){if(state!=State.APPLICATION)return;int used=Math.min(queuedCipher,value),produced=Math.min(64-queuedPlain,value);queuedCipher-=used;queuedPlain+=produced;/* explicit hypothetical native residue */return;}
   if(type==5){pendingOut-=Math.min(pendingOut,value);queuedPlain-=Math.min(queuedPlain,value);if(++drains>64){fail();return;}if(queuedCipher==0&&queuedPlain==0&&pendingOut==0)context=-1;return;}
   if(type==6){state=State.LOCAL_CLOSING;pendingOut=Math.min(64,pendingOut+1);/* target source can stage output then make it inaccessible */outputLost=true;return;}
   if(type==7){state=State.PEER_CLOSED;return;}
   if(type==8){fail();return;}
   if(type==10){if(state==State.PEER_CLOSED&&pendingOut==0){state=State.CLOSED;queuedCipher=queuedPlain=0;context=-1;}return;}
  }
 }
 static int targetDestination(int[] remaining,int offset,int length){for(int i=offset;i<length;i++)if(remaining[i]>0)return i;return -1;}
 static int specifiedDestination(int[] remaining,int offset,int length){for(int i=offset;i<offset+length;i++)if(remaining[i]>0)return i;return -1;}
 static int targetSourceSum(int[] sizes,int offset,int length){int n=0;for(int s:sizes)n+=s;return n;}
 static int specifiedSourceSum(int[] sizes,int offset,int length){int n=0;for(int i=offset;i<offset+length;i++)n+=sizes[i];return n;}
 static void examples(){
  check(targetDestination(new int[]{0,2},1,1)==-1&&specifiedDestination(new int[]{0,2},1,1)==1,"Nonzero destination offset omission");
  check(targetSourceSum(new int[]{5,2,9},1,1)==16&&specifiedSourceSum(new int[]{5,2,9},1,1)==2,"Nonzero source offset can include out-of-range buffers");
  check(targetDestination(new int[]{2},0,1)==0&&targetSourceSum(new int[]{2},0,1)==2,"Production single-buffer path avoids array offset issue");
  // Two latent native states can have identical visible consumed/produced/remaining values NOW.
  int[] visibleEmpty={0,0,0};int[] latentPendingButInvisible={0,0,0};check(Arrays.equals(visibleEmpty,latentPendingButInvisible),"Visible zero is not a hidden-residue proof");
  Model m=new Model();m.state=State.APPLICATION;m.event(3,1);m.event(4,1);m.event(3,2);check(m.state==State.FAILED&&m.context==-1,"Cross-frame attribution ambiguity fails closed");
  m.fresh();check(m.state==State.NEW&&m.queuedPlain==0&&m.queuedCipher==0&&m.pendingOut==0,"Explicit fresh epoch clears all residue");
  m.state=State.APPLICATION;m.event(6,0);check(m.state==State.LOCAL_CLOSING&&m.pendingOut>0&&m.outputLost,"Close staging model reports inaccessible output rather than claiming delivered");
 }
 public static void main(String[] args){examples();Random r=new Random(SEED);
  for(int sequence=0;sequence<25000;sequence++){
   Model m=new Model();for(int step=0;step<12;step++){State old=m.state;int oldEpoch=m.epoch,event=r.nextInt(11);m.event(event,r.nextInt(8));
    prop(m.queuedCipher>=0&&m.queuedCipher<=64&&m.queuedPlain>=0&&m.queuedPlain<=64&&m.pendingOut>=0&&m.pendingOut<=64,"Bounded latent buffers seed/index="+sequence+"/"+step);
    prop(!((old==State.CLOSED||old==State.FAILED)&&event!=9)||m.state==old,"Terminal cannot revive without explicit fresh event");
    if(event==9)prop(m.epoch==oldEpoch+1&&m.state==State.NEW&&m.context==-1&&m.queuedPlain==0&&m.queuedCipher==0&&m.pendingOut==0,"Reset clears entire frame epoch");
    if(m.terminal())prop(m.context==-1&&m.queuedPlain==0&&m.queuedCipher==0,"Terminal has no attributed media residue");
   }
   int count=1+r.nextInt(5);int[] sizes=new int[count];for(int i=0;i<count;i++)sizes[i]=r.nextInt(9);int offset=r.nextInt(count),length=1+r.nextInt(count-offset);
   int actual=targetDestination(sizes,offset,length),expected=specifiedDestination(sizes,offset,length);if(actual!=expected)riskOffsets++;
   if(targetSourceSum(sizes,offset,length)!=specifiedSourceSum(sizes,offset,length))sourceDifferences++;
   prop(actual<0||actual>=offset&&actual<offset+length,"Target selection never invented destination");
   prop(targetDestination(new int[]{1},0,1)==specifiedDestination(new int[]{1},0,1),"Single destination differential agreement");
   prop(targetSourceSum(new int[]{1},0,1)==specifiedSourceSum(new int[]{1},0,1),"Single source differential agreement");
  }
  check(riskOffsets>0&&sourceDifferences>0,"Nonzero offset risks actually exercised");
  System.out.println("RESULT PASS deterministic="+checks+" propertyChecks="+properties+" shadowSequences=25000 seed="+SEED+" destinationDifferences="+riskOffsets+" sourceDifferences="+sourceDifferences+" api22RuntimeCases=0; STATIC PROVIDER MODEL ONLY; expected differences are risks, NOT fixed or runtime qualified");
 }
}
