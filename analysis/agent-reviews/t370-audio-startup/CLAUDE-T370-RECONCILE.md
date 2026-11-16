# T370 audio start-trim — CLAUDE RECONCILES (after CODEX ATTACKS, round 1)

Codex review `CODEX-T370.md` (gpt-6.1-sol, read-only) broke the first placement with two real counterexamples.

- **P1 (real) — the trim could run on an empty queue and mark the session synced BEFORE the track was built,**
  so the ~0.8 s construction backlog (the very thing it targets) was never trimmed. The trim sat at the top of
  the loop, before the lazy AudioTrack construction. **FIXED:** moved the trim to run AFTER the `player==null`
  construction block — so the track exists and the start backlog has actually accumulated in the queue when we
  trim. `syncedSession` is now set there (once per session), not on an empty pre-construction queue.
- **P2 (real) — a stop/start interleaving between `queuedMs()` and `poll()` could discard a NEW session's live
  frames.** **FIXED:** the trim is now keyed to `frame.session` (the frame we already confirmed is the current
  session) and drains only SAME-session frames via peek-then-remove: it peeks the head, bails if the head is a
  different session or already gone, and removes that exact element. A concurrent stop/start can never make it
  drop a newer session's audio. A hard `guard<256` bound makes the loop provably finite (P3 "no work bound").
- **P3 — "already ACKed" wording.** Codex is right that enqueue precedes the ACK within the same arrival
  callback. But the ACK runs unconditionally in that callback's `finally`, independent of whether the worker
  later plays or discards the frame — so discarding never withholds an ACK. Comment reworded to
  "ACKed by its own arrival callback regardless of play/discard." No flow-control stall.
- **Guidance safety — confirmed** by Codex: `audioType!=1` excludes the type-1 guidance sink; drain/finishDrain
  untouched.

## Behaviour after the fix
Fresh media session: poll first frame → build track → (backlog now present) → discard this stale frame and
drain same-session backlog down to `AUDIO_START_TRIM_MS` (500 ms) → `continue` (no stale frame is written) →
next poll is near-live. Small/no backlog → no trim, play normally. Resume (release cleared the queue and reset
`syncedSession`) → little backlog, re-trims if needed.

## Residual / honest (car test decides)
- 500 ms is a chosen target (keeps a cushion above an underrun; one 341 ms max frame could leave ~159 ms).
  Tunable from the next car log (`T370_AUDIO_START_TRIM ... keptMs=`). Underrun blip neither proved nor excluded.
- `queuedMs()` measures queued PCM duration, not timestamp age — a proxy for latency, not an exact measure.
- "Once per AA session" holds for a stable session id (the car log shows song changes keep the same id); a phone
  that issued a fresh playbackStart per song would re-trim then too (still only a start-of-playback trim).

## Verification
Rebuilt offline, baseline restored. Host tests **PASS 287 bundle checks** + feature suites.
APK sha256 `5068820EF266D6A97A20285490E271BF814C365F47EFF1A7BBECC139972F843A`, versionName 0.9-T370.
Source diff vs T360: `AudioSink.java`, `AndroidManifest.xml`.

---

## Round 2 (CODEX-T370-round2.md) — attacking the P1/P2 fixes

Verdict: **no new P1.** The construction-order fix holds; different-session protection holds. Remaining
findings were all SAME-session-id release/resume micro-races (worker paused between the queue check and the
peek/remove, while a protocol release+resume reused the same session id):

- **P2a — could discard freshly-resumed audio** (same id defeats the session key).
- **P2b — could lose the release reset** (worker overwrites `syncedSession` after release set it to MIN), so a
  resume skips its re-trim.
- **P2c — could write one pre-release frame** held by the worker across a flush.
- **P3 — 500 ms is a trim threshold, not a guaranteed reserve** (can leave >500 ms if replenished, or <500 ms
  for one big frame). Latency tuning, not correctness.

**FIX (generation guard):** added `AtomicInteger audioGeneration`, bumped on every focus release and full stop
(next to the `syncedSession` reset). The trim captures `gen` at entry, the drain loop runs only while
`audioGeneration.get()==gen`, and after the loop: if the generation changed we drop the now-stale frame and
`continue` WITHOUT marking synced (so the new generation re-trims); otherwise we mark synced and, if we trimmed,
discard the stale polled frame. This closes **P2a** (drain bails the instant a release races) and **P2b**
(synced is not set when the generation changed, so the reset survives).

**Residual (honest):** **P2c** — a single pre-release frame the worker already holds can still be written after
a flush if the worker reads the new generation. This is the pre-existing check-then-write window that also
exists in T360 (`AudioSink` write guard), is one ~35–341 ms frame, and is not introduced by this trim; left as
a documented pre-existing residual rather than re-architecting the poll/write path. **P3** latency figures are
tunable from the car log (`T370_AUDIO_START_TRIM ... keptMs=`).

Rebuilt: host tests **PASS 287 bundle checks**. APK sha256
`4AA3CA344A057C446221458128B5CC947FC9672ADD605B1351EDA75D89F54184`, versionName 0.9-T370.

---

## Round 3 (CODEX-T370-round3.md) — attacking the generation guard

Verdict: **no new P1.** Codex showed the generation guard still had check-then-act windows: the loop-head
generation check and the `peek/remove` were separate (P2a), and the pre-assignment gate and the
`syncedSession=` write were separate (P2b).

**FIX (point-of-action re-checks):**
- **P2a:** moved the generation check to RIGHT BEFORE `frames.remove(head)`. A frame is only ever enqueued
  AFTER a release has bumped the generation (release's `incrementAndGet()` runs before the resumed session
  sends any PCM), so if `head` is fresh resumed audio the generation has already changed and the remove is
  skipped. This distinguishes "same-generation backlog" (trim) from "new-generation resumed audio" (keep) at
  the instant of removal.
- **P2b:** added a re-check AFTER `syncedSession=frame.session`; since release writes `syncedSession=MIN`
  BEFORE bumping the generation, any racing release leaves the final state = reset (re-trim preserved). Across
  all enumerated interleavings the final `syncedSession` is correct.

**Accepted residuals (not fixed, by decision):**
- **P2c** — a single pre-release frame the worker already holds can be written after a flush. This is the
  pre-existing check-then-write window present in T360 too (one ~35–341 ms frame), not introduced or worsened
  by this change. Closing it would require re-architecting the poll/write path or locking the audio hot thread,
  which is not justified for a one-frame, self-healing artifact.
- **P3** — `AtomicInteger` wraparound after 2^32 release/stop cycles (not reachable in a drive) and the 500 ms
  trim being a threshold not an exact reserve (latency tuning via the `keptMs=` log).

Review stopped after round 3: P1 fixed, P2a/P2b closed, residuals pre-existing/cosmetic. The car test is the
behavioural validator (does the start-up audio land in sync, no new dropouts).

Rebuilt: host tests **PASS 287 bundle checks**. APK sha256
`F2820591277086B5A2F69CF3F33DFC12BEF37E76AE962AE1BF212A61192A5170`, versionName 0.9-T370.
