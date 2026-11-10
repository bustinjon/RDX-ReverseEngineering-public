1. **Files inspected**

All paths are relative to `C:/Users/REDACTED\Desktop\RDX-ReverseEngineering`. Evidence references below use these aliases:

| Alias | Path |
|---|---|
| `S` | `analysis/test-prep/todo-tests-20261103` |
| `B` | `S/builds/T150-bundle` |
| `H` | `B/source/analysis/parallel-aa-receiver/usb-helper` |
| `J` | `H/source/com/rdx/fullscreen/usbhelper` |
| `USB` | `decompiled/Services/sources/com/android/server/usb` |
| `PMS` | `decompiled/Services/sources/com/android/server/pm/PackageManagerService.java` |
| `HP` | `decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/settings` |
| `E` | `analysis/parallel-aa-receiver/evidence` |
| `MD` | `analysis/parallel-aa-receiver/warning-phonefree-20261025-190517/detector-jadx/sources/com/honda/maliciousdetector` |

Inspected:

- `PROJECT-RULES.md`, `AGENTS.md`; public `LATEST-TEST-PLAN.md`, `START-HERE.md`, `PORTING.md`, README and diagnostic-app README.
- `S/tools/{Run-Test,After-PowerOff,Add-Phone,Build-Test,Switch-Source}.ps1`; `S/VISIT.md`, README, baseline manifest, T20/T32 cards; T100–T130 `RESULT.md`.
- `B/{test.json,Prepare-Test.ps1,Prepare-TimedStage.ps1,Collect-Test.ps1,collect-owned-processes.sh,source-manifest.json,HondaPhonePolicyTest.java}`.
- `H/AndroidManifest.xml`, `H/res/xml/device_filter.xml`; relevant portions of `J/{UsbHelperService,HondaPhonePolicy,PersistentMode,PersistentBootService,BootBlockerReceiver,SettingsActivity,AppSettings,HelperActivity,PermissionClickService,AaMediaSourceService,HondaNavBridge,HondaNavProviderService,AaSessionService,AaOverlayService}.java`.
- Shared/live `UsbBulkTransport.java`, `UsbAttachActivity.java`, `BootBlockerService.java`, `NightModeWatcher.java`; T150 `GalReceiver.java`.
- `tools/car-test/CarTest.Core.ps1`; relevant `scripts/Build-RdxUsbHelper.ps1` source; launcher README.
- `USB/{UsbSettingsManager,UsbService}.java`; framework `PackageMonitor.java`; Honda MSS `PackageMonitor.java` and `MediaSourceService.java`; relevant PMS permission code.
- `HP/{StartPreferences,DeviceListActivity,SelectDeviceActivity,ConfirmDeviceDeletionActivity}.java`; detector `UserLocalRepository.java` and `MDService.java`.
- `E/device/{native-provenance.json,stock-package.stdout.txt,receiver-library-paths.stdout.txt}`; native-summary dependency metadata; stock APK **entry names only**.
- Setup-kit plan, detector review, USB-default research, user-guide notes, recorded Diagnostics instructions and corresponding `USBModeSwitchActivity.java`; existing Honda update research.

2. **Files changed**

None.

3. **Commands run**

Read-only PowerShell `Get-Content` with numbered/ranged output, scoped `rg --files`, `rg -n`, `Test-Path`, and `tar -tf apks/AndroidAuto-current-2026-10-22.apk` with filename filtering/counting. Exact invocations and output are in this conversation.

Some guessed paths and PowerShell literal-wildcard searches failed; subsequent inventories located the relevant files. No Git, network, build, ADB, device commands, repository scripts, or agents were invoked.

4. **Tests run and results**

No executable tests or builds ran. Static checks produced:

[Code block omitted; consult project-authored source.]

The APK check examined names, not entry contents. T100–T130 reports document car results; they do not establish T140/T150 success. `S/builds/T100-bundle/RESULT.md:20` records a successful cold start with accessibility restored; T130 records later feature passes. `PROJECT-RULES.md:3` explicitly gives current results precedence over stale roadmap text.

5. **Findings, ranked options, and concrete plans**

**1 — Daily-use installation**

**Feasible, but it needs a dedicated installation path and a safe first-run state. Simply leaving a test session uncollected is unsuitable.**

Today’s T150 preparation:

- Verifies target/firmware/Home state, then uses `install -r`, pulls the installed APK back and checks its hash. It stops old helper/session/overlay services and enables the accessibility component while retaining other services. (`B/Prepare-TimedStage.ps1:64–103`; `tools/car-test/CarTest.Core.ps1:183–220`)
- Configures `usb.CONFIGURE_HONDA_NEVER` with an explicit phone serial. Honda’s Disabled/Never preference is **operator asserted**, not read or written by this action. (`B/Prepare-TimedStage.ps1:103`; `J/UsbHelperService.java:146–190`)
- Automatically grants `WRITE_SECURE_SETTINGS`, then broadcasts `PERSISTENT_ON`. The broadcast saves the preference; it does **not** immediately enable accessibility. (`B/test.json:72–84`; `J/BootBlockerReceiver.java:22–25`)
- Uses cooperative PhonePreference mode. The runner’s Honda force-stop and repeated kill loop belong to its **ForceStop branch**, which T150 does not select. (`tools/car-test/CarTest.Core.ps1:223–252`)
- Initially prepares a timed test, then disarms its watchdog and starts owned long-drive logging/monitoring. Those processes are test infrastructure, not daily-use dependencies. (`B/Prepare-Test.ps1:25–67`)

Collect force-stops Hackura, restores the original accessibility values only when the current list matches its expected write, stops owned diagnostics, and verifies absence. The outer UNDO then broadcasts `PERSISTENT_OFF`, revokes the grant and checks accessibility removal. Neither path clears saved USB defaults, the phone policy or Honda’s per-phone preference. (`tools/car-test/CarTest.Core.ps1:131–152`; `B/Collect-Test.ps1:70–90`; `S/tools/Run-Test.ps1:63–74`; `B/test.json:78–82`)

Important first-install counterexample: persistent mode defaults **on**; Honda’s media-source bind can start the persistent boot service; with no configured main phone, helper startup attempts the legacy Honda force-stop and VBUS reset. Installation can therefore expose a startup race before configuration. (`J/PersistentMode.java:24`; `J/AaMediaSourceService.java:129–130`; `J/PersistentBootService.java:44–52`; `J/UsbHelperService.java:187–194`)

**Options ranked:**  
1. Dedicated daily installer plus app-owned setup/health screen, with unconfigured startup refusing USB actions.  
2. Separate, explicit manual installation/activation checklist using the same primitives.  
3. Reusing the test launcher with a new fully designed daily mode; avoid merely skipping Collect because its preparation creates watchdog/logging state.

**Proposed flow:**

1. Prepare a release candidate whose unconfigured state performs no Honda stop, VBUS reset, permission request or session start; mark setup complete only after saving the explicit device policy.
2. Park, unplug phone/dongle, verify supported firmware/API/ABI and normal Diagnostics access; record original accessibility settings and each affected Honda phone preference.
3. Install the owner-built APK. Configure the main phone and owner-assigned device names before permitting helper startup.
4. Owner sets Honda Android Auto to Disabled/Never for each participating phone/dongle identity.
5. Perform the one-time privileged grant; enable persistent mode, Remember this phone and warning auto-dismiss. Explicitly run `ensureAccessibilityResult()` and verify **ON and connected**.
6. Return to phone mode and Honda Home; connect the selected device. Confirm remembered defaults across both normal USB and AOAP enumeration where prompts occur.
7. Verify replug, cold starts with device absent/present, Home/return controls and warning dismissal. Finish with a persistent-health result, without test timers or cleanup hooks.
8. For updates, retain package/signing identity and component names; preserve owner choices through migrations; verify grant/defaults/accessibility after replacement and cold start.

The saved PMS preserves an already granted development permission during permission recomputation, provided the updated package still requests it. This supports grant survival on ordinary updates, but is not a live update result. (`PMS:6149–6191,6263–6264`)

| Step | Privileged ADB genuinely needed? | App/UI alternative |
|---|---|---|
| APK installation | Current route uses ADB | Standard installer UI may suffice; head-unit availability **UNKNOWN** |
| Initial secure-settings grant | Yes for the established ordinary-app route | App cannot self-grant; PMS enforces `GRANT_REVOKE_PERMISSIONS` |
| Main-phone policy and names | No intrinsic requirement | Save app preferences; main-phone setup UI is currently missing |
| Persistent preference | No | Existing Developer switch |
| Accessibility activation | No after grant | Existing “Turn auto-accept on now”; normal accessibility UI is another option |
| Remembered USB defaults | No | System checkbox/chooser; app cannot directly call privileged `setDevicePackage` |
| Honda Disabled/Never | No | Owner uses Honda’s UI |
| Stop own session/overlays | No | Graceful app shutdown |
| Force-stop Honda | Unnecessary in cooperative daily mode | Preserve per-phone Never policy |

Evidence: `PMS:2262–2281`; `USB/UsbService.java:153–160`; `J/SettingsActivity.java:176–229`.

**2 — Clean-install test**

**A functional fresh-install baseline is achievable; a literal “never had any third-party app” state is not achievable within the permitted scope.**

The detector stores `DID_USER_INSTALL_3RD_APP_KEY`, exposes only a true-setting method, and warns at boot even after the current app scan finds nothing. Do not clear, disable or otherwise modify the detector. (`MD/data/UserLocalRepository.java:23–30`; `MD/service/MDService.java:80–99`)

**Options ranked:**  
1. Functional clean reinstall on this car, explicitly retaining detector history.  
2. Separately authorized first-install validation on another previously unmodified car, after owner disclosure.  
A factory reset is not a scoped or proven method for restoring this history.

**Proposed procedure and exact acceptance checks:**

1. Record current package version/UID, accessibility list and switch, USB preferences, Honda device entries and working stock behavior.
2. Unplug the device and allow graceful session shutdown. Verify navigation unregister/focus release and overlay removal before process termination.
3. While the grant remains available, execute persistent-off behavior and remove only Hackura’s accessibility entry. Verify both full and shorthand component forms are absent; preserve unrelated entries and their effective enabled state.
4. Use Honda Settings → Apps → Hackura → **Clear defaults**. Inspect `dumpsys usb`: no Device/Accessory preference may point to `com.rdx.fullscreen.usbhelper`.
5. Revoke `WRITE_SECURE_SETTINGS`, stop Hackura and uninstall **without retaining data**. Check package/path absence, no Hackura process/services/windows, and no residual accessibility entry.
6. For each participating identity, delete its Honda Android Auto device record through the OEM UI to exercise fresh first-run behavior. Deletion removes status, name and FRX state; the absent-status default is Ask User. This differs from preserving an existing owner’s original preference.
7. Power-cycle and check stock operation and absence of Hackura’s tile/media source/provider. Record any detector warning as expected retained history.
8. Install through the proposed new-user flow, configure a phone from empty app data, grant once, remember USB defaults, and repeat the cold-start/replug checks from item 1.

Primary checks: `pm path`, `dumpsys package`, `dumpsys activity services`, `dumpsys window`, `dumpsys accessibility`, the two secure-setting reads, `dumpsys usb`, and visible Honda device/source lists. These are **future checks, not commands executed here**.

Uninstall normally clears USB defaults through the saved USB package monitor. Explicit pre-uninstall clearing and post-uninstall checking make that observable. Detaching removes transient device permissions. (`USB/UsbSettingsManager.java:389–390,618–619,1035–1063`; `J/PermissionClickService.java:145–148`; `HP/StartPreferences.java:33–35,108–121`)

Do not clear all Honda AA data: the required reset is per device, and the existing AA update research identifies additional shared-UID data-clear concerns. Exact recovery of an original preference that was never recorded is **UNKNOWN**.

**3 — Setup tool feasibility, extraction and device naming — final release step**

The current build requires:

| Input | Current origin/use |
|---|---|
| Protocol root certificate, client certificate and private key | Builder references `decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/common/PlatformCertKeysImpl.java`; fields are named in `scripts/Build-RdxUsbHelper.ps1:27–29`. That material-bearing file was not opened |
| Packed protocol container | `analysis/parallel-aa-receiver/assets/private-test-material/platform.creds`; runtime expects that asset path and three length-prefixed strings (`J/AaSessionService.java:866–879`) |
| Vendor native receiver | `analysis/parallel-aa-receiver/evidence/device/libautoreceiver_jni.so`, packaged as `lib/armeabi-v7a/libautoreceiver_jni.so` (`scripts/Build-RdxUsbHelper.ps1:46–52,99–102`) |
| Car compatibility configuration | Firmware/API/ABI, geometry/input/audio behavior, Honda APIs and service contracts; target-specific, not protocol secrets |
| APK signing identity | Owner-local update identity; distinct from protocol credentials and not extracted from the car |

Captured native provenance is `/system/app/AndroidAuto/lib/arm/libautoreceiver_jni.so`, 1,918,948 bytes, SHA-256 `031797DD4B0AECCA007A3AD7AF31C365BA3D47BEBDA8C94BFF13C5289F464C50`. Saved path evidence identifies a link to `/system/lib/libautoreceiver_jni.so`. (`E/device/native-provenance.json:2–4`; `E/device/receiver-library-paths.stdout.txt:1–2`)

**Critical correction:** pulling the stock APK and extracting its library is insufficient on the inspected firmware: its 98 entries contain **zero native-library matches**. The tool needs a direct, read-only native-file acquisition fallback.

The recorded access path is Back + Home + Track/Card hold → Detail Information & Setting → another hold → Developer Diagnostics → USB Mode Switch → ADB; accept debugging authorization, then return normally to Home. Restore **Apple CarPlay** mode afterward. The recorded physical sequence is for the original 2021 car; other cars remain **UNKNOWN**. (`analysis/agent-reviews/DRAFT-FORUM-POST-2022-OWNERS.md:23–30`; `decompiled/HondaDiagnostics/sources/com/honda/auto/diagnostics/developer/USBModeSwitchActivity.java:15–20,46–49`)

**Options ranked:**  
1. Owner-local profile/extract/build/install tool with known-firmware support and explicit stop on unsupported inputs.  
2. Guided local commands and local build using the same validated stages.  
Sending material to the project or supplying a pre-authenticated receiver conflicts with `PROJECT-RULES.md:32–40`.

**Proposed tool stages:**

1. Explain local-only handling and obtain the owner’s confirmation before each stage, as the project rules require.
2. Read a minimal target profile; identify the actual stock AA package/code path and native-library location, rather than hardcoding this car’s paths.
3. Pull the owner’s stock APK; locate the required protocol fields locally without printing their values or dumping material-bearing decompilation to logs.
4. Inspect APK entry names for the library; if absent, obtain the declared/resolved stock native file from the same connected car. Validate ARM ABI, dependencies and JNI contract.
5. Build locally in an isolated workspace using the owner’s signing identity; ensure crash reports, logs, archives and support exports exclude extracted material.
6. Show compatibility findings and install the finished receiver only after owner confirmation.
7. Run the separately defined daily activation flow and retain a local recovery record.

**Rule conflict to resolve in the design:** the setup tool currently may change nothing beyond installing the receiver. Automatically granting permissions or writing secure settings exceeds that literal allowance. Rank 1 under existing rules: owner performs the separate activation step; rank 2: operator explicitly revises the rule to permit narrowly specified activation operations. This report does not authorize either live action. (`PROJECT-RULES.md:35–39`)

Firmware differences include native ABI/JNI/dependencies, protocol-provider layout, package paths, Honda navigation/audio/voice APIs, display/input geometry, binder getters, permissions and Diagnostics access. Whether protocol values are unique per car, shared by firmware family, or interchangeable is **UNKNOWN**; always acquire from the owner’s connected car. The current native hash pin is one compatibility anchor, not a universal value. (`scripts/Build-RdxUsbHelper.ps1:49–50`; public `PORTING.md:5–9`)

**Naming plan:** store an owner-editable alias separately from USB product names, keyed by validated device identity; display alias first, with identity available for disambiguation. Preserve aliases through recent-history eviction, disable/re-enable and updates. Current storage records USB product names in an eight-entry recent list; the page has toggles but no rename control. Main + four extras is the current allowance. (`J/HondaPhonePolicy.java:9,30–43`; `J/UsbHelperService.java:782–788`; `J/SettingsActivity.java:185–204`)

**4 — Other Android phone brands**

The protocol transport is not inherently OnePlus-only, but entry and pre-AOAP switching remain partly OnePlus-specific:

- Manifest filter: Google AOAP `18d1:{2d00,2d01,2d04,2d05}`, OnePlus `22d9` any PID, and smartBox `2717:ff40`. (`H/res/xml/device_filter.xml:3–13`)
- `isNonAoapPhone()` accepts only `0x22d9`. The main-phone raw switch path therefore excludes another brand unless it also qualifies through the explicitly added-extra path. (`J/UsbHelperService.java:739–755`)
- `HelperActivity.phonePlugged()` separately recognizes AOAP, OnePlus and the known dongle; changing only the service would leave this entry path incomplete. (`J/HelperActivity.java:49–55`)
- `HondaPhonePolicy` is serial-based and brand-independent, but its legacy null-main state permits unrestricted identities; public setup should refuse that state. (`J/HondaPhonePolicy.java:89–105`)
- Each device still needs Honda Disabled/Never; the policy does not establish that preference. AOAP switching already probes protocol support before sending accessory-start. (`J/HondaPhonePolicy.java:3–6`; `J/UsbHelperService.java:799–838`)

**Options ranked:**  
1. Brand-independent discovery with explicit serial enrollment; retain narrowly scoped filters for validated normal-mode identities plus current AOAP filters.  
2. Generated owner-specific VID/PID/serial filters, at the cost of rebuilding to add identities.  
3. A finite list of verified vendor filters; workable but incomplete and costly to maintain.  
A catch-all USB filter has the greatest unwanted chooser/default interaction risk and should not be the initial approach.

The saved parser supports `serial-number` attributes, so owner-specific filtering is feasible. Do not infer or publish an “all Android” VID list from memory; exact additional identities are **UNKNOWN** until measured. (`USB/UsbSettingsManager.java:97–115`)

**Plan:** discover devices without opening/transferring; let the owner identify/name/enroll one; use the same enrollment check for main and extra devices; update launcher detection, attach handling and polling together. Before every permission request, raw open, AOAP switch and session handoff, require the explicit identity. Keep unknown/missing serials denied. Validate identity again after re-enumeration; provide explicit pairing if a device changes serial, without a VID-only fallback.

Test another brand as **main and extra**, normal USB modes, AOAP modes, cold start, locked/unlocked phone, permission rejection, saved defaults, disable/remove, changed/missing serial, unsupported AOAP, simultaneous attached devices, dongles and unrelated peripherals. Verify unknown devices receive no open/claim/control transfer. Test Android Auto/phone-version and Bluetooth call/media interactions separately. The current bulk transport still requires a supported AOAP PID and interface-0 bulk pair. (`analysis/parallel-aa-receiver/src/com/rdx/fullscreen/projection/UsbBulkTransport.java:19–42`)

**5 — Uninstall / restore stock — Developer option, final step**

**Options ranked:**  
1. Developer “Restore stock and uninstall” preparation, followed by normal uninstall confirmation, plus a laptop verification fallback.  
2. Entirely guided laptop restoration using the same checks.  
Ordinary uninstall alone removes the app but cannot restore Honda choices it never recorded.

**Proposed exact sequence:**

1. Park, unplug the phone/dongle and gracefully end projection; release USB, audio/voice focus, media session, navigation guiding focus/provider registration and overlays.
2. Set persistent mode off; cancel boot restoration and warning scans; remove only Hackura’s accessibility component while the grant is still held.
3. Clear Hackura’s USB defaults through App info; preserve unrelated defaults. Stop the media source so it no longer remains selected.
4. Restore each Honda device preference to its recorded pre-install value. For a newly introduced device, offer deletion/reset to the OEM first-run state.
5. Revoke the secure-settings grant, stop Hackura and uninstall without retaining data. Use normal uninstall UI or the owner-authorized host route.
6. Verify package/process/services/windows/accessibility/defaults are absent. Verify Hackura is absent from Honda’s source list and navigation providers, then power-cycle and test stock AA, audio, navigation and controls.
7. Restore the intended USB phone mode and any setup-only debugging choice the owner changed. Retain the disclosure that the detector warning may remain.

Current Developer “Start without laptop: off” only saves a boolean; it is **not** equivalent to `PERSISTENT_OFF` and does not itself remove accessibility or stop existing services. (`J/SettingsActivity.java:223–225`; `J/BootBlockerReceiver.java:27–31`)

Navigation cleanup already abandons guiding focus and unregisters **Hackura** by name; media cleanup releases its session. Honda MSS observes package removal and deletes that package’s source records. Prefer these normal paths over editing OEM databases. Whether forced termination/uninstall alone cleans every navigation registration is **UNKNOWN**, so graceful shutdown and postchecks are required. (`J/HondaNavBridge.java:203–226`; `J/AaMediaSourceService.java:212–215`; `decompiled/Services/sources/com/honda/auto/mss/PackageMonitor.java:38–48`; corresponding `MediaSourceService.java:544–551`)

Include permission overlay, AA overlay and the inherited BootBlocker overlay in shutdown verification. (`J/UsbHelperService.java:893–905`; `J/AaOverlayService.java:1090–1145`; `analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/BootBlockerService.java:99–104`)

**6 — Honda software-update risk and recovery**

**No inspected evidence establishes what a future Honda update will preserve.** Treat these as compatibility risks, not predictions:

| Possible change | Effect / recovery |
|---|---|
| Grant reset or permission protection change | Recheck grant and actual accessibility write; regrant only if supported. If no longer grantable, manual accessibility may be needed after each restart |
| Accessibility list reset | Existing persistent path retries through five minutes, but requires its grant and a boot/media-bind trigger |
| USB defaults or descriptors change | Repeat owner-approved Remember flow; defaults include VID/PID/class/manufacturer/product/serial |
| Diagnostics/debugging path changes | Follow the actual OEM UI; if unavailable, host extraction/regrant/recovery may be blocked |
| Stock AA/native/JNI/dependency changes | Profile and qualify the new firmware; re-extract locally only when necessary and supported |
| Honda navigation/media/voice/binder changes | Disable affected integrations and requalify; do not reuse numeric transactions by analogy |
| User-app/data removal | Reinstall and repeat owner setup from the local recovery record |

Evidence: `J/PersistentBootService.java:16–28,44–54`; `USB/UsbSettingsManager.java:86–94`; `scripts/Build-RdxUsbHelper.ps1:46–50`; public `PORTING.md:7–9`. Existing preflight rejects changed framework/services hashes rather than blindly invoking its getter. (`B/Prepare-TimedStage.ps1:71–78`)

**Options ranked:**  
1. Compatibility/health check after an owner-initiated OEM update, with guided repair for confirmed failures.  
2. Full owner-local requalification/rebuild when firmware contracts change.  
Automatic firmware rollback or factory-app replacement is neither established nor recommended.

**Plan:** before the OEM update, retain the owner APK, signing identity, nonsecret configuration and restoration record locally. Afterward check stock behavior first, then package/grant/accessibility/defaults, then Hackura integrations while parked. If broken, stop Hackura, restore Honda preferences and use stock AA while assessing the new profile. Recovery without working HMI/ADB is **UNKNOWN**.

Separately, improve Hackura’s own updates: T150 migration rewrites all option switches to true and feature switches to false. That can undo owner choices even if Android retains all app data. Replace blanket resetting with migration of missing/new keys and test preservation. (`J/AppSettings.java:42–65`)

T20’s “two packages prepare successfully” criterion is insufficient: preparation itself rewrites accessibility, reconfigures policy and reapplies the grant. A daily update test must omit those repairs until preservation has been measured. (`S/cards/T20-update-install.md:7–12`; `tools/car-test/CarTest.Core.ps1:210–238`; `B/test.json:74–76`)

**7 — Remaining roadmap items and recommendations**

- **T140/T150 validation:** steady cursor, extended warning dismissal, stuck-screen protection and Save logs have source but no corresponding `RESULT.md` found. Recommend completing their existing acceptance checks before treating them as daily-release behavior. Public `LATEST-TEST-PLAN.md:119–120` still lists these as pending/built.
- **Daily endurance:** retain the requested multi-day, ignition/cold-start, multi-hour and unrepaired update tests. Existing passes support use on this car, not this complete matrix. (`LATEST-TEST-PLAN.md:131`)
- **Save logs:** T150 writes app logs/settings to app external storage and retains a bounded set, but there is no demonstrated owner-friendly export path. Verify capture, retrieval and privacy before relying on it for laptop-free support. (`J/SettingsActivity.java:35–69`)
- **Inherited boot blackout:** `BootBlockerReceiver` still starts `BootBlockerService` on boot independently of persistent mode; shared source schedules an eight-second full-screen black overlay. Recommend explicitly deciding whether this remains appropriate now that warning dismissal exists, then validating visibility/camera behavior. Actual current boot execution is **UNKNOWN**. (`J/BootBlockerReceiver.java:37–40`; shared `BootBlockerService.java:16–24,63–79`)
- **Full-screen Maps/Spotify:** retain as separate research; density changes failed and narrow-pane drag experiments were retired. No working alternative is established. (`LATEST-TEST-PLAN.md:68,114,122,127`)
- **Native wireless without dongle:** keep parked; announcing support produced no phone response. Dongle support already has reported passes. (`LATEST-TEST-PLAN.md:20,126`)
- **Other car/firmware, guide and legal review:** retain before public setup-tool release; use fake extraction fixtures during tool development. AcuraLink remains untested. (`PROJECT-RULES.md:30,38–40`; `analysis/agent-reviews/backlog/USER-GUIDE-NOTES.md:9–15`)
- **Parked-state reporting:** document the existing choice and its implications in the safety/user guide; do not silently change that product decision in this task. (`LATEST-TEST-PLAN.md:104`)
- M5/M6/M7 are historical, explicitly outside the current roadmap; no follow-on work proposed. (`PROJECT-RULES.md:43–55`)

6. **Primary evidence for each finding**

The path:line references above identify implementation evidence. Particularly decisive counterexamples are:

- First-run legacy side effects: `J/UsbHelperService.java:187–194`.
- Persistent-on versus immediate restoration: `J/BootBlockerReceiver.java:22–25`; `J/PersistentMode.java:69–86`.
- Cleanup versus UNDO: `tools/car-test/CarTest.Core.ps1:131–152`; `B/test.json:78–82`.
- Grant update retention: `PMS:6154–6160,6263–6264`.
- USB replacement distinction: framework `PackageMonitor.java:240–270` separates replacing events from actual removal; `USB/UsbSettingsManager.java:380–390` handles addition/change/removal. Therefore uninstall behavior must not be assumed for ordinary replacement.
- Missing native APK entry: command output `tar_exit=0`, `archive_entries=98`, `native_entry_matches=0`; external native provenance at `E/device/native-provenance.json:2–4`.
- Irreversible-within-scope detector history: `MD/data/UserLocalRepository.java:23–30`; `MD/service/MDService.java:80–99`.
- Owner-choice reset on update: `J/AppSettings.java:59–65`.

7. **Assumptions**

The supplied T150-over-baseline source model is the intended review target; shared files not overridden were inspected from the existing source tree. No complete source/APK parity audit was performed. Saved decompilations describe captured firmware; current or future firmware equivalence is not assumed proven.

All proposed procedures are future plans, subject to the existing operator authorization and setup-tool rules.

8. **Unresolved uncertainties**

**UNKNOWN:** current device state; T140/T150 car outcomes; all daily-update preservation behavior; cross-brand serial stability; per-car protocol-material uniqueness; other-firmware native compatibility; universal Diagnostics access; complete navigation cleanup after abrupt death; OTA effects and recovery without HMI/ADB; AcuraLink interactions.

9. **Exact diff summary**

Not applicable; no files changed.

10. **Preservation checks performed**

Only local reads and APK filename enumeration were performed. No frozen artifact was rebuilt or modified; preservation-anchor hashes were not recomputed. No device, milestone, Git or network state changed.

No credential/private-test file or material-bearing `PlatformCertKeysImpl.java` was opened. A source search surfaced an embedded local-test signing value in the build script; it was not repeated in this report, and subsequent reads excluded signing sections.