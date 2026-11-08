1. **Files inspected:** `PROJECT-RULES.md`, `AGENTS.md`; T130/T140 `AbsoluteTouch`, `AaOverlayService`, `AppSettings`, `SettingsActivity`, `BundleTests`, `AbsoluteTouchTest`; T140 `ScrollStrip`, `AaSessionService`, saved host-test output/configuration; `VISIT.md`; T130 `RESULT.md`.
   Paths below: `B=analysis/test-prep/todo-tests-20261103`; `S=B/builds/T140-bundle/source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper`.

2. **Files changed:** none.

3. **Commands run:** read-only `Get-Content`, `rg`, `Get-ChildItem`, `Get-Command`, `fc.exe /n` and `/b`. Python comparison failed to launch; two PowerShell/search attempts failed and were corrected. No Git/network/device/build commands.

4. **Tests run and results:** none executed. Existing `B/builds/T140-bundle/host-test-output.txt:1,9` records 15 absolute-touch and 183 bundle checks passing; these were not independently reproduced.

5. **Findings:** item 1 **BLOCKER**; item 2 **BLOCKER**; item 3 **SHOULD-FIX**; item 4 **SHOULD-FIX**. Verdict: **NOT READY**.

6. **Primary evidence for each finding:**
   - **1 — Gesture lifecycle:** a hover while pressed can change coordinates and activate dragging (`S/AbsoluteTouch.java:81–84`), but the hover path sends no touchscreen MOVE (`S/AaOverlayService.java:734–739`; `S/AaSessionService.java:518`). Counterexample: DOWN at A → hover beyond 50 units → physical UP: transmitted sequence can be DOWN(A), UP(B), without MOVE. UP uses the changed position (`S/AaOverlayService.java:621–627`).
   - **1 — Cleanup OK by inspection:** MOVE requires pressed state (`S/AbsoluteTouch.java:106`); UP/CANCEL clear it (`:107–110`). Long Back minimizes (`S/AaOverlayService.java:491–494`); minimize releases (`:897`); release leaves/flushed strip gestures before absolute UP (`:1033–1041`); teardown releases before reset (`:1077–1078`). Strip `leave()` emits MOVE/UP when needed (`S/ScrollStrip.java:94–101`). Native delivery success remains UNKNOWN.
   - **2 — Reset blocker:** reset clears `hn`, not `hi` (`S/AbsoluteTouch.java:60`); writes use `hi` (`:90`), reads scan slots `0..hn-1` (`:119–121`). Static counterexample: hover(500,300,1000), reset, hover(900,300,2000), DOWN(2010) selects stale slot 0 at x=500 instead of the new sample.
   - **2 — Edges/units:** thresholds 2/50 operate in active coordinates (`S/AbsoluteTouch.java:66,82,87`; `S/AaOverlayService.java:1021–1029`). Relative dragging clamps only minimums (`S/AbsoluteTouch.java:83`); frame clamping permits y through 1079 (`:21–23`), beyond the default active height 720 (`S/AaOverlayService.java:65`). Freeze sampling/selection consistently use uptime (`:616,621,734`); touchscreen sending ignores the supplied event timestamp (`S/AaSessionService.java:529–532`).
   - **3 — Off parity:** timed methods delegate to legacy logic (`S/AbsoluteTouch.java:79,95`), and `fc.exe /b` reports identical `AbsoluteTouchTest.java` files. However, the new ring condition suppresses pressed MOVE updates even with steady off (`S/AaOverlayService.java:618–619`); therefore whole-service behavior is not exactly T130.
   - **4 — VISIT mismatch:** `B/VISIT.md:8` promises steady ring behavior. Both ring call sites still use raw coordinates (`S/AaOverlayService.java:619,735`), while taps use filtered/history coordinates (`S/AbsoluteTouch.java:88,98–100`); hover updates also move the ring while pressed. Default-on/schema/toggle/replug instructions agree with `S/AppSettings.java:31,43,63`, `S/SettingsActivity.java:95`, and `B/VISIT.md:24`.

7. **Assumptions:** counterexamples are static source traces, not executed tests.

8. **Unresolved uncertainties:** actual hover/press interleaving, dispatch latency and native delivery are **UNKNOWN**. T130’s problem baseline is documented at `B/builds/T130-bundle/RESULT.md:11`.

9. **Exact diff summary:** none; review only.

10. **Preservation checks performed:** read-only operations only; no credentials/private-test material accessed. Frozen artifacts untouched; hashes not independently checked.