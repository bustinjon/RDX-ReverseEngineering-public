1. **Files inspected**

   `PROJECT-RULES.md`, `AGENTS.md`, the current and proposed cores, `tools/m5/Test-M5ArmReadinessOffline.ps1`, `scripts/Test-M5ArmReadiness.ps1`, `tools/m5/Invoke-M5FutureSession.ps1`, and the session’s `fresh-install-proof.json`.

   In `analysis/parallel-aa-receiver/m5-retry-live-20261026-174603/`, I inspected `samples.json`, `commands.json`, and `readiness.json` for:

   - **A:** `readiness-42377042f28a48aca415a3c202c204c6`
   - **B:** `readiness-ca6157bd57e8447cbbb90f999bd7d497`
   - **C:** `readiness-255a9a215c0a44c299247adb878092c6`

2. **Files changed**

   None.

3. **Commands run**

   Read-only `Get-Content`, `Get-ChildItem`, `rg`, `Get-FileHash`, `git status --short`, and `git diff --no-index`/`--numstat`.

   Executed in-memory PowerShell timing reconstructions, the exact freshness expression extracted from core line 77, and JavaScript arithmetic, comparison, and SHA-256 checks. No device commands or runner stages were invoked.

   Direct dot-sourcing of the core failed because PowerShell reported different language modes. I did not circumvent that restriction.

4. **Tests run and results**

   **Exact captured arithmetic**, using `endMs − startMs` and successive `startMs` differences:

   | Attempt | Sample durations 0–3, ms | Start gaps, ms | Total start span, ms |
   |---|---|---|---:|
   | A | 1563, 1531, 1516, 1484 | 2141, 1953, 1953 | 6047 |
   | B | 1532, 1531, 1531, 1516 | 2141, 1953, 1969 | 6063 |
   | C | 1672, 1469, 1515, 1484 | 2250, 1891, 1953 | 6094 |

   Claude’s gap numbers are correct. The exact duration range is **1469–1672 ms**, slightly outside the rounded 1470–1670 range. Each sample contains nine successful shell commands; no sample includes a pull.

   **Diff:** PASS. One executable line changed, plus five added comment lines: `6 insertions / 1 deletion`. Removing those comments and reverting `3000` to `2000` reproduced the current source text exactly.

   **Reconstructed timing checks:** PASS.

   - All three captures fail at 2000 ms and pass at 3000 ms.
   - Removing both middle samples creates jumps of **6047, 6063, and 6094 ms**. All three remain refused, solely for `Polling gap/clock order unsafe`.
   - Tested gaps: **1999, 2000, 2001, 2141, 2250, 2999, 3000, 3001 ms**. Proposed acceptance ends at 3000 inclusive.
   - Sample duration 2000 passes; 2001 fails. Incomplete duration and non-increasing timestamps remain refused.
   - Final-precheck age 2000 passes; 2001 fails.
   - The **exact extracted core freshness expression** accepts ages 1687 and 2000, and rejects 2001.

   These were timing reconstructions, **not a full native parser replay**. Unchanged content predicates were accepted during the captured native runs, whose sole reported reason was the polling gap. I did not run the existing full suite: it writes files and invokes runner refusal paths.

5. **Findings**

   **F1 — Verdict: UNKNOWN whether safe to apply as-is.** The latency correction is **SUPPORTED**. The stronger claim that it does not weaken the guard is falsified in terms of temporal coverage: it admits observation sequences previously refused.

   **F2 — Independent safe samples cannot exclude a reverted unsafe transition.** Consider safe samples covering `[0,1500]`, `[2500,4000]`, `[4400,5900]`, and `[6300,7800]` ms. An unsafe excursion during **1600–2400 ms**, restored before the next sample, intersects no sample. With content copied unchanged from a captured accepted sample, the reconstructed old policy refuses this sequence; the proposal accepts it.

   This is a countermodel to continuous stability, **not evidence that such an excursion occurred in the car**. Whether a fully reverted excursion creates a residual ARM hazard is **UNKNOWN**. The surrounding checks contain no history mechanism that excludes it. Comparing 3000 ms with the five-second minimum does not establish safety.

   The proposal also reduces the minimum observations needed across five seconds from **four to three**: starts at `0,2500,5000` satisfy the proposed timing policy.

   **F3 — The final-precheck check already ran and passed.** `Get-M5WindowAssessment` accumulates reasons and continues after finding a gap. Its line-69 check therefore executed on all three attempts. Calling that check untested is inaccurate.

   The later runner path remains unmeasured:

   | Attempt | Last-sample duration | Age at result creation | Remaining 2000 ms budget |
   |---|---:|---:|---:|
   | A | 1484 ms | 1656 ms | 344 ms |
   | B | 1516 ms | 1687 ms | 313 ms |
   | C | 1484 ms | 1656 ms | 344 ms |

   Result creation precedes serialization of `commands.json`, `samples.json`, and `readiness.json`. Those writes, return to the runner, result loading, intent saving, and process preparation must fit the remaining **313–344 ms**. A later freshness refusal is plausible; its actual likelihood is **UNKNOWN**.

   For these captures, widening the gap does not simply expose an already-failing sample-duration or final-precheck condition. Future variability could make either fail first. The worst observed sample leaves only **328 ms** below its duration ceiling.

   **F4 — No permanent test pins 3000 ms.** The suite constructs gaps of at most 500 ms, except its isolated 5000 ms skip-middle case. The named `1900`, `2000`, and `3000` tests concern **total window duration**, not inter-sample gaps. Randomized fixtures retain 500 ms spacing.

   Reconstructing those timing cases showed identical outcomes for limits **500, 2000, 3000, and 4999 ms**. Consequently, this suite would neither catch reverting the proposal to 2000 nor increasing it to 4999. The proposal directory contains only the proposed core.

   **Ranked follow-up before applying as-is:**

   **Priority 1:** Establish whether the required safety property permits unobserved, reverted excursions and three observations across five seconds. Otherwise, investigate collection cadence while retaining the existing temporal bound.

   **Priority 2:** Add permanent, isolated boundary tests at 2999/3000/3001 ms, the captured first-gap values, and retained duration, ordering, span, and freshness limits. Run them against the actual core.

   **Priority 3:** Measure or simulate the complete host path through serialization and runner freshness checks with device execution stubbed. Do not widen untouched thresholds based on the inter-sample measurements.

6. **Primary evidence for each finding**

   **F1 / arithmetic:** Captured timestamps occur at lines 3/13, 16/26, 29/39, and 42/52 in [A samples](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/m5-retry-live-20261026-174603/readiness-42377042f28a48aca415a3c202c204c6/samples.json:3), [B samples](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/m5-retry-live-20261026-174603/readiness-ca6157bd57e8447cbbb90f999bd7d497/samples.json:3), and [C samples](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/m5-retry-live-20261026-174603/readiness-255a9a215c0a44c299247adb878092c6/samples.json:3). Their matching `commands.json` files establish command timing and success. The independent arithmetic output is reproduced in item 4.

   **F2:** [Core lines 44–71](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/m5/M5ArmReadiness.ps1:44) validate sampled fields, matching foreground tasks, durations, gaps, span, and final age. [Collector line 68](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/scripts/Test-M5ArmReadiness.ps1:68) shows sequential reads. The countermodel output was `old: ready=false, reasons=[gap]`; `proposed: ready=true, reasons=[]`.

   **F3:** [Core line 69](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/m5/M5ArmReadiness.ps1:69); [result creation and writes](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/scripts/Test-M5ArmReadiness.ps1:78); [runner checks and intent saving](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/m5/Invoke-M5FutureSession.ps1:62); [process-boundary check](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/m5/Invoke-M5FutureSession.ps1:19). Each captured `readiness.json` records only the gap reason, with `createdMs` at line 8.

   **Reference correction:** `Test-M5ReadinessFresh` is at **core line 77**. `scripts/Test-M5ArmReadiness.ps1` line 77 initializes the result run ID.

   **F4:** [Fixture spacing](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/m5/Test-M5ArmReadinessOffline.ps1:25), [duration tests](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/m5/Test-M5ArmReadinessOffline.ps1:40), [5000 ms negative control](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/m5/Test-M5ArmReadinessOffline.ps1:55), and [randomized fixture construction](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/m5/Test-M5ArmReadinessOffline.ps1:92).

7. **Assumptions**

   Captures accurately represent their original runs. Applying the proposal changes only the reviewed core line and comments. The transient countermodel assumes restoration of all observed fields before the next read; it asserts no actual vehicle event.

8. **Unresolved uncertainties**

   Acceptable blind-interval duration, residual hazard from reverted transitions, latency tails beyond these three attempts, and successful-path runner freshness timing are **UNKNOWN**. Full native parser replay remains unperformed in this review.

9. **Exact diff summary**

   No review edits. Candidate diff: current line 65 changes `-gt2000` to `-gt3000`; five comments are added immediately above it. No other source-text differences.

10. **Preservation checks performed**

   SHA-256 comparisons confirmed **all 17 inspected files unchanged** between checkpoints.

   Current core: `3466943DAC577BDACCE775444550FD4D75A7B0991B13B880E0A479C4F09A9841`  
   Proposed core: `79F8175AB31D04F0844AD51E963F3B623D06F1B6041DA19471C8F7C2C985A788`

   Final `git status` showed an additional untracked `analysis/agent-reviews/CLAUDE-TIMING-THRESHOLD-REVIEW.md` appearing during the review. I did not create or read it; its origin is **UNKNOWN**.

   No frozen artifact was rebuilt or modified; their hashes were not reverified. No key material, devices, or milestone operations were accessed.