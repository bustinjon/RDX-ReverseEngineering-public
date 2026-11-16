# T380 audio-latency measure + auto-resync — CODEX ATTACKS

Context: T370 tried to fix a ~1-2 s start-up audio delay by trimming our software frame queue. Car test on
T370 shows it did NOT help, and the T360 log shows why: at cold start there are ZERO dropped frames and writes
keep real-time pace, so our queue stays near-empty — the latency is buffered INSIDE the AudioTrack (the phone's
start-up burst fills it; MODE_STREAM blocking writes keep it full), which only a flush clears (why manual
pause/resume works). T380 measures the true latency from the hardware playback head and auto-flushes once.

CLAUDE PROPOSES: "T380 correctly measures the AudioTrack's buffered latency (framesWritten-since-flush minus
getPlaybackHeadPosition), logs it, and once per media session flushes to drop it — without miscounting across
flush/stop/resume, without dropping live steady-state audio, without a state-exception or spin, and without
breaking guidance."

Find counterexamples. READ-ONLY. Do not build/edit/touch any device.

## The change (T380-bundle AudioSink.java, 2 files incl. manifest version)
- Fields: `long framesSinceFlush` (PCM frames written since the track last (re)started/flushed),
  `long lastLatencyLogMs`, `volatile boolean startupResynced`. Constants `AUDIO_RESYNC_MS=700`,
  `AUDIO_LATENCY_LOG_MS=500`.
- Track creation: `framesSinceFlush=0` and AUDIO_TRACK_READY now logs `minBuf/buf/bufMs`.
- Write callback: on each `player.write` success, `framesSinceFlush += written/(channels*2)`.
- After the write, for media (`audioType!=1`), `player!=null`, `frame.session==activeSession`, throttled to
  every `AUDIO_LATENCY_LOG_MS`: `head = getPlaybackHeadPosition() & 0xFFFFFFFFL`;
  `latMs = framesSinceFlush>head ? (framesSinceFlush-head)*1000/sampleRate : 0`; log AUDIO_LATENCY; if
  `!startupResynced && latMs>AUDIO_RESYNC_MS` → `player.pause(); player.flush(); player.play();`
  `framesSinceFlush=0; startupResynced=true;` log T380_AUDIO_RESYNC.
- `framesSinceFlush=0; startupResynced=false` appended to BOTH reset sites: focus release (which also
  `track.pause();track.flush()`) and full-stop playbackStopCallback (same). Guidance drain `finishDrain()`
  (`track.stop()`) is guidance-only (audioType==1) and untouched.

## Attack (cite file:line)
1. **Head accounting.** `getPlaybackHeadPosition()` resets to 0 on flush(), stop(), release(). Is `framesSinceFlush`
   reset to 0 at EVERY place the track is flushed/stopped/released so the subtraction never goes wrong? Walk:
   creation, the T380 resync flush, focus-release flush, full-stop flush, finishDrain stop, final release. Any
   path where the head resets but framesSinceFlush doesn't (→ huge bogus latMs → false resync), or vice-versa
   (→ negative, clamped to 0 → missed resync)?
2. **Unsigned / wrap.** `getPlaybackHeadPosition()` returns int; `& 0xFFFFFFFFL`. Is latMs correct for the
   startup window? Any overflow in `(framesSinceFlush-head)*1000`?
3. **Resync safety.** Is `pause(); flush(); play()` legal here (track is playing)? Can flush() drop LIVE
   steady-state audio rather than only start-up latency? It fires only when latMs>700 and once per session —
   confirm it can't fire mid-song on a healthy low-latency stream, and that one resync cannot loop/thrash.
4. **Does one resync hold, or will the latency rebuild?** With MODE_STREAM blocking writes and a 0.5 s buffer,
   after flush the buffer refills. Reason about whether latMs will climb back above 700 ms (it can't re-fire —
   startupResynced latches — but will the delay come back?). Is the single-shot design sufficient, or should it
   be allowed to re-fire? State the trade-off; this is the main design risk.
5. **Guidance.** Confirm `audioType!=1` excludes guidance from both the measurement and the resync, and
   finishDrain/draining is unaffected.
6. **Threading.** framesSinceFlush is written only on the worker thread (write callback + resets that run on
   callback threads). Are the resets (focus release / full stop run on handler/native threads) racing the
   worker's increments in a way that corrupts the measurement or causes a false resync? Does it matter given
   latMy is diagnostic + a one-shot flush?
7. **Did we fix the reported bug?** Given the evidence (queue near-empty, real-time writes, flush fixes it), is
   measuring head-vs-written the right latency, and is flush the right lever — or could the ~1-2 s be partly
   phone-side (which a car-side flush cannot fix)? What would the AUDIO_LATENCY log look like in each case?

## Report back
Findings P1/P2/P3 with file:line evidence, assumptions, uncertainties, whether the claim holds.
