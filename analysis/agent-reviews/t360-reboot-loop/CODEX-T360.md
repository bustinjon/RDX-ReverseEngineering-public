**The broad claim does not hold.** T360 removes the observed queue-full teardown trigger, and its rejected-packet ACK ownership is sound in Java. However, it can preserve a permanently frozen decoder, does not bound recovery-handler backlog, and does not eliminate the existing audio-retention path. Actual start-up recovery remains **UNKNOWN**.

1. **Files inspected**

   Paths below are relative to `C:/Users/REDACTED\Desktop\RDX-ReverseEngineering`.

   Read `PROJECT-RULES.md` first, then `AGENTS.md`.

   Source aliases used in the evidence below:

   | Alias | Exact file |
   |---|---|
   | S | `analysis/test-prep/todo-tests-20261103/builds/T360-bundle/source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/AaSessionService.java` |
   | D | `analysis/test-prep/todo-tests-20261103/builds/T360-bundle/source/analysis/parallel-aa-receiver/src/com/rdx/fullscreen/projection/VideoDecoder.java` |
   | V | `analysis/test-prep/todo-tests-20261103/builds/T360-bundle/source/analysis/parallel-aa-receiver/src/com/google/android/projection/protocol/VideoSink.java` |
   | A | `analysis/test-prep/todo-tests-20261103/builds/T360-bundle/source/analysis/parallel-aa-receiver/src/com/google/android/projection/protocol/AudioSink.java` |
   | B | `analysis/test-prep/todo-tests-20261103/builds/T360-bundle/BundleTests.java` |
   | L | `analysis/installer-20261112/Hackura-Installer/car-logs/headunit-logs-20261114-181708/hackura-20261114-181617.txt` |
   | C | Same log directory, `hackura-20261114-165532-auto-stall-3504ms.txt` |

   Also inspected: T350/T360 source-tree differences and `BundleTests.java` differences; T360 manifest, `host-test-output.txt`, `host-test-compile.txt`, `build-result.json`, relevant `build-report.json`/`test.json` entries, `GalReceiver.java`, and a `Prepare-Test.ps1` excerpt; canonical `BufferPool.java`.

2. **Files changed**

   None.

3. **Commands run**

   Read-only commands only:

   - `Get-Content`, indexed line excerpts, `rg --files`, and `rg -n` against the files above.
   - `Get-Location`.
   - `git status --short`, followed by a scoped `git status --short --untracked-files=no`.
   - `git diff --no-index` between T350/T360 source trees and test files, including `--numstat` and `--unified=0`.
   - `Get-FileHash -Algorithm SHA256` twice for six reviewed files.

   Diff exit status `1` indicated differences. Git reported an inaccessible global ignore file. One lookup for bundle-local `BufferPool.java` failed because that file was absent; the canonical file was subsequently read.

4. **Tests run and results**

   None executed, as instructed. No build or device operation performed.

   Existing saved output reports `PASS 282 bundle checks` at `T360-bundle/host-test-output.txt:10`. This is historical output, not an independently rerun result.

5. **Findings**

   **F1 — P1: Permanent decoder failure can become an indefinitely frozen Wi-Fi session.**

   `frame()` returning false establishes queue saturation, not transient recoverability. T360 keeps the same decoder and merely ACKs, logs, and requests video focus. A worker stuck permanently inside codec processing cannot be repaired by this branch. A stopped worker can also accept packets into its queue because `VideoDecoder.frame()` checks no worker-health state.

   With GAL ping/audio traffic still arriving, the TCP inactivity timeout need not fire. Wi-Fi explicitly disables `stuckWatch` recovery. T350 would terminate upon a subsequent full-queue rejection; T360 removes that escape.

   **Trade-off:** T360 avoids repeated reconnection during temporary saturation, but persistent decoder failure can leave the session frozen until another teardown trigger occurs. Whether the observed decoder stall was temporary is **UNKNOWN**.

   **F2 — P2: The five-second throttle does not bound handler-queue growth.**

   Every rejected frame calls `pictureLost()`, which allocates and posts a Runnable before checking the throttle. A blocked or sufficiently delayed handler can accumulate one task per rejected frame without a code-level cap or coalescing.

   The throttle does bound this method’s `requestVideo()` attempts to once per five seconds when its handler executes serially. It does **not** bound pending tasks. No new Java busy-spin loop appears in the changed branch; sustained allocation/ACK/post work remains driven by incoming frames.

   **F3 — P2: Audio leak elimination is unproven; the existing retention mechanism remains.**

   The log establishes repeated sessions and unclean teardown before the first `-12`. The source also supplies a concrete retention path: if another worker fails to stop, shutdown skips `AudioSink.destroy()`. Consequently, `playLoop()` need not reach its releasing `finally`.

   T360 removes one trigger for repeatedly entering that path. It does not repair the path itself. A later legitimate disconnect with a wedged decoder can still retain audio resources.

   No new AudioTrack construction loop was found in the changed branch. Within one AudioSink, initialization failure exits `playLoop()` rather than retrying track creation indefinitely. Nevertheless, “stopping this restart loop removes the audio failure” remains **UNKNOWN** without runtime evidence.

   **F4 — P2: The added tests validate saturation, not recovery.**

   The checks exercise the real bounded `VideoDecoder.frame()` queue: they are not vacuous about its rejection signal. However, the decoder is never started, ACKs are null, and the service callback is never invoked.

   Both checks would still pass with T350’s aborting service behavior. They prove neither recovery nor ACK delivery, throttle behavior, teardown preservation, or absence of leaks.

6. **Primary evidence for each finding and requested verification**

   **F1:**

   - `D:11,32`: capacity is 24; `frame()` only calls `queue.offer(...)`.
   - `D:60–73,89–118`: codec processing occurs on the worker; outer exceptions can terminate it; no worker restart is implemented.
   - `S:1554–1570`: rejection now ACKs and calls `pictureLost()` without replacing/stopping the decoder.
   - `S:72–86`: timeout applies to socket reads, not decoder progress.
   - `S:1662–1674`: stuck protection excludes `tcpMode`.
   - `V:37`: `requestVideo()` invokes `nativeSetVideoFocus(1,true)`; it does not recreate the local decoder.

   **F2:**

   - `S:1500–1508`: unconditional `handler.post(...)` precedes the checks and `lastPictureAsk` update.
   - `S:1567–1570`: every rejected frame reaches `pictureLost()`.
   - `S:1499,1568–1569`: `videoQueueFullDrops` affects logging only. Concurrent increments could lose counts; no ACK, lifecycle, or recovery decision depends on it. This is a benign logging race, not the identified correctness problem.

   **F3:**

   - `L:257,480,690,903,1112,1314,1525`: successive media tracks become ready in PID 3405.
   - `L:272–295`: queue-full shutdown is followed by two “Workers not confirmed stopped: native objects retained” reports.
   - `L:308–311`: another session starts in the same process.
   - `L:1726–1730`: AudioFlinger `-12`, initialization failure, and playback-worker summary occur later.
   - `S:822–850`: new sessions construct and initialize two AudioSinks.
   - `S:1696–1720`: failed worker joins/decoder stop prevent AudioSink destruction.
   - `A:121–130`: destruction signals stopping and interrupts/joins the playback worker.
   - `A:226–239,250–257`: track creation, failure exit, and release in `finally`.

   The clean comparator is limited: `C:55` shows one session, `C:275` shows a ready media track, and the file ends at `C:277`. It does not establish sustained playback or clean teardown.

   **F4:**

   - `B:268–275`: constructs an unstarted decoder, fills it using null ACKs, then checks rejection.
   - Source-tree comparison leaves `VideoDecoder.java` unchanged between T350 and T360.
   - Saved host output reports aggregate success without demonstrating these runtime properties.

   **ACK ownership: passes at the Java control-flow level.**

   - `V:29`: configures max unacked frames as 16.
   - `D:32`: a rejected `offer` does not enqueue that packet.
   - `S:1554–1567`: accepted packets own the Runnable; rejected packets receive the explicit ACK.
   - `D:111,117`: worker ACKs apply only to packets removed from the queue.
   - `V:41`: an active sink sends `nativeAckFrames(session,1)`.

   Therefore the explicit rejected-frame ACK and a later worker ACK cannot both belong to that same rejected packet. The session/count match the queued path. This proves one Java ACK attempt under an active sink, not successful native delivery. Outstanding accepted frames can still wait indefinitely on a wedged worker.

   **Decoder-null premise: correction required.**

   - `S:878,898–900`: decoder assignment/start precede `running=true`.
   - Assignment search found only `decoder = new VideoDecoder(this)`.
   - `S:1709` calls `decoder.stop()`; it does **not** null the field.

   No ordinary running-and-selected null-decoder path was found. Queue rejection remains reachable with a slow, wedged, exited, or concurrently stopping worker.

   **Remaining teardown callers: unchanged.**

   - Reader error/timeout: `S:1313–1319`.
   - Writer exception: `S:1391–1394`.
   - Phone goodbye: `S:1511–1514`.
   - `abortIo()` still closes transport, schedules shutdown, and prepares the receiver: `S:1412–1422`.

   The source diff changes only the new counter and queue-rejection branch, plus manifest version. These callers do not depend on queue rejection.

   **Dead-link reasoning needs qualification.**

   `S:1287–1309` reads a complete GAL message before dispatch. Buffered data can still be processed after physical connectivity disappears, so a callback does not prove present connectivity. Once buffered callbacks cease, queue-full handling stops; unchanged EOF/error/timeout handling remains responsible for teardown. A full decoder queue establishes neither a dead link nor a healthy decoder.

7. **Assumptions**

   - Source findings concern the reviewed T360 bundle.
   - Native ACK calls return normally for the Java ownership argument.
   - F1/F2 are conditional counterexamples, not claims that permanent codec hangs or handler backlog were observed.

8. **Unresolved uncertainties**

   - Whether T360 actually restores video after the recorded stall.
   - Which worker caused each unclean shutdown.
   - Whether retained tracks caused AudioFlinger `-12`; chronology and source support that explanation but do not prove exclusivity.
   - Native ACK reentrancy/delivery and phone response to repeated video-focus requests.
   - Why the observed queue reaches capacity 24 despite configured credit 16; strict one-callback-per-credit enforcement is not established by these Java facades.

9. **Exact diff summary**

   No review-generated diff.

   Observed T350→T360 source differences:

   - `AaSessionService.java`: **14 additions, 2 deletions**.
   - `AndroidManifest.xml`: **1 addition, 1 deletion**, versionName change.
   - Separately, `BundleTests.java`: **15 added lines**.

   Thus “two files only” holds for the compared **source trees**, not the complete bundles.

10. **Preservation checks performed**

   Two SHA-256 readings of the service, decoder, video sink, audio sink, tests, and manifest returned **ALL 6 HASHES IDENTICAL**.

   Reviewed service SHA-256:
   `1AAEE9AEC239031CB1091367160377D4D15460720B65528B4FF16C4C9F168189`

   That matches `T360-bundle/build-report.json:63–64`.

   No files were written, no frozen artifacts rebuilt, no key material read, and no device tools or prohibited Git mutations executed. Frozen-artifact hashes were not independently reverified.