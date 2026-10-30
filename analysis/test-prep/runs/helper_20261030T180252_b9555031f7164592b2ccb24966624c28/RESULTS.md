# Connected helper setup — 2026-10-30

**Setup stopped: Honda restarted 275 ms after force-stop. No phone test began.** The corrected parser and fresh accessibility binding passed on the actual head unit. Do not plug in the phone for this attempt; cleanup is complete.

## 1. Files inspected

PROJECT-RULES.md, AGENTS.md, current runner/core, preparation validation, captured command journal, firmware force-stop implementation, and this attempt's capture and postchecks.

## 2. Files changed

New connected-preflight evidence in the preceding preparation directory; this run's artifact plan, installed-APK copy, command/session journals, capture, postchecks, result-summary.json, and this report. No implementation or app source edits this turn.

## 3. Commands run

Explicitly targeted ADB checks for serial 00000000; reviewed framework/services hash verification; two Home/lock-task observations five seconds apart; Run-CarTest.ps1 with Mode=Live, HistoricalBaseline, and SafetySeconds=60. This installed/verified the selected APK, started capture, established fresh accessibility, attempted Honda force-stop, then cleaned up after refusal. Retrieved capture and checked processes/settings. No milestone command, build, signing, staging, or commit.

## 4. Tests run and results

- Connected identity and reviewed framework hashes: MATCH.
- Home and inactive lock-task: confirmed in two samples.
- Installed APK: C7943B4FD9194E6AAD3E2C28AE68F880519D8EC624148AA794FBE9CA97F80757, matching the explicit baseline.
- Capture launch and fresh accessibility binding/callback: PASS on hardware.
- Honda stopped-state check: FAILED; package dump says stopped=false.
- Failure cleanup: no recorded command errors; settings list empty/accessibility_enabled=0; no helper process in postcheck; only connection-binding records remain in service dump. Owned capture PID 5554 is absent after cleanup.
- Frozen artifacts: 4/4 hashes match. The 38 prior offline tests were not repeated because implementation is unchanged.

## 5. Findings

The previous doubled-CR parser problem is resolved on hardware. The actual callback appears at capture.log:29847 and the runner advanced past the exact-process, bound-service, and fresh-callback checks.

At capture.log:29982, Honda is force-stopped at 14:03:07.395. Lines 30070–30073 record scheduled service restarts; line 30085 starts a new Honda process for GalService at 14:03:07.670. The subsequent package dump still reports stopped=false. A successful force-stop command does not establish durable USB ownership exclusion on this head unit.

The observed restart is a real setup blocker, not another parser failure. Its initiating caller/trigger remains UNKNOWN. Saved firmware ActiveServices.java:971 clears stopped state when bringing up a service; this supports the state transition but does not identify what requested this restart.

Do not repeat the same attempt or remove the stopped-state check to call this ready. The next implementation review should address a stable Honda coexistence/disable strategy, using the existing Honda-disable research, before another phone attempt. No such alternative was implemented or activated here.

## 6. Primary evidence for each finding

- commands.jsonl: full targeted requests and raw outputs, including successful accessibility checks and failed Honda state check.
- capture.log:29847 fresh callback; :29982 force-stop; :30070–30073 restart scheduling; :30085 GalService process restart (275 ms later).
- honda-stop-evidence.txt: active package User 0 stopped=false.
- session.json: FAILED, installed hash, cleanup/capture-cleanup status.
- post-settings.txt, post-helper.txt, post-processes.txt, capture-termination.txt: cleanup postchecks.
- result-summary.json: evidence hash, frozen hashes, and bounded outcome.

## 7. Assumptions

The user's explicit ADB authorization covers this prepared helper-baseline test and its necessary cleanup. No permission for another milestone or a new app strategy is inferred.

## 8. Unresolved uncertainties

The restart trigger, future ability to keep Honda inactive, and all phone permission/transport/video outcomes remain UNKNOWN. The helper USB session, watchdog, and Honda kill loop were not started; therefore their runtime behavior was not tested in this attempt. The baseline still differs from two current Java inputs and has PENDING static audit.

## 9. Exact diff summary

Evidence files added only. Existing implementation, source, APK build artifacts, instructions, and milestone records unchanged. No files deleted or staged. Device changes were the authorized baseline installation and temporary preparation settings/processes; cleanup restored the observed accessibility settings and stopped the owned helper/capture.

## 10. Preservation checks performed

All four frozen artifacts match their anchors. The selected APK matches its explicit hash. Historical evidence was retained. The firmware system logger was left running; cleanup targeted only this run's logger. No key material was queried or printed in this turn. No milestone advanced.
