# Car-test runner corrections — 2026-10-29

The runner corrections are implemented and **34 offline simulation tests pass**. No connected test was performed. The available APK remains an explicitly identified **historical baseline**, with two recorded Java inputs different from current source; it is rejected when selected as `CurrentSource`.

This completes the user's request to fix the preparation problems identified in the [test-preparation review](../test-prep/20261029-helper-startup/README.md). It changes the helper runner and its local tests, not the app, v6h proposal, frozen artifacts, M5 readiness guard, or milestone status. Claude remains the lead. [AGENTS.md](../../AGENTS.md) and [PROJECT-RULES.md](../../PROJECT-RULES.md) still govern connected work.

## 1. Files inspected

- Project instructions, prior test packet, saved build report, and the preceding 263-file preservation inventory.
- `scripts/Run-CarTest.ps1`, `scripts/device-kill-honda.sh`, and relevant builder source-list logic (read only; builder not run).
- Helper manifest/accessibility configuration, `PermissionClickService`, and `UsbHelperService` startup/destruction behavior.
- Saved firmware `AccessibilityManagerService`, `ActivityManagerService`, `ActiveServices`, and `ServiceRecord` source to establish actual dump formats.
- New runner core/tests, shell scripts, simulation outputs, and the actual local APK/build-source hashes.

## 2. Files changed

Existing files modified:

- [scripts/Run-CarTest.ps1](../../scripts/Run-CarTest.ps1)
- [scripts/device-kill-honda.sh](../../scripts/device-kill-honda.sh)

New implementation/test files:

- [tools/car-test/CarTest.Core.ps1](../../tools/car-test/CarTest.Core.ps1)
- [tools/car-test/Test-CarTestOffline.ps1](../../tools/car-test/Test-CarTestOffline.ps1)
- [scripts/device-car-test-watchdog.sh](../../scripts/device-car-test-watchdog.sh)

New evidence: this report; [validation.json](../test-prep/runner-fix-20261029/validation.json); simulation directories under `analysis/test-prep/runner-fix-20261029/`; and one [actual offline artifact plan](../test-prep/runs/helper_20261029T193015_ac165e5ae6044e94acfb8c0ba9d0cd89/artifact-plan.json). Every device response in `tests-*` is **simulated**, including any `READY` session result and any file named `installed.apk`. The fixture APK is deliberately non-installable text. The actual preparation directory contains only a local artifact plan.

## 3. Commands run

- Local inspection with `Get-Content`, `rg`, `Get-FileHash`, `git status --short`, and `git diff --numstat`; PowerShell parser and JSON checks.
- `tools/car-test/Test-CarTestOffline.ps1 -OutputDirectory <fresh local directory>` ran in-process fake transports. Shell strings were treated as data, never evaluated.
- Git Bash `-n` parsed each shell script separately, including generated cleanup text. It did not execute their bodies.
- The actual runner was executed with `-Mode Prepare`, the pinned APK/hash, `-CandidateRole HistoricalBaseline`, and an intentionally nonexistent `-AdbPath`. It returned before the live adapter.
- A separate local artifact check selected that same APK as `CurrentSource` and confirmed rejection.
- `apply_patch` edited source/report files; the local tests/checks wrote their evidence. No ADB, fastboot, signing, APK build, device-facing shell body, Git staging, commit, or push occurred.

## 4. Tests run and results

| Check | Result |
|---|---|
| Final offline suite | **34 PASS, 0 FAIL**; [results](../test-prep/runner-fix-20261029/tests-final/results.json) |
| Actual APK, explicit historical-baseline preparation | PASS; two source differences disclosed, audit remains PENDING |
| Actual APK selected as CurrentSource | Rejected before any device operation |
| PowerShell syntax | Runner, core, and tests parse successfully |
| Shell syntax and encoding | Each source script and generated cleanup parse; LF line endings, no UTF-8 BOM |
| Preservation | Only the two authorized existing scripts differ from the 263-file baseline; all four frozen anchors match |

The first simulation run exposed a closure bug in the **test transport**: the fixture APK path was not captured. That was corrected. Subsequent runs passed 29 tests, then 34 after additional cases and parser/timing corrections. The final run covers the final implementation; earlier outputs are retained rather than substituted for the final result.

The tests check the expected reason for each rejection, not just that something threw. Covered cases include failed install exit/text, wrong installed bytes, wrong device/user, missing remote exit status, transport timeout, failed capture, a stale helper instance, absent process, unbind failure, stale/wrong-PID accessibility callbacks, historical service records, failed Honda stop, failed upload/watchdog/loop, unexpected early phone activity, wrong helper phase, short/malformed timing, cleanup disconnect, and concurrent accessibility-setting changes.

## 5. Findings and implemented behavior

**F1 — Artifact identity is explicit.** `ApkPath`, `ApkSha256`, and `CandidateRole` are mandatory. There is no moving `latest-build.txt` fallback and no `SkipInstall` path. The runner matches the local APK against the supplied SHA and build metadata. `CurrentSource` rejects recorded Java-input differences; `HistoricalBaseline` records them. During a future live invocation, installation must succeed and the installed package APK is pulled and hashed before readiness can continue. Source coverage is explicitly limited to recorded Java inputs; this is not a complete reproducible-build audit. [E1]

**F2 — Preparation defaults to offline.** `Mode=Prepare` validates local inputs and saves an artifact plan, then returns. The existing pinned APK can therefore be reviewed without any device executable. Live use remains a separate operator action subject to project instructions. The actual native transport branch was not executed in this work. [E2]

**F3 — Failures cannot fall through to READY.** Every connected command is bound to the known head-unit serial. Native commands have a 30-second host timeout. Remote shell commands additionally return a unique exit marker, because host success alone is insufficient. Exceptions and output are journaled; a failed preparation records `FAILED`, and READY is printed only after successful return. [E3]

**F4 — Accessibility and helper readiness require fresh evidence.** The runner stops and verifies removal of individual helper/session/overlay services instead of force-stopping the whole package before accessibility setup. It removes/re-adds only its own accessibility entry, preserves other entries, and requires the original instance to unbind. Readiness pairs the exact active user-0 service/process with the firmware's bound-services dump and a fresh `onServiceConnected` log after a unique boundary marker. It then requires a fresh helper creation/WAITING record and refuses phone activity before readiness. This proves more than a `ServiceRecord` substring; it still does not prove a future dialog will be clicked successfully. [E4]

**F5 — Capture and timing are checked.** The runner starts a unique capture without clearing global logs or killing unrelated logcat processes. Slow installation/binding preparation occurs before the watchdog starts. The watchdog starts before the helper and is independent of the laptop and Honda loop. Immediately before READY, the runner checks capture/watchdog evidence and remaining monotonic device deadlines, deducts the timing command's host round trip plus a two-second reserve, and refuses less than 30 seconds of cleanup window or 15 seconds of Honda-loop window. Displayed remaining times are estimates at that sample, not guarantees after a delayed cable swap. [E5]

**F6 — Cleanup and preservation are recorded.** Failures after accessibility mutation attempt cleanup and retain any cleanup error. The device cleanup script stops the helper and restores original accessibility settings only if the current service list still equals the runner's write; subsequent changes are preserved. Successful setup retains an independent watchdog for disconnect. Each session records original settings, candidate/installed hashes, and hashes of all four runner components. The Honda loop uses uptime and cancellation instead of treating 300 iterations as a measured 30 seconds. An individual in-flight `am` call can still exceed its loop deadline; shell runtime behavior remains untested. [E6]

Safe local preparation, from the project root:

[Code block omitted from public report; see authored source where available.]

The former invocation interface changes deliberately: omission of the artifact/hash/role no longer selects an APK implicitly, `SkipInstall` is removed, and running the script defaults to local preparation. For any later authorized helper test, the phone must be unplugged during preparation and the operator must already be ready for the swap. Existing M5-only authorization/guard rules are not replaced by this helper runner. This work does not establish safe UI/lock-task state or permission to execute the live branch.

## 6. Primary evidence for each finding

| Finding | Source and result |
|---|---|
| E1 | `CarTest.Core.ps1:6` artifact-plan validation and `:157,163–164` install/installed-hash checks; `Run-CarTest.ps1:5` mandatory inputs. Actual local artifact plan linked above; final wrong-hash/source/installed-bytes cases. |
| E2 | `Run-CarTest.ps1:9,23` default mode and early return. Actual preparation passed with nonexistent `C:/DO-NOT-EXECUTE/no-such-device-tool.exe`. |
| E3 | `CarTest.Core.ps1:43,53` explicit target and native/remote result handling; `Run-CarTest.ps1:46,54` timeout and READY placement. Final timeout, remote-status, install, and target cases. |
| E4 | `CarTest.Core.ps1:65,78,86` service/accessibility/log-boundary parsers and `Invoke-CarTestPreparation` lifecycle checks. Firmware `AccessibilityManagerService.java:1304–1327,2046–2054` lists bound services by label; `ActiveServices.java:1776–1807` defines active-service sections; `ActivityManagerService.java:9720–9723` requests their detailed dump. Helper `PermissionClickService.java:203–211` emits the callback. |
| E5 | Core capture/watchdog/timing sequence and final timing cases; `device-car-test-watchdog.sh:8–13` writes the uptime deadline and invokes cleanup. |
| E6 | `CarTest.Core.ps1:103` generates cleanup, and its catch/finally saves failure/cleanup state. `device-kill-honda.sh:7–19` bounds iterations by uptime/cancellation. Final cleanup-disconnect/concurrent-change cases and success session's `ToolHashes`. |
| Preservation | `validation.json` contains expected/current hashes, the exact permitted baseline differences, parser/encoding results, and final test-summary hash. |

## 7. Assumptions

- “Fix it” authorizes the runner corrections previously recommended, plus local tests and a handoff; it does not authorize app implementation, device work, or milestone advancement.
- The known head-unit target remains serial `00000000`; the runner deliberately accepts only that target.
- The pinned APK may be selected as an explicitly labeled historical experiment. It is not a newly repaired app build.

## 8. Unresolved uncertainties

**UNKNOWN:** actual installed APK/state, device command availability and output parity, real accessibility rebinding/click behavior, safe UI/lock-task state, persistence of the watchdog across disconnect, real cleanup completion, and the underlying permission/USB/TLS/video failure causes. Shell bodies and the native process adapter were not runtime-tested. Existing legacy timers/loggers are not globally killed by the new runner; the operator must establish a clean test context.

The build's two source differences and `staticAudit: PENDING` remain. Recorded-source matching does not cover unrecorded build inputs. No APK was rebuilt because that was outside this runner fix and the supplied rules prohibit reading key material. v6h and the protocol/decoder recommendations remain separate unimplemented work.

## 9. Exact diff summary

- Replaced `Run-CarTest.ps1` with explicit artifact selection, an offline default, and a serial-bound/timeout-limited live adapter calling tested preparation logic.
- Changed `device-kill-honda.sh` to accept a session directory and fixed 30-second window, use uptime/cancellation, and pause between iterations; the prior argument-free invocation is no longer supported.
- Added the core, 34-case simulation suite, and independent watchdog script.
- Added this report, machine-readable validation, simulation evidence, and one local artifact plan. `validation.json:changed_existing_files` supplies before/after hashes for the exact two modified pre-existing files; `implementation_files` supplies final hashes/line counts.
- App/source/build/signing files, previous reports/logs, instructions, M5 guard, and milestone files: **no edits**. No files deleted, staged, or committed.

## 10. Preservation checks performed

Compared every file in the preceding 263-file baseline: the two authorized scripts changed; the other **261 files are unchanged**. All four frozen artifact hashes match their anchors. The existing APK hash remains `C7943B4FD9194E6AAD3E2C28AE68F880519D8EC624148AA794FBE9CA97F80757`. Earlier source/log modifications were preserved, not reset. No credential contents were read, no device tool was executed, and no milestone status changed.
