**Verdict: NOT READY.** The exported attach receiver and strip-touch teardown need fixes before this bundle’s car test.

1. **Files inspected**

Path abbreviations used below:

- `B` = `analysis/test-prep/todo-tests-20261103/`
- `H` = `B/builds/T100-bundle/source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/`
- `P` = T100’s corresponding `source/com/google/android/projection/protocol/`
- `V` = `B/builds/T100-bundle/source/analysis/parallel-aa-receiver/src/com/google/android/projection/protocol/`
- `AM` = `decompiled/Services/sources/com/android/server/am/`
- `USB` = `decompiled/Services/sources/com/android/server/usb/UsbSettingsManager.java`
- `AA` = `decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/`
- `L` = `analysis/test-prep/runs/helper_20261106T214625_78865cc19bd64bf4993a6daa4a43370a/longdrive-evidence/rdx_f221a028b4e74afd98460af2893b26de/capture.log`

Read PROJECT-RULES.md and AGENTS.md first; T90 review/reconciliation/results; all 11 changed source files against T90; relevant unchanged helper/session/input/boot code; BundleTests, phone-policy and HomeToggle tests; test.json, VISIT.md, saved test/build/package records; supplied stock references, stock VideoSink and CarInfo; cited car-log portions and preservation metadata. Hashed all 35 overlay entries and corresponding saved/working baselines.

2. **Files changed:** none.

3. **Commands run**

Read-only `Get-Content`, `Get-ChildItem`, `rg --files`, `rg -n`, `Resolve-Path`, `Test-Path`, `Get-FileHash`, and `node -e` using filesystem reads, SHA-256 and in-memory source comparisons. Initial baseline/glob lookups were corrected; `python -c` could not start. No Git, network, builds, device commands or credential/private-material reads.

4. **Tests run and results**

No executable suites or compilation run. Saved output reports **123 bundle checks plus eight passing feature suites** (`B/builds/T100-bundle/host-test-output.txt:1-9`).

Static comparison: **35 overlay paths in each bundle; 11 changed, zero added/removed**. T90 and T100 each matched **35/35 candidate**, **35/35 saved-baseline**, and **35/35 working-baseline** hashes.

5. **Findings**

| Item | Status | Finding |
|---|---|---|
| A | **CONFIRMED / OK** | Resolved activity starts are refused through this entry point when AutoSS reports moving and the target lacks permission. “Silent” describes the return; a toast is requested. |
| B | **CONFIRMED / OK** | Broadcast precedes default resolution; permission grant precedes activity start. Requires a matching saved default and an eligible running package. |
| C | **CONFIRMED / OK** | Current now-playing activity intent reaches the motion guard. T80’s claimed bypass was incorrect. |
| D | **REFUTED / SHOULD-FIX** | The two listed manual routes exist, but T100’s Settings watchdog also restores AA. “Only routes” is too absolute. |
| E | **REFUTED / SHOULD-FIX** | The log contains a NATIVE focus request before detach. The missing-request premise is false. |
| F | **CONFIRMED / OK** | The cited re-grab sends DOWN/MOVE/UP over two elapsed milliseconds. |
| 2. AttachReceiver | **BLOCKER** | Unprotected receiver accepts arbitrary actions and caller-supplied USB identity; permission/path checks do not authenticate that identity. |
| 3. AUTO_GRANTED refactor | **SHOULD-FIX** | Inner decision branches are preserved, but new early deduplication changes retry behavior. |
| 4. Focus | **SHOULD-FIX** | Every mode-2 request minimizes, without stock’s reason/visibility restriction; minimizing does not guarantee Honda Home. |
| 5. ScrollStrip/Pacer | **BLOCKER** | Teardown cancels a queued UP; scheduled deadlines do not guarantee actual 16-ms send spacing. |
| 6. Settings watchdog | **SHOULD-FIX** | Slow opening or intervening Home can cause an unwanted restore. |
| 7. USB devices UI | **SHOULD-FIX** | Main-phone identity remains intact, but Allow omits the per-device Honda Disabled/Never prerequisite and silently ignores a full extras list. |
| 8. T103/T104 | **OK** | Steady-state accessibility/window exclusion and long-hold classification remain intact; transition-time delivery is UNKNOWN. |
| 9. Checklist/drive | **SHOULD-FIX** | Sequence agrees with test.json; passenger-only operation is explicit. Add a parked-pass gate before driving and qualify uncertain outcomes. |
| Schema 100 | **OK** | New switches default off; retired switches are removed. Persisted migration is not host-tested. |

6. **Primary evidence for each finding**

**A–C:** `AM/ActivityStackSupervisor.java:646-648` checks the resolved target package and returns `0` on rejection. `AM/AutoSSMonitor.java:41-62` defines moving, checks permission and requests the toast. T100’s manifest has no AUTOMOTIVE_STATE_SERVICE request. `AM/ActivityManagerService.java:12028-12041` starts services without that check.

`USB:604-615,678-695` establishes broadcast → matching default → permission grant → activity start. Defaults match a device filter including VID/PID, manufacturer, product and serial (`USB:86-94`); one saved identity does not establish defaults for another enumeration.

`decompiled/SystemUI/sources/com/android/systemui/statusbar/auto/HondaStatusBar.java:4739-4758` rewraps the non-null intent with `PendingIntent.getActivity`. `H/AaMediaSourceService.java:113-115` documents the current activity route. MediaSourceSelector eventually sends the pending intent (`decompiled/Services/sources/com/honda/auto/mss/MediaSourceSelector.java:719-727`).

**D:** Blue-button restoration uses an overlay click and `updateViewLayout`, not an activity (`H/AaOverlayService.java:835-871`). Side restoration calls `onRestoreRequest` (`:156-161`). The watchdog independently calls `restoreOverlay` (`:186-191`).

**E:** **`L:8586` records `16:54:49.715 … Video focus request=2 reason=0`.** Detach occurs at `L:8993`, followed by write failures (`:9005-9025`). T90’s `AaSessionService.java:803-808` answers focus without minimizing. That explains failure to reveal Honda after a request; the subsequent USB drop’s cause remains **UNKNOWN**.

The facade directly forwards focus callbacks (`V/VideoSink.java:51`); no Java filter hides this request. Stock CarInfo explicitly defaults `displayName` to manufacturer (`AA/integration/CarInfo.java:18-19,34`), rather than omitting the field. T100 changes its value to “Honda Home” (`P/GalReceiver.java:25`).

**F:** `L:3482-3487` shows DOWN at `(1625,360)`, one MOVE to `(1625,324)`, then UP; elapsed timestamps are `397342` and `397344`. This proves the injected sequence, not the phone’s gesture classification.

**2 — Receiver security:** Manifest `:60` exports AttachReceiver without permission. `H/UsbHelperService.java:298-306` never checks the action or resolves the supplied device against UsbManager before starting the service. An explicit unrelated-action broadcast can therefore reach this code with a fabricated allowed serial.

The delayed path checks only path membership and permission, then retains the supplied descriptor (`:235-245`). Stock permission lookup is keyed by device path and UID (`USB:818-829`), not serial. Thus these checks do not establish the claimed identity. At minimum, a forged payload can wake the helper and start polling without a genuine attach (`H/UsbHelperService.java:181-189`). Restrict senders and use the authoritative device before any startup side effects.

**2 — Stopped state, races and boot:** Ordinary broadcasts acquire EXCLUDE_STOPPED (`AM/ActivityManagerService.java:12606-12607`); T102 adds no include-stopped flag. An unconditional “force-stopped app stays out” guarantee across explicit include-stopped spoofing and the stock activity path is **UNKNOWN** from the inspected evidence.

Main-thread serialization plus the AOAP `phase == GRANTED` check and session `sessionActive` check prevent ordinary duplicate AOAP starts (`H/UsbHelperService.java:261-270`; `H/AaSessionService.java:150-168`). Raw switching has no equivalent `aoapSwitchSent` check in `handleAttached` (`H/UsbHelperService.java:271-279`), and polling does not set `attachHandled` (`:397-408`).

The 1.5-second delay does **not** delay polling: polling starts first (`:181-189,235-246`). The logged dongle switches at `16:48:45.440` and reappears at `16:48:46.012` (`L:1573,1595`). The fallback checks whether the old path disappeared; slower removal and duplicate raw-switch scheduling lack tests.

Already-plugged boot recovery requires an attach event or another startup route. PersistentBootService starts the helper only after persistent accessibility setup succeeds (`H/PersistentBootService.java:44-52`); T102 supplies no independent boot scan.

**3:** Compare T90 `UsbHelperService.java:223-258` with T100 `:254-289`: the policy/permission/AOAP/raw branches are retained. However, T100 records `attachHandled` **before** rejection, permission failure or unsuccessful switching (`:255-258`), and suppresses later AUTO_GRANTED for that path (`:225-231`). Exact behavior preservation is therefore false.

**4:** Handler initialization precedes publication; `running` and `nativeFocus` are volatile (`H/AaSessionService.java:62,89-94,119`). Posted focus handling rechecks running and sink availability (`:805-817`); no normal initialized-running handler-null path was found.

Stock minimizes only for NATIVE **while visible and reason 0** (`AA/ui/ProjectionActivity.java:2121-2126`). T100 ignores reason and startup state, minimizing every mode 2. Repeats are visually idempotent through `HomeToggle.onHome` (`H/HomeToggle.java:18-22`); mode 3 is answered and marks nativeFocus without minimizing (`H/AaSessionService.java:812-816`).

Restoration requests projected video when nativeFocus is set (`:821-824`; `H/AaOverlayService.java:849`). The posted restore callback does not revalidate focus state; it clears the flag before success is established. Already-selected sessions receive no retry through `doRequestVideo` (`H/AaSessionService.java:729-743`). Recovery is **UNKNOWN** live.

`onObservedExit` only hides the overlay (`H/AaOverlayService.java:207-215,821-832`), revealing the underlying screen. It does not perform stock’s Home navigation.

**5:** Geometry, gain, edge clamp and minimum release displacement are implemented (`H/ScrollStrip.java:18-20,78-97`). However, `releaseAbsoluteTouch` queues strip release (`H/AaOverlayService.java:959-960`), then teardown immediately removes **all** handler callbacks (`:997-1020`). A recently sent DOWN can lose its queued MOVE/UP.

Minimize leaves queued sends active; their callback checks only `touchListener`, not minimized/session generation (`:253-264,821-831`). Pacer assigns deadlines without limiting backlog or measuring actual sends (`H/ScrollStrip.java:105-111`): overdue callbacks can bunch after handler delay, and ordinary touchscreen events bypass this queue.

`BundleTests.java:61-83` covers generated actions and delay arithmetic, not handler stalls, teardown cancellation, interleaving or phone tap recognition. “Never a tap” remains **UNKNOWN**.

**6:** The watchdog uses a two-second deadline and last-resume timestamp (`H/AaOverlayService.java:180-204`; `H/SettingsActivity.java:151-154`). A launch taking longer than two seconds is indistinguishable from refusal. Home updates minimized state but does not cancel the watchdog (`H/HomeToggle.java:18-22`), so Home during the wait can still be followed by automatic AA restoration.

**7:** UI actions modify extras only (`H/SettingsActivity.java:158-185`; `H/UsbHelperService.java:167-177`). Main-phone configuration remains separate. Serial validation, empty-list handling and four-extra cap remain (`H/HondaPhonePolicy.java:21-22,59-80`); recent writes cap at five and sanitize separators (`:31-55`). UI shows “None yet” when empty.

The required per-extra Honda Disabled/Never condition is documented in `HondaPhonePolicy.java:5-6`, but absent from the new UI explanation (`SettingsActivity.java:85`). A fifth Allow silently leaves extras unchanged (`HondaPhonePolicy.java:73`). Recent-list growth is bounded through its writer; `parseRecent` alone does not cap arbitrary input.

**8:** Window handling is disabled while `keysObserved` is true (`H/AaOverlayService.java:369-374`). Accessibility sets/clears that volatile flag (`H/PermissionClickService.java:302,327-344`), observes short/long releases and returns false (`:309-318`). Long classification remains 1.5 seconds held alone (`H/HomeToggle.java:39-58`). Lifecycle transitions and Honda/assistant coexistence are not exercised by the host tests.

**9 / migration:** VISIT’s Start/skip-GRANT/Collect sequence agrees with `test.json:64-78`. Drive instructions explicitly require a passenger (`B/VISIT.md:52-60`), and unplug is the emergency stop (`:17`). They do not explicitly stop progression after a failed parked restore/start check. “Honda Home” and “Settings is blocked” outcomes need the qualifications above.

`H/AppSettings.java:38,54-60` resets options on, tests off and removes retired keys. BundleTests checks defaults, not persisted migration (`:16-23`).

7. **Assumptions**

Omitted overlay paths use the shared baseline. Saved test/build reports are historical records. Security and scheduling counterexamples are static deductions, not device reproductions.

8. **Unresolved uncertainties**

Force-stop guarantees across all launch paths; cold-boot event ordering; focus recovery; actual tap classification; accessibility lifecycle transitions; Honda voice coexistence; and the USB detach’s cause remain **UNKNOWN**.

9. **Exact diff summary:** none; no files changed.

10. **Preservation checks performed**

All frozen anchors matched PROJECT-RULES/PROJECT-INTEGRITY: M5 `A22E9649…EE8F40`, M6 `D4DAC2DD…B28761F`, both receiver DEX copies `2FDBC63F…FE7C235`, TLS qualifier `86350131…999FC1F`.

Readiness wrapper, core and schema hashes all matched PROJECT-INTEGRITY. T100 APK matched **`DAE86800A7A3FFDE5352D0835FFE5C7353DBEDE3D53AB2994ADD7FD7F1C67ACD`**. No guard bypass, artifact modification, milestone action, build, Git/network/device operation or private-material read was performed.