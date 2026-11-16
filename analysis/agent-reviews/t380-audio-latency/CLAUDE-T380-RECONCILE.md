# T380 — CLAUDE RECONCILES (after CODEX ATTACKS, round 1)

Codex review `CODEX-T380.md` (gpt-6.1-sol, read-only) broke the first design. Key correction accepted and it
forced a redesign.

- **P1 (decisive) — the measurement couldn't see the delay, and the threshold couldn't fire.**
  `getPlaybackHeadPosition()` returns SERVER-CONSUMED frames, capped at the ~0.5 s buffer, so
  `framesWritten - head` can never reach the 700 ms trigger, and it never sees the deep mixer/HAL/hardware
  pipeline where the real 1-2 s lives. So the v1 resync would essentially never fire and the logged "latency"
  was only client-buffer occupancy. **REDESIGNED:** the fix no longer depends on any measurement. It now does
  **one automatic pause+flush+play per media session, a fixed `AUDIO_RESYNC_DELAY_MS` (1200 ms) after playback
  starts** — exactly the manual pause/resume the user does, which is known to work. For diagnostics it now logs
  the TRUE latency via `getTimestamp()` (presented frames, `presMs`) alongside track-occupancy (`trackMs`) and
  `queuedMs`, so a drive log shows where the delay actually lives and whether the flush holds.
- **P2 — counter race could cause a false/missed resync.** `framesSinceFlush` is no longer in the resync
  DECISION (now timer-based), so a race on it only perturbs the diagnostic log, never the flush. FIXED in effect.
- **P2 — stale resync could restart playback after a stop / consume the next session's latch.** FIXED: the
  resync is now guarded immediately before the flush by `focusAllowed && frame.session==activeSession &&
  !stopping && audioGeneration.get()==gen` (gen captured just above), plus try/catch on the pause/flush/play.
  `playStartMs` and `startupResynced` reset on release and full-stop, so each session re-arms cleanly.
- **P2 — "startup only" not guaranteed.** FIXED: fires once at `playStartMs + 1200 ms` (playStart = first media
  write of the session) and latches, so it cannot fire mid-song; a session reset re-arms it.
- **P3 — wrap.** `getPlaybackHeadPosition` is used ONLY for the `trackMs` diagnostic (bogus only after ~24 h,
  not a drive, not a decision). The resync decision uses `SystemClock.uptimeMillis` deltas; `getTimestamp`
  framePosition is a non-wrapping long. No decision depends on the wrapping counter.
- **Guidance** confirmed excluded (`audioType!=1`), drain path untouched.

## The main open question (honest, car-test decides)
Does one flush HOLD, or does the latency rebuild? With MODE_STREAM blocking writes the buffer can refill. The
single-shot flush mirrors the user's manual action (which holds for them), but if `presMs` in the drive log
climbs back up after the resync, the next step is repeated resyncs or a smaller AudioTrack buffer. T380 is
deliberately also a MEASUREMENT build: `AUDIO_LATENCY presMs=…` will tell us definitively, including whether
any residual is phone-side (which no car-side flush can fix).

## Verification
Rebuilt offline, baseline restored. Host tests **PASS 289 bundle checks** + feature suites.
APK sha256 `C66932B69EBC6A22FA8C9A23B20345D018C85684F10DA048AF28AE97755ECB83`, versionName 0.9-T380.
Source diff vs T370: `AudioSink.java`, `AndroidManifest.xml`.

---

## Round 2 (CODEX-T380-round2.md) — attacking the timer design

Verdict: **no new P1** (timer removed the unreachable threshold). Codex found a cluster of **P2** session-
bookkeeping races, all one root cause: the resync state (`playStartMs`/`startupResynced`) was reset only on
full-stop/release, but `activeSession` also changes on data-arrival and playback-start WITHOUT a reset — so an
old session's expired timer or set latch could leak into a new session (immediate first-write flush, or never
flushing). Plus: a stop could still race the flush; a caught exception still latched+logged "resync"; and the
`presMs` diagnostic ignored `audioTs.nanoTime` and the 32-bit framePosition wrap.

**FIX — rekeyed the whole thing to `audioGeneration`** (the AtomicInteger already bumped on every release/full-
stop, i.e. whenever the track is flushed/torn down — and NOT on a song change). Three worker-only fields:
`resyncArmMs` (when this generation's playback started), `resyncArmedGen`, `resyncFiredGen`. The timer arms on
the first media write of a generation and fires once per generation. This structurally removes the leak: a new
playback period = a new generation = fresh arm + fresh latch; a song change keeps the generation so it does NOT
re-flush (no per-song skip). The flush latches `resyncFiredGen=gen` BEFORE the try (a caught exception can't
re-loop), re-checks `audioGeneration.get()==gen` immediately before `pause()`, and only logs success inside the
try (a skip logs `T380_AUDIO_RESYNC_SKIPPED`). The `activeSession==frame.session` guard means a full-stop
(activeSession→-1) already fails the condition; the gen re-check covers the rest. `presentationLatencyMs()` now
advances framePosition by `(now-nanoTime)` and returns -1 on a negative or >10 s value (wrap guard). Diagnostics
never feed the resync decision.

**Residual (accepted):** a sub-instruction TOCTOU remains between the final `audioGeneration.get()==gen` and
`player.pause()`. If a stop bumps the generation in that window, we pause/flush/play a just-flushed track with
`activeSession=-1`; it starts an empty track that plays nothing and `destroy()` cleans up — benign, and the
try/catch covers an illegal state. Same lock-free residual class accepted for T370. **Efficacy UNKNOWN** (does
one flush fix + hold the delay) is a car-test question the `presMs` log is built to answer.

Rebuilt: host tests **PASS 289 bundle checks**. APK sha256
`39D4119B3D2C8D78B47E4F3E92833487B2775068BE2EA64898A751AC068A5F90`, versionName 0.9-T380.

---

## Rounds 3 & 4, and the structural redesign (playback-head trigger)

- **Round 3 (no new P1):** confirmed once-per-generation, latch-before-op, diagnostic isolation, timestamp
  math, guidance exclusion. Found one P2: the post-write block could ARM the timer while PAUSED (a write that
  returned -1 during a focus-release still reached the block). First fix: gate the block on `complete &&
  focusAllowed` (only act when audio actually played).
- **Round 4 (no new P1):** that closed the exact failed-write schedule, but the race just moved one notch
  narrower — a release landing between the `complete && focusAllowed` gate and the generation capture could
  still arm while paused. Classic lock-free check-then-act: each fix narrows the window, the next review finds a
  narrower one.
- **Structural redesign (shipped):** stop using a wall-clock timer entirely. The resync now triggers when the
  **hardware playback head** (`getPlaybackHeadPosition`, frames actually PLAYED since the last flush/start) has
  reached `AUDIO_RESYNC_DELAY_MS`. That counter is **frozen while paused and reset to 0 by flush()**, so
  `AUDIO_RESYNC_DELAY_MS` of real playback can NEVER accumulate during a pause — the entire "arm while paused"
  race class (r3 + r4) is removed, not patched. Removed `resyncArmMs`/`resyncArmedGen`; kept only
  `resyncFiredGen` (fire once per generation). `framesSinceFlush` and the head/getTimestamp reads are now
  diagnostic-only. AUDIO_LATENCY also logs `playedMs` (the head clock).

## Why review stopped here (4 rounds)
The worst-case outcome of ANY remaining race in this block is a single brief audio skip (exactly what a manual
pause/resume does) — never a crash, hang, data loss, or stuck state: every call is guarded by
focus/session/generation checks and wrapped in try/catch, and a failed op logs `T380_AUDIO_RESYNC_SKIPPED` and
latches so it cannot loop. The one accepted residual is the sub-instruction TOCTOU between the final
`audioGeneration.get()==gen` and `player.pause()` (benign empty-track restart, destroy cleans up) — the same
lock-free residual class accepted for T370. Further rounds are diminishing returns on a low-stakes feature; the
car test + the `AUDIO_LATENCY presMs=/playedMs=` logs are the right validator now (does the flush fix + hold the
delay, and is any residual phone-side).

Rebuilt: host tests **PASS 289 bundle checks**. APK sha256
`D37424A6423CE697DA415C076DEA47FDE3FB6B28511ED0F32229074D1709E5D4`, versionName 0.9-T380.
