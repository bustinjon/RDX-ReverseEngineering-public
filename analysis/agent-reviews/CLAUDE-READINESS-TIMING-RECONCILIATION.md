# Readiness timing: reconciliation (CLAUDE RECONCILES)

2026-10-26. Inputs: `CLAUDE-READINESS-TIMING-FIRST-PRINCIPLES.md` (proposal) and
`CODEX-READINESS-TIMING-FIRST-PRINCIPLES-ATTACK.md` (attack). Disagreements were settled against primary
evidence, not averaged. Nothing has been applied.

## Accepted from Codex (verified)
- **The bookend approach does not help final freshness. My claim was wrong.** The algebra is correct: final age =
  (D − P) + P + H = D + H, unchanged. The mock also attached the closing package read after the last
  sample's recorded end, which misdescribes the evidence. **Approach 2 is rejected.**
- **"Command time = device time" is false.** `scripts/Test-M5ArmReadiness.ps1:33` writes stdout and stderr to disk
  inside the per-command timer, and the services dump is about 165 KB per sample. Host disk I/O (and possibly antivirus) is inside
  the measured sample. The 60-90 ms "spawn floor" is not isolated.
- **"pm cost is mostly VM startup" is downgraded to UNKNOWN.** "Filter is client-side after full fetch" stays CONFIRMED.
- **Removing the sleep forces a 5th sample.** Spans without the sleep would be 4847/4863/4894 ms, under the 5 s minimum.
  That means more commands, more replay and more serialization afterwards.
- **The final-freshness check undercounts.** `NowMs` is taken at line 74, before the window function replays samples. The
  JSON writes (lines 79-81) come after result creation and before the runner's own freshness checks. So the
  313-344 ms margins come from refused runs, and the successful path has never been measured.
- **Approach 3 is incomplete.** Name matching is exact (I independently confirmed this at `Settings.java:2946`), but it also matches
  aliases and hidden system records. It omits the `com.rdxresearch.*` namespace, and a finite name list cannot replace the
  "any project package" rule. Package state can change without operator action (`PackageManagerService` enabled-state
  and install paths; services un-stop packages).
- **The governing principle needs to be broader.** It must also preserve coverage, observation intervals per field (not just
  sample starts), the lock-before/lock-after placement, failure detection, and freshness through the runner.

## Where I keep my position
- The core diagnosis stands. The threshold is not the bottleneck; collector overhead is. Both reviews agree that no
  threshold should be widened.
- Approach 1 (remove the sleep) is still the strongest narrow candidate. Codex ranks it first too, but as "investigate," not
  "adopt."

## New options surfaced
- **Move evidence file writes out of the timed command path** (buffer in memory, write after the loop or in
  `finally`). This changes no observation, field or threshold, and it shrinks both the gaps and final freshness. Codex raised the
  general idea ("move bulk persistence earlier"), and line 33 is the concrete instance. The benefit is UNKNOWN until measured.
- **A single `dumpsys package packages` query** (Codex). This is native `dumpsys`, so there is no Java `pm` client. It might replace both
  `pm list -u` and the M5 package dump while keeping full-namespace coverage. Output size and latency are UNKNOWN; this needs
  live measurement and a section-aware parser.

## Reconciled plan (ordered; each step gated)
1. **Offline, safe:** add permanent boundary tests for the existing core (1999/2000/2001 ms for gap, duration
   and final age; span minimum). Tests only, no logic change. This closes Codex F4 from the earlier review.
2. **Offline, safe:** build a disarmed host harness that runs the real collector and runner path with the device stubbed and
   timestamps every stage (commands, file writes, assessment, sleep, serialization, intent save, the three runner freshness
   checks). This answers whether final freshness is the next refusal, and how much file I/O costs.
3. **Live, read-only measurement session (needs separate authorization):** no install and no ARM. Repeat the 9 commands many times
   to get a latency distribution, measure the real sleep time, and time `dumpsys package packages` plus its output size.
4. **Only then** choose the change: most likely approach 1 plus moving the file writes, then Codex review, then user approval, then apply.
