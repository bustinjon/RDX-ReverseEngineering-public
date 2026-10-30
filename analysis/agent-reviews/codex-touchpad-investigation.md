**Honda AA restarts, but the proposed persistent click hijack is unproven.** The code shows a different click path than the hypothesis assumes, and saved logs show Honda cleaning up while our overlay continues receiving DOWN/UP events.

1. **Files inspected**

   Read `PROJECT-RULES.md` and `AGENTS.md` first, then all seven task-listed Java files. Additional inspection covered Honda’s `ITouchbridge`, Settings touch-sensitivity code, protocol input/video classes, PackageManager and USB framework code, our overlay/session/input source, saved session logs, captured permissions/SELinux context files, and preservation manifests. Primary paths are linked below.

2. **Files changed**

   None.

3. **Commands run**

   Read-only commands: `Get-Content`, numbered source excerpts, `Get-ChildItem`, `rg --files`, `rg -n`, `Select-String`, `Get-Command`, `Get-FileHash`, `git status --short`, and `git diff --stat`. Also consulted Android 5.1.1 AOSP source for `pm` and property-service behavior.

   Two searches needed PowerShell syntax corrections; one hash-output formatting attempt failed under constrained language mode and was rerun successfully.

   No device commands, builds, package-state changes, property writes, or Binder calls were executed.

4. **Tests run and results**

   - Static source/log cross-checks completed.
   - Captured shell permission check: `CHANGE_COMPONENT_ENABLED_STATE count=0`; `FORCE_STOP_PACKAGES count=1`.
   - All four frozen-artifact SHA-256 checks matched their anchors.
   - No runtime or hardware tests performed.

5. **Findings**

   | ID | Classification | Finding |
   |---|---|---|
   | F1 | **CONFIRMED / UNKNOWN** | The inspected Java interface exposes no Android-output or output-mode setter. The native callers and routing-mode meanings remain **UNKNOWN**. |
   | F2 | **CONFIRMED** | Honda handles physical clicks as DPAD_CENTER key events; hover movement goes through `sendTouchPadEvent()`. |
   | F3 | **CONFIRMED** | `mInputType=2` selects touchpad view listeners. `mVideoFocusState` manages video/protocol focus; no Java evidence establishes it as a touchbridge routing switch. |
   | F4 | **SUPPORTED** | Honda’s restart creates contention, but its view continuously swallowing clicks cannot by itself explain the reported lasting failure: saved captures reach cleanup and `onDestroy()`. |
   | F5 | **CONFIRMED / SUPPORTED** | Our input implementation differs from Honda’s click handling. This could explain selection failure inside AA; it does not establish the cause of persistent native-UI failure. |
   | F6 | **CONFIRMED / SUPPORTED** | Both proposed component `disable-user` commands have a state-selection problem on this framework. Captured shell permissions additionally predict permission denial. |
   | F7 | **UNKNOWN / SPECULATIVE** | A native/HMI state left behind remains possible, but neither a working reset API nor a controlling property is established. |

6. **Primary evidence for each finding**

   **F1 — Touchbridge mechanism**

   The complete interface method list contains diagnostics, backlight, heartbeat/status, flashing, and `switchToMaster/Normal1/Normal2`; it contains no `enableAndroidOutput` or `setOutputMode` method. Transactions 1/2/3 map to those three switch methods. See [ITouchbridge.java:10](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/honda/touchbridge/ITouchbridge.java:10) and [transaction mapping:49](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/honda/touchbridge/ITouchbridge.java:49).

   Crucially, Honda Settings uses `switchToNormal1()` for **LOW glove sensitivity** and `switchToNormal2()` for **HIGH glove sensitivity**. They are not established AA/native routing controls. See [TouchSensitivityActivity.java:48](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/HondaSettings/sources/com/honda/settings/system/touch_sensitivity/TouchSensitivityActivity.java:48) and [line 73](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/HondaSettings/sources/com/honda/settings/system/touch_sensitivity/TouchSensitivityActivity.java:73).

   `TouchpadProxy` obtains the Binder, registers a heartbeat callback, and queries availability; it supplies no routing mechanism. See [TouchpadProxy.java:143](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/current-update-stack/com.honda.auto.diagnostics.service/sources/com/honda/auto/diagnostics/service/proxy/TouchpadProxy.java:143).

   The boot evidence associates Android-output enablement with **power state**: `OpeningAnimation => FullMode`, touchpad `0 => 1`, then Android output `0 => 1`. Thus the quoted boot disable is not evidence of an AA takeover. See [saved boot log:9782](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/m4-single-port-20261023-170305-676/20261023-170422-060-before-logcat.stdout.txt:9782), with the earlier disable at [line 56](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/m4-single-port-20261023-170305-676/20261023-170422-060-before-logcat.stdout.txt:56). This establishes sequence, not native causality.

   Native implementation was unavailable: the saved listing records permission denial for `/system/bin/touchbridge` and identifies `tbc` as its symlink. See [system-bin-listing.txt:399](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/adb/RDX-Audit/logs/system-bin-listing.txt:399) and [line 373](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/adb/RDX-Audit/logs/system-bin-listing.txt:373). **The callers of both native functions and the meaning of output mode `1` remain UNKNOWN.**

   **F2 — Click versus direction**

   Honda’s touchpad click listener consumes ACTION_DOWN/UP and dispatches predefined DPAD_CENTER down/up events. Key code 23 is sent through `input.sendKeyEvent()`. See [ProjectionActivity.java:559](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/ui/ProjectionActivity.java:559), [key definitions:161](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/ui/ProjectionActivity.java:161), and [key handling:2267](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/ui/ProjectionActivity.java:2267).

   Hover actions 7/9/10 are converted to motion actions 2/0/1 and sent through `sendTouchPadEvent()`; the hover listener also returns `true`. Therefore the code does **not** show hover directions bypassing Honda’s AA pipeline while clicks alone enter it. See [ProjectionActivity.java:574](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/ui/ProjectionActivity.java:574).

   The 200 ms suppression logic belongs to `mSurfaceTouchListener`. Touchpad type 2 installs `mPadTouchListener` instead. The property therefore is not an established remedy for this click failure. See [surface listener:503](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/ui/ProjectionActivity.java:503), [property read:1334](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/ui/ProjectionActivity.java:1334), and [listener selection:2220](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/ui/ProjectionActivity.java:2220).

   Policy’s `VirtualPointer` updates pointer visibility/coordinates and drawing; it supplies no click-routing restoration. See [VirtualPointer.java:61](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Policy/sources/com/honda/touchpad/VirtualPointer.java:61).

   **F3 — Lifecycle and focus**

   `HMIPresenter.getInputDeviceType()` returns `2`; dimensions are 1325×720 and 60×40 mm. These configure input representation rather than prove a hardware-mode change. See [HMIPresenter.java:717](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/presentation/HMIPresenter.java:717) and [GalIntegration.java:120](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/integration/GalIntegration.java:120).

   `onResume()` updates foreground/visibility and may resume video. `onPause()` updates those flags and may request native video focus. `onDestroy()` calls cleanup. Cleanup sets the local focus state to native, stops GAL, releases resources, and ultimately nulls `mGal`. See [ProjectionActivity.java:1485](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/ui/ProjectionActivity.java:1485), [onDestroy:1801](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/ui/ProjectionActivity.java:1801), [cleanup:1836](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/ui/ProjectionActivity.java:1836), and [GAL destruction:1966](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/ui/ProjectionActivity.java:1966).

   The “restore to native mode” runnable calls `requestVideoFocus(VIDEO_FOCUS_NATIVE)`. That path invokes `display.setVideoFocus()` and stops the renderer; it is not a demonstrated touchbridge reset. See [runnable:413](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/ui/ProjectionActivity.java:413), [focus request:1564](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/ui/ProjectionActivity.java:1564), and [VideoSink.java:174](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/google/android/projection/protocol/VideoSink.java:174).

   No global touch-consumer registration was found in these classes. The demonstrated touch registrations are view listeners. Hardware-button broadcasts register/unregister in `onStart/onStop`. See [ProjectionActivity.java:1631](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/ui/ProjectionActivity.java:1631).

   **F4 — Counterexamples to the persistent hijack hypothesis**

   Restart is confirmed: `StartReceiver` starts `GalService` on attachment, and the service explicitly launches `ProjectionActivity`. See [StartReceiver.java:19](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/receiver/StartReceiver.java:19) and [GalService.java:938](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/service/GalService.java:938).

   In v6e, Honda logs cleanup and later `onDestroy()`, while our overlay subsequently records DOWN/UP. See [cleanup:6027](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/logs/car-test-20261028-v6e.txt:6027), [onDestroy:7473](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/logs/car-test-20261028-v6e.txt:7473), [DOWN:8289](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/logs/car-test-20261028-v6e.txt:8289), and [UP:8323](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/logs/car-test-20261028-v6e.txt:8323).

   V6f also contradicts “Honda never obtains a functioning protocol path”: it reaches codec setup/config and projected video focus before disconnecting and being destroyed. See [codec setup:5024](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/logs/car-test-20261028-v6f.txt:5024), [projected focus:7838](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/logs/car-test-20261028-v6f.txt:7838), and [onDestroy:9816](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/logs/car-test-20261028-v6f.txt:9816).

   **F5 — Our input path**

   Our session forwards DOWN/UP/MOVE as touchpad motion reports. Its touchpad registration sets `tapAsSelect=false`; the inspected path does not reproduce Honda’s DPAD_CENTER click conversion or key registration. See [AaSessionService.java:191](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/AaSessionService.java:191), [registration:295](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/AaSessionService.java:295), [InputSource.java:59](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/src/com/google/android/projection/protocol/InputSource.java:59), and [Honda key registration:165](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/integration/AbstractGalIntegration.java:165).

   Our fullscreen overlay consumes touch events unconditionally. A surviving overlay is therefore a plausible click consumer, but v6e records its removal/destruction, so persistence is not established there. See [AaOverlayService.java:190](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/AaOverlayService.java:190), [return true:275](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/AaOverlayService.java:275), and [removal log:11021](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/logs/car-test-20261028-v6e.txt:11021).

   **F6/F7 — Prevention options and permissions**

   | Option | Assessment |
   |---|---|
   | Disable `StartReceiver` | Would block that manifest entry, if successfully disabled. It would not eliminate an already-running service’s dynamically registered USB receiver. [GalService.java:1166](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/service/GalService.java:1166) |
   | Disable `ProjectionActivity` | Would block that activity entry, if successfully disabled. The service’s direct launch has no local exception handler. [GalService.java:960](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/service/GalService.java:960) |
   | Use `disable-user` on either component | **Wrong component state for this implementation.** State 3 is `DISABLED_USER`, but the component branch accepts only 0/1/2; `disable` corresponds to state 2. [PackageManager.java:26](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Framework/sources/android/content/pm/PackageManager.java:26), [PackageManagerService.java:10175](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/pm/PackageManagerService.java:10175), [AOSP pm dispatch](https://raw.githubusercontent.com/aosp-mirror/platform_frameworks_base/android-5.1.1_r1/cmds/pm/src/com/android/commands/pm/Pm.java) |
   | Shell uid 2000 changes component state | Captured evidence predicts **permission denial**: PackageManager requires the permission or same-app identity, and shell’s captured grant list lacks it. Current live permission state is **UNKNOWN**. [permission check:10140](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/pm/PackageManagerService.java:10140), [shell grants:14385](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/adb/RDX-Audit/logs/dumpsys-package-full.txt:14385) |
   | `service call touchbridge` | Shell access and native server permission enforcement are **UNKNOWN**. The Java transaction numbers do not establish native authorization or a routing-reset operation. |
   | Set `persist.aa.*` | No inspected property is a demonstrated routing switch. Captured property contexts give these names the default context; Android 5.1.1 checks SELinux permission to set properties. Target shell authorization remains **UNKNOWN**. [property_contexts:47](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/adb/RDX-Audit/security/property_contexts:47), [AOSP property_service.c, lines 90–143](https://raw.githubusercontent.com/aosp-mirror/platform_system_core/android-5.1.1_r1/init/property_service.c) |
   | Send a `restoreNativeMode` equivalent | The demonstrated equivalent restores **video focus**. Its ability to repair touchbridge click delivery is **UNKNOWN**; see F3. |

7. **Assumptions**

   Decompiled code is treated as evidence of the inspected implementation. Exact parity with every deployed test APK is **UNKNOWN**, especially for currently modified/untracked receiver source. The reported 2/2 failure and reboot recovery are supplied observations; the inspected logs do not independently establish their precise timing.

8. **Unresolved uncertainties**

   - Native mode values, callers, Binder checks, and hardware press-to-Android mapping.
   - Which window and process received clicks during the persistent failure.
   - Whether press reports disappeared, became keys, or reached a consumer that ignored them.
   - Why native UI remained affected after both Honda and overlay teardown.
   - A verified touchbridge restoration operation.

   A persistent native/HMI latch is **SPECULATIVE**. The available evidence does not identify a confirmed root cause or reboot-free recovery.

9. **Exact diff summary**

   None attributable to this review. Initial and final `git status --short` showed the same pre-existing modified/untracked file set.

10. **Preservation checks performed**

   `Get-FileHash -Algorithm SHA256` matched all four `PROJECT-RULES.md` anchors:

   - Frozen M5 APK: `A22E96490B9557AFF022893A8B8B7A08BB13CEC236E52704CDDAFA90A8EE8F40`
   - Disabled M6 APK: `D4DAC2DD8B2AFF1FA7B64BFB32D2A5E889854CCEB4B4A9F7AD5AEF89FB28761F`
   - Receiver DEX: `2FDBC63F2F9D63B764697D311AF89D460AE6B8E14B0FADABA9C9339F7FE7C235`
   - API22 TLS qualifier: `86350131FFC5CBE5766E523AB03AE07D4C9F5EAD78F0570B68255C9A3999FC1F`

   No artifacts rebuilt, key material opened, device touched, or milestone advanced.