# Honda privileged Android Auto update paths: offline findings

Date: 2026-10-22. Local/static inspection only. No update service, broadcast, installer, factory function, filesystem operation or reboot was invoked on the head unit. No internet or ADB used in this pass.

## Conclusion

**Latest read-only collection follow-up:** the seven active service packages and public root have now been collected and analyzed; [current-stack trace](current-update-stack/README.md). The root is OTA Honda Root CA V1/RSA4096, DER SHA256 `27C3D45ADD87D80F15C210FA8D269F1CF8717A585AA5E35837BC6E917F495688`. FactoryUpdateProxy adds another persistent app-copy path with possible whole-directory error cleanup; factory ROLLBACK is not AA undo. This closes the earlier missing-service/certificate gaps without establishing safe custom-code deployment. Historical missing-input statements below describe the original offline pass.

**Superseded detail, 2026-10-22 follow-up:** [DEPLOYMENT-PATHS.md](DEPLOYMENT-PATHS.md) now traces boot scan order, raw-instruction duplicate/signature checks, normal updated-system rollback and native delivery authentication. Intact stock AA normally wins over a later plain persistdata duplicate. Trusted boot certificate collection checks the signed manifest rather than every DEX entry; do not read this earlier report as proof of full APK integrity verification on that path. The earlier offline pass identified `/system/etc/security/sw_update_root.crt` but lacked its bytes; the latest authorized collection above closes that gap. [TEMPORARY-EXECUTION.md](TEMPORARY-EXECUTION.md) separately audits instrumentation, wrap.* and Honda data-backed extensions. No safe execution method has been established.

There is a concrete OEM **system-app staging mechanism under `/persistdata/app`** worth pursuing before any system-image modification. Red Bend code stages component APKs there, and Honda PackageManager scans that directory at boot as a system/privileged source. This is **not yet a verified reversible way to deploy our patch**: package/shared-UID signatures, authenticated update input, duplicate-package precedence, native-library placement, recovery and rollback behavior remain constraints.

An official, compatible replacement retaining the OEM-trusted signing certificate could preserve package identity/system UID. Arbitrarily changing classes.dex does not retain its cryptographic signature. Our unsigned A/B artifacts therefore cannot be fed to an official installer and assumed to work. No signing bypass or exploit was pursued.

## APK trust and shared UID

API-22-aware `apksigner verify --min-sdk-version 22 --max-sdk-version 22 --verbose --print-certs` verifies the current original receiver under **v1/JAR signing**, one signer. [Verifier output](fullscreen-candidate/original-apk-apksigner.txt).

- Signer subject: Windriver / Windriver RDC (OEM-trusted signing identity; the subject does not literally say Honda).
- Certificate SHA-256: `2156c50e3c08347f28adccb49ae839394053a45767f153bd8f036ae33d5f8568`.
- Public key SHA-256: `db59a280158a9bf7cd29934cbf65e421d8d05b7a9d1ebf894113f3ff090807ec`.
- RSA 2048-bit key. Public certificate/key material is not the private signing key.

Modern Java17 jarsigner initially treated its SHA1-era signature algorithms as disabled; that report is not evidence that Android5 rejected the APK. The Android-aware verifier resolves that tool-policy ambiguity. The unsigned candidate fails verification because META-INF/MANIFEST.MF is missing, as deliberately expected. No global Java security policy was changed to obtain these results.

Matching device `services.jar` source `com/android/server/pm/PackageManagerService.java:4427` checks both existing-package signatures and shared-user signatures. Failure codes -7 and -8 respectively reject mismatches. `android:sharedUserId="android.uid.system"` in a modified manifest does not grant UID1000 without that trust relationship. APK signing, AA's embedded GAL TLS certificates/private client credentials, update-container signatures and verified-system integrity are **different trust boundaries**. `CertKeys` for the AA phone connection is not an APK signing key.

## Official regular/factory update interfaces

Local `honda-manager.jar` defines `com.honda.auto.softwareupdate.ISoftwareUpdate`, with clients `SoftwareUpdate`, `RegularUpdate`, `FactoryUpdate`. Service name `software_update`; operations include source/location/metadata/state queries, checking, downloading, installing now/at driver exit and factory workflows. This is evidence of supported orchestration, not authority to run its mutating methods.

Earlier captured package inventory identifies these D-side directories:

| Package | Known codePath | Local implementation status |
| --- | --- | --- |
| `com.honda.auto.softwareupdate` | `/system/app/SoftwareUpdateService` | APK not present in current local collection; framework interfaces available. |
| `com.honda.auto.transportservice` | `/system/app/Transport` | APK missing locally; native libtransport present. |
| `com.honda.ota` | `/system/app/tjbaOTA` | APK missing locally. |
| `com.honda.auto.factoryflashing` | `/system/app/FactoryFlashingService` | APK missing locally. |
| `com.honda.auto.diagnostics.service` | `/system/app/DiagnosticsService` | APK missing locally; diagnostic Binder interfaces present. |
| `com.honda.miscellaneous` | `/system/app/HondaMiscellaneous` | APK missing locally; display-service log evidence present. |
| `com.redbend.client` | `/system/priv-app/RedBendApp` | APK available and decompiled; snapshot version 10.2-honda-1.0.0.101, UID1000. |

These are directory paths established from an existing package dump, not guesses about the basename of each APK or guaranteed 2022 paths. A future collection should include every file in each active package directory, resolved by a path inventory; no collection occurred in this pass.

`SoftwareUpdateDefines` names errors for APK file/application-ID lookup, install, permission setting and cache/install directory deletion, plus invalid/expired/unreadable update ZIP errors. This supports distinct component and package validation stages. It does not reveal the complete signed outer payload format or prove that AndroidAuto is an independently authorized updatable component on this vehicle.

## Red Bend signed component / system-app route

Available original: `adb/RDX-Audit/full-system/priv-app/RedBendApp/RedBendApp.apk`; full JADX output under `decompiled/RedBendApp`.

Trace:

1. `ClientService` registers `GenericInstallerHandler` for `B2D_MSG_SCOMO_GENERIC_INSTALL_REQUEST`.
2. `GenericInstallerHandler` decodes component type, mode, payload path, component ID, byte offset and length. Type **202** is its system-app installer. Phase1/mode1 calls `GenericInstallerIpl.installSystemApp(info)`; mode3 uninstalls. Successful system-app processing marks a reboot required in postinstall phase2.
3. `GenericInstallerIpl.getDCfile()` extracts the component byte range from the delivery package into a staging file. This operation is not merely inspecting an APK.
4. `installSystemApp()` (`GenericInstallerIpl.java:414`) obtains the APK package name, copies to `/persistdata/app/<package>.apk.tmp`, then renames to `/persistdata/app/<package>.apk`. It may force-stop an existing process and call `removeOldApk()` for its existing source path.
5. `removeOldApk()` (`:392`) can recursively attempt to remove the old APK parent directory and does not provide a transactional backup or demonstrated restore. A call that reaches this code is **not a safe probe**. For an app originally in read-only `/system`, success/failure and duplicate-source behavior need separate static/reference validation; do not infer harmless behavior from a protected mount.
6. Matching PackageManager constructor (`PackageManagerService.java:1421-1436`) scans framework, system priv-app and app directories, then `/persistdata/app` with parse flags **193**, the same parse flags used for priv-app. Its scan flags differ, and version/disabled-system/duplicate-package logic also matters. Merely observing scan order does not prove that an arbitrary copy shadows the stock package or will roll back safely.
7. Package/shared-user signature checking remains a separate PackageManager boundary. An installer with UID1000 does not recreate a missing OEM signature.

Ordinary SCOMO application install paths (`ui.InstallApk`, `GenericInstallerIpl.installApk`) call `pm install -r` (one handler uses `-d`). `InstallApkNonRoot` launches the standard package installer UI. Neither is a demonstrated bypass of package signature/shared-UID verification. These code strings were read, not executed.

The service's manifest sets ClientService exported=false. Its dynamic event receiver is registered with `com.redbend.client.permission.EVENT_INTENT`; the permission is signatureOrSystem. Some unrelated boot/network/update-request receivers are exported, but that does not make the internal generic system-component installer a public arbitrary-APK interface. No events were forged or sent. The native engine is selected as `smm_release` or `smm_debug` by BasicService; outer delivery-package authentication and exact component authorization need its matching implementation/config/payload.

Component catalogs include `/data/data/com.redbend.client/files/generic_comps.txt`, read by `SwmcInstallerHelper`, plus native delivery metadata. Modified PackageParser reads a `scomoId` attribute and PackageInfo exposes it. The local AA manifest does not establish a distinct update component ID for this target, and no genuine AndroidAuto component payload was found. Obtain official catalog/package evidence rather than inventing that mapping.

## Developer image / Compulsion Loading route

Local `DevUpdateManager` uses `/system/lib/libdevelupdate.so`, removable USB `manifest.cfg`, native `parseManifest` and `checkImages`. Its update method sets a persistent developer-update flag and can reboot with reason `develupdate`. `CompulsionLoadingActivity` invokes this workflow from its update action. Even the wrapper can mutate state **before** all image checks finish.

Native symbols/strings from local libdevelupdate show:

- `verify_manifest`, `verify_file`, `verify_partition`, `verify_image`.
- `EVP_DigestVerifyInit/Final`, `PEM_read_RSA_PUBKEY`, SHA256 error/verification paths.
- Manifest entries for MLO, UBOOT, BOOT, ENV, SYSTEM, LOGGING, PERSISTDATA, IPU1; image hashes and a data_cleanup option.
- Named `system1` and `system2` partitions.

These indicate signed/integrity-checked image machinery. They do **not** establish the exact signature coverage/key policy, a safe rollback, or that two partitions constitute an independently usable A/B rollback scheme. No official manifest/payload or complete native instruction-level verifier analysis is available locally. Do not construct or trigger a manifest as a test. Factory Flashing and Compulsion Loading remain prohibited without explicit future approval and a separate verified plan.

Framework `com.honda.auto.utility.ISwUpdate` exposes boot/system partition/status getters and setters via `swupdate`. Existence of setters is not a safe rollback procedure. None was called.

## What would establish a reversible official route?

Required evidence, in order:

1. A genuine same-branch official update containing an AA component, its complete manifest/catalog, all container signatures/public verifiers and version/region/model eligibility rules.
2. Matching SoftwareUpdateService/Transport/OTA/FactoryFlashing service APKs and native engine/daemon implementation, plus exact component-ID/installer selection. These are presently missing locally.
3. Verification that any candidate **official APK** carries a signer compatible with the existing app/shared UID; ABI, framework/native dependencies and native search paths must also match. The custom unsigned candidates do not satisfy this.
4. Exact staging/deduplication rules for an AA package already in `/system/app/AndroidAuto`, including whether the original is preserved, what code path wins and how native libraries are resolved.
5. Documented restore/recovery behavior, version/downgrade restrictions, package database effects and head-unit reboot requirements. Original signed artifacts must remain recoverable without assuming an unsigned image can be flashed back.
6. Only after those are known: a concrete live execution and rollback plan for separate approval. No broad approval to "try the updater" is adequate evidence that the procedure is reversible.

A compatible official signer-preserving component update may avoid modifying a verified system image. It still cannot make our arbitrary DEX edits retain an OEM signature. If that signing/deployment requirement cannot be met, report it as a blocker; do not quietly substitute exploit or flash work.

## Files produced / remaining limits

- `analysis/libautoreceiver_jni.so.strings.txt`, `libdevelupdate.so.strings.txt`, `libswupdate.so.strings.txt`, `libtransport.so.strings.txt`: static printable-string evidence, not executed libraries or a full native decompilation.
- Original APK verification report and unsigned candidate reports in `analysis/fullscreen-candidate/`.
- Requirements for the later factory fullscreen implementation: [2022-reference-needed.md](2022-reference-needed.md).

No reversible deployment method preserving OEM signing for a **custom modified APK** has been demonstrated. The official `/persistdata/app` route is a specific research lead with concrete code evidence, not authorization or a promise that it can install this patch.
