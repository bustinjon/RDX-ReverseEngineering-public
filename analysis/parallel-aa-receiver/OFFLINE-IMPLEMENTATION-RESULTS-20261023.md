# READY FOR NEXT CAR SESSION: YES — bounded M4 only

2026-10-23 offline build/audit continuation. Workspace write/create/read/delete PASS. Vehicle disconnected; **no ADB, installation, ARM execution or new live milestone**. Preserved prior research report and all historical raw evidence/notes/factory/Candidate A/B/prototype hashes. Chronological documentation additions do not change historical M0–M2 results or deferred M3.

## Built artifacts

Full absolute paths/components/signatures/audit locations: [build matrix](BUILD-VALIDATION-MATRIX.md), [machine-readable matrix](BUILD-VALIDATION-MATRIX.json).

| Artifact | Latest reviewed build | SHA256 | Result |
|---|---|---|---|
| M4 | usb-probe/build/20261023-081948-336/rdx-usb-probe-0.1.0-development.apk | BAD93C688F7019E4205DC86EF34E6078B695623DB85770C789F29B0A3CFF4148 | Existing APK unchanged; READY FOR BOUNDED LIVE M4 TEST |
| Grid | grid-test/build/20261023-103955-076/rdx-grid-test-0.1.0-development.apk | 24843A11B417B20F37D33C9FB269007A9F69158E39D27882E67CEAFBF33B7214 | Built; independent static PASS; separate geometry test |
| Decoder | decoder-test/build/20261023-104441-074/rdx-decoder-test-0.1.0-development.apk | A9509D00E312725F0062292950F513FF44BD9D5AB3C38C4B9A6B864397504B05 | Built; independent static PASS; NO CLIPS, not ready for decoding |

All min21/target22, no shared UID, permissions, filters or native libraries. Development signer SHA256 c001f59b25081ddfc73937155ca3580717e817c45c66e68b9e059737b0b28831. V1/API22 signature verification and zip alignment PASS. aapt actual packaged manifest, JADX decompilation, independent SDK DEXDUMP, complete DEX reference/string/class inventories, current-source hashes and manual control-flow review recorded. Static pass does not prove device runtime behavior. Neither visual harness is included in the next M4 test.

## M4 clearance

[Independent audit](usb-probe/M4-INDEPENDENT-AUDIT.md): exact package com.rdx.fullscreen.usbprobe, version0.1.0-m4-passive. One Service com.rdx.fullscreen.usbprobe/.UsbInventoryService, :probe process; no Activity, native library/support library, receiver or boot/USB/package filter. Prohibited methods/strings absent: openDevice, requestPermission, claimInterface, controlTransfer, bulkTransfer, releaseInterface, System.load/loadLibrary, MediaCodec, GAL/socket/protocol, Runtime.exec, ProcessBuilder, su/Shizuku, wm/overscan/size/density, settings put, setprop, reboot, force-stop, pm clear or Honda package-control code. No unexpected generated behavior; two Java classes with normal synthetic accessors.

Allowed references are enumeration, hasPermission and descriptors, own-process runtime metadata, logging, clocks, finite Java iteration/threading and Service lifecycle. Manual source/final-DEX comparison confirms15 iterations, at most14x1000ms sleeps, duplicate-start suppression, cancellation, END/stopSelf, return2 START_NOT_STICKY. A blocked Binder call is not forcibly time-limited by iteration count.

Exact future start command (not executed):

[Code block omitted from public report; see authored source where available.]

M4 PASS requires actual app descriptor logs showing the phone/accessory inventory under ordinary UID/context, with bounded END and clean own-package removal. hasPermission=false is valid. Empty snapshots do not prove phone visibility. Wrong target/hash/identity, install failure, unexpected UI/permission/transport, crash/denial, ADB loss, missing END or failed cleanup means STOP and preserve evidence; no privileged fallback.

## Visual harnesses

Grid renders actual Surface/view/window and app/physical display metrics;100px divisions,0–1900labels, emphasized1338/1339/1919, y labels, density/xdpi/ydpi/orientation/Hz. No global display changes. Activity resumes can still trigger Honda's known private preference setter.

Decoder's explicit one-clip START requests OMX.TI.DUCATI1.VIDEO.DECODER only, never software fallback. Stable-Surface start gating, no concurrent decoder, cancellation/cleanup,2ms dequeue waits,20sec pump and25sec watchdog. Binder configure/release can still hang beyond those guards; shared-media errors are STOP, never media-service kill/restart/reboot. Logs input/output formats, PTS/flags/bytes, queue/receive/release counts and duration. Format keys absent on API22 are unavailable; no displayed-frame/FPS claim from released counts.

All six clips absent:1280x720/30,1280x688/60,1920x720/30,1920x720/60,1920x1080/30,1920x1080/60. FFmpeg/ffprobe not found; no download/system install. Reproducible generation script prepared with fixed testsrc/grid/labels, baseline/no-B/yuv420p/fixed GOP, hash/ffprobe/SPS traces; not executed. Generate/inspect then rebuild/re-audit. First fullscreen-relevant raster remains1920x720/30; protocol margins/SPS/crop/touch unresolved and historical Candidate A/B untouched.

## Capture tooling

scripts/Capture-RdxBoundedBaseline.ps1 is new, explicit serial and allowlisted test package, targeted read-only plan. Captures22 baseline commands plus dynamic own-process status/context if available; timestamp/stdout/stderr/exit/timeout, no log clearing. Process timeout kills only the host adb client. PlanOnly run recorded locally without launching ADB. Source/control-flow and plan allowlist reviewed;7 new PowerShell scripts parsed. Missing/denied observations are evidence, not escalation triggers. See offline-implementation-validation.json.

## Unauthorized-app finding

[Detailed warning report](HONDA-UNAUTHORIZED-APP-WARNING.md). HIGH confidence detection owner com.honda.maliciousdetector, historical UID10023/platform_app, `/system/app/MaliciousDetector/MaliciousDetector.apk`, version5.1.1-168/code22. MDBroadcastReceiver registered for package scheme and BOOT_COMPLETED, MDService present/running. Runtime scan log names the custom package at installation; this preceded the reported later warning.

Exact warning UI class/resource, authorized-app predicate/certificate whitelist, history storage, uninstall handler and Dismiss code remain UNKNOWN.136 local APK/JAR archives searched, no detector/message hit; one zero-byte corrupt JAR recorded. Missing detector APK is the narrow collection gap. Detection owner does not conclusively prove dialog owner. User-reported one-time warning after uninstall is consistent with historical/queued warning or acknowledgment but not code-confirmed. It does not prove APK remnants. Future checks separate package/process/path removal from OEM logs/history and later natural-startup UI; no bypass or state restoration.

## Progression

M5 source/design completed and Java compilation checked; no APK. Exact device/intent/M4 acknowledgment gate, one permission request and verified result,45sec timeout, no open/transfer/default handler. Permission UI can resume SystemUI and cause Honda effects. Gate acknowledgment cannot prove M4 success; separate approval/build/audit required.

M6 documentation only; no active AOA implementation. Stock may react to re-enumeration even if our tool never starts AA. auto-start=false is UI/resumption policy, not transport disable. M4 may see original descriptors disappear/accessory descriptors appear through factory actions; observe, do not compete. No stock suppression needed for passive observation.

Clean ordinary receiver remains preferred; no new evidence makes proprietary-native reuse more attractive. M3 stays deferred/off critical path. No protocol credentials were included. Next model: GPT-6.1 Sol High as requested for the bounded operator/log-analysis task.

## Roadmap

| Stage | Status |
|---|---|
| DONE | Historical M0–M2; existing M4 independent audit; grid/decoder builds; capture script; warning detector identification; docs and preservation validation |
| NOW | Bounded M4 package ready; decoder assets still missing |
| NEXT | Separately authorized M4 passive observation, then review and M5; independent decoder session only after assets/rebuild |
| LATER | Gated M6, ownership, TLS/discovery, conservative video, active1920x720, separately full Surface, then TTI |
