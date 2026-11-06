**Verdict: NOT READY.** Items 3, 5 and 7 contain blockers.

Paths: `P = analysis/test-prep/todo-tests-20261103`; `B = P/builds/T60-bundle`; `S = B/source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper`; `O = analysis/parallel-aa-receiver/offline-followup/public/open-headunit/andreknieriem-open-headunit-e9377ff/app/src`.

1. **Files inspected**

   `PROJECT-RULES.md`, `AGENTS.md`; T60/T50/T30/T43 source snapshots and manifests; T50 `RESULT.md`; `CODEX-BUNDLE*.md`; T60 settings, tests, hooks and collection/preparation scripts; `VISIT.md`; shared runner/cleanup code; current VideoGeometry, UsbAttachActivity and BootBlockerService; open-headunit touch mapping, tests and touchscreen declaration; preservation/package metadata.

2. **Files changed**

   None.

3. **Commands run**

   Read-only `Get-Content`, `Get-ChildItem`, `Get-Command`, `Select-Object`, `rg`; Node filesystem reads, comparisons, SHA-256 verification and numbered excerpts. Python and `py` failed to start; one Node verification command had a syntax error and was corrected. No Git, network, build or device command ran.

4. **Tests run and results**

   - Independent hash verification: **T60 23/23**, T50 **17/17**, T30 **5/5**, T43 **4/4** candidate files matched their source manifests. Corresponding existing baseline copies and expected absences matched.
   - Byte comparisons: seven T50 files, three T30 files and two T43 files are identical in T60.
   - Existing `B/host-test-output.txt:1-9` records **113 passing checks**; executable tests were **not rerun**.
   - Five frozen artifacts and the T60 APK matched recorded hashes.

5. **Findings**

   - **1 — OK: merge retention.** No unintended lost or duplicated feature hunk established. T30’s three persistent classes and T43’s ReconnectPolicy/AudioSink are exact copies. T50’s seven unchanged files remain identical; RestoreActivity’s omission matches the requested retirement. Integration defects follow. **[E1]**
   - **2 — SHOULD-FIX: qualify all-off equivalence.** The ordinary permission/AUTO_GRANTED paths and recovery-off START intent retain T50 behavior; no reconnect gate/watchdog runs in that branch. Complete equivalence is nevertheless false: T43’s audio-worker cleanup guard, generation bookkeeping and end broadcasts execute with recovery off. Preserve the cleanup safeguard, but document this difference. The inherited `GRANTED` rejection of direct AOAP AUTO_GRANTED also remains. **[E2]**
   - **3 — BLOCKER: `sessionActiveNow()` is insufficient.** After an unclean shutdown retains workers/native objects, `sessionActive` becomes false. Hackura then replaces ReconnectPolicy, clearing its fail-closed latch and allowing another session in that process. It also misses the interval between issuing START and accepting START. A launch/reset during that interval can discard the reserved generation; a second hand-off can leave the watchdog tracking a generation whose duplicate START was rejected. Accepted duplicate STARTs are guarded, so two simultaneous protocol sessions are **not established**. Pending permission callbacks are not invalidated by LAUNCH. Phone-identity gates remain intact. **[E3]**
   - **4 — SHOULD-FIX: persistent-off gating is incomplete.** Settings correctly preserves the running accessibility service; boot checks recheck the preference. However, an already queued detector retry never checks it and can dismiss after OFF/Reset all. GRANT correctly contains only `pm grant`. Its skipped/result state is discarded, while UNDO always attempts removal/revocation; absent-grant revoke behavior is **UNKNOWN** here. **[E4]**
   - **5 — BLOCKER: T39’s switch gates new roots, not service behavior.** Binding while OFF can still create an active PLAYING MediaSession whenever AA runs. A browser/controller retained from an ON connection can forward keys during a later OFF connection: activation, state updates, children and forwarding lack switch checks. Also address upgrade migration: T50 explicitly wrote component-disabled overrides, whereas preparation uses replacement installation and T60 never clears/verifies that override. Effective enabled/indexed state is **UNKNOWN**. Honda’s selection/retry behavior after a null root is likewise **UNKNOWN**. **[E5]**
   - **6 — OK as an experiment; correctness UNKNOWN.** Top-aligned coordinates have stronger reference support than the comment alone: open-headunit tests that mapping and registers the full negotiated touchscreen dimensions. Thus 1920×1080 registration does not itself demand +180. However, its buffer-top-left observation does not establish this car’s input origin; local VideoGeometry explicitly crops centered margins. Keep the top/center comparison and measure top/bottom targets. Host assertions establish formulas, not alignment. **[E6]**
   - **7 — BLOCKER: power-off/collection evidence and undo handling need repair.** A full reboot ends the shell logger/monitor; neither boot path restarts capture, and Collect pulls existing files without capturing current postboot logs. More seriously, UNDO runs only after Collect succeeds: an original-accessibility mismatch or another collection failure prevents the persistent-off/revoke hook. VISIT provides no failure recovery route. Its GRANT ordering also contradicts the runner. Defaults, sizes, probes and alignment controls otherwise match BundleTests; parked/Home/unplug instructions are appropriate. **[E7]**

6. **Primary evidence for each finding**

   - **E1:** Byte-comparison output: T30 `PersistentMode`, `PersistentBootService`, `BootBlockerReceiver` identical; T43 `ReconnectPolicy`, `AudioSink` identical. T50 identical: SensorSource, VideoSink, InputSource, FrameRate, GpsForwarder, HomeToggle, HondaPhonePolicy. Manifest launcher/service integration: `B/source/analysis/parallel-aa-receiver/usb-helper/AndroidManifest.xml:12,20,35,43,49`.
   - **E2:** T50 `source/.../UsbHelperService.java:495-501` versus `S/UsbHelperService.java:534-546`; recovery reconciliation exits at `:584`. Unconditional cleanup/end behavior: `S/AaSessionService.java:703-733`. Direct AOAP rejection: `S/UsbHelperService.java:218-238`.
   - **E3:** Reset/check: `S/UsbHelperService.java:182-195`; reservation/START: `:549-571`; generation reconciliation: `:585-599`. Accepted-session guard: `S/AaSessionService.java:117-140`. Retained resources followed by inactive state: `:685-733`. Fail-closed rule: `S/ReconnectPolicy.java:52-56`. Outstanding callback registration/processing: `S/UsbHelperService.java:418-429,463-529`.
   - **E4:** Settings OFF/reset: `S/SettingsActivity.java:97-112`; boot recheck: `S/PersistentBootService.java:33-38`. Initial detector gates: `S/PermissionClickService.java:51,302`; ungated retry/action/rescheduling: `:190-215`. Permissionless removal returns at `S/PersistentMode.java:79`. Hooks: `B/test.json:48-56`; discarded setup result: `P/tools/Run-Test.ps1:105`.
   - **E5:** OFF-independent activation: `S/AaMediaSourceService.java:25-34,39-52`; state/forwarding: `:71-83`; root gate: `:87-94`; ungated children: `:98-102`. Snapshot persists beyond shutdown: `S/AaSessionService.java:83,141,725-733`. Previous component override: T50 `source/.../AaSessionService.java:75-80`; replacement install: `tools/car-test/CarTest.Core.ps1:191`. Indexing motivation remains an inference in `P/builds/T50-bundle/RESULT.md:22`.
   - **E6:** `O/main/java/com/andrerinas/openheadunit/input/TouchCoordinateMapper.kt:28-40`; corresponding test `O/test/java/com/andrerinas/openheadunit/input/TouchCoordinateMapperTest.kt:28-47`; full negotiated touchscreen: `O/main/java/com/andrerinas/openheadunit/aap/protocol/messages/ServiceDiscoveryResponse.kt:176-182`. Local centered crop: `analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/VideoGeometry.java:20-23,59-60`; conversion/registration: `S/AaOverlayService.java:839-847`, `S/AaSessionService.java:363`.
   - **E7:** Logger/monitor launch: `B/Prepare-Test.ps1:49-50`; boot path: `S/BootBlockerReceiver.java:37-38`, `S/PersistentBootService.java:33-41`; file collection: `B/Collect-Test.ps1:31-46`; failure before UNDO: `:76,94-97` and `P/tools/Run-Test.ps1:64-66`. Runner grants before TEST NOW (`:105-107`), while `P/VISIT.md:14-15` reverses that order. Power-off/UNDO instructions: `P/VISIT.md:39-49`. Settings/test consistency: `S/AppSettings.java:15-27,89-103`, `B/BundleTests.java:17-30`.

7. **Assumptions**

   All-off comparison means persistent OFF, Standard density, probe OFF, volume ON/Small and unchanged phone policy. Race examples describe possible event ordering, not observed car failures.

8. **Unresolved uncertainties**

   **UNKNOWN:** actual launch ordering, Honda null-root handling/reconnection, retained component overrides, postboot accessibility changes, touch origin, absent-grant revoke status and runtime APK behavior. Recorded host tests do not exercise these Android lifecycle paths.

9. **Exact diff summary**

   None; no files changed.

10. **Preservation checks performed**

   **5/5 frozen files matched** PROJECT-RULES anchors: M5, disabled M6, both receiver DEX copies and API22 qualifier. T60 APK SHA-256 matched candidate metadata: `5F653B92FA47E8034605F274BA33F800E2C26938E735252ED9A59AE44DDB2F3B`. No credential/private-test material was opened; no guard, milestone or artifact was modified.