# To-do status — November 4, 2026

Scope: status summary from saved reports only. This task changes only this note; no implementation, device action, build or publication.

## 1. Files inspected

PROJECT-RULES.md, AGENTS.md, local Git status/history, todo-plan-20261102/PLAN.md, todo-tests-20261103 review files, test-suite README/cards, baseline-history.jsonl and B-current-baseline/candidate.json; latest A/T21/T11/T10/T13 result reports.

## 2. Files changed

This status note only. All existing files preserved.

## 3. Commands run

Read-only Get-Content/Get-ChildItem/rg and git status/log/show. No ADB, car/phone interaction, test execution, build or Git mutation.

## 4. Tests run and results

No tests run for this status query. Saved November4 results establish:

- A-watch-only: Maps route persistence PASS; reverse camera and return PASS; Bluetooth calls including reported wheel call controls PASS. Talk button invokes Honda VR and does not reach phone.
- T21: navigation speech with media playback PASS after guidance draining and internal duck/restore feedback correction; promoted.
- T11: AA mic icon and Hey Google/Gemini work by operator report, including high fan; music resumes; promoted.
- T10: console previous/next short presses PASS, no double skip with Bluetooth Media audio on/off; promoted. Wheel track buttons remain unresolved. Console holds can trigger Honda Bluetooth seek/pause behavior.
- T13: day/night changes PASS; promoted.

## 5. Findings / current remaining work

Current promoted baseline is F8C1EF5C33630A44301BD89E9F72D3E51E9173E0B11A9F9F6D7335E6C0BCEE18, recorded as T13 atop T10, T11 and T21. Older handoff pending statuses for Maps, mic and navigation speech have been superseded by these results.

| Remaining area | Current task/status |
|---|---|
| Reconnect and startup | Controlled three-cycle unplug/replug test, then ignition and cold boot separately; laptop-free startup, explicit-stop behavior and failure recovery. T12 exists but predates the new passing baseline; verify/rebuild against current baseline before use. Two earlier automatic reconnections are observations, not full qualification. |
| Steering-wheel controls | Track next/previous and routing talk/PTT to phone Assistant. Console track controls now work; the wheel events do not reach the overlay. Research Honda input/media integration. |
| Volume indication | Volume adjustment works; visible indicator remains missing. T09's direct amplifier-broadcast HUD path is marked dropped because the observed signal requires Honda-only permission. An alternative approach needs review. |
| Home/launch/resume | Clean Honda Home-to-AA launch and return, tile/icon if feasible, focus restoration and repeatable interaction with OEM UI. |
| Spotify compact row | Exact clean stock-AA/provider comparison still open; user reports stock failure too. Avoid more speculative receiver remapping before distinguishing shared AA/Spotify behavior. |
| Unauthorized-app warning | Narrow solution for recurring Honda warning; temporary boot overlay is not the final integration. |
| Qualification | Multi-hour drive, memory/performance, crash recovery, held/cancelled/edge input, audio duck/resume and repeated calls/camera transitions. Individual initial passes do not establish sustained reliability. |
| Delivery/infrastructure | Final installation/update procedure and refresh standalone Windows launcher/docs to the latest passing baseline after review. Existing long-drive launcher still selects older D1A29; avoid accidentally reverting new passing features. Checkpoint/publish only within authorized scope. |
| Optional vehicle data | Speed/gear/GPS and real vehicle state remain deferred. Day/night is now done. The November3 plan records the user's decision to retain the current parked-state behavior for now. |

## 6. Primary evidence

- [A-watch-only results](../test-prep/todo-tests-20261103/builds/A-watch-only/RESULT.md).
- [T21 navigation speech](../test-prep/todo-tests-20261103/builds/T21-nav-voice/RESULT.md).
- [T11 microphone](../test-prep/todo-tests-20261103/builds/T11-mic/RESULT.md).
- [T10 console/wheel distinction](../test-prep/todo-tests-20261103/builds/T10-track-buttons/RESULT.md).
- [T13 day/night](../test-prep/todo-tests-20261103/builds/T13-day-night/RESULT.md).
- [Promoted baseline metadata](../test-prep/todo-tests-20261103/builds/B-current-baseline/candidate.json) and baseline-history.jsonl.
- [Volume card/status](../test-prep/todo-tests-20261103/cards/T09-volume-display.md), [reconnect card](../test-prep/todo-tests-20261103/cards/T12-reconnect.md), [stock Spotify card](../test-prep/todo-tests-20261103/cards/T07-spotify-stock.md), [suite README](../test-prep/todo-tests-20261103/README.md).
- [Plan and review reconciliation](todo-plan-20261102/PLAN.md). Its dated plans/review UNKNOWN statements should be read with later November4 results.

## 7. Assumptions

Saved operator results and promotion records describe the latest completed work visible in this workspace. No new milestones or tests are assigned by this summary.

## 8. Unresolved uncertainties

Current live vehicle state UNKNOWN. Complete production qualification, steering-wheel track/talk access, volume presentation, controlled reconnect and cold-start behavior remain unverified. No fresh APK hash/runtime/source audit was performed for this status question.

## 9. Exact diff summary

One new Markdown status report. No source/script/configuration/build or existing report edits.

## 10. Preservation checks performed

Read-only inspection of project evidence/Git state; no frozen artifact, key material, source, device, settings or repository history changed. Local Git notes an unrelated global-ignore access warning; reads still returned local history/status. No network/publication action.
