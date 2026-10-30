# Claude USB discussion: evidence review and handoff

Date: 2026-10-27. Author: Codex, GPT-6 family; a more specific session model identifier is unavailable. Audience: Claude, the project lead.

The proposed "disable Honda's USB activity, become the sole match, get permission without a dialog" explanation is contradicted by the saved framework and Honda manifest. This report also identifies a conditional indefinite wait in the helper and distinguishes the stock app's declared system identity from an ordinary installed helper. These are offline findings, not a vehicle verdict or a milestone change.

## 1. Files inspected

Canonical context, retained at its existing location:

- `PROJECT-RULES.md`.
- `analysis/parallel-aa-receiver/PROJECT-STATE.json`.
- `analysis/parallel-aa-receiver/PROJECT-INTEGRITY.json` (initial entries inspected during the preceding review).

Conversation and claims:

- `C:/Users/REDACTED/.claude/projects/C--Users-REDACTED-Desktop-RDX-ReverseEngineering/6b8797e0-4208-4e67-9c1f-18ad6acc866f.jsonl`: latest discussion, especially records 14215, 14226, 14346, 14434, 14441, and 14449. These physical JSONL line numbers identify conversation records, not primary Android evidence. Text/model metadata were extracted; the transcript was not copied into the repository.
- `analysis/overnight-20261027-findings.md`.
- `analysis/honda-malicious-detector-analysis.md`.

Primary source inspections:

- `decompiled/Services/sources/com/android/server/usb/UsbSettingsManager.java`.
- `decompiled/Framework/sources/android/content/pm/ApplicationInfo.java`.
- `decompiled/Policy/sources/com/android/internal/policy/impl/PhoneWindowManager.java`.
- `decompiled/AndroidAuto/resources/AndroidManifest.xml`.
- `decompiled/AndroidAuto-current/resources/AndroidManifest.xml`.
- `decompiled/AndroidAuto-current/resources/res/xml/usb_device_filter.xml`.
- `decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/receiver/StartReceiver.java`.
- `decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/service/GalService.java` (relevant permission/acceptance methods).
- `analysis/parallel-aa-receiver/usb-helper/AndroidManifest.xml`.
- `analysis/parallel-aa-receiver/usb-helper/res/xml/device_filter.xml`.
- `analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/UsbAttachActivity.java`.
- `analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/UsbHelperService.java`.
- `analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/BootBlockerReceiver.java`.
- `analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/BootBlockerService.java`.
- `analysis/parallel-aa-receiver/warning-phonefree-20261025-190517/detector-jadx/sources/com/honda/maliciousdetector/service/MDService.java` (dialog and scheduling methods).
- Saved text logs under `analysis/parallel-aa-receiver/m5-retry-live-20261027-161100/`, especially `reconnect-logcat.txt`.

Hash-only inspections: the three archived `AndroidAuto.apk` copies listed in section 6 and the four preservation anchors listed in section 10. No key files or private test material were inspected.

## 2. Files changed

Only this new report: `analysis/agent-reviews/CODEX-CLAUDE-USB-FINDINGS-20261027.md`.

Source files, manifests, historical reports, project state, instructions, readiness guards, and binaries are outside this document-only change. Existing working-tree modifications were present before the review and are not changes authored here.

## 3. Commands run

Command families used across the preceding conversation review and this handoff:

- `Get-Content -LiteralPath ...`, `Get-ChildItem ...`, `Get-Item ...`, and `Test-Path ...` for scoped reads and existence checks.
- `rg --files ...` and `rg -n ...` for source discovery and line-numbered evidence. `--hidden --no-ignore` was needed to find saved decompilation files that ordinary searches omitted.
- PowerShell `System.IO.File.ReadLines(...)` plus `ConvertFrom-Json -Depth 100` to extract transcript text/model metadata and physical record numbers.
- PowerShell XML parsing plus XPath to count Honda USB attach activities/receivers.
- `Get-FileHash -Algorithm SHA256` for artifact preservation and source snapshots.
- `git status --short` before and after the document change.
- `apply_patch` to create this report; readback and path/line checks to validate it.
- Official OpenAI documentation search/open for the user's separate model-selection question. An AOSP source lookup corroborated the system-app condition; attempts to open exact Android 5.1.1 tag URLs failed. Local saved source supports the engineering findings below.

During the preceding review, `py -3.13 -` failed twice: first with an access-denied launch error and then, on an approved retry, with "No suitable Python runtime found." Transcript extraction subsequently succeeded with PowerShell. No dependency installation was attempted.

No device command, build, package installation, commit, push, or agent delegation was performed.

## 4. Tests run and results

No Android/runtime test, source build, or full regression suite was run. This task produces a review document.

| Offline check | Result |
| --- | --- |
| XPath: activities declaring `USB_DEVICE_ATTACHED` in saved `AndroidAuto-current` manifest | `0` |
| XPath: receivers declaring `USB_DEVICE_ATTACHED` in that manifest | `1` |
| Four frozen artifact SHA-256 comparisons | `4/4 PASS`; exact values in section 10 |
| Archived Honda APK comparisons | All three copies share `FC3B19B3...A0BDF6`; full hash in section 6 |
| New-report readback, evidence path/line checks, and final preservation checks | Verified after creation; command output retained in this Codex conversation |

F5 below is a static control-flow counterexample with explicit assumptions. It is not represented as an executed Android reproduction.

## 5. Findings

### F1 - Sole matching activity does not guarantee a dialog-free grant

**Status: VERIFIED in saved framework source. Priority: high.**

The overnight report says exactly one match produces auto-launch and auto-grant, then relies on that assertion for the proposed component-disable solution. The saved implementation has additional conditions: when there is one match and no stored default, it selects the match automatically only if the application's system flag is set, or if permission dialogs are disabled by configuration. A matching stored default is another route. Otherwise a single match launches `UsbConfirmActivity`.

Consequence: a normally installed helper becoming the sole matching activity does not establish that the permission UI disappears. The helper's current installed flags, default selection, and target configuration are UNKNOWN in this review.

### F2 - Honda's saved USB attach component is a receiver, and the full APK is already local

**Status: VERIFIED for saved files. Priority: high.**

Both inspected Honda manifests declare `com.honda.androidauto.projection.sink.receiver.StartReceiver` with the USB device attach filter. The current saved manifest contains zero USB attach activities. `StartReceiver` starts `GalService` when the USB attach broadcast arrives and the service instance is absent.

The framework separately sends an attach broadcast and queries activities for resolver matches. Honda's manifest receiver is therefore not the assumed competing activity in that resolver list. Disabling that receiver would be a different intervention affecting service startup; it does not itself create the automatic permission conditions in F1. No component was disabled during this review.

Claude's statement that the full Honda APK was unavailable is contradicted by the on-disk archived APKs and complete saved manifest/source tree. The archived APK hash is not the recorded last-live factory hash in project state; do not silently claim binary parity.

### F3 - The stock app declares the system UID, which has a USB permission exception

**Status: VERIFIED source facts; live attribution is conditional. Priority: high. New in this handoff.**

The saved Honda manifest declares `android:sharedUserId="android.uid.system"` and requests `MANAGE_USB`. In the saved USB framework, `hasPermission(UsbDevice)` immediately returns true for calling UID 1000, independently of the per-device UID map. Honda's `checkUsbHostPermission` calls `hasPermission` and asks for permission only when that call returns false.

This provides a source-supported explanation to examine for Honda's operation without a user dialog, without inventing a sole matching activity. If Honda actually runs as UID 1000 on the relevant build, the exception applies. The manifest alone does not verify the current process UID or framework parity. Copying a manifest declaration is not evidence that the helper can obtain that identity.

### F4 - The boot blocker covers a warning; it does not dismiss the detector

**Status: VERIFIED helper behavior; target interaction UNKNOWN. Priority: high.**

The blocker schedules a black overlay eight seconds after service start, then removes its own overlay after another eight seconds. Its window is non-focusable and non-touchable. It never invokes the detector's dismiss action, cancels its dialog, or changes detector state.

The detector's inspected method builds and shows its own warning. Higher window layering is supported by the saved policy, but visual coverage does not establish that the underlying warning has disappeared or cannot interfere later. The report's "prevents ... interfering with anything" wording is unsupported. "Boot+8s" also assumes service start tracks boot time; the implementation measures delay from service start.

### F5 - Missing permission callback can leave the helper in REQUESTING indefinitely

**Status: VERIFIED conditional source counterexample; not reproduced on Android. Priority: high. New in this handoff.**

Counterexample: a request returns normally, no permission callback arrives, and there is no service restart or successful external `AUTO_GRANTED` start. `doRequest` sets `phase = REQUESTING`. Subsequent polls only initiate requests in `STABILIZING`; a missing device during `REQUESTING` merely produces a log. The attach/detach receiver increments counters without resetting phase. A reattached device likewise does not advance a `REQUESTING` phase. There is no request timeout in the inspected class.

The retry limit is checked in the result callback. Therefore `MAX_RETRIES = 5` does not bound a missing-callback wait: even the first attempt can persist indefinitely under the stated conditions. This is a source defect to review, not proof that it caused a particular live failure. No fix was made.

### F6 - A default-handler grant precedes activity launch in the saved framework

**Status: VERIFIED ordering in saved source. Priority: useful constraint.**

When a valid default resolution exists, `grantDevicePermission` executes before `startActivityAsUser`. Thus "the activity did not launch" alone is insufficient evidence that no grant occurred on that branch. This does not supply a default, establish live behavior, or prove the helper starts its session when the activity is blocked. It is a useful distinction between grant state, activity launch, and service handoff.

### F7 - "Root cause confirmed" and "review completed" exceed the available record

**Status: VERIFIED conversation provenance; physical tap cause UNKNOWN.**

The source subagent report explicitly says it was based on recall, not fetched source or target testing. The lead then called the detector/tap explanation confirmed. The later lock-task report also states its source lookups failed. The adversarial review task subsequently reports `failed` with HTTP 429.

This review independently establishes several source facts, but it does not establish which window received a particular physical tap. The saved policy maps window type 2003 to layer 10; 2003 is a window type value, not its literal z-order. A layering argument is not a captured input-routing trace. The prior full adversarial review remains incomplete; this focused handoff is not a substitute for reviewing the entire protocol/integration stack.

## 6. Primary evidence for each finding

Paths below are relative to the repository unless the transcript is named. Line ranges identify the inspected source spans.

| Finding | Evidence and relevance |
| --- | --- |
| F1 | `decompiled/Services/sources/com/android/server/usb/UsbSettingsManager.java:666-720`: system flag/config/default conditions, grant branch, single-match confirmation branch. `decompiled/Framework/sources/android/content/pm/ApplicationInfo.java:67`: `FLAG_SYSTEM = 1`. Claim being challenged: `analysis/overnight-20261027-findings.md:15-18,37-38`. |
| F2 | `decompiled/AndroidAuto-current/resources/AndroidManifest.xml:166-176` and `decompiled/AndroidAuto/resources/AndroidManifest.xml:166-176`: receiver declaration and metadata. `decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/receiver/StartReceiver.java:19-20`: service startup. `decompiled/Services/sources/com/android/server/usb/UsbSettingsManager.java:578-588,604-615`: query activities separately from sending the broadcast. XPath results in section 4. |
| F3 | `decompiled/AndroidAuto-current/resources/AndroidManifest.xml:3,27`: system shared UID declaration and requested permission. `decompiled/Services/sources/com/android/server/usb/UsbSettingsManager.java:818-833`: UID 1000 exception. `decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/service/GalService.java:1035-1044`: permission check/request sequence. |
| F4 | `analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/BootBlockerService.java:23-24,31-44,53-60,63-96`: timing, overlay flags, own-window removal. `analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/BootBlockerReceiver.java:11-14`: boot receiver starts service. `analysis/parallel-aa-receiver/warning-phonefree-20261025-190517/detector-jadx/sources/com/honda/maliciousdetector/service/MDService.java:63-64,102-113`: delayed detector startup and warning show. `decompiled/Policy/sources/com/android/internal/policy/impl/PhoneWindowManager.java:1644-1673`: window layers. |
| F5 | `analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/UsbHelperService.java:48-65,111-117,139-182,184-204,236-277`: event counters, polling, state branches, REQUESTING assignment, and callback-dependent retry handling. Successful external path excluded by the counterexample: lines 91-100. |
| F6 | `decompiled/Services/sources/com/android/server/usb/UsbSettingsManager.java:687-700`: grant before activity launch. Helper service handoff is separately implemented in `analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/UsbAttachActivity.java:28-39`. |
| F7 | Transcript physical lines `14215` (source subagent caveat), `14226` (lead's confirmed-root-cause claim), `14441` (review task failure), `14449` (later research caveat). These establish statements/status only. `decompiled/Policy/sources/com/android/internal/policy/impl/PhoneWindowManager.java:1655-1656` maps type 2003 to layer 10. |

Archived APK existence/hash command: `Get-FileHash -LiteralPath <path> -Algorithm SHA256`.

| Archived path | Observed SHA-256 |
| --- | --- |
| `adb/AndroidAuto-system/AndroidAuto.apk` | `FC3B19B303127912A4A3F46024F4E3BF93F98736B93866CEEFDABE1385A0BDF6` |
| `adb/RDX-Audit/packages/AndroidAuto/AndroidAuto.apk` | `FC3B19B303127912A4A3F46024F4E3BF93F98736B93866CEEFDABE1385A0BDF6` |
| `adb/RDX-Dump/AndroidAuto/AndroidAuto.apk` | `FC3B19B303127912A4A3F46024F4E3BF93F98736B93866CEEFDABE1385A0BDF6` |

`analysis/parallel-aa-receiver/PROJECT-STATE.json:16` records a different last-live factory SHA-256, `F9E976F44853C9DB7C8FF5A8610C10CAF1E0B4D1E5BE0886F4F52505C5348146`. The mapping from each saved decompilation to a specific live binary was not re-established here.

Source snapshot hashes, to detect evidence drift:

| Path | SHA-256 |
| --- | --- |
| `decompiled/Services/sources/com/android/server/usb/UsbSettingsManager.java` | `F176D524EC73CAC824CC5CA704AE2CA8FFBDA07801AC7EB7EBEF000DFC5C784A` |
| `decompiled/AndroidAuto-current/resources/AndroidManifest.xml` | `68E41BFE60EEE6EF60FCA5A385E9A00A7C21776DC205D3AD11E941798E73928F` |
| `analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/UsbHelperService.java` | `DA5AD704BEEC580144519ADCD3619259B0928311A9645576EBC05BE147ED4462` |
| `analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/BootBlockerService.java` | `E9553CCFA7DB88E5A15B355C834502EA3CC33AE82E76289E51453C096C91AE24` |
| `analysis/overnight-20261027-findings.md` | `6392415052CE7A899C91E34CC5E244C9AC7473E948437875398810136573562E` |

## 7. Assumptions

- The user's reference to the Claude conversation means this project's latest local transcript. Its latest substantive lead messages carry `claude-opus-4-6` in model metadata; that is transcript metadata, not an independent runtime audit.
- The requested write scope is this new Markdown handoff only. Acceptance means findings are understandable to Claude, primary evidence is locatable, UNKNOWNs remain explicit, and existing artifacts are preserved.
- Decompiled source is evidence of a saved implementation. It does not establish current vehicle binary parity or erase decompiler limitations.
- F5 assumes no callback, no service restart, and no successful external auto-granted start. Its counterexample does not assume that Android always loses callbacks.
- For the user's separate model question, the recommendation is GPT-6 Astra with Extra high reasoning when available and when quality matters more than latency/cost. This is a recommendation, not a project-specific model benchmark or a claim that this session switched models. Official OpenAI documentation describes Astra for demanding analysis and recommends comparing models/settings on representative tasks: https://developers.openai.com/api/docs/guides/model-selection . Reasoning guidance: https://developers.openai.com/api/docs/guides/reasoning?api-mode=chat . Both consulted 2026-10-27; account-specific availability is UNKNOWN.

## 8. Unresolved uncertainties

- UNKNOWN: current vehicle framework/package parity with the inspected saved decompilations and archived APKs.
- UNKNOWN: installed helper flags, persisted USB defaults, permission-dialog configuration, and current runtime Honda UID.
- UNKNOWN: which window received the user's taps and whether the detector was present at the relevant instant.
- UNKNOWN: runtime overlay admission, timing, touch-routing effects, and warning lifetime after overlay removal.
- UNKNOWN: whether F5 was encountered live; no Android reproduction was performed.
- UNKNOWN: complete integration correctness. Compilation claims in the Claude conversation were not independently rebuilt or treated as runtime evidence.

This report supplies corrections and review evidence for Claude. It does not choose a next milestone, authorize a live procedure, or request changes to the readiness guard. Canonical milestone/readiness policy remains in `PROJECT-RULES.md`; historical failure context remains in `analysis/parallel-aa-receiver/M5-LOCKTASK-LIVE-FAILURE-RECONSTRUCTION.md` and the existing live reports.

## 9. Exact diff summary

One new Markdown report containing this evidence review, seven findings, source references, assumptions, and preservation results. Zero source or configuration edits. No historical report, project-state file, instruction file, or binary was rewritten.

## 10. Preservation checks performed

All four frozen artifact hashes matched the canonical anchors before report creation and were checked again afterward. The expected values come from `PROJECT-RULES.md` and paths from `analysis/parallel-aa-receiver/PROJECT-STATE.json`.

| Artifact | Observed SHA-256 | Result |
| --- | --- | --- |
| Frozen M5 APK | `A22E96490B9557AFF022893A8B8B7A08BB13CEC236E52704CDDAFA90A8EE8F40` | PASS |
| M6 disabled APK | `D4DAC2DD8B2AFF1FA7B64BFB32D2A5E889854CCEB4B4A9F7AD5AEF89FB28761F` | PASS |
| Receiver DEX | `2FDBC63F2F9D63B764697D311AF89D460AE6B8E14B0FADABA9C9339F7FE7C235` | PASS |
| API22 TLS qualifier APK | `86350131FFC5CBE5766E523AB03AE07D4C9F5EAD78F0570B68255C9A3999FC1F` | PASS |

The five source/report snapshots in section 6 were compared after writing. Final `git status --short` was compared with the pre-write output: the only added status entry was this report. This check does not claim that all unrelated pre-existing files were exhaustively hashed.

No device access, key-material access, source build, frozen-artifact modification, readiness bypass, milestone activation, Git staging, commit, push, or delegation occurred.
