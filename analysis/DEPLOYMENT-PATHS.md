# Android Auto deployment paths: static evidence and reversibility

Latest priority: [recovery first](RECOVERY-FIRST-PLAN.md), [root feasibility](ROOT-FEASIBILITY.md) and [first-test comparison](FIRST-LIVE-TEST-CANDIDATES.md) on the exact D.1.6.4 unit. No newer-unit reference is required. The recovery gate is not met; no live root/modified-AA test is recommended. Earlier route rankings below describe research designs, not current executable options.

2026-10-22. Current target: D.1.6.4, Android 5.1.1/API22, `com.honda.androidauto.projection.sink`, versionCode22, shared UID1000. Updated after the explicitly authorized **read-only package/certificate collection**, followed by local static analysis. Collection used devices/getprop/pm path/dumpsys package/ls/pull only; **no updater invocation, staging, install, property change or process interruption occurred**. No internet used; the HMI patch is unchanged. Earlier offline-only findings below retain their original provenance where identified.

## Current collection follow-up: service and certificate gaps closed

All seven requested complete active package directories and `/system/etc/security/sw_update_root.crt` are now preserved under [current-update-stack](../apks/current-update-stack). Seven APKs, two Diagnostics JNI target contents and the certificate were collected; all pulls report0 skipped. Raw listings preserve the two original library symlinks; local copies materialize target bytes in the same hierarchy. All seven packages are UID1000/shared-user android.uid.system and verify with the same Windriver certificate as AA. Fresh RedBendApp differs from the earlier APK in its binary manifest and three signing entries; DEX and all other payload entries match. The decoded manifest change is platformBuildVersionName `5.1.1-168` to `5.1.1-14`; component/permission declarations are unchanged. Earlier draft whole-APK identity claims were incorrect.

[Current-stack collection and full dispatch trace](current-update-stack/README.md) provides source references, package paths/versions, SHA256 inventory, signer reports and concrete responsibilities for every collected service. [Collection validation](current-update-stack/collection-validation.json) audits all32 logged ADB operations (plus initial interactive devices check), file hashes, sizes and copy completion. All seven current APKs decompile successfully with no JADX warnings/errors; critical destructive/factory/validation methods are also retained as raw smali.

New conclusions:

- **Delivery root identified and verified locally:** OTA Honda Root CA V1, RSA4096, self-issued/self-signature valid, 2016-03-17..2066-03-20. DER certificate SHA256 **`27C3D45ADD87D80F15C210FA8D269F1CF8717A585AA5E35837BC6E917F495688`**; PEM file SHA256 `1498982CA3C1C3C0EA491DD5DFAEB8FC621F0318E033541317F277D3EEF01ECF`; SPKI SHA256 `D0564C28CF7644B0DBB099BE73B791EDBE30B12711BB17BEED78BAEE09E61457`. It is distinct from the APK signing key. No actual delivery payload was authenticated in this pass. [Certificate metadata](current-update-stack/update-root-certificate.json), [self-signature verification](current-update-stack/update-root-self-signature.txt).
- **Dispatch closed through current Java:** OTA AppService/UI -> Honda SoftwareUpdate clients -> SoftwareUpdateService/Binder -> regular/factory proxies -> serialized Honda event -> RedBend ReceiverEvent/ClientService -> native SMM. Externalized events return through SoftwareUpdateReceiver. Boot/resume constructors themselves send events/write state; no service was started/bound merely to inspect it. Source and manifest permission checks are distinguished from untested direct global Binder reachability.
- **Another staging implementation:** FactoryUpdateProxy.installApk enumerates TO_DOWNLOAD apps from FactorySettings, takes files from `/cache/persistdata_app`, uses normal `pm install -r` **only for Garmin-named app IDs**, and otherwise copies into `/persistdata/app/<app_dir>/<appId>` and enables the configured app. On error it can recursively delete **the entire `/persistdata/app/` directory**. This factory path has broad side effects and does not supply AA rollback.
- **ROLLBACK is not AA undo:** the factory state handler invokes native partition-update status handling and reboots; regular install handling also invokes partitionSwitch for installer-type104. No AA-specific source restoration, health check or update-removal API was found. Normal PMS generic restoration remains conditional; an actual AA delivery classification/update history is still missing.
- **Transport is ECU coordination/programming:** inventory/YMT/component versions, diagnostic session seed/key, retrieve/apply program updates and status. It is not a second Java X.509 verifier or a temporary AA code loader. The OTA APK is the UI/orchestrator; FactoryFlashing performs persistent configuration/database/app/hardware setup.
- **Temporary audit strengthened:** none of the seven manifests declares instrumentation and none of their DEX tables references the audited dynamic DEX loaders/startInstrumentation. No OEM-signed runner, safe AA wrapper/helper, temporary replacement mode or alternate developer/test APK trust path was identified. Validation mode concretely controls the MOST/MOCCA firewall; it is not JDWP or a Java loader. See updated [temporary execution audit](TEMPORARY-EXECUTION.md).

**Decision unchanged:** no concrete safe, reversible execution/deployment path for our custom patch has been established. Factory copying/cleanup and partition ROLLBACK are unsuitable first tests. No live modified-APK test is proposed. The public root and seven implementations are no longer collection gaps; authentic AA payload/catalog, effective private updater/PMS state, recovery semantics and conditional wrapper prerequisites remain unresolved.

## Finding

**No presently available path meets both requirements: run our custom modified code and provide a demonstrated safe rollback.** There are two distinct OEM installation mechanisms, with different precedence and recovery behavior:

1. Normal PackageManager replacement of a system app, generally stored under `/data/app`, records the original as a disabled system package. Its transaction-failure and explicit update-removal restore code is present. It requires an acceptable complete APK signature and compatibility. We have no OEM-signed custom patch or qualifying signed helper.
2. Red Bend type202 copies APKs into `/persistdata/app`, outside the normal replacement transaction, and may delete the old source directory. Boot PackageManager scans this as a system/privileged source. **This does not automatically override an intact `/system/app/AndroidAuto` package, and is not an established transactional update/rollback mechanism.**

An additional trust distinction corrects the earlier report: the boot scan verifies the signed Android manifest rather than every APK payload entry. That is not equivalent to a normal full APK verification and is not proof that arbitrary DEX changes can never load from a trusted directory. It also supplies neither authorized filesystem access, duplicate resolution nor safe rollback. Our existing unsigned analysis APKs do not even retain the signed manifest metadata required by that branch.

Best next work is an authentic compatible AA payload/catalog and the remaining state/recovery evidence, while investigating the temporary wrapper prerequisites in [TEMPORARY-EXECUTION.md](TEMPORARY-EXECUTION.md). The seven implementations and public trust anchor have now been collected. Do not run an updater, stage a file, delete a package or reboot to discover its behavior.

## Answers to the ten deployment questions

| Question | Finding from available code | Limit / evidence needed |
| --- | --- | --- |
| 1. Who scans/installs `/persistdata/app`? | Android `PackageManagerService` inside **system_server** scans at startup. Red Bend ClientService stages through GenericInstallerIpl. Current SoftwareUpdateService's FactoryUpdateProxy also copies configured apps there. `installd` handles requested native/dex/data work; it is not the directory's boot package selector. | No separate live directory watcher for this path found in the audited PMS. A copy is not an immediate package-replacement API. |
| 2. Same Honda/Wind River signature? | AA must retain signing identity compatible with `android.uid.system`. The boot system-directory catch may tolerate a package-only signer change, **but explicitly rejects shared-user mismatch** with -104. Normal installs enforce package/shared-user signature matching (-7/-8). | Boot certificate collection authenticates only the manifest entry when PARSE_IS_SYSTEM is set; cached certificate reuse also exists. Thus signer identity requirements do not establish complete DEX integrity verification on this path. |
| 3. Payload format? | Native Red Bend understands delivery packages with headers, signature/certificate metadata, component byte ranges and delta extraction. A type202 component is an extracted raw APK. Other paths handle ZIPs, split delivery packages and filesystem deltas. | No genuine AA update package exists locally. Cannot identify its particular outer ZIP/container version, component type or full-vs-delta choice from filenames alone. |
| 4. Where verification? | Native `SWM_DP_validate` calls `VDM_SWMC_PL_Security_verify`; split-file counterpart exists. These read a root certificate, verify dates/chain, digest data and verify an RSA signature. APK parse/signature/shared-UID checks occur separately in PMS/PackageParser. USB developer image verification is a third implementation in libdevelupdate. | Current service dispatch is now traced. Authentic payload eligibility/version policy, effective catalogs and complete native recovery behavior remain unresolved; authenticated transport is another independent boundary. |
| 5. Which certificate/key? | Red Bend native root lookup reaches Java Ipl.getRootCertificatePath, returning **`/system/etc/security/sw_update_root.crt`**. Now collected: **OTA Honda Root CA V1, RSA4096**, DER SHA256 `27C3D45ADD87D80F15C210FA8D269F1CF8717A585AA5E35837BC6E917F495688`; self-signature verifies locally. Payload chain/leaf keys are used downstream. | Actual payload chain/algorithm/eligibility still needs a genuine payload. APK signer, TLS client/BKS trust and developer-image key are separate. |
| 6. Can an official AA update replace stock without writing `/system`? | **Normal PackageManager: structurally yes**, for an accepted compatible OEM-signed update, through `replaceSystemPackageLI`, keeping the stock file and a disabled-system record. **Simple Red Bend staging with both stock and staged copies: no general override.** | No actual official AA component, compatible F-series APK, eligibility rule or successful AA update transcript is present. The type202 installer attempts deletion of the previous source. No safe AA replacement through it is demonstrated. |
| 7. Which duplicate wins? | For ordinary boot state, valid stock AA is scanned first and registered; a later `/persistdata/app` duplicate is rejected -5 even if its versionCode is higher. AA is not in the delayed-scan list. | Existing disabled-system/update records can alter this through the explicit updated-system/version logic. Private packages.xml was not collected. Do not generalize one state to all upgrade histories. |
| 8. Exact rollback after staged load failure? | **No type202 health-based restore/backup logic identified.** Current factory app-copy failure can delete the whole persistdata app directory. Factory ROLLBACK calls partition status handling/reboot, not AA package restoration. Normal PackageManager update failure has separate restore logic. | No AA package health/restore guarantee for staging, interruption, crash loops or data migration. Actual native recovery/boot outcomes remain unproved. |
| 9. Does removing staged APK restore stock? | If an intact valid stock copy remains, no conflicting `/data/app` update/disabled record exists, and its dependencies/data remain compatible, the next boot scan can register stock first. Often stock was already winning, so removal changes nothing. | Removing a file is not a live rescan/transactional uninstall. If the installer deleted stock, there is nothing to restore. A `/persistdata`-only system package can lose its data when absent at boot. No current authorization to remove anything. |
| 10. Boot-loop/PMS failure possible? | Expected invalid/duplicate-package errors are caught; an AA playback crash does not itself prove a system boot loop. However this is privileged startup code, no automatic health rollback is shown, critical/shared components can be affected and unexpected runtime failures are not all caught as PackageManagerExceptions. | **Cannot certify boot safety.** No evidence justifies testing a bad package on the vehicle. Stock AA alone is not shown to cause a head-unit boot loop, but absence of that proof is not a safety guarantee. |

## Evidence locations and provenance

Source roots below are relative to the project root. Line numbers refer to the current local JADX output; raw DEX is authoritative.

- `decompiled/Services/sources/com/android/server/SystemServer.java:270`: calls PackageManagerService.main during bootstrap.
- `.../pm/PackageManagerService.java:1421-1515`: boot order, system/data scans and `expectingBetter` fallback; `:3443` scanDirLI; `:3546` certificate cache; `:3571` file parse/update handling; `:5023` package wrapper and `scanPackageDirtyLI`; `:4427` verifySignaturesLP; `:8728` replaceSystemPackageLI; `:8883-8898` ordinary install parse flags and complete certificate collection; `:9367` deleteSystemPackageLI. Relevant raw instructions: [PMS smali](deployment-evidence/services-smali/com/android/server/pm/PackageManagerService.smali).
- `decompiled/Framework/sources/android/content/pm/PackageParser.java:478,810`: certificate collection; [raw PackageParser smali](deployment-evidence/framework-smali/android/content/pm/PackageParser.smali). Matching core runtime [StrictJarFile.java](deployment-evidence/StrictJarFile.java) independently confirms lazy per-entry verification.
- `decompiled/RedBendApp/sources/com/redbend/client/GenericInstallerHandler.java`, `GenericInstallerIpl.java`, `SwmcApkInstallerHelper.java`, `Ipl.java`, `BasicService.java`, `HondaDIL.java`; decoded manifest under `decompiled/RedBendApp/resources/`.
- Native originals: `adb/RDX-Audit/full-system/lib/{libsmm_release.so,libsmm_debug.so,libdevelupdate.so,libswupdate.so,libtransport.so}`. [Evidence inventory and limitations](deployment-evidence/README.md). Functions were disassembled as ARM data on the host, never loaded/executed as vehicle libraries.
- Matching current/historical framework/services DEX identity was established in [archive-entry-hashes.json](../logs/2026-10-22-investigation/archive-entry-hashes.json). Red Bend's current DEX matches the prior APK, but the complete APK and build metadata differ: [entry comparison](current-update-stack/redbend-provenance.json), same package version10.2-honda-1.0.0.101/UID1000. Newly collected service sources live under `decompiled/current-update-stack/`. Global native updater libraries were not re-collected in this pass.

## Boot scan and precedence, reconstructed

PMS constructor sets `mScanningSystemDirs=true` and scans, in order:

| Directory | parseFlags before `PARSE_MUST_BE_APK` | scanFlags |
| --- | --- | --- |
| `/vendor/overlay` | 65 (0x41) | 17312 |
| `/system/framework` | 193 (0xC1) | 49570 |
| `/system/priv-app` | 193 | 49568 (0xC1A0) |
| `/system/app` | 65 | 49568 |
| **`/persistdata/app`** | **193** | **16800 (0x41A0)** |
| `/vendor/app`, `/oem/app` | 65 | 16800 |
| `/data/app`, `/data/app-private`, later | 0 / 16 | 20896 |

193 = PARSE_IS_SYSTEM1 + PARSE_IS_SYSTEM_DIR64 + PARSE_IS_PRIVILEGED128. scanDirLI adds MUST_BE_APK4. Both ordinary system and persist scan flags include INITIAL16384, BOOTING256, DEFER_DEX128 and NO_PATHS32; stock also enables the OEM cache flag32768. Thus **persist staging grants a trusted/privileged source classification**, not just an ordinary user app directory. Version and shared-UID acceptance remain separate.

scanDirLI accepts `.apk` files and package directories, excludes PackageInstaller stage names and ignores the type202 temporary `.apk.tmp` file. Existing non-first boot scans can divide a directory across two threads, but join before returning, so `/system/app` scan completes before `/persistdata/app` begins. Delayed apps are Contacts, Calendar and QuickSearchBox; **not AndroidAuto**.

For no disabled-system record and intact stock AA:

[Code block omitted from public report; see authored source where available.]

The duplicate check precedes registration/signature-update logic. A larger staged versionCode alone does not evade it. There is no generic last-directory-wins rule or persist-specific AA preference.

If a disabled-system record exists, `scanPackageLI(File...)` compares scanned system version with saved active version, may suppress the base copy, or remove the update and enable a newer system package. The later `/data/app` scan and `expectingBetter` recovery implement the normal updated-system model. Raw smali also resolves a JADX ambiguity: unexpected fallback paths are logged and **skipped**, not scanned with an uninitialized flag. The fallback whitelist covers system priv-app/app, vendor and oem, **not `/persistdata/app`**. Persist-only updates must not borrow an assumed rollback guarantee from that branch.

Existing dumps show several real persistdata packages (beansconverter, telematics, lpaconverter, intuitionengine, an att package). This proves the directory is used, not that it has replaced an intact `/system` copy. `SwmcApkInstallerHelper.getInstalledPackages()` enumerates persist-source or UPDATED_SYSTEM_APP packages; stock AA is not included merely by being a system app. Whether a real delivery plan targets AA still needs its catalog/payload.

## APK authentication: precise correction

There are three different checks:

1. **PackageParser per-entry JAR verification.** It always reads/verifies `AndroidManifest.xml`. Only when `(flags & PARSE_IS_SYSTEM)==0` does it add the other non-META-INF entries to the verification list. Raw smali confirms the conditional. `loadCertificates()` consumes the entry stream, then gets its certificate chains. Core StrictJarFile loads META-INF at construction but verifies individual content through the entry's stream, not by eagerly reading every classes.dex byte.
2. **Signer identity comparison.** `verifySignaturesLP` checks the stored package and shared-user signatures. For a trusted system-directory scan a package-only signature change can be tolerated. The exception branch still compares shared-user signatures and throws -104 for incompatible system-UID membership. Self-signing is not equivalent to Wind River identity.
3. **Normal install validation.** A normally submitted APK is fully certificate-collected before replacement. Keeping stale META-INF while changing DEX does not create a valid fully signed update. Neither existing unsigned candidate is a correctly signed official update.

`collectCertificatesLI` can reuse saved signatures/keysets when codePath and modification time match and compatibility/recovery updates are unnecessary. Stock's OEM package cache adds another trusted-file optimization; persist scan does not use that cache flag. These mechanisms assume protected, authenticated provisioning. They are not a supported shell API.

**What follows:** a signed-manifest-only trusted boot scan is not proof that modified DEX is cryptographically authenticated. **What does not follow:** that our unsigned APK will load, that a staged AA wins the duplicate, that shell may provision the directory, that the original can be retained as fallback, or that replacing a trusted package is safe. No alternate integrity-bypass package was constructed or staged in this pass.

Original AA APK signer SHA256 remains `2156c50e3c08347f28adccb49ae839394053a45767f153bd8f036ae33d5f8568` (Windriver/WindriverRDC). This identifies package trust, not the official delivery root key. Public certificate possession does not confer signing capability.

## Red Bend delivery, authentication and staging

### Format and native trust chain

BasicService selects `smm_release` normally or `smm_debug` via `persist.rb.debug`, then System.loadLibrary resolves the installed library. It initializes the engine with private files directory + `dma_config.txt`. The asset named `.txt` is binary/encrypted config material, not readable plaintext policy; the actual effective config may be a private copied/updated version. `AESCryptHandler` is an engine callback for encryption/decryption, **not proof of an official payload signing bypass**.

Native evidence now extends beyond strings. In the available **release** library:

| Function / range | ELF VA | Relevant behavior |
| --- | --- | --- |
| SWM_DP_validate | 0xDBB7C | Checks/reads a DP and security parameters, calls VDM_SWMC_PL_Security_verify. |
| VDM_SWMC_PL_Security_verify | 0x144940 | Root/expiry/chain checks, digest calculation, signature extraction/hex decoding and RSA verification path. |
| VDM_SWMC_PL_Security_splitFile_verify | 0x144E18 | Separate data/script file variant. |
| VDM_SWMC_PL_Security_getRootCaPath | 0x143E30 | JNI lookup of Ipl.getRootCertificatePath. |
| SWMC_Security_X509_PEM_to_certificate | 0x143F60 | BIO memory input -> PEM_read_bio_X509. |
| Root-certificate analysis range | 0x143FB4..0x144298 | Obtains root path, reads root bytes and converts PEM. End is a neighboring known function, not a recovered source declaration. |
| Entity-chain analysis range | 0x1442EC..0x144940 | Reads payload certificates, checks expiry, obtains issuer key and calls X509_verify; invalid verification branches to failure. |
| Signature-helper analysis range | 0x142F5C..0x1437A0 | RSA public-key extraction, PKCS1/PSS paths and digest-algorithm choices, including SHA256/SHA512. Actual payload selects parameters. |
| SWM_DP_ValidateSignature | 0xDB784 | Separate streaming checksum-style signature comparison. **Do not confuse this with the X.509/RSA authenticity routine.** |
| VDM_SWMC_PL_Dp_validateExternalSignatureDp | 0x13D0B0 | This separate release entry is a 16-byte stub: stores zero through r0, returns zero. Its name is not evidence of an additional verification step. Nor does it remove the distinct SWM_DP_validate -> Security_verify path. |

Release library SHA256 `75776A5BD89AF6C213C2AC6F533DB38A77C6CA0D67A539BDEEE3C1338C8285CD`; debug `1AB9C3ECEAA48CD4A246AEA36011D670CF6D151979995B9F5EABF15825A9D231`. Both contain authentication routines; the presence of a debug library does not demonstrate disabled verification. `DMA_redbend_SCOMO_getConfigSignatureValidationVal()` queries **`enable_dp_signature_validate_once`**. Its name/value lookup alone does not establish a publicly writable off switch or the effective policy on this head unit.

`SWM_DP_validate` passes data ranges, signature offset/length and certificate metadata to the verifier; the verifier reads a chain, computes a digest and checks the signature with a leaf key chained to the root. Exact real-world component layout/coverage/algorithm must be validated against an authentic payload; no fabricated header or unsigned container was submitted. Native strings identify `update_%s.dp`, `dp.dp`, `_delta.rdp`, `rb_ota.zip`, security-header signature/certificate offsets and delta-header versions. These are format evidence, not a file extension-based authenticity check.

One exact format discriminator is recovered: release `SWM_DP_IO_isRbDp` at **0xDD054** compares the first **20 bytes** against `RedBendEFDPackage` followed by three NUL bytes, then reads a little-endian 32-bit value at offset20 and accepts **4 or 5** on the recognized-header path. `SWM_DP_IO_getRbDpPreambleSize` at **0xDD04C** returns **24**. The magic bytes are at ELF VA/file offset **0x16B0B2 / 1487026** in this library. This establishes a supported Red Bend delivery-package preamble, not the complete Honda outer USB format or proof that a particular AA update uses this package flavor. `SWM_calcUpdatedSignature` shows a complemented table-driven 32-bit checksum loop, supporting the distinction between that checksum and RSA authenticity.

The trust anchor **is now collected**, with subject/key/fingerprints and verified self-signature in the current-stack section above; its absence in the earlier inventory has been resolved. TLS `VdmRawConnection.openHttps()` separately supports a BKS trust store and TLS1.2/hostname checks; do not assume the `.crt` delivery root is that BKS store. libdevelupdate's EVP_DigestVerify/PEM RSA public-key path is another verification mechanism whose actual key identity is not established here.

The Java helper can extract ZIP content; native USB update validation/extraction functions are available and were disassembled. Some large functions include undecoded words/literal data, explicitly recorded in LLVM diagnostics. Current service dispatch is now available and traced; absent authentic metadata/native recovery behavior still prevents claiming the complete accepted Honda USB/OTA grammar, all eligibility checks, or that every native path was fully recovered.

### Type202 execution and absence of a rollback transaction

[Code block omitted from public report; see authored source where available.]

`getPackageArchiveInfo(...,0)` is not a full signing/authentication check. Authentication must come from the delivery engine and later package parsing. The path does not call normal PMS replaceSystemPackageLI or create a disabled-system backup explicitly.

Defects/limitations material to reversibility:

- Existing-package branch ignores the return value of `renameFilePath`; it can continue after rename failure.
- `removeOldApk` may recurse through the **old APK parent directory**, including its native libraries. Its recursive helper logs deletion failures, while the parent branch returns true regardless of whether deletion succeeded.
- Thus an old read-only `/system` copy can survive an attempted delete while the installer reports success. At next ordinary boot that surviving stock copy can win the duplicate scan. This is a reason staging may have no effect, not a safe behavior to probe.
- No old `.apk` backup, atomic multi-file transaction, sync/health validation or crash-triggered restore appears in this Java path. A temp rename only bounds one file's visibility. It does not protect old app removal, package state, native libraries, catalog updates or power loss.
- `uninstallSystemApp` simply finds the installed package and calls the same removal helper. It does not promise to select a particular staged source or re-enable `/system`.
- Generic ZIP paths include extraction to `/cache/persistdata_app/`. Asset `rb_ua.conf` declares a workdir, a data partition mapping into a private temp directory, `no_reboot=1` and other installer options. These are per-installer asset options, not a guarantee that the ClientService postinstall branch will not reboot.

No staging or rollback command is supplied: selecting/deleting the wrong active source would be destructive and is not justified by this analysis.

## Failure and removal cases

| State / failure | Available-code result | Rollback quality |
| --- | --- | --- |
| Intact valid stock, plain staged duplicate, no disabled-system record | Stock registers first; later duplicate rejected. Higher staged version alone does not change this. | No actual update occurred; removing staged file is not an execution test. |
| Staged invalid APK with intact valid stock | Per-file PackageManagerException logged; stock can remain active. System-directory invalid files are not automatically deleted by the non-system invalid-package cleanup branch. | Residual bad file can remain; not transactional recovery. |
| Persist-only package absent/invalid, no disabled original | Startup cleanup can remove the system package setting and wipe package data because no package was registered. | Poor; no original backup created by this path. |
| Staged package parses but crashes/decoder fails | PMS parsing is not a projection health check. No type202 rollback on runtime failure found. | Poor/unestablished. |
| Normal signed system-app update fails during installation | replaceSystemPackageLI attempts to rescan old package, re-enable disabled system package and write restored settings. Restoration can itself fail and is logged. | Better transaction semantics, not guaranteed vehicle recovery. |
| Normal updated system app removed through PMS | deleteSystemPackageLI uses disabled-system record, removes update/native binaries, enables/rescans original and updates permissions/settings. | Code-backed restore path, but **downgrade can clear app data**: older disabled version causes DELETE_KEEP_DATA to be cleared. No claim of data-preserving rollback. |
| Raw file removed while process is running | No persist-specific live observer/rescan was identified; loaded code and package database can remain stale. | File deletion alone is not rollback. |
| Reboot after removal, stock retained | Normal stock-first scan can register original, subject to update records, ABI/dependencies and data compatibility. | Conditional boot behavior, not tested rollback. |

No watchdog/health monitor guaranteeing recovery from an arbitrary privileged staged APK was found. The existing raw sepolicy has not been fully decoded; a pathname or UID1000 declaration alone is not proof of shell provisioning rights. File contexts explicitly label `/persistdata/app` as `persist_app_file`, `/data/honda/lib` as `data_honda_lib_file` and `/data/local/tmp` as `shell_data_file`.

## Ranked candidates

Rank reflects the next **research/deployment design** priority, not permission or present executability. Risk describes a future execution, not this offline audit.

| Rank | Candidate | Availability / relevance to our patch | Risk | Rollback quality |
| --- | --- | --- | --- | --- |
| 1 | Compatible official signed AA component through **normal PMS updated-system path**, if OEM supports it | Current OEM code confirms normal PMS for Garmin/generic APKs, **not an actual AA update**. Compatible AA payload/eligibility still missing; cannot carry arbitrary custom DEX without appropriate trust. | Moderate, conditional on exact payload/dependencies | Best documented persistent-code restore; explicit update removal exists, may clear AA data and needs vehicle recovery plan. |
| 2 | OEM-signed instrumentation/helper, or validated per-process wrapper entry | Best potential temporary route; signature/helper or property/SELinux/startup prerequisites unresolved. [Detailed audit](TEMPORARY-EXECUTION.md). | Moderate to high until narrowly validated | In-memory changes could revert on process exit; helper/property/files may still require cleanup. No working route yet. |
| 3 | Genuine authenticated Red Bend AA type202 component / factory app staging | Current staging implementations present; actual AA catalog/payload absent. Stock duplicate still blocks simple override. Factory failure cleanup can delete all persistdata apps. | High | Weak: no AA transaction/health restore, destructive cleanup, old-source deletion attempts and reboot. |
| 4 | Existing Honda `/data/honda/lib` extension infrastructure | Real writable-partition dependency indirection; no demonstrated shell write, AA classpath insertion or injection entry point. | High, broad vehicle subsystem impact | Poor; persistent symlink/code changes and multiple process lifetimes. Not a suitable first test. |
| 5 | Raw trusted-directory APK manipulation, including relying on manifest-only boot checks | A trust assumption was identified, not a safe deployment method. Requires protected-file access and still faces duplicates/dependencies. | High | Poor/unestablished; not recommended for vehicle testing. |
| 6 | Modified `/system`, developer image, Compulsion Loading, cross-generation flash | Outside current scope; verified image/authentication/hardware compatibility issues unresolved. | Critical | No demonstrated recovery. Excluded as first-test paths. |

No rank is currently green/ready. Specifically, do not convert the manifest-only finding into a vehicle test, remove stock to resolve duplicates, or use a debug updater as a signing bypass.

## Missing evidence that changes the decision

Highest value, in order, obtained later from existing files/official sources or separately authorized read-only collection:

1. Genuine D.1.6.4-compatible update payload containing AA (if one exists), full manifest/catalog/signature chain, supported install and downgrade policy. A confirmed F-series fullscreen receiver is useful for code diff, not proof of D-series deployability.
2. Effective Red Bend component/config metadata (including private generic component catalog if obtainable legitimately), original installer/engine configs and an authentic signed payload. **Public root certificate already collected**; private signing keys are not required for analysis.
3. Actual AA AppType/ota_app_id and component installer classification, plus any needed current global native verifier/recovery implementations. **All seven requested active service directories are now collected/decompiled**; they are not a remaining gap.
4. Package-manager state needed to select the exact rollback branch: disabled-system records, saved AA source/version/shared-user identity, active native library resolution, prior successful official component update logs. Current public package dump alone is insufficient.
5. A documented OEM restore procedure applicable to this exact hardware and signing/firmware branch. Two named system partitions and a saved APK are not proof of recovery.

Updated practical acquisition plan: [2022-reference-needed.md](2022-reference-needed.md). Nothing here authorizes collection from, or changes to, the vehicle in this pass.
