# M5 live USB permission test — 2026-10-23

**FINAL VERDICT: M5 INCONCLUSIVE. M4 remains PASS.** The service timed out before the phone was connected. No permission request occurred, so this run establishes neither permission success nor a platform denial. User ended phone tests until later tonight; no repeat was performed. M5 was cleanly uninstalled. **Live access ended2026-10-23 17:48:25 EDT (21:48:25Z); no subsequent ADB command was run.**

## Artifact, static clearance, and runtime identity

- Package `com.rdx.fullscreen.m5permission`; component `com.rdx.fullscreen.m5permission/.PermissionService`.
- Version `0.1.1-m5-single-port-180s`, versionCode2, minSdk21/targetSdk22.
- APK `m5-permission/build/20261023-173344-965/rdx-m5-permission-0.1.1-m5-single-port-180s-development.apk`.
- SHA256 `90E95C898D41C233F1F4F79BD0A8E84C28C31D78458C165489716D45F801EA30`.
- Development signer SHA256 `c001f59b25081ddfc73937155ca3580717e817c45c66e68b9e059737b0b28831`.
- Normal UID10050, PID12543, SELinux `u:r:untrusted_app:s0`; no shared UID/privileged install.
- Vehicle serial00000000, D.1.6.4/API22; same boot UUID454c5096-50d6-49a9-9bbf-561a0f4fa6d1 before/after.

API22 v1 signature and alignment PASS. Final packaged manifest, JADX decompilation, DEXDUMP and complete DEX references/strings/classes independently checked; source hashes matched, and decompiled control flow manually reviewed before installation. [Revision clearance](m5-permission/M5-SINGLE-PORT-AUDIT.md). Exactly one gated requestPermission callsite. No openDevice, claimInterface, releaseInterface, controlTransfer, bulkTransfer, System.loadLibrary, MediaCodec, GAL, AA protocol, AOA, shell/system mutation or Honda package-control code. One headless Service, no Activity, manifest permissions/receivers/filters/native libraries.

Original0.1.0 APK remains unchanged: SHA256757726DE360D466ACE5F7C12A90DE5B4377F2BD19D8D4BD8C13879967FDE95C8. Original source/manifest archived under m5-permission/history/pre-single-port-20261023/. Historical reports remain intact.

## Single-port revision and explicit gates

Phone and laptop cannot share the port. User authorized a narrow single-port change: total180sec bounded wait, one-second passive inventory polling, and durable logging to the app's own external files. No storage permission was added. Existing action/M4 acknowledgment/exact-device-name mode/nonce/callback identity verification remain. Deferred selection additionally requires wait_for_target=true and the exact M4-observed18D1:2D01; multiple matching devices stop without a request. Once found, its real path/VID/PID is pinned before the single permission request. No retry after request, no sticky restart, no device opening. Timeout/result ends Service and removes handlers/callback registration.

Start command actually executed (not a future authorization):

[Code block omitted from public report; see authored source where available.]

## Evidence

[Raw session evidence](m5-live-20261023-173401-872/), [machine validation](m5-live-20261023-173401-872/final-validation.json), [own durable result](m5-live-20261023-173401-872/m5-last-run.txt).

Thirty device commands were recorded with exact argument vectors, explicit serial, UTC timestamps, stdout, stderr, exit codes and timeouts. All completed exit0/no timeout. Shell ls absence diagnostics are preserved even though the compound shell command's overall exit code was0. No logcat buffer was cleared. Raw baseline and final full logcat snapshots are retained.

A local evidence-loop typo (`text-placeholder`) emitted PowerShell errors after each of eight initial baseline commands; their separately captured ADB commands all succeeded and their evidence was preserved. The typo did not execute a vehicle action. The interim report is preserved in the session directory and was superseded by this final report.

The app file was pulled through the normal shell-visible `/sdcard/Android/data/com.rdx.fullscreen.m5permission/files/m5-last-run.txt` alias. No private-data bypass was used.

## Timeline and attribution

Times below are the recorded logcat/host-local labels (EDT, UTC-04). Java epoch and elapsedRealtime records are preserved for correlation; head-unit shell date prints GMT despite the differing local log labels, so do not infer timezone solely from that abbreviation.

| Time | Actor | Event |
|---|---|---|
|17:34:26|Host/system|Baseline phone absent, M5 absent, factory AA/package/USB/display/process/boot/log state captured|
|17:35:05.686|Honda detector|Logs non-authorized third-party installation of M5|
|17:35:16.889|M5|START, UID10050, exact target18D1:2D01,180000ms deadline|
|17:35:16.898–17:38:16.000|M5|172 passive inventory snapshots; target absent|
|17:38:16.933|M5|TIMEOUT; no retry|
|17:38:16.934|M5|END, no open/claim/transfer|
|17:42:44.769|System|Host root hub003/001 appears after normal USB-mode transition|
|17:42:58.732|System|OnePlus13 phone003/002,22D9:2769|
|17:42:58.770|Honda GalService|Starts accessory switching timer|
|17:42:59.481|System|Accessory003/003,18D1:2D01,accessory_adb; two interfaces/four bulk endpoints|
|17:42:59 onward|Honda|Normal factory AA reaction; user reports regular Android Auto connected|
|17:44:53–54|System/Honda|Phone disconnect/mode transition|
|17:45:13 onward|Host|Retrieves own result, surviving framework/Honda logs and state|
|17:48:17|Host/package manager|M5 uninstall Success|
|17:48:18 onward|Host|Own cleanup and factory AA/display comparisons captured|
|17:48:25|Host|Live access ends; no more ADB|

**Phone initial attach was281.799sec after M5 timeout; accessory attach was282.548sec after timeout.** The3-minute bound did not accommodate the actual7min42sec start-to-accessory interval. The gap is measured; the exact physical/UI cause of the delay is not inferred.

M5 observed only baseline1D6B:0002,1D6B:0003,076D:010D,0424:2514 devices, hasPermission=false. It did not observe the target phone during its active window. Phone identities above come from system logs, not M5 samples. Honda performed the accessory conversion while M5 was already stopped.

## Permission outcome

- Intended target18D1:2D01; never matched during active M5 window.
- Actual requestPermission invocations: **0**.
- Permission callbacks: **0**.
- Dialog: user reports **none**.
- User grant: **none**.
- Target before/after hasPermission: **NOT MEASURED**, not a false result.
- Device opens/claims/transfers/AOA by M5: **none**; corresponding APIs absent from final DEX.

No ordinary-app USB permission boundary was demonstrated. Future grant remains an empirical question. No automatic second run was started; the proposed10-minute retry was not approved or built. User said no more phone tests until later tonight.

## Crash, lifecycle and detector observations

No FATAL EXCEPTION, ANR or SELinux denial was found in the captured17:35–17:48 log window. This describes retained logs, not an exhaustive proof of all system behavior.

At17:35:05.686, MD_PackageLocalRepository recorded `Non-authorized third party package installed detected (runtime scan): com.rdx.fullscreen.m5permission`. No warning suppression or detector changes were attempted. MaliciousDetector.apk was **not acquired** in this session; exact warning UI/authorization/persistence/Dismiss implementation remains unresolved.

Honda AcuraLifecycleCallbacks and GalPrefs auto-start=false writes appear during normal Diagnostics/menu/USB-mode Activity transitions, including17:44:09.940,17:44:38.408,17:44:41.746 and17:44:49.180. No M5 Activity exists. These logs must not be attributed to a permission dialog, since M5 never requested one. Honda private data was not read/restored; equality of private preferences is not claimed.

## Cleanup and preservation — verified

M5 stop requested; already ended naturally. Uninstall only com.rdx.fullscreen.m5permission: Success. Package path/dump absent; process absent. Both potential code directories, normal private data directory, own external directory and pushed APK all explicitly report No such file or directory, with no access-denied result. Evidence was retrieved before uninstall.

Factory AA full package dump is byte-for-byte identical before/after: com.honda.androidauto.projection.sink, UID1000, version5.1.1-14/code22, path/system/app/AndroidAuto/AndroidAuto.apk. Its PID2445/system_app persisted. Before, intermediate and final APK copies all hash:

`F9E976F44853C9DB7C8FF5A8610C10CAF1E0B4D1E5BE0886F4F52505C5348146`

Identical APK bytes preserve the embedded signer; no factory package installation, clear, stop, disable or mutation occurred. Package identity preservation is separate from private runtime/preference state.

Before/after geometry lines are identical:

[Code block omitted from public report; see authored source where available.]

No overscan/display/settings/property commands or reboot occurred. User used normal supported USB-mode UI only.

## Next decision

**Next LIVE candidate: corrected M5 permission-only retry, separately authorized later. No further phone tests now.** Before another start, allow adequate bounded time for the actual mode/cable workflow, confirm operator readiness immediately before arming, and announce both absolute deadline and remaining time. A10-minute timer revision was proposed but has not been built or authorized for execution. Preserve this run as INCONCLUSIVE rather than a permission failure.

M6 is not justified by this result: ordinary permission has not yet passed. Its existing disabled scaffold remains unchanged. No AOA request, open/claim/transfer, GAL/TLS/decoder/fullscreen/TTI experiment was executed. M3 remains deferred; clean ordinary-app receiver remains preferred.

**LIVE CAR ACCESS HAS ENDED. NO M6 LIVE ACTION WAS EXECUTED. NO FACTORY HONDA PACKAGE WAS MODIFIED.**
