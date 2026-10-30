1. **Files inspected**

   Read `PROJECT-RULES.md`, `AGENTS.md`, and `analysis/agent-reviews/CLAUDE-READINESS-TIMING-RECONCILIATION.md` first.

   Inspected both new tools, `tools/m5/M5ArmReadiness.ps1`, `scripts/Test-M5ArmReadiness.ps1`, the runner, and frozen preflight source; all three specified captures’ timing JSON; saved smoke/full harness results; generated variant collectors and core copies; six existing mutation fixtures; preservation-manifest entries; and relevant decompiled Android service methods.

   Below, **H** means the supplied scratchpad’s `harness-full` directory. Its [results file](C:/Users/REDACTED/AppData/Local/Temp/claude/C--Users-REDACTED-Desktop-RDX-ReverseEngineering/6b8797e0-4208-4e67-9c1f-18ad6acc866f/scratchpad/harness-full/harness-results.json:1) has SHA-256:

   `C01E8B1A067A44D695ECF483AFDAB9B1E67B0EAB606BDB1F538B8322A081A007`

2. **Files changed**

   None.

3. **Commands run**

   Read-only `Get-Content`, `Get-ChildItem`, `Get-FileHash`, `rg`, `Get-Command`, `git status --short`, and `git diff --no-index`.

   Executed the boundary suite and its six previously created mutation copies using `pwsh -NoProfile -File`. Performed read-only timing reconstruction, saved-result comparisons, and an in-memory string-order counterexample.

   Some exploratory PowerShell expressions failed because of constrained-language restrictions; two proposed in-memory core-mutation executions did **not** execute. Those failures are excluded from test-success claims. Consulted primary AOSP Android 5.1.1 sources online.

   Did **not** execute the harness, collector, runner, compiler, real/fake adb, or any device command.

4. **Tests run and results**

   - **Boundary suite:** exit `0`; `PASS=true`, `checks=38`, `failed=[]`.
   - **Existing mutations:** all six exited `1` with relevant assertion failures: duration, gap, final precheck, runner freshness, span, and start-order removal. This independently confirms the reported six mutation detections.
   - **Saved matrix consistency:** `rows=40 mismatches=0` when comparing each row’s durations, gaps, sample count, result, and created age against its saved samples/readiness files.
   - **Variant inspection:** current collector copy is byte-identical; generated changes match the declared replacements. All five copied cores hash to the current core.
   - **Static-order counterexample:** after removing the searched-for line-64 expression, the assertion reported `checkIndex=-1; armIndex=9038; passes=True`.
   - Preservation checks passed as described in item 10.

5. **Findings**

   **F1 — The harness’s unconditional “no real ADB, no device” guarantee is too strong.**

   Its ordinary inspected path uses an explicit fake executable, with no real-adb fallback or runner invocation. However, line 55 interpolates the user-controlled output path into executable PowerShell source:

   ```powershell
   powershell.exe -NoProfile -Command "Add-Type -Path '$fakeDir/...' ..."
   ```

   An apostrophe in that path breaks quoting; a crafted path can inject PowerShell statements. Therefore, arbitrary command execution—including a real-device command—is possible through that construction. I did not execute an injection.

   Fresh-directory checking also does not establish a scratch-only location or resolved-path containment. With an ordinary fresh output tree, I found no direct write to the original session or frozen files; that narrower statement is supported.

   **F2 — The runner mirror is incomplete, and snippet checks do not establish fidelity.**

   The real runner invokes its `Adb` function with the complete arm argument array, performs function binding, and adds every argument before line 19. The mirror skips that function call and constructs only:

   ```text
   -s SERIAL shell am startservice
   ```

   It omits the component, action, extras, and associated argument construction. It also captures collector output through `Out-String`, whereas the runner emits it directly. These differences have unmeasured, potentially opposing timing effects.

   The mirror stops before `Process.Start()`. Consequently, `wouldReachArmCommand` means **three copied predicates passed**, not that the actual runner reached process start or that a device received the command within two seconds.

   The drift guard checks string presence independently. It accepts reordered snippets, additional intervening work, or preserved snippets in comments/dead code. It does not pin the full control flow or argument list.

   **F3 — The replay is useful for host-path exploration, but its remaining-margin accuracy is unproven.**

   Calibration subtracts a median of five fake executions covering spawn, read, and file writes. This approximates aggregate elapsed time; it does not isolate real spawn, device execution, transport, and persistence costs.

   Important differences:

   - The fake sleeps, then writes the complete captured output. Real output can stream while work proceeds.
   - It has no adb-server connection, USB transport, head-unit execution, or transport contention.
   - It replays the first output for each key on every sample, always successfully with empty stderr. Dynamic outputs and failure paths are absent.
   - Pulls become local `File.Copy` operations.
   - Fixed mean/max delays erase live distributions and correlations. Per-key maxima combine observations that did not necessarily occur together and are **not a future upper bound**.
   - Sleep scheduling and the observed roughly 15–16 ms timestamp increments matter when the smallest claimed margin is 31 ms.
   - Forty collectors run in one process, in fixed variant order. Later variants inherit warmed host execution paths; warm-up comparisons are confounded.

   The smoke run does **not** establish accuracy within 31–78 ms. Its first gap, 2094 ms, undershoots the three live first gaps, 2141–2250 ms, by **47–156 ms**. Its later gaps, 2015/2000 ms, exceed the live later-gap range, 1891–1969 ms. Its created age, 1704 ms, exceeds live 1656–1687 ms by **17–48 ms**.

   Thus the bias changes with the stage: optimistic for the cold first gap, pessimistic for later gaps and created age. “Close enough” for a narrow freshness margin remains **UNKNOWN**.

   **F4 — The boundary suite is sound in several places, but “pins every timing boundary” is overstated.**

   The isolated middle-sample duration test, `Clean`, and exact-single-reason `Only` checks prevent the main content/multiple-reason masking concern. The six mutations genuinely are caught.

   Missing or weak coverage includes:

   - No executable boundary tests for the collector’s 20-second expiry or 15-second process timeout.
   - No integration test showing expiry between the pre-replay `NowMs` capture and runner checks.
   - No runner-freshness acceptance at minimum `sampleCount=2` or maximum valid policy `15`; its valid fixture uses count `4`, policy `5`. Tightening those runner limits to `3` or `14` would leave the represented cases unchanged.
   - No explicit 1999 ms final/runner freshness case, despite the broader claim.
   - Static presence checks do not test semantics, and the order assertion accepts a missing first expression because `IndexOf` returns `-1`.
   - Duration acceptance fixtures use 1500 ms start gaps with 1999/2000 ms durations—overlapping samples the serial collector cannot produce. They test the pure core, not collector behavior.

   The collector’s 20-second check is also a **soft loop check**, not a hard whole-operation deadline: it occurs after command execution and assessment, and after the span-complete break. Individual commands have their separate 15-second wait.

   **F5 — Deferred writes are the declared edit, but change evidence preservation and can worsen final freshness.**

   An ordinary caught mid-loop throw still reaches the flush after `catch`. Buffered outputs, including a command that subsequently fails its status check, are therefore written on that normal failure path.

   But termination before the flush loses all buffered stdout/stderr. A flush failure occurs outside the collection `try/catch` and can prevent the JSON artifacts from being written. This weakens preservation relative to writing each completed command immediately. It remains fail-closed for arming because the runner cannot obtain a valid fresh result.

   It also defers **pre-loop** stdout/stderr writes. Those previously occurred before the last-sample freshness interval; now they consume that interval.

   The matrix demonstrates this tradeoff: mean-mode worst line-19 age increases from **1719 ms** for no-sleep to **1781 ms** for no-sleep plus deferred writes. Moving persistence outside the sample timer does not remove it from the runner’s timing budget.

   **F6 — “Warm-up is negligible” is not established.**

   The dummy empty sample does not exercise the successful parser path fully: several predicates return early. The empty `catch` hides whether warming completed.

   It does not bypass actual sample validation, so I found no acceptance bypass from this edit. Nevertheless, the experiment should record whether warming succeeded. Its placement after other variants in an already-used process prevents a clean cold-start comparison.

   **F7 — Several conclusions go beyond the results.**

   The supplied full matrix contains **four runs per cell**, forty total. The following are minimum observed margins in milliseconds; each column independently takes its worst run.

   | Variant / mode | Mirror reach | Gap | Sample duration | Line 64 | Line 67 | Line 19 |
   |---|---:|---:|---:|---:|---:|---:|
   | Deferred / mean | 4/4 | 0 | 421 | 297 | 297 | 297 |
   | Deferred / max | 0/4 | −265 | 157 | refused | — | — |
   | No-sleep / mean | 4/4 | 359 | 375 | 297 | 281 | 281 |
   | No-sleep / max | 4/4 | 125 | 140 | 62 | 47 | 47 |
   | No-sleep + deferred / mean | 4/4 | 375 | 375 | 219 | 219 | 219 |
   | No-sleep + deferred / max | 4/4 | 141 | 157 | 63 | 63 | 63 |
   | No-sleep + deferred + warm / mean | 4/4 | 375 | 390 | 265 | 265 | 250 |
   | No-sleep + deferred + warm / max | 4/4 | 172 | 171 | 31 | 31 | 31 |

   Current collector: **0/4 reach in both modes**, with worst gap margins −63 ms mean and −297 ms max.

   Exact core-window precheck margins cannot be recovered: its `NowMs` is not logged. Using the later `createdMs` gives conservative lower bounds for successful no-sleep cells of **313/78 ms**, no-sleep+deferred **313/141 ms**, and warm combination **359/109 ms**, mean/max respectively.

   Conclusions:

   - **SUPPORTED:** no-sleep passed every saved mirrored check; final freshness has much less headroom than polling gaps in max mode.
   - **UNSUPPORTED as a universal claim:** sleep removal is necessary. Deferred-only mean runs also passed, albeit at zero gap margin.
   - **UNSUPPORTED:** sleep removal is insufficient. It was sufficient in every saved no-sleep replay. Live reliability is **UNKNOWN**.
   - **UNSUPPORTED:** only cheaper samples can improve freshness. Assessment/replay, persistence, serialization, and runner preparation also contribute.
   - **SUPPORTED approximately:** the last sample dominates age.
   - **UNSUPPORTED as measured stage attribution:** “60–80 ms serialization.” The harness groups operations together. No-sleep max runs have only **0–16 ms** from creation to collector return; deferred runs include the deferred flush in that interval.

   None of these margins qualifies the live path. The smoke/live discrepancies already exceed the smallest margins.

   **F8 — Concurrent middle reads are a plausible experiment, not an established fix.**

   Keeping lock-before completed before launching middle reads, and issuing lock-after only after **all seven** middle reads finish, preserves endpoint ordering. Neither the existing serial bracket nor a concurrent bracket proves continuous inactivity: inactive → active → inactive between endpoints remains possible. Neither produces an atomic snapshot.

   The candidate introduces concrete implementation requirements:

   - Preserve field identity and actual per-command start/end times; completion order must not become observation order.
   - Do not call the existing `ReadDevice` concurrently unchanged. `$records.Count` filenames and its mutable generic list are not a concurrency-safe recording design.
   - Drain stdout/stderr for every process while it runs; retain every completed/partial result on failure.
   - On any failure or timeout, refuse the sample and terminate/reap remaining work. Do not leave observations running into later samples.
   - Preserve binary qualification, allowlisting, all fields, namespace coverage, and both lock reads.
   - Measure per-field observation intervals, not just sample-start gaps.

   Android 5.1.1 adb supports separately identified streams and shell subprocesses; this establishes architectural feasibility, **not a safe or performant seven-way limit on this head unit**. [AOSP protocol](https://raw.githubusercontent.com/aosp-mirror/platform_system_core/android-5.1.1_r1/adb/protocol.txt), [AOSP services implementation](https://raw.githubusercontent.com/aosp-mirror/platform_system_core/android-5.1.1_r1/adb/services.c).

   The inspected decompilation shows activity and service dumps sharing the ActivityManager monitor, and package enumeration/package dumps sharing the package monitor. Parallel processes therefore include serialized work and contention. Exact corresponding behavior on the live build, concurrency capacity, and latency improvement are **UNKNOWN**.

   The “slowest read plus two locks” estimate is an idealized critical path, not a measured duration. Faster samples also require more samples to span five seconds, increasing replay and evidence serialization.

   **Ranked recommendation**

   1. **First candidate for validation: remove the 400 ms sleep alone.** It is the narrowest demonstrated change and preserves immediate raw evidence. Do not adopt it as live-qualified from this harness.
   2. **Measure cheaper sampling alternatives:** compare sequential batching and bounded concurrency, including seven-way only as an explicitly authorized measurement case. Batching preserves serial order but needs unambiguous framing and per-subcommand failure evidence; the current allowlist does not accept an arbitrary combined shell string.
   3. **Investigate the single package-dump alternative separately**, preserving full inventory semantics and handling hidden/retained records.
   4. **Do not adopt whole-loop deferred writes or dummy warm-up on this evidence.**
   5. **Do not accept 31–78 ms replay margins as adequate live evidence, and do not widen thresholds.**

   A separately authorized read-only measurement session must record cold and warm repetitions, command launch/completion and first/last-byte times, output sizes, actual sleep, persistence, assessments, window replay, serialization, and all three disarmed runner boundaries using the **complete** argument-construction path. Compare serial, batching, and concurrency under comparable conditions; record contention, failures, disconnects, and per-field intervals. No install or ARM is needed to measure latency; such measurements must not manufacture fresh-install readiness.

6. **Primary evidence for each finding**

   - **F1:** [harness:13](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/m5/Measure-M5ReadinessHostPath.ps1:13), lines 35–55, 107–118, 143. Explicit fake path and unescaped compiler-command interpolation.
   - **F2:** [runner:14](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/m5/Invoke-M5FutureSession.ps1:14), lines 14–20 and 62–68; [harness:118](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/m5/Measure-M5ReadinessHostPath.ps1:118), lines 118–132; snippet checks at lines 20–32.
   - **F3:** harness lines 39–48, 61–85 and 113–118; smoke `harness-results.json`; original captures’ `samples.json`/`readiness.json`. Independently reconstructed live durations were 1469–1672 ms.
   - **F4:** [boundary tests:30](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/m5/Test-M5TimingBoundaries.ps1:30), lines 30–75; [core:56](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/m5/M5ArmReadiness.ps1:56), lines 56–77; collector lines 30–35, 68–74. Command outputs in item 4 establish mutation detection and the `-1` counterexample.
   - **F5/F6:** [variant replacements:90](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/m5/Measure-M5ReadinessHostPath.ps1:90), lines 90–104; [collector:76](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/scripts/Test-M5ArmReadiness.ps1:76), lines 76–82. Generated diffs contain only those declared replacements.
   - **F7:** H `harness-results.json`, rows at lines 28–827 and summaries at 829–929; independently checked against all forty saved run directories.
   - **F8:** [collector:32](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/scripts/Test-M5ArmReadiness.ps1:32), lines 32–35 and 68–74; `decompiled/Services/sources/com/android/server/am/ActivityManagerService.java:6745`, `:9611`, `:9720`; `decompiled/Services/sources/com/android/server/pm/PackageManagerService.java:3144`, `:10524`. These show endpoint getter behavior and shared monitors, not measured concurrency performance.

7. **Assumptions**

   Timing JSON is treated as saved capture evidence. Reconstructed margins describe the supplied executions, not a future latency distribution.

   Safety statements about the ordinary harness path assume the inspected source, ordinary filesystem paths, and no intervening executable replacement.

8. **Unresolved uncertainties**

   Live successful-path freshness, tail latency, device-command arrival age, seven-way concurrency behavior, batching/package-dump latency and parser equivalence, and preservation under abrupt termination remain **UNKNOWN**.

   The current harness does not separately timestamp enough stages to resolve the claimed causal breakdown.

9. **Exact diff summary**

   None. No files edited.

10. **Preservation checks performed**

   Start/end hashes of both new tools, core, collector, runner, rules, and `AGENTS.md` remained unchanged. Core/collector/runner hashes match the saved harness metadata. All five variant core copies match the original core.

   All four frozen preservation anchors matched, including both manifest-listed receiver DEX copies. Git status remained the same as at entry.

   No key material read; no harness execution, compilation, device access, milestone action, or Git mutation performed.