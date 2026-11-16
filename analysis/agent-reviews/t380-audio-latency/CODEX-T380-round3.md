**The claim does not hold as written. A P2 stale-timer counterexample remains without integer wrap. No new P1 established.**

**1. Files inspected**

Paths below use these references:

- **A:** [T380 AudioSink.java](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/test-prep/todo-tests-20261103/builds/T380-bundle/source/analysis/parallel-aa-receiver/src/com/google/android/projection/protocol/AudioSink.java).
- **S:** [T380 AaSessionService.java](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/test-prep/todo-tests-20261103/builds/T380-bundle/source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/AaSessionService.java), relevant focus/setup/shutdown excerpts.
- **P:** [shared PcmFrames.java](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/src/com/google/android/projection/protocol/PcmFrames.java).

Also inspected: `PROJECT-RULES.md`, `AGENTS.md`, `CLAUDE-T380-RECONCILE.md`, `CODEX-T380-round2.md`, shared `AudioFocusPolicy.java`, T370 AudioSink through comparison, T380 `BundleTests.java` and saved `host-test-output.txt`; official Android documentation and AOSP excerpts.

**2. Files changed**

None.

**3. Commands run**

Read-only `Get-Content`, `rg`, `rg --files`, `Get-FileHash -Algorithm SHA256`, scoped `git status --short --untracked-files=no`, and `git diff --no-index`; official Android/AOSP web reads; in-memory JavaScript models.

One attempted bundle-local `PcmFrames.java` read failed because that file was absent; the shared source was subsequently located. Some version-specific AOSP URLs were inaccessible. Git status warned that the global ignore file was inaccessible.

**4. Tests run and results**

No build, application tests, or device tests ran.

Seven in-memory source-order/arithmetic scenarios passed their assertions:

[Code block omitted; consult project-authored source.]

These are models, **not execution of the Java implementation or Android runtime**.

Saved output reports `PASS 289 bundle checks` (`T380-bundle/host-test-output.txt:10`). The T380-specific assertions check constant ranges, not lifecycle interleavings (`BundleTests.java:163–164`).

**5. Findings**

**P2 — An old/aborted write can arm the new generation during the stopped interval, producing an immediate first-resumed-write flush.**

Concrete protocol-release schedule:

1. Worker passes `focusAllowed` and executes `player.play()` (`A:324–325`).
2. Handler executes protocol release: denies focus, clears the queue, increments generation, pauses and flushes. It leaves `activeSession` unchanged (`A:100–101`).
3. Worker reaches its writer, which returns `-1` because focus is denied (`A:328`). `P:13–14` returns `false`; `A:331` only logs the incomplete write.
4. The post-write guard still passes: same session, existing player, not stopping. It does **not** require focus or a successful write (`A:335`).
5. Worker reads the **new generation** and arms its timer while paused (`A:336–338`).
6. After more than 1200 ms, successful protocol regain restores focus without another generation bump (`A:106–107`).
7. First resumed write retains that expired timer and flushes immediately (`A:338,345–350`).

Thus `resyncArmedGen==gen` can hold for the first actual write of the resumed period **without any generation value repeating**.

A full-stop variant also exists: worker passes `A:335`, stop completes `A:230–233`, then worker captures and arms the stopped generation at `A:336–338`. The inner guard prevents firing while stopped, but does not undo the premature arm.

**P3 — The diagnostic counter is not worker-only.**

`framesSinceFlush` is reset by release and stop callbacks (`A:100,230`) and incremented by the worker (`A:329`). Its unsynchronized accounting can therefore be inconsistent across a flush. This affects diagnostics, not the resync predicate (`A:345–348`).

**P3 — Integer wrap remains a theoretical equality collision.**

If the worker observes no intervening generation during `2^32` increments, the generation can equal an old armed/fired value. An expired arm can survive, or an old fired latch can suppress the attempt (`A:53,70–71,100,230,338,345`). Operational occurrence is **UNKNOWN**.

**6. Primary evidence and requested checks**

| Check | Assessment and evidence |
|---|---|
| Once per generation | For a non-repeating generation, **at most one attempt**: latch precedes the operation (`A:345–351`). Exactly one successful resync requires subsequent qualifying writes, allowed focus, and successful operations. |
| Fresh 1200 ms timer | Ordinary path works: arming and comparison use the same `nowMs`, so that iteration has zero elapsed time (`A:337–345`). The P2 schedule above defeats the first-resumed-write guarantee. |
| Song change | Data-arrival/start change `activeSession` without changing generation (`A:194–196,215–218`). An already-fired generation does not re-fire. |
| Stale resync after final generation check | A stop can still complete between `A:348` and `A:349`, leaving an initialized track playing after the callback’s flush. **No crossing into subsequently written PCM found:** writing and resync execute sequentially on the same worker (`A:325–354`). Release sites are worker-owned initialization fallback/final cleanup (`A:286,360–361`), so no released-track resurrection path was established. |
| “Benign, activeSession=-1, destroy cleans up” | Too absolute. Start/data callbacks can restore `activeSession` before the delayed operation (`A:194–196,216`). Ordinary playback-stop does not invoke `destroy()` (`A:222–235`); destruction occurs separately (`A:171–180`, `S:1750–1755`). The worker can be descheduled between instructions; the window has no source-level time bound. Audible harm from this empty-track restart is **UNKNOWN**. |
| Android transient focus loss/gain | Generation and timer/latch remain unchanged (`A:118–125`). If unfired, the timer ages through the pause and can fire on the first resumed write; if fired, it stays fired. This satisfies generation-based semantics, but supplies no fresh 1200 ms delay after transient regain. |
| Latch before operation | Confirmed. A caught `IllegalStateException` consumes the attempt and logs `SKIPPED`; success logging follows all three operations (`A:347–351`). A failed generation re-check produces neither operation nor success log. |
| Diagnostic decision isolation | Confirmed numerically: `presMs`, head position, `trackMs`, and `queuedMs` feed logging, not the predicate (`A:339–348`). |
| Timestamp advance/clamp | Formula correctly accounts for timestamp age at nominal sample rate; null player, invalid rate, unavailable timestamp and `IllegalStateException` return `-1` (`A:81–92`). Negative and over-10-second values are rejected. Android specifies the compatible monotonic timebase and wrapping timestamp position. [AudioTimestamp contract](https://developer.android.com/reference/android/media/AudioTimestamp#nanoTime) |
| Diagnostic exception containment | Partial: `getPlaybackHeadPosition()` is outside the helper’s local catch (`A:341`). An exception there reaches the worker-wide failure/cleanup path (`A:357–361`). No reachable released-track cause was found in this lifecycle; unconditional diagnostic exception isolation is not established. |
| Guidance/draining | New resync block excludes type 1 (`A:335`). T370→T380 comparison leaves `finishDrain`, guidance-stop branching and draining logic unchanged (`A:223–243,258–264`). |

**7. Assumptions**

One initialization and one playback worker per sink. Protocol focus work can interleave with that worker: it is posted to the service handler (`S:851–858`), while playback runs on a separately created thread (`A:156–157`). Counterexamples assume successful focus regain after a pause exceeding 1200 ms.

**8. Unresolved uncertainties**

**UNKNOWN:** race frequency, native callback-order guarantees, vendor timestamp accuracy, audible impact of the empty-track restart, and whether a successful one-shot flush fixes and holds the latency reduction.

**9. Exact diff summary**

Reviewer diff: none. Read-only comparison confirmed the guidance/drain paths were unchanged.

**10. Preservation checks performed**

T380 AudioSink SHA-256 matched before and after review:

[Code block omitted; consult project-authored source.]

Reconciliation SHA-256 also matched:

[Code block omitted; consult project-authored source.]

Scoped tracked-file status produced no entries before or after review, with the global-ignore warning noted above. Frozen-artifact hashes were not reverified. No writes, builds, device operations, key-material reads, agent spawning, or milestone changes occurred.