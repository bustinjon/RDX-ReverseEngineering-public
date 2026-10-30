package com.rdx.fullscreen.clean;
import java.util.*;
import com.rdx.fullscreen.clean.TlsPumpResults.*;
/** New typed-progress fault script; complements, never replaces, FakeSecureBodyAdapter. No crypto. */
public final class FakeTlsPump {
 private final ArrayDeque<Accounting> steps=new ArrayDeque<Accounting>();private boolean terminal;public int calls;
 public FakeTlsPump(){}
 public void enqueue(Accounting r){if(r==null||steps.size()==32||terminal)throw new IllegalStateException("Bounded fake script");steps.addLast(r);}
 public Accounting pump(){if(terminal||steps.isEmpty())throw new IllegalStateException("No fake progress or terminal");calls++;Accounting r=steps.removeFirst();if(r.action==Action.FAILED||r.action==Action.PEER_CLOSED)terminal=true;return r;}
 public boolean terminal(){return terminal;}
}
