# T370 round 2 — CODEX ATTACKS the P1/P2 fixes

Round 1 (`CODEX-T370.md`) broke the first placement: P1 (trim ran before the track was built, missing the
construction backlog) and P2 (a stop/start race could discard a new session's live audio). Both are now
reworked. Reconciliation: `CLAUDE-T370-RECONCILE.md`.

CLAUDE PROPOSES (the claim you must try to break):

"The trim now runs only AFTER the AudioTrack is built (so the start backlog is present), drains ONLY frames of
the just-confirmed `frame.session` via peek-then-remove (so a concurrent stop/start can never discard a newer
session's live audio), is provably finite, trims once per session, and does not stall flow control or play a
stale frame."

Find counterexamples. READ-ONLY. Do not build, do not touch any device, do not edit files.

## The current code (T370-bundle, AudioSink.java, after the fix)
`.../builds/T370-bundle/source/analysis/parallel-aa-receiver/src/com/google/android/projection/protocol/AudioSink.java`
In `playLoop()`, after the `if(player==null){ ...construct AudioTrack... }` block and before `if(!focusAllowed)`:
[Code block omitted; consult project-authored source.]
`AUDIO_START_TRIM_MS=500`. `syncedSession` (volatile) reset to MIN in `requestProtocolFocus()` release and
`playbackStopCallback()` full-stop. `frame` was already confirmed `frame.session==activeSession || ==drainingSession`
earlier in the loop. `queuedMs()` sums `frames` byte lengths (weakly-consistent iterator). `frames` is
`ArrayBlockingQueue<Frame>(64)`; `Frame` has no `equals` (identity).

## Attack these specifically (cite file:line)
1. **P1 really fixed?** Is there still any path where `syncedSession=frame.session` is set while the real start
   backlog is NOT yet present, so later backlog is never trimmed? Consider: track already existed (resume) so the
   `player==null` block is skipped — does the trim still sit after it and behave correctly with an empty queue?
2. **P2 really fixed?** With peek-then-remove keyed to `frame.session`, construct any interleaving (stop+start,
   guidance interleave, activeSession flip) that still discards a frame belonging to a different/newer session,
   or that removes a frame after the head changed. Does `frames.remove(head)` (identity) ever remove the wrong
   object? Can `head` be a different-session frame that slips through the `head.session!=frame.session` check?
3. **Stale frame.** The trimmed iteration `continue`s without writing `frame`. Confirm no stale frame is written
   before/after the trim, and that discarding the polled `frame` (counted via `dropped++`) is correct.
4. **Draining vs guidance / drainingSession.** `frame.session` may equal `drainingSession` (guidance) — but the
   whole block is gated `audioType!=1` (media sink only). Confirm the media sink's `drainingSession` path (if
   any) can't mis-key the trim.
5. **Termination & correctness of the bound.** Can the `guard<256` loop exit with `queuedMs()` still >500 (leaving
   latency), or over-drain below the intended cushion? Is leaving >500 ms (bound hit) or <500 ms (one big frame)
   a correctness problem or just latency tuning?
6. **syncedSession reset races.** A resume resets `syncedSession` at release; can an in-flight trim overwrite it
   so the resume skips its re-trim — and does that matter given release also `frames.clear()`s?
7. **Flow control.** Re-confirm discarding queued frames can't stall the phone (each frame ACKed by its own
   arrival callback), and that `dropped` accounting is purely diagnostic.

## Report back
Files inspected, findings ranked P1/P2/P3 with file:line primary evidence, assumptions, unresolved
uncertainties, and whether the core claim holds. "Looks fine" without cited evidence is rejected.
