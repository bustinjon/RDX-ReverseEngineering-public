# Phone-free RDX precheck — 2026-10-25

**PHONE-FREE PRECHECK COMPLETE. M5 REMAINS UNARMED. NO USB PERMISSION REQUEST WAS MADE. NO CLEANUP OR HONDA DETECTOR MODIFICATION WAS PERFORMED. WAITING FOR USER AUTHORIZATION TO ARM M5.**

**READY FOR M5 ARM** means software/evidence readiness only. No timer was started. The laptop stays connected; the next physical step now is **none**. A later explicit arm instruction and physical-readiness confirmation are required before the separately authorized M5-only arm/swap workflow. This report does not request a phone connection, authorize cleanup or advance M6/M7.

## Main finding

The recurring pre-today warning is best classified **LIKELY DETECTOR-PERSISTED STATE**. The live-acquired build14 detector saves a true-only historical bit, `DID_USER_INSTALL_3RD_APP_KEY`. A fresh boot scan with **no current unauthorized apps** still shows the warning when that bit is true. Neither ordinary uninstall nor Dismiss clears it in the inspected code. This explains why all prior research apps can be absent while a warning recurs. Actual private preference contents and the original historical writer were not read/proven.

Today's new M5 install is a separate, observed event: PACKAGE_ADDED at18:55:47.285 followed by the detector's exact M5 runtime-scan warning at18:55:47.318. That runtime branch sets the history bit but does not directly display a warning. It must not be mistaken for proof of the pre-today cause or an immediately displayed dialog.

## Requested results

|#|Check|Result|
|---|---|---|
|1|ADB/RDX identity|Explicit serial00000000; Android5.1.1/API22/armeabi-v7a; fingerprint Acura/gen1CBD_HS/gen1CBD_HS:5.1.1/LMY48P/14:user/release-keys; SELinux Enforcing.|
|2|M5 installed bytes|Initial/final read-only pulls match frozen A22E96490B9557AFF022893A8B8B7A08BB13CEC236E52704CDDAFA90A8EE8F40; local API22 signature verification PASS. Version0.2.0-m5-single-port-300s/code3; UID10049, u:r:untrusted_app:s0.|
|3|M5 armed?|NO. Host session still INSTALLED, no armedAt; no active M5 service; no ARMED event. Cached process8902 after LIST_RESULTS is not an armed run.|
|4|Permission requests|ZERO. No request/reservation/return/callback run events or saved run. Only explicit non-arming LIST_RESULTS was invoked twice in this phase.|
|5|Saved runs|ZERO via audited LIST_RESULTS path; no SAVED_RESULT/error/active-run response. That path returns before UsbManager acquisition and ends the Service.|
|6|Project package count|Seven manifest-confirmed identities from132 analysis APK paths/86 hashes, source manifests and live reports. Original pre-M5 list116 packages; current117 differs only by fresh M5.|
|7|Installed project packages|Only com.rdx.fullscreen.m5permission. Other six names absent. No unexpected project service.|
|8|PM residue|No project UNINSTALLED-BUT-STATE-VISIBLE entry found in -u, exact pm path/dumpsys or full normal package metadata; only user0. No direct PackageManager private files accessed.|
|9|Stale APKs|None found in readable inspected locations; five known exact staging paths absent; Download empty. Vendor tmp subdirectory metadata and /data/app listing have access limits; no whole-filesystem absence claim.|
|10|Detector package|com.honda.maliciousdetector, manifest/pm/dumpsys cross-confirmed.|
|11|Detector path|/system/app/MaliciousDetector/MaliciousDetector.apk.|
|12|Detector SHA256|3F29DBD72CE61DFA354AB0A70B5A58094A94E6C87FAC6C2041ABFE93EFA1F053. Remote SHA256 utility absent; remote/local MD5 match and independent second pull SHA256 match.|
|13|Detector signer|Windriver; certificate SHA2562156c50e3c08347f28adccb49ae839394053a45767f153bd8f036ae33d5f8568; API22 signature verification PASS. Public metadata only, no key reuse.|
|14|Process/components|UID10023/PID4468/u:r:platform_app:s0, processcom.honda.maliciousdetector; MDBroadcastReceiver +nonexported MDService; no Activity. Warning uses shared HondaDialog.|
|15|Runtime trigger|PACKAGE_ADDED/PACKAGE_INSTALL receiver forwards package URI as installed_app to MDService; package-added logs correlate with M5.|
|16|M5 classification|Specific ApplicationInfo lookup → !isSystemApp → in-memory name append/log → startMaliciousAppDetection(true,true) → historytrue.|
|17|Unauthorized reason|M5 lacks flags SYSTEM0x1, UPDATED_SYSTEM_APP0x80 and PRIVILEGED0x40000000. No signature/name/UID/path comparison in actual predicate; unused approved-key field is not an active allowlist.|
|18|Package added|Checks the named app, cancels pending boot scan, sets history on detection; no direct dialog in that runtime branch.|
|19|Package removed|No PACKAGE_REMOVED/FULLY_REMOVED/REPLACED receiver or handling in manifest/DEX; no automatic history reset. Replacement may generate PACKAGE_ADDED, which has no EXTRA_REPLACING distinction.|
|20|Boot|BOOT_COMPLETED → MDService →10000ms delayed full installed-app scan. Current boot delivery/service intent observed. No reboot performed.|
|21|Startup scan|getInstalledApplications(128/GET_META_DATA), classify flags; combine fresh result with history bit. Not an uninstalled-package/file scan.|
|22|Runtime scan|getApplicationInfo(pkg,0) for new package; exact M5 log observed18:55:47.318. NameNotFound returns detectedtrue, but not needed for today's identified M5 case.|
|23|Persistence|Default private SharedPreferences; true-only historical boolean setter with apply(). In-memory package list is separate and not persisted.|
|24|Key/path|DID_USER_INSTALL_3RD_APP_KEY. Derived standard file /data/data/com.honda.maliciousdetector/shared_prefs/com.honda.maliciousdetector_preferences.xml; not read from vehicle. No database/table found.|
|25|Survives uninstall?|Yes according to code semantics: uninstalling another app does not reset the detector's preference, and no removal handler resets it. Actual preference value not directly inspected.|
|26|Should uninstall clear warning?|It removes the current app from a later scan, but does not naturally clear this historical-warning branch. Dismiss also does not clear history.|
|27|External APK files scanned?|No such path in this seven-class APK; it enumerates installed apps, not APK files.|
|28|Staging/temp scanning?|None in detector manifest/source/DEX references. No java.io file-walk/log-history scan.|
|29|Unrelated package?|None currently identified: pm -3 and -u -3 list only M5. Original historical trigger might predate our work; not conclusively attributed.|
|30|Pre-today cause|LIKELY DETECTOR-PERSISTED STATE; historytrue alone reproduces the code condition despite absent old apps.|
|31|Confidence/limits|High confidence in DEX-confirmed mechanism/current M5 classification; likely explanation of reported recurrence. Private value, original writer and actual prior UI/dismissal timeline unverified; DEBUG isfalse, current focus is Diagnostics.|
|32|Future cleanup plan|After later M5 test/evidence/hash/review: normal uninstall only M5, no -k; verify absence/factory/display. No other removal justified now. If historical warning persists, STOP; do not manipulate detector state. Plan only, not executed.|
|33|Detector modification|NONE: no patch/disable/stop/uninstall/data clear/permission/whitelist/signature change.|
|34|Package modification|NONE during this phone-free phase. M5 installation occurred in the preceding authorized phase; no additional install or uninstall here.|
|35|Cleanup|NONE; no file/package deletion, cache cleanup or reboot.|
|36|Phone|Not connected/used for this phase. System host inventory has no normal/accessory phone target. M5 itself is not sampling inventory while unarmed.|
|37|USB permission|No request. No USB open/claim/control/bulk/AOA operation; no permission grant mutation.|
|38|M6|Absent/not running; no action. Frozen disabled artifact unchanged.|
|39|M7|No installed receiver/projection package or service; no action, GAL/phone TLS/MediaCodec. Receiver DEX unchanged.|
|40|Final M5|INSTALLED /UNARMED /0requests /0saved runs /no active service; same exact APK.|
|41|Arm readiness|READY FOR M5 ARM from software/evidence checks, pending explicit user instruction and physical-readiness confirmation.|
|42|Next physical step|None now; keep laptop connected. Do not swap cables or start timer until separately instructed.|

## Preservation and exact evidence

Factory AA com.honda.androidauto.projection.sink remains at `/system/app/AndroidAuto/AndroidAuto.apk`; initial/final APK SHA256 `F9E976F44853C9DB7C8FF5A8610C10CAF1E0B4D1E5BE0886F4F52505C5348146`, same signer certificate as above, code22/version5.1.1-14. No factory package/data operation was issued; private-data equality is not claimed.

Physical1920×720/density160 unchanged. Stable window geometry unchanged: mOverscanScreen=(0,0)1339x720; mRestrictedScreen=(0,0)1920x720; mStable=(0,0)-(1339,720); mSystem=(0,0)-(1920,720). Boot UUID `4f995fac-e0d5-42d7-b566-bf9ee04c11f7` unchanged. No display writes/reboot. Initial head-unit shell date:Sun Oct25 19:05:46 GMT2026; raw epoch/hostUTC command records are retained rather than assuming shell/logcat timezone equivalence.

Frozen disabled M6 `D4DAC2DD8B2AFF1FA7B64BFB32D2A5E889854CCEB4B4A9F7AD5AEF89FB28761F` and receiver DEX `2FDBC63F2F9D63B764697D311AF89D460AE6B8E14B0FADABA9C9339F7FE7C235` hash-preserved. No live decoder/M6/M7 actions or Honda credential/JNI use.

Evidence: [directory](warning-phonefree-20261025-190517/), [final machine state](warning-phonefree-20261025-190517/final-state.json), [read/status command audit](warning-phonefree-20261025-190517/read-only-command-audit.json), [file inventory](warning-phonefree-20261025-190517/FILE-INVENTORY.csv), [hash manifest](warning-phonefree-20261025-190517/SHA256-MANIFEST.json), [command log](warning-phonefree-20261025-190517/commands.jsonl). Each ADB call selects serial00000000 and has independent argv/start/end/exit/timeout/stdout/stderr files.92 ADB calls in this phase: read operations plus two explicitly allowed M5 LIST_RESULTS invocations. No active detector service invocation was issued.

Local JADX initially encountered sandbox access denial to its bundled Java security file; the approved retry succeeded. The subsequent current-UI single-class decompilation used installed JDK17. Missing head-unit sha256sum and denied directory listings are retained as limitations, not converted to false absence/success claims. Source/DEX/manifest/resources, focused log excerpts and derived branch table are included. Raw USB/log evidence can contain device identifiers and a public ADB host key; these are not reproduced in narrative reports and the bundle is not a publication/redacted export.

Reports: [package inventory](HONDA-WARNING-PROJECT-PACKAGE-INVENTORY.md), [static analysis](HONDA-WARNING-DETECTOR-STATIC-ANALYSIS.md), [persistence map](HONDA-WARNING-DETECTOR-PERSISTENCE-MAP.md), [future cleanup plan only](HONDA-WARNING-SAFE-CLEANUP-PLAN.md).

**PHONE-FREE PRECHECK COMPLETE. M5 REMAINS UNARMED. NO USB PERMISSION REQUEST WAS MADE. NO CLEANUP OR HONDA DETECTOR MODIFICATION WAS PERFORMED. WAITING FOR USER AUTHORIZATION TO ARM M5.**
