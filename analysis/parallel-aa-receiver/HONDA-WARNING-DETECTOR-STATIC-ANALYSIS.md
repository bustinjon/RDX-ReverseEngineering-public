# Honda warning detector — live-acquired static analysis, 2026-10-25

**Read-only acquisition and local analysis. No detector execution was requested, no detector state was changed, and no cleanup was performed.** This report describes the actual build14 APK acquired from the connected RDX, not the previously saved build168 framework by assumption.

Evidence root: [warning-phonefree-20261025-190517](warning-phonefree-20261025-190517/). All source anchors below are in its `detector-jadx/sources/com/honda/maliciousdetector/` directory. [DEX disassembly](warning-phonefree-20261025-190517/detector-dexdump.txt), [method references](warning-phonefree-20261025-190517/detector-method-references.txt) and [manifest](warning-phonefree-20261025-190517/detector-jadx/resources/AndroidManifest.xml) independently support the decompilation.

## Identity and acquisition

|Property|Observed|
|---|---|
|Package|com.honda.maliciousdetector|
|Version/code/min/target|5.1.1-14 /22 /22 /22|
|UID/process|10023; com.honda.maliciousdetector; PID4468 at capture|
|System path|/system/app/MaliciousDetector/MaliciousDetector.apk|
|System-app state|SYSTEM package, installed/enabled for user0; no changes made|
|APK SHA256|3F29DBD72CE61DFA354AB0A70B5A58094A94E6C87FAC6C2041ABFE93EFA1F053|
|Signer certificate SHA256|2156c50e3c08347f28adccb49ae839394053a45767f153bd8f036ae33d5f8568|
|Signer subject|Windriver /Windriver RDC /costin.costas@windriver.com; public APK-signature metadata only|
|Components|Nonexported .service.MDService; .service.MDBroadcastReceiver; no Activity|
|Manifest permissions|RECEIVE_BOOT_COMPLETED,WAKE_LOCK,SYSTEM_ALERT_WINDOW,DELETE_PACKAGES|
|Manifest application|allowClearUserData=false; requiredForAllUsers=true|

`sha256sum` is not installed on the head unit; raw failure is retained. Vehicle-side `md5` returns `30fb669c7bfc66559c4562d6fe1de47d`, matching the local copy. A second independent `adb pull` has the same SHA256 as the first. SHA256 is computed locally, not misrepresented as a vehicle-side SHA256 calculation. API22 APK signature verification passes. No signing material was loaded or reused.

The APK contains seven DEX classes: PackageLocalRepository plus its deletion observer, UserLocalRepository, MDBroadcastReceiver, MDService plus its two Runnable/button classes. The generated JADX R class is a resource reconstruction, not an additional original class.

## Event and classification paths

1. [MDBroadcastReceiver.onReceive](warning-phonefree-20261025-190517/detector-jadx/sources/com/honda/maliciousdetector/service/MDBroadcastReceiver.java) handles BOOT_COMPLETED and PACKAGE_ADDED/PACKAGE_INSTALL. Package URI becomes the `installed_app` extra of an internal MDService start.
2. [MDService.onStartCommand](warning-phonefree-20261025-190517/detector-jadx/sources/com/honda/maliciousdetector/service/MDService.java) schedules the boot scan after10000ms. A runtime install cancels any pending boot-scan Runnable and checks the supplied package only. Return2 is START_NOT_STICKY; no agent service start/stop was issued to the detector.
3. [PackageLocalRepository.detectMaliciousWholePackages /detectMaliciousSpecificPackage /isSystemApp](warning-phonefree-20261025-190517/detector-jadx/sources/com/honda/maliciousdetector/data/PackageLocalRepository.java) obtains ApplicationInfo through PackageManager. Full scan uses getInstalledApplications(128), i.e. GET_META_DATA, **not GET_UNINSTALLED_PACKAGES**. Specific scan uses getApplicationInfo(pkg,0).
4. A package is considered acceptable by this implementation if any of flags0x1 (SYSTEM),0x80 (UPDATED_SYSTEM_APP),0x40000000 (PRIVILEGED) is present. Otherwise it is recorded as non-authorized. DEX `isSystemApp` at code item0x000cd4 confirms these masks.

The actual classification is **application flags**, not a signature comparison. No signer/public-key lookup, certificate verification, name allowlist, UID threshold, installer check or APK-path comparison is called in the classifier. `mApprovedPublicKeys` is initialized but unused. Ordinary third-party signing is therefore not itself the tested condition; M5's ordinary installation lacks all three exemption flags. Its package name is used for lookup/reporting, not a project-specific blacklist. Its `/data/app` location and UID10049 corroborate ordinary installation but are not direct tests in this predicate. No attempt was made to change those properties.

The NameNotFoundException path returns true; it can set historical detection even when the package lookup fails. That path is **not** needed to explain today's M5 event, which logs an identified ApplicationInfo classification.

## Today's M5 trace

Recorded head-unit/logcat labels, not host UTC conversions:

|Time|Evidence|
|---|---|
|18:55:46.625|PackageManager renames installation staging directory to /data/app/com.rdx.fullscreen.m5permission-1|
|18:55:47.285|MSS_PackageMonitor receives PACKAGE_ADDED for com.rdx.fullscreen.m5permission|
|18:55:47.291|ApplicationMonitor reports onPackageAdded for M5|
|18:55:47.318|PID4468 /MD_PackageLocalRepository logs `Non-authorized third party package installed detected (runtime scan): com.rdx.fullscreen.m5permission`|

The manifest/receiver/service path and correlated broadcast log strongly establish PACKAGE_ADDED as the trigger. The detector's own DEBUG action log is disabled, so the exact incoming action is corroborated rather than separately printed by its receiver. Specific-package scan checks M5, appends its name to the in-memory list and calls `startMaliciousAppDetection(true,true)`. That branch writes historical preference true and returns; it **does not directly display the warning**. A visible dialog specifically caused immediately by this event was not established.

## Persistence and boot warning

[UserLocalRepository](warning-phonefree-20261025-190517/detector-jadx/sources/com/honda/maliciousdetector/data/UserLocalRepository.java) uses default private SharedPreferences. It reads `DID_USER_INSTALL_3RD_APP_KEY` with defaultfalse and has one setter: putBoolean(key,true), then apply(). There is no false setter, remove, clear, database, persistent package list or warning-dismiss acknowledgement in this APK. DEX0x000fac /putBoolean at0x000fce confirms literaltrue.

The boot branch in MDService.startMaliciousAppDetection is independently confirmed at DEX code item0x0012b0:

|Historical bit|Current full scan detects non-system app|Boot behavior|
|---|---|---|
|false|false|No warning|
|false|true|Show warning with Remove all; set historytrue|
|true|false|Show warning with Dismiss only; retain historytrue|
|true|true|Show warning with Remove all; retain historytrue|

Thus absence of all research packages is compatible with a warning on every subsequent boot. Ordinary uninstall does not clear this history according to this APK's code. The detector's current private preference value was **not read**; the original historical triggering package and exact dismissal history remain unknown. [Persistence map](HONDA-WARNING-DETECTOR-PERSISTENCE-MAP.md).

## Warning UI and Dismiss, traced through current UI library

MDService.displayMaliciousWarningDialog sets system-alert mode, dialog type30 and message resource0x7f020000: **“Non authorized by Honda application(s) detected”**. It always adds Dismiss, and conditionally adds Remove all with an uninstall callback. `dialog_title` is defined as “Applications Detector”, but this function does not explicitly set that title; do not infer its actual visible title merely from the resource name.

The current `/system/framework/com.honda.ui.jar` was also acquired read-only to resolve Dismiss precisely. SHA256 `109FA084F7668179F26646B9B33F436D4F8AA07EDAD4269C835534D5B3746A76`; remote/local MD5 `841c33db6e034fd73649d645a8aad120` match. Only [HondaDialog](warning-phonefree-20261025-190517/honda-ui-jadx/sources/com/honda/ui/HondaDialog.java) was decompiled. Builder.addButton(text,style) installs a null callback. The default button click invokes a callback only if nonnull and then dismisses; dismiss closes the Android dialog and updates in-memory showing state. This path does not clear the detector history. The detector does not register a preference-reset dismissal listener.

Remove all is different: it iterates the repository's in-memory package list and calls PackageManager deletion through reflection with a deletion observer. **It was not pressed or invoked.** It is not part of our proposed cleanup because it can act on more than the exact authorized project package. That path also contains no history reset. No bypass/whitelist/signature manipulation was implemented or proposed.

## Negative coverage and limits

- Manifest and receiver/service DEX contain no PACKAGE_REMOVED, PACKAGE_FULLY_REMOVED or PACKAGE_REPLACED handling. PACKAGE_ADDED may also arrive during replacement; no EXTRA_REPLACING branch appears. No removal-triggered rescan/history clearing exists here.
- Full scan enumerates installed ApplicationInfo objects; it does not walk `/data/local/tmp`, Download, APK archives, Dalvik/ART caches or event logs. No filesystem scan path/SQLite/database call exists in the seven-class APK.
- `mThirdPartyPackages` is an in-memory singleton list, appended without clearing in the scan methods. It can be stale/duplicated within one process, but it is not a persisted historical name list. A new process rebuilds it; the separate preference survives.
- Boot delivery/service existence are observed: PID4468 starts for MDBroadcastReceiver at18:40:59.368; dumpsys shows its service's BOOT_COMPLETED intent. DEBUG=false suppresses scan-start logging. No live private-preference read, forced boot, new warning display or dismissal test was performed. Current window focus was the normal Diagnostics USB-mode screen.
- Best-supported pre-today cause: **LIKELY DETECTOR-PERSISTED STATE**. Code mechanism is confirmed; current private flag, original writer and every past visible warning are not independently proven. No current unrelated third-party package or project PackageManager residue was found.
