1. **Files inspected:** `PROJECT-RULES.md`, `AGENTS.md`, `analysis/agent-reviews/todo-tests-20261103/CODEX-T220.md`; service, AppSettings and BootBlockerReceiver under `H=analysis/test-prep/todo-tests-20261103/builds/T220-bundle/source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper`.
2. **Files changed:** none.
3. **Commands run:** read-only `Get-Content`, `rg`, `ForEach-Object` for numbered excerpts.
4. **Tests run and results:** none; static inspection only.
5. **Findings — verdict: NOT READY.**

   - **F1 NOT FIXED completely:** normal daily startup gets recovery, but daily takeover of an already-running Developer test removes its timeout without scheduling `dailyWatch`: `H/WirelessProbeService.java:476-498`.
   - **F2 NOT FIXED:** accepted limitation remains; variant selection requires `!running`: `H/WirelessProbeService.java:479-483`.
   - **F3 NOT FIXED completely:** success reasserts the flag, but an older reset callback still unconditionally clears it if delivered afterward: `H/WirelessProbeService.java:527`, `:804`. Actual callback ordering is **UNKNOWN**.
   - **F4 FIXED:** normal accept-loop exits clear and close their matching server slots: `H/WirelessProbeService.java:626`, `:666`; daily reopening is at `:92-93`.
   - **F5 FIXED for session-ended:** daily mode returns sticky: `H/WirelessProbeService.java:468`.

6. **Primary evidence:** source locations above; F1’s watchdog scheduling is inside `!running`, while the daily transition occurs before that condition.
7. **Assumptions:** F2 is accepted as instructed; F5 assessment covers the requested session-ended branch.
8. **Unresolved uncertainties:** runtime recovery and cross-channel callback ordering are **UNKNOWN**.
9. **Exact diff summary:** none.
10. **Preservation checks performed:** read-only commands only; no builds, Git, network, device access or key-material reads. Frozen hashes were not reverified.