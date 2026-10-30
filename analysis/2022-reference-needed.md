# 2022+ Acura RDX fullscreen reference artifacts needed

Current priority clarification: this reference is **optional bonus evidence**. The exact2021/D.1.6.4 recovery and test plan does not depend on obtaining it; see [D-series material priorities](OFFICIAL-D-SERIES-ARTIFACTS-NEEDED.md) and [recovery first](RECOVERY-FIRST-PLAN.md).

Status: offline requirements, 2026-10-22. No internet or head-unit commands used for this pass. No 2022+ fullscreen Android Auto implementation was found in the local collection; all eight AA DEX copies are identical to the current 2021 receiver.

## Practical acquisition plan: smallest definitive comparison

Priority is **original receiver code from one observed fullscreen F-series unit**, not a complete firmware flash. A before/after pair on the same 2022+ hardware remains the best way to identify the actual fullscreen update; it is not required to start a definitive binary comparison of that receiver with our already preserved D.1.6.4 receiver.

| Order | Acquisition route | Concrete request / result | Constraint |
| --- | --- | --- | --- |
| 1 | A researcher/owner who already has a local dump or already-working read-only ADB | Share the original active AA package directory, receiver JNI library and the small metadata/session bundle below. An existing dump can be transferred without touching a vehicle. | Confirm the unit actually negotiates/renders fullscreen; a firmware label or stretched screenshot alone is insufficient. Do not ask an owner to enable hidden diagnostics, root, install a collector or change firmware merely to obtain files. |
| 2 | Original owner-downloaded official fullscreen USB/OTA package | Preserve the exact outer download and every manifest/catalog/certificate alongside the payload; inspect/extract it locally, including deltas requiring the matching base. | Local Red Bend Ipl.createLinkFile points to `https://usb.acura.com`; this is a code-derived acquisition lead, **not a freshly verified download link or assurance F.1.4.1 is publicly available there**. Use the vehicle's legitimate supported eligibility flow, never alter VIN/configuration to obtain another branch. Do not install the download. |
| 3 | Service/research archive with both original pre/post files | Obtain the original signed components and matching version/part-number manifest rather than screenshots, repacked APKs or a patch advertised for another model. | A dealer-installed update may not expose a raw APK independently. Request original package/image files only through an authorized source; no recovery/partition operation is needed for this plan. |

No source was contacted and no website was accessed. Suggested owner/researcher request, ready to send manually if desired:

> We need an unmodified Android Auto receiver from an Acura RDX that visibly supports fullscreen Android Auto, preferably F.1.4.1. If you already have a dump or read access, please share the active `com.honda.androidauto.projection.sink` APK(s), its native receiver library, package/build/display information and existing AA initialization logs. We do not need VIN, accounts, vehicle configuration changes, root, installation, reboot, flashing or private signing keys. Original bytes and source paths matter; do not re-sign or repack the APK. Please describe the firmware, phone/Android Auto version and how fullscreen was confirmed.

### Minimum bundle, first transfer

1. **Active original AA APK and all splits**, identified by package `com.honda.androidauto.projection.sink`, including manifest/resources/classes*.dex. Known 2021 source is `/system/app/AndroidAuto/AndroidAuto.apk`; use the reference's actual PackageManager path, which may be under persistdata/data or renamed. Retain whole package directory if possible.
2. **The actually used `libautoreceiver_jni.so`** and any adjacent receiver-specific libraries. Known 2021 location is `/system/app/AndroidAuto/lib/arm/libautoreceiver_jni.so`. If absent from APK, resolve nativeLibraryDir/package directory and ELF dependencies. Do not send only an APK and silently assume native code is unchanged.
3. **Small text provenance bundle:** full getprop snapshot, package path/dump, panel/app/window bounds and reported DPI, anonymous unit/model/region/part-number identifier, capture date, exact phone/Android/AA versions, confirmation that an overscan/stretch override was not responsible for the observed wide layout. Avoid VIN/serial/account data in shared metadata.
4. **Existing buffered receiver startup/session log**, ideally showing advertised/selected configuration, DPI/margins/fps, active callback and renderer/decoder bounds, plus a picture of actual full-width layout. Do not clear logs, start apps, alter display settings or reconnect/reboot merely to produce a test under our current no-vehicle-action instruction.
5. **Only if DEX is stripped:** matching ODEX/VDEX/ART sidecars and necessary boot image/classpath artifacts. If normal classes*.dex are present, a whole boot framework is not required to diff getVideoMode and Java GAL/renderer behavior.

This is the minimum for a definitive **receiver-level** Java/native comparison. It cannot alone prove the window-policy, TTI or installer change. If code calls new OEM helpers, obtain exactly the matching dependency JARs next. If HMI/GAL is identical while observed layout differs, escalate to display/framework/overlay/input set below. An APK-only diff cannot certify deployment compatibility or safety.

For a later separately authorized owner collection, the lookup operations would be read-only `pm path <package>`, `dumpsys package <package>`, `getprop`, `dumpsys display/window` and copying the resolved existing files. **None was executed here and no collection script was deployed.** If ADB is not already available, an existing official download/dump is preferable to a new head-unit setup experiment.

### Local intake and comparison procedure

- Keep incoming originals under `reference/rdx2022/confirmed-fullscreen/` (or paired `before`/`after`), with original source paths, sizes and SHA256 hashes. Preserve original signing metadata; avoid repacking before hashing/verifying.
- Check firmware/build, ABI, APK version/signing certificate and classes/native completeness. A shared signer is necessary for some deployment paths, but not proof that F-series software is compatible with D-series hardware/framework.
- Diff HMI mode creation, configuration order/protobufs, renderer/codec crop and input registration first. Diff native ELF build IDs/exports and relevant functions; compare manifest/resources and new framework dependencies.
- Separate three conclusions: changed fullscreen implementation, which platform dependencies it needs, and whether a supported reversible installer exists. **Do not cross-flash, transplant or install reference files as part of acquisition/diff.**

## Clean comparison design

Obtain a **before/after pair from the same 2022-generation RDX head unit**, ideally the exact update that first enables fullscreen. Historical research identifies F.1.4.1 / bulletin B23066 as the relevant later-generation release; this attribution has not been independently fetched or verified in this offline pass. Confirm actual installed versions and visible behavior rather than assuming a model year or firmware label guarantees fullscreen.

Compare before vs after on that same hardware first, then compare changed components with the 2021 D.1.6.4 collection. Keep region, trim, navigation/audio options, phone/Android/AA versions, physical panel, and user projection mode comparable. A single newer APK is useful but cannot isolate all changes between 2021 and 2022 platforms.

Preserve original bytes and directory structure. Store captures under `reference/rdx2022/{before,after}/`, each with a manifest containing original device path, capture date, firmware/build, file size and SHA-256. Record package versionName/versionCode, ABI, target SDK, sharedUserId/UID, signing certificate SHA-256 and public key fingerprint. Do not obtain or request private signing keys or alter vehicle configuration. VIN is not required; use an anonymous paired-unit identifier.

Paths below are the **known 2021 paths/package names** and are exact lookup targets, not a claim that every 2022 file has the same location. Obtain the newer package-path inventory and resolve renamed/moved/split packages. Include all splits and the full package native-library directory; a lone base APK may omit essential code.

## Minimum useful AA reference set (highest priority)

| Artifact | Known 2021 target / exact name | Reason |
| --- | --- | --- |
| Original AA receiver APK(s) | Package `com.honda.androidauto.projection.sink`; `/system/app/AndroidAuto/AndroidAuto.apk`; also check its actual active source under `/persistdata/app` or `/data/app` using a package-path snapshot | Compare `presentation.HMIPresenter`, `VideoMode`, `integration.AbstractGalIntegration`, `GalIntegration`, `video.ProjectionRenderer`, `DimensionUtils`, `ui.ProjectionActivity`, `VirtualPointer`, resources and manifest. |
| Receiver native library | `/system/app/AndroidAuto/lib/arm/libautoreceiver_jni.so`, or ABI-equivalent paths in APK `lib/<abi>/`, app nativeLibraryDir, `/system/lib[64]`, `/vendor/lib[64]` | Native capability/discovery messages, supported codec modes, selected configuration index, margin handling, input normalization. Preserve every dependency identified through ELF `DT_NEEDED`. |
| All DEX/optimization sidecars | `classes*.dex` in APK; adjacent `oat/<abi>/*.odex`, `.vdex`, `.art` or legacy `.odex` if present | Required if the reference APK is stripped or uses a different runtime. Record runtime/boot classpath and matching boot image if deodexing is necessary. |
| Manifest + resource originals | Binary `AndroidManifest.xml`, `resources.arsc`, all `res/`, overlays and splits | Mode/profile can move into resources, product overlays, metadata or model-specific implementations. Do not substitute only a decompiled manifest. |
| Public signing material | APK `META-INF` and any v2/v3 signing block; certificate fingerprints and verifier report | Determine whether D/F branches use compatible package/shared-UID signers; a matching public certificate does not supply the private key. |
| Reference AA session evidence | Existing buffered logcat covering initialization/phone connection, selected source config, margins, codec output format and renderer bounds; screenshots showing actual fullscreen | Distinguish changed negotiation from a stretched old source; identify primary/fallback indices, density, framerate and crop. Do not clear logs or change device settings to obtain this evidence under the present offline instruction. |

If only a small transfer is possible, obtain the original AA package directory plus the native receiver and a package/build/display/log snapshot from each version first.

## Framework, display and input set

Obtain the following from **both** reference versions, including new equivalents and their dependencies:

- `/system/framework/honda-manager.jar`: OEM configuration, LCD, diagnostic, update and vehicle interfaces.
- `/system/framework/honda-lib.jar` and other Honda projection/HMI framework JARs on the receiver's actual classpath.
- `/system/framework/framework.jar`, `services.jar`, `android.policy.jar` if present, `framework-res.apk`: logical display policy, B-Zone resources, WindowManager, input and package loading rules.
- `/system/framework/com.honda.ui.jar` and its resource/overlay dependencies: UI/touch dispatch and HMI layouts.
- `/system/framework/com.honda.app-fixup.jar`: framework-loaded runtime lifecycle overrides.
- `/system/framework/com.honda.touchbridge.jar`, `/system/bin/touchbridge`, its ELF dependencies and matching configuration/calibration files.
- `/system/framework/com.honda.auto.voicerecognition.jar`, `com.broadcom.bt.jar` and all other shared libraries listed for the reference AA package. These are classpath dependencies, not presumed resolution owners.
- `/system/priv-app/SystemUI/SystemUI.apk` and splits/native libraries; actual package `com.android.systemui`. Capture any variant-specific SystemUI overlays.
- APK implementing `com.honda.miscellaneous.HondaDisplayService`, normally package `com.honda.miscellaneous`; actual package path and native dependencies.
- `/system/usr/idc/`, `/system/usr/keylayout/`, `/system/usr/keychars/` and relevant `/vendor/usr/` input configuration; touchbridge/TTI model and mapping/calibration files under `/system/etc`, `/vendor/etc`, or readable OEM directories. Record exact filenames and hashes from the reference inventory rather than guessing names.
- `/system/etc/media_codecs.xml`, `media_codecs_*.xml`, `media_profiles.xml` if present, and `/vendor/etc/media_codecs*.xml` equivalents; decoder component libraries and firmware versions for the actual reference OMX/Codec2 stack.
- Native display/LCD components implementing `lcd_service` and their dependencies; Java `HondaLCDManagerService` may remain inside services.jar.

Input evidence should include the receiver's advertised touchpad dimensions, physical dimensions and flags; raw range/device identifiers from an existing input dump; logical event coordinates before/after fullscreen; and pointer/TextureView rectangles. The 2021 app advertises 1325x720 and 60x40 mm separately from video; do not assume these should become 1920x720 on the reference.

## Factory/profile/CarPlay comparison set

- Original FactorySettings schema/config definitions and property/ECU/app enumeration from both states. Known DB path `/persistdata/honda/factorysettings/factorysettings_database.db`; obtain an authorized readable copy or schema/value export, not a write or bypass of a protected path. A copied live SQLite DB may require matching `-wal`/`-shm` files or a consistent export. Vehicle-specific configuration should be protected/redacted as appropriate.
- Factory flashing/configuration templates/overlays used to populate that DB, where readable or present in an official update package. Known D-side directory `/persistdata/honda/factoryflashing/`; record actual reference names.
- CarPlay package `com.honda.carplay`, known `/system/priv-app/CarPlay/CarPlay.apk`, package native libraries including `libdrcarplay.so`, `/system/bin/dr_carplay_service` and dependencies. Fullscreen AA and CarPlay may share a new HMI/config flag, but their negotiation implementations remain distinct.
- Honda Settings package `com.honda.settings`, known `/system/app/TJBASettings/TJBASettings.apk`, for a fullscreen selection UI or persisted OEM flag.

## Official update/recovery set

For assessing a signed, reversible deployment route, obtain these **as original files**, never by triggering an update during collection:

- Official update payload for the relevant before/after transition, including outer container, manifests, component catalog/IDs, signatures, public verification certificates, version/region/model constraints and any image/delta payloads.
- Reference-unit packages `com.honda.auto.softwareupdate`, `com.honda.auto.transportservice`, `com.honda.ota`, `com.honda.auto.factoryflashing`, and their full APK/native directories. D.1.6.4 service implementations are now collected/decompiled; the missing comparison inputs are the reference unit's active counterparts. Resolve its actual paths from package inventory.
- `com.redbend.client`, known `/system/priv-app/RedBendApp/RedBendApp.apk`, native engine libraries and original assets (`files/dma_config.txt`, component catalogs/partlists, installer mapping/config files).
- `/system/lib[64]/libdevelupdate.so`, `libswupdate.so`, `libtransport.so`, native update daemon(s) implementing `swupdate` and `update_transport`, and associated public-key/config files.
- **`/system/etc/security/sw_update_root.crt`**, the Red Bend delivery verification root returned by Ipl.getRootCertificatePath; effective component catalogs and authentic included payload certificate chains. The D.1.6.4 root is now collected/identified as OTA Honda Root CA V1; obtain the reference unit's root for comparison rather than assuming equality. Also obtain independent developer-image public keys where referenced; they are not presumed identical to the Red Bend root or APK signer.
- Honda Diagnostics `com.honda.auto.diagnostics`, known `/system/app/HondaDiagnostics/HondaDiagnostics.apk`, and `com.honda.auto.diagnostics.service`; these identify official workflows but their operations must not be invoked during this offline investigation.
- If available from an official package: boot/recovery/update ramdisk manifests, slot/partition layout, verified-boot metadata and rollback/version policy. Do not dump protected partitions, enter recovery, reboot, remount or flash to obtain them under current instructions.

The D-side code stages some system-app updates in `/persistdata/app` and scans that path at boot. This does not prove a 2022 payload will work on 2021, that unsigned APKs are accepted, or that replacing the original APK is reversible.

Exact **2021 baseline** directories below are now fully collected; their APK basenames, signatures and hashes are recorded in the current-stack report. Obtain the active counterpart on the reference, even if its path/name changed. The reference unit's basenames are not established; resolve them and collect its complete directories rather than assuming the 2021 names.

| Package | Known 2021 codePath |
| --- | --- |
| `com.honda.auto.softwareupdate` | `/system/app/SoftwareUpdateService` |
| `com.honda.auto.transportservice` | `/system/app/Transport` |
| `com.honda.ota` | `/system/app/tjbaOTA` |
| `com.honda.auto.factoryflashing` | `/system/app/FactoryFlashingService` |
| `com.honda.auto.diagnostics.service` | `/system/app/DiagnosticsService` |
| `com.honda.miscellaneous` | `/system/app/HondaMiscellaneous` |

The seven requested D.1.6.4 package directories, including these baseline services, have now been collected: [current stack](current-update-stack/README.md). Obtain their active 2022 counterparts when updater compatibility needs comparison. Current static evidence and signing/rollback limitations: [DEPLOYMENT-PATHS.md](DEPLOYMENT-PATHS.md).

## Version and state evidence to accompany every capture

Obtain already available/read-only snapshots of:

- Firmware version (`ro.build.fwversion`), build display ID/fingerprint/date, Android release/API/security patch, product/device/board/hardware and ABI list; native build IDs where present.
- Kernel version, head-unit model/part number, panel dimensions/DPI/refresh, boot/runtime SELinux state and filesystem/verified-boot layout. Hardware identity should be compared without editing it.
- Full package/library/path/version inventory, receiver package dump, effective permissions/exported components/shared UID, active APK source path and signing fingerprints.
- Display/window state in stock and actual fullscreen projection, including physical vs app bounds, B-Zone dimensions and whether a display override was active.
- Receiver startup/discovery selection logs, renderer/decoder output bounds and existing touch/input dumps. Record phone model, Android build and Android Auto version for the compared sessions.
- Official update source/name/version and known success/rollback history; do not assume presence of `system1`/`system2` proves a safe automatic rollback.

## Diff acceptance criteria

Identify the exact changed code/resource/native configuration controlling: offered codec resolution and margins, UI/real density, framerate/profile, selected configuration order/index, display aspect/pixel aspect, window/B-Zone policy, renderer cropping and touchpad normalization. A changed package version, a fullscreen screenshot, or a different hardcoded number alone is insufficient evidence of a portable fix.
