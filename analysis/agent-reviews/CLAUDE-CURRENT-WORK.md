# CLAUDE-CURRENT-WORK (checkpoint — read first on resume)

Updated: 2026-10-26 late night. Phase: OFFLINE BUILD DONE. Waiting for (a) the user at the car, saying
"Latency measurement authorized.", and (b) a separate decision on committing the new files. No live guard file has
changed. The car hasn't been touched since the M5 cleanup.

## Built (untracked, not committed, not in PROJECT-INTEGRITY.json yet)
- `tools/m5/Test-M5TimingBoundaries.ps1`: 45/45 PASS, 9/9 mutations caught, writes nothing.
- `tools/m5/Measure-M5ReadinessHostPath.ps1`: disarmed fake-adb harness. Replay estimates only.
- `scripts/Measure-M5ReadinessLatency.ps1`: read-only live latency tool, serial only (concurrency removed). Two Codex rounds:
  `CODEX-LATENCY-TOOL-ATTACK.md`, `CODEX-LATENCY-TOOL-RECHECK.md`. Its 2 blocking defects (cleanup on interrupt, stdout
  error text) were fixed after the recheck, and an INTERRUPTED label was added; all were verified offline with the fake adb,
  but Codex has not seen this final version. Known limit: a hard OS kill of the host can leave one read-only adb client
  finishing its current command.
- `INCAR-CHECKLIST-LATENCY-MEASUREMENT.md`: plain-language session procedure.

## Live session command (only after the exact authorization phrase, user present)
`pwsh -NoProfile -File scripts/Measure-M5ReadinessLatency.ps1 -AdbPath <repo>/adb/adb.exe -Serial 00000000 -OutputDirectory analysis/parallel-aa-receiver/latency-<timestamp>`
Defaults only. One run. No retries. Afterwards confirm no adb client is left running, then STOP.

## LIVE LATENCY MEASUREMENT DONE (2026-10-26 20:44, user authorized, COMPLETE, exit 0)
Evidence: `analysis/parallel-aa-receiver/latency-20261026-204437/`. All 24 samples had lock INACTIVE and foreground Honda Home;
zero error text; no leftover client (the only adb.exe is the server from 2026-10-25). Car faster than in the earlier
captures: sample duration 1375-1547 ms (earlier 1469-1672); pm list 515-593 ms (earlier 593-750). With sleep: gaps 1781-1953
(the earlier first-gap cold cost of ~180-210 ms would still push it over). Without sleep: gaps 1390-1485 (>=515 ms margin).
Projected final freshness without sleep ≈ last sample + ~80-100 ms host ≈ 1650 ms today, ≈ 1770 ms at the earlier worst
(~230-350 ms margin). The harness max mode (~1950) was pessimistic. Single session, n=12 per cadence; latency varies by
~100 ms/sample between sessions. NOT yet analysed by Codex. STOPPED after the measurement as agreed.

## USER DECISIONS 2026-10-26 ~20:57
- APPROVED: apply the no-sleep fix (delete only `Start-Sleep -Milliseconds 400` from scripts/Test-M5ArmReadiness.ps1,
  exactly as `proposed-readiness-nosleep/Test-M5ArmReadiness.proposed.ps1`, hash 6E606EEA...). Codex verdict: "apply with
  conditions" (CODEX-NOSLEEP-FIX-ATTACK.md); not blocking. The user said to apply automatically when Codex finds no
  blocking problem; a local commit is OK, and the user pushes.
- APPROVED: self-scheduled check-ins to keep working through the day before the 3 PM car session (2026-10-27).
- If the post-apply Codex review finds a BLOCKING defect: restore the original collector (hash 542F25F2...) and its
  manifest entry, re-run integrity, and report. No live action at any time without the user present and the exact phrase.

## NO-SLEEP FIX APPLIED 2026-10-26 21:0x (check-in 1 done manually; cron de441472 cancelled)
Live collector is now 6E606EEA... (one deleted line). Manifest entries for the collector and PROJECT-STATE.json were updated;
a PROJECT-STATE note `readinessNoSleep20261026` was added. Integrity PASS (570). Boundary tests 45/45. Offline suite
PASS (62 deterministic, 1000 randomized, 87/913, 0 ADB). Harness on the live collector: mean mode 2/2 mirrored checks passed
(gap margin 343, final age max 1796); max (sum-of-maxima) mode 1/2: one run reached 2016 ms at the line-19 mirror -> refused
before Process.Start (fail-closed). Final freshness is the remaining tight spot; the sleep removal does not change it.
If the 3 PM attempt refuses on freshness, the next lever is a cheaper last sample (not thresholds).
Committed locally as 5356aa1 (user pushes).

## CHECK-IN 2 (2026-10-26 ~22:10): post-apply Codex check PASS
`CODEX-NOSLEEP-APPLIED-CHECK.md`: no blocking defects. Collector equals the proposal byte for byte (6E606EEA..., 9,496 bytes);
the diff is exactly one deleted line; the manifest changes only the collector and PROJECT-STATE entries; core and runner are unchanged; frozen
anchors match. Codex ran integrity (570 PASS) and boundary tests (45/45). It did not run `tools/m5/Test-M5ArmReadinessOffline.ps1`
(it invokes the collector/runner, which the prompt forbade). That suite was already run by Claude on this same hash at check-in 1: PASS.
Claude independently re-verified the hashes and the one-line diff. Fix stays applied. User pushed 5356aa1.

## NIGHT 2026-10-26 (user: "use your usage and codex usage now to prepare for next attempt"; no deferring to the car)
- Codex pre-mortem `CODEX-M5-SESSION-PREMORTEM-1026.md`: all parsers pass on real car output; dead ends in recovery (F1 late
  freshness refusal stranded app in ARM_ATTEMPTED, F2 ambiguous install, F3 snapshot retry, F4 async ARMED/dump, F6 UI scope, F8).
- Claude found by rehearsal: deadlineUTC re-parse ~+4 h (pwsh 7 ConvertFrom-Json DateTime -> local re-parse). Codex confirmed.
- Runner fixed (proposal -> Codex attack: apply with fixes, 2 blockers in PRESERVE -> fixed -> recheck: APPLY). Live runner
  now 2CEADBCD... (was 4028AA09...). Arm gating/thresholds/frozen APK unchanged. PROJECT-STATE note `runnerRecovery20261026`.
- New tools: `tools/m5/Test-M5SessionEndToEnd.ps1` (fake-car rehearsal, 15 scenarios, 144/144 on the live runner; the old
  runner failed 21/96 of the earlier set), `tools/m5/Get-M5ArmTimingReport.ps1` (offline margins after each ARM try).
- Checklist v3 (`INCAR-CHECKLIST-M5-RETRY.md`): exact commands with console tee, ARM rules (max 3 tries, only after
  "ARM NOT ISSUED"; 3 timing refusals -> stop), PRESERVE rules, 60 s on phone after Allow, explicit VERIFY.
- Tests after apply: integrity 572 PASS, boundary 45/45, offline suite 62+1000 PASS (0 ADB), rehearsal 144/144.
- Fullscreen-brainstorm Codex prompt was stopped by a safety classifier before it was written; not retried in that form.
- Cron: 739059b1 (Oct 27 9:07 re-run all tests on live runner), b9874f70 (12:13 plain-language "ready for 3 PM" note).
- Remaining unknown: installed-path final freshness margin. If refused 3x on timing: next lever is a faster last sample, offline.

## MORNING 2026-10-27: evening exploration prep (user: "prep for time this evening ... 5 hours of car time", user present, "no phone tests unless something great shows")
- a9f5bbe pushed by the user. Leaving the car on is not a concern (memory saved).
- Key finding re-read: our own app measured 1339x720 (live test 02); the 581 px B zone is `mBzoneAreaWidth` (framework
  resource, PhoneWindowManager:1252), separate from overscan. Historical `wm overscan 0,0,-581,0` widened native apps to 1920x720.
  Overscan currently zero (DisplayInfo prints ", overscan (" only if non-zero; absent in the 10-26 captures). Reset from zero
  removes the DisplaySettings entry (DisplaySettings.java:85).
- Grid APK 24843A11... and decoder 0.2 APK ADD395FC... are on disk, hashes match, never run on the car.
- Built (untracked): `scripts/Capture-RdxEveningSurvey.ps1` (read-only, 36 fixed commands + bounded getevent, allowlist,
  7/7 injected changing commands refused); `tools/evening/Invoke-RdxEveningStage.ps1` (BASELINE/INSTALL/LAUNCH/CAPTURE/
  OVERSCAN_APPLY/OVERSCAN_RESTORE/UNINSTALL/POSTCHECK, per-stage authorization tokens, PID-scoped result lines);
  `tools/evening/Test-RdxEveningRehearsal.ps1` (fake car, 13/13 PASS, 343 calls, 0 outside allowlist).
- Docs: `EVENING-EXPLORATION-PLAN-20261027.md`, `INCAR-CHECKLIST-EVENING-20261027.md` (v1 draft).
- Codex attack `CODEX-EVENING-ATTACK.md`: NOT READY (F1-F4 blocking: pm-path failure read as ABSENT, LAUNCH blocked by
  surviving process, reset file-write failure invisible, non-atomic journal; F5-F9 should-fix). All verified against
  source and fixed in runner v2 (150EF562...); rehearsal 19/19 (768 calls, 0 outside allowlist); survey 017344BF...;
  plan + checklist v2 updated. Rehearsal also caught a single-item array unrolling bug (fixed with @()).
- Codex recheck `CODEX-EVENING-RECHECK.md`: NOT READY (F3 retry reset ignored its own exit; F4 partial journal; F5 PNG
  check weak; F7 wording; DisplayInfo completeness). Fixed in runner v3 (83FF90B8...), rehearsal 22/22 (922 calls, 0 outside).
  Rehearsal found real captures end lines with \r\r\n; parsers now validated on ALL repo captures: 31 display (none
  with overscan), 86 window (all one identical stock 11-rectangle set).
- Codex recheck 2 `CODEX-EVENING-RECHECK-2.md`: READY (all fixed, no new blocking defect). Manifest: 5 evening files added,
  integrity PASS 577. M5 runner/collector/core/APK untouched (git status shows only evening files + checkpoint + manifest).
- Waiting for user OK to commit the evening prep (not committed). 3 PM M5 retry unchanged; evening stages need the user's phrases.

## CHECK-IN 3 (2026-10-27 morning, cron 739059b1, offline only, no ADB, no PREPARE)
- git status NOT clean: only the uncommitted evening prep (5 new files, 3 Codex reviews, this checkpoint, manifest).
  Not committed: no documented approval for it yet. Night work (runner recovery a9f5bbe) is committed and pushed.
- Live runner 2CEADBCD..., live collector 6E606EEA... (unchanged).
- Integrity PASS 577; boundaries 45/45 PASS (0 adb, 0 files written); offline suite PASS (62 deterministic + 1000
  randomized, 87 safe/913 refused, seed 20261025); end-to-end rehearsal on the live runner 15 scenarios, 144/144 PASS.
  Scratch outputs: scratchpad/checkin3-offline-*, checkin3-e2e-*.
- Nothing else in this checkpoint was marked for the morning. Live work only after "M5 retry authorized" at the car.

## CHECK-IN 4 (2026-10-27 midday, cron b9874f70, offline only)
- Check-in 3 results confirmed (all PASS). Live runner 2CEADBCD... and collector 6E606EEA... still unchanged.
- No unpushed commits (origin/main == HEAD a9f5bbe). Evening prep still uncommitted, waiting for the user's OK.
- Sent the user the plain-language "ready for 3 PM" note (checklist v3). Nothing live started.

## After live data
Compare the measured serial sample-duration distribution with the harness (final-freshness margin ≈ last sample duration
+ ~80-100 ms host). Decide between "remove sleep alone" and needing faster samples. Then Codex attacks it, the user
approves, and it is applied with hashes re-sealed.

## Hard limits (unchanged)
No live action without the user present and the explicit phrase. No guard bypass, no threshold loosening, no commit/push
without authorization, never `git add .`.
