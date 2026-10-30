1. **Files inspected**

   Read `PROJECT-RULES.md` and `AGENTS.md` first, followed by:

   - Claude’s first-principles reassessment, both prior timing reviews, and the framework-parity reviews.
   - The collector, assessment core, runner, offline-suite source, retry-guard plan, and relevant Git history.
   - All three captures’ `samples.json`, `commands.json`, and `readiness.json`; sample-command stdout files 9–44; pre-loop SDK/release/ABI/path stdout; command stderr files.
   - Decompiled `PackageManagerService`, `Settings`, `ParceledListSlice`, and relevant activity/service-management sources.
   - The existing decompiled `Pm.java` under `C:/Users/REDACTED/.claude/jobs/6b8797e0/tmp/pm-check/`.
   - Claude’s specified mock, inspected without executing it.
   - Preservation manifests and the frozen artifacts, for hashing only.

   Capture abbreviations below: **A** = `42377042…`, **B** = `ca6157bd…`, **C** = `255a9a21…`.

2. **Files changed**

   None.

3. **Commands run**

   Read-only `Get-Content`, `Get-ChildItem`, `Get-Item`, `rg`, `Get-FileHash`, `git status`, `git log`, and `git diff`.

   Executed in-memory PowerShell arithmetic/text comparisons and JavaScript arithmetic countermodels. No collector, runner, mock, device command, build, or file-writing suite was executed.

   Some initial searches used unsupported Windows glob syntax. An initial aggregation also encountered PowerShell language restrictions; its purported comparison results were discarded. The corrected checks used permitted hashtables and direct property reads.

4. **Tests run and results**

   **Captured timing reconstruction — PASS.** Every sample contained nine successful shell commands. All 108 saved sample fields matched their corresponding raw stdout exactly. All 135 command records reported success without timeout; shell stderr was empty.

   | Capture | Sample durations 0–3, ms | Start gaps, ms | Gap − duration − nominal 400 ms |
   |---|---|---|---|
   | A | 1563, 1531, 1516, 1484 | 2141, 1953, 1953 | 178, 22, 37 |
   | B | 1532, 1531, 1531, 1516 | 2141, 1953, 1969 | 209, 22, 38 |
   | C | 1672, 1469, 1515, 1484 | 2250, 1891, 1953 | 178, 22, 38 |

   Thus Claude’s **178–209 ms first residual** and **22–38 ms subsequent residuals** are correct arithmetic. They are residuals after subtracting a *requested* 400 ms sleep; actual sleep duration was not separately measured.

   Other independently recomputed results:

   - `pm list packages -u`: **593–750 ms**, mean **653.67 ms**, 12 measurements. The per-capture means are **652.5, 652.5, and 656 ms**.
   - `pm path`: **578, 640, 609 ms**, mean **609 ms**, three pre-loop measurements.
   - Pre-loop `getprop`: **62–141 ms**.
   - Targeted M5 package dump: **78–110 ms**, mean **89.92 ms**.
   - Command-duration sums fall **15–16 ms short** of sample duration in **six of twelve samples**.
   - Final sample end → result creation: **172, 171, 172 ms**.
   - Last sample start → result creation: **1656, 1687, 1656 ms**, leaving **344, 313, 344 ms** before the 2000 ms limit.

   **Counterfactual arithmetic — PASS, conditional on unchanged costs.** Removing only the requested sleep produces gaps:

   - A: **1741, 1553, 1553 ms**
   - B: **1741, 1553, 1569 ms**
   - C: **1850, 1491, 1553 ms**

   These are arithmetic projections, not observations of a modified collector.

   The native offline suite was **not run**: its source creates files and invokes runner refusal paths.

5. **Findings**

   **F1 — CONFIRMED: Claude overstates what the timing decomposition establishes.**

   The residual arithmetic is correct, but “summed command times equal sample duration” is false for half the samples. More importantly, command timing includes host work: stdout/stderr draining, disposal, and two output-file writes occur before the recorded command end. Argument construction and other work also occur outside that command timer.

   Consequently, neither “all adb round-trips” nor a **60–90 ms fixed spawn floor** is established. The fastest combined measurement cannot isolate the host process-creation component.

   The stated `pm list` cost of 652–656 ms describes capture averages while concealing the **750 ms first-call tail**. That distinction matters when predicting a worst case. [E1, E2]

   **F2 — SUPPORTED: a large shared `pm` cost exists. UNKNOWN: whether VM startup accounts for most of it.**

   The Java client does more common work than Claude identifies. Before dispatching either `path` or `list`, it obtains the user service, package service, and package installer. Both paths then perform package-manager IPC.

   The list path additionally requests the complete package list before applying its text filter. The service iterates package settings, generates package records, and returns a parcelled list. Parcel construction, transfer, deserialization, service-lock contention, class loading, runtime initialization, process scheduling, and output handling remain competing costs.

   Similar `path`/`list` timings support a substantial common component. They do **not** measure that component’s composition: three pre-loop path calls are not controlled counterparts to twelve later list calls. The inspected Java source also does not establish the exact live `/system/bin/pm` launcher implementation.

   Therefore:

   - “Filtering still fetches the full list” is **CONFIRMED in the inspected source**.
   - “List size does not explain all the cost” is **SUPPORTED**.
   - “Mostly fresh-VM startup” remains **UNKNOWN**.
   - “Any replacement must avoid `pm` entirely” is an unnecessarily absolute conclusion. [E3, E4]

   **F3 — UNKNOWN attribution: the first-gap excess has several unmeasured host causes.**

   Between sample end and the next sample start, the collector performs collection insertion, object handling, assessment, loop conditions, and `Start-Sleep`. Candidate first-use costs include PowerShell execution/type initialization, regex/runtime initialization, allocation and GC, first sleep invocation, and scheduler delay. File activity or antivirus contention could indirectly delay this work.

   Ordinary synchronous adb transport latency belongs primarily **inside the recorded sample**, because those reads finish before `endMs`. It should not be offered as a direct explanation of the between-sample residual without an identified spillover mechanism.

   For the overall budget, additional candidates include Windows process creation, adb server/client IPC, transport scheduling, remote process startup, Binder contention, and output handling. The service dump alone contains approximately **165 KB per sample**; the four-sample JSON files are **875,925–876,490 bytes**. That workload deserves attention alongside the 4,403-byte package list.

   Clock quantization can blur small differences; it does not identify the source of the first excess. No separate timestamps isolate sleep, assessment, process start, output draining, or writes. The supplied mock contains no reproducible cold/warm benchmark establishing the claimed **74–118 ms versus 17 ms** attribution. [E1, E2, E5]

   **F4 — CONFIRMED: the governing principle is insufficiently specified.**

   Keeping thresholds and observation frequency is a useful constraint, but it is not a complete safety property. It must also preserve:

   - Which states and package namespaces are covered.
   - Actual observation intervals and ordering.
   - Lock-before/lock-after placement.
   - Output completeness, failure detection, and provenance.
   - Freshness through the runner’s final check.
   - The collector’s effect on the system being observed.

   Sample-start cadence is not identical to field-observation cadence. A timing-only countermodel used sample starts **0, 1800, 3600, 5400**, each lasting **1700 ms**. A field read at offsets **100, 1600, 100, 1600** has observation gaps **3300, 300, 3300 ms**, despite every sample-start gap being 1800 ms.

   Even fixed field cadence cannot exclude safe → unsafe → safe excursions between observations, including inside a bracketed sample. “Avoids F2 entirely” should mean preserving its specific temporal bound, not eliminating the underlying observability limitation.

   The defensible property is bounded, complete, conservative **pre-ARM evidence** under an explicit observation policy. It cannot establish continuously safe state or guarantee permission-dialog eligibility after the subsequent phone swap. [E2, E6, E7]

   **F5 — Approach 1: the strongest narrow candidate, but not established safe or sufficient.**

   **SUPPORTED:** removing sleep would eliminate the captured gap refusals under fixed-cost replay, without needing warm-up. **UNKNOWN:** whether warm-up reliably removes the remaining first-use excess on the actual execution path.

   Reasons to challenge immediate adoption:

   - The delay is documented as policy, although I found no justification for specifically **400 ms** in the inspected plan/history.
   - Service dumping runs under the activity-manager monitor; package dumping runs under the package-manager monitor. Denser reads can change contention and transition timing. Material live impact is **UNKNOWN**.
   - Removing sleep does not remove the five-second minimum: the collector measures sample-start span.
   - Subtracting the three sleeps leaves the captured spans at **4847, 4863, 4894 ms**. Each would require another sample under unchanged timings—**five samples rather than four**, with more commands, validation, memory, and serialization.
   - Every extra sample still participates in the core’s checks. More observations can detect more transitions, but also increase host cost and workload.
   - Warm-up must remain separate from qualifying observations and must not replace the first real assessment.
   - The “20 s overall expiry” is a loop checkpoint, not a hard execution deadline. Its check follows the successful-span break, and individual commands permit 15 seconds before timeout.

   **Final freshness:** sample duration is unchanged directly; additional replay and serialization can **worsen** the full path. Calling freshness simply “unchanged” misses the sample-count effect. [E2, E6, E8]

   **F6 — Approach 2: reject the supplied bookend model as equivalent evidence.**

   It removes package observations from the intervening samples. A forbidden package can appear and disappear between the two inventories without an active process or service being present at the sampled instants. This is a countermodel, not evidence that it happened.

   The mock also assigns the closing inventory to the last sample **after that sample’s recorded end and lock-after read**. The recorded interval consequently does not describe all the evidence attached to it.

   Its freshness claim fails even before accounting for extra work. Let `D` be the original final sample duration, `P` its package-list cost, and `H` subsequent host work:

   `original age = D + H`

   `bookend age = (D − P) + P + H = D + H`

   Using the captured final costs gives **1656, 1687, 1656 ms** either way. The extra closing assessment and additional samples can increase those ages.

   Moving the closing inventory before the recorded lock-after/end would restore honest bracket placement, but also restore its contribution to critical-sample duration. Retiming the sample to conceal older fields would not solve this. [E1, E2, E5]

   **F7 — Approach 3: exact-name behavior is supported, but semantic equivalence and coverage are missing.**

   In the inspected API 22 sources, the package argument is used as a package name; package records match by equality against **`ps.name` or `ps.realName`**, not prefix. Matching hidden system-package records can also be emitted. Thus “exact” needs an alias/record-section qualification.

   Concrete problems:

   - A factory package with an updated system version may produce ordinary and hidden-system records. A simple “one matching block” parser can misclassify this.
   - Missing, truncated, denied, malformed, and genuinely absent output require distinct handling; absence must not be inferred merely from a missing text match.
   - A finite list of known names cannot replace the current rejection of **every `com.rdx.*` and `com.rdxresearch.*` package**.
   - Claude mentions unknown `com.rdx.*` names but omits the second namespace.
   - The canonical plan says **M7 has no separate installed package**, so “known M6/M7 names” is not a complete inventory model.
   - Adding several dumps is not free; the measured 78–110 ms applies to the small M5 dump, not arbitrary factory/absent-package output.

   Package state need not await an operator command. Source permits authorized application/component changes and privileged installation; service launch clears stopped state, and settings clears `notLaunched`. A pending install or privileged actor supplies a possible asynchronous path. Whether any such actor operated during these captures is **UNKNOWN**. Also, the original name-only inventory never established factory enabled state.

   **Final freshness:** targeted reads add cost. A closing full list retains the bookend cost, so improvement is **not established**. [E3, E4, E8, E9]

   **F8 — Approach 4: plausible, but its proposed saving is overstated and its failure semantics need redesign.**

   Batching can remove repeated adb client/session setup. It does not automatically remove remote child processes, the Java `pm` client, Binder work, output transfer, or host persistence. The claimed removable **0.5–0.8 s** was never isolated.

   A replacement must reject missing, duplicated, reordered, stale, truncated, or cross-sample sections. A final shell success must not hide an earlier command failure. Fixed command content, per-command status, unambiguous framing, bounded output/time, and preserved raw evidence are required.

   The fixed getter must remain gated by framework verification, with lock-before first and lock-after last. A generic concatenated-string escape from the allowlist would enlarge the command surface.

   **Final freshness:** **LIKELY to improve if actual collection cost falls**, but buffering, parsing, and evidence writing could consume the gain. Magnitude is **UNKNOWN**. [E2, E7]

   **F9 — Approach 5: additional complexity without a demonstrated additional benefit.**

   A persistent shell adds cross-sample state, framing, buffered-old-output, reconnect, shell-death, backpressure, and cleanup failure modes. A healthy channel is not proof that its next returned text is current.

   It still starts remote utilities unless their execution model also changes. Therefore “biggest saving” is **UNKNOWN**, especially compared with one fixed batch per sample.

   **Final freshness:** potentially better through lower setup cost; potentially worse through buffering and queueing. It requires the same boundary instrumentation as batching, plus session-lifecycle tests. [E2, E7]

   **F10 — Final freshness remains a credible next refusal, not a demonstrated next refusal.**

   The measured **313–344 ms** margins are correct, but they come from refused runs. Their post-sample path includes window reassessment and failure/exception handling; successful-path timing is unmeasured.

   After result creation, the actual path still serializes three JSON files, returns to the runner, loads readiness, saves ARM intent, prepares a process, and checks freshness again. Moreover, the window function receives its `NowMs` **before** its reassessment loop, so that particular check does not charge the replay time. The runner’s later checks remain essential.

   Expiry after intent saving leaves `ARM_ATTEMPTED` recorded and requires preservation/review; it is not an automatic retry opportunity. A check immediately before host process start also does not bound subsequent device dispatch latency. [E2, E6, E7]

   **Ranked recommendation**

   1. **Investigate approach 1 first — SUPPORTED arithmetic; UNKNOWN operational qualification.** Separate sleep removal from optional warm-up. Require complete freshness-path measurement before adoption.
   2. **Investigate a new alternative: one per-sample `dumpsys package packages` query — SUPPORTED source capability; UNKNOWN latency.** The source supports the `packages` selector and dumps the complete settings inventory, potentially supplying inventory plus M5 facts in one query. This preserves unknown-name coverage better than approaches 2/3. It needs section-aware parsing, retained/hidden/user-state equivalence checks, and output-size measurement.
   3. **Fixed batching, approach 4 — SUPPORTED opportunity; UNKNOWN saving.** Preserve complete coverage and explicit failures.
   4. **Persistent shell, approach 5 — SPECULATIVE benefit beyond batching.**
   5. **Targeted/bookend hybrid, approach 3 — incomplete equivalence; do not treat as satisfying the governing principle.**
   6. **Bookends alone, approach 2 — reject the supplied implementation model.** Coverage is reduced and the claimed freshness improvement is unsupported.

   A separate host-side option is to move bulk persistence/replay work earlier, before a genuinely fresh final **complete** sample, while retaining every observation and all final checks. Its benefit is **UNKNOWN** until measured; it must not manufacture freshness by relabeling cached fields.

   No threshold widening or guard bypass is recommended. APK changes remain outside this review.

   **Minimum evidence before adoption**

   **Offline, separately from this read-only review:**

   - Actual-core tests at **1999/2000/2001 ms** for gap, duration, and final age; minimum-span boundaries; retained 5–15 s policy; collector expiry behavior.
   - All three captured sequences, including the additional-sample consequence of cadence changes.
   - A disarmed host harness covering serialization, readiness loading, intent saving, and all three runner freshness boundaries.
   - Cold/warm measurements that isolate assessment, sleep, process work, output draining, writes, and replay.
   - Approach-specific malformed/truncated/absent output, aliases, hidden records, retained packages, both project namespaces, command failures, framing, and session-lifecycle tests.
   - Demonstrated refusal with zero ARM process starts whenever evidence is incomplete or any freshness boundary expires.

   **Live confirmation, only in a separately authorized evidence-only session:**

   - Latency distribution and repeated first-use behavior on the pinned API 22 target.
   - Actual sleep and host-stage timing, sample count, output size, collection duration, and full freshness margin.
   - Command-output equivalence for any replacement query.
   - Whether denser dumps materially perturb responsiveness or transition behavior.

   None of these live confirmations was performed here.

6. **Primary evidence for each finding**

   - **E1 — F1–F3, F6, F10:** The three capture directories beneath `analysis/parallel-aa-receiver/m5-retry-live-20261026-174603/`. Sample timestamps are at `samples.json` lines **3/13, 16/26, 29/39, 42/52**. Matching command records and raw stdout establish the arithmetic and text comparisons reported in item 4. [A samples](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/m5-retry-live-20261026-174603/readiness-42377042f28a48aca415a3c202c204c6/samples.json:3), [B samples](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/m5-retry-live-20261026-174603/readiness-ca6157bd57e8447cbbb90f999bd7d497/samples.json:3), [C samples](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/m5-retry-live-20261026-174603/readiness-255a9a215c0a44c299247adb878092c6/samples.json:3).
   - **E2 — F1, F3–F6, F8–F10:** [Collector](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/scripts/Test-M5ArmReadiness.ps1:17): allowlist lines 18–27; timer/process/output writes 28–35; loop 67–74; result and serialization 78–81.
   - **E3 — F2, F7:** [Pm.java](C:/Users/REDACTED/.claude/jobs/6b8797e0/tmp/pm-check/decompiled/sources/com/android/commands/pm/Pm.java:87): common initialization 93–99; full-list fetch/filter 271–285 and 316–318; path lookup 1545–1565. SHA-256: `9FD2D716185FB8885E90DE081EEBC3C3BF79EB950FEB10A280AD968B9D2E514F`.
   - **E4 — F2, F7, new alternative:** [PackageManagerService](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/pm/PackageManagerService.java:3144): full-list generation 3144–3178; dump selection 10475–10498; synchronization 10524; settings dump 10724–10725. [Settings](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/pm/Settings.java:2940): exact name/alias matches 2946; renamed records 2963; hidden system records 2983–2993. [ParceledListSlice](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Framework/sources/android/content/pm/ParceledListSlice.java:99): additional parcel retrieval.
   - **E5 — F3, F6:** [Specified mock](C:/Users/REDACTED/AppData/Local/Temp/claude/C--Users-REDACTED-Desktop-RDX-ReverseEngineering/6b8797e0-4208-4e67-9c1f-18ad6acc866f/scratchpad/mock-readiness-test.ps1:24): fixed durations 24–27; reused opening inventory 34–40; closing read and substitution 49–54. SHA-256: `6E1E2D2B90D44C9CDE4915BCDD5534E9A0152D732DC3031DAE0704D59031A623`.
   - **E6 — F4, F5, F10:** [Core](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/m5/M5ArmReadiness.ps1:44): predicates 44–56; replay/order/span/freshness 59–77. [Guard plan](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/M5-RETRY-LOCKTASK-GUARD-PLAN.md:16): documented delay and policy, including discrete-observation limitation.
   - **E7 — F4, F8–F10:** [Runner](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/m5/Invoke-M5FutureSession.ps1:19): process-start check; lines 62–68 cover collection, loading, intent saving, and freshness checks; lines 68–70 establish the later service/phone-swap path.
   - **E8 — F5, F7:** [ActivityManagerService](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/am/ActivityManagerService.java:9720): service dumping under its monitor. [ActiveServices](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/am/ActiveServices.java:971): package unstopping. [Settings](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/pm/Settings.java:2604): stopped/not-launched transitions. Git history inspected: baseline `3fdd869`, collector changes through `74372c6`.
   - **E9 — F7:** [PackageManagerService](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/pm/PackageManagerService.java:10136): enabled-state authorization and mutation; installation authorization at 7104. [Guard plan](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/M5-RETRY-LOCKTASK-GUARD-PLAN.md:12): project-package scope and no separate M7 package.

7. **Assumptions**

   Captured timestamps, outputs, and file associations accurately represent the saved runs. Decompiled sources describe the supplied artifacts; source inspection alone does not establish every loaded/native runtime behavior.

   All projected savings assume unchanged surrounding costs unless explicitly stated otherwise. Countermodels demonstrate possible observation failures, not historical events.

8. **Unresolved uncertainties**

   **UNKNOWN:** actual sleep duration; precise first-gap attribution; VM startup’s fraction of `pm` time; future latency tails; live effects of denser querying; replacement-dump size/runtime; successful runner-path margin; whether any asynchronous package change occurred.

9. **Exact diff summary**

   None. Final `git diff --exit-code` returned **0**. Initial and final status both showed only the pre-existing untracked first-principles review.

10. **Preservation checks performed**

   The collector, core, runner, and offline-suite hashes matched between repeated checks. Frozen artifact hashes matched all four `PROJECT-RULES.md` anchors:

   - M5 APK: `A22E96490B9557AFF022893A8B8B7A08BB13CEC236E52704CDDAFA90A8EE8F40`
   - Disabled M6 APK: `D4DAC2DD8B2AFF1FA7B64BFB32D2A5E889854CCEB4B4A9F7AD5AEF89FB28761F`
   - Receiver DEX, both manifest-listed copies: `2FDBC63F2F9D63B764697D311AF89D460AE6B8E14B0FADABA9C9339F7FE7C235`
   - TLS qualifier APK: `86350131FFC5CBE5766E523AB03AE07D4C9F5EAD78F0570B68255C9A3999FC1F`

   No files were edited, no key material was read, and no device access or milestone action occurred.