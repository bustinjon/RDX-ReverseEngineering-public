**The core claim does not hold unconditionally.** The construction-order fix and protection against removing a **different numeric session ID** hold. Same-ID release/resume races can still discard fresh audio, lose the marker reset, or write a pre-release frame. These are source-level counterexamples; occurrence on the car is **UNKNOWN**.

1. **Files inspected**

   Let `B` mean `analysis/test-prep/todo-tests-20261103/builds/`.

   - `PROJECT-RULES.md`, `AGENTS.md`.
   - `analysis/agent-reviews/t370-audio-startup/{CODEX-T370.md,CLAUDE-T370-RECONCILE.md}`.
   - **A:** `B/T370-bundle/source/analysis/parallel-aa-receiver/src/com/google/android/projection/protocol/AudioSink.java`.
   - Corresponding T360 `AudioSink.java`.
   - **S:** `B/T370-bundle/source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/AaSessionService.java`.
   - **P:** `analysis/parallel-aa-receiver/src/com/google/android/projection/protocol/PcmFrames.java`; adjacent `AudioFocusPolicy.java`.
   - T370 `BundleTests.java`, `test.json`, `host-test-output.txt`.

   References such as **A:258** below identify these exact files and lines.

2. **Files changed**

   None.

3. **Commands run**

   Read-only `Get-Content` with line numbering; scoped `rg`/`rg --files`; `Get-FileHash -Algorithm SHA256`; `Get-Command java,javac,python`; arithmetic expressions; `git status --short`; and `git diff --no-index -- <T360 AudioSink> <T370 AudioSink>`.

   Initial Git status was truncated because of existing workspace changes. No build, device command, Git mutation, or file write ran. Official Java queue and equality documentation was also inspected.

4. **Tests run and results**

   No executable tests or builds run.

   Existing `host-test-output.txt:10` reports **PASS 287 bundle checks**. T370’s checks at `BundleTests.java:158–159` cover the constant’s range and arithmetic round-trip, not these interleavings.

   Read-only arithmetic returned:

   ```text
   InitialQueuedMs=501
   RemainingQueuedMsExact=159.666666666667
   ReplenishedQueueMs=560
   ```

   An initial arithmetic attempt using `[math]::Floor` failed under constrained PowerShell; direct arithmetic succeeded.

5. **Findings**

   - **P2 — An old trim can discard fresh resumed audio with the same session ID.** Identity removal protects the object selected by `peek`; it does not establish which playback generation that object belongs to.
   - **P2 — An in-flight assignment can erase the release reset.** Clearing the queue does not protect a later resumed backlog from being marked already synced.
   - **P2 — The broad “no stale frame” guarantee fails across release/resume.** The selected trim iteration skips its frame correctly, but a pre-release frame can survive outside the queue and subsequently pass the same-ID write check.
   - **P3 — Startup coverage and the 500 ms target remain conditional.** An existing track can mark an empty queue synced before a later burst; the finite guard can leave over 500 ms, and whole-frame removal can leave substantially less.
   - **No new P1 established.** The original pre-construction placement is corrected.

6. **Primary evidence for each finding and requested attack**

   **P2: fresh resumed audio can be removed.**

   This schedule requires no changed numeric session ID:

   1. Worker holds frame `F` for session `S`, passes **A:223–224**, and enters trimming.
   2. Pause after the loop’s `queuedMs()>500` test at **A:261**, before `peek()` at **A:262**.
   3. Protocol release clears the queue and resets the marker at **A:59**.
   4. Focus resumes successfully at **A:65–66**. A fresh, small frame `G(S)` arrives through **A:154–155**.
   5. Worker resumes: `peek()` returns `G`; its ID equals `F.session`, so **A:263** removes it—even if the queue now contains only 40 ms.

   The old trim has therefore discarded fresh post-resume audio and can empty that small queue. Full stop/start with reused ID `S` permits the same schedule: **A:189** clears; **A:175** accepts the reused ID and clears `stoppedSession`.

   **The narrower different-ID guarantee holds.** `Frame.session` is final and `Frame` has no equality override (**A:72–75**). A head with another ID fails **A:263**. Removal uses equality, which here means object identity; it cannot substitute a newly allocated frame after the selected object disappears. See [ArrayBlockingQueue.remove](https://docs.oracle.com/javase/8/docs/api/java/util/concurrent/ArrayBlockingQueue.html#remove-java.lang.Object-) and [Object.equals](https://docs.oracle.com/javase/8/docs/api/java/lang/Object.html#equals-java.lang.Object-).

   With the single worker shown at **A:115–116**, producers append and callbacks clear. If clearing changes the head after `peek`, the old object is absent and `remove(head)` fails. **No different-ID removal counterexample established.**

   **P2: release reset can be lost, and clearing does not make it harmless.**

   1. Worker evaluates **A:257** true for `F(S)`; pause before **A:258**.
   2. Release executes **A:59**, clearing the queue and setting `syncedSession=MIN_VALUE`.
   3. Worker executes **A:258**, overwriting that reset with `S`.
   4. Queue is empty at **A:259**; focus remains disallowed, so **A:270** drops `F`.
   5. Resume grants focus; fresh `S` audio accumulates above 500 ms.
   6. Subsequent iterations skip trimming because the marker already equals `S`.

   The reset was intended to enable this later trim, but the worker erased it. Protocol release does not change `activeSession` (**A:56–68**). Its invocation is posted to the service handler (**S:851–858**), while playback uses a separate worker (**A:115–116**).

   **P2: stale-frame handling is correct inside the taken trim branch, but not across every release race.**

   There is no PCM write before trimming in the current iteration: construction ends at **A:250**, trim runs at **A:257–269**, and playback/write occur at **A:271–275**. When trimming is selected, **A:260** counts the polled frame and **A:267** skips its write. That accounting is correct.

   However, a worker-held frame is outside `frames.clear()`:

   1. Worker polls `F(S)` and passes **A:223–224**.
   2. Release clears/flushes at **A:59–60**.
   3. Same-session focus resumes before the worker continues.
   4. With queued duration ≤500 ms, **A:259** does not select trimming.
   5. **A:273** accepts the pre-release `F`, because its session still equals `activeSession`; **A:274** writes it.

   There is no generation field in `Frame` (**A:72–75**). Thus a pre-release frame can be submitted after the flush.

   Separately, even different IDs have a check/write window between **A:273** and **A:274**: stop/start can occur after validation and before `player.write`. That window already exists in **T360 AudioSink.java:245–246**; it is not introduced by this trim.

   **P1 placement and existing-track resume.**

   The original construction-backlog bug is fixed narrowly: marker assignment follows completed construction (**A:235–258**).

   When `player` already exists, the worker still executes the trim block, but it can mark `S` synced with an empty queue (**A:257–259**). If a burst arrives after that measurement, subsequent same-ID frames skip trimming. This does not invalidate catching backlog already present after construction; it does invalidate any guarantee that all startup/resume backlog must already be present at that point.

   **Guidance and `drainingSession`.**

   Media and guidance use separate sink instances: media type 3 at **S:822–841**, guidance type 1 at **S:845–849**. The only assignment of a real draining ID is under `audioType==1` (**A:182–185**), while trimming excludes that type (**A:257**).

   Under the inspected initialization, the media sink has no real guidance-draining session to mis-key this trim. **No guidance-specific counterexample established.**

   **Bound, remaining latency, and cushion.**

   **A:261** permits at most **256 successful queued-frame removals**, plus the already-polled frame: at most **257 discarded frames per taken branch**. Continuous replenishment cannot make the removal loop unbounded.

   It can leave more than 500 ms: keep fourteen 40 ms frames queued and replace each removed frame before the next measurement. After 256 removals, 560 ms remains. No retrim follows while the marker stays equal (**A:257–258**).

   It can also leave less than 500 ms without concurrency. At media’s configured 192,000 bytes/second (**S:841**), queued frames of 65,536 and 30,656 bytes total 501 ms. Removing the first leaves approximately 159.67 ms, reported as 159 by **A:51**. Both lengths satisfy **P:5–7**.

   Therefore 500 ms is a removal threshold, not a guaranteed reserve or postcondition. The iterator used by **A:52** is also [weakly consistent](https://docs.oracle.com/javase/8/docs/api/java/util/concurrent/ArrayBlockingQueue.html#iterator--). These are latency/cushion limitations; an audible underrun is **UNKNOWN**.

   **Flow control and diagnostics.**

   Queue publication is at **A:155**; ACK is in the arrival callback’s `finally` at **A:158**, independently of playback/discard. Trimming adds no playback-dependent ACK requirement.

   “Already ACKed” remains literally inaccurate in the older comment at **A:45–46**: the worker can discard after enqueue but before the callback reaches `finally`. Shutdown also has the `created` guards at **A:145,158**. Native ACK success is **UNKNOWN**.

   `dropped` is used for increments and diagnostic logging, not playback/ACK decisions (**A:35,151–158,260–276,285**). Its unsynchronized increments can lose diagnostic counts.

7. **Assumptions**

   The counterexamples assume callback/handler work can interleave with the playback worker, consistent with **A:115–116** and **S:852–858**. They assume successful focus reacquisition and a valid AudioTrack.

   Same-ID protocol focus resume is directly supported by release leaving `activeSession` unchanged. Numeric-ID reuse across full stop/start is accepted by the Java source; native guarantees about reuse are **UNKNOWN**.

   Frame-size calculations assume the shared `PcmFrames.java` named by `test.json:88` matches the packaged dependency.

8. **Unresolved uncertainties**

   **UNKNOWN:** actual race occurrence/frequency, native callback ordering guarantees, full-stop ID reuse on the phone, packaged dependency parity, audible effects, hardware buffering, native ACK failures, and end-to-end latency.

9. **Exact diff summary**

   None; no files changed.

10. **Preservation checks performed**

   Repeated SHA-256 checks of current T370 AudioSink matched:

   ```text
   53DD2D6C14257FAEC5342A5100D5BCCF4B37E702BBE3DAA48D3D7D7FE20EF09A
   ```

   No frozen artifact was rebuilt or modified; frozen hashes were not checked. No key material, device, or milestone was accessed or advanced.