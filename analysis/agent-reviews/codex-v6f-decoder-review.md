v6f removes the permanent latch caused by an input-buffer timeout, but **recovery remains incomplete**. The main concerns are losing the initial key frame, racing config updates, and treating real codec errors as ordinary buffer shortages.

1. **Files inspected**

   Relevant contents of:

   - `PROJECT-RULES.md` and `AGENTS.md`.
   - [VideoDecoder.java](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/src/com/rdx/fullscreen/projection/VideoDecoder.java) — “decoder” below.
   - [AaSessionService.java](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/AaSessionService.java) — “caller”.
   - [Honda ProjectionRenderer.java](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/video/ProjectionRenderer.java).
   - [Receiver VideoSink.java](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/src/com/google/android/projection/protocol/VideoSink.java), plus searched excerpts of Honda’s corresponding facade.
   - [Car-test log](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/logs/car-test-20261028-v6e.txt).

   The requested Honda `video/VideoDecoder.java` is absent; `rg --files` identified `ProjectionRenderer.java` as the relevant implementation.

2. **Files changed**

   None.

3. **Commands run**

   - `Get-Content -LiteralPath PROJECT-RULES.md` and `AGENTS.md`.
   - `Get-Content` with numbered, scoped source excerpts.
   - `rg --files` for nested instructions and Honda video sources; `rg -n` for decoder operations, callbacks, ACK limits, and relevant log events.
   - `git status --porcelain=v1 --untracked-files=no`.
   - `git diff --`, `git diff --numstat --`, and `git diff --check --` for the decoder.
   - `Get-FileHash -Algorithm SHA256` for reviewed source/log files.
   - `Get-Command python, java, javac -ErrorAction SilentlyContinue`.
   - Browser lookups of official Android documentation, Android 5.1.1 AOSP source, and Oracle’s `BlockingQueue` contract.

   One ranged read failed under constrained PowerShell and was successfully repeated using a counter filter. Searching the nonexistent `analysis/parallel-aa-receiver/tests` directory returned a path error. Android Gitiles fetches failed; the Android 5.1.1 source was retrieved through the AOSP mirror.

4. **Tests run and results**

   - Decoder `git diff --check`: **PASS**, exit code 0; Git emitted an LF/CRLF advisory.
   - No compilation, executable unit tests, hardware tests, or device commands were run.
   - Retry and concurrency conclusions below are source-analysis results, not observed v6f runtime results.

5. **Findings**

   - **F1 — High; CONFIRMED mechanism, SUPPORTED rendering risk:** Config retries discard and acknowledge each associated video packet. If those discarded packets contain the initial IDR, successfully feeding config on frame 11 does **not** guarantee rendering. There is no key-frame retention, detection, or resynchronization in this decoder.
   - **F2 — High; CONFIRMED:** Config updates can be lost. The worker can capture config A, block while feeding it, receive a concurrent update to B with `configFed=false`, then overwrite that reset with `configFed=true`. B can subsequently be skipped. Making both fields volatile alone would not fix this interleaving.
   - **F3 — High; CONFIRMED:** Recovery conflates buffer shortage with genuine codec failure. Config feeding catches every `Exception`; regular feeding catches every `IllegalStateException`, including `MediaCodec.CodecException`. Separately, an exception from `drain()` exits the entire worker.
   - **F4 — Medium; CONFIRMED:** Frames can be submitted before explicit config: `ensureConfig()` returns true when `config==null`. Whether a particular frame contains sufficient in-band initialization is **UNKNOWN**.
   - **F5 — Medium; CONFIRMED ownership defect, SUPPORTED starvation risk:** After acquiring an input index, the capacity-error path abandons that index without submitting it or resetting the codec. Repeated failures can exhaust available input buffers. The capacity check predates v6f; the new retry behavior does not repair it.
   - **F6 — Medium; CONFIRMED:** Mid-stream config changes have neither FIFO ordering relative to queued frames nor a codec reconfiguration procedure. A newer config can be applied ahead of older queued frames. Actual TI support for a particular configuration change is **UNKNOWN**.
   - **F7 — Low; CONFIRMED:** Config-failure logging is unthrottled. `"Config feed deferred"` is logged on every failure. The config-drop counter logs drop 1 and every 100th, rather than the stated first three.
   - **F8 — Evidence correction; CONFIRMED:** The log’s `1525` count describes **outbound transport packets**, not phone-sent video frames. The supplied evidence does not establish the number of video access units received.

6. **Primary evidence for each finding and review question**

   **F1 / retry behavior.** [Decoder lines 41–52](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/src/com/rdx/fullscreen/projection/VideoDecoder.java:41) leave `configFed=false` after a failed feed. [Lines 81–101](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/src/com/rdx/fullscreen/projection/VideoDecoder.java:81) retry for each subsequent dequeued packet, discard that packet on config failure, and always invoke its ACK.

   Consequently, with stable config and a functioning codec, ten failures followed by success cause config to be queued before packet 11. Subsequent packets bypass config feeding once `configFed=true`. **That proves submission order, not successful rendering.** Android requires a suitable key frame at stream startup; for AVC this is an IDR. [MediaCodec stream-boundary documentation](https://developer.android.com/reference/android/media/MediaCodec#seeking--adaptive-playback-support)

   **F2 / thread safety.** [Decoder fields and setter](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/src/com/rdx/fullscreen/projection/VideoDecoder.java:17) contain plain `config` and `configFed`; [lines 43–47](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/src/com/rdx/fullscreen/projection/VideoDecoder.java:43) separate the captured header from the later flag write. This permits the A/B interleaving described above even under sequentially consistent execution.

   There is an important qualification: when the same reader calls `config()` and then successfully offers a frame, queue publication makes preceding writes visible after the worker removes that frame. Thus the ordinary initial-config sequence has publication support; the whole implementation is still **not race-free**, especially while processing an older packet. [BlockingQueue memory-consistency contract](https://docs.oracle.com/javase/8/docs/api/java/util/concurrent/BlockingQueue.html)

   `dropCount` is accessed only within the worker’s `loop()`; its thread confinement is **CONFIRMED** by [lines 77–103](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/src/com/rdx/fullscreen/projection/VideoDecoder.java:77).

   **F3 / exception and lifecycle recovery.** [Decoder lines 94–106](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/src/com/rdx/fullscreen/projection/VideoDecoder.java:94) show:

   - An ordinary input timeout with non-null codec does not set `broken`; another packet is attempted.
   - `drain()` sits outside the per-packet recovery block. Its exception reaches the outer catch and terminates the worker.
   - `codec==null` does not uniquely mean codec creation failed: `"Surface unavailable"` also reaches permanent `broken=true`.
   
   Moreover, [codec assignment precedes configure/start](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/src/com/rdx/fullscreen/projection/VideoDecoder.java:33). If either throws `IllegalStateException`, the non-null reference prevents `broken=true`, after which the code attempts output dequeue on an unsuccessfully started codec.

   `CodecException` extends `IllegalStateException`; API-supported handling distinguishes transient, recoverable, and fatal errors. Retrying all of them unchanged is insufficient. [CodecException contract](https://developer.android.com/reference/android/media/MediaCodec.CodecException)

   **F4 / absent config.** [Decoder line 44](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/src/com/rdx/fullscreen/projection/VideoDecoder.java:44) returns true for null config, leading directly to regular `feed()` at line 87.

   **F5 / acquired-buffer ownership.** [Decoder lines 56–61](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/src/com/rdx/fullscreen/projection/VideoDecoder.java:56) acquire an index, then throw on insufficient capacity without returning ownership. The API transfers ownership on dequeue and warns that retained buffers can stall processing. [Android 5.1.1 MediaCodec source, lines 88–106](https://raw.githubusercontent.com/aosp-mirror/platform_frameworks_base/android-5.1.1_r38/media/java/android/media/MediaCodec.java)

   **F6 / mid-stream config.** [The setter](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/src/com/rdx/fullscreen/projection/VideoDecoder.java:31) replaces shared state outside the packet queue. [Packet processing](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/src/com/rdx/fullscreen/projection/VideoDecoder.java:85) consults that latest state regardless of packet age. No stop/configure/start or adaptive-playback capability check exists.

   Android 5.1.1 documents stop/configure/start for nonadaptive format changes; adaptive AVC size changes require SPS/PPS and IDR together in a regular input buffer. [Android 5.1.1 MediaCodec source, lines 139–189](https://raw.githubusercontent.com/aosp-mirror/platform_frameworks_base/android-5.1.1_r38/media/java/android/media/MediaCodec.java)

   **F7 / logging.** Compare unconditional [line 51](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/src/com/rdx/fullscreen/projection/VideoDecoder.java:51), config-drop condition at line 91, and regular-drop condition at line 96.

   **F8 / actual failure evidence.** The log records config receipt at [line 6607](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/logs/car-test-20261028-v6e.txt:6607), decoder startup at line 6737, and the input-buffer failure at line 6747. [Line 10759](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/logs/car-test-20261028-v6e.txt:10759) explicitly says `"Transport write ended after 1525 frames"`. The caller’s [writeLoop, lines 407–420](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/AaSessionService.java:407), increments this counter per `receiver.outgoing()` result. No first-render notification was found.

   **Timeout/API assessment — CONFIRMED legality; SUPPORTED tuning choice.** The healthy path correctly calls configure, start, then dequeue. Positive timeout arguments are microseconds: 500ms and 50ms are valid finite waits, and neither imposes an unconditional delay when a buffer is already available. Their sufficiency for this TI decoder is **UNKNOWN**. [MediaCodec dequeue contract](https://developer.android.com/reference/android/media/MediaCodec#dequeueInputBuffer(long))

   Separately submitting flagged codec config after startup is supported, including when creating the codec by name. This format supplies no `csd-*` entries, so automatic-plus-explicit duplication is not present. Actual config bytes and vendor acceptance remain unverified. [Decoder lines 36–38 and 61](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/src/com/rdx/fullscreen/projection/VideoDecoder.java:36); [Android 5.1.1 API source, lines 119–128](https://raw.githubusercontent.com/aosp-mirror/platform_frameworks_base/android-5.1.1_r38/media/java/android/media/MediaCodec.java)

   **Honda comparison — CONFIRMED decompiled-source behavior.** Honda queues config into the same pending-input FIFO at [lines 213–232](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/video/ProjectionRenderer.java:213). Its input loop uses **100,000µs per dequeue**, dropping after **11 consecutive failures** because the condition is `dequeFails > 10`. It retains the same input during those retries. Its first successful submission uses config flag `2`; subsequent submissions use `0`. [Lines 383–431](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/video/ProjectionRenderer.java:383)

   Honda also starts separate output and input threads at [lines 300–305](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/video/ProjectionRenderer.java:300). v6f’s single worker postpones output draining while waiting for input.

   **Queue overflow — CONFIRMED behavior; policy correctness UNKNOWN.** The queue holds 24 packets and `frame()` uses nonblocking `offer()`. A rejected offer causes [caller lines 505–511](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/AaSessionService.java:505) to invoke `abortIo()`, which closes transport and schedules shutdown at lines 443–449. This is consistent with a fatal-overflow policy, but provides no recovery from temporary queue pressure.

   The receiver requests a maximum of **16 unacknowledged frames** at [VideoSink line 25](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/src/com/google/android/projection/protocol/VideoSink.java:25). If enforced for one stream, that should constrain queue pressure below 24; native enforcement and cross-session behavior are **UNKNOWN**. The longer waits alone do not prove overflow will occur.

7. **Assumptions**

   - Callback threading follows the supplied reader-thread description; Java forwarding is direct, but native callback scheduling was not audited.
   - The IDR-loss example is a counterexample, not a claim about the unrecorded frame contents.
   - Honda comparison describes the supplied decompilation, not independently verified runtime behavior.

8. **Unresolved uncertainties**

   TI first-buffer readiness time; validity of the supplied SPS/PPS bytes; received video-frame count and IDR cadence; adaptive-playback support; native flow-control enforcement; and actual v6f rendering are **UNKNOWN**.

9. **Exact diff summary**

   Reviewer diff: **none**. The pre-existing decoder change against HEAD reports **30 insertions, 6 deletions**; this is not an independently established v6e-to-v6f artifact comparison.

10. **Preservation checks performed**

   Tracked-file status was unchanged between observations. Repeated SHA-256 checks matched for decoder, caller, Honda renderer, and failure log. Reviewed decoder hash:

   `E1A8EA65322AEBC3CB197787B13F0C80E5573F7E214028949B2EF128B068B6AE`

   No files were written, frozen artifacts rebuilt, key material opened, devices accessed, milestones advanced, or agents spawned. Frozen-artifact hashes were not reverified.