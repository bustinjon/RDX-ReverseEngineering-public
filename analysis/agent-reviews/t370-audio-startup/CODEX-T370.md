**The core claim does not hold as written.** There is a startup schedule that misses the construction backlog, and a race that can discard a newer session’s live frames. These are source-level counterexamples; their occurrence on the car is **UNKNOWN**.

1. **Files inspected**

   Let `B` mean `analysis/test-prep/todo-tests-20261103/builds/`.

   - `PROJECT-RULES.md`, `AGENTS.md`.
   - `B/T370-bundle/source/analysis/parallel-aa-receiver/src/com/google/android/projection/protocol/AudioSink.java` — called **AudioSink** below.
   - T370’s `AaSessionService.java`, `AndroidManifest.xml`, `BundleTests.java`, `test.json`, and saved host/build/package output.
   - Corresponding T360 AudioSink, manifest, tests, and session-service comparison.
   - Shared `analysis/parallel-aa-receiver/src/com/google/android/projection/protocol/{PcmFrames,AudioFocusPolicy}.java`.
   - Supplied `hackura-20261114-203729.txt` — called **car log** below.
   - Official Java queue and Android AudioTrack documentation.

2. **Files changed**

   None.

3. **Commands run**

   Read-only `Get-Content` with line numbering; scoped `rg`/`rg --files`; `git diff --no-index` comparisons; `Get-FileHash -Algorithm SHA256`; initial `git status --short`.

   The initial status output was truncated because the workspace contains many existing changes. Two attempted dependency reads under T370’s snapshot failed because those files were absent; I then inspected their shared source paths, which `test.json:85,88` names. No build, device command, or mutation ran.

4. **Tests run and results**

   No executable tests or builds run, as requested.

   Existing `T370-bundle/host-test-output.txt:10` reports `PASS 287 bundle checks`. The two new checks at `BundleTests.java:158–159` validate the constant’s range and arithmetic round-trip. They do **not** exercise startup ordering, concurrent callbacks, session transitions, or underruns.

5. **Findings**

   - **P1 — Startup trimming can complete before the backlog exists.** The worker marks the session synced even with an empty queue, before lazy AudioTrack construction. Consequently, the construction backlog can remain untrimmed.
   - **P2 — Trimming can cross a stop/start and discard new live audio.** The duration check and destructive poll are separate operations. Neither the loop nor its final marker assignment validates that the original session is still current.
   - **P3 — “Every dropped frame was already ACKed” is false literally.** Publication to the queue precedes the ACK. Nevertheless, I found no new playback-dependent ACK requirement that would establish a flow-control stall.
   - **P3 — The trim has no finite work bound.** A continuously replenished queue can keep the loop running. Whether actual callback scheduling can sustain that condition is **UNKNOWN**.

6. **Primary evidence for each finding and attack**

   **P1: concrete startup counterexample.** `AudioSink.java:220–227` allows this sequence:

   1. `playbackStartCallback(S)` sets `activeSession=S` (`:175`).
   2. Worker reaches the trim branch while the queue is empty and focus is allowed.
   3. `backlog=0`; no frames are dropped, but `syncedSession=S` is assigned unconditionally (`:221–227`).
   4. First PCM arrives; worker polls it (`:229`) and constructs AudioTrack (`:247–261`).
   5. PCM accumulates during construction. Subsequent iterations skip trimming because `syncedSession==activeSession`.

   This requires no unusual phone behavior. The supplied **car log:329–335** shows focus granted before playback start, **63 ms between start and first PCM**, and **807 ms between first PCM and track ready**. The worker polls with a 100 ms timeout (`AudioSink.java:229`), so a timeout inside that 63 ms interval permits the counterexample. The log does not reveal the worker’s exact polling phase.

   There is also an alternate ordering: if the worker was already blocked in `poll` before playback start, the first frame bypasses the trim check, constructs the track, and is written at `:264–268`; trimming happens on the **next** iteration. Thus “trim before poll” is true locally, but **trim before the first write is not guaranteed**. That first stale frame can remain in AudioTrack; this trim does not flush it.

   **P2: concrete cross-session race.** At `AudioSink.java:224`, pause the worker after `queuedMs()>500` returns true but before `frames.poll()`:

   1. Callback executes full stop, clearing the old queue and resetting the marker (`:189`).
   2. Callback starts session B (`:175`) and enqueues one live B frame (`:154–155`).
   3. Worker resumes its already-authorized `poll`, discarding that B frame despite the new queue containing less than 500 ms.
   4. Worker assigns `syncedSession=activeSession`, potentially marking B synced (`:227`).

   The poll does not inspect `old.session`, `focusAllowed`, or `stopping`. Volatile fields (`:29,49`) provide visibility, **not an atomic relationship between the session, queue measurement, poll, and marker assignment**.

   A related lost-reset race exists: protocol release resets `syncedSession` at `:59`, but an in-progress trim can overwrite it at `:227`. A same-session focus resume can then skip its intended retrim.

   **Flow control.** The only queue insertion found is `AudioSink.java:155`. ACK occurs later in `finally` at `:158`. Therefore, a worker can dequeue or discard a frame **before** its ACK executes.

   Normal callback completion still ACKs independently of playback or discard. The trim adds no ACK withholding. Existing exceptions to an unconditional ACK include `!created` at entry (`:145`) and the `if(created)` guard in `finally` (`:158`), relevant to shutdown. Native ACK success and native callback serialization remain **UNKNOWN**.

   **Once per session / song changes.** Every `activeSession` writer is:

   - Initialization: `:29`.
   - Every accepted PCM callback: `:154`.
   - Playback start: `:175`.
   - Guidance stop: `:185`.
   - Full stop: `:189`.

   `requestProtocolFocus()` does **not** write `activeSession`; it resets `syncedSession` on release (`:59`). With a stable session ID and no release/full stop, the marker prevents further trimming.

   The supplied **car log:372–382,423–435** records next-song commands and changed metadata between session-0 start (`:331`) and stop (`:485`), without another playback-start event. That supports stable sessions across those observed song changes. A universal guarantee for all phones/apps is **UNKNOWN**. PCM callbacks themselves can change the active ID without `playbackStartCallback` (`AudioSink.java:153–155`).

   **Guidance safety.** T370 `AaSessionService.java:841` creates media as a separate type-3 sink; `:845–849` creates guidance as type 1. The new branch explicitly excludes type 1 (`AudioSink.java:220`). Guidance draining (`:182–187`), `finishDrain()` (`:197–202`), and its worker dispatch (`:231`) are unchanged in the T360→T370 diff. No direct guidance-trim counterexample found.

   **Queue iteration, under-drop, and looping.** `queuedMs()` iterates the concurrent queue (`AudioSink.java:52`); its result is not an atomic snapshot with the later poll. Java documents this iterator as [weakly consistent](https://docs.oracle.com/javase/8/docs/api/java/util/concurrent/ArrayBlockingQueue.html#iterator--). Arrivals after a measurement can leave more than 500 ms queued after the trim commits. Concurrent clear/refill permits the over-drop described above.

   No iterator-induced NPE was established: insertion creates a non-null `Frame`, and the inspected `PcmFrames.java:5–8` rejects null data. Exact packaged dependency parity is an assumption below.

   The loop at `AudioSink.java:224` has no drop limit, deadline, or cancellation check. For example, repeatedly replenishing one frame after each discard can maintain a queue above 500 ms indefinitely. This is a possible schedule, **not evidence of an observed hang**.

   **Underrun and remaining latency.** The 500 ms value is an **upper bound**, not a guaranteed reserve. Whole-frame removal can leave less. With the inspected 65,536-byte maximum (`PcmFrames.java:6`) and configured 48 kHz stereo PCM (`AaSessionService.java:841`), one frame can represent approximately **341 ms**; trimming can leave approximately **159 ms**.

   `PREBUFFER_MS=0` (`AudioSink.java:38`) disables replenishment waiting. AudioTrack capacity remains **at least** 500 ms (`:252`), but capacity does not ensure that buffer is filled. The worker calls `play()` before writing (`:264–267`). Android documents that insufficiently primed streaming playback waits for a device-specific minimum and can underrun if writes arrive too slowly. [AudioTrack documentation](https://developer.android.com/reference/android/media/AudioTrack#play())

   An audible startup blip is therefore neither proved nor excluded. Steady-state queue capacity remains 64 (`AudioSink.java:71`), but unchanged capacity alone does not prove unchanged startup gap tolerance.

   Finally, `queuedMs()` measures **queued PCM duration**, not timestamp age (`:52`; callback timestamp unused at `:144–158`). Even a successful trim cannot establish end-to-end “near-live” latency by itself.

7. **Assumptions**

   Counterexamples assume callbacks and the playback worker can interleave at the cited statements. The source starts a distinct worker (`AudioSink.java:115–116`); the car log also shows callback and worker activity on different thread IDs (`car log:331–335`).

   Frame-size calculations assume the inspected shared `PcmFrames.java` matches the packaged dependency. T370’s snapshot did not contain that file; packaged parity was not established.

8. **Unresolved uncertainties**

   **UNKNOWN:** actual T370 runtime ordering; frequency of either race; native callback/session-order guarantees; behavior across other phones/apps; audible underruns; actual hardware buffering; end-to-end latency after trimming.

   `T250_PCM_GAP ms=1149` at **car log:510** establishes an arrival gap during manual pause/resume. It does not independently measure how much latency flushing removed.

9. **Exact diff summary**

   None produced. Reviewed differences add the trim constant/marker, two marker resets, the worker trim branch, two constant checks, and the manifest version change.

10. **Preservation checks performed**

   Repeated SHA-256 checks returned `UNCHANGED` for:

   - AudioSink: `9CB2E50E2D61B0E2209427935FC081E2343FA1B555E005A8BB05658115E4C6CB`
   - BundleTests: `3A86BDF806FD371B57AC3A3446C269C1B9064A2E78CE1C14850155AEC80290BB`
   - Manifest: `958492796D8F80E31077ECFC7D6A4DB5F7C72A3B764A01B5B16BA3F1B26CE85C`

   No frozen artifact was rebuilt or modified. Frozen artifact hashes were not checked. No key material or device was accessed.