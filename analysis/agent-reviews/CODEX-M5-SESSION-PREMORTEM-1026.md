The captured formats pass the current parsers. The concrete problems are **failure recovery and asynchronous capture**, including paths that can leave an installed app with no permitted cleanup stage.

**WILL-BREAK below means the stated trigger deterministically blocks continuation. Whether that trigger occurs tomorrow is UNKNOWN.**

**1. Files inspected**

- `PROJECT-RULES.md`, `AGENTS.md`.
- All six requested scripts, including every runner stage and the readiness core.
- Both requested checklists.
- Frozen-app dependencies: `PermissionService.java`, `PermissionMachine.java`, `PrivateJournal.java`; current independent audit metadata and permission-callsite evidence.
- `m5-retry-live-20261026-174603`: command records, before/after snapshots, install/cleanup outputs, all three readiness sample sets.
- `latency-20261026-204437`: summary, samples, all 222 recorded commands’ stdout/stderr.
- Both historical M5 reports and their referenced successful-ARM evidence, including logcat, SELinux processes, dump records and reconstructed journals.

**2. Files changed**

None.

**3. Commands run**

Read-only commands only:

- `Get-Content`, `Get-ChildItem`, `Test-Path`, `Get-FileHash`, `rg`.
- `git status --short`, `git log -1`, `git show --stat 5356aa1`, scoped `git diff`.
- PowerShell parser expressions evaluated against saved outputs.
- Inline Python, using `C:/Users/REDACTED/AppData/Local/Programs/Python/Python312/python.exe`, to read captures, reproduce parser checks, reconstruct a dump **in memory**, and calculate hashes.

No ADB, device command, runner, collector, harness or latency-tool execution occurred.

**4. Tests run and results**

| Check | Result |
|---|---|
| Current ARMED regex against successful retry | PASS |
| Current `ps -Z` selection/domain regex against both earlier sessions | PASS |
| RETRIEVE terminal regex against actual DETACHED/SERVICE_END | PASS |
| Current-run permission-UI scoping and rejection expressions | PASS |
| Dump reconstruction from real CR-CR-LF logcat | PASS: 3,926 bytes, four chunks, exact saved-journal SHA-256 |
| Verdict expressions against reconstructed live journal | One invocation, one return, zero callbacks → INCONCLUSIVE |
| Twelve saved installed-M5 readiness samples | Individual field/parser checks PASS; saved windows correctly fail polling-gap limit |
| Forty-eight latency Binder replies | All match inactive lock-task reply |
| Latency foreground/window/process/service/package syntax | PASS |
| Today’s before/after geometry, factory APK and signer comparison | PASS |
| Reviewed-file preservation | Eight of eight hashes unchanged during final comparison |
| Frozen artifacts | All four match preservation anchors |

Test limitations: the review shell refused importing the pure parser file because of its language mode. Direct PowerShell expressions and independent Python reproductions were used instead. Initial Python readiness reproduction omitted component-name normalization; that reproduction was corrected and all twelve samples then passed. These were **not end-to-end runner tests**.

**5. Findings**

**F1 — WILL-BREAK / CONFIRMED: pre-process ARM expiry creates an unrecoverable no-journal phase.**

At [runner:66](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/m5/Invoke-M5FutureSession.ps1:66), ARM saves `ARM_ATTEMPTED` **before** its last two freshness checks.

Exact sequence:

`INSTALLED → readiness passes → save ARM_ATTEMPTED → freshness expires at line 67 or 19 → no ARM process starts → RETRIEVE eventually attempts DUMP_RESULTS → no journal exists → conversion throws → UNINSTALL refuses ARM_ATTEMPTED`.

The app creates the journal only inside the ARM handler: [PermissionService.java:117](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/m5-permission/source/com/rdx/fullscreen/m5permission/PermissionService.java:117). Retrieval cannot manufacture missing evidence.

Smallest fix: distinguish **ARM definitely not issued** from **ARM issuance uncertain**. Persist a cleanup-only state for the former; preserve/hash available evidence and permit M5 cleanup without requiring a nonexistent journal. Do not permit another ARM.

**F2 — WILL-BREAK / CONFIRMED: unsuccessful or ambiguous INSTALL has no cleanup transition.**

[Runner:51](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/m5/Invoke-M5FutureSession.ps1:51) invokes installation before saving `INSTALL_REVIEW_REQUIRED`.

- Transport failure/timeout leaves `PREPARED`, although installation may have happened.
- Failure of success parsing or fresh-package verification leaves `INSTALL_REVIEW_REQUIRED`.
- UNINSTALL accepts neither phase.
- RETRIEVE accepts neither phase.

The real successful install was multi-line: `Performing Push Install`, a `pkg:` line, then `Success`. That parser is now fixed; the **failure-state recovery remains missing**.

Smallest fix: record installation intent before invocation, then provide explicit evidence-preserving cleanup for an uncertain installation. Never automatically reinstall.

**F3 — WILL-BREAK / CONFIRMED: Snapshot cannot resume after a partial attempt.**

[Runner:34](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/m5/Invoke-M5FutureSession.ps1:34) unconditionally creates `before` or `after`, with terminating errors enabled.

Exact POSTCHECK sequence:

`UNINSTALLED → create after → any subsequent query/pull/signer/logcat failure → phase stays UNINSTALLED → repeat POSTCHECK → existing after directory stops Snapshot immediately`.

INSTALL has the same problem after a partial `before` snapshot.

Smallest fix: preserve separate snapshot attempts and select a completed attempt, or explicitly resume an existing incomplete snapshot without discarding its evidence.

**F4 — MAY-BREAK / SUPPORTED: ARM and DUMP confirmation race asynchronous service execution.**

[Runner:69](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/m5/Invoke-M5FutureSession.ps1:69) takes one ARMED log snapshot. [Runner:75](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/m5/Invoke-M5FutureSession.ps1:75) likewise takes one snapshot immediately after requesting DUMP_RESULTS.

Real evidence proves service-command completion precedes app work:

- ARM command completed `23:31:13.590Z`.
- App recorded ARMED at `23:31:13.878Z`.
- DUMP command completed `23:37:23.029Z`.
- DUMP_BEGIN appeared at logcat `19:37:23.296`.

Those captures succeeded, but they demonstrate an asynchronous gap. Slower scheduling can produce false “ARM not confirmed” or “No dump”/“Incomplete dump” failures.

Smallest fix: bounded read-only polling for current-run ARMED and a complete dump token/END. Never resend ARM. RETRIEVE failures generally remain retryable; ARM failures retain the F1 distinction.

**F5 — MAY-BREAK / SUPPORTED: host deadline plus three seconds does not establish app termination.**

[Runner:66](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/m5/Invoke-M5FutureSession.ps1:66) starts its 300-second deadline before launching the service. The app starts its own monotonic window later.

The real session’s host deadline began approximately **990 ms before** app ARMED. The three-second allowance covered that session, but there is no bound proving it covers a slow service start or delayed main-thread pump.

After host deadline+3, RETRIEVE permits DUMP without terminal evidence. The app explicitly ignores dumps while active: [PermissionService.java:99](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/m5-permission/source/com/rdx/fullscreen/m5permission/PermissionService.java:99).

Smallest fix: treat the host deadline as an earliest retry time, then confirm terminal state or complete explicit dump output. Keep the frozen app unchanged.

**F6 — MAY-BREAK / CONFIRMED parser behavior: missing ARMED marker makes UI evidence unscoped.**

[Readiness core:81](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/m5/M5ArmReadiness.ps1:81) falls back to the entire log when the requested run’s ARMED marker is absent. VERIFY overrides the verdict whenever `blocked=true`, without requiring `runScoped=true`.

Counterexample using the unchanged real reconnect log and an absent run ID:

[Code block omitted from public report; see authored source where available.]

Thus an older lock-task violation can be attributed to a later run if its ARMED marker has rolled out of logcat.

Smallest fix: require current-run scope before automatic UI-based verdict override; otherwise report UI attribution UNKNOWN.

**F7 — MAY-BREAK / SUPPORTED: sleep removal does not establish final freshness on the installed path.**

Current thresholds still require:

- Each nine-command sample ≤2,000 ms.
- Sample-start gaps ≤2,000 ms.
- Actual ARM process start ≤2,000 ms after the last sample **started**.

The installed captures’ final samples took 1,484–1,516 ms, followed by another 171–172 ms before result creation. Result serialization, runner loading, intent saving and process setup still follow.

The no-sleep latency captures took 1,390–1,485 ms, but explicitly had **M5 absent** and did not traverse the installed ARM handoff.

Smallest fix: reduce avoidable work between the final sample and process start, retaining every safety check and threshold. Current installed-path success after `5356aa1` is **UNKNOWN**.

**F8 — MAY-BREAK / SUPPORTED: interrupted UNINSTALL is not idempotently recoverable.**

[Runner:83](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/m5/Invoke-M5FutureSession.ps1:83) saves `UNINSTALLED` only after uninstall, package listing, process listing and cleanup-file writing.

If uninstall succeeds and a later step fails, the phase remains `INSTALLED`, `RETRIEVED` or `VERIFIED`. POSTCHECK refuses it; another UNINSTALL unconditionally attempts removal again.

The absent-package uninstall response is **UNKNOWN from these captures**, so successful recovery cannot be established.

Smallest fix: persist cleanup intent, then let read-only package/process verification complete an already successful removal without requiring another successful uninstall.

**F9 — COSMETIC / CONFIRMED: checklist runtime-getter statements are stale.**

The in-car checklist says the getter has never been exercised live; the technical checklist calls it still untested. Today’s readiness captures and all 48 latency replies establish actual execution.

Smallest fix: distinguish **getter/parser exercised successfully** from **complete post-fix installed ARM freshness still unverified**.

**6. Primary evidence for each finding**

For compactness, these evidence paths are relative to `analysis/parallel-aa-receiver/`:

- **T** = `m5-retry-live-20261026-174603/`
- **R** = `m5-live-retry-20261025-185128/`
- **L** = `latency-20261026-204437/`

F1–F3 and F8 are source-established conditional defects; no captured occurrence of their complete failure sequence is claimed.

| Finding | Primary evidence |
|---|---|
| F1 | Runner lines 19, 66–78, 83; `PermissionService.java:117`; `PrivateJournal.java:37` opens the requested journal and fails if absent |
| F2 | Runner lines 20–25, 51–57, 71, 83; `T/m5-install-success.txt:1` and `:4` show actual multi-line success |
| F3 | Runner lines 2, 34–40, 49, 84 |
| F4 | `R/commands.jsonl:18`, `:25`; `R/armed-logcat.txt:4`; `R/reconnect-logcat.txt:50737` |
| F5 | `R/session.json:9–10`; `R/armed-logcat.txt:4`; runner lines 66, 74; `PermissionMachine.java:63`, `:73`; `PermissionService.java:99` |
| F6 | Readiness core lines 81–86; runner line 81; real violation at `R/reconnect-logcat.txt:30698`; absent-run expression result above |
| F7 | Three `T/readiness-*/samples.json` and `readiness.json`; `L/latency-summary.json:9`, `:23`; readiness script lines 68–80; runner lines 64–68 |
| F8 | Runner line 83; successful real removal at `T/20261026-175024-269-m5-adb-642258e8.stdout.txt:1` |
| F9 | `INCAR-CHECKLIST-M5-RETRY.md:54`, `:62`; `NEXT-CAR-SESSION-CHECKLIST.md:13`; `L/6.stdout.txt:1` |

Stage-by-stage transition audit:

| Stage | Normal transition | Failure/recovery behavior |
|---|---|---|
| PREPARE | New directory → `PREPARED` | Existing directory refused. No live operation. |
| INSTALL | `PREPARED` → `INSTALL_REVIEW_REQUIRED` → `INSTALLED` | Partial snapshot and ambiguous-install dead ends: F2/F3. |
| ARM | `INSTALLED` → `ARM_ATTEMPTED` → `PHONE_SWAP_WAIT_RECONNECT` | Guard refusal before intent preserves `INSTALLED`, permitting cleanup. Failure after intent needs F1 handling. |
| RETRIEVE | Either arm phase → `RETRIEVED` | Early/failed/incomplete retrieval normally retains arm phase and permits RETRIEVE again. Missing journal prevents progress. |
| VERIFY | `RETRIEVED` → `VERIFIED` | Blocked UI still reaches VERIFIED and allows cleanup. Verdict failure leaves RETRIEVED, also cleanup-eligible. |
| UNINSTALL | Installed/retrieved/verified → `UNINSTALLED` | Rejects installation-review and arm-attempt phases; partial cleanup has F8. |
| POSTCHECK | `UNINSTALLED` → `FINISHED` | Partial snapshot has F3. Preservation mismatch is checked **after saving FINISHED** at line 85; phase alone therefore does not prove successful preservation. |

Real-output parser audit:

| Parser | Actual captured evidence | Result |
|---|---|---|
| Install success | `T/m5-install-success.txt:4`: `Success` after other output | Matches current split/trim check. |
| Fresh package | `userId=10049`; equal install/update times; `installed=true hidden=false stopped=true notLaunched=true enabled=0` | Matches current facts/provenance checks. |
| ARMED | `R/armed-logcat.txt:4`: `run=m5_270c93bb178648759beda65ed9593e72 … state=ARMED event=ARMED …` | Matches `run=<id>.*event=ARMED`. |
| SELinux process | `R/armed-selinux-processes.txt:197`: `u:r:untrusted_app:s0 … com.rdx.fullscreen.m5permission` | One selected row; domain matches despite CR-CR-LF. Original session row also matches. |
| RETRIEVE terminal | `R/m5-before-dump.txt:21`: `run=… state=DETACHED event=DETACHED_AFTER_REQUEST …`; line 22 includes `event=SERVICE_END` | Both accepted. `STOPPED`/`ALREADY_AUTHORIZED` are omitted as states, but their SERVICE_END can satisfy the alternative. |
| Binder getter | `L/6.stdout.txt:1`: `Result: Parcel(00000000 00000000   '........')` | Matches INACTIVE; 48/48 latency replies matched. |
| Foreground | Saved resumed/focused activity uses `com.honda.tjba.launcher/.ui.HomeActivity`; window uses full class | Normalization makes them equal. |
| Permission UI | `R/reconnect-logcat.txt:30695`: `START … UsbPermissionActivity`; `:30698`: `Attempted Lock Task Mode violation … UsbPermissionActivity` | Attempted=true, blocked=true, correctly scoped for this run. |
| Dump BEGIN | `R/reconnect-logcat.txt:50737`: `DUMP_BEGIN token=45b32906-b1b2-494f-abdd-02148f6769a2 run=… bytes=3926 sha256=138f…67af` | Matches. |
| Dump CHUNK/END | Four real chunks; `:50743`: `DUMP_END token=45b32906-b1b2-494f-abdd-02148f6769a2 chunks=4` | Bounds, indices, decoded lengths and SHA all pass. CR-CR-LF is harmless. |
| Journal verdict | Reconstructed journal lines 15–16 contain `REQUEST_API_INVOKING` and `REQUEST_API_RETURNED`; no RESULT_RECEIVED | Correct INCONCLUSIVE. Real granted-callback branch remains UNKNOWN. |
| UNINSTALL package absence | `T/20261026-175025-399-m5-adb-96d9cf05.stdout.txt` is empty | Package regex returns false, as intended. |
| UNINSTALL process absence | Following real `ps` output contains no M5 process | Process regex returns false. It does not validate the listing header/error format or check code/data directories. |
| Factory path | `T/before/honda-path.txt:1`: `package:/system/app/AndroidAuto/AndroidAuto.apk` | Matches anchored factory-path regex. |
| Geometry | `T/before/window.txt:43,49,53,55`: `1339x720`, `1920x720`, corresponding stable/system rectangles | All exact geometry checks pass before and after. |
| Display | `T/before/display.txt:155`: `real 1920 x 720 … rotation 0, density 160 … state ON` | Matches before and after. |
| Signer | Before/after signer line 2: `2156c50e3c08347f28adccb49ae839394053a45767f153bd8f036ae33d5f8568` | Entire captured signer outputs equal. |

The original 180-second journal ends with `TIMEOUT; no retry` and `END; permission-only…`, rather than the current event format. It is historical-version evidence, not a valid current dump-conversion input.

Timing and phone-reconnect audit:

| Boundary | Implemented behavior and captured measurement |
|---|---|
| Runner ADB timeout | Every call has 30 seconds, including install, uninstall, factory pull and full logcat. |
| Factory pull | Today: approximately 396 ms before and 448 ms after. No observed timeout. |
| Full logcat | Today: 4,501,467 bytes in 5.489 s; 5,395,106 bytes in 4.742 s. No observed timeout; slower transfers still hit the same 30-second limit. |
| Readiness command timeout | 15 seconds per query/pull; separate 2-second sample/freshness limits remain stricter. |
| Observation bound | 20-second check occurs after a sample, not around the entire sampling operation. |
| App bound | 300,000 monotonic milliseconds, checked by app callbacks/pump; not an independent hard process-kill timer. |
| Reconnect | No `wait-for-device`, enumeration loop, server-restart recovery or offline/unauthorized retry. |

**The first RETRIEVE command is actually the common fingerprint query at runner line 29.** If the device is offline, unauthorized or missing, that query can fail before retrieval begins. An earlier real reconnect/startup failure says:

[Code block omitted from public report; see authored source where available.]

Source: `R/20261025-185211-343-identity-fingerprint-retry.stderr.txt:2–3`.

That failure leaves the arm phase intact, so RETRIEVE can be repeated once connectivity returns. It does not itself strand the state. Recovery of the physical connection is UNKNOWN; the runner does not implement it.

Hard-coded host prerequisites, all confirmed present:

| Prerequisite | Location |
|---|---|
| ADB | `C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/adb/adb.exe` |
| AAPT | `C:/Program Files (x86)/Android/android-sdk/build-tools/32.0.0/aapt.exe` |
| Java | `C:/Program Files/Eclipse Adoptium/jdk-17.0.20.101-hotspot/bin/java.exe` |
| APK signer | `C:/Program Files (x86)/Android/android-sdk/build-tools/32.0.0/lib/apksigner.jar` |
| Frozen M5 | `analysis/parallel-aa-receiver/m5-permission/build/20261023-180320-335/rdx-m5-permission-0.2.0-m5-single-port-300s-development.apk` |
| Audit pointer | `analysis/parallel-aa-receiver/m5-permission/latest-audit.txt` |
| Referenced audit | `…/build/20261023-180320-335/independent-audit-20261023-180346-106/{audit.json,dexdump.txt}` |
| PowerShell/.NET | Modern APIs are required: `ArgumentList`, `TickCount64`, `SHA256.HashData`, `Convert.ToHexString`. Review host is PowerShell 7.6.8. |

Preflight reports `adbPathExists`; it does not reject false. Java/apksigner availability is first exercised inside Snapshot.

Additional checklist disagreements:

- In-car step 8 omits an explicit **VERIFY invocation**. RETRIEVE does not create `m5-verdict.json`; NEXT checklist step 9 correctly names VERIFY.
- NEXT checklist requires code absence; runner cleanup checks package/process only. The in-car checklist correctly acknowledges that additional checks are needed.
- In-car timing says approximately 20 seconds after Allow; runner/NEXT say 60–90 seconds. No captured evidence proves the shorter instruction fails, but the instructions differ.
- The existing half-finished-ARM warning acknowledges a gap; it does not supply a runnable recovery procedure.

**7. Assumptions**

- Tomorrow uses the reviewed files at commit `5356aa1`, the frozen APK, and the recorded head unit/build.
- Conditional failure findings describe source-established paths, not claims that tomorrow’s hardware will trigger them.
- Python checks reproduce parser logic; they do not substitute for executing the prohibited entrypoints.

**8. Unresolved uncertainties**

- Complete installed-path ARM freshness after removing the sleep.
- Actual granted-callback parser behavior against live evidence.
- Tomorrow’s reconnect state and service scheduling delays.
- Response to uninstalling an already absent package.
- Whether current-run ARMED remains in the log buffer until retrieval.
- End-to-end success of the proposed recovery fixes: no fixes were made or executed.

**9. Exact diff summary**

No task edits.

The working tree already contained unrelated changes. A new untracked `tools/m5/Get-M5ArmTimingReport.ps1` appeared during review; I did not create, inspect or execute it. All eight reviewed scripts/checklists retained their recorded hashes.

**10. Preservation checks performed**

Frozen artifact SHA-256 values matched exactly:

| Artifact | SHA-256 |
|---|---|
| M5 APK | `A22E96490B9557AFF022893A8B8B7A08BB13CEC236E52704CDDAFA90A8EE8F40` |
| Disabled M6 APK | `D4DAC2DD8B2AFF1FA7B64BFB32D2A5E889854CCEB4B4A9F7AD5AEF89FB28761F` |
| Receiver DEX | `2FDBC63F2F9D63B764697D311AF89D460AE6B8E14B0FADABA9C9339F7FE7C235` |
| API22 TLS qualifier APK | `86350131FFC5CBE5766E523AB03AE07D4C9F5EAD78F0570B68255C9A3999FC1F` |

No rebuilds, key-material access, device operations or milestone changes occurred.