**READY FOR CAR TEST** — scoped source review; live behavior remains **UNKNOWN**. This verdict authorizes no device action.

1. **Files inspected:** `PROJECT-RULES.md`, `AGENTS.md`, prior `CODEX-T100-RECHECK.md`, preservation manifest, and source files cited below.  
   `H=analysis/test-prep/todo-tests-20261103/builds/T100-bundle/source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper`.

2. **Files changed:** none.

3. **Commands run:** read-only `Get-Content`, `rg`, `ConvertFrom-Json`, `Get-FileHash` and output formatting. One brace-based search failed PowerShell parsing; corrected search succeeded.

4. **Tests run and results:** static control-flow inspection only; no builds or executable suites. Preservation comparisons: **8/8 matched**.

5. **Findings:**
   - **1 — OK:** Direct press flushes queued strip events first; release uses the same drain. No additional overlapping direct touchscreen path found.
   - **2 — OK:** All three successful raw-switch routes mark the raw path handled. Given a distinct AOAP path, its needed start remains reachable.
   - **3 — OK:** Restore retry requires both no native focus and no minimization. No regression established from these edits.

6. **Primary evidence:**
   - **1:** `H/AaOverlayService.java:562,567,571` drains before direct touch; `:978-984` drains before release. `:291-294` ends strip interaction while pressed; `H/AbsoluteTouch.java:43-52` tracks press state. Hover sends no phone touch in absolute mode (`H/AaSessionService.java:286`). Touchscreen call sites: overlay `:276,571,984`.
   - **2:** Success-only marking: `H/UsbHelperService.java:276-281,410-415,567-572`; exact-path suppression: `:227-231,240-246`. AOAP starts independently at `:261-271`; polling prioritizes AOAP without consulting `attachHandled` (`:347-354,403-407`).
   - **3:** Both conditions appear at `H/AaSessionService.java:830-832`; stopped sessions are rejected at `:729-730`, with shutdown callback cancellation at `:862`.

7. **Assumptions:** As supplied, successful switching removes the raw path and creates a different AOAP path.

8. **Unresolved uncertainties:** Live ordering and re-enumeration remain **UNKNOWN**. Synchronous draining bypasses normal 16 ms pacing (`H/AaOverlayService.java:268`; `H/ScrollStrip.java:109,120-121`); phone classification remains **UNKNOWN**.

9. **Exact diff summary:** none; no files changed.

10. **Preservation checks:** SHA-256 matched PROJECT-INTEGRITY for all four frozen anchors, including both receiver DEX copies, plus readiness wrapper/core/schema: **8 matches**. No writes, Git, network, builds, devices/ADB, credential/private-material reads, guard changes or milestone actions.