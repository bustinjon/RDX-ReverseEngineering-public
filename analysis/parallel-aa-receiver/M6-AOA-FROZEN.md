# M6 AOA-only frozen artifact — LIVE DISABLED

**OFFLINE-PREPARED / LIVE-DISABLED. NEXT LIVE M5 RETRY ONLY.**

|Field|Frozen value|
|---|---|
|APK|`m6-aoa/build/FINAL/rdx-m6-aoa-only-disabled.apk`|
|SHA256|D4DAC2DD8B2AFF1FA7B64BFB32D2A5E889854CCEB4B4A9F7AD5AEF89FB28761F|
|DEX|21E02321DBA74E245FD863EC56D45A3DF3A76C622B6BF683249EB12961B5C0B1|
|Package/version/code|com.rdx.fullscreen.m6aoa /0.1.0-m6-aoa-only-frozen /1|
|min/target SDK|22/22;Java7;D8min22|
|Signer/reviewer public-cert SHA256|C001F59B25081DDFC73937155CA3580717E817C45C66E68B9E059737B0B28831 — independent development identity, not Honda|
|Permissions|ZERO;no shared UID, default USB association or boot receiver|
|Component|One exported `.M6AoaService`, explicit ARM only;debuggable/testOnly=true,allowBackup=false|
|Scope|9 modules/19 classes;137 saved API22 references resolve;no Android runtime execution|
|Host suite|392 checks/9304615 assertions;50000 sequences;62 transcripts;seed5563706198314856497|

`LiveExecutionPolicy.requireReviewedActivation()` is compiled into an unconditional SecurityException throw. It gates Service ARM before manager lookup/private-proof processing/receiver/worker and independently gates every adapter inventory/permission/open/transfer operation. There is no intent, debug, boolean, environment, force or build parameter that activates this frozen release. The build script refuses EXECUTION_ENABLED=true. Do not install this APK on the vehicle as a live M6 test.

Underlying future transfer glue is audited: getDeviceList/hasPermission; one standard own-package requestPermission if needed; one normal-target openDevice after permission; only requests51/52/53; close. Max8 controls/1 START; no accessory-mode open. Three actual DEX callsites have fixed type/code/value/timeouts. No claim/release/forceClaim/bulk/reset/audio/AA/GAL/TLS/MediaCodec/Honda JNI/socket/shell/settings/WM path exists.

After a genuine reviewed M5 PASS, prepare canonical signed metadata using future `tools/m6/New-M5ReviewedProof.ps1`; it requires the actual journal in a ZIP with matching frozen/live retrieval session identity. No live PASS was fabricated. Production trusts only the pinned project reviewer public certificate, validates signature/strict fields/bundle SHA256 and rejects synthetic provenance. This is milestone-review evidence, not USB permission or M6 authorization. The frozen code still refuses even a valid proof.

Future execution would require **all**: M5 PASS reviewed → inspect this audit/permission strategy and stock race → separately authorized small activation release/version/hash/audit review → explicit M6-only authorization/ARM → fresh M6-UID exact-attachment permission. No override or automatic progression is supplied. [Future checklist](M6-FUTURE-LIVE-CHECKLIST.md).

[Machine freeze](m6-aoa/FROZEN.json) pins the second build and static audit. [Reproducibility](m6-aoa/reproducibility.json) verifies two final clean builds, exact DEX/classes/JAR/APK payloads and transcripts; archive metadata differences documented. Frozen M5 A22E…8F40, receiver2FDBC…C235, API22 qualifier863501…FC1F,69 original APKs and M4/M5 live reports remain untouched.
