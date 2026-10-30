# Laptop-independent Android Auto receiver alternatives

Review evidence: 2026-10-28. Exported: 2026-10-29.
Author: Codex, delegated reviewer. Recipient: Claude, project lead.

This document exports the preceding conversation review at the user's request. It is an analysis and handoff, not an implementation, installation procedure, milestone decision, or authorization for live work. Follow [PROJECT-RULES.md](../../PROJECT-RULES.md) and [AGENTS.md](../../AGENTS.md). Canonical deployment research remains in [DEPLOYMENT-PATHS.md](../DEPLOYMENT-PATHS.md); reference-firmware requirements remain in [2022-reference-needed.md](../2022-reference-needed.md).

**Recommendation:** the strongest candidate is to make our existing receiver operate independently on the head unit, using Honda's per-phone **Disable** setting and Android's saved USB default to reduce the startup race. Saved code supports this approach, and the current launcher has a specific missing handoff. Its effectiveness on the car is **UNKNOWN**.

Replacing Honda's installed Android Auto APK is substantially harder because of package-signature and system shared-UID checks. HUR and Open Headunit are credible separate-app alternatives and useful independent comparisons, but neither has demonstrated the required behavior on this target.

## 1. Files inspected

During the underlying review:

- `PROJECT-RULES.md` and supplied `AGENTS.md` instructions.
- `analysis/parallel-aa-receiver/usb-helper/AndroidManifest.xml` and `res/xml/device_filter.xml`.
- Helper source: `HelperActivity.java`, `UsbAttachActivity.java`, `UsbHelperService.java`, `PermissionClickService.java`, `BootBlockerReceiver.java`, `BootBlockerService.java`, `AaSessionService.java`, and `AaOverlayService.java`.
- Receiver source including `GalReceiver.java` and `VideoDecoder.java`.
- `scripts/Run-CarTest.ps1` and supporting saved test scripts, inspected as text only.
- Saved car logs, particularly `analysis/logs/car-test-20261028-v6e.txt`, `car-test-20261028-v6f.txt`, and `car-test-20261028-v6g-retry.txt`.
- Honda receiver decompilation: `GalService.java`, `StartPreferences.java`, `SelectDeviceActivity.java`, the manifest, `ProjectionRenderer.java`, and `DimensionUtils.java`.
- Captured firmware implementations: `UsbSettingsManager.java`, `UsbPermissionActivity.java`, `UsbConfirmActivity.java`, and `PackageManagerService.java`.
- `adb/RDX-Audit/packages/androidauto-sink.txt` and `logs/2026-10-22-investigation/initial-getprop.txt`.
- `analysis/DEPLOYMENT-PATHS.md`, `analysis/2022-reference-needed.md`, and relevant prior agent reviews.

Official documentation and upstream sources for Acura, HUR, Open Headunit, Android Auto, AAWireless, Shizuku, and Honda Hack were also reviewed. Links appear below. The export itself reread `PROJECT-RULES.md` and the repository's `AGENTS.md`; it did not repeat the substantive investigation.

## 2. Files changed

- Underlying investigation: none.
- User-authorized export: added only `analysis/agent-reviews/codex-20261029-laptop-independent-receiver-alternatives.md`.
- No application code, scripts, settings, historical logs, instruction files, or frozen artifacts were edited by this export.

## 3. Commands run

Underlying review used read-only PowerShell `Get-Content`, `rg -n`, `rg --files`, `Get-FileHash -Algorithm SHA256`, `git status --short`, and `git diff --stat`, plus browser research through the web tool.

Export workflow: read project instructions, checked the proposed output location, added this Markdown file with `apply_patch`, and checked the resulting file and local links. Device-control scripts were read as text, never executed. No `adb`, `fastboot`, install, build, staging, commit, or push command was run.

## 4. Tests run and results

- Static tracing completed for startup, USB permission, Honda preferences, and package replacement. These are source-level findings, not live validation.
- The underlying review verified all four frozen artifact SHA-256 hashes against `PROJECT-RULES.md`: **4/4 matched**. Exact anchors are recorded in section 10.
- No hardware, decoder, Android runtime, installation, or application-build tests were performed for this alternatives review.
- Export validation is limited to document existence, required report sections, and local-link targets. It cannot validate the proposed workflows on the car.

## 5. Findings

### A. Honda already has a setting that could remove much of the ownership race

**Confirmed in saved code:** the stock receiver's **Disable button for an individual phone** stores `StartPreferences.NEVER`, value `0`.

The relevant behavior is:

1. Before accepting a normal phone and probing accessory support, Honda checks the preference and returns without opening the device when it is `NEVER`.
2. For a phone already in accessory mode, Honda normally declines to start its receiver when the preference is `NEVER`.

This is a promising alternative to repeatedly force-stopping Honda: configure Honda to decline the phone, then let our receiver handle startup. The official Acura guide places the phone settings under **Settings -> Connections -> Android Auto -> Select device**. See the [2021 RDX Android Auto guide](https://owners.acura.com/utility/download?path=/static/pdfs/2021/RDX/2021_RDX_Android_Auto_Integration.pdf), page 3. The exact Disable behavior is established by the captured Honda code, not inferred from the owner's guide. [E1]

**Implementation catch:** our helper attempts the initial accessory-mode switch only when `forceStopSucceeded` is true. Honda could be running normally and correctly declining the phone while our helper refuses to perform the switch. Selecting Disable alone therefore does not establish a working replacement workflow. [E2]

Recommendation for the lead's consideration: represent an explicit state such as "Honda declines this phone; our app performs accessory startup." Do not treat that as proof that the Honda process is force-stopped, and do not fake the existing `HONDA_STOPPED` signal. This recommendation is not a request to bypass any project readiness guard.

Counterexamples to assuming complete isolation:

- `onUsbDeviceConnected()` invokes a USB-speed-related operation before checking the preference. That path can request `VBUS_DATA_CDP_OFF`.
- A temporary `mAllowedDeviceSerial` can override the preference during an existing transition.
- Pressing Disable for the currently connected phone calls Honda's USB-reset path.

Consequently, the hypothesis needs evaluation from a clean disconnected state. Toggling Disable during an active session is not established as harmless. **Whether this preference eliminates all disruptive Honda USB activity is UNKNOWN.** [E1]

The per-phone `NEVER` preference is also distinct from `gal_should_auto_start`. Disabling automatic presentation of Honda's UI is not evidence that Honda has stopped handling the USB protocol. [E1]

### B. We may be repeatedly racing a permission dialog Android can remember

The captured firmware implements this normal path:

`Resolve saved USB default -> grant that app permission -> launch its attachment activity`

Our `UsbAttachActivity` already passes the device to `UsbHelperService`. A laptop-independent attachment path therefore already exists in the project. [E3]

However, the current accessibility clicker presses **OK/Allow**; it does not select **Always use**. SystemUI saves a default only when that checkbox is checked. A successful automatic click does **not by itself establish a persistent default**. Whether a default was already selected on the target is UNKNOWN. [E3]

The comment in `UsbAttachActivity` also overstates the single-match case. Being the sole matching ordinary app does not automatically grant access on this firmware: the special single-match automatic-selection branch checks for a system app, apart from a separate disabled-dialog configuration. Our helper is an ordinary application. [E3]

The proposed workflow must distinguish:

1. Permission for the phone before accessory mode.
2. The detach/re-enumeration transition.
3. Permission for the new accessory-mode device.

Do not assume the first device's grant transfers to the second. The current filter already covers the OnePlus vendor and relevant accessory-mode identifiers; adding a missing broad phone filter is not the demonstrated gap here. [E3]

Honda's per-phone setting and Android's USB default address different questions. The former discourages Honda from starting its receiver. The latter grants and launches our app. Neither alone proves exclusive transport ownership.

### C. Updating our installed helper is the most direct way to remove laptop timing

The launcher icon currently opens `HelperActivity`, the older permission checker. Its success path sets `GRANTED` and logs success; it does not start the receiver service. The boot receiver starts only `BootBlockerService`, not the projection session. [E4]

We therefore have much of a standalone application, but its manual entry point does not operate the current receiver pipeline. USB attachment can already take a different path through `UsbAttachActivity`; the claim is not that every current start requires the laptop.

Recommended application behavior for the lead to evaluate:

- A real **Start/Stop** screen connected to the receiver services.
- Readiness derived from actual permission, attachment, and service state.
- An explicit sequence: initial permission -> accessory switch -> re-enumeration -> accessory permission -> transport -> TLS -> channel setup -> video.
- Local logs containing build identity, session identity, monotonic state-transition timestamps, and the first failure.
- Session-specific cleanup and bounded timeouts that begin when their relevant state starts.

The timeout distinction is material. `Run-CarTest.ps1` starts its cleanup timer before the later startup and phone-plug steps. That timer eventually force-stops the entire helper package. An unpredictable human delay therefore consumes the available session time. [E4]

Moving shell commands into an APK does not supply shell privileges. The helper already invokes `am force-stop` from its own process; it does not thereby become the ADB shell user. The saved retry log records the attempt failing. A standalone workflow should not depend on that privilege appearing merely because the laptop is absent. [E2]

An updated helper would improve repeatability and observability. It would not itself repair the separate protocol and decoder failures in section F.

### D. Replacing the installed base Android Auto is a separate trust and compatibility problem

The Honda receiver is `com.honda.androidauto.projection.sink`, under `/system/app/AndroidAuto`, with shared system UID 1000. Its captured package metadata identifies versionCode 22 and ARMv7 native code. [E5]

The package manager checks both compatibility with the installed package's signature and compatibility with the shared UID's signature. A modified APK signed by us would not pass an ordinary update solely because its package name matches. Renaming it creates a separate app without Honda's inherited privileges. Replacing another OEM app as a shortcut encounters the same signature problem. [E5]

Two distinct candidates remain:

- **Update our helper under its existing signing identity:** a plausible normal application update, subject to checking the installed signer and exact build.
- **Obtain an authentic, compatible OEM receiver update:** potentially viable, but native libraries, Honda framework dependencies, hardware branch, update eligibility, and recovery behavior must match. A suitable payload has not been established by this review.

See the canonical [deployment assessment](../DEPLOYMENT-PATHS.md), especially line 188 onward, and [reference-firmware requirements](../2022-reference-needed.md). Do not infer that a newer model-year APK or the existence of a writable application directory establishes a compatible replacement.

Google's phone-side Android Auto app is not a substitute for Honda's receiver. Android Auto's normal architecture projects the phone experience to a compatible receiver. See [Google's architecture overview](https://developer.android.com/training/cars/platforms/android-auto).

### E. Alternative receivers are credible comparisons, with different unresolved constraints

| Alternative | Potential benefit | What remains unresolved |
|---|---|---|
| Updated existing helper | Preserves current receiver work and adds direct on-device operation | Honda cooperation, two-stage USB permission, TLS/video defects |
| Headunit Reloaded (HUR) | Existing receiver with documented USB and Wi-Fi modes | Exact APK compatibility, display area, Acura touchpad and audio integration |
| Open Headunit | Auditable receiver implementation and independent protocol/decoder comparison | Exact release compatibility and Acura-specific integration |
| Direct Wi-Fi receiver connection | Avoids competing for the phone's USB connection when that data connection is absent | Phone startup method, head-unit networking, decoder and display behavior |
| Compatible OEM-signed receiver update | Could preserve OEM integration | Suitable payload, dependencies, eligibility and recovery remain unestablished |
| Wireless USB adapter using stock Honda AA | Removes the phone cable | Continues through the stock receiver; does not establish fullscreen support |

HUR's developer advertises older-Android support, and its current official listing documents USB defaults and Wi-Fi operation. These make it a candidate, **not proof that the current release works on this RDX**. Sources: [HUR developer information](https://www.b3itlabs.com/prod.php?id=1) and [official app listing](https://play.google.com/store/apps/details?id=gb.xxy.hr).

Open Headunit's inspected build configuration declares minimum SDK versions below this target's API 22. This clears a source-level compatibility question; it does not establish usable ARMv7 native libraries or runtime behavior for an actual release. Source: [upstream build configuration](https://raw.githubusercontent.com/andreknieriem/open-headunit/main/app/build.gradle.kts).

The Open Headunit project warns that Android Auto 17.4 and later can break legacy wireless startup triggers. It documents native wireless negotiation and a phone-side developer-server alternative. A wireless proposal must therefore identify the actual phone AA version and startup method. Source: [Open Headunit documentation](https://github.com/andreknieriem/open-headunit).

For research, **Open Headunit is the more inspectable comparison; HUR is the packaged-app comparison**. Neither has demonstrated the required 1920x720 output, Acura input, or audio behavior here. Direct Wi-Fi removes one shared transport path only when the phone is not simultaneously connected through the competing USB data path; it does not remove decoder, display-policy, or input questions.

Shortcuts that are poorly matched to the demonstrated problem:

- **AAWireless:** the manufacturer explicitly says it cannot enable fullscreen if the head unit does not support it. It still delivers projection through the car's USB receiver. [Manufacturer explanation](https://www.aawireless.io/en/support/topics-faq-aawireless/troubleshooting)
- **Current Shizuku:** its documented Android 6.0 minimum exceeds this target's Android 5.1/API 22. [Shizuku requirements](https://github.com/RikkaApps/Shizuku-API/blob/master/README.md)
- **Honda Hack:** the vendor's supported-vehicle list does not list this RDX. Exact-target compatibility is **UNKNOWN**. [Supported vehicles](https://www.autohack.org/vehicles/)

These are evaluation results, not purchase or installation instructions. No alternative APK was installed or runtime-qualified in this review.

### F. Removing laptop timing improves the experiment, but the logs show additional failures

The v6e log records selection of **1920x1080 encoded video with a 1920x720 active area**, followed by decoder startup and an input-buffer failure. The v6f log records a TLS **decryption failed or bad record mac** error. [E6]

Those observations separate several questions that should not be collapsed into "Honda timing":

| Question | Evidence needed |
|---|---|
| Can startup happen without the laptop? | App launch, both permission stages, and transport startup |
| Does Honda still interfere? | Correlated Honda activity, USB resets, and transport failures |
| Is the protocol session valid? | TLS success, channel setup, and sustained valid traffic |
| Does video actually work? | Decoder output and visible changing frames |
| Is the fullscreen goal met? | Actual surface dimensions, crop, and content across 1920x720 |
| Is it usable? | Correct touchpad mapping, audio, and reconnect behavior |

The most informative comparison would hold the phone and display conditions constant while changing one factor at a time: receiver implementation or transport. A successful independent receiver would narrow the problem. Failure at the same stage would strengthen the case for a shared platform limitation. Neither outcome alone identifies the cause.

For example, a replacement receiver succeeding over Wi-Fi would establish a useful combination, but would not isolate whether USB ownership or our receiver implementation caused the previous failures. A receiver connecting successfully but rendering only a narrower surface would establish connectivity, not achievement of the fullscreen goal.

Do not discard the v6e progress: the saved evidence already shows acceptance of the advertised active video geometry. Equally, do not report that geometry selection as proof of successful rendering. [E6]

## 6. Primary evidence for each finding

Line numbers refer to files inspected during the review. Recheck them if Claude edits the source. Relative links identify the files; the following line references identify the relevant evidence.

### E1: Honda Disable behavior and limitations

- [SelectDeviceActivity.java](../../decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/settings/SelectDeviceActivity.java), lines 48-65: Disable listener stores 0 and invokes `onDisableGal()` for the current device. Lines 68-85: Enable stores 1.
- [StartPreferences.java](../../decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/settings/StartPreferences.java), lines 14-21: ALWAYS/ASK_USER/NEVER constants; lines 33-35: per-serial preference with default ASK_USER; `gal_should_auto_start` is separately defined at line 20.
- [GalService.java](../../decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/service/GalService.java), lines 715-719: USB-speed handler occurs before preference lookup; lines 736-759: accessory preference and allowed-serial override; lines 855-874: speed-related reset request; lines 1058-1067: NEVER rejection before opening the device; lines 1818-1845: Disable calls USB reset.

### E2: Helper's force-stop dependency

- [UsbHelperService.java](../parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/UsbHelperService.java), lines 104-107: startup force-stop/reset attempts; lines 117-120: `HONDA_STOPPED` flag; line 138 and line 195: non-accessory processing gated on `forceStopSucceeded`; lines 437-459: app-process force-stop and stopped-flag fallback; lines 470-519: existing accessory-switch implementation.
- [v6g-retry log](../logs/car-test-20261028-v6g-retry.txt), line 291: force-stop returns rc=1; nearby lines 295-297 record the reset attempt and denial.

### E3: USB defaults and permission

- [UsbSettingsManager.java](../../decompiled/Services/sources/com/android/server/usb/UsbSettingsManager.java), lines 665-675: restricted single-match automatic-selection path; lines 678-695: saved-default resolution, permission grant, and activity launch.
- [UsbPermissionActivity.java](../../decompiled/SystemUI/sources/com/android/systemui/usb/UsbPermissionActivity.java), lines 93-96: grant permission, then save the package only if Always use is checked.
- [UsbConfirmActivity.java](../../decompiled/SystemUI/sources/com/android/systemui/usb/UsbConfirmActivity.java), lines 86-95: corresponding default-choice handling.
- [PermissionClickService.java](../parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/PermissionClickService.java), lines 126-146: clicks OK/Allow without an Always use selection step.
- [UsbAttachActivity.java](../parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/UsbAttachActivity.java), lines 10-14: overly broad sole-match comment; lines 33-39: permission check and handoff to helper service.
- [device_filter.xml](../parallel-aa-receiver/usb-helper/res/xml/device_filter.xml): OnePlus vendor match and Google accessory-mode identifiers.

### E4: Standalone entry-point gap and timer

- [AndroidManifest.xml](../parallel-aa-receiver/usb-helper/AndroidManifest.xml), lines 8-12: launcher activity is `HelperActivity`; lines 14-21: separate USB attachment activity.
- [HelperActivity.java](../parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/HelperActivity.java), lines 301-303: success sets GRANTED and logs it. Read/search of the file found no receiver-service start or `AaSessionService` handoff.
- [BootBlockerReceiver.java](../parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/BootBlockerReceiver.java), line 14: starts `BootBlockerService` only.
- [Run-CarTest.ps1](../../scripts/Run-CarTest.ps1), lines 129-130: starts the cleanup timer before later startup/readiness/plug steps; cleanup includes force-stopping the whole package.

### E5: Replacement constraints and target identity

- [androidauto-sink.txt](../../adb/RDX-Audit/packages/androidauto-sink.txt), lines 79-97: UID1000, system shared UID, system application path, ARMv7 ABI, and version metadata.
- [PackageManagerService.java](../../decompiled/Services/sources/com/android/server/pm/PackageManagerService.java), lines 4427-4449: installed-package and shared-user signature enforcement, with failure codes -7 and -8.
- [initial-getprop.txt](../../logs/2026-10-22-investigation/initial-getprop.txt), line 243: D.1.6.4; line 254: SDK22; lines 274-278: ARMv7/32-bit ABI list.
- [DEPLOYMENT-PATHS.md](../DEPLOYMENT-PATHS.md), line 188 onward: canonical synthesis of conditional official-update feasibility and unresolved payload/recovery requirements. This report is a research index, not independent primary proof of a compatible update.

### E6: Failures beyond startup

- [v6e log](../logs/car-test-20261028-v6e.txt), line 6587: selected codec 1920x1080 and active area 1920x720; line 6737: decoder-start report; line 6747: no-input-buffer decoder failure.
- [v6f log](../logs/car-test-20261028-v6f.txt), lines 3133-3137: SSL read/decryption/bad-record-MAC and subsequent framing error.

Alternative-product claims in section E are supported by the adjacent upstream or manufacturer links. Product support claims are not target-specific test results.

## 7. Assumptions

- The intended outcome remains correctly rendered 1920x720 Android Auto with usable controls on the captured D.1.6.4 head unit.
- Saved firmware and logs describe the relevant target. Exact parity with the currently installed helper build has not been established by this review.
- The user's latest authorization covers exporting the existing analysis to this document, not implementing or deploying the recommendations.

## 8. Unresolved uncertainties

**UNKNOWN:** whether Honda's per-phone Disable eliminates disruptive USB activity; whether the phone retains the expected identity through accessory switching; whether both saved USB defaults work across reconnects and reboots; the current installed helper's exact provenance; the phone's current Android Auto version; exact HUR/Open Headunit APK compatibility; available direct wireless startup methods; actual fullscreen rendering; and Acura input/audio integration.

The code establishes candidate mechanisms. It does not establish a laptop-free end-to-end pass. Future upstream changes may also alter the alternative-app compatibility findings; URLs were reviewed for the original analysis and were not revalidated merely to export this document.

## 9. Exact diff summary

Added one Markdown report: `analysis/agent-reviews/codex-20261029-laptop-independent-receiver-alternatives.md`.

No existing project file was intentionally changed by the export. No source, executable, configuration, instruction, or historical log changes are included. Existing working-tree modifications belong to the prior project state and must not be attributed to this report.

## 10. Preservation checks performed

The underlying review's `Get-FileHash -Algorithm SHA256` comparison returned `Match=true` for all four frozen artifacts:

| Artifact | SHA-256 |
|---|---|
| Frozen M5 APK | `A22E96490B9557AFF022893A8B8B7A08BB13CEC236E52704CDDAFA90A8EE8F40` |
| Disabled M6 APK | `D4DAC2DD8B2AFF1FA7B64BFB32D2A5E889854CCEB4B4A9F7AD5AEF89FB28761F` |
| Receiver DEX | `2FDBC63F2F9D63B764697D311AF89D460AE6B8E14B0FADABA9C9339F7FE7C235` |
| API22 TLS qualifier APK | `86350131FFC5CBE5766E523AB03AE07D4C9F5EAD78F0570B68255C9A3999FC1F` |

No key material was accessed. No car, phone, or USB device was contacted. No frozen artifact was rebuilt, no milestone was advanced, and no Git staging or commits were performed. The export writes only this report.
