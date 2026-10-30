# Live test 01: ordinary installation passed; diagnostic Lock Task Mode blocked launch

Target: 2021 Acura RDX, D.1.6.4, Android5.1.1/API22, ARMv7. Device serial00000000. Capture window: 2026-10-22 20:35–20:37 America/New_York / 2026-10-23 00:35–00:37 UTC. Cleanup is complete. No phone, GAL, USB transport, decoder, native initialization or display-setting experiment was performed.

**The independently signed package installed normally as UID10049 and uninstalled successfully. Its Activity was rejected before process creation by Android Lock Task Mode.** This establishes ordinary package installation/removal, not a working Surface or receiver. It is a launch-policy boundary earlier than the previously anticipated USB permission/ownership boundary.

Raw evidence is preserved in [live-test-01](live-test-01). See [machine summary](live-test-01/summary.json), [45-command record](live-test-01/commands.json), [relevant log extract](live-test-01/relevant-log-extract.txt) and [evidence hashes](live-test-01/evidence-hashes.json). Only four commands attempted state changes: install our APK, start our Activity, force-stop our package, uninstall our package. No retry with alternate flags, privileged installer, root or policy change occurred. The initial connectivity check before the numbered capture also ran `adb devices -l`.

[Final host verification](live-test-01-validation.json) validates the raw evidence hashes, report links, before/after APK signing, command scope and preserved original/candidate/prototype artifacts. These checks do not turn the failed launch into a runtime Surface or native success.

## Results and milestone classification

| Milestone | Result | Runtime evidence |
| --- | --- | --- |
| M0: separate APK installs | **PASS** | Normal `adb install` returned Success. UID10049, own /data/app path, no shared UID or requested permissions. Pulled installed base.apk exactly matches approved APK. |
| M1: Activity and synthetic Surface | **BLOCKED before startup** | `am start -W` printed unknown error code5; ActivityManager logged Attempted Lock Task Mode violation. No custom process, Activity instance or custom log output. |
| M2: custom1339x720 geometry | **NOT REACHED** | System baseline app area1339x720 is confirmed, but no custom Surface existed. Do not substitute diagnostics/system geometry for our app's measurement. |
| M3: load/link receiver SO only | **NOT TESTED** | Existing native control calls nativeInit, credentials and video-service registration after loadLibrary; it is not an isolated load-only control. It was not used. |
| M4+ | **NOT AUTHORIZED / NOT RUN** | No phone session, USB grant/open/claim, native GAL initialization or decoding. |

## Exact installation and launch observations

Approved and installed APK SHA256:

`6C554513BF7340B5335ADD4FA4E204A12A7AC290DDF2A854348CFAB860CC8F82`

[Code block omitted from public report; see authored source where available.]

Important diagnostic distinction: the ADB/am shell process returned exit code0 even though the Activity launch failed. The return text and matching ActivityManager log determine M1, not the shell exit code.

Installed package: com.rdx.fullscreen.projection; versionCode1/versionName0.1.0-experimental-offline; targetSDK22; UID10049; code/resource path `/data/app/com.rdx.fullscreen.projection-1`; dataDir `/data/data/com.rdx.fullscreen.projection`; native root `/data/app/com.rdx.fullscreen.projection-1/lib`, resolved ARM directory `/lib/arm`; primaryCpuAbi armeabi-v7a. No requested/granted package permissions were listed. Before launch it remained stopped=true/notLaunched=true. Native extraction existed as apk_data_file, but **file label is not a process domain and extraction is not successful library loading**.

The pulled installed APK matches the approved artifact byte-for-byte. Host API22 v1 verification confirms development signer SHA256 `c001f59b25081ddfc73937155ca3580717e817c45c66e68b9e059737b0b28831`. See [installed package](live-test-01/installed-custom-package.stdout.txt), [native paths](live-test-01/installed-native-paths.stdout.txt), [signer](live-test-01/installed-signature.txt), [launch result](live-test-01/launch.stdout.txt).

There is **no observed custom SELinux process domain**, because the app never started. untrusted_app remains a static expectation, not a live result. No app-side DisplayMetrics, logical/physical DPI callback, orientation, native-library path log, exception or rendering evidence can be claimed. The system display reports physical1920x720, app1339x720, density160, physical200x200dpi, rotation0/landscape and refresh57.000004Hz.

## First exact boundary and narrow non-root remedy

At20:36:46.599 device time:

[Code block omitted from public report; see authored source where available.]

Current task2 is rooted in Honda Diagnostics dealer.MainActivity; foreground is developer.USBModeSwitchActivity. These were already present in the baseline and were not launched/closed by this test. [Activity stack evidence](live-test-01/blocked-activities.stdout.txt). No enabled device administrator was listed; this does not mean lock task was absent.

Matching local framework: [ActivityManager.java](../../decompiled/Framework/sources/android/app/ActivityManager.java) defines START_RETURN_LOCK_TASK_MODE_VIOLATION=5. [ActivityStackSupervisor.java](../../decompiled/Services/sources/com/android/server/am/ActivityStackSupervisor.java) checks isLockTaskModeViolation(reuseTask) before starting a new task and returns5 with the observed log. Its predicate rejects a task different from mLockTaskModeTask. This is not an APK-signing error, Java crash, missing Honda class, USB denial or SELinux denial.

Local Honda Diagnostics code supplies a normal exit path: [dealer/MainActivity.java](../../decompiled/HondaDiagnostics/sources/com/honda/auto/diagnostics/dealer/MainActivity.java) calls startLockTask in onCreate and stopLockTask in finish. [ClosingActivity.java](../../decompiled/HondaDiagnostics/sources/com/honda/auto/diagnostics/ClosingActivity.java) stops lock task and finishes; [BaseContentsActivity.java](../../decompiled/HondaDiagnostics/sources/com/honda/auto/diagnostics/BaseContentsActivity.java) uses it for closeDiagnostics. These are **static evidence**, not operations executed here.

The narrow remedy to investigate is normal operator exit from Diagnostics before repeating this same Surface test. Root, another signer, a UID1000 clone, policy edits and injected tasks are not justified. Do not externally launch ClosingActivity, call stop-lock-task Binder/`am` operations, or alter allowlists under this test's authorization. [DiagnosticsBaseActivity.java](../../decompiled/HondaDiagnostics/sources/com/honda/auto/diagnostics/DiagnosticsBaseActivity.java) can call leaveDiagMode on destruction; normal diagnostic exit is therefore a separate OEM lifecycle transition requiring explicit setup agreement. [USBModeSwitchActivity.java](../../decompiled/HondaDiagnostics/sources/com/honda/auto/diagnostics/developer/USBModeSwitchActivity.java) writes dev.adb only in its mode-selection callback; no such callback or normal exit was triggered here. ADB retention after exit remains to be observed, not assumed.

## Warnings and denials

Honda launcher/monitor observed a non-authorized third-party package, logged missing-resource-ID0 warnings and a missing metadata NullPointer message during its package scan. The package nevertheless installed. These are OEM observer warnings, not evidence that our app crashed. ActivityManager's explicit lock-task refusal is the demonstrated launch cause. No app process, custom log entries, FATAL EXCEPTION, Permission Denial or AVC lines were found in the captured main/system/crash buffers. This does not prove future native/USB/media SELinux access; no such path ran, and kernel-only messages may not be in these buffers.

Normal OEM package observers also updated launcher/media bookkeeping and queried GET_VANILLA_STATE. We did not invoke an updater/factory action. Do not equate normal package-added/removed observer activity with modified AA private data or a fully inert global OS snapshot.

## Cleanup and preservation

[Code block omitted from public report; see authored source where available.]

No running Activity existed to exit cleanly; the own-package stop was precautionary. Package/path dumps after removal are empty, custom process absent, and ls reports the former app code directory, private data directory and ADB temporary APK absent. [Uninstall](live-test-01/uninstall.stdout.txt), [path cleanup](live-test-01/post-app-paths.stdout.txt), [post processes](live-test-01/post-processes.stdout.txt). Normal ADB push installation used its own `/data/local/tmp` temporary file, and normal installer cleanup removed it; no custom staging was performed.

Factory AA before/after pulls and preserved original all have SHA256 `F9E976F44853C9DB7C8FF5A8610C10CAF1E0B4D1E5BE0886F4F52505C5348146`. Both signatures verify with Windriver certificate SHA256 `2156c50e3c08347f28adccb49ae839394053a45767f153bd8f036ae33d5f8568`. Full before/after package dumps are identical: codePath/system/app/AndroidAuto, UID1000, version22/5.1.1-14, installed/enabled flags unchanged. Stock process PID2440/domain system_app appears before and after; no stop/restart was requested. See [before package](live-test-01/pre-stock-package.stdout.txt), [after package](live-test-01/post-stock-package.stdout.txt), [before signer](live-test-01/stock-before-signature.txt), [after signer](live-test-01/stock-after-signature.txt).

Full before/after WindowManager dumps are identical. Physical/app geometry and display override remain unchanged. No overscan/size/density command ran. Boot UUID is identical and uptime increased, demonstrating no reboot between snapshots. No command wrote settings/properties, /system, /persistdata or Honda private data.

Limits: Android's `settings list` is unsupported on this build and only printed usage, so a complete settings snapshot comparison is unavailable. Observed ambient properties **did change**: sys.settings_global_version1503→1539 and sys.temperature.value52→55. We did not set them; do not report whole-system property equality. Uninstall is not byte-for-byte restoration of PM files, logs or OEM launcher records. Factory APK/signature/package preservation is directly demonstrated; byte-for-byte Honda private-data immutability and every system/persistdata file were not forensically checked. Factory projection was not functionally retested because the phone remained disconnected.

## Decision

Reached **M0 only**; ordinary install/removal and development signing are now demonstrated on this exact build. Return offline first to review the normal diagnostic-exit setup, then repeat only M1/M2 after separately authorized normal-UI preparation. The next boundary is **leaving the already-active diagnostic lock task while retaining ADB**, not USB, GAL, root or stock-AA replacement. [Next bounded plan](NEXT-LIVE-TEST.md).
