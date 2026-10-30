# Next bounded experiment after live test02: constructor safety, then separate native/USB gates

**Current outcome:** [live test02](LIVE-TEST-02-RESULTS.md) completed normal Diagnostics exit with ADB retained, ordinary install, synthetic rendering and measured1339x720 Surface. M0/M1/M2 passed under UID10050/untrusted_app; clean exit/uninstall passed. M3 remains deferred because library startup constructors were not proved inert. No phone or later stage ran. This current plan supersedes the historical Surface-repeat plan retained below.

## First gate: offline load-time safety

Trace `.init_array` entries at0x1C6EF8: OPENSSL_cpuid_setup and unnamed Thumb functions0xBB359/0xBBCE9, plus their reachable branches/indirect calls and dependency startup. Record heap/global/TLS/mutex/atexit effects separately from sockets, threads, filesystem/device/Binder/protocol initialization. Absence of JNI_OnLoad is insufficient. Keep factory/native bytes unchanged. No root, injection, linker bypass or actual load is authorized merely to discover side effects.

Only after the load-time graph is understood well enough to meet the user's inert-load requirement should a new reviewed revision add System.loadLibrary alone, without nativeInit, credentials, service registration, USB or codec references in that path. Preserve distinct controls and log loaded/not initialized. A future approval would cover only install→synthetic UI→explicit load-only control→own exit/uninstall. If constructor safety cannot be established, keep M3 deferred; do not substitute the old L2 button.

The tested0.1.1 synthetic-only build has **no load-only control** and no GAL/USB/codec Java code; original0.1.0 receiver/backend remains unchanged. New tests require separately identified/hashes-reviewed artifacts, not an undocumented build substitution.

## New approval qualification: ordinary OEM lifecycle side effects

Honda GalService observes ordinary APP_LAUNCHED notifications and sets gal_should_auto_start=false for packages other than AA/launcher. This setter ran when the custom Activity resumed in test02, after an earlier false setter for navigation. OEM launcher/B-zone/CarPlay/media observers also react naturally. Do not promise all Honda private data remains byte-identical just because our package is independent. No direct app/agent Honda-data modification occurred; exact prior/private XML equality was not measured. Do not edit or restore the preference as cleanup. Future approvals must explicitly acknowledge normal OEM lifecycle reactions while continuing to forbid direct Honda package/data changes and configuration changes.

## Later bounded experiments: separate approvals, not one session script

| Stage / question | Minimum experiment and evidence | Change / rollback / gate |
| --- | --- | --- |
| Local GAL initialization without phone | Only after constructor/ABI/teardown review, initialize the original native engine in our process with Candidate A, no USB transport/nativeStart/decoder. Observe process/SSL/service-config logs and own teardown; never print key contents. | MODERATE, untested native crash/cleanup; own package stop/uninstall fallback. OEM lifecycle side effects explicitly accepted. This is **GAL init**, not inert M3, and remains unauthorized now. |
| Passive stock ownership trace | During an independently authorized normal factory phone session, capture dumpsys usb, ps, existing logs and readable /proc/AA-PID/fd links. Do not launch our receiver or send frames. | Phone connection has normal stock data/USB effects and needs a new approved setup. No stock force-stop/clear/reset/disable. Preserve serials locally only as needed. |
| Ordinary USB permission | A future permission-only build enumerates an already-authorized test phone topology and requests the Android user grant; no mode-switch/open/claim, no default-app preference. Observe dialog result and hasPermission. | MODERATE, changes per-device UID grant/dialog state and own package records. Own uninstall; grant lifetime/disconnect handled only as approved. Reinstall changes UID; do not reuse10050 as a permanent identity. |
| Can our process obtain an FD? | After granted permission, separately reviewed openDevice→close only, no claim/bulk/control/native/GAL traffic; log grant, FD result/error and close. | Ordinary FD access is distinct from ownership and transport delivery. Stop on denial; no direct MANAGE_USB grant, reset socket or root. Own close/exit/uninstall. |
| Exclusive interface/transport | Establish a cooperative stock handoff/idle state before any non-forcing claim. No handshake in a claim-only experiment. A busy claim is evidence, not authorization to force or reset. | **Not ready.** Safe release/handback and stock retry/reset behavior remain unresolved. Uninstall does not guarantee live-session recovery. Never stop/disable Honda AA to create availability. |

Questions addressed by those stages: public grant authorization; actual normal-process FD access/effective SELinux; which process owns/retries the interface; whether only one receiver can claim/use that phone protocol session; whether local GAL can initialize without our code modifying factory AA. These are separate observations—permission success is not FD success, claim success, handshake or video.

Even after a native-only test, do not combine phone/GAL/decoder/overscan experiments. No current code path supplies a proven safe stock/custom lease. No root/UID1000/signature/system_app requirement has been demonstrated for the core beyond the ordinary-app capabilities now measured. USB/SELinux denials must be diagnosed at the exact boundary before considering any narrow bridge.

## Recommended next model

Use GPT-6 Astra Medium for the next constructor/dependency/ownership analysis; GPT-6.1 Sol High remains adequate for routine bounded collection, build and report steps. This is a workload judgment consistent with [official OpenAI guidance](https://developers.openai.com/api/docs/guides/model-selection), not a benchmark result or an automatic switch. No model choice changes the live authorization boundaries.

---

## Historical plan for test02 — completed, do not replay automatically

This is a future plan, not an executable continuation. [Live test01](LIVE-TEST-01-RESULTS.md) established normal installation/removal but failed M1 before process startup with Lock Task Mode error5. **Do not move on to phone, USB, GAL or decoding.** Stock AA remains untouched; the prototype is currently uninstalled.

## Offline work and setup gate

The foreground USBModeSwitchActivity belongs to diagnostic task2 whose dealer.MainActivity starts lock task. Static normal finish/ClosingActivity paths stop lock task. This is a task-lifecycle problem, not a demonstrated normal-app privilege prohibition. Review existing [dealer.MainActivity](../../decompiled/HondaDiagnostics/sources/com/honda/auto/diagnostics/dealer/MainActivity.java), [DiagnosticsBaseActivity](../../decompiled/HondaDiagnostics/sources/com/honda/auto/diagnostics/DiagnosticsBaseActivity.java), [BaseContentsActivity](../../decompiled/HondaDiagnostics/sources/com/honda/auto/diagnostics/BaseContentsActivity.java) and [USBModeSwitchActivity](../../decompiled/HondaDiagnostics/sources/com/honda/auto/diagnostics/developer/USBModeSwitchActivity.java).

Minimum future setup: the operator exits Diagnostics through its ordinary UI before a new test; no ADB-driven diagnostics Activity launch, lock-task Binder call, force-stop, task-injection flag, allowlist/policy edit or device-setting change. Existing dev.adb USB mode must not be toggled. Diagnostic exit can invoke leaveDiagMode, and ADB continuity must be checked. That operator/OEM lifecycle transition is outside live-test01's authorized custom-package-only operations. It was not performed. Do not promise that merely pressing Home or backing out one submenu releases the root task.

If the normal exit path cannot be identified without configuration changes or loses ADB, stop and analyze that exact condition offline. No root/factory reset/reboot workaround. A new ordinary installer failure or recurring error5 is also a stop condition, not permission to use alternate deployment or launcher methods.

## Proposed live test02, phone absent

Risk **LOW for the same new-package install/synthetic test**; normal diagnostic exit is an explicit separate setup action, with no automated fallback. No reboot is expected or authorized. Reuse exactly the approved artifact SHA256 `6C554513BF7340B5335ADD4FA4E204A12A7AC290DDF2A854348CFAB860CC8F82`; do not silently rebuild under that hash.

1. After separately agreed normal UI exit, verify ADB, foreground/task stack and no phone in dumpsys usb. Capture the same package/window/display/boot/stock APK baseline. If diagnostics is still locked, do not repeat installation merely to rediscover error5.
2. Confirm custom package absent, factory AA unchanged and approved APK hash/signature unchanged.
3. Install only the separate APK, start only ReceiverActivity without stage extras, collect app-tag logs, package/ps -Z/window/activity/display state. No buttons except Exit/back; no native/codec/inventory/USB controls.
4. If UI appears, record Surface width/height from the app log and actual app configuration/window. System DisplayInfo alone is not custom Surface evidence. Capture a screenshot through exec-out if useful; avoid uiautomator dump that writes a device file. The current app does not log full DisplayMetrics: identify available app resource configuration via read-only activity dump, and retain system xdpi/ydpi/refresh separately. Do not fabricate per-process metrics.
5. Exit/back only while our app is confirmed foreground, then stop only our package if needed and uninstall it. Preserve exact failures. Verify absence, same stock APK/signature/package, geometry and boot identity. If removal fails, stop without privilege escalation.

Exact future custom-package commands, **not executed by this plan**:

[Code block omitted from public report; see authored source where available.]

Expected state changes: our /data/app and private data/native extraction, normal ADB temporary APK/PM/dex/launcher/log records, own Activity/process. Stock AA code/data is not a target. Worst expected outcome is the same launch rejection, own-app crash/ANR or OEM observer/launcher warnings. Keep cleanup available via ADB; uninstall succeeded in test01 but is not a general system recovery demonstration.

## M3 requires an isolated load-only entry point

The existing L2 native button is **not** M3-only: it loads the library, initializes GAL/SSL and registers video. Do not press it in an M0–M3-only test. Preserve the tested APK. An optional later offline revision may expose an explicit load-only action that calls System.loadLibrary without nativeInit/nativeSetCreds, service registration, decoder or USB work, plus fuller own-process metrics logging. Build/sign/hash and review that revision separately before seeking its runtime approval. Static absence of exported JNI_OnLoad is useful evidence, not a substitute for reviewing constructors/init paths or observing a load.

## Later transport questions remain gated

Only after Activity/Surface/domain and isolated native-load behavior are demonstrated should another plan ask for the following independent stages:

| Question | Least invasive next evidence | Additional change requiring separate approval |
| --- | --- | --- |
| Ordinary USB authorization | Existing UsbSettingsManager public grant path; read-only dumpsys usb on a normally connected phone, actual host VID/PID/endpoints | Launch custom permission request. It may pause the app; no automatic open or default-app selection. |
| Competing stock receiver | Passive process/activity/log/USB snapshots during an independently authorized normal stock session; readable AA FD links if available | No stock stop/disable/clear. A safe cooperative release/handoff must be established before custom claim. |
| Custom data FD/claim | Normal UsbManager.openDevice after user grant; ownership remains distinct from permission | Explicit non-forcing interface claim only with an understood stock ownership state; abort if busy. No mode switch/reset/forced claim. |
| GAL initialization without phone | Isolated future local-native stage after clean load and teardown review | Existing native-init control, still separate from USB and decoder; may crash own process. It writes no stock app state by design, but behavior must be observed. |

These are designs, not authorization to connect a phone or execute any stage. Current next runtime boundary is still Activity launch outside the diagnostic lock task. Root is not justified; a narrow privileged bridge is not justified by error5.
