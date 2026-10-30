package com.rdx.fullscreen.m5permission;

import java.io.IOException;
import java.util.LinkedHashMap;
import java.util.Map;

/** Pure, single-thread-confined model. No Android, clocks, threads or I/O in constructors. */
public final class PermissionMachine {
    public static final long WINDOW_MS = 300000L;
    public static final int VID = 0x18d1, PID = 0x2d01, MAX_DEVICES = 32;
    public enum State { IDLE, ARMED, WAITING_FOR_TARGET, TARGET_SEEN,
        PERMISSION_REQUESTED, GRANTED, DENIED, ALREADY_AUTHORIZED,
        CALLBACK_INCONSISTENT, DETACHED, TIMED_OUT, ERROR, STOPPED }
    public interface Evidence { void record(String line) throws IOException; }
    public interface PermissionRequester { void request(Device device) throws Exception; }
    public static final class Device {
        public final String path;
        public final int vid, pid;
        public final boolean permission;
        public Device(String path, int vid, int pid, boolean permission) {
            if (path == null || path.length() == 0 || path.length() > 256 ||
                vid < 0 || vid > 65535 || pid < 0 || pid > 65535)
                throw new IllegalArgumentException("Invalid device identity");
            this.path = path; this.vid = vid; this.pid = pid; this.permission = permission;
        }
        public boolean same(Device other) {
            return other != null && path.equals(other.path) && vid == other.vid && pid == other.pid;
        }
        public boolean target() { return vid == VID && pid == PID; }
        public String describe() {
            return "vid=" + vid + " pid=" + pid + " path=" + escape(path) + " hasPermission=" + permission;
        }
    }
    private final Evidence evidence;
    private final PermissionRequester requester;
    private final Map<String, Device> previous = new LinkedHashMap<String, Device>();
    private State state = State.IDLE;
    private Device selected;
    private String nonce;
    private long start, last, wall, heartbeat;
    private boolean requestReserved;
    private int requestCount;
    public PermissionMachine(Evidence evidence, PermissionRequester requester) {
        if (evidence == null || requester == null) throw new IllegalArgumentException("Missing boundary");
        this.evidence = evidence; this.requester = requester;
    }
    public State state() { return state; }
    public Device selected() { return selected; }
    public int requestCount() { return requestCount; }
    public boolean terminal() {
        return state != State.IDLE && state != State.ARMED && state != State.WAITING_FOR_TARGET &&
               state != State.TARGET_SEEN && state != State.PERMISSION_REQUESTED;
    }
    public long remaining(long now) {
        if (state == State.IDLE || terminal() || now < start) return 0;
        long age = now - start;
        return age >= WINDOW_MS ? 0 : WINDOW_MS - age;
    }
    public void arm(long now, long wallTime, String requestNonce) {
        if (state != State.IDLE) return;
        if (now < 0 || requestNonce == null || requestNonce.length() < 16 || requestNonce.length() > 128)
            throw new IllegalArgumentException("Invalid arm parameters");
        start = last = heartbeat = now; wall = wallTime; nonce = requestNonce;
        state = State.ARMED;
        if (!emit("ARMED", "windowMs=" + WINDOW_MS)) return;
        state = State.WAITING_FOR_TARGET; emit("WAITING_FOR_TARGET", "");
    }
    private boolean clock(long now, long wallTime) {
        if (state == State.IDLE || terminal()) return false;
        wall = wallTime;
        if (now < last) { state = State.ERROR; emit("CLOCK_ERROR", "monotonic clock reversed"); return false; }
        last = now;
        if (now - start >= WINDOW_MS) { state = State.TIMED_OUT; emit("TIMED_OUT", "no retry"); return false; }
        return true;
    }
    public void timeAdvanced(long now, long wallTime) {
        if (clock(now, wallTime) && now - heartbeat >= 10000) {
            heartbeat = now; emit("HEARTBEAT", "remainingMs=" + remaining(now));
        }
    }
    public void snapshot(long now, long wallTime, Device[] devices) {
        if (!clock(now, wallTime)) return;
        if (devices == null || devices.length > MAX_DEVICES) { fail("inventory bound exceeded"); return; }
        Map<String, Device> current = new LinkedHashMap<String, Device>();
        Device match = null; int matches = 0;
        for (Device device : devices) {
            if (device == null || current.put(device.path, device) != null) { fail("duplicate/null identity"); return; }
            Device old = previous.get(device.path);
            if (old == null || !old.same(device) || old.permission != device.permission)
                if (!emit("DEVICE_APPEARED_OR_CHANGED", device.describe())) return;
            if (device.target()) { match = device; matches++; }
        }
        for (Device old : previous.values()) if (!current.containsKey(old.path))
            if (!emit("DEVICE_DISAPPEARED", old.describe())) return;
        previous.clear(); previous.putAll(current);
        if (state == State.PERMISSION_REQUESTED) {
            Device stillHere = current.get(selected.path);
            if (!selected.same(stillHere)) { state = State.DETACHED; emit("DETACHED_AFTER_REQUEST", "no re-selection or retry"); }
            return;
        }
        if (matches > 1) { fail("ambiguous target"); return; }
        if (match == null) return;
        selected = match; state = State.TARGET_SEEN;
        if (!emit("TARGET_SEEN", "pinned identity")) return;
        if (selected.permission) { state = State.ALREADY_AUTHORIZED; emit("ALREADY_AUTHORIZED", "zero requests"); return; }
        if (requestReserved) { fail("request latch already reserved"); return; }
        // Commit the one-shot latch durably BEFORE crossing the Android permission boundary.
        requestReserved = true; state = State.PERMISSION_REQUESTED;
        if (!emit("REQUEST_RESERVED", "not proof of framework invocation")) return;
        requestCount++;
        try { requester.request(selected); }
        catch (Exception error) { fail("permission boundary exception=" + error.toString()); }
    }
    public void callback(long now, long wallTime, String returnedNonce, Device returned,
                         boolean granted, boolean currentlyVerified) {
        if (!clock(now, wallTime)) return;
        String detail = "callbackDevice=" + (returned == null ? "null" : returned.describe()) +
            " callbackGranted=" + granted + " verifiedPermission=" + currentlyVerified;
        if (state != State.PERMISSION_REQUESTED || !nonce.equals(returnedNonce) || !selected.same(returned)) {
            emit("CALLBACK_REJECTED", detail); return;
        }
        state = granted && currentlyVerified ? State.GRANTED :
            (!granted && !currentlyVerified ? State.DENIED : State.CALLBACK_INCONSISTENT);
        emit("RESULT_RECEIVED", detail);
    }
    public void fail(String reason) {
        if (terminal()) return;
        state = State.ERROR; emit("ERROR", reason);
    }
    public void stop(long now, long wallTime) {
        if (terminal() || state == State.IDLE) return;
        if (!clock(now, wallTime)) return;
        state = State.STOPPED; emit("STOPPED", "explicit Service destruction; no retry");
    }
    private boolean emit(String event, String detail) {
        String line = "wallMs=" + wall + " monoMs=" + last + " state=" + state + " event=" + event +
            " requestReserved=" + requestReserved + " boundaryCalls=" + requestCount + " " +
            (selected == null ? "selected=none" : selected.describe()) + " detail=" + escape(detail);
        try { evidence.record(line); return true; }
        catch (IOException error) { state = State.ERROR; return false; } // Fail closed; no further boundary crossing.
    }
    private static String escape(String value) {
        return value.replace("\\", "\\\\").replace("\r", "\\r").replace("\n", "\\n").replace("\t", "\\t");
    }
}
