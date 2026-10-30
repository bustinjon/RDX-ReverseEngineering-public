# Readiness timing: first-principles reassessment (CLAUDE PROPOSES)

Written by Claude, 2026-10-26, after the user said to stop implementing and reassess. Nothing has been
applied. Live guard files are unchanged. This document is the position for Codex to attack.

## The problem, stated without assuming a fix
The guard needs consecutive sample *starts* no more than 2000 ms apart. A sample is 9 sequential `adb shell` commands.
On the real car, the first start-to-start gap was 2141/2141/2250 ms (refused). Later gaps were 1891-1969 ms, passing by only
31-109 ms. Note that Windows `TickCount64` ticks every ~15.6 ms, so every number here carries roughly ±16 ms of noise.

## Where the gap budget actually goes (measured from the 3 real captures)
Gap(i→i+1) = sample duration + 400 ms deliberate `Start-Sleep` + host residual.

| | Sample duration | Sleep | Host residual |
|---|---|---|---|
| After sample 0 | 1532-1672 ms | 400 | **178-209 ms** (one-time) |
| After samples 1-2 | 1469-1531 ms | 400 | 22-38 ms |

- Inside a sample, the summed command times equal the sample duration. Inside a sample there is no host gap; it is all adb round-trips.
- `pm list packages -u` costs 652-656 ms, and `pm path` costs 578-640 ms. The car runs **Android 5.1.1 / API 22**.
  On that version `pm` starts a fresh Java VM on every call. So the cost is mostly VM startup, not the size of
  the list. This corrects my earlier framing ("Binder fetch is the cost"). It also means `cmd package`
  (Android 7+) does not exist here.
- The cheapest command (`getprop`) takes 62-141 ms, so each adb spawn has a fixed cost of roughly 60-90 ms.
  Across 9 commands that is about 0.5-0.8 s per sample.
- Offline, the first call of `Get-M5SampleAssessment` in a fresh process took 74-118 ms, versus about 17 ms
  when warm. That explains part of the one-time residual (SUPPORTED); the rest is UNKNOWN.

## Assumptions that led us here, challenged
1. *"The threshold is the problem."* It is not. A fixed 400 ms of every gap is a deliberate sleep, and one-time host
   warm-up cost lands on the first gap. The device-side work fits.
2. *"`pm list` is expensive because of the list."* It is expensive because of the VM startup (see above).
   Any replacement must avoid `pm` entirely.
3. *"The mock validated reality."* It is an overclaim. The mock hard-codes average durations, so it only re-checks
   arithmetic plus the real core's verdict on real text. It cannot reveal latency tails, and Start-Sleep rounding makes it
   slightly pessimistic.
4. *"Packages can only change if the operator runs adb install."* This is weak. The Honda updater, OTA, or system package
   enable/disable could change state. Sampling packages less often is a real reduction in coverage of
   that field, and it needs a real justification.
5. *"Fix the gap and ARM proceeds."* This is not established. The final-freshness budget after the last sample had
   only 313-344 ms of margin (Codex F3). Removing the sleep does not shrink sample duration, so it does
   not help that margin. Only cheaper samples help it.

## Governing principle proposed
Do not loosen any threshold. Change only collection cost or cadence, in ways that observe the
same fields at least as often as today. This principle avoids Codex's F2 countermodel entirely.

## Candidate approaches (my ranking, to be attacked)
1. **Remove the 400 ms sleep, and warm up the assessment function before the loop.** No threshold changes, every
   field is still read every sample, and sampling gets strictly denser. Predicted gaps are about the sample duration plus 20-100 ms,
   so roughly 1500-1770 ms in the worst observed case (230-500 ms margin). It does not help the final-freshness margin. Open question:
   why the sleep exists. No documented rationale was found; it may be there to avoid hammering the head unit.
2. **Bookend the package list** (one fresh `pm list` immediately before the loop and one immediately after, re-validated on the
   last sample; never inside the loop). Offline simulation: gaps 1359-1516 ms, sample about 950 ms, 5 samples,
   READY. It also helps final freshness. But it reduces that one field's temporal coverage (assumption 4).
3. **Targeted per-sample `dumpsys package <name>`** for the factory AA package and known M6/M7 names (about 90 ms each), plus the
   bookend full list for unknown `com.rdx.*` names. This keeps per-sample coverage of the named-package invariants. Whether
   `dumpsys package <name>` on API 22 matches exactly or by prefix is UNVERIFIED.
4. **Batch several reads into one `adb shell` invocation.** This saves most of the roughly 0.5-0.8 s spawn overhead, but it changes the
   allowlisted command surface (a concatenated shell string) and needs care around the lockBefore/lockAfter bracket.
5. **Persistent shell session over stdin.** This gives the biggest saving but is the most complex, with new failure modes.
6. **Widen the 2000 ms threshold.** Rejected; see `CODEX-TIMING-THRESHOLD-ADVERSARIAL-REVIEW.md` F2.
7. **In-app lock-task check right before the permission request.** This is defense in depth, but it changes the M5 APK. Out of
   scope unless the user wants it.

Any chosen path also needs permanent boundary tests (Codex F4) and a measurement of the full path through
the runner's freshness checks (Codex F3).

My tentative leaning is approach 1, possibly combined with 2 or 3 if the final-freshness margin turns out to need cheaper samples.
I hold this weakly until Codex attacks it.
