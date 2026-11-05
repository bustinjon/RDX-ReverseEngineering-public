**Verdict: READY FOR CAR TEST**, for the requested parked checks. E2, E3, E4 and E6 are **FIXED** in the reviewed source; live behavior remains **UNKNOWN**.

Paths below: `P = analysis/test-prep/todo-tests-20261103`; `B = P/builds/T50-bundle`; `S = B/source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper`.

1. **Files inspected:** `PROJECT-RULES.md`, `AGENTS.md`, previous `CODEX-BUNDLE.md`; six changed Java files, `AaMediaSourceService.java`, manifest, `BundleTests.java`, baseline overlay/HomeToggle, `VISIT.md`, source/package/test records and preservation manifest.

2. **Files changed:** none.

3. **Commands run:** read-only `Get-Content`, `Get-ChildItem`, `rg`, `Select-Object`, `ConvertFrom-Json`, `Test-Path`, `Get-FileHash`, `Format-List`. A `python -B -c` read attempt failed because the WindowsApps executable was inaccessible; no script executed.

4. **Tests run and results:** no builds or executable tests run. Read-only hash verification returned **17/17 candidate matches and 10/10 existing baseline matches**. Existing `B/host-test-output.txt:1-6` records **69 passing checks**, not independently rerun.

5. **Findings:**
   - **E2 — FIXED:** plain HUD follows the baseline display path; reset includes density/display; chord and orphan Guide releases restore.
   - **E3 — FIXED:** all five switches are snapshotted; tile return uses that snapshot; media component changes only at accepted START.
   - **E4 — FIXED:** minimization precedes launch on the overlay handler; minimize failure prevents opening; launch exceptions trigger restoration when this call minimized AA.
   - **E6 — FIXED:** defaults/reset, Home before replug, Standard verification replug, parked checks, optional moving GPS and T41 prerequisite are present.
   - **Regressions:** no new threading, null-instance, double-restore or failed-open state defect established in the inspected paths.

6. **Primary evidence for each finding:**
   - **E2:** `S/AaOverlayService.java:99,768-781,810-837` guards fades, maximum-volume query and style logging; plain styling/display matches baseline overlay lines `94-95,691-722`. `S/AppSettings.java:13,48-51` resets density 229, display on and five switches off. `S/HomeToggle.java:44-58` implements lone ≥1500 ms LONG; every other non-canceled release is SHORT. `S/PermissionClickService.java:209-213` routes these and returns false.
   - **E3:** `S/AppSettings.java:55-78` contains five final switch fields and snapshot reads. `S/AaSessionService.java:114-133` rejects duplicate START before snapshot/application; `75-82` applies the component setting. `S/PermissionClickService.java:45` reads `flags().tileReturn`; `S/SettingsActivity.java:81-83` writes preferences only.
   - **E4 / recovery:** `S/AaOverlayService.java:151-174` handles null instance, posts sequential work, checks minimize outcome and restores once on a thrown launch failure. Handler initialization precedes volatile instance publication at `86,213-217`. Minimize failure resets state at `717`; restore success resets it at `735`; restore failure returns it to minimized at `728-732`. `S/HomeToggle.java:26-30` clears state before the recovery restore.
   - **E6:** `P/VISIT.md:5,17-18,26,37,39,44,53` supplies the requested corrections.

7. **Assumptions:** accepted differences and the user’s decision to omit driving-state gating stand. READY denotes readiness for testing, not authorization for device action or milestone advancement.

8. **Unresolved uncertainties:** **UNKNOWN:** Honda key delivery/chord behavior, actual activity/lock-task outcome, HUD rendering and media-source rediscovery. `startSettings()` detects thrown exceptions (`S/AaOverlayService.java:169-174`); actual Settings visibility requires live verification. Host tests do not exercise Android launch/minimize failures (`B/BundleTests.java:7-28`).

9. **Exact diff summary:** none; no files changed.

10. **Preservation checks performed:** **5/5 frozen files matched** the four SHA-256 anchors in `PROJECT-RULES.md`, including both receiver DEX copies. T50 APK hash matched package metadata: `FF521CEAC463E8BDCC7911581FA2697B48D34A7A568E8A962DA3A6CF534216A0`. No Git, network, build, device/ADB, credential or private-test-material access occurred; no milestone or guard changed.