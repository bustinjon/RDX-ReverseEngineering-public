# T370 start-up audio backlog trim — CODEX ATTACKS

CLAUDE PROPOSES (the claim you must try to break):

"At a media session's playback start, Hackura now drops the stale audio backlog once so music begins
near-live instead of ~1-2 s behind (what a manual pause/resume did), WITHOUT stalling the phone's audio
flow control, WITHOUT trimming mid-song / on every song change, WITHOUT affecting guidance (TTS) or the
steady-state Wi-Fi burst tolerance, and WITHOUT a race that could drop live audio or loop."

Find counterexamples. READ-ONLY. Do not build, do not touch any device, do not edit files.

## Evidence the fix is based on (primary)
Clean T360 car log `analysis/installer-20261112/Hackura-Installer/car-logs/headunit-logs-20261114-203807/hackura-20261114-203729.txt`:
- Cold start: `Audio playback start` 20:32:33.937, first `PCM` 34.000 (playedBytes=0), `AUDIO_TRACK_READY`
  34.807 — ~0.8 s where PCM arrives but the track isn't built, so audio queues.
- A manual resume (`:508-510`) shows `T250_PCM_GAP ms=1149` — i.e. flushing on pause/resume is what clears the lag.
The queue is `ArrayBlockingQueue<Frame>(64)` (~2.5 s of media, T220). So a burst + the build window = ~1-2 s of
backlog played late until flushed.

## The change (T370-bundle, copied from T360-bundle) — 2 source files
`.../builds/T370-bundle/source/analysis/parallel-aa-receiver/src/com/google/android/projection/protocol/AudioSink.java`
- New `public static final long AUDIO_START_TRIM_MS = 500;` and `private volatile int syncedSession`.
- In `playLoop()`, before the normal `frames.poll(...)`: for media (`audioType!=1`) with `activeSession!=-1`,
  `focusAllowed`, and `syncedSession!=activeSession`, if `queuedMs() > AUDIO_START_TRIM_MS` drain the oldest
  frames (poll+discard, `dropped++`) until `queuedMs() <= AUDIO_START_TRIM_MS`, then set `syncedSession=activeSession`.
- `syncedSession` reset to `Integer.MIN_VALUE` in `requestProtocolFocus()` release and `playbackStopCallback()`
  full-stop, so a resume re-trims.
- `AndroidManifest.xml` versionName 0.9-T370. `BundleTests.java` adds 2 AUDIO_START_TRIM_MS checks.

## Attack these specifically (cite file:line)
1. **Flow control.** Confirm every dropped frame was ALREADY ACKed to the phone (dataAvailableCallback
   `finally{ nativeAckFrames }`), so discarding from the play queue cannot stall the phone. Any frame path that
   reaches the queue WITHOUT being ACKed?
2. **Trims only once per session.** Can `syncedSession!=activeSession` re-fire mid-session (e.g. activeSession
   flips to -1 and back, or a guidance interleave changes it) and trim LIVE audio mid-song? Trace every writer of
   `activeSession` (dataAvailableCallback, playbackStart/StopCallback, requestProtocolFocus) and whether a normal
   song change within one AA session keeps the same session id (so no re-trim).
3. **Guidance safety.** Confirm `audioType!=1` excludes the TTS/guidance sink, and the guidance drain path
   (drainingSession / finishDrain) is untouched.
4. **Race / thread-safety.** `queuedMs()` iterates `frames` while the native callback thread offers to it; the
   trim loop polls it. Can the trim under-drop, over-drop, spin, or NPE? Is `syncedSession` volatile enough, and
   can the trim ever run with a stale `activeSession` and discard a newer session's frames?
5. **Underrun risk.** With AUDIO_START_TRIM_MS=500 and a 0.5 s AudioTrack buffer, can the trim leave too little
   to start cleanly (immediate underrun/blip), or interact badly with the (currently off, PREBUFFER_MS=0) prebuffer?
6. **Does it actually fix the reported lag,** or only shift it — e.g. the track is still built lazily AFTER the
   first polled frame, so is one stale frame (~35 ms) still played before the trim, and does the trim run before
   that first write? Is the ordering right (trim before poll)?

## Report back
Files inspected, findings ranked P1/P2/P3 with file:line primary evidence, assumptions, unresolved
uncertainties, and whether the core claim holds. "Looks fine" without cited evidence is rejected.
