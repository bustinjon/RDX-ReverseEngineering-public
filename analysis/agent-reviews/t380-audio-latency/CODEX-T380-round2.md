**The claim does not hold as written.** The timer removes round 1’s unreachable threshold, but stop/release races, incomplete session resets, and delayed firing remain. Whether one flush fixes the audible delay—and holds—is **UNKNOWN**.

1. **Files inspected**

   References used below:

   - **A:** [T380 AudioSink.java](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/test-prep/todo-tests-20261103/builds/T380-bundle/source/analysis/parallel-aa-receiver/src/com/google/android/projection/protocol/AudioSink.java).
   - **S:** T380-bundle `source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/AaSessionService.java`.
   - **L:** [saved T360 capture](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/installer-20261112/Hackura-Installer/car-logs/headunit-logs-20261114-203807/hackura-20261114-203729.txt).

   Also inspected: `PROJECT-RULES.md`, `AGENTS.md`, `CODEX-T380.md`, `CLAUDE-T380-RECONCILE.md`; T370 AudioSink; T380 `BundleTests.java`, `host-test-output.txt`, and `test.json`; shared `PcmFrames.java` and `AudioFocusPolicy.java`; official Android documentation and AOSP AudioTrack implementation.

2. **Files changed**

   None.

3. **Commands run**

   Read-only `Get-Content`, `rg`, `rg --files`, `Get-FileHash -Algorithm SHA256`, `git status --short`, and `git diff --no-index`; official Android/AOSP web reads; in-memory JavaScript interleaving/arithmetic models.

   Initial broad status output was truncated; subsequent status was scoped. T380 `RESULT.md` was absent. Some version-specific AOSP URLs were inaccessible.

4. **Tests run and results**

   No build, application tests, or device tests ran.

   In-memory models confirmed these counterexamples under the stated schedules:

   ```text
   Guard -> full stop -> worker resync:
     track=playing, focus=false, activeSession=-1, latch=true

   Old write -> release/reset -> same-session regain -> capture new generation:
     guard accepts the old frame before any resumed write

   Session change without reset:
     first-write immediate flush, or inherited latch prevents any resync

   First write -> 60-second gap -> next write:
     resync fires at +60000 ms

   Timestamp position=written, presentation time=now+1000 ms:
     current presMs=0

   32-bit position wrap, actual pending=50 ms:
     reported pending=89478535 ms
   ```

   These demonstrate code-level schedules and arithmetic, not Android runtime execution.

   Existing saved output reports **PASS 289 bundle checks** (`T380-bundle/host-test-output.txt:10`). The T380 assertions check constant ranges, not lifecycle ordering or AudioTrack behavior (`BundleTests.java:163–164`).

5. **Findings**

   **P2 — The final generation check does not prevent restart after stop/release.**

   Concrete schedule:

   - Worker passes every check at `A:332–333`.
   - Callback executes full stop: resets state/latch, increments generation, pauses and flushes (`A:217–220`).
   - Worker executes `pause(); flush(); play()` and sets `startupResynced=true` (`A:334–336`).

   Nothing rechecks generation or focus after the callback. The track remains initialized, so this sequence need not throw. It leaves the track playing despite the logical stop and overwrites the reset latch. Audible output from an already emptied buffer is **UNKNOWN**, but this is not guaranteed to be a harmless no-op.

   Android focus-loss callbacks also pause without incrementing generation or resetting the timer/latch (`A:104–110`).

   **P2 — Generation is captured too late to identify the write’s playback period.**

   An old frame can finish writing, enter the T380 block, and capture `nowMs`. Release then resets `playStartMs=0`; same-session regain restores focus. The worker subsequently captures the **new** generation at `A:331`.

   Its old frame still matches `activeSession`, and `nowMs-0>=1200` passes. It can resync immediately, before the first resumed write (`A:87–94,322–334`). The generation comparison does not detect this schedule.

   **P2 — “Exactly once per session,” fresh timing, and “cannot fire mid-song” are not guaranteed.**

   Both data arrival and playback-start can change `activeSession` without resetting `playStartMs` or `startupResynced` (`A:181–183,202–205`).

   Consequently:

   - An unresynced old session can donate an expired timer to a new session: immediate first-write flush.
   - A resynced old session can donate `startupResynced=true`: the new session never resyncs.
   - Android focus pause/resume preserves the old timer/latch.
   - The check runs only after writes. A long pause, starvation interval, or worker delay can move its first execution far beyond startup; there is no upper deadline (`A:245–250,314–338`).

   Even normally, this provides at most one **attempt per uninterrupted latch period**. A short session may receive none; release can re-arm the same protocol session.

   **P2 — A failed operation is still latched and logged as a resync.**

   Any caught `IllegalStateException` skips the remaining operations, but execution still resets the counter, sets the latch, and logs `T380_AUDIO_RESYNC` (`A:334–337`). Successful pause+flush+play is therefore not established by that log.

   **P2 — `presMs` is not established as current speaker latency.**

   `presentationLatencyMs()` subtracts positions but ignores `audioTs.nanoTime` (`A:74–79`). Android permits a returned position whose presentation is committed for a future time. Thus equal written/timestamp positions can produce `presMs=0` while their presentation time is still ahead. [AudioTrack timestamp contract](https://developer.android.com/reference/android/media/AudioTrack#getTimestamp(android.media.AudioTimestamp))

   This directly undermines the reconciliation’s claim that these logs definitively locate the delay or distinguish phone-side residual latency.

   **P3 — Timestamp position also wraps; the reconciliation’s non-wrapping claim is incorrect.**

   Android specifies wrapping low-order 32-bit frame units for `AudioTrack` timestamps despite the Java `long` field. Neither subtraction extends that counter (`A:77,327–328`). [AudioTimestamp.framePosition](https://developer.android.com/reference/android/media/AudioTimestamp#framePosition)

   The existing unsynchronized `framesSinceFlush` resets/increments can also corrupt either diagnostic (`A:64,87,217,316`). Their numeric corruption no longer controls resync.

6. **Primary evidence and requested path checks**

   Every `activeSession` assignment found in A:

   | Transition | Evidence | Timer/latch reset? |
   |---|---|---|
   | Initial `-1` | `A:29,66–67` | Initial zero/false |
   | Incoming PCM selects session | `A:181–183` | **No** |
   | Playback-start selects session | `A:202–205` | **No** |
   | Guidance stop sets `-1` and drains | `A:210–215` | No; guidance excluded |
   | Full stop sets `-1` | `A:217` | **Yes**, unsynchronized with worker |

   Other relevant boundaries:

   | Path | Evidence | Assessment |
   |---|---|---|
   | Protocol focus release | `A:87–88` | Resets and flushes; races remain |
   | Protocol regain | `A:93–94` | No independent reset |
   | Android focus loss/gain | `A:104–110` | Pauses/restores flags; no re-arm |
   | Destroy | `A:158–164` | Sets stopping and pauses; cannot revoke an already-passed guard |
   | First-write timing | `A:314–324` | Recorded after the write attempt, even if incomplete; not necessarily first successful write |
   | Diagnostics → decision | `A:327–333` | Neither position nor `framesSinceFlush` feeds the condition |
   | Diagnostic helper safety | `A:75–79` | Null, unavailable timestamp, and `IllegalStateException` handled; wrap/accounting accuracy unresolved |

   **Guidance:** S creates type-3 media and separate type-1 guidance sinks (`S:841,845–849`). The new block excludes type 1 (`A:322`). T370→T380 diff leaves `finishDrain`, the guidance-stop branch, and draining logic unchanged. No direct guidance-drain regression found.

   **Does flushing address the downstream pipeline?** The source reuses the existing track and leaves the software queue intact (`A:334–336`). Android documents discarding queued unpresented audio; AOSP flush invokes both client-proxy and server-track flush. Calling this *only* a client-buffer operation would therefore also be unsupported. Neither source establishes a reset of this vendor’s entire mixer/HAL/hardware pipeline. [Flush contract](https://developer.android.com/reference/android/media/AudioTrack#flush()), [AOSP flush implementation](https://android.googlesource.com/platform/frameworks/av/+/f888020/media/libmedia/AudioTrack.cpp)

   The saved successful manual sequence also included stop, a new session, and a **1,149 ms arrival gap** (`L:485,508,510`). It does not isolate flushing as the successful mechanism.

   **Design opinion:** A single shot reasonably limits disruption during an experiment, but cannot guarantee sustained correction. Automatic repeated flushing should not depend on the current `presMs` calculation.

   Assuming valid, same-period timestamp accounting:

   | Outcome | Expected diagnostic behavior |
   |---|---|
   | Flush removes excess buffering and holds | Settled `presMs` falls and remains lower |
   | Buffering rebuilds | Settled `presMs` rises again; latch prevents another attempt |
   | Delay remains beyond what the timestamp represents | Audible delay may persist with low `presMs` |
   | Timestamp unavailable/reset/stale | `-1` or misleading transients; no decisive conclusion |

7. **Assumptions**

   Counterexamples assume callbacks can interleave with the playback worker. S posts protocol-focus work to its handler (`S:851–858`), while A starts a distinct worker (`A:143–144`). Saved logs also show callback and worker activity on different thread IDs (`L:331–335`).

   Session-change counterexamples assume no intervening release/full-stop. A permits those transitions; whether the native protocol guarantees otherwise is **UNKNOWN**.

8. **Unresolved uncertainties**

   **UNKNOWN:** actual race frequency, vendor timestamp accuracy, complete downstream flush behavior, refill behavior, native session-order guarantees, phone-side contribution, and T380’s audible outcome.

   No new P1 was established. The original measurement-gate reachability defect is removed (`A:332–333`).

9. **Exact diff summary**

   Reviewer diff: **none**.

   Read-only T370→T380 comparison confirmed additions to fields/helper, reset sites, buffer logging, write accounting, and the post-write resync block. Guidance draining was unchanged.

10. **Preservation checks performed**

   T380 AudioSink SHA-256 matched before and after review:

   ```text
   A1AC8A1C6A2E689A60EF57C6EA3A9E6D55440584C9F39E9278E564D3F4C08C97
   ```

   No files written, builds performed, device commands executed, key-material contents read, agents spawned, or milestones advanced. Frozen-artifact hashes were not reverified.