# M4 single-port revisions — final artifact safety review, 2026-10-23

Original0.1.0 BAD93C... remains preserved, independently cleared for its original15-sample scope. Single-port vehicle testing required longer duration and retrievable local evidence, explicitly authorized by the user. Original source/manifest/audit pointers were archived in the live session before edits.

**PASS — reviewed passive M4-only revisions:**

| Version | APK under usb-probe/build | SHA256 | Bound |
|---|---|---|---|
|0.1.1-m4-single-port/code2|20261023-170310-355/rdx-usb-probe-0.1.1-m4-single-port-development.apk|74826762D83DF8474FEBF4B2BE73EB8AE58ABEC0390FD4F1A34C819FA8A04EBA|121 samples/120 sleeps|
|0.1.2-m4-single-port-300s/code3|20261023-171136-859/rdx-usb-probe-0.1.2-m4-single-port-300s-development.apk|B09CB40FDE09FA8DAE0C0DED53F8B4019782383682A606FCD12990385672BBF4|301 samples/300 sleeps,1sec per sleep|

Same package/component/action, min21/target22, own test signer c001f59b25081ddfc73937155ca3580717e817c45c66e68b9e059737b0b28831. Fresh v1/API22 signature, zipalign, aapt/ZIP/DEXDUMP/JADX/method-string/source audit PASS for each. Manual review recorded before each install. Automated audit.json's generic manual-review-required marker is resolved by live session single-port-manual-clearance.json and attempt2-manual-clearance.json, not silently treated as full clearance.

No Activity, requested permission, receiver/filter/provider, native library, additional DEX or assets. USB methods remain only getDeviceList/hasPermission/descriptor getters. No requestPermission/openDevice/claim/control/bulk/release/reset, native loading, GAL/TLS/projection, MediaCodec, shell, settings/property/window/Honda modification. Same explicit SNAPSHOT action, START_NOT_STICKY, duplicate suppression, thread cancellation/stopSelf. DEX constants121/120 then301/300 and1000ms inspected. Actual second-revision method-reference set exactly matches first; decompiled diff only changes bounds and version/duration label.

New FileWriter only targets new File(getExternalFilesDir(null),"m4-last-run.txt"); the caller cannot supply a path. It mirrors logs with wall/elapsed timestamps, flushes each line and closes in worker cleanup. No broad storage permission. File IO failures retain logcat fallback. Process-view /storage/emulated/0 differs from shell-view /sdcard on this head unit; normal /sdcard own app directory successfully pulled. No bypass/private Honda access.

Counts bound iterations/sleeps, not a blocked Binder/file operation. No wake lock or sticky restart. A normal Android Service is not the adb shell child; it survived actual ADB cable loss in this session. Second run was explicitly stopped after phone observation, then uninstalled normally.

Raw evidence: ../m4-single-port-20261023-170305-676/, per-build independent audit directories and signature files. [Live results](../M4-LIVE-TEST-RESULTS.md). Runtime PASS applies only to passive visibility, not permission/ownership or any later milestone.
