# M5 frozen USB-permission retry — 2026-10-25

**M5 INCONCLUSIVE — STOPPED FOR REVIEW. M6 REMAINS DISABLED.**

One normal permission request reached Android and returned. Android attempted to launch SystemUI's UsbPermissionActivity, but **Diagnostics lock-task mode rejected the launch**. No callback arrived before the selected USB device disappeared during re-enumeration. The app correctly terminated DETACHED without retrying. M5 was normally uninstalled after evidence retrieval/hash verification. No detector cleanup or modification, M6/M7, or further live test was performed.

This is a new result, distinct from [original timing-INCONCLUSIVE M5](M5-LIVE-TEST-RESULTS.md), which remains unchanged. In this retry the target was seen16.753seconds after arming; the previous “phone arrived after timeout” problem did not recur. This run establishes ordinary-app visibility, one returned permission API call and an attempted framework permission-dialog launch. It does **not** establish permission grant/denial or satisfy M5 PASS.

## Authorization, identity and artifact

The user explicitly authorized M5 RETRY ONLY and confirmed physical readiness before ARM. Laptop/phone shared one port. No ADB commands were issued during the phone interval; after the user reported laptop reconnection, retrieval preceded uninstall. User reports: regular Honda Android Auto opened; **no permission prompt** appeared; no manual ALLOW/default selection occurred.

|Property|Recorded|
|---|---|
|Vehicle|Serial00000000; Android5.1.1/API22/ARMv7; fingerprintAcura/gen1CBD_HS/gen1CBD_HS:5.1.1/LMY48P/14:user/release-keys|
|Package/service|com.rdx.fullscreen.m5permission /.PermissionService|
|Version/code|min21/target22;0.2.0-m5-single-port-300s /3|
|Frozen APK|m5-permission/build/20261023-180320-335/rdx-m5-permission-0.2.0-m5-single-port-300s-development.apk|
|SHA256|A22E96490B9557AFF022893A8B8B7A08BB13CEC236E52704CDDAFA90A8EE8F40|
|Signer certificate SHA256|C001F59B25081DDFC73937155CA3580717E817C45C66E68B9E059737B0B28831; ordinary development signer, no Honda signing material|
|Runtime|UID10049 /PID8902 /u:r:untrusted_app:s0|
|Run|m5_270c93bb178648759beda65ed9593e72|
|Final app state|DETACHED; SERVICE_END; no replay/reselection/retry|

The installed APK had been independently pulled and byte-matched to the frozen artifact during phone-free checks. Source/APK were not rebuilt or modified. Static clearance remains one SDK requestPermission callsite and no openDevice/claim/release/control/bulk/AOA/GAL/TLS/decoder/settings/Honda-control code.

## Exact timeline

UTC below is derived from the app's saved wallMs. Logcat prints the corresponding19:31 local labels. Relative app timing uses saved monotonic milliseconds, avoiding timezone assumptions.

|Event|UTC /raw monotonic|Meaning|
|---|---|---|
|Host ARM invocation|23:31:12.881Z|One reviewed service invocation; operator readiness already confirmed|
|App ARMED +WAITING_FOR_TARGET|23:31:13.878Z /3050211|300000ms maximum window; durable journal synced|
|Normal phone in system log|19:31:29.257 logcat|22D9:2769 /dev/bus/usb/003/002; brief phase not sampled by M5|
|First accessory in system log|19:31:29.971 logcat|18D1:2D01 /dev/bus/usb/003/003|
|M5 TARGET_SEEN|23:31:30.631Z /3066964|16.753s after ARMED; pinned /003/003, hasPermission=false|
|SDK invocation intent|23:31:30.658Z /3066991|One request reserved durably and invoked|
|SystemUI launch attempted|19:31:30.671 logcat|START UsbPermissionActivity from system UID1000|
|Lock-task violation|19:31:30.682 logcat|ActivityManager rejects UsbPermissionActivity|
|SDK returned|23:31:30.683Z /3067016|25ms after invocation-intent record; no grant implied|
|Diagnostics exits lock task|19:31:32.577 logcat|dealer.Main.finish /stopLockTaskMode;1.895s after rejected launch|
|Pinned device gone /DETACHED_AFTER_REQUEST|23:31:50.602Z /3086935|19.971s after target selection; terminal, no retry|
|SERVICE_END|23:31:50.644Z /3086978|36.767s after ARMED by monotonic clock; run ended early on detach, not300s timeout|
|Later identities, system only|19:31:50.762 then19:31:51.626|22D9:2765 /003/004 →18D1:2D01 /003/005; M5 already terminal|

The observed system sequence is22D9:2769→18D1:2D01→22D9:2765→18D1:2D01, consistent with prior stock switching observations. The user kept the phone connected and reported normal AA. “DETACHED” refers to the selected USB enumeration disappearing; it does not assert the operator physically unplugged at19:31:50. M5 issued no accessory-switch request. Stock Honda AA activity is separate from this permission-only app.

## Permission result and exact blocker

- REQUEST_API_INVOKING=1; REQUEST_API_RETURNED=1; accepted callbacks=0; rejected callbacks=0.
- Target identity/path were pinned correctly. Callback nonce/device/grant validation was **not exercised**, because no callback arrived. Raw nonce is not stored by the frozen APK.
- hasPermission wasfalse on target selection. No callback verifiedtrue. Later heartbeat lines repeat the originally pinned identity; they must not be mistaken for proof of a fresh final permission measurement. Final grant outcome is **unproven**, not a recorded denial.
- User saw no standard dialog and performed no ALLOW/default-handler action, consistent with the logged Activity launch rejection.

Direct runtime evidence:

[Code block omitted from public report; see authored source where available.]

The saved UsbSettingsManager.requestPermissionDialog implementation supports this call chain: validate caller package/UID, create a SystemUI USB-permission Intent and request Activity launch. That saved framework source is corroborating static evidence, not an assertion of binary parity with live build14. The **actual live ActivityManager log** establishes this run's UI rejection.

The pre-arm phone-free readiness assessment was incomplete: Diagnostics/USBModeSwitchActivity was still the foreground diagnostic task, and prior live02 already documented its lock-task restriction. I should have checked that known constraint before arming. No missing prompt is attributed to user inaction. There is no evidence here that Honda's unauthorized-app detector blocked the permission API.

## Evidence retrieval and preservation before uninstall

Evidence directory: [m5-live-retry-20261025-185128](m5-live-retry-20261025-185128/). System logcat was saved **before** DUMP_RESULTS. The frozen app then exported its own private journal through the explicitly non-arming dump path; no run-as/private-data bypass was used.

- [Reconstructed journal](m5-live-retry-20261025-185128/reconstructed/m5-m5_270c93bb178648759beda65ed9593e72-45b32906-b1b2-494f-abdd-02148f6769a2.txt):3926bytes; dump token/chunks/length/SHA256 verified.
- Journal SHA256: **138F02161E79536D3C7D6F0D671D9253F8573D89881A2B1BD27B2A937D1E67AF**.
- [Pre-uninstall preservation](m5-live-retry-20261025-185128/pre-uninstall-preservation.json):241 retained files hashed and verified before uninstall. Mutable session/command-log files subsequently advance normally; this inventory records that point in time.
- [Raw reconnect logcat](m5-live-retry-20261025-185128/reconnect-logcat.txt), earlier before-dump captures, [parsed app events](m5-live-retry-20261025-185128/journal-events.json), [redacted UI/USB excerpt](m5-live-retry-20261025-185128/focused-ui-usb-timeline-redacted.txt), [user observations](m5-live-retry-20261025-185128/user-observations.json).
- [Final validation](m5-live-retry-20261025-185128/final-validation.json), [file inventory](m5-live-retry-20261025-185128/FILE-INVENTORY.csv), [hash manifest](m5-live-retry-20261025-185128/SHA256-MANIFEST.json), [session seal](m5-live-retry-20261025-185128/SEAL.json).

Exact command argument vectors, explicit vehicle serial, timestamps, stdout/stderr and exit/timeout records are retained. Early ADB startup/enumeration failures and corrected host-only inventory/parser diagnostics remain distinguishable from the successful permission run. No log buffer was cleared. Raw logs include phone identifiers; the narrative/redacted excerpt omit the serial. This is a local evidence bundle, not a redacted publication export.

## Normal uninstall and final preservation

After retrieval/reconstruction/hash verification, normal uninstall of **only com.rdx.fullscreen.m5permission** succeeded, without-k. The prior Service had ended naturally; cleanup stopservice did not restart it. Final pm path/dumpsys are empty; package absent from-u list; process absent. Exact original code directory, private-data directory and own external path all report No such file or directory. No manual file deletion or detector operation occurred.

All seven project names are absent in the final normal PackageManager inventory. No M6/qualifier/receiver/decoder APK was installed. [Final project package table](m5-live-retry-20261025-185128/final-project-package-status.json).

Factory AA packagecom.honda.androidauto.projection.sink stays at/system/app/AndroidAuto/AndroidAuto.apk, code22/version5.1.1-14. Before/after APK SHA256 **F9E976F44853C9DB7C8FF5A8610C10CAF1E0B4D1E5BE0886F4F52505C5348146**, signer and wm-size compare equal. Supplemental final density160 and window stable geometry match: mOverscanScreen=(0,0)1339x720; mRestrictedScreen=(0,0)1920x720; mStable=(0,0)-(1339,720); mSystem=(0,0)-(1920,720). Boot UUID4f995fac-e0d5-42d7-b566-bf9ee04c11f7 unchanged. Private Honda data equality is **not claimed**; stock AA ran independently following phone connection.

Frozen M5 hash remains A22E…8F40, frozen disabled M6 D4DAC2DD8B2AFF1FA7B64BFB32D2A5E889854CCEB4B4A9F7AD5AEF89FB28761F and receiver DEX2FDBC63F2F9D63B764697D311AF89D460AE6B8E14B0FADABA9C9339F7FE7C235 preserved. Original M4/M5 reports/historical APKs preserved by the project integrity check.

## Stop and next review

**No further live action is authorized.** No M5 repeat, detector cleanup/change, M6/M7, custom device open/claim/control/bulk/AOA/GAL/phone TLS/MediaCodec, display/settings mutation, default-handler selection, root, factory package control/data clear or reboot occurred. Normal Honda/phone AA behavior is not claimed as our protocol/decoder result.

Next recommended step is an **offline review of the pre-arm Diagnostics/lock-task gate and single-port UI choreography**. Prior live02 established that supported normal RETURN navigation can leave Diagnostics while ADB remains available; any future retry must verify that condition **before** arming/phone arrival. Do not use a lock-task bypass or manipulate factory components. No script/source/APK activation or new test was implemented/executed here. A later M5-only retry would require separate authorization. M5's timer length is not the demonstrated blocker now.

**M5 INCONCLUSIVE — STOPPED FOR REVIEW. M6 REMAINS DISABLED.**
