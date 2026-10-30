**Verdict: apply with fixes. Do not apply the proposal unchanged: PRESERVE weakens the evidence and active-request protections.**

**1. Files inspected**

Aliases below identify exact files:

- **P:** `analysis/agent-reviews/proposed-runner-recovery/Invoke-M5FutureSession.proposed.ps1`
- **R:** `tools/m5/Invoke-M5FutureSession.ps1`
- **E:** `tools/m5/Test-M5SessionEndToEnd.ps1`
- **T:** `tools/m5/Get-M5ArmTimingReport.ps1`
- **H:** `tools/m5/Measure-M5ReadinessHostPath.ps1`
- **B:** `tools/m5/Test-M5TimingBoundaries.ps1`
- **C:** `tools/m5/M5ArmReadiness.ps1`
- **G:** `scripts/Test-M5ArmReadiness.ps1`
- **D:** `scripts/Convert-RdxM5Dump.ps1`
- **I:** `analysis/agent-reviews/INCAR-CHECKLIST-M5-RETRY.md`
- **N:** `analysis/parallel-aa-receiver/NEXT-CAR-SESSION-CHECKLIST.md`

Also inspected `PROJECT-RULES.md`, `AGENTS.md`, the pre-mortem, frozen preflight/verdict scripts, and `PermissionService.java`, `PermissionMachine.java`, `PrivateJournal.java` under `analysis/parallel-aa-receiver/m5-permission/source/com/rdx/fullscreen/m5permission/`.

Read relevant command records, logs and metadata from the specified 10-26/10-25 sessions and `latency-20261026-204437`.

**2. Files changed**

None.

**3. Commands run**

Read-only `Get-Content`, `Get-FileHash`, `Get-TimeZone`, `rg`, `git diff --no-index`, PowerShell DateTime expressions, and inline Python for text pins, replay-map inspection, in-memory dump decoding and hashes.

The independent diff reports **45 insertions, nine deletions**. SHA-256:

[Code block omitted from public report; see authored source where available.]

**4. Tests run and results**

| Read-only check | Result |
|---|---|
| Independent DateTime reproduction on PowerShell 7.6.8 | CONFIRMED approximately +4-hour shift and lost fractional seconds |
| Proposal DateTime branch | Preserved exact UTC value |
| H’s ordered runner snippets against P | **17/17 PASS**, unique and ordered |
| B’s runner/collector static pins against proposal/current collector | PASS |
| Replay-map reconstruction | 44 base entries; all referenced source files exist |
| Replay dump decoded after harness-style run-ID replacement | 3,926 bytes; SHA valid; embedded journal still names historical run |
| Old complete dump against P’s polling predicate | Accepted without any new dump |
| Unrecognized cleanup text against absence predicates | Accepted as package/process absent |
| Final hash comparison | 16/16 recorded review inputs unchanged |

The end-to-end rehearsal was **not executed**: it writes scratch output, prohibited by this read-only sandbox. Full-suite runtime results are **UNKNOWN**. The shell also reports `ConstrainedLanguage`; an auxiliary custom-object expression and direct DateTimeOffset invocation were refused. The successful UTC reproduction used permitted core DateTime operations.

**5. Findings**

- **BLOCKING / CONFIRMED — PRESERVE can skip a retrievable journal.**  
  P:111–116 checks phase/time, saves logs and unlocks UNINSTALL. It never establishes that RETRIEVE failed or that a journal is unavailable. Counterexample: finish a normal run, wait past the host deadline, invoke PRESERVE directly, then UNINSTALL. The durable journal is discarded without token/length/SHA reconstruction.  
  **Smallest fix:** retain the ambiguous-install recovery, but require attempted journal recovery and explicit evidence of irretrievability before unlocking arm-phase cleanup.

- **BLOCKING / SUPPORTED — PRESERVE can authorize cleanup while the app remains active.**  
  P:112 treats host deadline+3 seconds as sufficient. The app starts its own 300-second clock later, and expiration depends on its callbacks/pump. A sufficiently delayed start or pump permits PRESERVE→UNINSTALL during an active request. The admission path is confirmed; tomorrow’s occurrence is **UNKNOWN**.  
  **Smallest fix:** require positive current-run termination evidence. When termination is UNKNOWN, preserve logs without granting cleanup eligibility. A longer fixed grace period does not prove termination.

- **SHOULD-FIX / CONFIRMED — dump polling accepts an old completed token.**  
  P:96 does not distinguish pre-command tokens from the requested dump. During delayed processing of a repeated DUMP, the first poll can accept an older complete dump. If that token was already reconstructed before a later RETRIEVE failure, D:45’s `CreateNew` rejects it again.  
  **Smallest fix:** record existing tokens before DUMP and wait for a new complete token; handle an already reconstructed, hash-identical token explicitly.

- **SHOULD-FIX / CONFIRMED — rehearsal PASS overstates coverage.**  
  `dump-late` can pass without dump polling; run-ID rewriting leaves the encoded journal attributed to the old run; unsupported scenario names execute no scenario assertions. See section 6.  
  **Smallest fix:** synchronize full/tag replay visibility, assert expected call counts and verdict content, repair embedded journal/envelope consistency, and validate scenario names.

- **SHOULD-FIX / CONFIRMED conditional behavior — cleanup absence remains fail-open on unrecognized stdout.**  
  P:119 rejects positive package/process matches, but does not validate successful inventory syntax. Synthetic error text passes both absence predicates. Actual occurrence on this car is **UNKNOWN**. This weakness already existed in R.  
  **Smallest fix:** require recognized inventories and reject error text, following C:51–55.

**6. Primary evidence for each finding and claim**

| Claim | Assessment and primary evidence |
|---|---|
| **C1: not-issued re-ARM** | **SUPPORTED.** P:73 and P:22 throw before P:23’s `Process.Start`. Post-start explicit failure uses `"M5 command failed"` at P:28, outside the matched prefix. I found **no concrete double-request or attribution counterexample** under sequential execution and unmodified session files. My earlier blanket “do not permit another ARM” recommendation was too restrictive for these two proven pre-process refusals. |
| **Response-file discriminator** | **Unsound alone:** a process can issue ARM and fail before the response file is written. The conjunction at P:79 is supported because the matched literal throws precede process start. Existing response evidence causes conservative refusal to restore INSTALLED. |
| **C2: PRESERVE** | **FALSIFIED as preserving all safety properties.** P:111–119 allows both blocker paths above. `PermissionService.java:99–103` ignores dumps during active runs; `:130` starts the app clock; `:57–72` pumps it. `PermissionMachine.java:63–73` uses app monotonic time. The earlier pre-mortem F5 therefore remains unresolved and gains a destructive consequence. |
| **C3: Snapshot retry** | **SUPPORTED.** P:38 moves the existing directory aside before recreation; no deletion appears. A move/name collision fails rather than silently deleting evidence. |
| **C4: bounded polling** | **Partly supported.** P:87 performs at most ten reads with nine 500-ms sleeps and never resends ARM. P:96 performs at most ten tag reads, then P:98 captures full log. Old-token acceptance remains. These are call-count bounds: P:23 permits 30 seconds per call, so they are not five-/ten-second wall-clock bounds. |
| **C5: UI attribution** | **SUPPORTED.** P:105 preserves the journal verdict and adds UNKNOWN attribution for unscoped blocking; P:106 overrides only when `runScoped`. C:81–86 supplies that flag. Scope still extends to end-of-log if SERVICE_END is absent; it is not proof of a closed window. |
| **C6: uninstall recovery** | **SUPPORTED for interrupted cleanup**, subject to inventory validation. P:119 tolerates removal failures but retains checked calls for the subsequent queries. A completely successful UNINSTALL is not repeatable: P:117 excludes UNINSTALLED. |
| **C7: postcheck mismatch** | **CONFIRMED source correction.** P:121 saves POSTCHECK_MISMATCH on a completed comparison mismatch. Earlier snapshot/parser failures retain UNINSTALLED. |
| **C8: UTC defect/fix** | **CONFIRMED on this host.** R:11 creates a UTC DateTime; R:74 reparses its zone-free text. P:16 uses the DateTime directly. Its string fallback is source-supported; direct runtime execution was constrained by the shell. |
| **C9: pins** | **CONFIRMED static compatibility.** All 17 H:27–44 snippets remain unique and ordered. B:78–83’s runner/collector pins also match. |
| **Remaining pre-mortem failures** | Original F1/F2/F3 transitions are addressed in source. Original **F5 remains**, as above. F7’s complete installed-path freshness margin remains **UNKNOWN**; `latency-summary.json:9` explicitly says M5 was absent. |

Exact UTC reproduction:

[Code block omitted from public report; see authored source where available.]

Thus live RETRIEVE waits roughly four extra hours **when the current tag log lacks the accepted terminal/SERVICE_END pattern**. A retained terminal marker avoids the wait. The historical 10-25 `m5-before-dump.txt:21–22` contains DETACHED/SERVICE_END.

No other equivalent dangerous DateTime reparse was found in the inspected runner, collector, core, timing report or tests. T:8 handles DateTime directly; G/C use monotonic numbers for safety timing; E:121 deliberately loads date strings.

**C10 — scenario-by-scenario coverage**

| Scenario | What source actually exercises |
|---|---|
| `happy` | Full stage sequence and verdict-file existence; no expected verdict/content assertion. E:125. |
| `refuse-line67`, `refuse-line19` | Separate 2.1-second delay hooks, restored phase, zero first-arm invocations, successful subsequent sequence. E:67–68,126–131. Meaningful source coverage. |
| `install-transport-failure` | `FAIL` returns before changing S0. Tests failure-before-install, **not installation succeeded but reply was lost**. E:43–44,132–136. |
| `armed-marker-late` | First two S2 tag reads empty; immediate-only ARMED confirmation would fail. E:137–138. |
| `dump-late` | Only tag reads are delayed. S3 full log is immediately complete, so a runner reading full log immediately can pass without polling. E:102–103,139–140. |
| `postcheck-partial` | First S4 pull fails, retry and preserved partial directory are asserted. E:141–143. Does not exercise partial INSTALL baseline or preservation mismatch. |
| `uninstall-repeat` | First process query fails after removal; repeated uninstall returns nonzero `Failure`; subsequent absence checks succeed. E:144–146. Meaningful interrupted-cleanup coverage. |
| `retrieve-after-deadline` | Lacks terminal marker, checks early refusal, manually expires host deadline, retries. E:147–149. Exercises UTC bug, not delayed app termination. |
| `armed-never-preserve` | Hides ten ARMED reads and manually expires host time. Fake device already entered S2; no active app clock or missing private journal is modeled. E:150–154. |

Additional harness evidence:

- E:38–48 implements state/key counters, nonzero FAIL exits and transitions. `FAIL` changes no state; `FAILURE-TEXT` occurs **after** the uninstall transition. Transport timeouts and ambiguous committed operations are absent.
- E:91 changes plain run-ID text but not Base64 chunks. Independent decoding produced:

  ```text
  envelope run=m5_REVIEW_NEW_RUN
  decoded journal run=m5_270c93bb178648759beda65ed9593e72
  SHA256 valid=True
  ```

- E:124 has no rejecting default; E:156 adds a passing forbidden-command check even for an unknown scenario. E:160 treats zero failed checks as PASS and does not throw on failed assertions.
- No scenario tests C5’s attribution branches, C7’s mismatch branch, genuine post-start ARM ambiguity, stale dump tokens or delayed active termination.

**Checklist disagreements**

- I:6’s “every failure”/“UNINSTALL is always reachable” is unproven and relies on the unsafe PRESERVE gate.
- I:51,61 and N:16 say cleanup stages are repeatable without qualifying partial versus completed stages; P:117/120 reject already completed phases.
- I:90 still says the runtime getter was never exercised live, contradicting I:82 and N:13.
- T:44–45 scans the cumulative console and prioritizes any old process-start refusal. After a successful retry, `consoleRefusal` can still describe an earlier attempt. Smallest fix: scope console analysis to the latest ARM attempt.

**7. Assumptions**

Sequential operator-driven stages; reviewed files remain unchanged; no manual session-state edits. The proposal is reviewed as a replacement for R, not as directly executable from its proposal directory.

**8. Unresolved uncertainties**

Real installed-path timing, delayed service scheduling, reconnect failures, log rotation, grant/callback behavior, and complete rehearsal runtime success remain **UNKNOWN**. Replay does not establish those behaviors. They can still require abort/recovery; zero in-car edits cannot be guaranteed from this harness.

**9. Exact diff summary**

No task edits. The inspected proposal differs from live by **45 insertions and nine deletions**.

**10. Preservation checks performed**

All 16 recorded review-input hashes remained unchanged. The four frozen artifact anchors matched, including both manifest-listed receiver DEX copies. No rebuilds, key-material reads, runner/collector execution, ADB/device operations, prohibited Git mutations or milestone changes occurred.