**Verdict: NOT READY for the bundle as specified.** Feature code is retained, but two switches bypass session snapshots and the new Settings launch lacks safety checks.

1. **Files inspected**

   `PROJECT-RULES.md`, `AGENTS.md`; T50’s 17 source/manifest files; corresponding baseline and T25/T33/T34/T35/T37/T38/T39/T41 files; T50 test/build records; `VISIT.md`; Survey and its three child scripts; related launcher, preparation and phone-policy instructions.

2. **Files changed**

   None.

3. **Commands run**

   Read-only `Get-Content`, `Get-Item`, `Get-ChildItem`, `Get-Command`, `rg`, `Get-FileHash`; Python `-B -c` byte comparisons, unified diffs and manifest/hash verification. Interpreter/module probes and an in-memory PowerShell parser attempt also ran. No Git, network, build, device or ADB command ran.

4. **Tests run and results**

   - Source-manifest verification: **17/17 candidate hashes and 10/10 existing baseline hashes matched**; no unlisted Java/XML bundle files.
   - Candidate comparison: **10 component files byte-identical**; shared integration changes inspected against each candidate.
   - Frozen-artifact verification: **5/5 files matched the four preservation anchors**, including both listed receiver DEX copies.
   - Existing `host-test-output.txt:1–6` records **68 passing checks**; these were **not rerun**.
   - PowerShell parsing was blocked by ConstrainedLanguage. Its subsequently printed “0 parse errors” values are **not valid results**.

5. **Findings**

   - **1 — OK: merge retention.** No lost or newly duplicated feature logic found across the eight candidates. GPS, touchscreen registration/events, both volume layouts, restore routes, FPS logging, settings, media callbacks and extra-phone policy are retained. Integration defects follow below. **[E1]**
   - **2 — SHOULD-FIX: all-off equivalence is false.** At default settings, the plain volume HUD now fades in/out, queries master maximum volume and emits additional style logging. Long Guide presses always open Settings; Guide releases during observed chords no longer restore AA. Fine-location permission is also added regardless of the GPS switch. Moreover, feature switches being off does not reset density or `volume_display`. **[E2]**
   - **3 — BLOCKER: not every switch is session-fixed.** Absolute touch, volume look, GPS, density and volume display use the snapshot. **Tile return reads preferences live**, and **media-source availability changes immediately** through PackageManager. Both therefore change during an existing connection. Absolute registration and overlay use the same snapshot; toggling its preference off does not change the current mode. Held-touch release on minimize/teardown is independent of that preference. Both HUD layouts are present, but both receive the new animations. **[E3]**
   - **4 — BLOCKER: Settings launch is insufficiently guarded.** Observed Home/Back chords suppress the new Guide action, and keys remain unconsumed; actual Honda shortcut preservation is **UNKNOWN**. A standalone long press can nevertheless launch Settings with AA visible, with no foreground, lock-task or parked-state check. Minimization is queued, while `startActivity()` runs immediately without waiting for success. `NEW_TASK` and exception handling are present, but a failed launch has no restoration path. **[E4]**
   - **5 — OK: survey commands remain read-only on the head unit.** They perform state/query reads and launcher copying; local evidence files are written. `-Yes` skips only each initial confirmation. Connection checks and the Signals action prompt/sampling remain. **[E5]**
   - **6 — SHOULD-FIX: VISIT needs corrections.** Its blanket “next connection” and exact-baseline claims contradict findings 2–3. Explicitly establish switches off, volume display on and Standard density before comparison. The loop omits returning Home before reconnecting, and Standard density lacks a final verification reconnect. The second-phone shortcut omits the required Honda **Disabled/Never** prerequisite. “Stay parked” also conflicts with the GPS “short drive” instruction; separate stationary operations from any authorized moving test. **[E6]**

6. **Primary evidence for each finding**

   Paths below use the workspace root `C:/Users/REDACTED/Desktop/RDX-ReverseEngineering`.

   - **E1:** Python byte-comparison output returned `IDENTICAL` for SensorSource, GpsForwarder, InputSource, AbsoluteTouch, RestoreActivity, FrameRate, VideoSink, AaMediaSourceService, HondaPhonePolicy and UsbHelperService. Shared integrations appear in [AaSessionService.java:329](/C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/test-prep/todo-tests-20261103/builds/T50-bundle/source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/AaSessionService.java:329), lines 399–413 and 635–640; manifest entries are at lines 8, 13, 20, 37 and 40.
   - **E2:** [AaOverlayService.java:95](/C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/test-prep/todo-tests-20261103/builds/T50-bundle/source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/AaOverlayService.java:95), lines 749–754 and 802–811 contain unconditional animations/querying. Baseline counterparts use immediate visibility changes. [AppSettings.java:31](/C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/test-prep/todo-tests-20261103/builds/T50-bundle/source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/AppSettings.java:31) reads density/display preferences separately; SettingsActivity:65–66 clears only feature keys.
   - **E3:** Snapshot fields/construction: AppSettings.java:48–64; assignment and duplicate-START rejection: AaSessionService.java:102–125. Live tile read: [PermissionClickService.java:45](/C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/test-prep/todo-tests-20261103/builds/T50-bundle/source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/PermissionClickService.java:45). Immediate component toggle: [SettingsActivity.java:79](/C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/test-prep/todo-tests-20261103/builds/T50-bundle/source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/SettingsActivity.java:79), lines 80–85. Absolute consistency/release: AaOverlayService.java:184, 692, 828–835, 857–858; AaSessionService.java:341–342.
   - **E4:** [HomeToggle.java:44](/C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/test-prep/todo-tests-20261103/builds/T50-bundle/source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/HomeToggle.java:44), lines 45–57 suppress observed chords. PermissionClickService.java:209–219 launches without context checks and returns false. AaOverlayService.java:147–155 posts minimization; lines 689–700 handle minimization failure independently.
   - **E5:** [Survey.ps1:8](/C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/test-prep/todo-tests-20261103/tools/Survey.ps1:8), lines 9–19 invoke children with `-Yes`. Confirmation gates: Check-Signals.ps1:19, Check-Capabilities.ps1:14, Pull-HondaLauncher.ps1:14. Device-command sites: Signals:20–37; Capabilities:15–29; Pull:15–20.
   - **E6:** [VISIT.md:3](/C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/test-prep/todo-tests-20261103/VISIT.md:3), lines 5, 17–18, 23–27, 36, 38 and 52. Required second-phone condition: [T41 test.json:19](/C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/test-prep/todo-tests-20261103/builds/T41-multi-phone/test.json:19). T50 HondaPhonePolicy.java:64–65 accepts allowlisted phones in cooperative mode; UsbHelperService.java:153–157 treats Honda preference as operator-asserted.

7. **Assumptions**

   “All switches off” means the five feature keys. Baseline comparison additionally requires density 229, volume display enabled and no extra phones.

8. **Unresolved uncertainties**

   **UNKNOWN:** actual Honda key delivery, Diagnostics shortcut behavior, activity-launch/lock-task outcome, HUD rendering, GPS delivery and live APK/source parity. No runtime validation occurred.

9. **Exact diff summary**

   None; no files changed.

10. **Preservation checks performed**

   Frozen M5, disabled M6, both receiver DEX copies and API22 qualifier hashes matched their canonical anchors. T50 APK SHA-256 matched package metadata: `EEDE284E79B98C2607E2353B8D1458B3D119E714C3798CBBFB9C07FF26CF1286`. Credential/private-test material was not opened; no milestone or readiness guard was changed.