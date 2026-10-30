package com.rdx.fullscreen.m5permission;

import java.io.*;
import java.util.Arrays;
import java.util.Random;

/** Host simulator: synthetic identity/time/callback events; no Android classes. */
public final class PermissionTests {
    private static int checks, propertyChecks, maxRequests;
    private static final String NONCE = "test-nonce-0123456789abcdef";
    private static final PermissionMachine.Device NORMAL = device("/normal", 0x22d9, 0x2769, false);
    private static final PermissionMachine.Device NORMAL2 = device("/normal2", 0x22d9, 0x2765, false);
    private static final PermissionMachine.Device TARGET = device("/target", 0x18d1, 0x2d01, false);
    private static final PermissionMachine.Device TARGET2 = device("/target2", 0x18d1, 0x2d01, false);
    private static PermissionMachine.Device device(String path, int vid, int pid, boolean permission) {
        return new PermissionMachine.Device(path, vid, pid, permission);
    }
    private static void check(boolean result, String message) {
        checks++; if (!result) throw new AssertionError(message);
    }
    private static final class Rig implements PermissionMachine.Evidence, PermissionMachine.PermissionRequester {
        PermissionMachine core; long now; int calls, records; boolean failWrite, failRequest, inlineCallback;
        String lastLine;
        Rig() { core = new PermissionMachine(this, this); }
        void arm() { core.arm(now, 1700000000000L + now, NONCE); }
        void time(long value) { now = value; core.timeAdvanced(now, 1700000000000L + now); }
        void see(PermissionMachine.Device... devices) { core.snapshot(now, 1700000000000L + now, devices); }
        void callback(String nonce, PermissionMachine.Device d, boolean grant, boolean verified) {
            core.callback(now, 1700000000000L + now, nonce, d, grant, verified);
        }
        public void record(String line) throws IOException {
            records++; if (failWrite) throw new IOException("simulated disk failure"); lastLine = line;
        }
        public void request(PermissionMachine.Device d) throws Exception {
            calls++;
            if (failRequest) throw new IOException("simulated boundary failure");
            if (inlineCallback) callback(NONCE, d, true, true);
        }
    }
    private static void deterministic() throws Exception {
        Rig r = new Rig();
        check(r.core.state() == PermissionMachine.State.IDLE && r.records == 0 && r.calls == 0,
              "constructor has no side effects");
        r.arm(); r.time(300000); r.see(TARGET);
        check(r.core.state() == PermissionMachine.State.TIMED_OUT && r.calls == 0, "A no device timeout");
        r = new Rig(); r.arm(); r.see(NORMAL); r.time(299999); r.see(NORMAL2);
        check(r.calls == 0, "B normal identities never trigger");
        r = new Rig(); r.arm(); r.see(TARGET); r.see(TARGET);
        check(r.calls == 1 && r.core.requestCount() == 1, "C/D repeated target sighting");
        r = new Rig(); r.arm(); r.see(NORMAL); r.time(5000); r.see(TARGET);
        r.time(10000); r.see(); r.see(NORMAL2); r.time(15000); r.see(TARGET2);
        check(r.calls == 1 && r.core.state() == PermissionMachine.State.DETACHED, "E exact M4 sequence no second request");
        long[] times = { 0, 5000, 30000, 60000, 120000, 240000, 299999, 300000, 300001 };
        for (long time : times) {
            r = new Rig(); r.arm(); r.time(time); r.see(TARGET);
            check(r.calls == (time < 300000 ? 1 : 0), "timing=" + time);
        }
        r = new Rig(); r.arm(); r.time(300001); r.see(TARGET);
        check(r.calls == 0 && r.core.terminal(), "G post deadline never requests");
        r = new Rig(); r.arm(); r.see(TARGET); r.callback(NONCE, TARGET, true, true);
        check(r.core.state() == PermissionMachine.State.GRANTED, "H granted+verified");
        int events = r.records; r.callback(NONCE, TARGET, true, true); r.see(TARGET2); r.arm();
        check(r.calls == 1 && r.records == events && r.core.state() == PermissionMachine.State.GRANTED, "J terminal duplicates inert");
        r = new Rig(); r.arm(); r.see(TARGET); r.callback(NONCE, TARGET, false, false);
        check(r.core.state() == PermissionMachine.State.DENIED, "I denied+verified false");
        r = new Rig(); r.arm(); r.see(TARGET); r.callback(NONCE, TARGET, true, false);
        check(r.core.state() == PermissionMachine.State.CALLBACK_INCONSISTENT, "grant flag alone not success");
        r = new Rig(); r.arm(); r.see(TARGET); r.callback(NONCE, TARGET, false, true);
        check(r.core.state() == PermissionMachine.State.CALLBACK_INCONSISTENT, "denied flag inconsistent with map");
        r = new Rig(); r.arm(); r.see(TARGET); r.callback("wrong-nonce", TARGET, true, true);
        r.callback(null, TARGET, true, true); r.callback(NONCE, TARGET2, true, true);
        r.callback(NONCE, NORMAL, true, true); r.callback(NONCE, null, true, true);
        r.callback(NONCE, device("/target", 0x22d9, 0x2d01, true), true, true);
        r.callback(NONCE, device("/target", 0x18d1, 0x2765, true), true, true);
        check(r.core.state() == PermissionMachine.State.PERMISSION_REQUESTED && r.calls == 1,
              "K wrong nonce/path/VID/PID/null callback rejected");
        r.callback(NONCE, TARGET, true, true);
        check(r.core.state() == PermissionMachine.State.GRANTED, "valid callback after rejected callbacks");
        r = new Rig(); r.arm(); r.callback(NONCE, TARGET, true, true); r.see(TARGET);
        check(r.calls == 1 && r.core.state() == PermissionMachine.State.PERMISSION_REQUESTED, "early callback cannot grant");
        r = new Rig(); r.arm(); r.see(TARGET); r.see(); r.callback(NONCE, TARGET, true, true); r.see(TARGET2);
        check(r.calls == 1 && r.core.state() == PermissionMachine.State.DETACHED, "L detach terminal no retry");
        r = new Rig(); r.arm(); r.see(TARGET); r.time(300000); r.callback(NONCE, TARGET, true, true);
        check(r.core.state() == PermissionMachine.State.TIMED_OUT, "callback at deadline ignored");
        r = new Rig(); r.arm(); r.see(device("/target", 0x18d1, 0x2d01, true));
        check(r.calls == 0 && r.core.state() == PermissionMachine.State.ALREADY_AUTHORIZED, "already authorized no request");
        r = new Rig(); r.arm(); r.see(TARGET, TARGET2);
        check(r.calls == 0 && r.core.state() == PermissionMachine.State.ERROR, "ambiguous target stops");
        r = new Rig(); r.arm(); r.see(TARGET, TARGET);
        check(r.calls == 0 && r.core.state() == PermissionMachine.State.ERROR, "duplicate path malformed snapshot");
        r = new Rig(); r.arm(); r.see(new PermissionMachine.Device[33]);
        check(r.calls == 0 && r.core.state() == PermissionMachine.State.ERROR, "inventory max+1");
        r = new Rig(); r.arm(); r.failWrite = true; r.see(TARGET);
        check(r.calls == 0 && r.core.state() == PermissionMachine.State.ERROR, "disk failure before target stops");
        final int[] calls = {0};
        PermissionMachine diskFail = new PermissionMachine(new PermissionMachine.Evidence() {
            public void record(String line) throws IOException {
                if (line.contains("REQUEST_RESERVED")) throw new IOException("reservation sync failed");
            }
        }, new PermissionMachine.PermissionRequester() { public void request(PermissionMachine.Device d) { calls[0]++; } });
        diskFail.arm(0, 0, NONCE); diskFail.snapshot(1, 1, new PermissionMachine.Device[] { TARGET });
        check(calls[0] == 0 && diskFail.terminal(), "reservation must sync before request");
        r = new Rig(); r.arm(); r.failRequest = true; r.see(TARGET); r.see(TARGET2);
        check(r.calls == 1 && r.core.state() == PermissionMachine.State.ERROR, "boundary exception no retry");
        r = new Rig(); r.inlineCallback = true; r.arm(); r.see(TARGET); r.see(TARGET);
        check(r.calls == 1 && r.core.state() == PermissionMachine.State.GRANTED, "reentrant immediate callback safe");
        r = new Rig(); r.now = Long.MAX_VALUE - 10; r.arm(); r.time(Long.MAX_VALUE); r.see(TARGET);
        check(r.calls == 1, "no deadline-addition overflow");
        r = new Rig(); r.now = 100; r.arm(); r.time(99); r.see(TARGET);
        check(r.calls == 0 && r.core.state() == PermissionMachine.State.ERROR, "clock reversal closed");
        r = new Rig(); r.arm(); r.core.stop(2, 2); r.see(TARGET);
        check(r.calls == 0 && r.core.state() == PermissionMachine.State.STOPPED, "Service stop inert");
        r = new Rig(); r.arm(); r.see(TARGET); r.failWrite = true; r.callback(NONCE, TARGET, true, true); r.see(TARGET2);
        check(r.calls == 1 && r.core.state() == PermissionMachine.State.ERROR, "callback persistence failure cannot retry");
        r = new Rig(); r.arm(); r.time(1); r.see(device("/name\nwith\ttabs", 1, 1, false));
        check(r.lastLine.indexOf('\n') < 0 && r.lastLine.contains("\\n"), "device name escapes preserve journal framing");
        System.out.println("TIMING_CASES=9 EXPLICIT_SCENARIOS=A-M PASS");
    }
    private static void persistence(File root) throws Exception {
        File notCreated = new File(root, "constructor-must-not-create"); new PrivateJournal(notCreated);
        check(!notCreated.exists(), "journal constructor side effect free");
        File folder = new File(root, "journal-tests"); if (!folder.mkdir()) throw new IOException("Fresh test dir required");
        PrivateJournal store = new PrivateJournal(folder);
        PrivateJournal.Session saved = store.create("restart-proof");
        Rig boundary = new Rig();
        PermissionMachine machine = new PermissionMachine(saved, boundary);
        machine.arm(0, 0, NONCE); machine.snapshot(1, 1, new PermissionMachine.Device[] { TARGET });
        saved.close();
        byte[] original = new PrivateJournal(folder).read("restart-proof");
        check(new String(original, "UTF-8").contains("REQUEST_RESERVED"), "M durable reservation readable after new store");
        try { new PrivateJournal(folder).create("restart-proof"); throw new AssertionError("replay allowed"); }
        catch (IOException expected) { check(boundary.calls == 1, "M same run cannot replay"); }
        check(Arrays.equals(original, store.read("restart-proof")), "read never clears evidence");
        PrivateJournal.Session result = store.create("granted-result");
        PermissionMachine granted = new PermissionMachine(result, new PermissionMachine.PermissionRequester() {
            public void request(PermissionMachine.Device d) { /* fake host boundary */ }
        });
        granted.arm(0, 1000, NONCE); granted.snapshot(1, 1001, new PermissionMachine.Device[] { TARGET });
        granted.callback(2, 1002, NONCE, TARGET, true, true); result.close();
        check(new String(new PrivateJournal(folder).read("granted-result"), "UTF-8").contains("state=GRANTED event=RESULT_RECEIVED"),
              "terminal granted result readable after store/process reconstruction");
        PrivateJournal.Session armed = store.create("crashed-before-target");
        PermissionMachine waiting = new PermissionMachine(armed, boundary); waiting.arm(0, 0, NONCE); armed.close();
        try { new PrivateJournal(folder).create("crashed-before-target"); throw new AssertionError("armed crash replay allowed"); }
        catch (IOException expected) { check(true, "same run blocked even before first permission attempt"); }
        for (String bad : new String[] { "../escape", "", "x/y", "x\\y", null }) {
            try { store.create(bad); throw new AssertionError("bad run accepted"); }
            catch (IllegalArgumentException expected) { check(true, "run id validation"); }
        }
        File bounds = new File(root, "journal-bounds"); bounds.mkdir();
        PrivateJournal bounded = new PrivateJournal(bounds);
        PrivateJournal.Session bytes = bounded.create("byte-bound");
        // Creation header consumes bytes too: fill exactly to the configured total.
        int used = "SESSION_CREATED run=byte-bound\n".getBytes("UTF-8").length;
        while (used < PrivateJournal.MAX_BYTES) {
            int n = Math.min(PrivateJournal.MAX_LINE_BYTES, PrivateJournal.MAX_BYTES - used);
            char[] chars = new char[n - 1]; Arrays.fill(chars, 'x'); bytes.record(new String(chars)); used += n;
        }
        try { bytes.record(""); throw new AssertionError("byte cap ignored"); }
        catch (IOException expected) { check(true, "max bytes enforced before write"); }
        bytes.close(); check(bounded.read("byte-bound").length == PrivateJournal.MAX_BYTES, "exact max bytes retained");
        PrivateJournal.Session line = bounded.create("line-bound");
        char[] tooLong = new char[PrivateJournal.MAX_LINE_BYTES]; Arrays.fill(tooLong, 'x');
        try { line.record(new String(tooLong)); throw new AssertionError("line cap ignored"); }
        catch (IOException expected) { check(true, "max line+1 rejected"); } finally { line.close(); }
        for (int i = 2; i < PrivateJournal.MAX_RUNS; i++) bounded.create("run-" + i).close();
        check(bounded.list().length == PrivateJournal.MAX_RUNS, "exact max runs retained");
        try { bounded.create("run-overflow"); throw new AssertionError("run cap ignored"); }
        catch (IOException expected) { check(true, "max runs+1 refuses no deletion"); }
        check(store.list().length == 3, "unrelated results never removed");
        File corrupt = new File(root, "journal-corrupt"); corrupt.mkdir();
        FileOutputStream big = new FileOutputStream(new File(corrupt, "m5-big.txt"));
        big.write(new byte[PrivateJournal.MAX_BYTES + 1]); big.close();
        try { new PrivateJournal(corrupt).read("big"); throw new AssertionError("oversize read accepted"); }
        catch (IOException expected) { check(true, "oversized stored evidence rejected before read allocation"); }
    }
    private static void randomized() {
        final long seed = 0x4d35524458323032L;
        Random random = new Random(seed); final int iterations = 20000, steps = 120;
        for (int iteration = 0; iteration < iterations; iteration++) {
            Rig r = new Rig(); r.arm();
            for (int step = 0; step < steps; step++) {
                switch (random.nextInt(12)) {
                    case 0: r.see(NORMAL); break;
                    case 1: r.see(TARGET); break;
                    case 2: r.see(TARGET2); break;
                    case 3: r.see(); break;
                    case 4: r.see(NORMAL2); break;
                    case 5: r.callback(NONCE, r.core.selected(), true, true); break;
                    case 6: r.callback(NONCE, r.core.selected(), false, false); break;
                    case 7: r.callback("wrong", TARGET, true, true); break;
                    case 8: r.time(r.now + random.nextInt(30001)); break;
                    case 9: r.see(NORMAL, TARGET); break;
                    case 10: r.see(TARGET, TARGET2); break;
                    default: r.callback(NONCE, TARGET2, random.nextBoolean(), random.nextBoolean());
                }
                propertyChecks++;
                maxRequests = Math.max(maxRequests, r.calls);
                if (r.calls > 1 || r.core.requestCount() > 1 || r.calls != r.core.requestCount())
                    throw new AssertionError("seed=" + seed + " iteration=" + iteration + " step=" + step);
            }
        }
        System.out.println("PROPERTY seed=" + seed + " hex=0x4d35524458323032 iterations=" + iterations +
            " stepsPerIteration=" + steps + " assertions=" + propertyChecks + " maxRequests=" + maxRequests);
    }
    public static void main(String[] args) throws Exception {
        deterministic(); persistence(new File(args[0])); randomized();
        System.out.println("RESULT PASS deterministicChecks=" + checks + " propertyChecks=" + propertyChecks);
    }
}
