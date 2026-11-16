# T370 round 3 — CODEX ATTACKS the generation guard

Rounds 1-2 fixed P1 (construction-order) and the different-session case. Round 2's same-session-id
release/resume races (P2a discard fresh audio, P2b lost reset) are now addressed with a generation guard.
Reconciliation: `CLAUDE-T370-RECONCILE.md`. This is a FOCUSED pass on the guard only.

CLAUDE PROPOSES: "The `audioGeneration` guard makes the start-trim abort cleanly when a focus-release or
full-stop races it mid-flight — it never discards freshly-resumed (same-id) audio and never loses the
re-trim reset — and it does not break the normal (unraced) trim or add a hang."

Find counterexamples. READ-ONLY. Do not build/edit/touch any device.

## Current code (T370-bundle AudioSink.java)
- Field: `private final AtomicInteger audioGeneration = new AtomicInteger();`
- `audioGeneration.incrementAndGet()` is appended to BOTH reset sites: `requestProtocolFocus()` release and
  `playbackStopCallback()` full-stop, right after `syncedSession=Integer.MIN_VALUE`.
- In `playLoop()`, after track construction:
[Code block omitted; consult project-authored source.]

## Attack (cite file:line)
1. **P2a closed?** Any same-id release/resume interleaving where the drain loop still removes a freshly-resumed
   frame? Consider the worker reading `gen` AFTER the release vs BEFORE; in the AFTER case is any removed frame
   actually a legitimate new-generation backlog (correct to trim) rather than a lost frame?
2. **P2b closed?** Any interleaving where `syncedSession=frame.session` still executes after a release bumped
   the generation, so a resume skips its re-trim? Walk the `if(audioGeneration.get()!=gen){...continue;}` gate.
3. **New hang/spin?** Can the `audioGeneration.get()==gen` loop condition plus `guard<256` ever fail to
   terminate, or busy-spin?
4. **Normal path intact?** With no race, does a real backlog still get trimmed once, the stale polled frame
   skipped, and small-backlog sessions play normally and mark synced?
5. **Atomicity.** `audioGeneration` is an AtomicInteger incremented from the release (handler) and stop (native)
   threads and read on the worker. Is "any change ⇒ abort" robust to two increments, wraparound, or visibility?
6. **Residual honesty.** Confirm the remaining P2c (one pre-release frame written after a flush when the worker
   reads the NEW generation) is unchanged-from-T360 pre-existing behaviour, not newly introduced or worsened.

## Report back
Findings ranked P1/P2/P3 with file:line evidence, whether the guard holds, and any remaining uncertainty.
