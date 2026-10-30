1. **Files inspected**

   `PROJECT-RULES.md`, `AGENTS.md`; all four requested plan/scripts; both real display/window fixtures; the four named framework sources; grid/decoder sources and audits; requested history; `PROJECT-INTEGRITY.json`; saved rehearsal `results.json` and every scenario’s `console.txt`/`invocations.log`.

2. **Files changed**

   None.

3. **Commands run**

   Read-only `Get-Content`, `rg`, `Get-ChildItem`, `Get-FileHash`; isolated PowerShell probes reproducing package parsing, PID filtering, and path allowlisting. Consulted official Android lifecycle documentation and AOSP API22 `getevent.c`. No repo script, adb, fastboot, or device operation executed.

4. **Tests run and results**

   - Independently recounted saved rehearsal: **343 calls, zero outside its allowlist**; saved results report **13/13 PASS**. Rehearsal not rerun.
   - Mocked failed/timed-out `pm path`, empty stdout: **interpreted as `ABSENT`**.
   - Historical log lines with current PID: **both accepted**.
   - Install/pull paths containing spaces: **both rejected**.
   - Both test APK hashes match the runner; four frozen preservation anchors match.

5. **Findings**

   **Verdict: NOT READY.** Fix the blocking recovery/reporting defects before the session.

   | ID | Rank | Concrete failure scenario and required correction |
   |---|---|---|
   | F1 | **BLOCKING** | Install succeeds, then `pm path` fails with empty stdout. State becomes `ABSENT`; UNINSTALL refuses despite the installed package. Later failed package queries can also let POSTCHECK report FINISHED. Treat transport failures/timeouts as UNKNOWN; permit cleanup after reconciling actual package state. |
   | F2 | **BLOCKING** | Grid EXIT finishes the Activity while Android retains its process. The wide-screen LAUNCH then refuses indefinitely with “press EXIT.” The rehearsal manually removes that process, masking this case. Check Activity/window state instead of requiring process death. |
   | F3 | **BLOCKING** | Reset clears RAM overscan, but writing XML fails; the framework catches the exception and retains the previous persistent file. Runtime checks pass, while the next boot can restore negative overscan. Also, absent-before → empty XML-after disproves “exact saved-file restore.” Separate runtime restoration from durable restoration and prepare an explicit recovery procedure. |
   | F4 | **BLOCKING** | Interruption during non-atomic `session.json` overwrite leaves invalid JSON while overscan/apps remain changed. Every recovery stage parses that file first; a new BASELINE refuses the changed target. Add atomic journal replacement and recovery independent of a readable session journal. |
   | F5 | **SHOULD-FIX** | CAPTURE for a new decoder clip can repeat the preceding clip’s END/result because only PID is checked. LAUNCH reports OK even when its snapshot says `running=false`; screenshot/log failures are ignored. Require fresh, clip-specific BEGIN→END evidence, current Surface evidence, and successful capture operations. |
   | F6 | **SHOULD-FIX** | Negative-right overscan produces **2501-pixel unrestricted/system bounds**, although app policy width becomes 1920. SystemUI/navigation can therefore lay out beyond the panel. Reset checks only two policy rectangles and cannot establish UI/service recovery. Add broader geometry/UI checks and a prepared failure decision tree. |
   | F7 | **SHOULD-FIX** | Stage 5b cannot establish the promised full **1920×720 video Surface**: decoder controls/status consume height, then video aspect-fits the remaining area. Grid’s `physical=` label also uses the vendor-broken `getRealMetrics`. Correct the promised measurement and metric labels. |
   | F8 | **SHOULD-FIX** | UNINSTALL performs a state change without checking authorization. INSTALL/LAUNCH also remain available after overscan becomes UNKNOWN, despite the plan’s stop rule. Enforce the spoken-authorization and recovery-only boundaries. |
   | F9 | **SHOULD-FIX** | A session directory containing spaces fails the Honda APK pull allowlist. The exact in-car checklist remains unfinished, including recovery commands. Validate the actual shell/output path and rehearse its complete checklist before departure. |

6. **Primary evidence for each finding**

   - **F1:** [runner:55](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/evening/Invoke-RdxEveningStage.ps1:55) ignores exit status, timeout and stderr; lines 90, 115 and 119–124 consume that result. Isolated probe output: `failed pm path interpreted as: ABSENT`.
   - **F2:** [GridActivity.java:20](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/grid-test/source/com/rdx/fullscreen/gridtest/GridActivity.java:20) calls only `finish()`; [runner:95](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/evening/Invoke-RdxEveningStage.ps1:95) rejects any surviving process. [rehearsal:49](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/evening/Test-RdxEveningRehearsal.ps1:49) explicitly deletes fake running state before the wide launch. Android documents that [process lifetime is system-controlled](https://developer.android.com/guide/components/activities/process-lifecycle).
   - **F3:** [WindowManagerService.java:6077](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/wm/WindowManagerService.java:6077) changes RAM before persistence. [DisplaySettings.java:245](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/wm/DisplaySettings.java:245) always serializes a file; lines 273–278 catch write failures. [runner:112](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/evening/Invoke-RdxEveningStage.ps1:112) checks runtime dumps only. This contradicts [plan:25](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/agent-reviews/EVENING-EXPLORATION-PLAN-20261027.md:25).
   - **F4:** [runner:26](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/evening/Invoke-RdxEveningStage.ps1:26) loads JSON before recovery; line 28 directly overwrites it. Lines 79–80 refuse changed baselines. **With an intact journal**, RESTORE is reachable from APPLY_PENDING/UNKNOWN, and UNINSTALL accepts REVIEW_REQUIRED.
   - **F5:** [runner:63](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/evening/Invoke-RdxEveningStage.ps1:63), lines 65–68 and 96–103: no freshness/clip boundary, no enforced Surface result, unconditional success reporting. [DecodeWorker.java:35](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/decoder-test/source/com/rdx/fullscreen/decodertest/DecodeWorker.java:35) emits `END ... EOS/...`, whereas [rehearsal:29](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/evening/Test-RdxEveningRehearsal.ps1:29) fabricates `RESULT PASS frames=300`.
   - **F6:** [PhoneWindowManager.java:3101](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Policy/sources/com/android/internal/policy/impl/PhoneWindowManager.java:3101): app width is `1920 - (-581) - 581 = 1920`; lines 3114/3118 make system/unrestricted width **2501**. Navigation uses those expanded bounds at lines 3212/3231; status bar at 3280. The resource B-zone width is independently loaded at line 1252; overscan compensates for it rather than changing it.
   - **F7:** [DecoderTestActivity.java:15](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/decoder-test/source/com/rdx/fullscreen/decodertest/DecoderTestActivity.java:15), lines 17–19 and 25–28; [GridActivity.java:29](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/grid-test/source/com/rdx/fullscreen/gridtest/GridActivity.java:29); [LIVE-TEST-02-RESULTS.md:47](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/LIVE-TEST-02-RESULTS.md:47).
   - **F8:** [runner:114](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/evening/Invoke-RdxEveningStage.ps1:114) lacks `Need`; INSTALL/LAUNCH at lines 83–99 lack an UNKNOWN-overscan stop guard.
   - **F9:** [runner:36](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/evening/Invoke-RdxEveningStage.ps1:36) requires `\S+` host paths; probe returned `False` for both spaced paths. [plan:79](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/agent-reviews/EVENING-EXPLORATION-PLAN-20261027.md:79) still lists the checklist as unfinished.

   Additional **NOTE** findings:

   - **Zero-overscan evidence is conditional.** [DisplayInfo.java:266](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Framework/sources/android/view/DisplayInfo.java:266) supports absence-of-clause for each complete object. The fixture’s base **and** override objects, `before/display.txt:78–79`, both contain zero overscan. That proves the captured snapshot, not tonight’s state or XML contents. [runner:58](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/evening/Invoke-RdxEveningStage.ps1:58) does not require both complete objects or bind them to `local:0`.
   - **POSTCHECK’s claim is broader than its checks.** [LIVE-TEST-02-RESULTS.md:67](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/LIVE-TEST-02-RESULTS.md:67) records Honda’s auto-start preference commit on ordinary app resume. Runner lines 119–124 do not verify that state or shared-media recovery. FINISHED must describe only the measured checks.
   - **Input capture is not a device-side timed operation.** [survey:97](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/scripts/Capture-RdxEveningSurvey.ps1:97) kills only the host client; lines 111–115 can report zero leftovers after a failed `ps`. API22 supports `-lt -c`, but its [AOSP getevent implementation](https://raw.githubusercontent.com/aosp-mirror/platform_system_core/android-5.1.1_r38/toolbox/getevent.c) waits for events without a wall-clock deadline. It opens input nodes read/write and sets its client clock; no event grab/injection is present. Exact OEM orphan behavior/harm is **UNKNOWN**. Real knob/buttons still operate Honda UI while being observed.
   - **No shell-injection escape identified** in the fixed command arguments. Host paths use `ArgumentList`; shell command values exclude metacharacters. `am start -W` is deliberately state-changing; `exec-out screencap -p` has no device output filename. Purity of every OEM dumpsys handler is **UNKNOWN**, rather than established by regex membership.

7. **Assumptions**

   Supplied framework decompilation represents this head unit. Interrupted writes, transient transport failures, and retained app processes are valid counterexamples; their occurrence tonight is not asserted.

8. **Unresolved uncertainties**

   Original XML existence/bytes, current live state, persistent-write success, SystemUI/Honda recovery after overscan, TI shared-service recovery, and exact OEM `getevent` behavior are **UNKNOWN**. No permanent UI damage was established.

9. **Exact diff summary**

   None; no edits or generated files.

10. **Preservation checks performed**

   All four reviewed plan/script hashes remained unchanged between checks. Frozen M5, disabled M6, receiver DEX and API22 TLS qualifier each returned `match=True` against `PROJECT-RULES.md`. Grid/decoder APK hashes matched their pinned values. No rebuild, key-material access, device access, milestone action, or Git mutation occurred.