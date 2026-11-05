1. **Files inspected**  
`R = analysis/test-prep/todo-tests-20261103/`; `J = source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/`.  
Read AGENTS.md, PROJECT-RULES.md, CODEX-BATCH2.md, relevant candidate sources, T33 host-test source, runner, T30 test.json, five source manifests/build reports, and baseline files.

2. **Files changed:** none.

3. **Commands run:** read-only `Get-Content`, `rg`, and Node numbered reads/SHA-256 comparisons. Initial `tools/Run-Test.ps1` lookup failed; reviewed `R/tools/Run-Test.ps1`.

4. **Tests run and results:** no builds or runtime tests. Read-only integrity comparison **PASS**: 21 baseline entries and 18 candidate entries; zero manifest/baseline/build-report hash mismatches.

5. **Findings**

| Candidate | Verdict |
|---|---|
| T25-car-gps | READY FOR CAR TEST |
| T30-persistent | **NOT READY** — write-result handling remains incomplete |
| T33-absolute-touch | READY FOR CAR TEST |
| T34-volume-look | READY FOR CAR TEST |
| T35-home-launch | READY FOR CAR TEST |

6. **Primary evidence for each finding**  
Candidate references below are relative to `R/builds/`.

- **T30 receiver — FIXED:** DUMP required at `T30-persistent/source/analysis/parallel-aa-receiver/usb-helper/AndroidManifest.xml:30`.
- **T30 OFF/callbacks — FIXED:** OFF stops the service at `T30-persistent/J/BootBlockerReceiver.java:29`; every check re-reads the preference at `PersistentBootService.java:34`; destruction cancels callbacks at `:44`.
- **T30 timing — FIXED:** 0/20/60/120/300-second checks at `T30-persistent/J/PersistentBootService.java:16`.
- **T30 write results — NOT FIXED completely:** enable returns `listed && enabled` at `T30-persistent/J/PersistentMode.java:67-70`; removal still ignores both `putString` results and logs success at `:83-85`. A false removal result can therefore escape detection before grant revocation (`T30-persistent/test.json:35-36`) and the runner’s cleanup announcement (`R/tools/Run-Test.ps1:72`).
- **T30 connection scan — FIXED:** detector scan scheduled after 1,000 ms at `T30-persistent/J/PermissionClickService.java:298-299`.
- **T30 accessibility race/global switch — ACCEPTED:** whole-list read/write and global switch remain at `T30-persistent/J/PersistentMode.java:62,67-68,81-84`.
- **Runner — FIXED:** hook returns false on skip and true on completion (`R/tools/Run-Test.ps1:45,52`); failed Diagnostics invokes undo (`:115`); both skipped-undo paths print NOT FULLY CLEANED and return before the cleanup announcement (`:68-72,117-118`). Empty hooks return true as a successful no-op (`:41`).
- **T33 — FIXED:** `release()` at `T33-absolute-touch/J/AbsoluteTouch.java:52`; minimize release at `AaOverlayService.java:662`; UP callback at `:769-771`; teardown release precedes reset at `:794-795`. DOWN/MOVE use their event coordinates through `toActive()` at `:394-396,753-761`.
- **T34 — FIXED:** HUD animation cancelled before reference removal at `T34-volume-look/J/AaOverlayService.java:761-762`.
- **T35 — FIXED:** stock package plus `ProjectionActivity` suffix required at `T35-home-launch/J/PermissionClickService.java:36,45-47`.
- **T25 — FIXED:** disabled GPS only logs; subscription proceeds at `T25-car-gps/J/GpsForwarder.java:47-49`.

7. **Assumptions:** supplied firmware DUMP protection/grants are accepted task context. READY denotes this narrow source review, not live authorization.

8. **Unresolved uncertainties:** no additional regression established in inspected paths. Live behavior remains **UNKNOWN**. T33’s normal session shutdown closes transport before overlay removal (`AaSessionService.java:622-624,655-658`); its touch callback ignores sends once `running=false` (`:219`), so teardown callback invocation does not establish wire delivery.

9. **Exact diff summary:** none; reviewer made no changes.

10. **Preservation checks performed:** baseline and candidate hash comparisons above passed. No Git, network, build, device, credential/private-material access, or milestone action; frozen artifacts were not modified or rehashed.