# T380 round 2 — CODEX ATTACKS the redesign

Round 1 (`CODEX-T380.md`) showed the getPlaybackHeadPosition-gated resync could never fire (P1) and had
counter/stop races (P2). Redesigned: the resync is now a TIMER-BASED one-shot (no measurement gate), and
getTimestamp is diagnostic-only. Reconciliation: `CLAUDE-T380-RECONCILE.md`.

CLAUDE PROPOSES: "T380 now does exactly one automatic pause+flush+play per media session, ~1200 ms after
playback starts, guarded so it can't operate on a stopped/other-session/paused track, can't fire mid-song,
and re-arms cleanly on resume — and the getTimestamp/head diagnostics can't corrupt the decision."

Find counterexamples. READ-ONLY. Do not build/edit/touch any device.

## Current code (T380-bundle AudioSink.java, in playLoop after the PCM write)
[Code block omitted; consult project-authored source.]
- `playStartMs`, `framesSinceFlush`, `startupResynced` reset to 0/false at focus-release and full-stop (which
  also pause+flush the track). `AUDIO_RESYNC_DELAY_MS=1200`, `AUDIO_LATENCY_LOG_MS=500`.
- `presentationLatencyMs()` = `getTimestamp(audioTs)` ? `(framesSinceFlush - audioTs.framePosition)` → ms : -1.
- `audioGeneration` (AtomicInteger) is incremented at focus-release and full-stop.

## Attack (cite file:line)
1. **Can the resync still hit a stopped/paused/other-session or just-flushed track?** Walk the window between
   the `audioGeneration.get()==gen` check and `player.pause()`. Does the gen bump at release/stop + the try/catch
   bound the damage to at most a harmless no-op? Any way it restarts a track that should stay stopped?
2. **Fire-once / re-arm.** Confirm it fires exactly once per session (startupResynced latch) and that playStartMs
   is set to the first media write per session and reset on both boundaries, so the next session re-arms at its
   own +1200 ms — not immediately, and not never.
3. **Mid-song.** Any path where playStartMs is stale (old session) so `now-playStartMs>=1200` fires on a brand
   new session's very first write (immediate flush) — e.g. playStartMs not reset on a session change that has no
   full-stop/release? List every activeSession transition and whether playStartMs resets with it.
4. **Diagnostics can't corrupt the decision.** Confirm `framesSinceFlush`/getTimestamp/getPlaybackHeadPosition
   feed only the log, never the resync branch. Is `presentationLatencyMs()` safe (null/exception/wrap)?
5. **Does the fix actually address the bug, and will it hold?** Given the delay is downstream of our writes, does
   pause+flush+play reset that pipeline, or only the client buffer? If it rebuilds, the latch blocks re-firing —
   is single-shot right, or should it re-fire on a measured rebuild? (Design opinion + what the presMs log should
   show in each case.)
6. **Guidance** unaffected (audioType!=1); finishDrain/draining untouched?

## Report back
Findings P1/P2/P3 with file:line evidence, assumptions, uncertainties, whether the claim holds.
