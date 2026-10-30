# Live test02: supported diagnostic exit and ordinary-app Surface succeeded

Target2021 Acura RDX D.1.6.4/API22/ARMv7. Session2026-10-22 approximately20:50–20:57 America/New_York (2026-10-23 UTC). **M0, M1 and M2 passed. M3 deferred; M4+ unauthorized and not run.** The disposable package has been removed. No phone, GAL initialization, native library load, USB transport, decoder, overscan, root, updater or firmware operation was performed by this test.

[Machine summary](live-test-02/summary.json), [68-command log](live-test-02/commands.json), [relevant log extract](live-test-02/relevant-log-extract.txt), [raw evidence hashes](live-test-02/evidence-hashes.json). Eight authorized state-changing commands: four normal Diagnostics RETURN taps, one custom install, one custom Activity launch, one custom Exit-button tap, one custom uninstall. All remaining logged device operations were observations or pulls. No factory component was force-stopped and no lock-task bypass API/command was invoked.

[Final host verification](live-test-02-validation.json) validates test02's214 evidence-file hashes, preservation of test01's144 evidence records, original notes/factory/Candidate A/B/original prototype hashes, API22 signing, synthetic compiled references and report links. No car operation was performed during final verification.

## Direct answers

| Question | Result |
| --- | --- |
| 1. Exact lock-task cause | Existing task2 rooted at com.honda.auto.diagnostics/.dealer.MainActivity. USBModeSwitchActivity was initially resumed inside it. dealer.MainActivity starts lock task in onCreate; the old error5 was the new-task refusal. |
| 2. Normal exit | Top-right RETURN: USB Mode Switch→Developer Diagnostics→Detail Information & Setting→Dealer Diagnostics→Honda Home. BaseContentsActivity handles finish; MenuActivity moves to its parent menu then finishes; dealer.MainActivity.finish calls stopLockTask. |
| 3. Exit performed? | **Yes**, four verified ordinary UI button taps, not direct ClosingActivity launch or hidden lock-task commands. |
| 4. ADB survived? | **Yes**, checked after every RETURN and after final exit. dev.adb remained1; sys.usb.config/state remained mtp,adb. |
| 5. Normal install again? | **Yes**, synthetic-only revision0.1.1/versionCode2, independently development-signed. No -r/shared UID/system paths. |
| 6. Running UID/domain | **10050**, PID30513, **u:r:untrusted_app:s0**, corroborated by ps -Z and proc attr/current. New install did not reuse test01's10049 UID. |
| 7. M1? | **PASS**: Activity Status:ok, valid Surface, Canvas posted, texture update, screenshot visually confirms synthetic frame. |
| 8. Dimensions | Own Surface/decor/resources/app metrics **1339x720**, visible frame[0,0][1339,720]. Physical display/getRealSize1920x720. Logical160dpi, physical200x200dpi, density/scaledDensity1.0, landscape2/rotation0,57.000004Hz. |
| 9. M2? | **PASS**, measured by our running app and its visible image, not inferred from baseline. |
| 10. Inert M3 established? | **No**. No exported JNI_OnLoad, but three ELF init_array entries exist; two unnamed constructor paths and dependency constructors were not fully proved inert. |
| 11. Native load/link success? | **Not tested**, no load-only probe added/executed. Packaging/extraction is not successful dynamic loading. |
| 12. Failures/denials? | No app crash, app permission/SELinux denial, framework classloading error or linker failure observed. GL preserved-swap-config retry succeeded. Shell→adbd ioctl AVCs occurred; shell reading our proc/maps was denied. These are not custom-app GAL/media denials. |
| 13. Cleanup? | **PASS**: own Exit button produced onPause, Surface destroyed, onDestroy; uninstall Success; package/process/code/data/temp APK absent. No force-stop needed. |
| 14. Honda AA unchanged? | **APK, signer, version and full package dump unchanged; PID2440 unchanged. Private-data equality cannot be claimed:** Honda's own lifecycle observer invoked its auto-start=false preference setter on app resume. See qualification below. |
| 15. Reached milestone | **M2**. M0/M1/M2 pass; M3 deferred; no higher stage attempted. |
| 16. Next exact boundary | Static safety of library load-time constructors/dependencies before any isolated M3/native init. After that, ordinary USB grant and exclusive ownership/handoff remain untested. |
| 17. Next model | Recommend **GPT-6 Astra Medium** for the next cross-layer constructor/ownership analysis; Sol High remains suitable for routine capture/build/test steps. This is workload judgment, not a measured High-versus-Medium benchmark. |

## Supported exit: static path and live confirmation

Baseline read-only screenshot/stack showed USBModeSwitchActivity in diagnostic task2. [Initial window](live-test-02/pre-window.stdout.txt), [initial activities](live-test-02/pre-activities.stdout.txt). The normal RETURN button is bound to onDiagReturnButtonClicked in [base_layout.xml](../../decompiled/HondaDiagnostics/resources/res/layout/base_layout.xml). [BaseContentsActivity](../../decompiled/HondaDiagnostics/sources/com/honda/auto/diagnostics/BaseContentsActivity.java) calls finish; [MenuActivity](../../decompiled/HondaDiagnostics/sources/com/honda/auto/diagnostics/MenuActivity.java) handles internal parent menus; [dealer.MainActivity](../../decompiled/HondaDiagnostics/sources/com/honda/auto/diagnostics/dealer/MainActivity.java) stops lock task in finish. Runtime View hierarchy confirmed the RETURN Button's live bounds1129,13–1329,93. Each tap used1230,50 and was followed by ADB and Activity/screen verification. No other diagnostic menu item was selected.

Logs show developer leaveDiagMode2→dealer mode1; final RETURN logged `dealer.Main: finish(), stop lock task`, ActivityManager stopLockTaskMode, dealer onDestroy and DiagnosticsService leaveDiagMode1→0. Those service calls/broadcasts were made by Honda's normal UI lifecycle, not by an agent Binder transaction. [Post-exit Activity](live-test-02/after-exit-top.stdout.txt) is com.honda.tjba.launcher/.ui.HomeActivity. Successful custom new-task launch then demonstrates the previous restriction no longer blocked it; the dump need not expose a dedicated lock-task flag to establish that behavior.

Normal exit also unregisters receivers and can call DiagnosticsManager.leaveDiagMode from [DiagnosticsBaseActivity](../../decompiled/HondaDiagnostics/sources/com/honda/auto/diagnostics/DiagnosticsBaseActivity.java). The service updates its mode/token state and broadcasts DIAG_MODE_CHANGED. [USBModeSwitchActivity](../../decompiled/HondaDiagnostics/sources/com/honda/auto/diagnostics/developer/USBModeSwitchActivity.java) writes dev.adb only in mode-selection UI, not in RETURN/destruction. Developer-option disable is a different toggle path; it was not selected. **ADB survival is now demonstrated for this exact normal exit/session**, not a guarantee for resets, toggles or future ignition cycles.

## Tested artifact and measured geometry

To remove accidental unsafe controls and log actual metrics, this test used an isolated synthetic-only revision under [live-test-02/prototype](live-test-02/prototype). The original0.1.0 source/APK, Honda files and Candidate A/B remain unchanged. New Activity has no Google/Honda classes, GAL/USB/MediaCodec imports, loader/native methods, settings/property operations, services or receivers. It contains only public Activity/TextureView/Canvas/Display logging and Exit. Original native bytes are packaged for extraction/provenance but never loaded; no protocol credentials are included. DEX contains two defined classes, ReceiverActivity and its Exit listener. [Compiled reference check](live-test-02/prototype/build/synthetic-static-check.json).

New APK SHA256 `8F61D8D99C2BE1B745CB4D529DD8806097CECD6B42809E98C68597D8A95D6481`; pulled installed base.apk matches. API22 v1 signer SHA256 `c001f59b25081ddfc73937155ca3580717e817c45c66e68b9e059737b0b28831`, the independent development key used by the original prototype. [Build report](live-test-02/prototype/build/build-report.json), [installed signature](live-test-02/installed-base-signature.txt). Assigned UID10050, ARMv7, codePath `/data/app/com.rdx.fullscreen.projection-1`, nativeLibraryDir `/data/app/com.rdx.fullscreen.projection-1/lib/arm`, no shared UID or requested/granted package permissions. [Package dump](live-test-02/installed-package.stdout.txt).

[App log](live-test-02/running-custom-log.stdout.txt), [running process](live-test-02/running-processes.stdout.txt), [own View hierarchy](live-test-02/running-top.stdout.txt), [window](live-test-02/running-window.stdout.txt), [render screenshot](live-test-02/running-screen.png) jointly establish M1/M2. The picture shows a cyan boundary and synthetic labels across exactly the left1339x720 area; the581px stock B zone remains separate. Its Android Auto “No Device Connected” card is stock UI, not our projection or a phone connection.

**Preserve an API discrepancy:** this app's getRealMetrics reports1339x720 while getRealSize reports1920x720. [Vendor Display.java](../../decompiled/Framework/sources/android/view/Display.java) explains it: getRealMetrics calls getAppMetrics, while getRealSize uses logicalWidth/logicalHeight. Do not interpret the former as physical panel size or assume standard AOSP semantics. No overscan/size/density correction was made.

## M3 safety decision

The old GalReceiver.initialize couples System.loadLibrary with nativeInit, nativeSetCreds and native car info; ProjectionSession adds the video service. It was not used. A new load-only Java method would avoid those explicit calls but **still runs ELF constructors and any dependency startup**.

[Native load-time survey](live-test-02/native-load-initializers.json): unchanged SO SHA256 `031797DD4B0AECCA007A3AD7AF31C365BA3D47BEBDA8C94BFF13C5289F464C50`; no exported JNI_OnLoad; no DT_INIT tag observed. DT_INIT_ARRAY0x1C6EF8, size12, three entries:

| Entry | Relocation / target | Safety status |
| --- | --- | --- |
| 0x1C6EF8 | R_ARM_ABS32→OPENSSL_cpuid_setup; raw slot0 is relocation input, not a null constructor | Actual load-time function, not proof of a GAL session. |
| 0x1C6EFC | R_ARM_RELATIVE→Thumb0xBB359, code0xBB358 | Unnamed startup path not completely audited. |
| 0x1C6F00 | R_ARM_RELATIVE→Thumb0xBBCE9, code0xBBCE8 | Unnamed startup path not completely audited. |

DT_NEEDED: libc,liblog,libm,libstdc++,libstlport,libdl. Transitive initialization also matters. Earlier symbolized direct-call survey does not cover all unnamed/indirect startup behavior; no claim of constructor safety follows from absence of Java_* calls or JNI_OnLoad. Original Java native facades have no automatic library-loading static initializer, but that alone cannot remove ELF initialization. M3 is **deferred, not declared impossible or dangerous**. No probe added, no library code executed, no debugger/injection/alternate loader used. Next offline work is bounded constructor/dependency CFG and side-effect auditing.

## Preservation, side effects and limits

Before/after factory APKs and preserved original all hash `F9E976F44853C9DB7C8FF5A8610C10CAF1E0B4D1E5BE0886F4F52505C5348146`. Both verify with Windriver SHA256 `2156c50e3c08347f28adccb49ae839394053a45767f153bd8f036ae33d5f8568`. Pre-exit, post-exit and post-test full Honda AA package dumps are identical: UID1000, /system/app/AndroidAuto,22/5.1.1-14. Stock PID2440/system_app persisted. We did not install/disable/stop/clear or directly write factory AA.

**Important qualification:** at20:56:08.238, Honda's existing GalService application-start observer reacted to our normal Activity resume and logged `storeShouldAAAutoStartPref: false` / `Another app started, should auto start set to false`. [GalService](../../decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/service/GalService.java) listens for the normal APP_LAUNCHED lifecycle notification; it excludes only AA and Honda launcher, then calls [StartPreferences](../../decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/settings/StartPreferences.java). That method commits gal_should_auto_start=false in gal_start_preferences. A prior false setter is logged at20:54:29.398, before our install, for a navigation Activity. Thus this may be a same-value commit; no prior/post private XML snapshot exists to prove exact data/value equality. This observation contradicts any absolute claim that displaying a separate app leaves all Honda private state untouched. No direct app/agent Honda-data write or lifecycle broadcast was issued, and no attempt to restore/edit that preference was made. Future approvals must explicitly account for these normal OEM observer effects.

Exit-button logs establish onPause, Surface destruction and onDestroy, followed by uninstall Success. Package/path/process and code/private/temp APK entries are absent. Stock application/window/display geometry matches the **post-Diagnostics baseline**, though full window lists and B-zone content naturally differ from task/UI transitions; do not claim byte-identical window dumps. mOverscanScreen(0,0)1339x720, stable[0,0][1339,720], physical1920x720/160dpi remain. Same boot UUID/increasing uptime establishes no reboot.

No agent setting/property writes, system/persistdata writes, remounts, updater calls or privilege changes occurred. Ambient post-exit→post-test properties did change: settings-global version1759→1827 and temperature46→54. Full settings/private-data equality is not established; prior settings-list capability limitation remains. Normal diagnostic mode changes, PackageManager/launcher metadata/logs and stock observer commits are not rolled back by uninstall. Phone functionality was not retested.

Shell→adbd socket ioctl0x5401 AVCs are present during command execution, and proc/maps was denied to shell. There is no captured denial against custom UID10050/untrusted_app for this synthetic path. App GL logged an EGL preserved-swap config retry, then rendered successfully. OEM unauthorized-package/resource/metadata warnings did not prevent launch. Native linker/media/USB access remain unexercised, not “passed.”

## Recommendation

Keep the separate ordinary-app strategy. Next resolve constructor safety and explicitly handle normal OEM lifecycle side effects before a new native-only test. Then design normal USB permission and non-forcing ownership tests independently; do not combine initial GAL/phone/arbitration/decoder experiments. No root or stock-AA replacement is justified by M1/M2.

For that deeper cross-layer review, recommend GPT-6 Astra Medium; GPT-6.1 Sol High remains appropriate for routine bounded collection/build tasks. This is a task-fit judgment consistent with [official OpenAI model-selection guidance](https://developers.openai.com/api/docs/guides/model-selection), not a controlled performance comparison or automatic model switch. Only official OpenAI model guidance was browsed; Honda investigation used local/device evidence.
