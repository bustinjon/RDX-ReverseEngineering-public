**Verdict: NOT READY.** E3 is fixed; E4/E5/E7 retain gaps, and wireless cleanup needs repair.

Paths: `P = analysis/test-prep/todo-tests-20261103`; `B = P/builds/T60-bundle`; `S = B/source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper`; `O = analysis/parallel-aa-receiver/offline-followup/public/open-headunit/andreknieriem-open-headunit-e9377ff/app/src/main/java/com/andrerinas/openheadunit/connection/wifi/direct`.

1. **Files inspected**

   `PROJECT-RULES.md`, `AGENTS.md`, prior `CODEX-T60.md`; S: UsbHelperService, AaSessionService, PermissionClickService, AaMediaSourceService, SettingsActivity, WirelessProbeService, ReconnectPolicy, BootBlockerReceiver, PersistentMode; bundled manifest, test/package metadata, preparation/collection scripts and recorded test output; `P/tools/Run-Test.ps1`, After-PowerOff scripts, VISIT; preservation manifest; wireless feasibility report and reference WifiDirectManager/Compat.

2. **Files changed**

   None.

3. **Commands run**

   Read-only `Get-Content`, `rg`, `Get-Command`, `Select-Object`, `Get-FileHash`; Node filesystem reads, JSON parsing and SHA-256 comparisons. Some path/glob reads failed; a constrained-PowerShell `[Math]` invocation failed and was corrected. No Git, network, build or device command ran.

4. **Tests run and results**

   - Independent verification: `SOURCE_MANIFEST 24/24`; test.json parsed with four undo commands.
   - T60 APK: `F80163A1D1A34BF2C3AAF837E1C0672358B20A43FD319FEEEC93F886EC0EF3EB`, matching candidate metadata.
   - Frozen artifacts: **5/5 matched** preservation anchors.
   - Existing `B/host-test-output.txt:1-9` records 113 passing checks; executable tests were not rerun.

5. **Findings**

   - **E3 — FIXED:** LAUNCH retains ReconnectPolicy and checks active session, phase, pending hand-off, unclean end, disabled policy and tracked session. This resolves the reviewed LAUNCH reset defects. **[A]**
   - **E4 — NOT FIXED overall:** detector retry gating is fixed. Tolerant revocation is followed by verification, but that verification can falsely succeed on command errors. **[B, C]**
   - **E5 — NOT FIXED:** activation, PLAYING and forwarding use `enabledLive()`, and START clears the component override. Children still require only the retained switch: after an ON session ends, a retained browser can receive the playable item while AA is stopped. **[D]**
   - **E7 — NOT FIXED:** independent postboot capture/undo, corrected GRANT order, failure route and postboot audio-source recheck exist. After-PowerOff can nevertheless announce success without verifying accessibility removal or successful log capture. **[C, E]**
   - **P1 — NEW ISSUE:** stop/destruction closes the listener, but does not synchronously close the accepted socket or join the worker. Stop/start while P2 keeps this service alive can let an old worker consume the new `btRunning/server` state or post `stopBt()` against the new listener. **[F]**
   - **P2 — NEW ISSUE:** removal failure clears busy state and permits service shutdown without confirming group removal. Destruction logs removal immediately after an asynchronous request with no result callback. Late callbacks lack a destruction/generation guard. Persistent profiles are neither inventoried nor deleted; zero leftovers is unproven. **[G]**
   - **Honda/USB safety — UNKNOWN:** P1 does not explicitly reconfigure HFP, but Honda-stack coexistence is untested. P2 actively creates a radio group; station coexistence/restoration is unverified. Neither probe directly starts USB AA, but they share its process: uncaught P2 runtime exceptions can terminate that process, and lingering radio activity can affect phone connectivity. USB unplug does not stop these probes. **[F–H]**

6. **Primary evidence for each finding**

   - **[A]** `S/UsbHelperService.java:68,184-198,621-630`; `S/AaSessionService.java:82,119-120,759-762`.
   - **[B]** Retry enters the newly gated method: `S/PermissionClickService.java:31,190-191`; hook order: `B/test.json:58-62`.
   - **[C]** `B/test.json:61-62`, `P/tools/After-PowerOff.ps1:23-24`: `! ... | grep ...` turns a final grep error/no-match into success, including empty upstream output. Target Android 5.1 toolbox support for `grep -A40` is **UNKNOWN** from inspected primary evidence; unsupported-option failure would also falsely pass. PowerShell correctly escapes remote `$?` at `P/tools/Run-Test.ps1:47` and After-PowerOff `:28`; quoting is not the established defect.
   - **[D]** Correct gates: `S/AaMediaSourceService.java:32-33,50,71-85`; switch-only root/children: `:93-104`. Snapshot retained across shutdown: `S/AaSessionService.java:85,160,745-753`. Override clearing: `:106-116,162`.
   - **[E]** Capture and undo precede Collect: `P/tools/After-PowerOff.ps1:19-35`; capture exit status is unchecked, accessibility is recorded only before undo, and success depends on the three shell steps. Accessibility removal can return without writing: `S/PersistentMode.java:78-87`; receiver still logs OFF: `S/BootBlockerReceiver.java:27-31`. Documentation repairs: `P/VISIT.md:14-15,51,56-59`.
   - **[F]** Accepted socket remains worker-local: `S/WirelessProbeService.java:93-108`; shared loop state/final stop: `:92,112`; stop/destruction: `:139-148,224-237`. Reads normally poll for up to 10 seconds, but stop has no accepted-socket close/join guarantee: `:115-130`.
   - **[G]** Create callbacks/timers: `S/WirelessProbeService.java:158-177`; removal failure: `:197-203`; unverified destruction cleanup: `:230-234`. Reference code separately handles abandoned creates and persistent-profile purging: `O/WifiDirectManager.kt:469-483,3000-3026`; this is not Honda runtime proof.
   - **[H]** No station preservation/ownership check surrounds group creation/removal: `S/WirelessProbeService.java:158-203`. Wireless and AA services declare no separate process: bundled `AndroidManifest.xml:45-46`. Settings starts probes immediately: `S/SettingsActivity.java:98-114`; USB unplug is advertised as emergency stop at `P/VISIT.md:9`.

7. **Assumptions**

   Review concerns this packaged T60 source/APK. Race findings describe possible source-level orderings, not observed vehicle failures.

8. **Unresolved uncertainties**

   **UNKNOWN:** target grep capabilities; Honda HFP/STA coexistence; actual persistent-profile residue; late callback timing; vendor socket behavior; effective Honda indexing after override clearing. E2’s unconditional cleanup/generation/end behavior remains visible at `S/AaSessionService.java:719-768`; its acceptance is supplied by the task.

9. **Exact diff summary**

   None; no files changed.

10. **Preservation checks performed**

   SHA-256 matched frozen M5, disabled M6, both receiver DEX copies and API22 qualifier against `PROJECT-INTEGRITY.json` entries at `:168-170,258-265,2318-2320,2363-2365` and PROJECT-RULES anchors. No credentials/private-test material was opened; no device, milestone, readiness guard or artifact was modified.