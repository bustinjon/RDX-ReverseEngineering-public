package com.google.android.projection.protocol;

import java.util.ArrayList;
import java.util.List;

/** Host fixture: real callback code, with only its private native endpoint replaced. */
public final class NavigationFocusTest {
    private static final List<Integer> replies=new ArrayList<Integer>();
    private static final List<String> events=new ArrayList<String>();
    private static int cases;
    public static void recordNative(int state) { replies.add(state); }
    private static void check(boolean condition,String message) {
        if(!condition)throw new AssertionError(message);
    }
    private static GalReceiver receiver() {
        return new GalReceiver(new GalReceiver.Listener(){
            public void event(String text){events.add(text);}
            public void discovery(){}
            public void byeBye(){}
        });
    }
    private static void request(GalReceiver receiver,int state,boolean valid) {
        int start=replies.size();events.clear();receiver.navigationFocusCallback(state);
        check(events.contains("NAVIGATION_PROTOCOL_REQUEST request="+state),"Missing request log");
        if(valid){
            check(replies.size()==start+1,"Valid request must reply exactly once");
            check(replies.get(start).intValue()==state,"Requested state not preserved");
            check(events.size()==2 && events.get(1).equals("NAVIGATION_PROTOCOL_REPLY state="+state),"Reply log mismatch");
        }else{
            check(replies.size()==start,"Invalid value crossed native boundary");
            check(events.size()==2 && events.get(1).equals("NAVIGATION_PROTOCOL_REJECTED request="+state),"Rejection log mismatch");
        }
        cases++;
    }
    public static void main(String[] args) {
        GalReceiver receiver=receiver();
        request(receiver,2,true);
        request(receiver,1,true);
        request(receiver,0,false);
        request(receiver,-1,false);
        request(receiver,3,false);
        request(receiver,Integer.MIN_VALUE,false);
        request(receiver,Integer.MAX_VALUE,false);
        request(receiver,2,true);
        request(receiver,2,true);
        request(receiver,1,true);
        check(replies.toString().equals("[2, 1, 2, 2, 1]"),"Sequence changed");
        System.out.println("PASS "+cases+" requests; native replies="+replies+"; logging and invalid rejection verified");
    }
}
