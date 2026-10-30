# NEXT LIVE TEST — bounded M4 passive inventory

Updated2026-10-23 after independent audit. **READY FOR BOUNDED LIVE M4 TEST. NOT EXECUTED.** Previous plan is preserved in NEXT-LIVE-TEST-before-20261023-build.md. This plan is not permission to run a connected session without its separate user authorization.

## Scope

Only install/start/stop/uninstall com.rdx.fullscreen.usbprobe, passive inventory and read-only observations. Phone initially disconnected. Phone attachment may activate normal stock Honda AA; our code never requests permission, opens USB, claims interfaces, performs transfers/AOA, initializes GAL or allocates a decoder. No stock disable/clear/force-stop, property/settings/display change, update/factory operation, root or reboot. No grid/decoder/M5/native test in this session.

## Exact reviewed artifact

Project root C:/Users/REDACTED\Desktop\RDX-ReverseEngineering.
APK analysis\parallel-aa-receiver\usb-probe\build\20261023-081948-336\rdx-usb-probe-0.1.0-development.apk.
SHA256 BAD93C688F7019E4205DC86EF34E6078B695623DB85770C789F29B0A3CFF4148.
Signer SHA256 c001f59b25081ddfc73937155ca3580717e817c45c66e68b9e059737b0b28831.
Package/version com.rdx.fullscreen.usbprobe /0.1.0-m4-passive, min21/target22.
Component com.rdx.fullscreen.usbprobe/.UsbInventoryService in :probe.

## Operator procedure — commands below remain documentation only

1. Keep phone disconnected. Obtain explicit session authorization; verify ADB serial by the known vehicle identity, not merely the presence of any Android device. Use Honda's normal supported Diagnostics exit if needed; no lock-task bypass. If ADB disappears, STOP.
2. Set $Serial to the independently verified head-unit serial. Confirm current D.1.6.4/API22 identity in baseline before installation. If wrong/unknown device or unexpected existing test package, STOP.
3. Hash the APK and compare the exact expected value. Capture baseline:

[Code block omitted from public report; see authored source where available.]

The package must be absent before installing; no -r replacement. Baseline script captures factory AA and MaliciousDetector package state, display/window/activity, USB, processes, build properties, uptime and existing logs without clearing. Read the output; do not proceed blindly because a host command exited0.

4. Install only the reviewed APK and verify ordinary UID, package path, version, permissions/components. Do not proceed on any PackageManager error:

[Code block omitted from public report; see authored source where available.]

5. Start the one bounded window. **Connect the Android Auto phone immediately after the Service-start response, preferably within2–3seconds.** Do not launch any test Activity or select another experiment. If this timing cannot be arranged, end this observation and separately start another explicit bounded window; no automatic retry or endless monitoring.

[Code block omitted from public report; see authored source where available.]

6. Let at most15 samples complete (normally about14seconds plus call/log time). Capture logs/process/window/USB with the read-only tool. Confirm RDX.M4 snapshots and END. Stock may query/switch/open/start AA independently; preserve that timeline rather than attempting to take ownership. Seeing only accessory mode is valid; missing original VID during1second sampling is not evidence it never appeared.

[Code block omitted from public report; see authored source where available.]

7. Record own PID/ordinary UID and context from captured output (ps -Z, dynamic own /proc context if readable). Expect untrusted_app based on M0–M2; verify, do not assume. No Activity should resume from this package. APP_LAUNCHED from factory/SystemUI after phone attach is a separate actor.
8. Normally disconnect phone and stop only the probe if still active. Uninstall only the exact package:

[Code block omitted from public report; see authored source where available.]

9. Verify package and :probe process absent, compare factory AA path/version/signer/package state, geometry/overscan evidence and uptime. If readable, inspect recorded app code/data paths; permission-denied is not proof of absence. Do not delete residual paths manually. No preference/history restoration is implied. Hash factory AA via preserved/local read-only collection only if practical; never modify it.
10. Observe detector logs at install/uninstall. On a **later natural vehicle startup**, if a warning appears, record exact wording/time/window owner and normal user Dismiss action. Do not reboot now to provoke it. Successful uninstall and a later warning can coexist; document both.

## PASS and STOP

M4 PASS: actual ordinary-app logs show a nonempty phone or Google accessory inventory consistent with dumpsys usb; descriptors and permission status recorded; no open/request/claim/transfer occurred in our code; bounded END/cleanup completed. hasPermission=false is acceptable. A changing inventory caused by factory AA is acceptable. Empty snapshots alone do not prove phone visibility.

STOP: wrong device/firmware/hash/signer, unexpected existing package, install failure, unexpected probe Activity/permission dialog/native/USB action, crash/AVC/denial requiring escalation, no bounded END, ADB loss, shared system problem, or failed stop/uninstall/verification. Preserve raw logs and do not broaden the experiment. A cached process after stopSelf may persist until normal uninstall; uninstall must remove it. If cleanup fails, no privileged fallback.

## Result report

Record UID/domain, sample count/clocks, each device transition and hasPermission, factory timelines, no-harness-UI evidence, END, package/process removal, factory code identity, separate private-preference/detector observations, and warning uncertainty. Do not claim USB permission, openability, ownership, AOA initiated by us, TLS, video or new Surface geometry from M4.

Next after an actual M4 PASS: analyze ownership timeline and separately authorize M5 permission-only. Independent decoder test remains a separate phone-disconnected session after missing assets are generated and its APK rebuilt/audited. M3 remains deferred; M6 is documentation-only.

## 2026-10-23 clips and clean-foundation continuation

Offline extras are now prepared: decoder0.2 with six clips and independent audit, built/gated M5, and disabled M6/clean-library scaffolding. **No scope expansion: NEXT LIVE SESSION REMAINS M4 ONLY.** Do not add decoder/grid/M5/M6 or MaliciousDetector pulling. M4 APK/service/hash and the operator sequence above remain unchanged. Other artifacts require their own separate authorization/session after relevant prerequisites. GPT-6.1 Sol High remains the requested model for M4.

## 2026-10-23 pure protocol-core continuation

Host-only serialization/state/fake-conversation tests now pass (31 modules,261 deterministic and23059 property assertions). No new receiver APK or live behavior was enabled; all existing APK hashes unchanged. These results do not prove phone compatibility or change this operator procedure. **M4 ONLY remains next; no M5/M6/decoder/grid/native-load/TLS/projection additions.** [Offline results](clean-receiver/PROTOCOL-CORE-RESULTS-20261023.md).
