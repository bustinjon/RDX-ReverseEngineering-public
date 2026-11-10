1. Files inspected: `PROJECT-RULES.md`, `AGENTS.md`; T270/T280 sources, manifests, tests, saved results; T260 AudioSink; Run-Test and both CMD files. Below, `R=analysis/test-prep/todo-tests-20261103`, `B=R/builds/T280-bundle`, `J=B/source/analysis/parallel-aa-receiver`, `S=J/usb-helper/source/com/rdx/fullscreen/usbhelper/AaSessionService.java`, `U=same directory/SettingsActivity.java`.

2. Files changed: none.

3. Commands run: read-only `Get-Content`, `Get-ChildItem`, `Get-Command`, `rg`, `Compare-Object`, `fc.exe`. Python/py attempts failed to launch; corrected `fc.exe` comparisons succeeded.

4. Tests run/results: none rerun. Existing `B/host-test-output.txt:10` reports **PASS 253 bundle checks**; parser fixtures are `B/BundleTests.java:151–154`.

5. Findings: **Verdict: SHOULD-FIX before relying on recorder evidence. No demonstrated BLOCKER; target performance and platform semantics remain UNKNOWN.**

   **OK — Audio:** source-level playback matches pre-T270: both cushion gates are constant-false; remaining additions are unused helpers/state resets. Actual audible equivalence is UNKNOWN.

   **SHOULD-FIX — Lifetime:** normal termination exits when the sampler next observes false. No recorder handle, interrupt, join or session token prevents overlap if the same instance restarts before that observation; overlap is possible, not demonstrated.

   **SHOULD-FIX — Cost/stalls/spam:** stall onset can perform two full process scans immediately when `quiet/1000` is even. Each scan reads every PID; ranking sorts results. Background priority cannot eliminate allocation/I/O contention. Logging continues indefinitely: up to eight history lines, then approximately one sample/second plus CPU reports. Dual-core cost is UNKNOWN; bound scans/logging and measure.

   **SHOULD-FIX — Parsing:** ordinary counter fields and PID names with parentheses are handled. CPU “busy” includes iowait; total sums guest fields too. PID ranking lacks process-start identity, allowing PID-reuse misattribution. Existing fixtures do not cover these cases.

   **SHOULD-FIX / UNKNOWN — Automatic saves:** priority is set before exec, but actual child priority and Android 5.1 `-t ⇒ -d` lack local primary evidence. If output streams, the blocking read has no timeout. **OK:** the button remains on its separate, unchanged normal-priority `-d` path.

   **SHOULD-FIX — Startup hook:** trailing `true` masks activity/HOME command failures. A missing success marker still makes Invoke-Hook throw. Failed HOME can leave Honda Settings foreground; persistent activity side effects are UNKNOWN.

   **OK — Collection:** bundle/nopause arguments match the caller. Collect proceeds after either reported pull failure because the wrapper does not branch on its result.

6. Primary evidence: audio `J/src/com/google/android/projection/protocol/AudioSink.java:38,196,205,208` and T260 comparison; lifetime `S:889,1108,1132,1218,1557,1605`; cost/logging `S:1116–1124,1157,1189–1209`; parsing `S:1147,1183,1187,1203`; saves/button `U:51,65,265,276–279,335`; hook `B/test.json:129–130`, `R/tools/Run-Test.ps1:49–51`; collection `R/Pull-Hackura-Logs.cmd:11–19`, `R/Collect-T280-bundle.cmd:4–7`.

7. Assumptions: T260 represents pre-T270 playback; snapshot source is the review target.

8. Unresolved uncertainties: packaged/runtime parity, restart timing, target scan latency, logcat priority/options and Honda activity side effects.

9. Exact diff summary: no review changes. Source manifests identify three changed Java files; inspected diffs contain the requested audio, recorder and automatic-save changes.

10. Preservation checks: only local read-only inspection; no builds, Git, network, device commands, key-material reads or artifact modifications. Frozen hashes were not reverified.