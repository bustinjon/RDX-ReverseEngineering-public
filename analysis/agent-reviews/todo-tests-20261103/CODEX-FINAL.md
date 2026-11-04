**F1–F6 are FIXED in the scoped source review. One new SHOULD-FIX remains in Build-Test’s lock cleanup.**

Paths below use `R = analysis/test-prep/todo-tests-20261103`; `H = source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper`; `P = source/analysis/parallel-aa-receiver/src/com/google/android/projection/protocol`.

**1. Files inspected**

- `PROJECT-RULES.md`, `AGENTS.md`, and the previous `CODEX-RECHECK.md`.
- `R/tools/{Build-Test,Switch-Source,Check-Signals,Run-Test}.ps1`.
- T11 `P/AudioSource.java`, `H/AaSessionService.java`.
- T12 `H/{ReconnectPolicy,AaSessionService,UsbHelperService}.java`, `ReconnectPolicyTest.java`, saved host-test output.
- T13 `H/NightModeWatcher.java`.
- T11–T13 source manifests; T11 build-result metadata.
- Decompiled `BroadcastRecord.java` and relevant `BroadcastFilter.java` excerpts.

**2. Files changed**

None. No report file written.

**3. Commands run**

Local inspection only: `Get-Content`, `rg`, `Get-Item`, `Select-Object`, and `node -e` for scoped SHA-256 comparisons and in-memory regex fixtures. Attempted PowerShell `Parser.ParseFile` checks.

No device, ADB, build, Git, network, or agent actions.

**4. Tests run and results**

| Check | Result |
|---|---|
| Five changed Java files against source-manifest hashes | **PASS 5/5** |
| Extracted permission regexes against three in-memory fixtures | **PASS 3/3**: excludes nested sender permission, preserves record permission, stops at direct filter |
| PowerShell syntax parsing | **UNKNOWN**: constrained language mode blocked parser invocation; printed error counts are not valid syntax results |
| Saved T12 host-test output | Reports `PASS 24 reconnect-policy checks`; inspected, not rerun |
| Active-source state | `active-source.json` absent |

**5. Findings**

| Finding | Status | Primary source evidence |
|---|---|---|
| F1 | **FIXED** | T11 `P/AudioSource.java:57` returns false for surviving capture; `H/AaSessionService.java:613` marks teardown unclean, preventing receiver and remaining native destruction at `:617`. |
| F2 | **FIXED** | T12 `H/ReconnectPolicy.java:18` declares the static counter; `:33` allocates generations. `H/AaSessionService.java:115` clears matching `lastEnd`. |
| F3 | **FIXED** | `R/tools/Build-Test.ps1:13` acquires the lock; `:14` refuses active source before manifest writing at `:23`. |
| F4 | **FIXED** | `R/tools/Switch-Source.ps1:73` catches copy/verification failures, restores at `:75`, verifies baseline at `:80`, removes state at `:81`, then throws at `:82`. |
| F5 | **FIXED** | `R/tools/Check-Signals.ps1:41` stops before nested receiver/filter permissions; `:46` states the receiver permission requirement without concluding exclusion. |
| F6 | **FIXED** | T11 `P/AudioSource.java:194` counts opens; `:140` pauses only without a newer open. `:164` acquires before sending; `:166` drops on timeout. |

Minor: **FIXED** — T13 `H/NightModeWatcher.java:53` now logs `NIGHT_MODE_THREAD_STILL_RUNNING`.

**New BLOCKER:** none identified within scope.

**New SHOULD-FIX:** Build-Test can retain the launcher lock after a preflight exception. Moving acquisition ahead of manifest validation introduced additional throwing operations outside its cleanup scope.

**6. Primary evidence for the new finding**

In [Build-Test.ps1](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/test-prep/todo-tests-20261103/tools/Build-Test.ps1:13):

- Lock acquisition: line 13.
- Explicit validation exception: line 20.
- Manifest write, another possible exception: line 23.
- Cleanup-protected `try` begins only at line 28.
- Lock disposal occurs at line 58.

A failure at line 20 or 23 cannot reach that `finally`. In a surviving PowerShell host, deterministic release is therefore missing; release depends on later collection or process exit. Runtime reproduction was not performed.

Operational package verdicts, including shared tooling:

| Candidate/tooling | Verdict | Basis |
|---|---|---|
| T09 | **NOT READY** | Shared tooling finding remains; prior candidate-code disposition carried forward. |
| T10 | **NOT READY** | Shared tooling finding remains; prior candidate-code disposition carried forward. |
| T11 | **NOT READY** | Requested source fixes pass; shared tooling finding remains. |
| T12 | **NOT READY** | Requested identity fixes pass; shared tooling finding remains. |
| T13 | **NOT READY** | Requested log correction passes; shared tooling finding remains. |
| Tooling | **NOT READY** | Launcher-lock cleanup SHOULD-FIX above. |

**7. Assumptions**

Existing FIXED and ACCEPTED-RISK dispositions remain accepted and were not reopened. F4 recovery assumes rollback I/O succeeds.

**8. Unresolved uncertainties**

Live behavior and native-call termination remain **UNKNOWN**. T13’s potentially unbounded destruction when a native report never returns remains the accepted **UNKNOWN**. Existing accepted ACK-session behavior was not reassessed.

**9. Exact diff summary**

None; no files changed.

**10. Preservation checks performed**

Five scoped Java source hashes matched their manifests. No key, credential, or private-test material was opened. Frozen artifacts were neither modified nor rehashed in this narrowly scoped check. Whole-workspace before/after equality is **UNKNOWN**.