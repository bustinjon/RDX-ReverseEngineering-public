1. **Files inspected**

`R = analysis/test-prep/todo-tests-20261103/`. Reviewed both rule files; all 18 candidate source files and their baseline counterparts; baseline/candidate manifests and build reports; T25/T30/T33 host tests and saved outputs; T30 preparation/collection scripts; both requested tools; stock `SensorSource`/`InputSource`; relevant decompiled framework code.

Below, `Txx/File.java` means that candidate’s `source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/File.java`. Protocol and manifest paths are identified separately.

2. **Files changed**

None.

3. **Commands run**

Read-only `Get-Content`, `Get-ChildItem`, `Get-Command`, `rg`, and Node scripts for numbered reads, baseline diffs, JSON comparisons and SHA-256 checks. Python diff attempts failed because the installed interpreters were inaccessible. No Git, network, build or device commands ran.

4. **Tests run and results**

- Node integrity/comparison checks: **PASS**, detailed below.
- PowerShell parser/Get-SpecValue probe: **BLOCKED by ConstrainedLanguage**; no test result established.
- Saved host outputs report T25 **8**, T30 **10**, T33 **15** passing checks. These were inspected, **not rerun**; they test helpers, not Android lifecycle integration.

5. **Findings**

| Candidate | Classification | Verdict |
|---|---|---|
| T25-car-gps | OK; recovery limitation | **READY FOR CAR TEST** |
| T30-persistent | BLOCKER | **NOT READY** |
| T33-absolute-touch | BLOCKER | **NOT READY** |
| T34-volume-look | SHOULD-FIX | **READY FOR CAR TEST** |
| T35-home-launch | SHOULD-FIX | **READY FOR CAR TEST** |

- **T25 — OK:** Location timestamp, field order and conversions match stock. Reports and destruction share synchronization; missing permission is caught during subscription. **SHOULD-FIX:** GPS disabled at startup prevents subscription permanently for that session; later provider availability does not trigger another start.
- **T30 — BLOCKER:** Any app can explicitly send ON/OFF to the exported, unprotected receiver. ON changes next-boot behavior; OFF immediately removes this accessibility service using the helper’s grant.
- **T30 — BLOCKER:** OFF does not cancel an already-running boot service or its callbacks. A subsequent scheduled check can re-enable accessibility after OFF.
- **T30 — BLOCKER:** Setup precedes the Diagnostics checkpoint, but checkpoint failure omits undo. Skipping UNDO during normal collection still reaches the “cleanup verified” announcement while the persistent preference/grant can remain.
- **T30 — SHOULD-FIX:** Accessibility preservation is conditional. Read/modify/write can overwrite another writer’s changes; the global accessibility switch also affects other listed services. Writes ignore boolean failure results.
- **T30 — SHOULD-FIX:** Late-reset recovery is incomplete: checks stop at 60 seconds, settings presence is treated as service readiness, and an already-visible detector warning is not scanned on accessibility connection.
- **T33 — BLOCKER:** Minimize has no explicit release for the new touchscreen contact. Teardown resets its pressed state before removing the window, suppressing any later CANCEL-derived release. A previously transmitted DOWN can remain unmatched.
- **T33 — SHOULD-FIX:** Touch MOVE ignores its own coordinates; position changes only through hover. Without intervening hover events, a held drag sends repeated old coordinates.
- **T34 — SHOULD-FIX:** Teardown clears handler work but does not cancel an active HUD animator. Its completion retains and accesses the detached HUD. Normal animations are finite; an unbounded leak was **not established**.
- **T35 — SHOULD-FIX:** Every stock-AA window-state event requests restoration, without proving a tile click or checking session-running state. An unrelated event while minimized can reclaim focus. Ordinary no-session handling is guarded; repeated events while visible do not create a restore loop.
- **Pull-HondaLauncher — OK:** Device commands are read-only. It writes downloaded files, logs and hashes locally.

6. **Primary evidence for each finding**

- **T25:** Candidate protocol `SensorSource.java:93–106` matches `decompiled/AndroidAuto-current/sources/com/google/android/projection/protocol/SensorSource.java:179–189,220`. Synchronization: candidate `:99,110`. Subscription failure/recovery: `T25/GpsForwarder.java:33–35,44–59`; session start/stop: `T25/AaSessionService.java:375,630`.
- **T30 exported receiver:** Candidate `AndroidManifest.xml:29–33` declares `exported="true"` without receiver permission; `T30/BootBlockerReceiver.java:22–30` accepts ON/OFF without caller authentication.
- **T30 OFF race:** `T30/PersistentBootService.java:24–28` checks the preference only when scheduling; `:33–40` never rechecks it. `BootBlockerReceiver.java:27–30` neither stops that service nor cancels its work.
- **T30 runner cleanup:** `R/tools/Run-Test.ps1:98–100` executes setup before Diagnostics; `:107–112` collects/restores source without `postCollectAdb`. `:45` allows skipping hooks, yet `:65–67` then announces verified cleanup. Grant/ON and OFF/revoke are `R/builds/T30-persistent/test.json:30–36`.
- **T30 other services:** `PersistentMode.java:62–68,81–84` reads then replaces the whole list. Counterexample: read `A`; another writer adds `B`; write `A:ours` loses `B`. `:68` sets the global switch to `1`; `:84` can clear it using a stale empty remainder.
- **T30 write failure:** `PersistentMode.java:67–70` ignores both return values and returns true. Firmware `decompiled/Framework/sources/android/provider/Settings.java:177–187` returns false on provider `RemoteException`.
- **T30 boot timing/missing grant:** `PersistentBootService.java:16,34–40` checks only at 0/20/60 seconds and starts the helper once. `PersistentMode.java:64–65` accepts already-enabled settings without a grant; otherwise missing permission logs and returns false. `PermissionClickService.java:288–298` registers event observation without scanning existing windows.
- **T26 dismiss restriction:** `T30/PermissionClickService.java:198–204` restricts the root package and searches the warning phrase; `:185–186,224–228` accepts trimmed, case-insensitive “Dismiss” and may click its parent. “Remove all” cannot pass the label predicate. Literal-exact text matching is **not** enforced; firmware `TextView.java:5430–5436` implements substring search.
- **T33 stuck contact:** DOWN transmission: `AaOverlayService.java:393–400`. Minimize only cancels old select state at `:654–661`. Teardown resets absolute state at `:764–765`, before window removal at `:788`. `AbsoluteTouch.java:43–46,51` drops releases after reset.
- **T33 drag:** `AaOverlayService.java:391–400` reads action but not touch coordinates; position updates occur at `:494–495`. The host test manually supplies hover before MOVE: `R/builds/T33-absolute-touch/AbsoluteTouchTest.java:19–20`.
- **T33 native/key compatibility — OK:** Candidate protocol `InputSource.java:31,40–42,75–86` matches stock declarations/call at `decompiled/AndroidAuto-current/sources/com/google/android/projection/protocol/InputSource.java:46,56,136`. Key registration remains at candidate `:77`; baseline `InputEvents.java:20` includes Back `4` and select `23`.
- **T34:** `AaOverlayService.java:94–99,745–751` creates/cancels animations during display; `:755–777` drops the HUD without animator cancellation. Reflection is caught at `:697–700`; firmware `AudioManager.java:520–526` contains the getter. Handler work is cleared at `:770`.
- **T35:** `PermissionClickService.java:45–48` accepts all stock-package window events. `AaOverlayService.java:118–125` checks instance/container/test mode, not session state. Baseline `HomeToggle.java:26–30` makes restoration a no-op once visible. `RestoreActivity.java:13–17` requests restoration and finishes.
- **Pull tool:** `R/tools/Pull-HondaLauncher.ps1:14–19` uses get-state, ls, dumpsys and pull; `:11,16–22` writes locally. Broadcast flag `32` is INCLUDE_STOPPED_PACKAGES in firmware `decompiled/Framework/sources/android/content/Intent.java:353`.

7. **Assumptions**

The supplied baseline is the accepted car-passed build; the firmware permission/grant description is accepted as task context. READY means this source review found no blocking defect, not live authorization.

8. **Unresolved uncertainties**

Actual JNI blocking/error behavior, event ordering, reverse-camera precedence, and stock-AA interactions on the car remain **UNKNOWN**. APK contents and signatures were not independently verified. T35’s broad event trigger could cause unwanted restoration; an actual repeating live loop was not established.

9. **Exact diff summary**

Reviewer diff: none. Candidate source counts against baseline: T25 **4**, T30 **5**, T33 **4**, T34 **1**, T35 **4**. Build-report Java changes were exactly **3/4/4/1/3**, with no unexpected or missing reported changes.

10. **Preservation checks performed**

Baseline manifest: **21 entries, zero mismatches**, identifying `191E43A65D3935D036382D1671FA3286641732C26C48E453B9427D003A96F48C`. All 18 candidate source entries matched their source manifests and corresponding build-report records. Every candidate reports the baseline native-library hash. Frozen binaries were not rebuilt, modified or rehashed; credentials/private-test material were not opened.