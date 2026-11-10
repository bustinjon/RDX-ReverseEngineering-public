**Verdict: NOT READY FOR CAR TEST.**

1. **Files inspected:** `PROJECT-RULES.md`, `AGENTS.md`, supplied background review and T160 result; six changed Java files in both bundles; helper manifest and relevant overlay code; Diagnostics menu, manifest, strings, layouts, menu/dealer/USB activities and dialog code; Honda HFP and framework socket excerpts.
   Paths below: `J` = `analysis/test-prep/todo-tests-20261103/builds/T170-bundle/source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper`; `D` = `decompiled/HondaDiagnostics`; `W/P/S/A/I` = `J/{WirelessProbeService,PermissionClickService,SettingsActivity,AaSessionService,InputEvents}.java`.

2. **Files changed:** none.

3. **Commands run:** read-only `Get-Content`, `rg`, `Get-ChildItem`, `Compare-Object`, `Get-FileHash`, output filtering and layout arithmetic. Content comparison identified six changed Java files against T160; no Git or network used.

4. **Tests run and results:** static review only; no builds or executable/device tests. Layout arithmetic: 17 items → nine rows → 51px minimum button height and 20px text at 720px. Initial arithmetic attempt hit PowerShell restrictions; corrected calculation succeeded.

5. **Findings**, with primary evidence:
   - **OK — Wi-Fi startup/refusal:** disabled station Wi-Fi and asynchronous `createGroup` refusal call shutdown and retain explanatory status. Evidence: `W:196–200,227–232`. Switching Wi-Fi off during an existing run has no corresponding watcher.
   - **BLOCKER — Hidden Developer menu:** scrolling cannot expose Developer Diagnostics: its configuration is `visible="false"`, invisible entries are removed, and entry uses a five-second key hold. T170 implements only text clicks/scrolling. Evidence: `D/resources/res/xml/diag_menus.xml:251–253`; `D/sources/com/honda/auto/diagnostics/MenuActivity.java:249–282,289–311`; `P:113–118`.
   - **BLOCKER — Wrong “Apple CarPlay” node:** Functional Setup contains an unrelated exact-label item opening `AppEnabledSelectorActivity`. On that screen, Android Auto swap can falsely finish; ADB swap can enter that unrelated activity. Require the USB-mode screen/control identity and dialog-row identity. Evidence: `D/resources/res/xml/diag_menus.xml:183–198`; `D/resources/res/values/strings.xml:397`; `P:94–106,122–127`.
   - **SHOULD-FIX — Stalled swap/retries:** a matching nonclickable title causes an unconditional return before scrolling; failed selection still sets `swapDialogClicked`, causing WAIT thereafter. Scrolling is bounded at 12 attempts and the operation at 30 seconds, so it is not infinite. Evidence: `P:85–87,98–100,113–118`; `I:83–87`; Diagnostics `MenuActivity.java:213`.
   - **BLOCKER — Diagnostics lock-task exit:** dealer entry calls `startLockTask`; its `finish()` stops it, while Home and Back are intercepted. T170 finishes with “go back to Home” and performs no exit. Provide a verified exit/recovery flow. Evidence: Diagnostics `dealer/MainActivity.java:44–47,80–83,119–127`; `P:105–106`.
   - **SHOULD-FIX — Helper off/open failure:** absent accessibility falls back to opening Diagnostics, but instructions remain on the obscured Settings page. Launch failure also leaves the queued swap request alive. Evidence: `P:56–60`; `S:289–301`.
   - **BLOCKER — Connected-phone switch:** no phone-presence check precedes selecting “Apple CarPlay”; Diagnostics immediately writes `dev.adb`. Combined with lock-task, the resulting attach/permission behavior is **UNKNOWN**. Require an unplugged-phone precondition. Evidence: `S:289–296`; `P:98–100`; Diagnostics `developer/USBModeSwitchActivity.java:46–50`.
   - **BLOCKER — Honda HFP/call safety:** AudioManager is checked once; existing/connecting/unknown Honda HFP never blocks the nudge—`linkUp` is merely logged. A call can start afterward. Honda owns a separate Broadcom HFP connection; interference from the second connection is **UNKNOWN**. Keep listener/SDP variants; omit nudge under the strict call-preservation requirement. Evidence: `W:118–145`; `decompiled/HondaSettings/sources/com/honda/settings/btservice/proxyhandlers/BluetoothHFPProfile.java:54–65,130–137`.
   - **BLOCKER — Stop/deadline race:** the worker-local nudge socket is absent from shutdown cleanup. Shutdown removes its three-second close callback; a worker can also start/connect after shutdown because it never rechecks cancellation. Track and close this socket, with an independently reliable deadline. Evidence: `W:138–149,496–509`.
   - **BLOCKER — Stale peer:** `phoneAddress` persists across sessions; the UUID receiver captures its first address. A later session without a pairing request can nudge the previous phone, while later SDP results can be ignored. Evidence: `A:841`; `W:81,88–102,133–145,496–514`.
   - **SHOULD-FIX — Session/variant consistency:** every shutdown, including operator stop/errors, signals “session ended.” Replug does not cancel the pending nudge; variant selection is reread after listener creation, permitting an insecure listener plus nudge. Bind peer, variant and delayed work to one session generation. Evidence: `A:415–417,1153–1156`; `W:177–183,206,304–306`.
   - **OK — Scoped actions/privacy:** swap steps reject non-Diagnostics active roots; exact visible text prevents substring matches. SDP registration/unregistration is ordinarily paired, and inspected new logs contain no peer addresses/names. Evidence: `P:92–93,122–127`; `W:93–105,137–149,509`. These checks do not solve the wrong-node issue.
   - **SHOULD-FIX — Developer fit:** 17 controls include Back. Heights are minimums, columns wrap content, and expanding status labels can enlarge buttons; rendered fit is **UNKNOWN**. Evidence: `S:237–272,324–340,358–362`.

6. **Primary evidence for each finding:** source locations accompany every finding above; background prose was not treated as proof.

7. **Assumptions:** supplied decompilation represents the target firmware; call preservation remains the background review’s hard constraint.

8. **Unresolved uncertainties:** live accessibility trees, rendered Settings fit, USB reattachment under lock-task, HSP/HFP channel interaction and actual call impact remain **UNKNOWN**.

9. **Exact diff summary:** none authored; T170/T160 differences were reviewed only.

10. **Preservation checks performed:** repeated SHA-256 inventory comparison returned `true` for all 32 T170 helper source/resource files. No writes, builds, Git, network, devices, credentials/private-test material or milestone actions; frozen artifacts were not rehashed.