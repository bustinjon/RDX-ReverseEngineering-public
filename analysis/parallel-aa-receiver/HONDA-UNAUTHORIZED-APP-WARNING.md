# Honda unauthorized-app warning — offline findings 2026-10-23

## Observation and conclusion

User reports a later vehicle startup displayed **"Non authorized by Honda application(s) detected"**, or very close wording, after the disposable APK had already been uninstalled and cleanup had shown package/process/code/data absent. Dismiss was pressed; the following startup had no warning. This is user-observed evidence, not a new session performed here. Exact dialog text/resource ID is not locally verified.

**Installation detector owner is identified with HIGH confidence:** `com.honda.maliciousdetector`. Exact warning-dialog owner/class remains **unresolved**; it may be this package or a UI it requests. Do not label the dialog itself proven merely from the detector tag.

## Evidence

Saved Live Test02 `after-exit-processes.stdout.txt` and `post-processes.stdout.txt` identify PID4293 as `com.honda.maliciousdetector`, UID10023, `u:r:platform_app:s0`. PID is historical only, not for reuse.

`live-test-02/post-logcat.stdout.txt:874`: ActivityManager starts PID4293 for broadcast `com.honda.maliciousdetector/.service.MDBroadcastReceiver`.
Line978 references `.service.MDService`. Line45964 at20:55:54.294:

> MD_PackageLocalRepository: Non-authorized third party package installed detected (runtime scan): com.rdx.fullscreen.projection

Live Test01 similarly records detection at20:36:07.274. Detection happened while the APK was installed and does not require a later leftover APK to explain the historical event. The logger identifies a repository class/tag, not enough information to reconstruct its full Java namespace or authorization predicate.

`adb/RDX-Audit/logs/dumpsys-package-full.txt:10359` gives:

- `/system/app/MaliciousDetector/MaliciousDetector.apk` (resolved separately in `packages-with-paths.txt`).
- VersionCode22, versionName5.1.1-168, target22, SYSTEM/HAS_CODE.
- Private directory `/data/data/com.honda.maliciousdetector` (existence of dataDir metadata does not prove a particular persisted flag).
- Permissions SYSTEM_ALERT_WINDOW, RECEIVE_BOOT_COMPLETED, WAKE_LOCK, DELETE_PACKAGES.
- Receiver resolver contains MDBroadcastReceiver under package data scheme and BOOT_COMPLETED.
- Service is already running in historical dumpsys activity.

These support install/package-event and startup participation. They do **not** prove exact PACKAGE_ADDED/PACKAGE_REMOVED branching, automatic deletion, or that any deletion actually occurred. The granted DELETE_PACKAGES permission is capability evidence only. Signing keyset1/signature identifier in PackageManager describes the detector's identity, not its trusted-app policy.

## Local artifact coverage

`scripts/Scan-RdxWarningArtifacts.ps1` searched136 local APK/JAR archives under adb/apks, including UTF8/UTF16 views of DEX/resources. `warning-evidence/archive-search.json` preserves paths/hashes/hits/errors. No exact/approximate warning/detector string hit was found. One existing zero-byte `com.honda.auto.ampvcs.ext.jar` is not a valid archive and is recorded as an error. Decompiled Java/XML and saved logs were searched as well. RDX-Audit.zip/RDX-Dump.zip entry inventories were checked for MaliciousDetector; its APK is absent there and in extracted local files. This is a collection gap, not proof no implementation exists.

Search variants: non-authorized/non authorized, not authorized by Honda, unauthorized application, application(s) detected, authorized by Honda, MD_PackageLocalRepository, com.honda.maliciousdetector; broader decompiled signature/certificate/package-manager references are contextual, not accepted as the warning's authorization logic.

## Questions still unresolved

| Question | Evidence-based answer |
|---|---|
| Exact dialog owner/class/resource ID | Unknown; detector package is strongest lead |
| Detection trigger | Runtime scan at installation observed; package-scheme and boot receiver registered |
| Authorization definition | Unknown: no demonstrated signer/package/system/location/installer whitelist predicate |
| Trusted certificate / Wind River check | Unknown; do not infer from the detected APK being development-signed |
| Persistence storage | Unknown: could be event/history, preference/database, UI acknowledgment or retained process state |
| Must package remain installed to show warning? | User observation says warning occurred after verified uninstall; exact display predicate untraced |
| Dismiss | Observed warning ceased next startup; exact callback/state mutation untraced |
| Does uninstall clear current detection/history? | Own package removal proved previously; OEM history/queued state clearance not established |
| Does one-time behavior match code? | Plausible and consistent with historical detection, but code confirmation unavailable |
| Does warning prove remnants? | **No**; it cannot overturn package/process/path absence evidence by itself |

## Narrow future read-only collection

When separately authorized and connected, resolve `pm path com.honda.maliciousdetector`, dump that package, pull its complete readable package directory, and capture public process/log/activity state. The known path is a lead, not a substitute for resolving the current active path. No private-data bypass, service invocation, warning trigger, settings mutation or whitelist change. Static analysis of that APK would resolve the precise predicates/resource/Dismiss handler if present. No live collection performed now.

## Implications

Every new normal test APK may produce another detection event/warning even after successful uninstall. Headless M4 avoids the identified Activity-resume trigger but **does not avoid package-install detection**. This plan accepts observation, not suppression. Future cleanup must report package/path/process absence separately from detector logs and later natural-startup UI observations. Record timestamps/install/uninstall/Dismiss and the exact visible wording if encountered; do not intentionally reboot or modify acknowledgment/history. Do not restore Honda AA preferences automatically.

## 2026-10-23 clips and clean-foundation continuation

No new detector code or runtime state was acquired. Exact future resolve/dump/pull/hash/public-signer/log commands are in MALICIOUS-DETECTOR-READONLY-ACQUISITION.md. This is a **separately authorized later collection**, not part of next M4. Target historical path remains /system/app/MaliciousDetector/MaliciousDetector.apk, package com.honda.maliciousdetector; resolve active path first. Installation detection owner is known, but precise warning UI, authorization predicate and acknowledgment storage remain unresolved. No whitelist/signature/warning bypass or private-state mutation was implemented.

## 2026-10-23 M5 installation observation — no new detector acquisition

Saved live logs now independently show at17:35:05.686 PID4194 MD_PackageLocalRepository: `Non-authorized third party package installed detected (runtime scan): com.rdx.fullscreen.m5permission`. Own M5 package was later uninstalled and its code/process/private/external paths verified absent. This corroborates runtime installation detection, not persistent warning/UI/Dismiss logic. No warning appearance was reported during this M5 attempt; no reboot was performed to provoke one. Detector APK was not pulled in this session, so authorization predicate and acknowledgment storage remain unresolved. No bypass/suppression/reset/whitelist edit or detector service invocation occurred. See M5-LIVE-TEST-RESULTS.md and m5-live-20261023-173401-872/final-validation.json.
