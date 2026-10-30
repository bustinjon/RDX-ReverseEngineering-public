# Timing threshold review: the readiness guard's 2000ms gap check vs real device latency

Written by Claude, 2026-10-26, after a second live M5 attempt was stopped because the readiness guard
refused three times in a row with "Polling gap/clock order unsafe." **Status: NOT RESOLVED. My first
proposal had a real flaw, found by Codex's independent review. Nothing has been applied. This needs a
decision from the user, not just a fix.**

## What happened
This was the first time the guard's 5-second sampling loop has ever run against the real car — every
earlier live attempt was blocked before reaching this stage. So this is new information, not a regression.

## The measurement (confirmed independently by Codex, exact match)
Each sample runs 9 sequential `adb shell`/`pull` commands.

| | Attempt 1 | Attempt 2 | Attempt 3 |
|---|---|---|---|
| Per-sample duration (4 samples each) | 1563/1531/1516/1484 ms | 1532/1531/1531/1516 ms | 1672/1469/1515/1484 ms |
| Gap, sample 0→1 | **2141 ms** | **2141 ms** | **2250 ms** |
| Gap, sample 1→2 | 1953 ms | 1953 ms | 1891 ms |
| Gap, sample 2→3 | 1953 ms | 1969 ms | 1953 ms |

Every individual sample stays under the separate 2000ms per-sample ceiling (worst: 1672ms, 328ms of
margin). The first sample-to-sample gap is consistently ~2140-2250ms — just over the 2000ms gap ceiling —
while later gaps settle to ~1890-1970ms. `pm list packages -u` is the single biggest per-sample cost
(~650ms).

## My first idea, and why it's not good enough as-is
I proposed raising only the gap threshold (2000ms → 3000ms), verified it against all three real captures
(all now pass) and a deliberately exaggerated bad case (still correctly refused). **Codex's independent
adversarial review found this insufficient**, and it's right:

1. **It genuinely enlarges an unobserved window, not just a number.** Codex built a concrete countermodel:
   four individually-safe samples at `[0,1500]`, `[2500,4000]`, `[4400,5900]`, `[6300,7800]` ms would now
   pass, but there's a ~2.4-second stretch (1600-2400ms) between the first two where the state could have
   gone unsafe and reverted before the next sample — completely unobserved. The *old* 2000ms policy would
   have refused a sequence shaped like that; the *new* 3000ms one wouldn't. This is a real reduction in
   what the guard can rule out, not a cosmetic change.
2. **It also lets the loop get away with fewer looks:** starts at `0, 2500, 5000` ms would now satisfy the
   whole 5-second window with only 3 samples instead of 4.
3. **Codex corrected a factual mistake in my first write-up.** I said the final-precheck check (a second,
   separate 2000ms limit inside the same function) was "never exercised tonight." That's wrong — the
   function doesn't stop at the first failure; it runs every check and collects every reason. That check
   *did* run, every time, and it passed — but only by **313-344ms of margin**. That's real measured
   evidence that a second, nearby 2000ms limit is sitting almost as close to the edge as the one that
   actually failed.
4. **There's no permanent test for whatever number we pick.** The existing offline test suite only ever
   used obviously-safe (500ms) or obviously-broken (one huge jump) synthetic gaps; it wouldn't catch a
   future accidental change to this threshold in either direction.

## A hoped-for alternative, checked and ruled out
I wondered whether `pm list packages -u` could be made cheaper by adding a name filter (e.g. `pm list
packages -u com.rdx`), since that's the single biggest per-sample cost. I decompiled this car's own
`pm.jar` to check, rather than guess. **Confirmed from the actual source: the filter is applied
client-side, after the full package list has already been fetched from the system over Binder.** Narrowing
the filter would not meaningfully reduce the real cost — this isn't a quick win.

## Where this leaves us
There is no clean, no-tradeoff fix here. The real choice is between:
- **Accept a somewhat larger (but still bounded, ~3 second) blind window** between observations, to get
  past a real hardware/timing constraint on this connection; or
- **Keep the tighter window** and accept that this guard may not be able to prove readiness on this
  connection as currently designed, which would need a more invasive restructuring (checking the
  expensive package-list signal less often than the cheap ones, not just moving one number) — a bigger,
  riskier change that itself would need careful, non-rushed testing, ideally live.

This is a risk-tolerance decision, not a bug fix. I'm not comfortable deciding it myself, and I didn't
apply anything. The project already accepts *some* blind-spot risk between any two discrete samples by
design (documented since this morning's guard-attack review); this would make that existing, accepted gap
somewhat wider — by how much, and whether that's still acceptable, is the actual question.
