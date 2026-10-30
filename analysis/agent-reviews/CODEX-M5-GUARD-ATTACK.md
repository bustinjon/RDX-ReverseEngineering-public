1. **Files inspected**

   - `PROJECT-RULES.md`, `AGENTS.md`.
   - All five requested PowerShell/schema files, plus `tools/m5/Test-M5FrozenPreflight.ps1`.
   - Both requested plans/reconstructions and the guard session’s `SESSION-RESULTS.md`.
   - `tests-final` and `tests-final-repeat`: summaries, deterministic cases, audits, provenance, compact fixtures, copied dumps, rejection excerpts and early-refusal results.
   - The six original dumps identified in [fixture provenance](/C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/m5-locktask-guard-20261025-195507/tests-final/fixtures/provenance.json:3), plus the original `reconnect-logcat.txt`.
   - Referenced saved framework sources: `ActivityManagerNative`, `ActivityManagerService`, `ActivityStackSupervisor`, `ActiveServices`, `PackageManagerService`, package-manager `Settings`, `UsbSettingsManager`, and Diagnostics `MainActivity`.
   - Preservation metadata and the four frozen artifacts, by hash only.

2. **Files changed**

   None. No report or counterexample fixture was written.

3. **Commands run**

   Read-only `Get-Content`, line-numbered content reads, targeted `rg`/`rg --files`, `Get-FileHash`, `Get-Command`, JSON comparisons, and in-memory probes of copied predicate expressions.

   Two attempts to dot-source the pure core failed with:

   ```text
   Cannot dot-source this command because it was defined in a different language mode.
   ```

   A PowerShell AST parsing attempt was also blocked:

   ```text
   Cannot create type. Only core types are supported in this language mode.
   ```

   No device commands, repository mutations, builds or agent calls were executed.

4. **Tests run and results**

   **New expression-level probes**, using the saved fixture and the source’s expressions:

   ```text
   baseline: fresh=True
   enabled2: fresh=True
   disabledService: fresh=True
   stdout-error-snapshot: missing=False conflict=False
   timing expressions: starts=0,2000,4000,6000; now=6200; accepted=True
   ```

   Eleven getter-regex probes classified ordinary inactive/active replies correctly and returned `UNKNOWN` for empty, denied, busy, transaction-failure, exception, invalid-boolean, trailing, localized and truncated examples.

   These were **expression probes, not executions of the complete core or collector**.

   Saved evidence independently checked:

   - Both summaries report **57 deterministic checks, 1,000 generated cases, 87 accepted, 913 refused**.
   - Summary, deterministic-case, static-audit and compact-fixture hashes match between final and repeat.
   - All **12 copied dumps** match their six original files.
   - Provenance JSON differs in property order; all compared mappings and other fields match.
   - The full saved suites were inspected, **not rerun**.

5. **Findings**

   **The predicate does not establish that the permission dialog can launch. I found one source-established launch-blocker omission and one source-established error-validation defect. Their occurrence on the real target is UNKNOWN.**

   | Angle | Assessment | Finding |
   |---|---|---|
   | **A. Getter parsing** | **No defect found** within the reviewed getter/normal-output trust model | Parsing requires exactly a zero exception word and a Boolean word. Unknown formats refuse. The pinned implementation returns whether a lock-task owner exists; it does not return false as a permission-denied or busy fallback. Runtime rendering remains untested. |
   | **B. Time handling** | **SUPPORTED weakness** | Five seconds means safe discrete observations. State can change between getter calls, between samples, after the final getter, or while the ARM command is being delivered. |
   | **C. Foreground/task/window** | **SUPPORTED weakness; no task-ID defect found** | Home identity and resumed/focused/current-focus agreement are checked. Task 4 is not hardcoded. Other Honda activities refuse. However, `mFocusedApp` and lockscreen/dream flags are not checked, and the separate dumps are not atomic. |
   | **D. Provenance/hash** | **CONFIRMED defect: disabled M5 remains “fresh”** | `enabled=2/3/4` and disabled-component entries are ignored. A fresh, correctly hashed but disabled M5 application/service can satisfy readiness although Android cannot start its permission service. Normal stale/previously executed installation replay is otherwise substantially constrained. |
   | **E. Post-arm gap** | **SUPPORTED weakness** | No observation binds READY to the later phone-triggered permission launch. SystemUI permission-component availability is also unobserved. |
   | **F. Errors/bypasses** | **CONFIRMED output-validation defect; no explicit bypass found** | Valid process/service headers followed by stdout error text are accepted. No `-Force`, `-IgnoreLockTask`, `-SkipReadiness`, equivalent parameter, environment switch or unconditional-success branch was found. |
   | **G. Coverage** | **SUPPORTED weakness** | The generated cases select one of twelve predefined modes against synthetic safe inputs. They do not exercise concurrent target behavior or live getter/collector/ARM integration. |

   **B — timing details.** Host `Environment.TickCount64` governs spacing and freshness; UTC is recorded separately. Head-unit install timestamps are compared for equality, not against the host clock, so ordinary host/head-unit wall-clock drift does not directly defeat freshness. At ARM, the runner checks the **age of existing observations**, including immediately before starting the host process. It does not query lock-task again or bound the time until the target actually handles `startservice`.

   **D — provenance limits.** The checker verifies the installed APK hash, framework hashes, boot ID, proof-file hashes, UID, timestamps and run/serial agreement. The normal runner creates a fresh guard directory and does not accept a supplied READY artifact. A copied, still-never-launched installation from the same boot can remain eligible; there is no proof-expiry limit or signed attestation. Host files and executables are trusted. These limitations alone do not establish an honest-session stale-APK bypass.

   **E — changes possible after READY:**

   | Change before the dialog | Detection or mitigation |
   |---|---|
   | Diagnostics is reopened and starts lock-task | Detectable only if sampled before readiness ends. Later re-entry is unobserved; ordinary RETURN and prompt swapping reduce exposure. |
   | Phone attachment starts Honda projection receivers/activity or changes focus | Unobserved by the readiness guard after disconnect. Saved logs establish attachment-triggered Honda receiver execution; a particular future foreground transition is UNKNOWN. |
   | Laptop disconnect and USB-role/controller changes | Ends host observation. |
   | Phone enumerates, changes VID/PID/device path, detaches or re-enumerates | No readiness prevention. The saved prior run demonstrates enumeration changes and terminal detachment. |
   | Screen sleeps, locks, dreams, changes geometry, or another window obscures UI | No post-READY guard check. Actual future occurrence is UNKNOWN. |
   | M5/SystemUI becomes disabled, crashes, is killed, or otherwise cannot launch | Initial M5 launch confirmation catches some failures; future dialog-component availability is not checked. |
   | Host scheduling, command delivery or physical swap consumes time | Freshness gates host process initiation; preparation reduces delay. It does not guarantee target-side execution time or phone arrival. |
   | Permission request is rejected, or UI appears but is not accepted | Later logs/journal/manual observation determine the outcome; READY cannot establish success. |

   **G — concrete gaps in the 57/1,000 coverage:**

   - No live inactive/active getter reply, shell-access qualification or build-14 hash parity.
   - No successful end-to-end collector-to-ARM execution.
   - No real latency, queued-command, transport interruption or scheduling measurements.
   - No hidden lock-task pulses or relock immediately after the final getter.
   - No phone-attachment/projection/Diagnostics interaction model.
   - No disabled M5 application or disabled `PermissionService` case.
   - No disabled/missing `UsbPermissionActivity` case.
   - No header-preserving stdout error/truncation case.
   - No contradictory `mFocusedApp` or lockscreen-state case.
   - No arbitrary Parcel fuzzing or combinations of independently generated faults. The oracle is `$mode -eq 0`; repeating the seed adds reproducibility, not coverage.

6. **Primary evidence and minimal counterexamples**

   **Defect D1 — disabled M5 launch prerequisite is unchecked.**

   - [Core:19](/C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/m5/M5ArmReadiness.ps1:19) through line 26 checks UID, timestamps, four user flags and version, but never `enabled` or disabled components.
   - [Core:50](/C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/m5/M5ArmReadiness.ps1:50) compares only those returned facts with the installation proof.
   - Saved [package dump:27](/C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/m5-live-retry-20261025-185128/m5-installed-package.txt:27) supplies the original `enabled=0`.
   - Saved Android [Settings:2566](/C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/pm/Settings.java:2566) rejects enabled states 2, 3 and 4; [Settings:2572](/C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/pm/Settings.java:2572) rejects disabled components.
   - [PackageManagerService:1970](/C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/pm/PackageManagerService.java:1970) filters disabled services. [ActiveServices:723](/C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/am/ActiveServices.java:723) resolves the service with flags 1024 and returns “not found” when unavailable.

   **Minimal fixture:** retain the successful synthetic sequence and original valid install proof. In each *current* package dump, change only `enabled=0` to `enabled=2`. Alternatively, retain `enabled=0` and add the fully qualified `PermissionService` under `disabledComponents`.

   **Expected:** `NOT_READY_TO_ARM`, because M5 cannot start its permission service.  
   **Actual source-derived result:** readiness remains eligible for `READY_TO_ARM`; the executed copied expressions returned `fresh=True` for both variants. Full collector execution was blocked by host policy.

   **Defect F1 — stdout errors pass inventory validation.**

   - [Checker:35](/C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/scripts/Test-M5ArmReadiness.ps1:35) examines timeout, exit status and selected **stderr** text.
   - [Core:51](/C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/m5/M5ArmReadiness.ps1:51) requires only recognizable inventory headers; line 52 searches for project names.
   - The positive [compact fixture:10](/C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/m5-locktask-guard-20261025-195507/tests-final/fixtures/synthetic-compact-inputs.json:10) already uses header-only inventories.

   **Minimal fixture:** otherwise safe samples, zero command exit status, empty stderr, with:

   ```text
   processes:
   USER PID NAME
   Permission denied

   services:
   ACTIVITY MANAGER SERVICES
   DUMP TIMEOUT
   ```

   **Expected:** `NOT_READY_TO_ARM`, because the inventories are unknown/error results.  
   **Actual source-derived result:** no inventory refusal; executed expressions returned `missing=False conflict=False`. The rest of the successful sequence is unchanged. Whether a hidden real blocker exists behind such output is **UNKNOWN**.

   **Timing counterexample — acknowledged design limit.**

   Supply safe 100-ms snapshots starting at `0, 2000, 4000, 6000`; evaluate at `6200`. Enter lock-task at `6101`, after the last getter, and retain it through the permission request. Timing expressions accept this sequence, while actual current lock-task can already be active.

   Evidence: [Core:65](/C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/m5/M5ArmReadiness.ps1:65), [Core:69](/C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/m5/M5ArmReadiness.ps1:69), [freshness predicate:77](/C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/m5/M5ArmReadiness.ps1:77), and [runner:19](/C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/m5/Invoke-M5FutureSession.ps1:19). The plan explicitly acknowledges discrete observation limits at [line 19](/C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/M5-RETRY-LOCKTASK-GUARD-PLAN.md:19).

   **Other primary evidence:**

   - **Getter correctness:** [dispatch:1650](/C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Framework/sources/android/app/ActivityManagerNative.java:1650), [synchronized getter:6745](/C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/am/ActivityManagerService.java:6745), [owner predicate:2515](/C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/am/ActivityStackSupervisor.java:2515), [parser:14](/C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/m5/M5ArmReadiness.ps1:14).
   - **Foreground/task checks:** [core:29](/C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/m5/M5ArmReadiness.ps1:29). The real Home dump still contains a background Diagnostics task at [line 48](/C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/live-test-02/after-exit-activities.stdout.txt:48); its presence alone is not proof of active lock-task.
   - **Post-READY observations cease:** [runner:68](/C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/m5/Invoke-M5FutureSession.ps1:68) through line 70.
   - **Diagnostics re-entry mechanism:** [MainActivity:47](/C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/HondaDiagnostics/sources/com/honda/auto/diagnostics/dealer/MainActivity.java:47).
   - **SystemUI prerequisite:** [UsbSettingsManager:874](/C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/usb/UsbSettingsManager.java:874) launches the explicit permission component and catches `ActivityNotFoundException`.
   - **Actual prior rejection:** [raw log:30698](/C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/m5-live-retry-20261025-185128/reconnect-logcat.txt:30698).
   - **Attachment-driven Honda execution:** [raw log:30521](/C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/m5-live-retry-20261025-185128/reconnect-logcat.txt:30521).
   - **No supplied-ready bypass:** [runner:61](/C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/m5/Invoke-M5FutureSession.ps1:61). `Add-Member -Force` updates metadata; it does not bypass readiness.
   - **Generated-case construction:** [offline tests:87](/C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/m5/Test-M5ArmReadinessOffline.ps1:87), especially line 102.
   - **Saved runtime limitation:** [summary:42](/C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/m5-locktask-guard-20261025-195507/tests-final/summary.json:42).

7. **Assumptions**

   - Host scripts, executables and provenance files are trusted unless explicitly discussing their trust boundary.
   - Saved decompiled framework behavior applies only if runtime parity is established.
   - Counterexamples describe inputs/states; they authorize no device changes.
   - “READY” is assessed against the requested dialog-readiness claim, while distinguishing the documented narrower observational contract.

8. **Unresolved uncertainties**

   **UNKNOWN:** actual build-14 binary parity, getter rendering/access/latency, real-world production of header-preserving errors, current component-enabled states, and whether phone attachment would re-enter Diagnostics or lock-task.

   No live false-READY event was observed. The complete guard could not be executed under the host language-mode policy.

9. **Exact diff summary**

   None; no edits or generated files.

10. **Preservation checks performed**

   Fourteen rehashed rule/source/report/artifact files matched the review baseline, with zero discrepancies. Frozen hashes matched all four project anchors:

   ```text
   M5        A22E96490B9557AFF022893A8B8B7A08BB13CEC236E52704CDDAFA90A8EE8F40
   M6        D4DAC2DD8B2AFF1FA7B64BFB32D2A5E889854CCEB4B4A9F7AD5AEF89FB28761F
   Receiver  2FDBC63F2F9D63B764697D311AF89D460AE6B8E14B0FADABA9C9339F7FE7C235
   Qualifier 86350131FFC5CBE5766E523AB03AE07D4C9F5EAD78F0570B68255C9A3999FC1F
   ```

   No key material was opened, no device was contacted, and no milestone was advanced.

**Top five risks to M5 success, ranked**

1. **Lock-task re-entry after the final getter**, including during command delivery or the physical swap.
2. **Phone-triggered projection and USB re-enumeration**, changing the environment before the one permission request completes.
3. **Unqualified live getter/hash/latency path**, potentially refusing every attempt or exceeding timing bounds.
4. **Unchecked launch prerequisites**, particularly disabled M5 service/application or unavailable SystemUI permission component.
5. **Incomplete/error inventories accepted as safe**, weakening the guard’s “unknown means refuse” claim.