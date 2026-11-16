**The guard does not close P2a or P2b.** Both have counterexamples under ordinary sequentially consistent execution; neither requires stale reads or wraparound.

1. **Files inspected**

   Source aliases below identify these exact files:

   - **A:** [T370 AudioSink.java](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/test-prep/todo-tests-20261103/builds/T370-bundle/source/analysis/parallel-aa-receiver/src/com/google/android/projection/protocol/AudioSink.java)
   - **B:** [T360 AudioSink.java](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/test-prep/todo-tests-20261103/builds/T360-bundle/source/analysis/parallel-aa-receiver/src/com/google/android/projection/protocol/AudioSink.java)
   - **S:** T370-bundle `source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/AaSessionService.java`
   - **P:** `analysis/parallel-aa-receiver/src/com/google/android/projection/protocol/PcmFrames.java`
   - `PROJECT-RULES.md`, `AGENTS.md`
   - `analysis/agent-reviews/t370-audio-startup/{CLAUDE-T370-RECONCILE.md,CODEX-T370-round2.md}`
   - T370-bundle `test.json`—scoped search only.

2. **Files changed**

   None.

3. **Commands run**

   Read-only `Get-Content` with line numbering, scoped `rg`/`rg --files`, `Get-FileHash -Algorithm SHA256`, and:

   ```text
   git diff --no-index -- <T360 AudioSink.java> <T370 AudioSink.java>
   ```

   Diff exited **1**, reporting source differences. An attempted read/hash of bundle-local `PcmFrames.java` failed because that path does not exist; inspected shared file **P**, referenced by `test.json:88`.

   Consulted official Java atomic and integer specifications. No build, device command, Git mutation, or file write ran.

4. **Tests run and results**

   No executable tests or builds run. Findings below are source-level interleaving counterexamples, not runtime reproductions.

5. **Findings**

   - **P2a — remains open:** a release/resume after the loop condition can make the old trim remove fresh same-ID audio.
   - **P2b — remains open:** a release after the final generation check can have its reset overwritten.
   - **P3 — theoretical wraparound limitation:** equality cannot detect a complete `2^32` increment cycle.
   - **No new P1 established.** Normal-path trimming and the loop’s iteration bound remain intact.

6. **Primary evidence for each finding**

   **P2a: generation check and removal are separate operations.**

   Let worker **W** hold old frame `F(S)` and capture generation `g`.

   1. W passes the complete loop condition at **A:266**: generation equals `g`, and queued duration exceeds 500 ms. Pause immediately before **A:267**.
   2. Handler releases focus: clears the queue, resets `syncedSession`, increments generation, and flushes (**A:63–64**).
   3. Focus successfully resumes (**A:69–70**). One fresh 40 ms frame `G(S)` is enqueued (**A:148–159**).
   4. W resumes. `peek()` returns `G`; its session matches `F.session`, so **A:268** removes it. There is no generation or duration recheck between the passed condition and removal.
   5. The next loop condition detects the change; **A:274** subsequently aborts. Neither restores `G`.

   **Result:** an old-generation trim empties a fresh 40 ms queue. The final gate detects the race after the destructive operation.

   This schedule is supported by separate worker creation (**A:119–120**) and handler-posted protocol focus requests (**S:852–858**). It does not require full-stop session-ID reuse.

   **Worker captures generation AFTER release:** if release/resume completes before **A:262**, and a legitimate new-generation backlog exceeds 500 ms, trimming that backlog is consistent with the intended resume trim. That case alone is not lost fresh audio. It does not invalidate the BEFORE-release counterexample above.

   **P2b: the final gate does not protect the assignment.**

   Choose a small backlog so `trimmed=false`.

   1. W captures `g` at **A:262**, then reads `g` at **A:274**. The inequality is false. Pause before **A:275**.
   2. Release executes **A:63**, setting `syncedSession=MIN_VALUE` and incrementing generation.
   3. W executes **A:275**, overwriting the reset with `S`.
   4. While focus remains disallowed, **A:278** drops W’s held frame.
   5. Resume succeeds and a same-ID backlog accumulates. Subsequent iterations skip the entire trim block because `syncedSession==frame.session` (**A:261**).

   **Result:** the re-trim reset is lost despite release having bumped generation before the assignment. There is no later generation check on the skipped path.

   Full-stop reset has the same exposure (**A:193**); same-ID restart is accepted by **A:178–180**. Phone/native reuse guarantees are **UNKNOWN**.

   **Termination and spin.**

   **A:266–270** permits at most **256 completed loop bodies** per invocation. Each body removes a frame or breaks. Generation mismatch exits rather than retries; **A:274** returns to the outer loop, whose next queue operation is timed `poll` (**A:221**).

   No self-sustaining generation-wait loop or new internal busy-spin was found. This proves an iteration bound assuming called operations return; it does not prove a wall-clock deadline under arbitrary scheduling or library contention.

   **Normal path.**

   With stable generation, valid focus, and a quiescent same-session queue:

   - Construction completes before trimming (**A:239–264**).
   - A backlog above 500 ms is drained by whole frames (**A:266–269**).
   - The session is marked synced; the stale polled frame is skipped (**A:275–276**).
   - A backlog at or below 500 ms is marked synced and reaches normal playback (**A:264–283**).
   - Later same-session frames skip trimming (**A:261**).

   Thus the guard preserves the intended normal control flow. The threshold remains subject to whole-frame removal and the existing 256 bound.

   **Atomicity, two increments, visibility, and wraparound.**

   The field is an `AtomicInteger` (**A:53**); both reset sites increment it (**A:63,193**). Individual increments are atomic, and reads/updates have volatile memory effects. Two increments produce `g+2`, distinct from `g` even across the signed boundary. These guarantees do not combine the generation check with queue removal or marker assignment. [Java atomic specification](https://docs.oracle.com/javase/8/docs/api/java/util/concurrent/atomic/package-summary.html), [AtomicInteger specification](https://docs.oracle.com/javase/8/docs/api/java/util/concurrent/atomic/AtomicInteger.html).

   **P3:** after exactly `2^32` increments between observations, the 32-bit value returns to `g`, defeating equality-based change detection (**A:262,266,274**). A single signed overflow still changes the value. Practical reachability during one trim is **UNKNOWN**; this is a formal limitation. [Java integer representation](https://docs.oracle.com/javase/specs/jls/se8/html/jls-4.html#jls-4.2), [overflow semantics](https://docs.oracle.com/javase/specs/jls/se8/html/jls-15.html#jls-15.18.2).

   **Residual P2c.**

   A pre-release frame already held outside the queue can survive clearing/flush. If W subsequently captures the new generation, sees a small backlog, and resumes with matching session/focus, it can reach **A:282**.

   This possibility predates T370: **B:208,214–215,242–246** already permits a worker-held frame to survive release/resume and pass the same write checks. The diff confirms those checks remain unchanged at **A:278–283**.

   **Pre-existing possibility: confirmed. “Not worsened” in frequency/timing: UNKNOWN.** T370 inserts trim work and possible logging between poll and write; unchanged race probability cannot be established from this source comparison. The held object remains one frame; partial writes can submit it in multiple calls (**P:10–15**).

7. **Assumptions**

   Worker and handler can interleave between the cited operations; focus reacquisition succeeds; the track is valid. Both principal counterexamples work with protocol focus release/resume preserving `activeSession` (**A:60–73**).

8. **Unresolved uncertainties**

   **UNKNOWN:** occurrence/frequency on hardware, audible impact, native callback ordering and full-stop ID reuse, packaged-source parity, wall-clock operation bounds, and whether T370 changes P2c frequency.

9. **Exact diff summary**

   None; no files changed.

10. **Preservation checks performed**

    Repeated SHA-256 checks matched before and after review:

    ```text
    T370 AudioSink:
    ECEB7C59B8FE167E79A69454A79FA783F8E95A2536DD9BF5DBE2AB0322952261

    T360 AudioSink:
    8DBE69143C7267C48E3E6C6332C039F363A21C74A08D791A19AB57087C3FF7C4
    ```

    Frozen artifacts were not rebuilt, modified, or hashed. No key material or devices were accessed; no milestone was advanced.