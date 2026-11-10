1. **Files inspected:** `PROJECT-RULES.md`, `AGENTS.md`; T200/T210 bundled source, manifests; T210 test output; T200 `logcat-now.txt` (23:07–23:12). Below, source filenames refer to T210’s bundled copies.

2. **Files changed:** none.

3. **Commands run:** read-only `Get-Content`, `rg`, `Get-ChildItem`, `Get-FileHash`, `Compare-Object`. Python diff attempt failed because `python.exe` was unavailable; PowerShell comparison succeeded.

4. **Tests run/results:** none executed. Saved [host-test-output.txt](/C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/test-prep/todo-tests-20261103/builds/T210-bundle/host-test-output.txt:1) reports passing suites and 234 bundle checks; this does not establish native/runtime behavior.

5. **Findings/verdict:** **SHOULD-FIX** before declaring all three issues resolved: the Settings timestamp guard has another false-refusal path. No demonstrated **BLOCKER**; fixes 1–2 are **OK** at source level.

6. **Primary evidence:**
   - **OK—requestVideo:** `AaSessionService.java:1295–1297` posts onto the handler created in `onCreate:177`, avoiding native callback re-entry (`1177–1180`). Existing `stuckWatch:1341–1353` calls it while selected; `pictureLost:1207–1212` also requests while AA holds focus. `VideoSink.java:19,37` sends `nativeSetVideoFocus(1,true)`. Native idempotence itself remains **UNKNOWN**.
   - **OK—motion block:** `AaOverlayService.java:183–209` retains restoration when no newer resume occurs; 8000 replaces 3000, adding five seconds of hidden AA without removing the fallback. Home cancels it (`278`).
   - **SHOULD-FIX—Settings already resumed:** `SettingsActivity.java:107` updates the timestamp only on resume; `AaOverlayService.java:205` requires a resume after each request. Track current resumed state as well. T200 [logcat-now.txt](/C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/test-prep/todo-tests-20261103/builds/T200-bundle/headunit-logs-20261108-231319/logcat-now.txt:41842) shows Settings resumed at 23:10:38; another request at `42056` is refused at `42260`. Save Logs succeeds at `42806`, immediately before another refusal (`42810`). Eight seconds can merely postpone this false bounce.
   - **OK—Wi-Fi frame-idle path:** `AaSessionService.java:1345` gates the sole `onStuckScreen()` caller with `!tcpMode`; both TCP entry paths set it (`513,524`). No additional frame-idle minimization path found. The Settings false-refusal path above remains applicable over Wi-Fi.

7. **Assumptions:** review concerns the bundled source; installed/native binary parity was not established.

8. **Unresolved uncertainties:** native safety guarantees, whether duplicate focus requests force a fresh frame, and T210 live behavior are **UNKNOWN**.

9. **Exact diff summary:** no reviewer edits. Source comparison found only the three requested changes in `AaSessionService.java` and `AaOverlayService.java`.

10. **Preservation checks:** source filenames/hash comparison performed; no writes, builds, Git, network, device access, or credential-material reads. Frozen artifact hashes were not checked.