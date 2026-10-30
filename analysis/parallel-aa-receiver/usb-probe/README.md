# RDX M4 passive USB probe

Version0.1.0-m4-passive, com.rdx.fullscreen.usbprobe. **READY FOR BOUNDED LIVE M4 TEST**, no new vehicle result. Start/cleanup/PASS/STOP procedure: [M4 test](../M4-USB-VISIBILITY-TEST.md), [operator plan](../NEXT-LIVE-TEST.md). Actual final-artifact evidence and prohibited-API table: [independent audit](M4-INDEPENDENT-AUDIT.md).

Only manifest and two-class DEX plus signatures are packaged. No permissions, Activity, receiver/filter, native library, credentials or automatic start. Service action SNAPSHOT is explicit; maximum15 samples/14 sleeps; START_NOT_STICKY; duplicate starts are ignored. Source is locally authored, not copied from Open Headunit.

APK path/hash/signer are in [build matrix](../BUILD-VALIDATION-MATRIX.md); latest-build.txt still identifies the original existing build, audited without rebuilding. latest-audit.txt identifies successful independent evidence. Rebuild only if source changes: `scripts/Build-RdxBoundedHarness.ps1 -Harness usb-probe`, then independently audit the new APK; old clearance does not transfer by filename. Neither command calls ADB.

## 2026-10-23 actual single-port live test

**M4 PASS**, own package uninstalled. The original build/source description above is historical and its APK remains unchanged. With explicit user authorization the source/manifest were revised for120sec then300sec bounded cable-swap windows and a tiny own external result file. Latest source/build/audit now identify0.1.2-m4-single-port-300s/code3, SHA256 B09CB40FDE09FA8DAE0C0DED53F8B4019782383682A606FCD12990385672BBF4. Only passive inventory and own-file logging; no permissions/Activity/active USB/native/media/system behavior. [Revision audits](M4-SINGLE-PORT-AUDIT.md), [live results](../M4-LIVE-TEST-RESULTS.md).

UID10049/untrusted_app observed phone18D1:2D01 at successive paths,2 interfaces/four endpoints andhasPermission=false. Initial120sec run missed phone timing; one user-requested longer repeat succeeded. Source history/raw evidence preserved. No automatic next milestone; M5 needs offline single-port review and separate authorization.
