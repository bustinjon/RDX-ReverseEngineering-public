1. **Files inspected**

   Read `PROJECT-RULES.md`, `AGENTS.md`, and the previous `CODEX-TIMING-HARNESS-ATTACK.md` first.

   Inspected:

   - `scripts/Measure-M5ReadinessLatency.ps1`
   - `tools/m5/Measure-M5ReadinessHostPath.ps1`
   - `tools/m5/Test-M5TimingBoundaries.ps1`
   - Collector, readiness core, future-session runner, and frozen-preflight source.
   - Saved capture C command records and package-output sizes.
   - Relevant decompiled framework dispatch, ActivityManager, ActivityStackSupervisor, PackageManager, Settings, WindowManager, DisplayManager, and Watchdog source.
   - Preservation manifest, current-work checkpoint, and relevant existing operator documentation.
   - AOSP Android 5.1.1 adb subprocess implementation.

2. **Files changed**

   **None.** No report file was created.

3. **Commands run**

   Read-only `Get-Content`, `Get-Item`, `Get-FileHash`, `rg`, and `git status --short`.

   Executed:

   ```text
   pwsh -NoProfile -File tools/m5/Test-M5TimingBoundaries.ps1
   ```

   Performed in-memory text counterexamples against the pin extractor and ordered-snippet guard. These did not execute modified scripts.

   Some exploratory AST checks failed under constrained language; Python was unavailable. Their outputs are excluded from successful-test claims.

   Did **not** execute the harness, measurement script, collector, runner, compiler, adb, fastboot, or any device operation.

4. **Tests run and results**

   **CONFIRMED — boundary suite:**

   ```json
   {
     "PASS": true,
     "checks": 45,
     "failed": [],
     "adbInvocations": 0,
     "filesWritten": 0
   }
   ```

   **CONFIRMED — static counterexamples:**

   ```text
   PINS currentMatches=1 groups=4
   PINS commented-old-before-edited-active acceptsOld=True
   ORDER snippets=17 original=True addedDelayAfterFreshness=True
   ORDER earlierDuplicateArmSnippet=True totalArmSnippetOccurrences=2
   ```

   The delay counterexample inserted three seconds immediately before `Process.Start`, preserving the searched snippets.

   **UNKNOWN — independently reproduced 9/9 mutation detection.** I did not execute mutation copies. The new assertions directly cover the reported sample-count, policy, and freshness cases, but that does not independently establish all nine mutation results.

5. **Findings**

   **Overall disposition — SUPPORTED: revise before live use.** The inspected command path contains no explicit device mutator, but cleanup, evidence preservation, pin extraction, and concurrent timing defects remain. Seven-way concurrency should remain excluded from the first session.

   **L1 — SUPPORTED: the current command path is explicitly read-only; its default allowlist is narrower than the collector’s.**

   Every constructed command passes through `Test-Allowed`. The default set omits the collector’s boot-ID read, installed-package path query, and installed-APK pull. It preserves the nine sampling commands and their serial order.

   `-IncludePackageDumpAll` deliberately widens the collector’s set by one exact command: `dumpsys package packages`. Therefore, “at least as strict” is true for the default mode, **not literally true with that switch**.

   I found no reachable `install`, `push`, `am start/stop`, settings write, reboot, root, remount, or lock-task setter. Argument construction uses `ProcessStartInfo.ArgumentList`, without user text interpolated into shell commands.

   This assumes a trusted, unchanged `$AdbPath` executable and imported core. The script only checks that the supplied executable exists; it does not authenticate it. Its `deviceMutation='NONE'` describes intended commands, not proof that Android writes no incidental logs or caches.

   **L2 — CONFIRMED: current getter gating matches the collector, but pin extraction is not robust against collector edits.**

   Current execution performs identity verification, framework pull/hash verification, then services pull/hash verification, and only then enables transaction 217. No current getter precedes these checks. Both scripts accept the same independent framework/services hash sets.

   Missing or reformatted pin text fails closed. However, the regex searches raw text and accepts its **first** match, including comments or inactive code. My in-memory counterexample retained the old pin tuple in a comment and changed the active framework hash; extraction still accepted the old tuple.

   Thus “the two can never disagree” is false. A collector edit can leave this tool accepting hashes the active collector no longer accepts—even if no active pin declaration remains.

   Use one shared, data-only pin definition, or enforce extraction from a uniquely identified active declaration. Do not treat the existing regex as a drift guarantee.

   **L3 — CONFIRMED: concurrent launch failures and interruptions can leave processes unmanaged.**

   Positive aspects:

   - Both output streams begin asynchronous draining immediately after each launch.
   - Records are added sequentially during completion handling; there is no concurrent list mutation.
   - On ordinary completion failures, the loop attempts to complete the remaining handles.
   - `lockAfter` occurs only after all middle handles complete successfully.

   Remaining defects:

   - Handles are assigned only after the launch loop finishes. If a later `Start-Read` throws, earlier processes have no cleanup path.
   - Neither serial nor concurrent operation has `finally` cleanup.
   - Stream-read, kill, wait, or persistence exceptions can bypass disposal.
   - Ctrl+C does not have a guaranteed cleanup/persistence path.
   - Detecting one failed middle read does not cancel outstanding peers.

   **CONFIRMED:** the 15-second timeout begins when each handle reaches `Complete-Read`, not at launch. Seven simultaneously stuck processes can therefore receive approximately seven successive 15-second waits, plus overhead. This is not a 15-second sample deadline.

   Killing a host adb client also does not establish cancellation of an already executing remote Binder operation.

   **L4 — CONFIRMED: concurrent per-command durations are incorrectly attributed.**

   `exitedMs` is captured after the handle is waited/drained in launch order. It is not the process’s actual exit timestamp.

   Counterexample: the first process takes ten seconds; the second finishes in 100 ms. The second record still receives an `exitedMs` around ten seconds because it is processed second. Its reported duration also includes earlier handles’ completion and persistence work.

   Whole concurrent sample duration remains useful as host-observed wall time. Its individual command distributions cannot establish actual command completion times or field observation intervals.

   **L5 — CONFIRMED: failure evidence is only partially durable, and COMPLETE does not mean valid observations.**

   Ordinary caught failures normally reach final JSON serialization, and completed command stdout/stderr are persisted immediately. However:

   - Command metadata, completed-sample metadata, and summary remain memory-only until the end.
   - A failed sample has no explicit partial-sample record.
   - Interruption can leave raw files without their argument/timestamp mapping.
   - A write failure can prevent the current record or final JSON artifacts.
   - Pin-parsing failure occurs before the main `try`, after output-directory creation.
   - A caught failure prints `INCOMPLETE` without an explicit failing process exit.

   The script does not interpret lock replies, foreground, or dump content. An active/unknown getter, Diagnostics foreground, or command error printed to stdout can still culminate in `COMPLETE` when process status and stderr pass.

   This is particularly relevant to legacy shell transport: AOSP Android 5.1.1 connects shell stdout and stderr to the same PTY. Checking host stderr alone cannot establish successful remote command content. [AOSP subprocess implementation](https://raw.githubusercontent.com/aosp-mirror/platform_system_core/android-5.1.1_r1/adb/services.c)

   **L6 — SUPPORTED: useful serial measurements; insufficient evidence for the complete reconciliation.**

   | Requirement | Assessment |
   |---|---|
   | Serial per-command distributions | Captured, including host persistence overhead |
   | Sample durations and start gaps by cadence | Captured |
   | Requested versus actual sleep | Actual elapsed sleep summarized; individual sleep records discarded |
   | Output sizes | UTF-8 re-encoding size captured; not raw transport-byte measurement |
   | Cold versus warm | First/subsequent samples recoverable, but cadence comparison is confounded by fixed order |
   | Concurrency effect | Whole-sample comparison possible; individual timings distorted |
   | First/last-byte timestamps | Missing |
   | Per-field observation intervals | Missing; launch-to-completion bounds are only approximate in serial mode |
   | Persistence-stage duration | Not isolated |
   | Assessment, window replay, serialization, runner boundaries | Missing |

   Sleep400 always runs before nosleep, and concurrency runs last. Consequently, faster later phases cannot be attributed solely to cadence or concurrency.

   **SUPPORTED:** absent-M5 package dumps exercise a different output path. `Settings.dumpPackagesLPr` emits package details only for matching packages. Saved installed-M5 capture C produced 1,221-byte package outputs with command durations of 78–110 ms.

   **UNKNOWN:** the absent-versus-installed timing difference on the car. Do not treat absent-M5 sample totals as exact installed-collector predictions or assume the distortion is negligible. Conversely, no install should be introduced merely to improve this measurement.

   Four or twelve samples also do not establish a reliable tail-latency bound. The reported p95 uses a lower order statistic; with four observations it selects the third, not the maximum.

   **L7 — SUPPORTED: seven-way concurrency introduces credible contention; harmful outcomes are unquantified.**

   The reads are not independent:

   - Activity and service dumps share the ActivityManager monitor.
   - Package dumps and package enumeration share the package monitor.
   - Window and display dumps also hold service locks.
   - ActivityManager’s watchdog monitor acquires the same ActivityManager lock.

   **LIKELY:** parallelism includes serialized work, extra Binder/shell load, and possible Honda UI latency.

   **SPECULATIVE:** these exact measurements cause an ANR, watchdog restart, or Honda Diagnostics transition. No measured probability or live counterexample establishes that. The inspected watchdog does contain a 60-second default and a system-process kill path, so long monitor blockage is a real mechanism, not proof this workload reaches it.

   No explicit command launches Diagnostics or changes lock-task state. An indirect Honda response to load, connection state, or failure remains **UNKNOWN**.

   Keep concurrency excluded. A later lower bounded experiment may be reasonable after cleanup and timing corrections, but neither two-way nor seven-way operation is presently qualified as safe. Do not substitute a modern dumpsys timeout assumption for an established target-build limit.

   **L8 — CONFIRMED: current runner integration does not accept this as readiness.**

   The summary is `latency-summary.json`, declares measurement-only scope, and uses `COMPLETE/INCOMPLETE`. It lacks the required readiness identity/freshness fields. The runner creates its own fresh guard directory and invokes the actual collector.

   Generic `commands.json`, `samples.json`, and `schema=1` names can confuse human analysis or filename-based tooling, but I found no current readiness-acceptance path. A distinct schema identifier and explicit artifact type would improve separation.

   **Previous-finding fix verification**

   | Previous finding | Disposition |
   |---|---|
   | **F1: compiler interpolation** | **COMPLETE by inspection:** scriptblock parameters and `-args` replace executable string interpolation. Harness execution was not repeated. |
   | **F1: output containment** | **PARTIAL:** ordinary lexical project-tree paths are refused. `GetFullPath` plus prefix comparison does not establish physical containment through junctions/aliases. No reparse-point attack was executed. |
   | **F1: real-adb coincidence** | **COMPLETE for the stated lexical check:** explicit refusal exists; this is not executable-authenticity verification. |
   | **F2: mirror argument construction** | **COMPLETE by inspection:** `MirrorAdb` receives the full arm array, constructs arguments, and stops before `Start`. `Out-Host` and `mirroredChecksPassed` corrections are present. |
   | **F2: drift/fidelity guard** | **PARTIAL:** broader ordered checks exist, but inserted work still passes. Global uniqueness is also incorrect: duplicates before the selected occurrence are missed. Both counterexamples passed. |
   | **F4: vacuous order assertion and missing acceptance cases** | **COMPLETE for the listed additions:** nonnegative indexes, count 2, policies 5/15, 1999 ms, and exactly-created acceptance are present; 45 checks pass. |
   | **F4: realistic duration fixtures** | **PARTIAL:** 1999/2000 acceptance fixtures are now non-overlapping. Some rejection fixtures still overlap, appropriately limiting them to pure-core tests. |
   | **F4: collector deadlines** | **PARTIAL, accurately documented:** 15-second wait and 20-second soft expiry are textual pins, not executable timeout/expiry coverage. |
   | **F6: warm variant** | **COMPLETE:** removed from selectable variants and edit construction. |
   | **F7: result interpretation** | **PARTIAL:** naming/scope now accurately describe mirrored replay checks. Live timing accuracy, stage attribution, and universal conclusions remain unproven. No new matrix was independently reviewed. |

   **Recommended first-session procedure — recommendation, not authorization**

   After addressing cleanup and interruption preservation:

   - Obtain separate measurement-only authorization with the operator present.
   - Park safely; start at stable Honda Home; keep the phone disconnected.
   - Leave Diagnostics through normal UI navigation if necessary; do not change USB settings or automate navigation.
   - Use a verified, absolute adb executable path, serial `00000000`, and a fresh, clearly named latency output directory.
   - Minimum current parameters: `SamplesPerCadence=4`; omit both optional switches.
   - Run once, with no simultaneous diagnostic workload or automatic retry.
   - Abort for UI lag/freeze, unexpected screen/Diagnostics transition, reboot/disconnect, identity/hash refusal, timeout, or query failure; preserve partial evidence and stop.

   The minimum current run still performs **both** serial cadences: eight samples, 72 sampling commands plus six qualification operations. There is no sleep-only parameter. The current script also does not automatically enforce Home/inactive-lock abort criteria, and Ctrl+C cleanup remains defective; these limitations must be resolved before relying on that procedure.

6. **Primary evidence for each finding**

   - **L1/L2:** [measurement allowlist and launch path](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/scripts/Measure-M5ReadinessLatency.ps1:19), lines 19–41 and 68–80; [collector allowlist](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/scripts/Test-M5ArmReadiness.ps1:17), lines 17–35 and 50–68; [identity predicate](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/m5/M5ArmReadiness.ps1:73). Pin counterexample output is in item 4.
   - **L3/L4:** [measurement completion and concurrency](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/scripts/Measure-M5ReadinessLatency.ps1:43), lines 43–66.
   - **L5/L6:** [measurement collection and serialization](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/scripts/Measure-M5ReadinessLatency.ps1:68), lines 68–90; [package detail filtering](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/pm/Settings.java:2940), lines 2940–2958. Installed-output timing/size evidence: capture C `commands.json` and metadata for `13`, `22`, `31`, and `40.stdout.txt`; command output reported `94/78/110/94 ms`, each `1221 bytes`.
   - **L7:** [ActivityManager dumps](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/am/ActivityManagerService.java:9611), lines 9611–9613, 9720–9722, and 14680–14683; [package enumeration](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/pm/PackageManagerService.java:3144), lines 3144–3155 and 10524; [window lock](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/wm/WindowManagerService.java:8282); [display lock](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/display/DisplayManagerService.java:883); [Watchdog](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/Watchdog.java:32), lines 32–35 and 362–377.
   - **Getter semantics:** [transaction 217](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Framework/sources/android/app/ActivityManagerNative.java:1650); [getter implementation](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/am/ActivityStackSupervisor.java:2515).
   - **L8:** [measurement artifacts](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/scripts/Measure-M5ReadinessLatency.ps1:86); [runner’s internal collector invocation](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/m5/Invoke-M5FutureSession.ps1:60); [freshness requirements](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/m5/M5ArmReadiness.ps1:76).
   - **Fix verification:** [harness containment/drift checks](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/m5/Measure-M5ReadinessHostPath.ps1:13), lines 13–43, 66–68, 100–115, and 129–162; [boundary additions](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/m5/Test-M5TimingBoundaries.ps1:39), lines 39–83. Item 4 records independent test/counterexample results.
   - **Operator navigation context:** [existing checklist](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/NEXT-CAR-SESSION-CHECKLIST.md:11). This supplies normal navigation guidance, not authorization for this measurement.

7. **Assumptions**

   Trusted, unchanged executable and source files; ordinary filesystem paths; saved capture records represent their recorded executions. Decompiled source supports mechanisms, not measured behavior or exact scheduling on the live head unit.

8. **Unresolved uncertainties**

   **UNKNOWN:** live tail latency, absent-package timing distortion, seven-way safety/performance, remote cancellation after host termination, Honda-specific indirect responses, and independent 9/9 mutation reproduction.

   The reported fake-adb COMPLETE/wrong-jar/wrong-serial measurement tests were not rerun under this task’s execution prohibition.

9. **Exact diff summary**

   None. No edits.

10. **Preservation checks performed**

   Entry/end hashes matched for the measurement script, harness, boundary suite, collector, core, runner, rules, and `AGENTS.md`. Principal reviewed hashes:

   ```text
   Measurement 23F78E20B9916EDEF5C5A8EAFC72633C9416A726F1D16BCDA546ED6955AE46EF
   Harness     73EF4FDCA12D7AEAC51B87B0ECC3EFDA58657587847F4F2C28F6B6881C44F8FA
   Boundaries  8E977D2413ED09FCA184A2CD6A113A3D50A83E8647DEF47E87E0D57C52CC19DF
   ```

   All four frozen anchors matched `PROJECT-RULES.md`, including both manifest-listed receiver DEX copies. Entry/end Git status was unchanged.

   No key material read, files edited, devices accessed, agents spawned, Git mutations performed, or milestones advanced.