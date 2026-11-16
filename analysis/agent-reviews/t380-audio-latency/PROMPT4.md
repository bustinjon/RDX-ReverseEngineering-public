# T380 round 4 — CODEX ATTACKS the "arm only when played" fix

Round 3 found P2: the post-write resync block could ARM the new generation's timer while PAUSED (a write that
returned -1 during a focus-release still reached the block), so a resume could flush its own first audio. Fix:
the block is now gated on `complete && focusAllowed` so it only runs when THIS iteration actually played.
Reconciliation: `CLAUDE-T380-RECONCILE.md`. FOCUSED pass on this one change.

CLAUDE PROPOSES: "Gating the T380 arm/measure/resync block on `complete && focusAllowed` means the timer is
armed only by a real played frame, so it can no longer arm during a pause and cause an immediate
first-resumed-write flush — while a normal cold start still arms on its first played frame and fires once
~1200 ms later."

Find counterexamples. READ-ONLY. Do not build/edit/touch any device.

## The change (T380-bundle AudioSink.java)
[Code block omitted; consult project-authored source.]
`complete` is true only if every `player.write` returned >0 (the writer returns -1 on stopping/!focusAllowed/
session-mismatch). `audioGeneration` bumps on focus-release and full-stop (both pause+flush), not on song change
or focus-regain.

## Attack (cite file:line)
1. **Armed-while-paused closed?** Reconstruct round 3's schedule (focus release mid-write → write returns -1 →
   block). Confirm `complete` is now false so the block is skipped and the timer is NOT armed during the pause.
   Any path where `complete` is true yet playback is effectively paused (so the timer arms during silence)?
2. **Normal cold start still works.** First real played frame: `complete && focusAllowed` true → arms
   (resyncArmedGen!=gen), fires once ~1200 ms later. Confirm the gate didn't break the intended behavior.
3. **Resume after release.** Release bumps gen + pauses; during pause writes fail (complete=false, no arm); on
   regain the first SUCCESSFUL write arms the new gen fresh → fires ~1200 ms after real resumed playback, not
   immediately. Confirm.
4. **Partial write.** If a frame is partially written (some writes >0 then a -1), `complete` is false → block
   skipped. Is skipping the arm/measure on a partial write acceptable (just delays arming to the next full
   frame), or can it starve arming forever under sustained partial writes? Realistic?
5. **Any NEW regression** from requiring `complete`: does the resync ever now fail to fire for a genuinely
   playing session (e.g. steady-state always-complete writes keep arming at the same gen — confirm arm only sets
   once per gen via `resyncArmedGen!=gen`)?
6. **Diagnostic try/catch** around the AUDIO_LATENCY read: confirm it contains getPlaybackHeadPosition +
   presentationLatencyMs + queuedMs and cannot swallow a resync or mislabel anything.

## Report back
Findings P1/P2/P3 with file:line evidence, whether the claim holds, remaining uncertainty.
