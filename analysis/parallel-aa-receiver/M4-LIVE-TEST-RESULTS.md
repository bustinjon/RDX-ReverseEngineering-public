# M4 LIVE TEST — PASS, 2026-10-23

**M4 PASS.** Ordinary package com.rdx.fullscreen.usbprobe, UID10049 / u:r:untrusted_app:s0, passively observed the OnePlus13 in accessory mode18D1:2D01, including two interfaces/four bulk endpoints, while hasPermission remained false. The probe remained passive and was removed cleanly. This proves visibility, not permission/openability/ownership or a custom AA session.

No M5, active USB, AOA/GAL/TLS, custom decoder/projection, fullscreen or input milestone was executed. Honda automatically reacted to phone attachment; those normal factory actions are distinguished below. Agent/app issued no display/settings/property/root/Honda-package mutation. The user used the normal car USB-mode UI between ADB and Android Auto; global settings/private Honda data equality is not claimed.

## Device and preserved evidence

Serial **00000000** explicitly selected for all device commands after the initial adb devices -l discovery. Identity: Acura Infotainment System, D.1.6.4, Android5.1.1/API22; fingerprint Acura/gen1CBD_HS/gen1CBD_HS:5.1.1/LMY48P/14:user/release-keys.

Evidence directory: [m4-single-port-20261023-170305-676](m4-single-port-20261023-170305-676/). Each command has timestamped `.command.json`, `.stdout.txt`, `.stderr.txt` with argument vector, exit code and timeout. Raw before/reconnect/final logcats were collected without clearing. Original result files, parsed nested JSON/device CSV, audit/signature/build records and chronological summaries are retained.

Core evidence:

* `attempt1-parsed.json`, `m4-attempt1-result.txt`, `attempt1-summary.json` and correlated timeline.
* `attempt2-parsed.json`, `attempt2-parsed-devices.csv`, `m4-attempt2-result.txt` (326884 bytes).
* `attempt2-system-usb-timeline.txt`, `attempt2-phone-system-identities.txt`, runtime issue excerpt.
* `final-summary.json`, `geometry-comparison.json`, `session-state.json`, `live-validation.json` and evidence hash inventory.

Times below are vehicle/logcat timestamps as printed. Raw wallMs and elapsedRealtime clocks are retained in every sample/result JSON; local formatted time is not substituted for the raw clocks.

## Artifact preparation and clearance

The original cleared0.1.0 APK was verified at SHA256 BAD93C688F7019E4205DC86EF34E6078B695623DB85770C789F29B0A3CFF4148 and preserved unchanged. It samples only15 times/about14 seconds, insufficient for a single-port physical/mode swap. User explicitly authorized the smallest longer-window/result-retention revision. Historical source/manifest/audit pointers were archived before changes.

| Attempt | Version / APK | SHA256 | Scope |
|---|---|---|---|
|1|0.1.1-m4-single-port, code2; usb-probe/build/20261023-170310-355/rdx-usb-probe-0.1.1-m4-single-port-development.apk|74826762D83DF8474FEBF4B2BE73EB8AE58ABEC0390FD4F1A34C819FA8A04EBA|121 samples/120 one-second sleeps, own result file; INCONCLUSIVE timing|
|2|0.1.2-m4-single-port-300s, code3; usb-probe/build/20261023-171136-859/rdx-usb-probe-0.1.2-m4-single-port-300s-development.apk|B09CB40FDE09FA8DAE0C0DED53F8B4019782383682A606FCD12990385672BBF4|301-sample/300-sleep upper bound; PASS; explicitly stopped after190 samples once observation complete|

Package/component unchanged: **com.rdx.fullscreen.usbprobe/.UsbInventoryService**, action **com.rdx.fullscreen.usbprobe.SNAPSHOT**, process:probe. minSdk21/target22, no shared UID, no Activity, requested permissions, intent filters/receivers, assets or native library. Development certificate SHA256 c001f59b25081ddfc73937155ca3580717e817c45c66e68b9e059737b0b28831; API22 v1 signature and zip alignment PASS for both revisions.

Fresh independent JADX, DEXDUMP, packaged manifest, method/string/ZIP audits PASS; manual actual-control-flow review saved. Both revisions have no requestPermission/openDevice/claimInterface/controlTransfer/bulkTransfer/releaseInterface/native load/GAL/TLS/MediaCodec/shell/system mutation. Only USB inventory/hasPermission/descriptor getters occur. START_NOT_STICKY, explicit action, duplicate-start suppression and cancellation retained. Second revision's DEX methods exactly match the reviewed first revision; only loop bounds and version/duration label change.

New evidence file is confined to getExternalFilesDir(null)/m4-last-run.txt, flushed per line, no broad storage permission. Process reported /storage/emulated/0/...; the head-unit shell could not resolve that process-view path, but normal **/sdcard/Android/data/com.rdx.fullscreen.usbprobe/files/m4-last-run.txt** alias was readable/pullable. This was a path-view discrepancy, not lost data or a privilege bypass. Copies were pulled before uninstall.

## Attempt1 — preserved INCONCLUSIVE timing

Started17:05:35.685, PID5924/UID10049/untrusted_app.121 snapshots completed naturally, END17:07:41.910. Probe remained alive across expected ADB loss. It observed baseline devices and the new host root hubs after normal mode selection, but **phone first appeared in system logs17:08:08.400**,26.49sec after probe END. No phone visibility claim can be made from this attempt.

Initial direct result-path pull failed; /sdcard alias succeeded. File139837 bytes, no probe errors. Same boot ID. Honda subsequently switched22D9:2769→18D1:2D01 in system logs, outside M4's window. User was told why the result was inconclusive and explicitly requested a longer repeat. Only one repeat was run; no active USB escalation.

## Attempt2 — PASS timeline

Normal install -r updated ONLY the existing disposable M4 package (same development signer/UID10049). No Honda replacement or permission change. PID7877/untrusted_app. Start17:13:46.678; app codePath /data/app/com.rdx.fullscreen.usbprobe-2, nativeLibraryDir/lib/arm; ordinary HAS_CODE/ALLOW_CLEAR_USER_DATA flags, no system/shared UID.

| Vehicle time | Actor/source | Observation |
|---|---|---|
|17:13:46.678|M4 sample0|Four baseline devices, no phone; own result file active|
|17:13:55.xxx|System/Honda|Normal USB-mode switch brings up bus003/004 host root hubs; factory receivers ignore these as non-phone devices|
|17:13:56.160|M4 sample9|Sees new host root hubs|
|17:14:00.644|UsbHostManager|Phone OnePlus13 at /dev/bus/usb/003/002, **22D9:2769**; factory GalService switches state and processes accessory conversion|
|17:14:00.712|Honda|Normal identity detached while SWITCHING|
|17:14:01.370|UsbHostManager|Phone reappears /003/003 as **18D1:2D01**|
|17:14:01.437 sample start; device line17:14:01.481|M4 sample14|Directly sees /003/00318D1:2D01,2 interfaces,hasPermission=false|
|17:14:21.751|M4 sample33|Last /003/003 observation;20 samples14..33|
|17:14:21.839|Honda/system|Accessory identity detached; exact trigger for this extra cycle not established by M4|
|17:14:22.526|UsbHostManager|Phone appears /003/004 as **22D9:2765**; Honda again enters SWITCHING and processes conversion|
|17:14:22.616–.617|Honda|Normal identity detached|
|17:14:23.279|UsbHostManager|Phone reappears /003/005 as **18D1:2D01**|
|17:14:23.863|M4 sample35|Directly sees new path /003/005, same accessory VID/PID,2 interfaces,hasPermission=false|
|17:16:07.270|M4 sample131|Last phone observation at /003/005;97 samples35..131|
|17:16:08.399|Honda|Phone detach; stateNO_DEVICE after user observation period|
|17:16:15.xxx|System/Honda|Host root hubs removed on normal return to ADB mode|
|17:17:08.461|M4 sample189|Last snapshot; baseline four devices only|
|17:17:09.391|M4 after authorized stopservice|Observation interrupted, then END; file flushed/closed, Service stopped normally|

System phone identity sequence: **22D9:2769→18D1:2D01→22D9:2765→18D1:2D01**. Our1sec sampler missed the brief normal-mode identities and gap at sample34, but directly captured both accessory paths and their disappearance/reappearance. Do not attribute system-only identities to app samples.190 total snapshots;117 phone-bearing snapshots (20+97). Raw final elapsed interval approximately202.7sec; configured300sec maximum was not exhausted because cleanup explicitly stopped our Service after reconnect. Expected interrupt is not a crash.

## Phone descriptors directly observed by ordinary M4

Both accessory paths have VID6353=0x18D1, PID11521=0x2D01, device class/subclass/protocol0/0/0, configurationCount1, interfaceCount2, **hasPermission=false in every phone snapshot**.

| Interface | Alternate | Class/subclass/protocol | Endpoint | Direction | Type | Max packet | Interval |
|---|---|---|---|---|---|---|---|
|0|0|255/255/0|129 (0x81)|128 / IN|2 / bulk|512|0|
|0|0|255/255/0|1 (0x01)|0 / OUT|2 / bulk|512|0|
|1|0|255/66/1|2 (0x02)|0 / OUT|2 / bulk|512|0|
|1|0|255/66/1|130 (0x82)|128 / IN|2 / bulk|512|0|

M4 did not open either interface. Interface1 corresponds to the ADB interface described by system logs; the agent did not connect to the phone's ADB endpoint. The vendor-specific accessory interface0 is visible despite the lack of USB permission. Visibility and descriptor inspection are therefore empirically separate from authorization/ownership on this unit.

Baseline ordinary-app inventory: /001/0011D6B:0002; /002/0011D6B:0003; /001/0020424:2514; /001/003076D:010D. During AA host mode it additionally saw /003/0011D6B:0002 and /004/0011D6B:0003. Root/hub devices class9;076D:010D class2. Raw configuration/interface/endpoint counts and changes for every sample are preserved in JSON/CSV. All observed hasPermission values were false, including baseline devices.

## What each actor did

**Probe:** explicit Service start, passive UsbManager inventory/hasPermission/getters, clocks/logging, own external result file, bounded sleep loop, cancellation/stop. No USB permission request/dialog, open/claim/transfer/AOA/GAL/TLS/decoder or Honda integration call.

**User:** normal car USB-mode selection and physical laptop↔phone swaps; phone connected for the observation interval. These normal mode changes necessarily affect system USB roles; they are not an agent settings/property command.

**Honda/system:** detected phone through UsbHostManager; GalService processed it, entered SWITCHING, then DEVICE_ACCESORY after re-enumeration. A second phone identity cycle occurred; its cause is not proven. M4 did not suppress or compete with Honda. Factory projection/device activity is not a custom receiver milestone.

## Issues and cleanup

No probe RuntimeException/FATAL EXCEPTION/AVC found in captured second-run window. Own evidence survived both cable loss/mode switches. The result-path alias discrepancy is recorded above. The normal stop triggered the expected interrupt/END line. No sticky restart, repeated crash, permission dialog or observed persistent instability.

Honda MD_PackageLocalRepository logged17:13:17.718: non-authorized third-party installation detected for com.rdx.fullscreen.usbprobe. This is an OEM install-detection event, not proof of app remnants. No warning UI/persistence investigation, suppression, whitelist modification, later reboot or preference restoration was attempted.

Stopservice and uninstall returned success. Post-uninstall pm path is empty, package dump empty, process rows0; ls reports no code directories(-1/-2), private data path, app external directory or either temporary pushed APK. No manual file deletion was used. Raw copied evidence remains locally.

Factory AA before/after:

* Full package dumps **identical**; UID1000, versionCode22/versionName5.1.1-14, enabled1, installed/visible/not stopped; /system/app/AndroidAuto/AndroidAuto.apk.
* Before/after/preserved SHA256 **F9E976F44853C9DB7C8FF5A8610C10CAF1E0B4D1E5BE0886F4F52505C5348146**.
* Actual pulled after-copy API22 v1 signature verifies; certificate SHA256 **2156c50e3c08347f28adccb49ae839394053a45767f153bd8f036ae33d5f8568**, same known Honda/Windriver signer. APK byte identity also guarantees the signer did not change.
* Factory process PID2445/system_app persisted. Private preference/data equality is **not claimed**, because normal factory phone interaction occurred.

WindowManager before/after core geometry identical: mOverscanScreen(0,0)1339x720; mRestrictedScreen1920x720; mStable(0,0)-(1339,720); mSystem(0,0)-(1920,720). Full window/activity contents can naturally change with Diagnostics/AA UI; no byte-identical window-list claim. No overscan/size/density command. Same boot UUID and increasing uptime: no reboot during the test.

## Verdict and boundary

**M4 PASS**: an ordinary untrusted_app can see the phone/accessory descriptors and interface endpoints with hasPermission=false, continue observing across ADB disconnection and car mode changes, preserve retrievable evidence, and be removed without changing factory code/package identity or display geometry.

Not established: standard permission dialog success, openability, exclusive ownership/stock competition resolution, our AOA or TLS, custom AA negotiation/video, decoder/fullscreen/TTI. One timing repeat was used, with explicit operator request for a longer window. **No M5 or later step was executed or authorized by this result.** Recommended next milestone is a separately reviewed/authorized M5 one-shot standard permission test, with single-port timing/evidence retention addressed before execution. Stop here.
