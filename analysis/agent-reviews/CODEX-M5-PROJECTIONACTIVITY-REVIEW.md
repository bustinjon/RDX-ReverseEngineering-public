**1. Files inspected**

Read `PROJECT-RULES.md` and `AGENTS.md` first, then:

- The three requested M5 conclusion/guard documents.
- Retry baseline/reconnect logs, armed log, reconstructed journal, journal events, verdict and user observations.
- Original M5 after-phone log and journal.
- M4 reconnect logs, passive results and validation records. `m4-live-20261023-163934-150/` contains three preparation/audit files; the live comparison evidence is in `m4-single-port-20261023-170305-676/`.
- Both readiness scripts, the future-session runner, Honda `GalService`, `ProjectionActivity` and manifest, Diagnostics `MainActivity`, saved framework lock-task/USB-permission implementations, and M5 permission source.
- Preservation-manifest entries for the frozen artifacts.

Log aliases used below, with **PowerShell `Select-String` line numbering**:

| Alias | File |
|---|---|
| R | [Retry reconnect log](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/m5-live-retry-20261025-185128/reconnect-logcat.txt) |
| O | [Original M5 after-phone log](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/m5-live-20261023-173401-872/20261023-174513-881-after-phone-logcat.stdout.txt) |
| A | [M4 attempt-one reconnect log](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/m4-single-port-20261023-170305-676/20261023-170923-027-reconnect-logcat.stdout.txt) |
| B | [M4 attempt-two reconnect log](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/m4-single-port-20261023-170305-676/20261023-171629-247-attempt2-reconnect-logcat.stdout.txt) |

**2. Files changed**

None.

**3. Commands run**

Read-only commands: `Get-Content`, `rg --files`, `rg -n`, `Select-String`, `Get-ChildItem`, `Get-FileHash -Algorithm SHA256`, timestamp subtraction, `git status --short`, and scoped `git diff --stat`.

The decisive log searches used:

[Code block omitted from public report; see authored source where available.]

Honda lock-task reference search:

[Code block omitted from public report; see authored source where available.]

Result: **no matches; exit code 1**.

Several exploratory lookups used nonexistent filenames; corrected paths were subsequently inspected. One timestamp-results formatting expression was rejected by PowerShell constrained language mode; individual arithmetic expressions succeeded.

No device commands or project scripts were executed.

**4. Tests run and results**

No live tests or executable project test suites were run.

Read-only timestamp calculations returned:

| Calculation | Result |
|---|---:|
| Projection rejection → permission rejection | 686 ms |
| Permission rejection → Diagnostics unlock | 1,895 ms |
| M4 second normal → accessory enumeration | 753 ms |
| M4 first accessory enumeration → detach | 20,469 ms |
| Retry accessory enumeration → M5 invocation-intent record | 687 ms |
| Retry accessory enumeration → system detach | 20,128 ms |

Frozen-artifact hash comparisons all returned `expectedMatch=True`. Scoped `git diff --stat` produced no output.

**5. Findings**

**Q1 — CONFIRMED: relevant retry timeline**

Times are October 25 logcat labels. Journal event times are distinguished where they precede log emission.

| Time | Event | Primary evidence |
|---|---|---|
| Before window: 18:43:03.869 | Diagnostics `dealer.Main` logs `onCreate(), start lock task`. | Retry `20261025-185431-873-baseline-logcat.stdout.txt:17535` |
| Before window: 19:31:13.878 | M5 arms and waits for the target. Log emission is 13.882. | `armed-logcat.txt:7`; reconstructed journal:3 |
| 19:31:25.746–25.783 | Diagnostics USBModeSwitch pauses; Diagnostics Menu starts/resumes. | R:60261,60345,60397 |
| 19:31:25.785 | Honda records AA autostart preference false following another activity’s start. | R:60405,60407 |
| 19:31:26.160 | USB host root hub `/003/001`, VID:PID `1D6B:0002`, appears; Honda rejects it as a phone candidate. | R:60491,60503,60507 |
| 19:31:26.200–26.203 | USBModeSwitch stops/destroys; Diagnostics leaves mode 2 but reports new diagnostic mode 1. This is not the later lock-task stop. | R:60531,60533,60535,60539 |
| 19:31:26.214 | Second host root hub `/004/001`, `1D6B:0003`, appears; Honda ignores it. | R:60541,60551,60555 |
| 19:31:26.449 journal / .454–.458 log | M5 observes the hubs, remains waiting, no request reserved. | R:60731,60733 |
| 19:31:29.257 | Phone enumerates normally as `22D9:2769`, `/003/002`. | R:60901 |
| 19:31:29.259–29.288 | Honda receives USB attach, accepts the phone, enters `SWITCHING`, starts the accessory-switch timer and processes the non-accessory device. | R:60915,60959,60963,61019,61031,61033,61037 |
| 19:31:29.313–29.314 | Normal enumeration detaches while Honda is `SWITCHING`. | R:61051,61053,61057,61059 |
| 19:31:29.971 | Phone re-enumerates as accessory `18D1:2D01`, `/003/003`. | R:61173 |
| 19:31:29.974–29.977 | Honda receives accessory attach, cancels switching timer; saved start preference is 1 and accessory test is true. | R:61195,61211,61213,61215 |
| 19:31:29.987–29.991 | Honda explicitly decides to start ProjectionActivity, minimized=true. Runtime caller stack: `GalService.onUsbDeviceConnected → startGal → startProjectionActivity`. Caller-side PID/TID is **2441/2441**. | R:61259,61263,61265 |
| 19:31:29.995 | ActivityManager logs ProjectionActivity START: caller **UID 1000**, user/display 0, explicit component, flags **0x10000000**, extras present. No action/data is printed. AM logging PID/TID is **2306/2720**, distinct from Honda’s caller-side PID. | R:61269 |
| **19:31:29.996** | **ProjectionActivity rejected for lock-task violation**, record `t-1`. | **R:61275** |
| 19:31:30.631 journal / .637–.647 log | M5 sees and pins `/003/003`, permission=false, then reserves its one request. | R:61377,61383,61385 |
| 19:31:30.658 journal / .665 log | M5 records `REQUEST_API_INVOKING`; M5 PID/TID **8902/8902**. | R:61387 |
| **19:31:30.671** | SystemUI UsbPermissionActivity START: caller UID **1000**, flags **0x10000000**, extras present; AM PID/TID **2306/3277**. | **R:61389** |
| **19:31:30.682** | **UsbPermissionActivity rejected for lock-task violation**, record `t-1`. | **R:61395** |
| 19:31:30.683 journal / .691 log | SDK permission call returns. | R:61397 |
| 19:31:31.624–32.090 | Diagnostics Menu pauses; existing dealer Main starts/resumes; Menu destroys. | R:61793,61823,61895,61965,61967 |
| **19:31:32.577** | Diagnostics logs `finish(), stop lock task`; ActivityManager logs `stopLockTaskMode`. | **R:61983,61985** |
| 19:31:32.638 | Honda Home starts/resumes. | R:62099,62101 |
| 19:31:33.866 | Diagnostics dealer Main stops/destroys. | R:62517,62523 |
| 19:31:34.923 | M5 heartbeat: permission requested, one boundary call. This is not a new permission measurement. | R:62555 |

No new lock-task **start** is recorded within this window. The saved baseline contains the earlier Diagnostics start; the rejection precedes the recorded stop.

**Q2 — CONFIRMED: Honda USB handling caused the ProjectionActivity attempt; lock-task was already active**

The runtime call stack and attach sequence directly establish Honda’s accessory-connected path as the immediate cause. Honda attempted its activity **before M5 selected the target or requested permission**: R:61265,61269,61275 versus R:61383,61387.

Diagnostics ownership is **SUPPORTED** by its earlier start log, diagnostic-task foreground history and its matching stop operation. The saved framework rejects a different task while its locked-task pointer is non-null; the rejected Honda and SystemUI records both have `t-1`. See primary-source references in item 6.

Thus the earlier rejection is evidence that the lock already existed when Honda tried to launch. It is **not evidence that ProjectionActivity activated lock-task**.

The UID 1000 on SystemUI’s START does not identify M5 as a system app. M5’s saved service-start record identifies UID **10049**, PID **8902** (`armed-logcat.txt:5`); the saved USB framework clears Binder calling identity before launching SystemUI.

**Q3 — CONFIRMED: the stock attach → ProjectionActivity pattern occurred previously**

| Run | Enumeration and activity evidence | Lock-task result |
|---|---|---|
| Original M5, actual phone interval | Normal phone at **17:42:58.732**, O:75395; accessory at **17:42:59.481**, O:75657; Honda caller stack O:75749; Projection START **17:42:59.498**, O:75753; activity creation O:75825,75851. | Diagnostics stopped lock-task earlier at **17:42:46.543**, O:71537. The projection activity then instantiated. M5 had already timed out at **17:38:16.933**, O:50535, and ended O:50537. |
| M4 attempt one | Normal **17:08:08.400**, A:77393; accessory **17:08:09.128**, A:77905; Honda caller stack A:78033; START **17:08:09.159**, A:78043; activity creation A:78253,78265. | Activity instantiated. A later Diagnostics creation logs lock-task start at **17:08:48.251**, A:91123. That log does not establish what caused Diagnostics to open. |
| Passing M4 attempt two | Accessory **17:14:01.370**, B:75365; Honda caller stack B:75437; START **17:14:01.390**, B:75441. | **Same ProjectionActivity lock-task rejection**, B:75447. Diagnostics stops lock-task at **17:14:05.525**, B:76841,76843. |
| Same passing M4 run, later enumeration | Normal **17:14:22.526**, B:78685; accessory **17:14:23.279**, B:79045; Honda caller stack B:79147; START **17:14:23.312**, B:79155. | Another launch attempt after the recorded unlock. |

The passing M4 app directly observed the first accessory at `m4-attempt2-result.txt:114`, permission=false. M4 PASS therefore establishes passive visibility despite that activity rejection; it does not establish permission-dialog viability.

The original M5 capture also contains retained **17:14** M4 history. Those older lines must not be classified as events from the actual **17:42** M5 phone interval.

**Q4 — guard implications**

**CONFIRMED: the guard checks observations before ARM.** It requires inactive replies around each snapshot, Honda Home foreground, at least five seconds of acceptable samples, bounded gaps and freshness. The runner rechecks freshness at the ARM boundary. References: `scripts/Test-M5ArmReadiness.ps1:64`, `tools/m5/M5ArmReadiness.ps1:46`, `:59`, `:77`, and `tools/m5/Invoke-M5FutureSession.ps1:64`, `:67`, `:68`.

**SUPPORTED: this addresses the demonstrated pre-existing Diagnostics condition.** The retry had Diagnostics lock-task before phone arrival. Requiring inactive lock-task and Home would reject the observed setup.

**UNKNOWN: inactive state at ARM predicts inactive state at permission-dialog time.** No reviewed run contains the new guard’s successful live inactive observations followed by a permission-dialog-time measurement. The checker’s sampling ends before the cable swap. Its five-second policy cannot establish future state; the plan expressly acknowledges this at `M5-RETRY-LOCKTASK-GUARD-PLAN.md:19` and `:49`.

**SPECULATIVE: phone attach or Honda’s ProjectionActivity launch automatically reactivates Diagnostics lock-task.** No such activation is established. The AndroidAuto search found no lock-task references; its attach path starts ProjectionActivity. Moreover:

- Original M5 launched ProjectionActivity after a recorded unlock.
- In this retry, Honda again starts ProjectionActivity at **19:31:51.645**, and the activity instantiates at **19:31:51.751**, after Diagnostics stopped lock-task: R:64461,64627.
- Diagnostics explicitly starts lock-task again at **19:36:23.113**, R:95205; the cause of that later Diagnostics entry is UNKNOWN.

Lock-task **can** re-enter if an actor invokes its activation path; Diagnostics has that path. The reviewed evidence does not tie such re-entry to phone attach.

**CONFIRMED correction to the ~0.75-second premise:** the measured M4 transition is **normal mode → accessory mode**, not accessory mode → normal mode. B:78685 at 17:14:22.526 and B:79045 at 17:14:23.279 give **753 ms**. The preceding accessory enumeration lasted **20.469 seconds**, B:75365→78547.

**SUPPORTED: re-enumeration is an independent threat to the pinned permission experiment.** The retry’s selected accessory disappears at R:63209; M5 subsequently ends `DETACHED_AFTER_REQUEST`, R:63551, without reselection. Saved framework source removes device permissions by device path on detach. Neither behavior depends on lock-task.

However, re-enumeration did **not precede this retry’s initial permission launch**: the invocation-intent record was 687 ms after accessory enumeration; system detach came 20.128 seconds after enumeration. The immediate recorded UI blocker remains lock-task. Whether an unlocked dialog would survive or complete before a later detach is **UNKNOWN**. The trigger of the extra accessory→normal cycle is also **UNKNOWN**.

**6. Primary evidence for each finding**

The timeline and comparisons above cite saved runtime events. The principal source corroboration is:

| Finding | Source evidence |
|---|---|
| Honda’s attach handler invokes its connected-device processing | [GalService.java:642](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/service/GalService.java:642) |
| Accepted accessory invokes `startGal` | [GalService.java:740](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/service/GalService.java:740) |
| False autostart preference can still lead to minimized activity launch | [GalService.java:938](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/service/GalService.java:938), [953](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/service/GalService.java:953) |
| Explicit activity intent, NEW_TASK flag and minimized extra | [GalService.java:960](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/service/GalService.java:960) |
| Diagnostics starts/stops lock-task | [MainActivity.java:44](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/HondaDiagnostics/sources/com/honda/auto/diagnostics/dealer/MainActivity.java:44), [80](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/HondaDiagnostics/sources/com/honda/auto/diagnostics/dealer/MainActivity.java:80) |
| Framework violation means a different locked task exists | [ActivityStackSupervisor.java:2501](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/am/ActivityStackSupervisor.java:2501) |
| Permission dialog launches under cleared calling identity | [UsbSettingsManager.java:866](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/usb/UsbSettingsManager.java:866) |
| Detach removes permissions for that device path | [UsbSettingsManager.java:618](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/usb/UsbSettingsManager.java:618) |
| M5 invokes the standard permission API | [PermissionService.java:75](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/m5-permission/source/com/rdx/fullscreen/m5permission/PermissionService.java:75) |
| Changed selected identity terminates M5 | [PermissionMachine.java:98](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/m5-permission/source/com/rdx/fullscreen/m5permission/PermissionMachine.java:98) |

The retry’s two decisive rejection records are [ProjectionActivity:61275](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/m5-live-retry-20261025-185128/reconnect-logcat.txt:61275) and [UsbPermissionActivity:61395](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/m5-live-retry-20261025-185128/reconnect-logcat.txt:61395).

**7. Assumptions**

Saved logcat labels are compared within their respective sessions. Journal wall times and log emission times are treated separately.

Saved decompiled implementations provide corroborating behavior. This investigation does not establish complete live-framework binary parity or exhaustively exclude indirect/native behavior.

**8. Unresolved uncertainties**

- **UNKNOWN:** a successful live result from the new readiness getter/guard followed by this phone workflow.
- **UNKNOWN:** predictive reliability of ARM-time lock state for dialog-time state.
- **UNKNOWN:** exact action causing Diagnostics to finish at 19:31:32.577.
- **UNKNOWN:** exact trigger of the later accessory→normal enumeration cycles.
- **UNKNOWN:** ordinary-app grant/denial outcome with lock-task inactive.
- **UNKNOWN:** whether later re-enumeration would interrupt a visible, unlocked permission dialog.
- **UNKNOWN:** automatic phone-attach-induced lock-task re-entry; no supporting activation record was found.
- **UNKNOWN:** actual complete launch extras beyond those logged or corroborated statically.

No callback or verified grant is established: retry `m5-verdict.json:4` records one invocation, `:6` zero accepted callbacks, and `:8` no verified grant.

**9. Exact diff summary**

None. No files edited. Scoped `git diff --stat` was empty.

**10. Preservation checks performed**

`Get-FileHash` matched all four preservation anchors:

| Artifact | Verified SHA-256 |
|---|---|
| Frozen M5 APK | `A22E96490B9557AFF022893A8B8B7A08BB13CEC236E52704CDDAFA90A8EE8F40` |
| Disabled M6 APK | `D4DAC2DD8B2AFF1FA7B64BFB32D2A5E889854CCEB4B4A9F7AD5AEF89FB28761F` |
| Receiver DEX, both manifest-listed copies | `2FDBC63F2F9D63B764697D311AF89D460AE6B8E14B0FADABA9C9339F7FE7C235` |
| API22 TLS qualifier APK | `86350131FFC5CBE5766E523AB03AE07D4C9F5EAD78F0570B68255C9A3999FC1F` |

Retry reconnect-log SHA-256: `895778DAA9D6399A974984A46A11BA434221FA272A4430B68A430D7DF55FDB10`.

Reconstructed journal SHA-256 matched its recorded value: `138F02161E79536D3C7D6F0D671D9253F8573D89881A2B1BD27B2A937D1E67AF`.

Initial and final status showed the same lead-owned modification under `analysis/agent-reviews/`; its content was ignored. No rebuild, device access, milestone action, key-material access or repository mutation was performed.