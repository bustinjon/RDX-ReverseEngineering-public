# T380 round 3 — CODEX ATTACKS the generation-keyed resync

Rounds 1-2: P1 (unreachable threshold) fixed by a timer; P2 cluster (session-bookkeeping leaks across
stop/resume) fixed by rekeying the whole resync to `audioGeneration`. Reconciliation:
`CLAUDE-T380-RECONCILE.md`. FOCUSED pass on the rewrite.

CLAUDE PROPOSES: "Keying the one-shot resync to `audioGeneration` makes it fire exactly once per fresh playback
period (not per song, not never, not immediately on a new period), with no stale timer/latch leaking across a
stop/resume, and the only residual is a benign sub-instruction TOCTOU."

Find counterexamples. READ-ONLY. Do not build/edit/touch any device.

## Current code (T380-bundle AudioSink.java, in playLoop after the PCM write)
[Code block omitted; consult project-authored source.]
- `audioGeneration` (AtomicInteger) is `incrementAndGet()` on focus-release and full-stop (both also pause+flush
  the track and clear the queue). It is NOT bumped on a song change (new activeSession via data-arrival /
  playback-start keeps the same generation).
- `resyncArmedGen`, `resyncFiredGen` init to -1; `resyncArmMs`, `framesSinceFlush` to 0. All touched only on the
  playback worker thread (this block + track creation). `AUDIO_RESYNC_DELAY_MS=1200`.

## Attack (cite file:line)
1. **Fire-once-per-period.** Confirm: exactly one resync per generation; a NEW generation (after release/stop)
   re-arms (resyncArmedGen!=gen) and fires ~1200 ms after its first write, not immediately (resyncArmMs set that
   same iteration) and not never. A song change (same generation) does NOT re-fire.
2. **Immediate-flush on a new period?** Any path where `resyncArmedGen==gen` holds for a NEW playback period so
   the timer is stale and `now-resyncArmMs>=1200` fires on its first write? (I.e., can a generation value repeat
   without an intervening arm? AtomicInteger only increments — consider int wrap after 2^32 release/stops.)
3. **Stale resync across stop.** Walk the window between `audioGeneration.get()==gen` (re-check) and `pause()`.
   Confirm the worst case is pause/flush/play on an already-flushed track with activeSession=-1 (benign, no new
   audio written, destroy cleans up), bounded by try/catch — not e.g. resurrecting a released track or crossing
   into a new generation's audio.
4. **Android focus loss/gain** (onAudioFocusChange, which pauses but does NOT bump generation): after a transient
   loss+gain within one generation, does the resync still behave (fire once if not yet fired; not re-fire if
   already fired)? Is that acceptable?
5. **Latch-before-op.** Confirm setting `resyncFiredGen=gen` before the try means a thrown/caught pause/flush/play
   does not retry every subsequent write, and does not wrongly log success.
6. **Diagnostics isolation + safety.** Confirm presMs/trackMs/getPlaybackHeadPosition/getTimestamp feed only the
   log; `presentationLatencyMs()` nanoTime advance + the `<0 || >10s → -1` clamp are correct and exception-safe.
7. **Guidance** excluded (audioType!=1); finishDrain/draining untouched.

## Report back
Findings P1/P2/P3 with file:line evidence, whether the claim holds, and remaining uncertainty.
