# Disposable harness safety and cleanup — 2026-10-23

All commands below are **future documentation**, not commands executed this offline session. No vehicle/ADB operation, installation, ARM execution or new live milestone occurred.

Use explicit independently verified head-unit serial and check D.1.6.4 identity before installation. Stop if a package is unexpectedly already present; do not replace it using -r. Verify APK hash/signer against BUILD-VALIDATION-MATRIX.md and use exactly one harness per bounded experiment. APK signing is local development signing, never Honda signing. min21/target22/v1 JAR verified for API22; no shared UID, permissions or native libraries in the three built APKs.

| Package | Entry | Future cleanup | Clearance |
|---|---|---|---|
| com.rdx.fullscreen.usbprobe | .UsbInventoryService, SNAPSHOT action | stopservice exact component if needed; uninstall exact package | Bounded M4 ready |
| com.rdx.fullscreen.gridtest | .GridActivity | EXIT button; uninstall exact package | Separate geometry-only test ready |
| com.rdx.fullscreen.decodertest | .DecoderTestActivity | STOP/EXIT; uninstall exact package | No decode test until six clips generated and rebuilt/audited |
| com.rdx.fullscreen.m5permission | .PermissionService | stopservice; normal permission-dialog closure; uninstall | Source/design only; M4 PASS required |

No install/start/stop/uninstall helper automatically executes from build/audit scripts. Historical Honda APKs, original prototype, Candidate A/B and notes source files remain preserved. `OFFLINE-DEEP-INVESTIGATION-RESULTS.md` is preserved as historical report; new build findings are separate.

For every installed harness, future operator records package path, ordinary UID, version, signer, native path/ABI where reported, process context and actual running behavior. No native library is packaged; these Java-only APKs are architecture-independent and can run in ARMv7 ART, which remains a runtime observation for each new package. No debug/shared-system-UID trick is used.

After uninstall: `pm path EXACT_PACKAGE` must show absence; `dumpsys package EXACT_PACKAGE` must show no installed package; `ps` must have no package or colon process. Record code/data paths from installed package dump; inspect only if readable and never bypass permission denial. Distinguish "not readable" from "absent". Do not recursively delete leftovers or escalate if uninstall fails. No test APK has an OEM-like package name.

Capture factory AA package path/version/signing/hash where practical and display state/uptime before/after; compare code/package identity separately from private preference/history. System properties/settings/overscan are not changed by these harnesses. Ordinary Activity launches can cause Honda to commit auto-start=false; installation can create MaliciousDetector history/warnings. Neither uninstall nor unchanged APK hash proves those OEM private states were restored. Do not restore them automatically.

M4 has no Activity and only enumerates. Phone attachment can independently start stock protocol. Stop on unexpected harness actions, wrong serial/firmware, install error, permission/SELinux failure, crash, missing bounded end, lost ADB or failed cleanup. Do not claim an elapsed14sec hard deadline on blocked Binder calls. No stock force-stop/disable/clear, USB reset/forceClaim, root, updater, reboot or display adjustment is a fallback.

Decoder failure is a separate shared-media risk. Its20sec pump and25sec watchdog cannot forcibly time-limit configure/stop/release Binder. STOP after such failure; never restart media services or reboot automatically. Grid/decoder Activities have the known OEM lifecycle side effect. Overscan, phone protocol and TTI are separate later authorizations.
