# M5 independent APK audit — 2026-10-23

**PASS STATIC — BUILT BUT DO NOT RUN BEFORE LIVE M4 PASS AND SEPARATE M5 AUTHORIZATION.** No permission request or installation occurred here.

APK `build/20261023-112129-849/rdx-m5-permission-0.1.0-M4-PASS-REQUIRED-development.apk`.
SHA256 `757726DE360D466ACE5F7C12A90DE5B4377F2BD19D8D4BD8C13879967FDE95C8`.
Package com.rdx.fullscreen.m5permission; min21/target22; versionCode1/versionName0.1.0-M4-PASS-REQUIRED.
Development signer SHA256 c001f59b25081ddfc73937155ca3580717e817c45c66e68b9e059737b0b28831; API22 v1 signature and zipalign PASS.

Final manifest: one exported headless .PermissionService, no Activity, permissions, shared UID, receiver/filter, native library or assets. Dynamic receiver exists only for its own callback while Service is active. No USB attach/boot/package filter, default handler or sticky restart. DEX defines Service/timer/result receiver classes and normal synthetic accessors only. Independent aapt/JADX/SDK DEXDUMP and complete reference/string/class inventories PASS; actual decompiled behavior manually compared to source.

| API/behavior | Final APK |
|---|---|
| getDeviceList / hasPermission | PRESENT |
| requestPermission | PRESENT — exactly one call site behind all gates |
| openDevice / claimInterface / releaseInterface | ABSENT |
| controlTransfer / bulkTransfer / AOA requests | ABSENT |
| GAL / AA / decoder / native receiver | ABSENT |
| Root / shell execution / Honda manipulation | ABSENT |
| Auto-start intent filters | ABSENT |

onStartCommand requires action REQUEST_ONCE_AFTER_M4_PASS, m4_pass_confirmed=true, exact device_name, vendor_id and product_id found in the current inventory. Wrong/missing gate or mismatched identity stops before request. Already-granted permission ends without requesting. Active duplicate requests are ignored; attempted latch prevents another request during the same Service lifetime. One-shot package-targeted PendingIntent uses a nonce, and result verifies device path/VID/PID plus hasPermission. Timeout45sec, non-sticky return, no retry. onDestroy cancels PendingIntent, unregisters callback and removes timers. Runtime exception from request logs STOP.

Operator acknowledgment is not automatic evidence that M4 passed. SystemUI may resume and update platform/OEM state; stopping Service/canceling PendingIntent does not necessarily dismiss a permission dialog already shown or undo a later grant. No claim of lifecycle neutrality or rollback of Honda history/defaults. Actual normal permission availability on this build and lock-task UI behavior remain live questions. See M5-USB-PERMISSION-TEST.md; do not include M5 in the next M4 session.
