1. **Files inspected**

Read `PROJECT-RULES.md` and `AGENTS.md` first. Inspected the requested SystemUI USB activities, manifest and resources; framework USB, activity, window and input code; Services USB managers, activity supervisor, AutoSS and WindowManager code; AppFixup; Honda USB manager interfaces/constants; AndroidAuto-current service, projection and USB transport code; M5 source and retry evidence; and both specified prior reviews.

Also inspected `decompiled/Policy/` because it contains Honda’s window layering, Home handling and touchpad pointer implementation.

Source citations below use tool-counted lines. Retry-log citations use PowerShell `Select-String` numbering, consistent with the earlier review; `rg` reports different numbers for that log’s unusual carriage returns.

2. **Files changed**

None.

3. **Commands run**

Read-only commands: `Get-Content`, `rg --files`, `rg -n`, `rg -l`, `Get-ChildItem`, `Select-String`, `Get-FileHash -Algorithm SHA256`, `git status --short`, and scoped `git diff --stat`.

Decisive bounded searches returned:

[Code block omitted from public report; see authored source where available.]

The logger search was:

[Code block omitted from public report; see authored source where available.]

No project scripts, device commands or applications were executed.

4. **Tests run and results**

No runtime tests or executable test suites were run. This was static analysis.

Preservation hashes matched all four anchors, including both listed receiver DEX copies. Initial and final Git status matched; scoped diff output was empty.

5. **Findings**

**Overall — SUPPORTED:** The saved implementation contains a complete ordinary USB permission dialog and grant path. I found no unconditional Honda ban that makes it impossible after lock-task is off.

**Overall — UNKNOWN:** Whether the dialog will actually become visible, accept the head unit’s physical input, and produce an accepted M5 grant on live build **14**. Saved SystemUI identifies itself as **5.1.1-168**, whereas the saved live fingerprint reports **14**. That parity gap matters especially for dialog resources, input adaptations, manifest permissions and window behavior. [Saved manifest:5](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/SystemUI/resources/AndroidManifest.xml:5), [live fingerprint:1](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/m5-live-retry-20261025-185128/20261025-185359-402-verified-fingerprint.stdout.txt:1).

**Q1. Request path — CONFIRMED in inspected code**

The chain is:

- M5 prepares its receiver/PendingIntent, then calls `manager.requestPermission(device, pending)`. [PermissionService.java:75](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/m5-permission/source/com/rdx/fullscreen/m5permission/PermissionService.java:75)
- `UsbManager` passes the device, calling package and PendingIntent to `requestDevicePermission`. [UsbManager.java:114](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Framework/sources/android/hardware/usb/UsbManager.java:114)
- `UsbService` selects settings for the calling user. [UsbService.java:173](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/usb/UsbService.java:173)
- `UsbSettingsManager` either returns an existing grant or launches explicit SystemUI `UsbPermissionActivity`, with `NEW_TASK`, device, package, UID and PendingIntent. [UsbSettingsManager.java:866](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/usb/UsbSettingsManager.java:866)

**CONFIRMED:** The explicit request does not consult the default-package resolver, an application whitelist, device-owner policy or `no_usb_file_transfer`. It checks existing permission and, when launching UI, verifies that the package exists and belongs to the calling UID. The file-transfer restriction occurs in gadget-function configuration, separately. [UsbSettingsManager.java:891](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/usb/UsbSettingsManager.java:891), [UsbService.java:205](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/usb/UsbService.java:205).

**CONFIRMED:** Existing permission, UID 1000, or `config_disableUsbPermissionDialogs` produces a **true** permission shortcut, not automatic denial. Default-package logic can grant and launch stock software on attachment, but does not exclude another UID from requesting permission. [UsbSettingsManager.java:818](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/usb/UsbSettingsManager.java:818), [attachment resolver:645](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/usb/UsbSettingsManager.java:645).

**CONFIRMED counterexample to “AppFixup is the only veto”:** `ActivityStackSupervisor.startActivityMayWait()` additionally calls Honda `AutoSSMonitor` and silently returns `0` when it refuses the destination package. AutoSS refuses packages lacking `auto.permission.AUTOMOTIVE_STATE_SERVICE` while its state is `CAR_MOVING`. [ActivityStackSupervisor.java:647](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/am/ActivityStackSupervisor.java:647), [AutoSSMonitor.java:55](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/am/AutoSSMonitor.java:55).

**SUPPORTED:** AutoSS should allow this saved SystemUI when its requested automotive permission is granted: the manifest requests it. The request alone does not establish the live package’s effective grant. [Manifest:87](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/SystemUI/resources/AndroidManifest.xml:87).

**CONFIRMED:** The known AppFixup veto is restricted to non-exempt audio applications during an audio interrupt. Audio classification requires a `MediaBrowserService`; the inspected SystemUI manifest contains none. [AppFixup supervisor:33](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AppFixup/sources/com/honda/appfixup/am/ActivityStackSupervisor.java:33), [AudioApp.java:25](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AppFixup/sources/com/honda/appfixup/AudioApp.java:25).

**CONFIRMED:** Other generic start vetoes remain: IntentFirewall and an installed activity controller can abort with return `0`; app-switch restrictions can defer launch. Their live configuration is **UNKNOWN**. [ActivityStackSupervisor.java:1045](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/am/ActivityStackSupervisor.java:1045).

**CONFIRMED distinction:** There is no pre-dialog branch here that sends `permission=false`. There are paths that return without UI **and without any callback**: refused activity start, missing activity, canceled PendingIntent, or swallowed/logged Binder failure. Therefore `REQUEST_API_RETURNED` cannot establish that a dialog appeared. [UsbSettingsManager.java:879](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/usb/UsbSettingsManager.java:879), [UsbManager.java:114](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Framework/sources/android/hardware/usb/UsbManager.java:114).

**Q2. Dialog behavior — CONFIRMED / SUPPORTED / UNKNOWN**

**CONFIRMED:** It uses `Theme.SystemUI.Dialog.Alert`, inheriting `Theme.DeviceDefault.Light.Dialog.Alert`, and standard positive/negative buttons. The saved text asks whether to allow access. [Manifest:199](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/SystemUI/resources/AndroidManifest.xml:199), [styles.xml:180](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/SystemUI/resources/res/values/styles.xml:180), [UsbPermissionActivity.java:59](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/SystemUI/sources/com/android/systemui/usb/UsbPermissionActivity.java:59).

**CONFIRMED:** It has no activity-specific `setType`, window-flag override, focus-loss dismissal, screen-off receiver or timeout. The normal activity window is assigned **type 1, `TYPE_BASE_APPLICATION`**. It receives no special system-dialog layer merely because SystemUI hosts it. [ActivityThread.java:2749](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Framework/sources/android/app/ActivityThread.java:2749).

**UNKNOWN:** Exact resolved flags, dimensions and layout on live build 14. The activity does not request non-focusable/non-touchable behavior, but the complete live inherited resource configuration was not established.

**SUPPORTED:** Display 0 is the expected route: no explicit alternative display is requested, and the actual rejected request logged `on display 0`. That log proves routing of the launch attempt, not successful rendering. [Retry log:61389](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/m5-live-retry-20261025-185128/reconnect-logcat.txt:61389).

**SUPPORTED:** Standard touch clicks and focused confirmation keys can answer its controls. AlertController installs ordinary button click listeners; `View` handles touch and confirmation-key clicks. [AlertController.java:568](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Framework/sources/com/android/internal/app/AlertController.java:568), [View.java:3890](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Framework/sources/android/view/View.java:3890).

**UNKNOWN, with a concrete touchpad concern:** SystemUI declares `HOVER_AWARE=true`, which disables Honda Policy’s fallback pointer. `UsbDebuggingActivity` explicitly adds `UsbDialogPointer`; `UsbPermissionActivity` does not. This establishes missing pointer assistance, **not** inability to click. Physical touchpad click translation and rotary navigation remain unproven. [Manifest:109](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/SystemUI/resources/AndroidManifest.xml:109), [VirtualPointer.java:37](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Policy/sources/com/honda/touchpad/VirtualPointer.java:37), [UsbDebuggingActivity.java:56](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/SystemUI/sources/com/android/systemui/usb/UsbDebuggingActivity.java:56).

**CONFIRMED:** Honda overlays can cover this ordinary activity. Policy assigns application windows layer 2, while status panels, screen-off, collision and rear-camera windows occupy higher layers. Screen-off explicitly uses type 2038. [PhoneWindowManager.java:1644](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Policy/sources/com/android/internal/policy/impl/PhoneWindowManager.java:1644), [ScreenOffDialog.java:44](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Policy/sources/com/honda/auto/policy/popup/ScreenOffDialog.java:44).

**CONFIRMED:** `minimized=true` initially moves projection’s task backward, but does not promise that it stays there. A later projected-video-focus request can start ProjectionActivity again; a separate first-run video timer can also request a non-minimized launch. Conversely, projection’s `onPause()` requests native video focus. [ProjectionActivity.java:1403](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/ui/ProjectionActivity.java:1403), [video-focus handling:2129](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/ui/ProjectionActivity.java:2129), [GalService.java:914](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/service/GalService.java:914).

**Q3. Dismissal — CONFIRMED, with important distinctions**

| Cause | Result supported by source |
|---|---|
| Negative button | Finishes with permission false. |
| Back | Inherited activity handling finishes it. |
| Matching USB detach | `UsbDisconnectedReceiver` finishes it. |
| ActivityManager `closeSystemDialogs()` | Manifest flag causes `finishActivityLocked(..., "close-sys", ...)`. |
| Configuration recreation | Old instance runs `onDestroy()` and can send false before replacement appears. |
| Ordinary pause, focus loss or screen off | No direct finish handler in this activity; it can instead remain hidden. |
| Task removal/other graceful destruction | Its result logic runs if `onDestroy()` executes. Abrupt process death does not provide a reliable callback guarantee. |

Evidence: [UsbPermissionActivity.java:85](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/SystemUI/sources/com/android/systemui/usb/UsbPermissionActivity.java:85), [click handling:123](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/SystemUI/sources/com/android/systemui/usb/UsbPermissionActivity.java:123), [UsbDisconnectedReceiver.java:35](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/SystemUI/sources/com/android/systemui/usb/UsbDisconnectedReceiver.java:35), [Activity.java:835](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Framework/sources/android/app/Activity.java:835), [ActivityStack.java:2437](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/am/ActivityStack.java:2437), [configuration relaunch:2357](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/am/ActivityStack.java:2357), [ActivityThread.java:3438](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Framework/sources/android/app/ActivityThread.java:3438).

**CONFIRMED:** Home is a real dismissal route after unlock. Policy’s Home handling calls the ActivityManager API before launching Home. [PhoneWindowManager.java:2949](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Policy/sources/com/android/internal/policy/impl/PhoneWindowManager.java:2949), [ActivityManagerService.java:4018](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/am/ActivityManagerService.java:4018).

**CONFIRMED distinction:** ProjectionActivity’s `sendBroadcastAsUser(CLOSE_SYSTEM_DIALOGS)` is **not** the ActivityManager API. The inspected HondaStatusBar receiver collapses panels and dismisses its seat dialog; it does not finish USB permission activities. Projection’s broadcast alone is therefore insufficient evidence of USB-dialog dismissal. Its subsequent foreground launch can still cover the dialog. [ProjectionActivity.java:2154](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/ui/ProjectionActivity.java:2154), [HondaStatusBar.java:1215](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/SystemUI/sources/com/android/systemui/statusbar/auto/HondaStatusBar.java:1215).

**CONFIRMED:** Honda constants identify `5=TYPE_UNSUPPORTED`, `7=TYPE_ANDROID_AUTO`. The retry transition follows `AndroidAuto onIconItemChanged false` and `Checking attached device`. [UsbMediaDefines.java:13](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/HondaManager/sources/com/honda/usbmediamanager/UsbMediaDefines.java:13), [retry log:66231](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/m5-live-retry-20261025-185128/reconnect-logcat.txt:66231).

**SUPPORTED:** That particular `5 → 7` is classification, not demonstrated re-enumeration: zero additional add/detach records occur between `/003/005` being added and the transition.

**UNKNOWN:** The exact logger implementation and whether it has additional permission side effects. Its process is `com.honda.usbmediaservice`, but its service implementation is absent from the inspected decompilations; the complete Java search returned zero matches. Client interfaces cannot establish its internals. [Saved process list:243](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/m5-live-retry-20261025-185128/20261025-185431-404-baseline-processes.stdout.txt:243).

**Q4. Grant semantics — CONFIRMED, with a narrow race**

**CONFIRMED:** Positive click sets `mPermissionGranted=true`; actual grant occurs in `onDestroy()`, before the PendingIntent send. The grant is an entry for **device path → UID**, within user-specific settings. It is not exclusive ownership of an interface. [UsbPermissionActivity.java:90](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/SystemUI/sources/com/android/systemui/usb/UsbPermissionActivity.java:90), [UsbSettingsManager.java:967](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/usb/UsbSettingsManager.java:967).

**CONFIRMED:** Host removal removes the device and clears its path’s permission map, then broadcasts detach. Re-enumeration consequently needs a grant for the resulting attachment; persisted defaults may automatically supply one to their matching package. Permission maps are not persisted with the preference settings. App/service restart alone does not clear this map; system-server restart loses the in-memory grants. [UsbHostManager.java:148](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/usb/UsbHostManager.java:148), [UsbSettingsManager.java:618](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/usb/UsbSettingsManager.java:618), [settings serialization:513](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/usb/UsbSettingsManager.java:513).

**SUPPORTED:** Normal callback routing is coherent. M5 registers first and uses a package-targeted, nonce-specific, one-shot broadcast. PendingIntent fill-in preserves the original action/package/nonce while adding device and permission extras. M5 checks nonce, path, VID/PID and `hasPermission`. [PermissionService.java:79](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/m5-permission/source/com/rdx/fullscreen/m5permission/PermissionService.java:79), [PendingIntentRecord.java:152](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/am/PendingIntentRecord.java:152), [Intent.java:1738](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Framework/sources/android/content/Intent.java:1738), [PermissionMachine.java:114](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/m5-permission/source/com/rdx/fullscreen/m5permission/PermissionMachine.java:114).

**CONFIRMED:** Delivery is not guaranteed after M5 terminates: its destruction cancels the PendingIntent and unregisters the receiver. The five-minute deadline and pinned-device disappearance can terminate it before an answer. [PermissionService.java:166](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/m5-permission/source/com/rdx/fullscreen/m5permission/PermissionService.java:166), [PermissionMachine.java:73](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/m5-permission/source/com/rdx/fullscreen/m5permission/PermissionMachine.java:73), [detach handling:96](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/m5-permission/source/com/rdx/fullscreen/m5permission/PermissionMachine.java:96).

**SUPPORTED race; occurrence SPECULATIVE:** Neither grant nor `hasPermission` verifies current host-list membership. M5’s callback checks the returned object, without refreshing inventory. An Allow/destruction interleaved with detach could therefore reinsert a stale path grant before the callback check. This could produce true/true without proving continued attachment. No reviewed runtime evidence demonstrates that interleaving. [UsbSettingsManager.java:825](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/usb/UsbSettingsManager.java:825), [grant:967](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/usb/UsbSettingsManager.java:967), [M5 callback:43](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/m5-permission/source/com/rdx/fullscreen/m5permission/PermissionService.java:43).

**Q5. Stock Android Auto contention — CONFIRMED / SUPPORTED**

**CONFIRMED:** Stock transport opens the device and claims interface 0. Its stop path may reset the device. [UsbHostTransport.java:51](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/google/android/projection/transport/usb/UsbHostTransport.java:51), [stop path:89](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/google/android/projection/transport/usb/UsbHostTransport.java:89).

**SUPPORTED answers:**

- **Showing/answering:** Claiming the interface is absent from permission-dialog eligibility. Stock activity launches, video focus and overlays are the relevant indirect UI contention.
- **Grant validity:** A stock interface claim does not delete another UID’s grant.
- **Later M5 `hasPermission`:** It reads the UID/path permission map, not interface ownership. It can remain true while stock AA owns the interface.
- **Indirect exception:** Reset/removal/re-enumeration can clear the grant and finish the dialog. Honda also has explicit USB-reset paths. [GalService.java:1829](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/service/GalService.java:1829).

M5 does no open/claim/transfer in this request path. A permission PASS would not establish transport availability.

**Q6. Top five residual risks — ranked by review judgment**

| Rank | Risk and confidence | Distinguishing in-car evidence | Offline reduction without changing frozen M5 |
|---|---|---|---|
| **1** | **CONFIRMED mechanism:** detach/re-enumeration ends the pinned experiment; a grant/detach race is **SPECULATIVE**. | Device path disappearance, USB detach, `DETACHED_AFTER_REQUEST`; correlate any true/true result with attachment continuity. The retry already records detach followed by M5 termination. | **Yes, evidence quality:** correlate saved host events and inventory continuity before accepting a result. Offline analysis cannot prevent the physical cycle. |
| **2** | **CONFIRMED mechanism:** Home/API close-system-dialogs can finish it; projection or higher Honda windows can cover it. Actual overlap **UNKNOWN**. | Screen recording plus foreground/window evidence; `close-sys`, projection `maximize AA activity`, focused-window type. A later false result need not mean Cancel was pressed. | **Yes:** document UI dismissal versus deliberate denial and identify required capture evidence. No APK change needed. |
| **3** | **CONFIRMED pointer gap; UNKNOWN usability:** hover-aware SystemUI lacks permission-dialog pointer assistance. | Prompt visible but no pointer/highlight; whether the physical control can select and activate the positive button. | **Partial:** improve observation instructions and inspect matching resources/input evidence. Cannot prove physical input offline. |
| **4** | **CONFIRMED lifecycle weakness:** configuration destruction can send false; M5 stop/deadline cancels delivery. Actual occurrence **UNKNOWN**. | Relaunch/configuration or service-end records around callback; `PendingIntent was cancelled`; distinguish false callback from observed negative-button input. | **Yes:** make reviewer classification require lifecycle/UI corroboration. Current verdict tooling already leaves non-PASS outcomes for manual review. |
| **5** | **CONFIRMED provenance gap:** saved SystemUI 168 versus live 14; effective AutoSS permissions and runtime firewall/controller policy **UNKNOWN**. | Exact live package identity/permissions and start/window outcome with lock-task inactive; AutoSS refusal toast/state versus a rendered activity. | **Partial:** analyze an already available matching build and its provenance. Existing build-168 analysis cannot establish parity. |

For risk 1, direct retry evidence is [detach:63237](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/m5-live-retry-20261025-185128/reconnect-logcat.txt:63237) and [M5 termination:63551](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/m5-live-retry-20261025-185128/reconnect-logcat.txt:63551). For risk 4, the current classifier explicitly reports non-PASS as inconclusive/manual review. [Get-M5JournalVerdict.ps1:6](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/m5/Get-M5JournalVerdict.ps1:6).

6. **Primary evidence for each finding**

Each answer above cites the relevant implementation or captured event. The decisive evidence is:

- **Capability:** positive click → destruction-time grant → PendingIntent send, `UsbPermissionActivity.java:85–128`.
- **Additional Honda veto:** `ActivityStackSupervisor.java:647` and `AutoSSMonitor.java:55`.
- **Residual dismissal:** manifest `finishOnCloseSystemDialogs`, `ActivityStack.java:2437`, Home handling at `PhoneWindowManager.java:2949`.
- **Input concern:** SystemUI hover metadata, Policy `VirtualPointer.java:37`, debugging-only pointer initialization.
- **Type transition:** `UsbMediaDefines.java:13`, retry log `66231–66235`; bounded add/detach search returned zero.
- **Permission lifetime/races:** settings map lookup, removal and insertion at `UsbSettingsManager.java:818`, `:618`, `:967`; M5 callback at `PermissionService.java:43`.
- **Actual failed attempt:** [retry log:61395](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/m5-live-retry-20261025-185128/reconnect-logcat.txt:61395) records lock-task rejection. It does not establish unlocked-dialog behavior.

7. **Assumptions**

- Decompiled code is usable static evidence where method bodies are present.
- Rank order is analytical judgment, not measured failure probability.
- No build-168/live-build-14 behavioral equivalence is assumed.
- A requested manifest permission is not treated as proof of its effective live grant.

8. **Unresolved uncertainties**

**UNKNOWN:** Successful unlocked live presentation/input/grant; exact live dialog geometry and flags; touchpad/rotary mapping; effective AutoSS permission; firewall/controller configuration; complete live binary parity; exact `UsbMediaService` logger implementation; occurrence of the identified races.

WindowManager’s handler also contains an undecompiled method, limiting any exhaustive claim about Honda window customization. [WindowManagerService.java:5775](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/wm/WindowManagerService.java:5775).

9. **Exact diff summary**

None. No edits. Scoped `git diff --stat` returned no output. Initial/final status retained only the same pre-existing `.gitignore` modification and two untracked files.

10. **Preservation checks performed**

SHA-256 results matched:

| Artifact | Verified SHA-256 |
|---|---|
| Frozen M5 | `A22E96490B9557AFF022893A8B8B7A08BB13CEC236E52704CDDAFA90A8EE8F40` |
| Disabled M6 | `D4DAC2DD8B2AFF1FA7B64BFB32D2A5E889854CCEB4B4A9F7AD5AEF89FB28761F` |
| Receiver DEX, both copies | `2FDBC63F2F9D63B764697D311AF89D460AE6B8E14B0FADABA9C9339F7FE7C235` |
| API22 TLS qualifier | `86350131FFC5CBE5766E523AB03AE07D4C9F5EAD78F0570B68255C9A3999FC1F` |

No rebuild, repository mutation, key-material access, device access, arming or milestone action occurred.