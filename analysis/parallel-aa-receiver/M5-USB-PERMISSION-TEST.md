> 2026-10-25 future-only kit: [NEXT-CAR-SESSION-CHECKLIST.md](NEXT-CAR-SESSION-CHECKLIST.md). Frozen0.2.0 APK unchanged; no install/ARM occurred. The kit uses DUMP_RESULTS because this APK is not debuggable; raw callback nonce is not stored, and accepted callback/device validation derives from the audited gate. No automatic M6 progression.

# M5 retry — operator procedure (future, not executed)

**Current: M4 PASS; prior M5 INCONCLUSIVE; retry0.2 built/audited READY. A fresh explicit live authorization is required. No M6.**

[Offline validation](M5-RETRY-OFFLINE-VALIDATION.md), [final APK audit](m5-permission/M5-RETRY-INDEPENDENT-AUDIT.md), [unchanged prior live result](M5-LIVE-TEST-RESULTS.md). Previous operator plans are preserved under m5-permission/history/pre-0.2.0-300s/ and earlier historical files.

## Exact artifact and behavior

Package com.rdx.fullscreen.m5permission; version0.2.0-m5-single-port-300s/code3; min21/target22. Component **com.rdx.fullscreen.m5permission/.PermissionService**.

APK `m5-permission/build/20261023-180320-335/rdx-m5-permission-0.2.0-m5-single-port-300s-development.apk`.
SHA256 **A22E96490B9557AFF022893A8B8B7A08BB13CEC236E52704CDDAFA90A8EE8F40**.
Signer SHA256 c001f59b25081ddfc73937155ca3580717e817c45c66e68b9e059737b0b28831.

Five-minute TOTAL armed bound, including callback wait. Target only18D1:2D01. Passive1sec snapshots until unique target, then path/VID/PID pinned and at most ONE requestPermission. Normal22D9:2769/2765 never request. Detach after request ends run; later identity cannot retrigger. No open/claim/release/control/bulk/AOA/GAL/TLS/media/native/system/Honda changes. No Activity, permissions, manifest receivers/intent filters or automatic startup. No default-handler association.

Private journal uses getFilesDir(), not the previous external file. Results are not overwritten, replayed or automatically deleted; max8runs/64KiB each. Retrieve through explicit log dump before uninstall. No private-file shell read/run-as/root/storage permission required.

## 1. Prepare BEFORE arming

Vehicle running, phone disconnected, laptop in ADB mode. Separately authorized operator verifies serial/current baseline and exact package/hash/signature. Never select an unrelated connected device. Factory Honda AA remains normal; preserve display/settings; do not clear logcat or reboot.

Phone unlocked/ready, cable in reach, and normal USB-mode navigation understood/prepared up to the mode selector while leaving ADB working. Confirm user is ready before the start command. **Prior physical/UI workflow took7min42sec after start, longer than even this5min bound.** This APK is not permission to repeat that delay. No automatic restart/rearm if timing is missed.

Future commands ONLY:

[Code block omitted from public report; see authored source where available.]

Verify version3, ordinary UID, no manifest permissions/Activity/native/shared UID. Do not replace/clear another existing package. If M5 already installed, inspect/preserve its results first; do not blindly install over it or uninstall before retrieval.

## 2. Explicit arm, then immediate swap

[Code block omitted from public report; see authored source where available.]

Require the CURRENT run's ARMED + WAITING_FOR_TARGET and ordinary untrusted_app domain. Record wallMs/monoMs; deadline is monoMs+300000 (wall estimate wallMs+300000). Announce exact local deadline using that run's wallMs, not an older log line. No ARMED/no durable file/error means STOP; do not swap blindly. Acknowledgment extra is an operator gate, not independent evidence M4 passed.

Tell user: **SWAP TO PHONE NOW — WATCH THE RDX SCREEN FOR A USB PERMISSION DIALOG.** Stop ADB commands during cable loss. User selects normal Android Auto USB mode, unplugs laptop and connects phone promptly.

## 3. Phone period

Honda may automatically convert22D9 normal identity to18D1:2D01 and run factory AA. M5 only waits for/accesses inventory and requests normal permission once. If a dialog specifically labels **M5 USB permission only**, user may Allow only if the live instruction authorizes it. Never select a permanent/default/always-use option. Do not automate/bypass UI. No prompt alone is not a denial.

Leave connected about60–90sec after connection/grant, within the announced bound. Target appearing at the deadline may be missed by sampling/preparation; no scheduling guarantee. Detach while waiting for callback ends DETACHED without retry. After the explicit observation period, disconnect phone, restore normal ADB mode and reconnect laptop. No second phone run automatically.

## 4. Retrieve PRIVATE evidence after reconnect

Capture non-clearing system/Honda logcat/USB/package/process state first. If M5 is still active, let its announced bound end or explicitly stop only its Service as part of the authorized cleanup. Active-run DUMP commands are deliberately ignored. Partial process-death evidence remains readable; no automatic replay.

[Code block omitted from public report; see authored source where available.]

Use two host terminals with the same verified $Serial/$RunId. In terminal1 start capture BEFORE DUMP (do not clear buffers):

[Code block omitted from public report; see authored source where available.]

In terminal2:

[Code block omitted from public report; see authored source where available.]

After DUMP_END, Ctrl+C only the host logcat capture. Reconstruct offline:

[Code block omitted from public report; see authored source where available.]

Require PASS with exact bytes/SHA256 and a saved text file. Read its terminal state and REQUEST_API_RETURNED/RESULT_RECEIVED. Reserved/invoking intent alone is not proof a framework call returned; partial crash must remain uncertain. If chunks are missing, repeat **DUMP_RESULTS only**, not arm/request/phone testing; private data remains intact. Confirm actual terminal result or documented partial outcome before uninstall. LIST_RESULTS is a separate explicit file-only action if run_id is lost:

[Code block omitted from public report; see authored source where available.]

LIST/DUMP never acquire UsbManager, enumerate or request. They are not a new phone run. No direct adb pull of private files, run-as, chmod or privilege bypass.

## 5. Interpret without conflating visibility/grant/ownership

GRANTED requires callback nonce+same path/VID/PID, EXTRA_PERMISSION_GRANTED=true and current hasPermission=true while device exists. DENIED with a valid requested-device callback is an observed denial, not automatically a permanent platform prohibition. CALLBACK_INCONSISTENT, TIMEOUT, DETACHED, partial/crash or missing target/result are inconclusive unless further evidence demonstrates a boundary. ALREADY_AUTHORIZED means a current grant was observed with zero new requests; report separately from a newly approved dialog. Permission after unplug may vanish; do not use the detached permission map to disprove an earlier recorded grant. No grant proves openability/interface ownership.

## 6. Cleanup and STOP

After successful local retrieval, stop only M5 if needed and uninstall only its package. Uninstall intentionally removes its private journal, so archive first.

[Code block omitted from public report; see authored source where available.]

Verify own package/process/code/normal data absence and factory AA package/APK/display preservation. Observe detector logs without suppressing them. Do not claim private Honda data equality or restore preferences.

STOP on unexpected active USB/device opening/claim/transfer/AOA/GAL/media/system changes, wrong identity, ambiguity, crash/evidence failure, unexpected permission UI/default selection or instability. Do not escalate or retry indefinitely. No M6 even on grant; end the experimental live portion after M5 evidence and cleanup.

No command in this procedure was executed during the offline preparation session. Prior live report is unchanged and remains M5 INCONCLUSIVE.
