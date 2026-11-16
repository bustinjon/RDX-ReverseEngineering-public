# T360 start-up reboot-loop fix — CODEX ATTACKS

CLAUDE PROPOSES (the claim you must try to break):

"A momentarily full video-decoder input queue is transient backpressure, not a dead link. T360 makes
`AaSessionService.frame()` recover from it (drop the frame, ACK it to preserve flow-control credit, ask
the phone for a fresh picture) and keep the session alive — which stops the start-up restart loop — WITHOUT
leaking an AudioTrack/AudioFlinger resource, WITHOUT stalling the phone's video flow control, WITHOUT
breaking the legitimate teardown paths, and WITHOUT introducing a new way for the session to freeze or spin."

Find counterexamples. This is READ-ONLY. Do not build, do not touch any device, do not edit files.

## Background: the bug being fixed (primary evidence)
Car log `analysis/installer-20261112/Hackura-Installer/car-logs/headunit-logs-20261114-181708/hackura-20261114-181617.txt`
shows one process (pid 3405) whose AA session starts, runs a few seconds, then tears itself down and the
phone instantly reconnects — repeatedly (an endless restart loop that looks like AA rebooting on start):
- `:248-254` decoder starts, audio playing (session is genuinely up)
- `:261-263` `GAL: Decoder drop #1/#2/#3: No decoder input buffer` (transient OMX.TI stall)
- `:277-278` `Video queue full/unavailable` then `Shutting down AA session...`
- `:308-311` `P4_TCP_HANDOFF n=3` -> `T200_TCP_SESSION_START` (phone reconnects) ... loop repeats.
Later, after many restarts, AudioFlinger refuses new tracks: `:1726` `E AudioTrack: AudioFlinger could not
create track, status: -12` -> `AUDIO_PLAYBACK_FAILED` (audio dies). The clean single-session log
`...165532.txt` has no loop and clean audio.

## The change (new bundle T360-bundle, copied from T350-bundle)
Edits live in the bundle copy; the build switches this into the canonical tree
`analysis/parallel-aa-receiver/usb-helper/source/...`:
`analysis/test-prep/todo-tests-20261103/builds/T360-bundle/source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/AaSessionService.java`

Diff T350-bundle vs T360-bundle is 2 files only:
- `AaSessionService.java` — `frame(int,long,ByteBuffer)`: the `if (d == null || !d.frame(copy, ack))` branch
  previously did `log("Video queue full/unavailable"); abortIo();`. Now it does:
  `if (vs != null) vs.ack(s);` then a throttled log (`videoQueueFullDrops++ % 100`) then `pictureLost();`.
  New field `private int videoQueueFullDrops;`.
- `AndroidManifest.xml` versionName 0.9-T350 -> 0.9-T360.

## Key facts to verify against primary evidence (cite file:line)
1. **Flow-control correctness.** `VideoSink` sets `nativeSetMaxUnackedFrames(16)`. The enqueued path ACKs via
   the Runnable that runs in `VideoDecoder.loop()`'s `finally`. On the drop path the Runnable never runs (the
   packet was never enqueued), so T360 calls `vs.ack(s)` explicitly. Verify: is that EXACTLY one ACK per
   dropped frame (no double-ACK, no missing ACK), matching what the enqueued path would have sent? Could the
   explicit ACK plus a later ACK ever both fire for the same frame? See `VideoDecoder.frame()`,
   `VideoDecoder.loop()` finally, `VideoSink.ack()`.
2. **AudioTrack / AudioFlinger -12.** Confirm the `-12` exhaustion is downstream of the restart loop (many
   sessions each building an AudioTrack), NOT something `frame()`/`abortIo()` causes directly — i.e. does
   stopping the loop actually remove the audio failure, and does T360 introduce any NEW path that could keep
   an AudioSink/AudioTrack alive or re-create it in a tight loop? See `AudioSink.playLoop()` finally (release),
   and where AudioSink is created/stopped across session teardown.
3. **`pictureLost()` safety under flood.** `frame()` runs on the native GAL callback thread and can fire at
   video frame rate. `pictureLost()` posts to `handler` and self-throttles via `lastPictureAsk < 5000`. Verify:
   no unbounded handler-queue growth, no busy-spin, and the throttle really bounds `requestVideo()` calls.
   Is `videoQueueFullDrops++` (unsynchronized, native thread) a correctness problem or merely a benign log race?
4. **Did we remove a NEEDED teardown?** Enumerate when `d.frame()` returns false or `d == null` while
   `running`. Is `d == null` actually reachable during a running+selected session (decoder is assigned at
   `:878` before protocol start, nulled only in shutdown `:1709`)? If a genuinely DEAD decoder (permanently
   wedged, never drains) now returns false forever, does T360 leave AA frozen with no recovery over Wi-Fi
   (stuckWatch is disabled for tcpMode), and is that better or worse than the old loop? State the trade-off.
5. **The 3 remaining abortIo() callers are still correct and unchanged:** reader IO error / T350 link-dead
   (`readLoop` ~:1313-1320), writer IO error (`writeLoop` ~:1391-1394), phone `byeBye()` (~:1510). Confirm T360
   did not alter them and that none of them depended on the queue-full path.
6. **Could recovery-instead-of-teardown mask a REAL dead link?** If the phone is actually gone but the socket
   hasn't timed out yet, frames stop arriving (so `frame()` isn't even called) — so queue-full only happens
   while frames ARE arriving (link alive). Verify that reasoning: can queue-full occur on a dead link?
7. **Host test honesty.** `BundleTests.java` adds 2 checks that `VideoDecoder.frame()` fills a bounded queue
   then returns false. Does that actually exercise the backpressure signal T360 relies on, or is it vacuous?

## Report back
Files inspected, findings ranked P1/P2/P3 with file:line primary evidence, assumptions, unresolved
uncertainties, and whether the core claim holds. "Looks fine" without cited evidence is rejected.
