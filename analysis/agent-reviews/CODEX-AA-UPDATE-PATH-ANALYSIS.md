**SUPPORTED: this firmware can accept a compatible, identically signed AA APK as an updated system app. That does not establish that a newer F-series APK will run—or provide full screen—on D.1.6.4.** Normal undo is removal of the update through PackageManager, which rescans the stock copy. **If the update has a higher versionCode than stock, that undo wipes AA data even with `-k`.**

1. **Files inspected**

   Principal source references below use these aliases; all cited line numbers were counted with `rg -n` or numbered `Get-Content` output.

   | Alias | File |
   |---|---|
   | PMS | [PackageManagerService.java](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/pm/PackageManagerService.java) |
   | Settings | [Settings.java](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/pm/Settings.java) |
   | Parser | [PackageParser.java](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Framework/sources/android/content/pm/PackageParser.java) |
   | InstallerService | [PackageInstallerService.java](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/pm/PackageInstallerService.java) |
   | AMS | [ActivityManagerService.java](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/am/ActivityManagerService.java) |
   | PMS-smali | [PackageManagerService.smali](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/deployment-evidence/services-smali/com/android/server/pm/PackageManagerService.smali) |
   | AA-manifest | [AndroidManifest.xml](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/resources/AndroidManifest.xml) |
   | MD repository | [PackageLocalRepository.java](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/warning-phonefree-20261025-190517/detector-jadx/sources/com/honda/maliciousdetector/data/PackageLocalRepository.java) |
   | MD service | [MDService.java](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/warning-phonefree-20261025-190517/detector-jadx/sources/com/honda/maliciousdetector/service/MDService.java) |

   Also inspected: `PROJECT-RULES.md`, `AGENTS.md`; the requested deployment/recovery/test/temporary-execution reports; current-stack signer metadata and APKs; saved package/property dumps; AA’s `GalService`, `StartPreferences`, integration, presenter and activity code; framework/AppFixup lifecycle hooks; Honda MSS `PackageMonitor`; detector receiver/preferences code; stock receiver ELF; preservation manifests; and the primary public bulletin.

   Read the saved `services.jar` and `pm.jar` DEX directly in memory to check downgrade policy and actual `pm` command handling. No extracted files were written.

2. **Files changed**

   **None.**

3. **Commands run**

   Read-only command families, with complete invocations/output retained in this conversation:

   - `Get-Content`, numbered line-range reads, `rg -n`, and scoped `rg --files --no-ignore`.
   - `Get-FileHash ... -Algorithm SHA256`.
   - API22-specific verification of stock AA plus seven updater APKs:

     ```text
     java -jar <installed-apksigner.jar> verify --min-sdk-version 22 --max-sdk-version 22 --verbose --print-certs <apk>
     ```

   - `aapt dump xmltree <apk> AndroidManifest.xml`.
   - `tar -tf apks/AndroidAuto-current-2026-10-22.apk`.
   - An inline Node ZIP/DEX reader for the saved firmware’s `installLocationPolicy`, `Pm.runInstall`, `Pm.runUninstall`, and `Pm.runClear`.
   - Python 3.12 with `-B`, reading ZIP entries and ELF headers/dynamic dependencies in memory.
   - Web retrieval of the primary Honda/NHTSA bulletin.

   Initial Windows Python aliases were unavailable; Python 3.12 worked. A PowerShell ZIP inspection was blocked by constrained language mode; subsequent ZIP inspection used `tar`/Python. Some literal wildcard searches failed and were replaced with supported searches.

   **No device commands, installation, uninstall, clear, reboot, build, or Git mutation ran.**

4. **Tests run and results**

   | Check | Result |
   |---|---|
   | API22 signature verification | Stock AA **and all seven updater APKs passed**, exit `0`; all use certificate SHA256 `2156c50e3c08347f28adccb49ae839394053a45767f153bd8f036ae33d5f8568`. |
   | Binary manifest checks | All eight declare `android.uid.system`; AA versionCode `22`, minSdk `21`, targetSdk `22`; AA has no persistent declaration. |
   | Stock APK native entries | `stock_APK_lib_entries=[]`. |
   | Receiver ELF | ELF32, ARM machine `40`; six dependencies listed under Q6. |
   | Firmware DEX inspection | Confirmed actual legacy `pm` route, option flags, and downgrade-policy bit test. |
   | Frozen artifact hashes | All four preservation anchors matched; details in item 10. |
   | Live install/rollback | **Not run.** No new runtime validation. |

5. **Findings**

   **Q1 — Install admission and branches**

   **CONFIRMED in saved firmware code:** actual `pm install` uses legacy `IPackageManager.installPackageAsUser`, rather than the session-create path. `-r` sets flag `2`; `-d` sets `128`. The DEX findings are identified precisely in item 6.

   The replacement route is:

   ```text
   InstallParams.installLocationPolicy
     → staging/copy
     → installPackageLI
     → replacePackageLI
     → replaceSystemPackageLI
   ```

   The last branch is selected because installed AA is a system app. An already updated system app continues through the system replacement branch.

   | Candidate versionCode | Plain `pm install -r` | With allow-downgrade flag |
   |---|---|---|
   | Same (`22`) | **CONFIRMED:** not rejected merely for equality. Lower base/split revision codes can still produce `-25`. Identical stock bytes pass this comparison. | Unnecessary for identical bytes. |
   | Higher | **CONFIRMED:** passes version comparison; other checks still apply. | Unnecessary. |
   | Lower | **CONFIRMED:** rejected in location policy before replacement; final error `INSTALL_FAILED_VERSION_DOWNGRADE (-25)`. | **CONFIRMED:** this saved implementation skips `checkDowngrade` when bit `128` is present. No `ro.debuggable` test occurs in that policy branch. |

   **The `ro.debuggable=0` fact does not establish a downgrade prohibition on this implementation.** The property is captured as zero; both Java and direct DEX show the flag-controlled skip. This is a code finding, not a recommendation to downgrade.

   **CONFIRMED:** shell has the necessary saved grants: `INSTALL_PACKAGES`, `DELETE_PACKAGES`, `CLEAR_APP_USER_DATA`, and cross-user permission. PMS explicitly recognizes UID2000 as an ADB installer. It does not require root merely because the target is a system package. **UNKNOWN:** current user restrictions/uninstall blocks at the moment of any future experiment.

   Additional admission conditions include:

   - Matching installed-package signature: otherwise `-7`.
   - Matching shared-user signing identity / unchanged shared user: otherwise `-8`.
   - Compatible APK parsing, SDK, required shared libraries, ABI and providers.
   - Internal storage, sufficient space, successful native preparation, rename/relabel and dex optimization.
   - Package verification, if enabled for the operation.
   - No forbidden test-only APK without the corresponding flag.

   Relevant failures include `-4` storage/rename, `-9` missing shared library, `-11` dexopt, `-12` incompatible minimum SDK, `-13` provider conflict, `-15` test-only, `-19` location, `-22` verification, `-24` UID mismatch and `-113` no matching ABI. Some later native-copy errors become `-110`.

   **Q2 — Successful installation changes persistent state**

   | State | Static conclusion |
   |---|---|
   | `/system/app/AndroidAuto/AndroidAuto.apk` | **CONFIRMED normal path:** retained as the stock base. First replacement does not schedule its code deletion. |
   | `/data/app/<package>-N` | **CONFIRMED:** staging directory is renamed to the first unused numeric suffix; code/resource paths change to that location. |
   | `/data/system/packages.xml` | **CONFIRMED:** active package state is updated; original is retained in disabled-system state and serialized as `<updated-package>`. Install status, paths, timestamps, installer, grants and shared-user state are written. |
   | Native libraries | **CONFIRMED:** APK-provided libraries are copied for a supported ABI; directory installs use `<codePath>/lib/<instruction-set>`, normally `lib/arm` here. Native-directory links may change. |
   | ART output | **CONFIRMED:** PMS requests dexopt/patchoat as needed; failure can reject installation. **UNKNOWN:** exact generated `/data/dalvik-cache` filename/output for this unperformed AA update. Java delegates that implementation to installer/native code. |
   | Existing AA data | **CONFIRMED normal matching-UID path:** reused, not uninstalled/wiped. **Exception:** UID/filesystem ownership mismatch recovery can erase data. |
   | Code cache | **CONFIRMED:** explicitly deleted during system replacement, including before later installation failure is known. |
   | Permissions | **CONFIRMED:** recomputed; shared-UID grants are involved. Unknown permission names are logged rather than necessarily rejecting installation. |
   | Preferred activities | **SUPPORTED:** replacement does not perform the ordinary data-removal preferred-activity clearing. Renamed/removed components can invalidate resolution; boot removes dangling preferred activities. |
   | Honda defaults | **UNKNOWN:** preservation of every Honda last-used/default-package setting. No comprehensive guarantee follows from retaining AA data. |
   | Running AA | **CONFIRMED:** `killApplication(..., "replace sys pkg")`; replacement also scans with the update-kill flag. This is disruptive even for identical code. |

   **Honda observers:**

   - **CONFIRMED:** package-added/replaced broadcasts are emitted. Honda MSS observes added/changed/removed packages and updates media-source discovery.
   - **CONFIRMED:** framework `Application.onCreate()` invokes Honda ApplicationFixup. AA is exempt from the audio lifecycle fixup; Acura lifecycle callbacks still register and broadcast resumed package/activity names.
   - **CONFIRMED:** `GalService` reads per-device preferences keyed by phone serial; `StartPreferences` persists device status/name, first-run state and auto-start preference. Normal replacement preserves these files, but a newer APK could migrate them.
   - **CONFIRMED:** car information is obtained from `UnitInfo`, including firmware/build/product-serial-derived information. Replacing AA does not turn D.1.6.4 into F.1.4.1.
   - **UNKNOWN:** all side effects of a not-yet-obtained newer build.

   **Q3 — Undo, data handling and failure branches**

   **CONFIRMED:** plain `pm uninstall <package>` defaults to all-users deletion in this firmware’s CLI. For updated system AA:

   ```text
   pm → PackageInstallerService.uninstall → PMS.deletePackage
      → deletePackageX → deletePackageLI → deleteSystemPackageLI
      → remove update → enable saved system package → scan stock path
   ```

   Do **not** substitute `pm uninstall --user 0`: the CLI can set the system-app per-user deletion flag, leading to hiding/removing the package for that user instead of removing its update.

   | Operation | Result |
   |---|---|
   | `pm uninstall <pkg>`, update version equals stock | **CONFIRMED:** forces keep-data on, restores stock versionCode22. |
   | `pm uninstall -k <pkg>`, update version equals stock | Same data-preserving branch. |
   | Either uninstall form, update version greater than stock | **CONFIRMED:** clears keep-data, removes AA data and ordinary preferred activities, then restores stock. `-k` does not override this. |
   | Update version lower than stock | **CONFIRMED:** stock version is greater/equal, so update removal keeps data. |
   | `pm clear <pkg>` | **CONFIRMED:** clears data; does **not** remove the update or select stock. AMS force-stops AA and removes relevant task/URI state. |

   **Additional `pm clear` concern:** PMS calls `removeKeystoreDataIfNeeded(userId, appId)`, ultimately `KeyStore.clearUid(1000)` for AA/user0. **CONFIRMED code call; UNKNOWN actual key impact.** Treat this as potentially affecting shared-UID keystore entries, not just an AA-private namespace. Normal uninstall’s last-shared-user handling differs.

   Update code deletion is scheduled through `FileInstallArgs`; cleanup removes its directory/native files and requests `rmdex` for its code paths. **SUPPORTED:** corresponding compiled artifacts are removed; **UNKNOWN:** successful removal of every artifact in a real trial. Negative `rmdex` results are logged.

   Failure cases:

   - **CONFIRMED:** missing disabled-original record → uninstall fails.
   - **CONFIRMED:** user restriction, uninstall block or active admin can reject deletion.
   - **CONFIRMED:** original rescan failure logs `Failed to restore system package` and returns failure. Update removal/data deletion may already have happened.
   - **CONFIRMED:** installation failure after replacement begins attempts to rescan the old package; restoration itself can fail.
   - **SUPPORTED:** killing the `pm` client after dispatch does not cancel an operation already running in system_server.
   - **CONFIRMED:** boot recognizes incomplete-install records and cleans their recorded code/data paths. Settings uses backup-file rotation and sync.
   - **UNKNOWN:** outcome at every power-loss/reboot point. This is not proof of an atomic, lossless rollback.

   **Stock-file preservation:** normal consistent install/update-removal branches leave the `/system` APK intact. **A universal “all branches” guarantee is UNKNOWN.** Incomplete-install cleanup deletes recorded paths without a `/data/app` containment check; corrupted/inconsistent settings are outside the normal-state assurance.

   **Q4 — Reboot selection and crash recovery**

   **CONFIRMED:** PMS scans system locations before `/data/app`. With disabled-system state present:

   - Stock version **less than or equal to** recorded update version: stock is ignored in favour of the update. Equality is sufficient; an identical versionCode22 update remains selected after reboot.
   - Stock version **greater than** update: PMS removes update resources and enables stock.
   - The `expectingBetter` fallback handles cases where stock was scanned but the expected update never appears; it re-enables/rescans stock.
   - Incomplete-install cleanup and failed original rescan have separate failure paths.

   **CONFIRMED:** current AA is nonpersistent: no manifest declaration, and saved package flags omit `PERSISTENT`. `GalService.onStartCommand()` returns `2` (`START_NOT_STICKY`). AMS marks repeatedly crashing nonpersistent processes bad and removes them.

   **SUPPORTED:** a newer AA could repeatedly crash, fail linking or lose projection without stopping Android boot. **UNKNOWN:** absence of broader HMI/system-service failures. AA has UID1000 and substantial OEM integration. Also, a candidate could introduce `persistent=true`; that must be checked.

   **CONFIRMED:** a runtime-crashing update that scans successfully remains selected after reboot; there is no demonstrated health-based automatic rollback here. Recovery is normal update removal **if shell/PMS remain reachable**. Recovery when Android/control access fails remains **UNKNOWN**.

   **Q5 — Reinstalling identical stock bytes**

   **Recommendation: do not describe it as harmless or recommend immediate execution. SUPPORTED as a useful later, separately reviewed experiment**, narrower than installing unknown newer code.

   Conditional documentation only; **none executed**:

   ```sh
   pm install -r /system/app/AndroidAuto/AndroidAuto.apk
   pm path com.honda.androidauto.projection.sink
   dumpsys package com.honda.androidauto.projection.sink

   # Only after confirming active update + intact disabled stock:
   pm uninstall com.honda.androidauto.projection.sink

   pm path com.honda.androidauto.projection.sink
   dumpsys package com.honda.androidauto.projection.sink
   ```

   Expected transition:

   ```text
   stock /system, vc22
     → /data/app update, vc22, SYSTEM + UPDATED_SYSTEM_APP,
       disabled stock record, retained AA data
     → stock /system, vc22, update removed, retained AA data
   ```

   This exercises same-version admission, replacement, process interruption, package-state writes and update removal. **It does not exercise higher-version rollback/data wiping, newer data migration, or newer dependencies.**

   Residual risks include storage/dex failures, process interruption, code-cache deletion, package observers, native lookup changes, restore failure and power loss. The APK contains **no native libraries**; identical APK bytes therefore do not reproduce the original package-directory topology.

   Before/after evidence should include package path/full dump, enabled/installed/stopped states, hidden-system record, grants, preferred activities, available `/data` space, APK/library identity and link topology, process state, and complete install/removal/Honda logs. Capture after install, after removal, and—only if separately approved—after reboot. Protected settings/cache evidence must use an authorized readable source; do not assume shell can copy `packages.xml` or AA preferences.

   **Detector:** **SUPPORTED expected exemption.** PMS assigns system/update flags before the added broadcast, and Honda’s classifier accepts either. **Not an absolute guarantee:** lookup failure is treated as detection; prior history alone can produce later warnings. Reinstallation does not clear detector history.

   Extra review needs: stock/native provenance and lookup, precise same-version rollback acceptance criteria, surviving independent control access, power/storage conditions, observer effects, and an explicit decision about the unresolved recovery limitations.

   **Q6 — Newer-build dependencies and offline checklist**

   **CONFIRMED stock dependencies:**

   - Required shared libraries: `com.honda.ui`, `com.broadcom.bt`, `com.honda.auto.voicerecognition`.
   - OEM APIs for vehicle information, hardware control, factory configuration, state-machine/power, Bluetooth/telephony, audio/media/navigation and voice recognition.
   - Honda HMI/B-zone/window behaviour; touchpad registration uses presenter-derived dimensions and physical size.
   - `System.loadLibrary("autoreceiver_jni")`.
   - Saved receiver: ELF32 ARM, 1,918,948 bytes, SHA256  
     `031797DD4B0AECCA007A3AD7AF31C365BA3D47BEBDA8C94BFF13C5289F464C50`.
   - `DT_NEEDED`: `libc.so`, `liblog.so`, `libm.so`, `libstdc++.so`, `libstlport.so`, `libdl.so`.
   - Manifest permissions include USB management, audio, Bluetooth, location, window/task access and multiple `auto.permission.*` services.

   **UNKNOWN:** which of these a newer APK changes or whether full screen depends on additional updated firmware components.

   Offline candidate checklist:

   | Check | Required examination |
   |---|---|
   | Provenance | Hash untouched APK/base/splits and associated native libraries; retain source paths and donor firmware evidence. |
   | Signing | `apksigner verify --min-sdk-version 22 --max-sdk-version 22 --verbose --print-certs`; require API22-valid v1 signing and matching signer. “Honda-signed” alone is insufficient. |
   | Identity | Exact package and `android.uid.system`; versionCode **and revision codes**; complete split set. |
   | SDK/format | minSdk ≤22; inspect targetSdk, DEX version/opcodes and resource/XML compatibility. A higher targetSdk alone is not the minimum-SDK rejection. |
   | Manifest | Required libraries/features, permissions, components, exported services, process names, persistent flag and changed intent contracts. |
   | Java linkage | Compare external class **and method/field descriptors** against saved boot/framework/Honda/shared-library DEX. Class-name existence alone is insufficient; inspect reflection too. |
   | Native linkage | ARM32-compatible libraries; JNI signatures; recursive `DT_NEEDED` and undefined-symbol resolution against this unit’s libraries. |
   | Library packaging | Determine whether the newer native receiver is inside the signed APK or supplied separately by firmware. An adjacent donor `.so` is not installed by `pm install <apk>`. |
   | Permissions | Compare every requested name/protection level against saved system permission definitions/dumps and shared-UID grants. Missing names can leave accepted code unable to operate. |
   | OEM behaviour/data | Diff display negotiation, B-zone/SystemUI calls, input registration, media/VR/phone contracts, stored preferences/databases and migrations. |

   **Crucial limitation:** an APK-only donor update may run newer Java against the old globally supplied receiver library. No compatible native replacement should be assumed.

   **Q7 — Ranked risks and distinguishing observations**

   Rankings are **SUPPORTED engineering judgments**, not measured probabilities.

   | Rank | Risk | Distinguishing observation in a separately authorized trial |
   |---|---|---|
   | 1 | Java/native/OEM contract incompatibility | Install succeeds; AA crashes or fails connection with `NoSuchMethodError`, `ClassNotFoundException`, `UnsatisfiedLinkError`, missing JNI/symbol or service errors. |
   | 2 | Full screen requires other F-series components | AA works, but retains old bounds/B-zone or incorrect input mapping; negotiation/window/input logs distinguish this from a launch failure. |
   | 3 | Data loss/migration on rollback | Stock code returns but saved devices/first-run/auto-start state resets or becomes incompatible. Higher-version removal is statically data-destructive. |
   | 4 | Transaction/restore failure or power interruption | Install/uninstall failure, incomplete package state, missing active package or original-rescan errors. Independent shell/PMS availability determines practical recovery. |
   | 5 | Broader privileged integration disruption | Audio/VR/phone/HMI abnormalities or OEM service failures beyond AA. |
   | 6 | Admission rejection | Specific `INSTALL_FAILED_*`; active code path remains stock if rejection precedes replacement. |
   | 7 | Detector/history effects | Detector log names the package or shows lookup failure. An existing boot warning alone cannot attribute a new detection to this experiment. |

6. **Primary evidence for findings**

   - **Baseline:** `AA-manifest:3–11,44–58`; `adb/RDX-Audit/packages/androidauto-sink.txt:81–105`; captured D.1.6.4 property at `analysis/parallel-aa-receiver/live-test-01/pre-properties.stdout.txt:243`; `adb/RDX-Audit/pulls/default.prop:6`.
   - **Signer correction:** `analysis/current-update-stack/README.md:13–23` lists seven updater packages, with AA as comparator—not seven including AA. Fresh verification covered **eight** APKs and returned exit0 for each.
   - **CLI/Downgrade:** saved `pm.jar` `Pm.runInstall`, code item `0x2fc4`: `-r` at PC `0x001b`, flag2 at `0x0025`; `-d` at `0x0068`, flag128 at `0x0072`; `installPackageAsUser` at `0x016d`. Saved `services.jar` `InstallParams.installLocationPolicy`, code item `0x218a8c`: bit128 test at `0x0026`, conditional skip at `0x0028`, downgrade call at `0x002a`. Also `PMS:7712–7733,7805–7807,11479–11492`.
   - **Shell:** `adb/RDX-Audit/logs/dumpsys-package-full.txt:14385–14409,14439,14523`; `PMS:7104–7136`; `InstallerService:637–647`. Prior ordinary install/removal success: `analysis/parallel-aa-receiver/live-test-01/install.stdout.txt:3`, `uninstall.stdout.txt:1`.
   - **Replacement:** `PMS:8896–8938,8970–8977,8648–8671,8728–8843`; signatures `4427–4449`.
   - **Persistent state:** `Settings:197–227,1131–1146,1181–1200,1291–1301`; `PMS:8032–8078,8091–8119,8522–8529,5863–5897,4912–4921`.
   - **Data/grants/preferences:** `PMS:4022–4083,6149–6175,6241–6266,10312–10328`; `Settings:491–507`.
   - **Undo:** `PMS:9157–9274,9309–9345,9367–9425,9482–9518`; raw corroboration `PMS-smali:10679–10725,10748–10791`. Cleanup/dex: `PMS:8155–8205`.
   - **Clear:** `AMS:3782–3824`; `PMS:9602–9678`. Boot/interruption: `PMS:1425–1509,1599–1615,3650–3679`; `Settings:1446–1455,1464–1477`.
   - **Crashes/processes:** `PMS:8747,5960–5965`; `AMS:3969–3987,4122–4160,8761–8783,12686–12723`; `AA-manifest:44–50`; `GalService.java:581–587`.
   - **Honda observers:** `decompiled/AppFixup/sources/com/honda/appfixup/ApplicationFixup.java:16–27`; `AudioApp.java:12`; `AcuraLifecycleCallbacks.java:54–61`; `decompiled/Services/sources/com/honda/auto/mss/PackageMonitor.java:29–48`; `GalService.java:736–744,1272–1320,1694–1713`; `StartPreferences.java:89–145`.
   - **Detector:** MD repository `57–68,88–92`; MD service `61–99`; detector `UserLocalRepository.java:24–29`.
   - **Dependencies:** AA-manifest `12–58`; `GalService.java:48–61`; `GalIntegration.java:120–126`; `AbstractGalIntegration.java:152–168`; `HMIPresenter.java:717–756`; `ProjectionActivity.java:1417–1426`; `GalReceiver.java:266`. Fresh ELF/ZIP command output establishes the native facts.
   - **Bulletin:** primary [B23066 v3, pages 1–2](https://static.nhtsa.gov/odi/tsbs/2026/MC-11028529-0001.pdf) confirms 2022–2025 RDX, F.1.4.1 dated 12/09/25, and full-screen AA support. It does **not** establish APK-only portability.

7. **Assumptions**

   The hypothetical candidate is untouched, complete, has the exact package/shared-user identity and genuinely matches the installed signer. No candidate APK currently exists for this review. Saved firmware evidence represents the supplied unit; live binary/hash parity was not reacquired.

8. **Unresolved uncertainties**

   Candidate compatibility, actual native-library resolution after stock reinstallation, exact ART output paths, current restrictions/free space, all Honda observer effects, data migrations, every interruption outcome, and recovery without working Android/PMS remain **UNKNOWN**. No live updated-system-AA restoration has been demonstrated here.

9. **Exact diff summary**

   **None; no files edited or generated.**

10. **Preservation checks performed**

   Fresh SHA256 checks matched all frozen anchors:

   - M5 APK: `A22E9649…EE8F40`
   - Disabled M6 APK: `D4DAC2DD…28761F`
   - Receiver DEX, both preserved copies: `2FDBC63F…E7C235`
   - API22 qualifier APK: `86350131…99FC1F`

   Stock AA SHA256: `F9E976F44853C9DB7C8FF5A8610C10CAF1E0B4D1E5BE0886F4F52505C5348146`.

   Saved `services.jar`: `98B4C3D3E2B0F2DDF3CEB9B582DED93DC0E73D922BB913D0B263E8812A0B6474`; saved `pm.jar`: `B13CAFB18DC7DC7C8041A393617DCFB4CAE4CBDD54BED877FE22F7351412491F`.

   No frozen artifact was rebuilt or modified; no key files were opened; no vehicle/device operation or milestone action occurred.