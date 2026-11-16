**The claim does not hold as written.** There are counterexamples for counter accounting, stop/resync ordering, and sustained correction. Whether T380 fixes the reported audible delay is **UNKNOWN**.

1. **Files inspected**

   References below:

   - **A:** [T380 AudioSink.java](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/test-prep/todo-tests-20261103/builds/T380-bundle/source/analysis/parallel-aa-receiver/src/com/google/android/projection/protocol/AudioSink.java).
   - **S:** T380-bundle `source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/AaSessionService.java`.
   - **P:** `analysis/parallel-aa-receiver/src/com/google/android/projection/protocol/PcmFrames.java`.
   - **L:** [T360 capture](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/installer-20261112/Hackura-Installer/car-logs/headunit-logs-20261114-203807/hackura-20261114-203729.txt).

   Also inspected: `PROJECT-RULES.md`, `AGENTS.md`; corresponding T370 AudioSink and manifests; T360 counter/write excerpts; T370/T380 source manifests; T380 `test.json`, `BundleTests.java`, saved host-test output; scoped prior-review and canonical-plan search matches; official Android documentation and AOSP implementation.

2. **Files changed**

   None.

3. **Commands run**

   Read-only `Get-Content`, `rg`, `rg --files`, `Get-FileHash -Algorithm SHA256`, `git status --short`, and `git diff --no-index`; source-manifest comparisons; official Android/AOSP web reads; in-memory JavaScript arithmetic/interleaving models.

   One dependency path was absent; I inspected its shared source instead. The Python launcher was unavailable; the models subsequently ran in JavaScript. A PowerShell custom-object comparison failed under constrained language mode and was rerun using string output. Initial workspace status was truncated.

4. **Tests run and results**

   No build, application test, or device test ran.

   In-memory models produced:

   ```text
   500-ms capacity: measured=500 ms; >700 trigger=false
   Lost-reset schedule: actual new head=2048; bogus latency=60000 ms
   32-bit wrap: actual latency=50 ms; reported=89478535 ms
   Refill counterexample: post-flush latency=1000 ms; second resync=false
   ```

   Existing `T380-bundle/host-test-output.txt:10` reports **PASS 289 bundle checks**. The new assertions at `BundleTests.java:162–163` check constant ranges, not AudioTrack behavior, races, or successful correction.

5. **Findings**

   **P1 — The measurement can miss the reported delay entirely.**  
   A requests `max(minimum, 500 ms)` of client buffering (`A:252–255`) but triggers strictly above 700 ms (`A:316`). With a 500 ms client buffer and a head representing server consumption, correctly counted occupancy cannot reach that threshold. AOSP’s ordinary PCM position path uses server-consumed frames; it is not universally a speaker-presentation measurement. [AOSP AudioTrack implementation](https://android.googlesource.com/platform/frameworks/av/+/f888020/media/libmedia/AudioTrack.cpp)

   Thus `AUDIO_LATENCY` is useful track-occupancy evidence, but calling it **true end-to-end latency** is unsupported. The callback receives a timestamp but does not use it (`A:158–172`), so phone-side audio age remains invisible.

   **P2 — Counter resets race the worker and can cause false or missed resyncs.**  
   `framesSinceFlush` is a plain `long` (`A:61`). Handler/native callbacks reset it (`A:73,203`), while the worker performs an unsynchronized read-modify-write (`A:302`).

   Concrete schedule: worker reads the old accumulated count for `+=`; callback resets it and flushes; worker stores the old count plus its increment. Subsequent subtraction compares an old-epoch count against a new head. The arithmetic model produces **60 seconds of bogus latency**, allowing a flush of current audio.

   The reverse mismatch is also possible: callback resets the count and pauses; worker, having already passed `A:297`, calls `play()` at `A:298`; callback’s subsequent `flush()` encounters a playing track and becomes a no-op. The retained head is then compared against a reset count, potentially clamping latency to zero. Android documents this flush no-op behavior. [AudioTrack API](https://developer.android.com/reference/android/media/AudioTrack#flush())

   **P2 — A stale resync can restart playback after stop and consume the next epoch’s latch.**  
   Worker passes `A:309`, computes excessive latency, then is delayed. Full stop executes `A:203–206`, clearing activity, resetting the latch, and pausing/flushing. Worker resumes at `A:316–319`, calls `play()`, and sets the latch true.

   There is no recheck of session, focus, stopping, or generation around this operation. The existing generation checks protect T370 trimming (`A:274–294`), not T380. This is consequential playback control, not merely diagnostic corruption.

   **P2 — “Startup only” and lasting correction are not guaranteed.**  
   The branch has no startup deadline (`A:309–321`). If no initial resync occurs, the first later threshold crossing can flush mid-song. Correct accounting below 700 ms prevents firing; the races above invalidate that protection.

   The resync also leaves the software queue intact. Remaining queued audio can immediately refill the track. If actual buffering exceeds 700 ms—permitted by the `minimum` selection—or later bursts rebuild it, the latch prevents another correction. Conversely, blocking writes alone do not force a buffer full when arrivals match consumption and no backlog remains. The decisive startup/refill behavior is **UNKNOWN**.

   Repeated firing could remove renewed excess buffering, but could also produce periodic skips when the threshold is below normal buffering. Single-shot operation limits disruption; it does not prove the correction persists.

   **P3 — Unsigned conversion is correct for startup, but wrap extension is missing.**  
   `& 0xFFFFFFFFL` correctly interprets the signed return (`A:313`). After approximately **24.855 hours at 48 kHz**, the head wraps while `framesSinceFlush` continues increasing. The model reports `89478535 ms` for an actual 50 ms occupancy. Diagnostics become bogus, and an unused latch permits a false resync. Android specifies the wrapping counter. [Playback-head API](https://developer.android.com/reference/android/media/AudioTrack#getPlaybackHeadPosition())

   Multiplication overflow is not a practical startup issue: it requires more than `9,223,372,036,854,775` outstanding frames, roughly 6,089 years at 48 kHz.

6. **Primary evidence and requested path checks**

   | Path | Evidence | Result |
   |---|---|---|
   | Creation / fallback release | `A:255–263` | Fresh initialized track resets count; fallback precedes PCM writes. |
   | T380 resync | `A:317–319` | Serial success resets count; exception still resets count and latches success. |
   | Focus-release flush | `A:73–74` | Reset exists, but precedes flush and races worker. |
   | Full-stop flush | `A:203–206` | Same problem. |
   | Guidance drain stop | `A:196–201,211–216,233` | Count is not reset; irrelevant to measurement because type 1 is excluded. |
   | Final stop/release | `A:327–330` | No reset; no subsequent worker measurement. |

   **Guidance:** S creates separate type-3 media and type-1 guidance sinks (`S:841,845–849`). Both measurement and resync are inside `audioType!=1` (`A:309`). Guidance draining is unchanged in the T370→T380 AudioSink diff. No direct guidance-drain regression found.

   **Legality and spin:** For an initialized stream track, isolated `pause(); flush(); play()` is legal. Flush discards all pending audio without distinguishing startup from current content. [AudioTrack API](https://developer.android.com/reference/android/media/AudioTrack) The T380 branch has no retry loop; P’s write loop terminates on failure or advances its offset (`P:10–16`). However, `A:317–320` reports resync success even after a caught exception.

   **Root-cause evidence:** L shows zero drops and approximately real-time byte progression (`L:356,389,402`). Those observations do **not** establish an empty queue: a constant backlog can coexist with both. Conditional on 8,192-byte packets—packet size unproven here—`L:356` implies approximately **1.963 seconds pending before AudioTrack consumption**.

   Manual pause/resume also coincides with stop, a new session, and a **1,149 ms arrival gap** (`L:485,508,510`). It does not isolate track flushing as the successful mechanism.

   Expected logs, assuming valid accounting:

   | Cause | Expected `AUDIO_LATENCY` |
   |---|---|
   | Excess buffering visible behind the reported head | High `ms`; falls after successful flush, possibly rebuilds |
   | Software backlog | Potentially ordinary track `ms`, high `queuedMs` |
   | Phone-side audio age | Ordinary `ms` and low `queuedMs` despite audible delay |
   | Downstream delay beyond the reported head | Can also show ordinary `ms`; indistinguishable from phone-side age using these fields alone |

7. **Assumptions**

   Counterexamples assume callbacks can interleave with the distinct playback worker. S explicitly posts protocol focus work to its handler (`S:851–858`); L records native callback and worker activity on different thread IDs (`L:331–335`).

   Capacity/refill models state their assumed buffer sizes. Shared P source is assumed to match the packaged dependency; packaged parity was not established.

8. **Unresolved uncertainties**

   **UNKNOWN:** actual car minimum/allocation, vendor playback-head semantics, race frequency, post-flush startup threshold, refill behavior, phone-side contribution, and T380 audible outcome. No T380 runtime evidence was established.

9. **Exact diff summary**

   Reviewer diff: **none**.

   Source-manifest comparison identifies exactly two changed source entries versus T370: `AudioSink.java` and `AndroidManifest.xml`. The manifest changes `0.9-T370` to `0.9-T380`; AudioSink contains the reviewed counters, logging, resets, and resync branch.

10. **Preservation checks performed**

   T380 SHA-256 values matched before and after review:

   ```text
   AudioSink.java
   DBF2DD929B9DF17FAC4C5B8FE83214859DA275CD267276514A08423506E2807B

   AndroidManifest.xml
   7902C340CBF361DD135B83A7C74292BF7F224A8A5F56DD3B8F7F73A0943D4E09
   ```

   No files were written, no frozen artifacts rebuilt, no key-material contents read, no device commands executed, and no milestones advanced. Frozen-artifact hashes were not reverified.