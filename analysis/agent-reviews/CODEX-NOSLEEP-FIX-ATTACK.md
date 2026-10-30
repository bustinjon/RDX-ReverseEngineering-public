1. **Files inspected**

   Read `PROJECT-RULES.md` and `AGENTS.md` first. Inspected both collectors, core, runner, latency-measurement source, supplied captures, three prior reviews, saved harness results, guard policy, relevant decompiled service locks, and preservation manifest.

2. **Files changed**

   None.

3. **Commands run**

   Read-only `Get-Content`, `Get-ChildItem`, `Get-Item`, `Get-FileHash`, `rg`, `git diff`, `git log`, `git status`, and in-memory timing calculations. One incorrect measurement-source lookup failed; corrected to `scripts/Measure-M5ReadinessLatency.ps1`.

   No harness, measurement, collector, runner, device command, or build was executed.

4. **Tests run and results**

   Read-only checks:

   - Exact-text comparison after deleting only the sleep: **True**.
   - Candidate diff: **0 insertions, 1 deletion**.
   - Tonight’s evidence: **24 samples, 222 commands, zero recorded command failures**, all recorded lock endpoints INACTIVE/Honda Home.
   - Recomputed no-sleep durations/gaps: **1390–1485 ms**; maximum corresponding field-command start gap: **1500 ms**, excluding block boundaries.
   - Core and runner tracked-file diff: **empty**.

5. **Findings**

   **F1 — CONFIRMED: the deletion preserves the implemented acceptance predicates. SUPPORTED: it is a reasonable narrow candidate.**

   All nine reads, their ordering, both lock endpoints, full package coverage, provenance checks, minimum two samples, 5–15-second start-span policy, and 2000 ms limits remain. Immediate raw-output persistence remains.

   It does remove a rate limit. Under the earlier captured timings, the qualifying window grows from **four samples/36 reads to five samples/45 reads**. Denser reads can affect contention: inspected service/package dumps hold system-service monitors. Material Android 5.1.1 impact is **UNKNOWN**. Tonight tested only **four consecutive no-sleep samples per block**, with sleep-cadence blocks between them.

   The policy documents 400 ms as the default delay; its specific safety rationale is **UNKNOWN**. Removing it does not establish continuous field safety: observations remain serial and non-atomic. The 20-second expiry remains a **soft checkpoint**, after collection/assessment and after the span-complete break—not a hard operation deadline. [E1, E3, E5]

   **F2 — SUPPORTED gap improvement; UNKNOWN live sufficiency.**

   | Basis | Gap margin below 2000 ms |
   |---|---:|
   | Tonight’s measured no-sleep maximum | 515 ms |
   | Earlier worst gap minus nominal sleep: `2250−400` | 150 ms |
   | Conservative combination of earlier maximum sample and maximum residual: `2000−(1672+209)` | **119 ms** |

   The **119 ms** figure is a conditional budgeting estimate, not a future lower bound. It retains the first-use residual rather than assuming warm measurement-loop behavior transfers to the full collector. Earlier actual sleep was not separately measured.

   M5 absence also matters: tonight’s targeted package output was empty; earlier installed output was **1221 bytes**. Its measured command times overlap, so assigning a specific installation penalty is unsupported. Session variation is visible elsewhere: package enumeration reached **750 ms** earlier versus **578 ms** tonight without sleep. [E2, E3]

   **F3 — Final freshness remains the stronger sufficiency objection.**

   Earlier last-start→result-creation ages were **1656–1687 ms**, leaving **313–344 ms before** JSON serialization, return, readiness loading, intent saving, and process preparation.

   The saved no-sleep stress replay reached ages **1938/1953/1953 ms** at runner lines **64/67/19**: margins **62/47/47 ms**. Its mean-mode five-sample cases passed with at least **281 ms** final margin; stress-mode cases used four samples. Neither bounds a mixed-speed, cold, installed **five-sample** execution. The fifth sample adds replay and serialization work; its incremental cost is **UNKNOWN**.

   Conservative conclusion: **credit no guaranteed positive live final margin**. The observed simulated **47 ms** is inadequate evidence of robust sufficiency. Faster samples are **not proven necessary**, but remain necessary to investigate if complete installed-path measurements cannot establish repeatable headroom. Sleep deletion alone does not directly shorten the final sample. [E1, E2, E4]

   **F4 — Next separately authorized attempt must distinguish timing refusal from unsafe acceptance.**

   Record per-command timings/status/output sizes; sample starts/ends and field associations; first assessment, window replay, serialization, readiness-load and intent-save timings; exact ages at **64, 67, 19**; installed/provenance hashes; sample count; and whether an ARM process actually started.

   Timing, unsafe-state, unknown-output, or provenance refusals are acceptable **fail-closed outcomes**. Expiry after intent saving may leave `ARM_ATTEMPTED`; preserve and review without automatic retry. Repeated timing refusal disproves sufficiency. Acceptance with incomplete/stale evidence, or an ARM process starting after a failed boundary, indicates a new guard problem. A later permission-UI block challenges readiness’s predictive adequacy, even if sampled predicates passed. [E1, E5]

   **Verdict — apply with conditions: SUPPORTED as the narrow first candidate; UNKNOWN as live-qualified, safe-and-sufficient remediation.** Do not widen thresholds or characterize the refusal problem as resolved.

6. **Primary evidence for each finding**

   - **E1:** [Collector:67](/C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/scripts/Test-M5ArmReadiness.ps1:67), lines 67–81; [core:44](/C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/m5/M5ArmReadiness.ps1:44), lines 44–77; [runner:62](/C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/m5/Invoke-M5FutureSession.ps1:62), lines 62–68 and 19.
   - **E2:** `analysis/parallel-aa-receiver/m5-retry-live-20261026-174603/readiness-{42377042f28a48aca415a3c202c204c6,ca6157bd57e8447cbbb90f999bd7d497,255a9a215c0a44c299247adb878092c6}/`: `samples.json` timestamp lines 3/13, 16/26, 29/39, 42/52; `readiness.json:8`; associated `commands.json` and stdout sizes.
   - **E3:** [Latency summary:9](/C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/latency-20261026-204437/latency-summary.json:9), associated JSONL records; [measurement source:57](/C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/scripts/Measure-M5ReadinessLatency.ps1:57), lines 57–78 show reduced assessment and four-sample blocks.
   - **E4:** [Saved replay:348](/C:/Users/REDACTED/AppData/Local/Temp/claude/C--Users-REDACTED-Desktop-RDX-ReverseEngineering/6b8797e0-4208-4e67-9c1f-18ad6acc866f/scratchpad/harness-full/harness-results.json:348). SHA-256: `C01E8B1A067A44D695ECF483AFDAB9B1E67B0EAB606BDB1F538B8322A081A007`.
   - **E5:** Guard plan `analysis/parallel-aa-receiver/M5-RETRY-LOCKTASK-GUARD-PLAN.md:16–19`; decompiled `ActivityManagerService.java:9720–9722`, `PackageManagerService.java:10524`.

7. **Assumptions**

   Saved captures accurately represent their executions. The proposal means deleting the live collector’s line, preserving surrounding costs except where explicitly discussed.

8. **Unresolved uncertainties**

   Future latency tails, installed cold-path freshness, incremental fifth-sample cost, sustained device-load effects, and command arrival age after host process start are **UNKNOWN**.

9. **Exact diff summary**

   No review edits. Proposal deletes only live collector line 72: `Start-Sleep -Milliseconds 400`.

10. **Preservation checks performed**

   Collector, proposal, core, and runner SHA-256 values matched between checkpoints. All four frozen-artifact anchors matched, including both manifest-listed receiver DEX copies. Git status remained only the pre-existing untracked proposal directory. No key material or devices were accessed.