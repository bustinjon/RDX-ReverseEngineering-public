# T240 interrupted startup and recovery correction — November 9, 2026

**Recovery path defect corrected; actual recovery awaits the operator-run result.** The T240 APK has not been replaced. The original startup reached timed readiness, then the host timed out launching the untimed monitor. This is not evidence that the per-device Off fix failed.

## 1. Files inspected

PROJECT-RULES.md / AGENTS.md; T240 operator-20261109-195909, live-20261109-195941 and retry-20261109-195941 evidence; actual run helper_20261109T195951_3a652f5e982348bfbe24267c585bf509 session, command journal, disarm/configuration receipts and operator-retrieved recovery evidence; T240 SettingsActivity/WirelessProbeService snapshots; Prepare/Collect scripts; core cleanup and existing Recover-SavedSession.ps1 template.

## 2. Files changed

New suite tools/Recover-T240Interrupted.ps1 and Recover-T240-interrupted.cmd. New review scope, evidence-generation and dependency-check procedures, report and fake/offline UI staging under this directory. Corrected the generated recovery helper's local collector path after the operator's failed recovery attempt. No application/APK/spec replacement, shared runner/template edit, original log rewrite, key access, Git mutation or device command by this agent.

## 3. Commands run

Read-only file/search/hash inspection and parsed filtering of saved command journals. Offline procedures:

[Code block omitted; consult project-authored source.]

Prepare-Recovery copies/narrows existing recovery code but does not execute it. The operator ran the generated recovery shortcut; its saved journal is reviewed as external evidence. Prepare-PendingUi compiles a proposed SettingsActivity only against the verified production JAR/API33 and saves its diff; it does not replace bundle source or build/sign an APK. No agent ADB/fastboot, live device, network or agent delegation.

## 4. Tests run and results

- Saved session/installed hash matches existing T240 **14CBCFFA0F02AC85AB271C3DE8E9DE2EC3560198F6C71291D6F4E52E6FA77004**; timed-stage output contains READY with 168 seconds remaining.
- Startup journal identifies **ADB command timeout**, exit -1, while launching longdrive-monitor.sh. Saved disarm/configuration receipts show those earlier steps succeeded. No successful longdrive-latest.json was created.
- Operator's recovery attempts failed pushing a local tools/collect-owned-processes.sh that does not exist. This is a generated-script dependency error, not an ADB authorization failure or a new Android failure.
- Corrected helper parses; canonical bundle collector, bundled ADB, core and pull-support dependencies all exist. The collector is now checked before device operations. Exact run-id/installed-hash scope and original artifact hashes verify. Result: recovery-path-verification.json PASS_OFFLINE.
- Pending main-settings toggle compiles; exactly one global wireless button is on Main and Wireless Test remains on Developer. Result: pending-main-page/verification.json. **NOT packaged or installed.**
- Actual device cleanup/accessibility restoration/owned-process absence: **UNKNOWN until a successful recovery receipt**. No SAFE TO DISCONNECT claim is made by this report.

## 5. Findings

**F1 — The two wireless switches intentionally control different modes.** Turning Developer Wireless Test off calls WirelessProbeService.stop, whose ACTION_STOP branch invokes shutdown then startDaily. Everyday wireless starts again when WIRELESS_AA remains enabled. This explains the reported T230 behavior. Wireless Test is already on Developer; the everyday toggle currently lives under Phone & devices, not Main.

**F2 — T240 was installed before the NOT READY failure.** Ordinary guarded preparation passed. Untimed conversion then stalled waiting for the monitor-launch ADB command to complete. The shell command was launched at the saved journal point and exceeded the 30-second host transport bound. Retrieved recovery evidence contains monitor.pid 6065 and a health SAMPLE for this run, showing the monitor did execute at least one sample despite the launch command not returning. **The underlying reason the host command hung is UNKNOWN.** Do not claim that extending timeouts or bypassing readiness fixes it.

**F3 — Cleanup ran but complete restoration was not verified.** The failure handler's saved output includes ACCESSIBILITY_NOT_RESTORED_SETTINGS_CHANGED and CLEANUP_FINISHED. That conditional cleanup preserves settings it does not recognize as its exact write; the marker alone does not establish either an unsafe accessibility state or successful restoration. The ordinary Collect shortcut requires longdrive-latest.json/longdrive-session.json, which were never completed, so a recovery path must address the exact saved interrupted run.

**F4 — The first recovery helper contained an avoidable copied-path defect.** Its inherited collector reference used PSScriptRoot, which now points to suite/tools rather than the original template directory. The operator's journal reports cannot stat that nonexistent local file. The script now binds ownedCollector explicitly to builds/T240-bundle/collect-owned-processes.sh, verifies it exists before device commands, and pushes that verified path. The generator was corrected too. The earlier syntax/path check missed this dependent input; the new dependency regression check covers it.

**F5 — Requested UI change is concrete but held outside the current package.** A compile-checked pending SettingsActivity moves the existing everyday wireless button from Phone & devices to Main; its callback behavior is unchanged, and Developer Wireless Test stays in place. It has not changed the installed/recovering artifact. Recovery should be verified before replacing the candidate/build/source manifests referenced by the saved run.

## 6. Primary evidence for each finding

- F1: T240 SettingsActivity.java:241–245 (everyday toggle), 308–315 (Developer Wireless Test); WirelessProbeService.java:522–526 (stop then startDaily), 160–165 (owner switch gate). The T230 base uses the same mode split.
- F2: actual session.json InstalledSha256/Status; live-20261109-195941/timed-stage-output.txt; saved commands.jsonl original failure at 20:00:49.5536371Z. Filtered copy: failed-commands.json. Operator-retrieved recovery-evidence-before contains monitor.pid and health.log with run rdx_2687017da9454a6b85fc3ad879072e8f, uptime187.70, initial_app_pid5707.
- F3: live-20261109-195941/refused-cleanup.txt; core New-CTCleanupText conditional restoration; absent T240 longdrive-latest.json; Collect-Test.ps1's required untimed identity fields. Original session records OriginalServices empty / OriginalEnabled0, but current device values require actual postchecks.
- F4: actual command journal failed pushes at 20:08:34.1929196Z and20:08:59.0813824Z; suite interrupted-recovery-output.txt; corrected tools/Recover-T240Interrupted.ps1 ownedCollector declaration/push; recovery-path-verification.json and Verify-RecoveryPaths.ps1.
- F5: pending-main-page/SettingsActivity.java, ui-only.patch, compile.txt, verification.json. Original T240 source/APK hashes remain pinned in preservation.json.

## 7. Assumptions

The reported NOT READY corresponds to the supplied 19:59 operator folder. The operator's recovery outputs correspond to the pinned run; serial, run-id and installed hash are validated rather than inferred from vehicle Home state. No further car condition check is performed by this agent.

## 8. Unresolved uncertainties / immediate operator step

If ADB remains connected, rerun **Recover-T240-interrupted.cmd** after the path correction. It collects available evidence, stops only owned run diagnostics/helper, and verifies original accessibility values and owned-process absence before reporting recovery complete. If it fails, retain the new output; do not reinterpret it as a readiness PASS. If the operator must leave, turn the car fully off; actual cleanup remains unverified until the next recovery check.

Underlying monitor launch hang remains UNKNOWN despite proof that the monitor started. No blind retry loop, timeout increase or readiness bypass was added. The main-page UI is staged only. The pre-existing teardown stall/session-end race remains outside this fix.

The project AGENTS.md instruction **“Never run adb, fastboot, or anything that touches a car, phone or USB device”** applies to this agent; this is why the prepared recovery file is operator-run and no live recovery result is invented here.

## 9. Exact diff summary

Suite: one exact-run recovery PowerShell file and one command shortcut. Recovery correction adds a canonical ownedCollector path, early existence check and uses it for the push. Generator receives the same substitution and recognizes the original monitor timeout separately from later recovery errors. New dependency/scope/identity verification covers that mistake. Pending UI diff moves one existing button block; no wireless policy or transport logic changes. Zero current bundle/application/APK/source-manifest changes.

## 10. Preservation checks performed

Original T240 snapshot/APK/candidate/build/source manifest and original operator/live/retry artifacts are hash-pinned and rechecked unchanged by Verify-RecoveryPaths. Host source was already restored by the failed Start's existing source-restore receipt. No private material, Git state, readiness implementation, milestone or frozen artifact was modified. The operator-run recovery creates its own evidence under the actual run; these new records are not treated as agent device execution. Current car state is UNKNOWN until successful postchecks.
