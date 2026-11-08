1. **Files inspected:** `PROJECT-RULES.md`, `AGENTS.md`; supplied reviews/reconciliation; T140 `AbsoluteTouch`, `AaOverlayService`, `PermissionClickService`, `AppSettings`, `SettingsActivity`, `PersistentMode`, manifest, saved tests/output; `VISIT.md`; detector `MDService`, strings, and `HondaDialog`.
   Paths: `B=analysis/test-prep/todo-tests-20261103`; `S=B/builds/T140-bundle/source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper`; `E=analysis/parallel-aa-receiver/warning-phonefree-20261025-190517`.

2. **Files changed:** none.

3. **Commands run:** read-only PowerShell `Get-Content`, `ForEach-Object`, `rg`, and `rg --files`. No Git, network, build, or device commands.

4. **Tests run and results:** none executed. Saved `B/builds/T140-bundle/host-test-output.txt:1,6,9` reports 15 absolute-touch, 9 dismiss-label, and 189 bundle checks passing; not independently reproduced.

5. **Findings:** item 1 **BLOCKER**; item 2 **OK** for the acquired detector UI; item 3 **SHOULD-FIX**. Verdict: **NOT READY**.

6. **Primary evidence for each finding:**
   - **1 — Normal UP fixed:** DOWN/MOVE record sent coordinates; UP/CANCEL restore them (`S/AbsoluteTouch.java:102,110,113–118`).
   - **1 — Cleanup still broken:** `release()` only clears flags (`S/AbsoluteTouch.java:58`); pressed hover can change position without sending MOVE (`:82–85`; `S/AaOverlayService.java:734–739`). Minimize/teardown then send UP using that changed position (`:897,1033–1041,1077`). Counterexample: DOWN(A), hover beyond drag threshold to B, minimize → DOWN(A), UP(B), without MOVE.
   - **1 — Reset/ring fixes OK:** reset clears both history indices (`S/AbsoluteTouch.java:60`); steady-off permits ring updates (`S/AaOverlayService.java:618–619`).
   - **2 — Detector branch excludes other-package/own roots:** requires detector package and warning text (`S/PermissionClickService.java:242–248`), then exact trimmed, case-insensitive “Dismiss” (`:228–229,269`). “Remove all” cannot match.
   - **2 — Acquired UI agrees:** detector creates distinct Dismiss/Remove all buttons; only Remove all invokes uninstall (`E/detector-jadx/sources/com/honda/maliciousdetector/service/MDService.java:102–118`; `E/detector-jadx/resources/res/values/strings.xml:3–6`). Dismiss has a null callback and closes the dialog (`E/honda-ui-jadx/sources/com/honda/ui/HondaDialog.java:148–152,486–498`).
   - **2 — Cost/lifecycle:** scans enumerate all window roots, search detector subtrees, and recycle acquired objects (`S/PermissionClickService.java:237–256`). First scan is after 1 s, then 2 s intervals, at most 90 per trigger; success returns before rescheduling; destroy removes callbacks (`:21–22,248,259,331–351`). Detector events reset the budget (`:54–58`).
   - **2 — Persistent-off works by inspection:** both entry points gate on AUTO_DISMISS, independently of persistent mode (`:54,233,351`); changing persistent mode only writes its preference (`S/PersistentMode.java:26–27`). AUTO_DISMISS defaults on and has a Developer toggle (`S/AppSettings.java:31,98`; `S/SettingsActivity.java:192`).
   - **3 — VISIT partly consistent:** ring-versus-tap wording now matches raw ring updates (`B/VISIT.md:9`; `S/AaOverlayService.java:619,735`). However, manual dismissal after one minute prevents observing the advertised three-minute fallback (`B/VISIT.md:8,34–35`).

7. **Assumptions:** counterexample is a static source trace; acquired detector/UI represents the intended firmware.

8. **Unresolved uncertainties:** live window discovery, dismissal reliability, scan latency, and native delivery are **UNKNOWN**. The clickable-parent fallback (`S/PermissionClickService.java:271–274`) does not independently validate the parent; universal safety for arbitrary UI trees is unproven.

9. **Exact diff summary:** none.

10. **Preservation checks performed:** read-only inspection only; no credential/private-test material accessed, devices touched, milestones advanced, or artifacts rebuilt. Frozen hashes were not rechecked.