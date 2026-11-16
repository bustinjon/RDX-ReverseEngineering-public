**The core claim fails: the new backstop can tear down a healthy, actively rendering session.** ACK ownership remains sound at the Java control-flow level, but the 12-second liveness and handler-backlog guarantees also need qualification.

**1. Files inspected**

Paths below are relative to the workspace. Let `P` mean:

`analysis/test-prep/todo-tests-20261103/builds/T360-bundle/`

Evidence aliases:

| Alias | File |
|---|---|
| S | `P/source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/AaSessionService.java` |
| D | `P/source/analysis/parallel-aa-receiver/src/com/rdx/fullscreen/projection/VideoDecoder.java` |
| V | `P/source/analysis/parallel-aa-receiver/src/com/google/android/projection/protocol/VideoSink.java` |
| R | `P/source/analysis/parallel-aa-receiver/usb-helper/source/com/google/android/projection/protocol/GalReceiver.java` |
| I | `P/source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/InputEvents.java` |
| B | `P/BundleTests.java` |
| L | `analysis/installer-20261112/Hackura-Installer/car-logs/headunit-logs-20261114-181708/hackura-20261114-181617.txt` |
| C | Same directory, `hackura-20261114-165532-auto-stall-3504ms.txt` |

Also inspected: `PROJECT-RULES.md` first, then `AGENTS.md`; round-one review and reconciliation; T350’s service for comparison; canonical `UsbBulkTransport.java`; T360 manifest and relevant saved test/build-report entries.

**2. Files changed**

None.

**3. Commands run**

Read-only commands:

- `Get-Content`, numbered excerpts, `rg -n`, `rg --files`, and `Test-Path`.
- `git diff --no-index --unified=3` and `--numstat` between T350/T360 services.
- `Get-FileHash -Algorithm SHA256`, twice for S, D, and B.
- An in-memory PowerShell arithmetic demonstration of the timer interleaving.

Diff exit status `1` indicated differences. One arithmetic-output attempt failed because constrained PowerShell disallowed `PSCustomObject`; the scalar-output retry succeeded. Searches with no matches returned `1`.

**4. Tests run and results**

No application tests, builds, or device operations executed.

The arithmetic demonstration returned:

[Code block omitted; consult project-authored source.]

This demonstrates the faulty arithmetic for an allowed interleaving; it is not an Android concurrency reproduction.

Existing saved output says `PASS 285 bundle checks` (`P/host-test-output.txt:10`). The added checks inspect constant bounds, not service concurrency or watchdog execution (`B:277–282`).

**5. Findings**

**F1 — P1: A render reset can itself cause an immediate false teardown.**

`queueFullSince` is read separately in the zero check and elapsed-time comparison. This interleaving is possible:

[Code block omitted; consult project-authored source.]

The full-queue episode lasted one millisecond, and a frame just rendered. Nevertheless, the service aborts because the zero sentinel becomes the subtraction operand. This also works if the worker clears a timestamp just assigned at line 1576.

`volatile` does not make these separate accesses one atomic operation. This is a false teardown, not merely a slightly early or late detection of a true wedge.

**F2 — P2: The backstop does not provide an unconditional 12-second deadline.**

The deadline is evaluated only during rejected-frame callbacks. Consider a queue that remains full with a permanently blocked worker, followed by no further video callbacks while GAL ping/audio traffic continues. Nothing evaluates the deadline; Wi-Fi’s stuck-screen watchdog is disabled, and incoming traffic can prevent the socket timeout.

Under **continued rejected callbacks**, no accepts/renders, returning native ACK calls, and progressing shutdown, the timer reaches its threshold. Without those assumptions, teardown within approximately 12 seconds is unproven.

**F3 — P2: F2 hardening limits posting rate, not pending-task count.**

For a serialized frame callback, the new gate limits this rejection branch to approximately one `pictureLost()` call per second. It does not coalesce outstanding tasks.

If the main handler is blocked while the decoder continues accepting/rendering intermittently, those resets prevent the wedge timeout, but rejection bursts can still add one pending recovery task each second indefinitely. The decoder-event route also calls `pictureLost()` outside this gate.

The frame-rate posting amplification is addressed. A strict claim that the handler cannot accumulate recovery tasks is still false.

**F4 — P2: The logs do not establish that 12 seconds safely covers the recorded recoverable stall.**

The failure log establishes **time to saturation**, not **time to recovery**. It tears down immediately on queue-full, so recovery without teardown was never observed in that session.

The clean log supplies no recorded queue-full trigger. Its startup timing therefore cannot establish the safe upper bound for a continuously full decoder queue.

**6. Primary evidence for each finding and requested checks**

**F1 — false trip and volatile race**

- `S:1576`: zero-check and possible timestamp assignment.
- `S:1577`: a separate volatile read supplies the subtraction operand.
- `S:1583`: teardown follows.
- `S:1668`: decoder worker independently writes zero.
- `D:85`: successful `releaseOutputBuffer(index,true)` calls `listener.rendered()`.

**Reset coverage and hidden-session behavior**

- Every accepted `d.frame(...)` clears the timestamp at `S:1564`, including startup frames accepted before any output.
- Every normal decoder output-release path calls `rendered()` at `D:85`; service reset is unconditional at `S:1668`.
- Thus, absent races, frames accepted normally cannot leave an old nonzero timestamp behind.
- Focus restoration resets `lastFrameMs`, not `queueFullSince` (`S:1612`, `S:1637`, `S:1645–1646`).
- With no callbacks, the timeout is not evaluated, but uptime still advances. A nonzero timestamp can therefore age across a pause. A subsequent accept/render clears it; a subsequent rejection can immediately expire it. Whether a healthy decoder retains a full queue throughout such a pause is **UNKNOWN**.

The “rendered” signal proves the decoder submitted output through this Java path; independent confirmation that pixels appeared is **UNKNOWN**.

**F2 — callback-dependent deadline**

- Timer initialization and expiry occur inside rejection handling only: `S:1574–1583`.
- `I:106–112` itself qualifies the mechanism as operating while video frames are still delivered.
- TCP timeout is attached to individual socket reads: `S:80–86`.
- Wi-Fi skips `stuckWatch` recovery: `S:1689–1691`.
- GAL ping responses are present during the recorded video failure (`L:263`, `L:268–270`).

Whether the phone actually produces the proposed full-queue/video-silent state is **UNKNOWN**; the Java watchdog does not exclude it or independently time it out.

**F3 — pending handler tasks**

- Gate and timestamp update: `S:1584–1590`.
- Each permitted call allocates/posts another Runnable: `S:1505–1507`.
- The five-second recovery throttle runs only after that task executes: `S:1508–1512`.
- Independent decoder-event calls: `S:1428–1430`, originating from `D:103,108`.
- Accepted frames and rendered output can repeatedly reset the wedge timer: `S:1564,1668`.

**F4 — recorded timings**

- First decoder drop: `L:258`, **18:07:24.217**.
- Queue-full: `L:272`, **18:07:27.839** — **3.622 seconds later**.
- Shutdown begins: `L:274`.
- Ignoring F1 and subsequent resets, a timer first armed at queue-full would expire no earlier than **18:07:39.839**. The log does not establish recovery before that point.
- Clean comparator: protocol starts at **16:55:09.353** (`C:93`); first frame renders at **16:55:29.516** (`C:255`), **20.163 seconds later**. No queue-full event was found in that file. Total startup duration is not the quantity this backstop measures.

**Native-thread `abortIo()` safety — UNKNOWN, with a concrete limitation**

- `abortIo()` closes transport before its atomic gate, posts shutdown, then calls `receiver.prepare()` (`S:1413–1422`).
- `prepare()` holds its Java monitor throughout `nativePrepareShutdown()` (`R:80`).
- Posted shutdown calls that same synchronized method before reaching joins or overlay removal (`S:1718`, `S:1760–1763`).

Consequently, posting shutdown first does **not** guarantee progress if callback-thread `prepare()` hangs while holding its monitor: the main handler can block entering `prepare()` too. Actual native lock reentrancy/deadlock behavior is **UNKNOWN** from these Java facades.

The TCP close wrapper takes no receiver monitor (`S:89`). Canonical USB close is synchronized and calls platform release/close (`UsbBulkTransport.java:128–130`); underlying platform lock behavior remains **UNKNOWN**.

**ACK ownership and throttle placement — pass, with qualifications**

- Accepted packets carry their ACK Runnable: `S:1559–1563`.
- Rejected packets receive the explicit ACK at `S:1574`, **before** both timeout handling and the one-second gate.
- Rejection uses `queue.offer(...)`, so rejected packets do not enter the decoder queue (`D:32`).
- Dequeued packets invoke their ACK in `finally`; remaining queued packets are ACKed during worker exit (`D:111,117`).
- Thus, the accept/reject restructure does not assign both ACK paths to one packet.

This establishes one Java ACK attempt per normally processed frame under an active sink and returning callbacks. It does not guarantee eventual ACK delivery for accepted packets behind a permanently blocked worker. Non-running callbacks return without ACK (`S:1552`), and `V:41` sends native ACKs only while `created`.

**Double teardown and spin**

The service diff adds no retry/spin loop. `aborting` gates shutdown posting (`S:1415`), but existing shutdown is not permanently idempotent: it resets `stopping` (`S:1771`), and surface loss calls shutdown directly (`S:674–676`). The historical log already shows a second shutdown after surface destruction (`L:290–295`). This is pre-existing, not a demonstrated T360 regression.

**7. Assumptions**

- Findings concern the supplied T360 bundle source.
- The one-second posting-rate argument assumes serialized frame callbacks; native serialization is **UNKNOWN**.
- ACK ownership assumes normal allocation/copying and returning callbacks.
- F2/F3 are source-permitted counterexamples, not observed runtime reproductions.

**8. Unresolved uncertainties**

Actual transient recovery, native locking and ACK delivery, callback serialization, handler responsiveness, and a safe maximum decoder-stall duration remain **UNKNOWN**. The 285 saved checks do not settle these properties.

**9. Exact diff summary**

No review-generated diff.

The read-only service comparison against T350 reported **39 additions, 3 deletions**. Changes comprise the counters/timestamps, accept-path reset, rejection recovery/backstop/gate, and render reset.

**10. Preservation checks performed**

Initial and final SHA-256 readings matched for all three checked files:

[Code block omitted; consult project-authored source.]

S matches `P/build-report.json:63`. No files were written, builds performed, devices accessed, key material read, agents spawned, or prohibited Git mutations run. Frozen-artifact hashes were not reverified.