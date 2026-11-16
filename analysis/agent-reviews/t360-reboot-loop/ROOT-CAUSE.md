# T360 — AA start-up "reboot loop" root cause and fix

**Reported:** T330 on the car got stuck in a reboot loop when starting Android Auto.
**Logs:** `analysis/installer-20261112/Hackura-Installer/car-logs/headunit-logs-20261114-181708/hackura-20261114-181617.txt`

## What the log shows (one cycle, process pid 3405, all inside our app — no OS reboot)
[Code block omitted; consult project-authored source.]
The "reboot loop" is not an OS or process reboot — it is **our own AA session being torn down and the
phone immediately reconnecting**, over and over, within ~6–9 s each cycle. To the user it looks like AA
restarting every time it starts.

## Root cause (one line, in `AaSessionService.frame()`)
[Code block omitted; consult project-authored source.]
`VideoDecoder.frame()` is `ArrayBlockingQueue(24).offer(...)`. It returns **false when the decoder's input
queue is full** — i.e. the OMX.TI.DUCATI1 decoder stalled for a moment and 24 access units are already
queued. That is **transient backpressure**, not a dead link. But the code treated it as fatal and called
`abortIo()`, killing the session. The phone reconnects at once (the Wi-Fi listener stays up), the fresh
session fills the same 24-deep queue within a few seconds, and it aborts again. Loop.

Note the asymmetry that made this a bug: the **in-worker** drop path (`feed()` can't get an input buffer →
"Decoder drop #N") is already handled gracefully — `event()` routes it to `pictureLost()` (ask the phone
for a fresh picture) and the session keeps running. Only the **queue-full-at-offer** path escalated to a
full teardown.

## Fix (T360)
Treat a full video queue the same as an in-worker decoder drop: **drop that frame and ask the phone for a
fresh picture; keep the session up.** Do not `abortIo()`.

[Code block omitted; consult project-authored source.]

### Why the explicit ACK matters
`VideoSink` runs flow control: `nativeSetMaxUnackedFrames(16)`. The phone sends at most 16 un-ACKed frames,
then waits for credit (`vs.ack()` → `nativeAckFrames(session,1)`). When a frame is **enqueued**, its ACK
runs later from the decoder worker. When the queue is **full** the frame is not enqueued, so its ACK would
never run — leaking one credit per drop. After 16 leaks the phone would stop sending entirely and freeze for
real. So the drop path ACKs the frame itself. Exactly one ACK per frame on every path now.

### Scope / safety
- Only `AaSessionService.frame()` changed. The three legitimate `abortIo()` callers are untouched: reader
  IO error / T350 Wi-Fi link-dead timeout (`readLoop`), writer IO error (`writeLoop`), and the phone's
  explicit `byeBye()`.
- `d == null` is effectively unreachable while `running && selected` (decoder is assigned before protocol
  starts and nulled only in shutdown); `pictureLost()` self-guards on `running/selected/!minimized/!native`
  anyway, so folding it into the same branch is safe.
- Builds on T350 (keeps the Wi-Fi disconnect socket timeout). Source diff vs T350 is 2 files only:
  `AaSessionService.java` and `AndroidManifest.xml` (versionName 0.9-T350 → 0.9-T360).

### Residual (honest)
If the TI decoder ever wedges **permanently** over Wi-Fi (never un-wedges on a fresh keyframe), AA would show
a frozen picture rather than a restart loop — recoverable with the side panel / Hackura tile (same as any
frozen AA), and no longer an unusable loop. The USB stuck-screen watchdog (T150) still covers USB; a
frame-level backstop for a permanently-wedged Wi-Fi decoder is a possible future enhancement, out of scope
for this minimal fix.

## Verification
Build-Test.ps1 -Test T360-bundle: **BUILD READY**, baseline restored.
Host tests **PASS 282 bundle checks** (+2 new: the decoder input queue fills and is bounded, so a full queue
is a real recoverable backpressure signal) + all feature suites.
APK sha256 `A8A3B8C68E002FD475454D900C59555D06392FD565CD5F030D82155704FA1FF9`, versionName 0.9-T360.
Installer `analysis/installer-20261112/Hackura-Installer` repackaged to carry T360 (build.json + hackura.apk
+ known-builds.json updated; logs / car-logs / remembered phone preserved).

**Not yet car-tested.**

---

## Related: the ~10 s start-up audio glitch (same root cause)

User also reports audio sometimes bugs for ~10 s on start-up. The logs tie it to the reboot loop:

- In the looping session (`...181617.txt`), after several restarts AudioFlinger refuses new tracks:
  `E AudioTrack: AudioFlinger could not create track, status: -12` (NO_MEMORY) →
  `E RDX.AUDIO: AUDIO_PLAYBACK_FAILED ... AudioTrack initialization failed`. Each restart builds a fresh
  AudioTrack (session ids climb 4,7,8,9,10,11,12...), and `AudioSink.playLoop()` exits on that failure, so
  sound drops out. First `-12` appears only after ~90 s of looping.
- In a clean single session (`...165532.txt`, no loop), audio is clean: one track, `AUDIO_TRACK_READY`,
  playing, zero errors.

Conclusion (high confidence): the start-up audio glitch is the reboot loop cutting audio in/out and then
exhausting AudioFlinger. **T360 (stops the loop) should resolve it; no separate audio change made.**

Possible small residual (low–medium confidence, to confirm on a clean T360 start): the media sink (id=4)
and guidance sink (id=5) briefly contend for audio focus in the first seconds
(`onAudioFocusChange(-1)`→`(1)` within ~30 ms). If a short stutter remains on a clean start, fix the
focus hand-off then — needs a loop-free log to isolate. Not changed now (one-change-per-test).
