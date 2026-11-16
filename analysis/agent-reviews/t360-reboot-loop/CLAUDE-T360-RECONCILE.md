# T360 — CLAUDE RECONCILES (after CODEX ATTACKS, round 1)

Codex review: `CODEX-T360.md` (model gpt-6.1-sol, read-only). ACK ownership and the three unchanged
`abortIo()` callers were confirmed sound. Codex did not break the core claim with evidence of a NEW loop or
leak introduced by the change, but raised two real risks (F1 P1, F2 P2) and two honest limitations
(F3, F4). Summary of what each finding changed.

## Finding-by-finding

- **F1 (P1) — a permanently wedged decoder would freeze the Wi-Fi session forever.** Valid. The original
  T360 recovered from a full queue but never escaped if the decoder was *permanently* wedged (queue stays
  full, nothing ever renders): stuckWatch is off for tcpMode and the socket stays alive, so nothing would
  tear it down. **FIXED** with a decoder-wedge backstop: `frame()` records `queueFullSince` when the queue
  first goes full; `rendered()` and any accepted frame clear it; if the queue stays full with no render for
  `InputEvents.DECODER_WEDGE_MS` (12 s — above any transient OMX stall, below LINK_DEAD_MS 20 s), it calls
  `abortIo()` so Honda's screen returns. Transient saturation (the observed bug) clears in a few seconds and
  never reaches 12 s. This also removes the "new way to freeze" risk in my own claim. 3 host checks added.
- **F2 (P2) — the 5 s throttle did not bound handler-queue growth** (every rejected frame posted a Runnable
  before `pictureLost()`'s own throttle). Valid. **FIXED**: the full-queue branch now gates the `pictureLost()`
  post on the native thread to at most once per 1 s (`lastQueueFullAsk`), so a frame-rate flood can no longer
  pile the handler up. `videoQueueFullDrops` is incremented either way (benign logging counter).
- **F3 (P2) — audio-track retention on UNCLEAN teardown is unproven/unfixed.** Correct and important: when a
  worker (here the wedged decoder) does not stop within the 2 s join, `shutdown()` keeps `stopped=false` and
  **skips `AudioSink.destroy()`** (S:1709-1721), so the AudioTrack is retained; across many such teardowns
  AudioFlinger refuses new tracks (`-12`, L:1726). This is the deeper cause of the start-up audio drop-out,
  and it PRE-DATES T360. **ACKNOWLEDGED, not changed in T360.** Rationale: the skip is a deliberate
  conservative choice to avoid native use-after-free while GAL threads are still alive; releasing audio on an
  unclean teardown is safe only after verifying AudioSink's native/ACK lifecycle, which is its own focused
  change and review. What T360 does here: the loop fix + F1 backstop drastically cut how often an unclean
  teardown happens (the loop was producing one every ~6-9 s), which is what was exhausting AudioFlinger. A
  proper release-audio-on-unclean-teardown fix is the recommended T370 follow-up.
- **F4 (P2) — host tests prove the backpressure signal, not the recovery.** True and inherent: the host JVM
  has no MediaCodec/Android runtime, so the service callback and real recovery can only be verified in the
  car. The host checks honestly cover what IS testable (the bounded queue signal; the wedge-window constant
  bounds). **Documented, not overclaimed.** Car test is the recovery evidence.

## Corrections Codex made to my prompt's premises (accepted)
- `decoder.stop()` (S:1709) does NOT null the field; the null-decoder branch is effectively unreachable while
  running+selected, but queue rejection is still reachable with a slow/wedged/stopping worker — which is
  exactly what the F1 backstop now handles.
- "A full queue can't happen on a dead link" holds only while buffered callbacks are still being drained;
  once they stop, EOF/error/the T350 socket timeout own teardown. The backstop does not rely on this.
- "Two files only" was true of the source tree; counting `BundleTests.java` it was three. After the F1/F2
  fixes the source diff vs T350 is **3 files**: `AaSessionService.java`, `InputEvents.java`,
  `AndroidManifest.xml` (plus `BundleTests.java`).

## Residual risks (honest, still open)
1. **F3 audio retention** remains (pre-existing): a legitimate disconnect while the decoder is wedged still
   retains that session's AudioTracks. T360 makes this rare; T370 should release audio on unclean teardown.
2. A 1-byte-dribble / sub-threshold pathological link is still handled by T350's socket timeout, unchanged.
3. Not yet car-tested. `test.json` repro: start AA several times (incl. cold), expect it to come up and STAY
   up; let it run a few minutes; version reads 0.9-T360.

## Verification
Rebuilt offline, baseline restored. Host tests **PASS 285 bundle checks** + all feature suites.
APK sha256 `824977ABDCC8F2CA45C20F17237B6EE6DFA083CBA536BF32D719AC70B03CF74C`, versionName 0.9-T360.
Source diff vs T350: `AaSessionService.java`, `InputEvents.java`, `AndroidManifest.xml` (+ `BundleTests.java`).
Installer `analysis/installer-20261112/Hackura-Installer` repackaged to this build.

---

## Round 2 (CODEX-T360-round2.md) — attacking the F1 backstop + F2 gate

Codex broke the backstop with a real P1 and raised P2 qualifications.

- **F1 (P1) — the backstop could false-trip a HEALTHY session via a non-atomic volatile read.** Valid, with
  a concrete interleaving: `frame()` read `queueFullSince` twice (zero-check, then subtraction); between them
  the decoder thread's `rendered()` could set it to 0, so `now - 0` fired `abortIo()` on a just-rendered
  session. **FIXED:** read the stamp ONCE into a local `started` and do all arithmetic on it; additionally
  require a CONTINUOUS full episode — a new field `lastQueueFullDrop` restarts the window if >2 s passed since
  the last full-queue drop, so a stale stamp left across an idle/minimized pause can never expire. A real
  wedge floods rejects (one per frame, <<2 s apart) so the 12 s still accrues.
- **F2 (P2) — the 12 s deadline is only evaluated on a rejected-frame callback; if video stops entirely while
  the worker is blocked, nothing times it out.** True coverage boundary. ACKNOWLEDGED: if video callbacks
  stop, the decoder queue is not being pushed (no new rejects), and the T350 socket read timeout (20 s) owns
  teardown once the link goes quiet. The wedge backstop is specifically for "frames keep arriving but none
  render"; "frames stop arriving" is the socket timeout's job. Documented, not changed.
- **F3 (P2) — the 1 s gate bounds posting RATE, not pending-task COUNT.** True but bounded: at most ~1
  `pictureLost()` post/s, and each is a near-no-op inside its own 5 s throttle. A main handler blocked for many
  seconds is a separate pre-existing condition. Accepted as a bounded residual.
- **F4 (P2) — the logs establish time-to-SATURATION (~3.6 s), not time-to-RECOVERY, so 12 s is a chosen
  margin, not a proven one.** Correct. 12 s sits above saturation and below LINK_DEAD_MS (20 s); the car test
  is the real evidence. Easily tunable if a slow-but-recovering decoder is ever observed.
- **Native-thread abortIo() — UNKNOWN re: receiver.prepare() monitor.** Noted: the backstop calls abortIo()
  from the SAME native GAL frame thread and the SAME call context as the pre-T360 queue-full abortIo() (T340
  already called abortIo() right here), so it adds no new re-entrancy surface versus shipped behavior.
- **ACK ownership / throttle placement — pass.** The explicit reject-path ACK is OUTSIDE the 1 s gate (every
  rejected frame is ACKed); only the pictureLost() post is gated. One ACK per frame, never both paths.

## Verification (round 2)
Rebuilt offline, baseline restored. Host tests **PASS 285 bundle checks** + feature suites.
APK sha256 `07EE60C440F5F00BF4EDDA07C8DD46BCD240C06C59976DEB539B87F88CF15D6A`, versionName 0.9-T360.
Installer repackaged to this build. Still not car-tested.
