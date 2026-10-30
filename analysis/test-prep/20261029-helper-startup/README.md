# Helper startup test preparation — 2026-10-29

**Local preparation is complete; live readiness is NOT ESTABLISHED.** The last meaningful saved attempt, `v6g-retry`, exhausted 15 permission requests, with 15 `granted=false verified=false` callbacks and no helper session or USB-open marker. It did not reach a decoder test. See F1 and E1 below.

This packet prepares evidence collection for the existing helper experiment. It does not implement v6h, change the live test procedure, choose a new milestone, or authorize a connected test. No device tool was run. The user's [AGENTS.md](../../../AGENTS.md) prohibits this agent from device access and M5/M6/M7 execution; [PROJECT-RULES.md](../../../PROJECT-RULES.md) remains authoritative. An isolated M5 test is a different package and procedure, not a substitute silently selected here.

Start with these files:

- [offline-check.json](offline-check.json): pinned APK, source differences, historical event counts, frozen hashes, and preservation check.
- [observations.template.json](observations.template.json): an unfilled future-run record. `NOT_RUN`, null fields, and `UNKNOWN` outcomes are intentional.
- [Test-OfflinePreparation.ps1](Test-OfflinePreparation.ps1): repeatable local verification. It prints JSON and invokes no external programs or device tools. Exit success means the local integrity/syntax checks completed, **not** that the experiment is ready to run.

From the repository root, this command only rechecks local files:

[Code block omitted from public report; see authored source where available.]

For the deeper research and implementation recommendations, use the existing [Claude resumption handoff](../../agent-reviews/CLAUDE-RESUME-20261102.md) and [laptop-independent alternatives review](../../agent-reviews/codex-20261029-laptop-independent-receiver-alternatives.md). This packet narrows that material to the next test's preparation.

## 1. Files inspected

- `AGENTS.md`, `PROJECT-RULES.md`, and current Git status.
- `analysis/agent-reviews/CLAUDE-RESUME-20261102.md`, its `claude-resume-20261102/evidence.json`, and `v6h-honda-disable-plan.md`.
- `scripts/Run-CarTest.ps1` and `scripts/device-kill-honda.sh`, as text only.
- Helper `UsbHelperService.java`, `PermissionClickService.java`, and `AaSessionService.java`; shared `projection/UsbBulkTransport.java`.
- `usb-helper/latest-build.txt`, the pinned build's `build-report.json`, and its 20 recorded Java input hashes.
- Saved `car-test-20261028-v6e.txt`, `-v6f.txt`, and `-v6g-retry.txt`, using bounded event searches and selected surrounding lines.
- Four frozen artifacts and the existing 263-file preservation inventory, by hash only. Inventory membership does not imply a full substantive review of every file.

The reusable script and JSON contain exact paths. No credential file was opened or APK contents extracted.

## 2. Files changed

Four new files, all under `analysis/test-prep/20261029-helper-startup/`: this README, `Test-OfflinePreparation.ps1`, `offline-check.json`, and `observations.template.json`.

No existing source, runner, APK, historical log, report, instruction, milestone state, or Git index was changed. Existing worktree modifications belong to the preceding work.

## 3. Commands run

- Read-only inspection: `Get-Content`, `rg -n`, scoped `rg --files`, `Get-Item`, `Get-FileHash -Algorithm SHA256`, and `git status --short`.
- PowerShell JSON parsing and comparisons; `System.Management.Automation.Language.Parser.ParseFile` for syntax inspection without running the existing car-test script.
- `apply_patch` created the packet's script, template, and report. The new local checker produced `offline-check.json` through `Set-Content`.
- The exact reusable check is the command above. Its command AST contains local read/hash/JSON operations and its own local functions; no external command is invoked.
- Compared 30 historical event counts and their nonempty first-line references against the preceding handoff's saved extraction. Checked the packet's JSON, report sections, and local links.

An initial source lookup used the nonexistent `src/com/rdx/fullscreen/transport/UsbBulkTransport.java`; `rg --files` identified the actual `projection/` path. No finding relies on that failed lookup.

## 4. Tests run and results

| Offline check | Result | Limit |
|---|---|---|
| Pinned APK vs recorded and expected SHA-256 | MATCH | Installed artifact remains UNKNOWN |
| Current Java sources vs 20 build inputs | 18 match; 2 differ | Current session/decoder fixes are not established as present in this APK |
| Existing `Run-CarTest.ps1` syntax | 0 parse errors | Syntax does not establish operational readiness |
| New offline checker syntax | 0 parse errors; execution completed | No Android execution |
| 30 historical event counts and nonempty first-line references | All agree with prior extraction | Checks consistency, not completeness of the captures |
| Four frozen artifacts | 4/4 expected hashes match | Preservation only |
| 263 pre-existing inventory files | All unchanged | Does not certify files outside that inventory |

The saved check reports `artifact_integrity_matches: true` and `live_readiness: NOT_ESTABLISHED`. No live, installation, build, signing, USB, decoder, or M5/M6/M7 test was performed.

## 5. Findings and prepared test specification

### F1. Resume from a startup failure, with separate downstream outcomes

| Saved capture | Helper session | USB open | Video selected | Decoder started | First-render marker |
|---|---:|---:|---:|---:|---:|
| v6e | 1 | 1 | 1 | 1 | 0 |
| v6f | 1 | 1 | 0 | 0 | 0 |
| v6g-retry | 0 | 0 | 0 | 0 | 0 |

These are matching log-event counts, not inferred physical results. The latest retry records failure at 21:02:52.212 after 15 requests; its subsequent reflective direct-grant attempt also reports failure. v6f instead records a TLS bad-record-MAC/decryption error in the same PID as the helper session. Do not use the startup failure to judge decoder changes, or assume one cause explains all three captures. [E1–E3]

The helper package was force-stopped early in v6g-retry, including its accessibility service. The current runner removes its earlier explicit pre-start helper force-stop. That is a useful correction, but does not prove it fixes the permission failure. Both successful-start captures also lack the `PermissionClickService connected` marker, so absence of that marker alone cannot establish that accessibility was unbound. v6g-retry additionally has no successful-click marker. Exact cause: **UNKNOWN**. [E1, E4]

### F2. The available APK is a historical baseline

Pinned file: [rdx-usb-helper-0.1.0-usb-helper-development.apk](../../parallel-aa-receiver/usb-helper/build/20261028-164612-233/rdx-usb-helper-0.1.0-usb-helper-development.apk).

SHA-256: `C7943B4FD9194E6AAD3E2C28AE68F880519D8EC624148AA794FBE9CA97F80757`.

Its metadata says `staticAudit: PENDING`. Current `AaSessionService.java` and `VideoDecoder.java` differ from the recorded build inputs; exact hashes are in `offline-check.json`. The other 18 recorded Java inputs match. This is not a complete audit of every APK input, and neither local hash matching nor a log filename proves what was installed for any historical run. [E5]

For a future run, explicitly choose either this historical baseline or an independently reviewed new candidate with its own build record. Do not label this APK v6h, silently follow a moving `latest-build.txt`, or attribute current-source behavior to it without matching build evidence.

### F3. A startup-focused helper run is not an isolated permission test

On verified AOAP permission, the helper calls `startAaSession()`, which starts `AaSessionService` with `aa.session.START`. Starting the helper also attempts Honda force-stop and VBUS reset in `onCreate()`. It therefore has effects beyond requesting permission. [E6]

The proposed v6h `hondaDisabled`/`usb.HONDA_DISABLED` path is absent from the current helper source and runner. Merely choosing Honda's per-phone preference would not implement the proposal's changed gates or eliminate the existing startup actions. The proposal remains implementation work, not a ready test variant. [E7]

### F4. Resolve these runner gaps before calling the setup ready

These are source-review findings about the current runner, not proof that this exact runner produced a historical log. [E8–E9]

| Gap | Required evidence or correction before a future run |
|---|---|
| Failed installation prints a message and continues | Abort on failure; record exact intended and installed artifact identity |
| Initial device check names a target, later commands lack explicit target selection | Bind every connected operation to the intended target |
| Service checks use `ServiceRecord` text; failed helper/A11Y checks can still reach green READY | Require positive readiness evidence and stop on failure; distinguish service existence, accessibility binding, click attempt, and verified grant |
| Accessibility recovery replaces the enabled-services list with this service alone | Preserve unrelated entries and retain original values for restoration |
| Cleanup timer starts before subsequent setup and human cable swap | Record its actual deadline and remaining interval; if the window is inadequate, abort instead of racing or disabling cleanup |
| Kill loop performs 300 commands but has no elapsed-time deadline | Treat “~30s” as an estimate, not a verified window; record the actual overlap with attach |
| Starting an already-running helper does not establish a fresh state | Record whether the process is fresh and its phase; terminal GRANTED/FAILED polling and duplicate attach behavior need review |

The timer eventually force-stops the entire helper package, which includes accessibility. The current runner fix avoids one earlier stop; it does not remove this later stop. No recommendation here is to bypass cleanup or any readiness guard.

### Prepared observation contract

For an authorized future helper attempt, use a fresh copy of `observations.template.json`; leave the original `NOT_RUN`. Keep the chosen APK, runner, startup approach, and phone preference fixed within the attempt so that the outcome can be interpreted.

Record capture start, readiness completion, cleanup deadline, laptop disconnect, physical phone attach, AOAP attach, permission request, dialog/click, verified permission, session creation, USB open, discovery, video selection, decoder start, first-render report, visible image, and cleanup. Correlate PID and USB device path through re-enumeration. Do not subtract wall-clock timestamps from app elapsed-realtime values without a recorded correspondence.

| Observation | What it establishes |
|---|---|
| Verified permission for the current enumerated device, including a valid already-granted path | Permission stage reached; a click alone is insufficient |
| `RDX.SESSION ... USB transport opened` | Helper transport constructor completed; retain nearby errors and device path |
| Service discovery | Protocol reached discovery; does not establish video selection |
| `VIDEO SELECTED` and decoder startup | Video configuration/decoder stages reached; not visible playback |
| `FIRST FRAME RENDERED` plus independent operator observation | Application render report and physical observation, recorded separately |
| First error plus following cleanup evidence | Failure classification and whether cleanup occurred |

If permission/startup fails, record later stages as NOT_REACHED or UNKNOWN, not as decoder failures. If TLS fails after USB open, retain the first error and session context. A read timeout alone does not establish Honda contention. If capture or installed identity is missing, classify the result as inconclusive. Do not add reinstall, preference changes, new kill loops, or extra retries inside the same attempt and then call it one controlled test.

This specification prepares interpretation; it is not a live command sequence. Current permission restrictions remain in effect.

## 6. Primary evidence for each finding

Line numbers below are LF-delimited physical lines, including blank lines. Paths are relative to the repository root; links open the relevant files.

| ID | Primary evidence |
|---|---|
| E1 | [v6g-retry log](../../logs/car-test-20261028-v6g-retry.txt):101,111 (helper/A11Y stop), 175 (helper service created), 20879,20955 (first request), 22767 (first rejection), 54307 (15-attempt failure), 54309,54311 (direct-grant attempt/failure). `offline-check.json:log_metrics` records all 15 request/rejection counts and zero downstream markers. |
| E2 | [v6e log](../../logs/car-test-20261028-v6e.txt):6587 (selected codec/active area), 6737 (decoder started); event counts and first-line excerpts in `offline-check.json`. |
| E3 | [v6f log](../../logs/car-test-20261028-v6f.txt):2113 (helper PID 5253), 2273 (USB open), 2624 (codec setup), 3134 (TLS error, PID 5253), 3137 (GAL error). |
| E4 | [Run-CarTest.ps1](../../../scripts/Run-CarTest.ps1):147–149 removes the pre-start helper force-stop. [PermissionClickService.java](../../parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/PermissionClickService.java):129,146,156,203–211 distinguishes click logging and service-connected logging. Historical marker counts are in the new JSON. |
| E5 | [build-report.json](../../parallel-aa-receiver/usb-helper/build/20261028-164612-233/build-report.json):6–14 (APK/hash/audit), 26–29 (session input hash), and `sourceHashes` decoder entry; current hash results in `offline-check.json:candidate`. |
| E6 | [UsbHelperService.java](../../parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/UsbHelperService.java):104,107 (startup actions), 129–137 (already-granted path), 391–396 (callback handoff), 429–434 (session start). [UsbBulkTransport.java](../../parallel-aa-receiver/src/com/rdx/fullscreen/projection/UsbBulkTransport.java):38–42 performs open and forced interface claim. |
| E7 | [v6h plan](../../agent-reviews/v6h-honda-disable-plan.md):4,25–66 calls for implementation. Search `rg -n -e hondaDisabled -e HONDA_DISABLED -e HondaDisabled scripts/Run-CarTest.ps1 analysis/parallel-aa-receiver/usb-helper/source` returned no matches. |
| E8 | [Run-CarTest.ps1](../../../scripts/Run-CarTest.ps1):18–20,29–34 (targeting), 43–48 (moving default), 55–61 (install continues), 129–140 (timer and kill loop), 153–177,182 (service checks then READY), 169 (accessibility list replacement). [device-kill-honda.sh](../../../scripts/device-kill-honda.sh):4–8 has count-only termination. |
| E9 | [UsbHelperService.java](../../parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/UsbHelperService.java):129–132 skips duplicate granted AOAP, 168–174 stops polling in GRANTED/FAILED. The runner's plain service start is at line 149. |
| E10 | `offline-check.json:frozen_artifacts` and `preservation_against_previous_review`; expected anchors in [PROJECT-RULES.md](../../../PROJECT-RULES.md):29–38 and inventory in the prior [evidence.json](../../agent-reviews/claude-resume-20261102/evidence.json). |

## 7. Assumptions

- “Resume” continues local preparation for the last helper experiment. It does not select v6h implementation, authorize device access, or substitute an M5 session.
- The user reports no ADB connection. This was not independently probed.
- The pinned APK is useful as a reproducible historical baseline. Its suitability for another live run is not established by this packet.

## 8. Unresolved uncertainties

**UNKNOWN:** currently installed APK/hash; historical APK-to-log mapping; exact cause of the latest denied callbacks; current accessibility binding and UI/lock-task state; persistent USB defaults; phone preference and USB mode; actual remaining timing window; visible fullscreen playback; live cleanup behavior; and whether the proposed Honda-disable approach works end to end.

The missing `connected` and render markers are bounded capture observations. No claim is made that accessibility never connected or that a physical frame was never displayed outside these captures. v6h and runner recommendations remain unimplemented.

## 9. Exact diff summary

- Added `README.md`: test preparation, evidence, limits, and this ten-part report.
- Added `Test-OfflinePreparation.ps1`: fixed-scope local hash, source-provenance, parser, preservation, and saved-log checks; no device or build operations.
- Added `offline-check.json`: output of the local checker; no fabricated live results.
- Added `observations.template.json`: future-run fields left unfilled, with explicit `NOT_RUN` status.
- Existing files edited: **0**. Files removed: **0**. Git staging/commits: **0**.

## 10. Preservation checks performed

The checker recalculated all four frozen artifact hashes and all 263 hashes in the preceding review's preservation baseline: every frozen anchor matched and no baseline file changed. [E10] Existing tracked modifications remained present; they were not reset or staged. No key material was read, no binary rebuilt, no device-facing script executed, and no milestone state advanced.
