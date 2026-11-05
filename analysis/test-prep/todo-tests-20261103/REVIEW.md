# Code review status — closed 2026-11-03

Process: Claude built → Codex attacked → Claude fixed → Codex re-checked → Claude fixed → Codex final check → Claude fixed the last item.
- [CODEX-REVIEW.md](../../agent-reviews/todo-tests-20261103/CODEX-REVIEW.md)
- [CODEX-RECHECK.md](../../agent-reviews/todo-tests-20261103/CODEX-RECHECK.md)
- [CODEX-FINAL.md](../../agent-reviews/todo-tests-20261103/CODEX-FINAL.md)

Every BLOCKER and SHOULD-FIX is now marked FIXED by Codex, except the last Build-Test lock-cleanup item. Claude fixed that afterwards; all 6 suite scripts parse with 0 errors. Codex's sandbox couldn't run the PowerShell parser, so Claude ran it.

| Test | Status | Notes |
|---|---|---|
| A watch-only | Ready | No code change; extra log tags only |
| T09 volume display | Ready **after T06** | No code issues found; whether the signal reaches us is unknown |
| T10 track buttons | Ready | Lost-release and stock 100 ms timing fixed; possible Bluetooth double skip is what the test measures |
| T11 mic | Ready (experiment) | Teardown keeps every native object if capture won't stop; failures pause cleanly; strict ack ceiling (drops a buffer on timeout) |
| T12 reconnect | Ready | Single start gate, unique generations, watchdog reconcile, fail-closed, operator STOP stays stopped |
| T13 day/night | Ready | Synchronized report/destroy; failed report retries |
| Tools | Ready | Full source verification; failed switches roll back; builds refuse while a test source is active |

Still unknown, so the car tests decide:
- Native-call threading and termination.
- Mic permission and routing in the car.
- Whether Honda's broadcasts reach our app.
- Real double skips.
- Second-session reliability in the same process.

Accepted risks:
- Plugging in the phone can restart a stopped helper through the existing attach screen (baseline behaviour).
- The baseline direct-grant path sets GRANTED without a handoff (pre-existing).
- T11 releases acks without checking their session, as stock does; mismatches are logged.
- T13 destroy waits indefinitely if a native report never returns.

## Batch 2 (2026-11-05): T25, T30, T33, T34, T35, runner hooks
Codex review ([CODEX-BATCH2.md](../../agent-reviews/todo-tests-20261103/CODEX-BATCH2.md)), fixes, then re-check ([CODEX-BATCH2-RECHECK.md](../../agent-reviews/todo-tests-20261103/CODEX-BATCH2-RECHECK.md)).

| Test | Status | What was fixed |
|---|---|---|
| T25 car GPS | Ready | Subscribes even if GPS is off at start |
| T30 persistent + dismiss | Ready, after Claude's final fix | Receiver needs DUMP (system/adb only); OFF stops the boot service; every check re-reads the switch; checks up to 5 min; write and remove results checked; scans for an already-visible warning; the runner's undo also runs on a failed gate, and a skipped undo prints NOT FULLY CLEANED; the undo ends with a check that our accessibility entry is gone |
| T33 absolute touch | Ready | A held touch is released on minimize/teardown; DOWN/MOVE use their own coordinates |
| T34 volume look | Ready | Fade animation cancelled on teardown |
| T35 home launch | Ready | Only the stock ProjectionActivity window triggers restore |

Accepted: the T30 accessibility list is read-modify-write (another writer at the same instant could lose an entry), and the global accessibility switch is shared. Live behaviour of all of these is UNKNOWN until car-tested.

## Batch 3 (2026-11-05): T37, T38, T39, T41, T43, Check-Capabilities, Add-Phone
Codex review ([CODEX-BATCH3.md](../../agent-reviews/todo-tests-20261103/CODEX-BATCH3.md)), fixes, then re-check ([CODEX-BATCH3-RECHECK.md](../../agent-reviews/todo-tests-20261103/CODEX-BATCH3-RECHECK.md)).

| Test | Status | Notes |
|---|---|---|
| T37 frame rate | Ready | Per-frame work is a clock read and counters; logs once per 10 s |
| T38 settings | Ready | Reports the effective density |
| T39 Honda audio source | Ready, after Claude's final fix | Only system-app media browsers get a root; no media-button claim; session active and PLAYING only while AA runs (AaSessionService notifies on start/stop). Accepted: an app the user grants notification access can still drive active sessions (Android design) |
| T41 multiple phones | Ready | Helper service requires DUMP (system, adb shell; same-app callers exempt); a new main phone clears extras |
| T43 self-recovery | Ready | Port of the reviewed T12 design verified byte-for-byte; recovers ENDED sessions only (not frozen ones); retains native objects if an audio worker survives |
| Check-Capabilities | Ready | Read-only |
| Add-Phone | Ready | Checks the exit code, "Starting service" and error text |
| T42 system audio | Dropped | Stock uses two sinks; system sounds already play via guidance |

## T50 feature bundle (2026-11-05): T25, T33, T34, T35, T37, T38, T39, T41 behind switches, plus Survey and VISIT.md
Codex review ([CODEX-BUNDLE.md](../../agent-reviews/todo-tests-20261103/CODEX-BUNDLE.md)) was NOT READY. Claude made the fixes below; the re-check ([CODEX-BUNDLE-RECHECK.md](../../agent-reviews/todo-tests-20261103/CODEX-BUNDLE-RECHECK.md)) says all four are FIXED: **READY FOR CAR TEST** (parked checks).

| Finding | Fix |
|---|---|
| Tile return and media source changed mid-session (BLOCKER) | All five switches are now in the per-connection snapshot. The media-source component is set only at session start. |
| Settings long-press not guarded (BLOCKER) | The screen opens only after AA is confirmed minimized. If it can't minimize, nothing opens. If the screen fails to open, AA is restored. |
| All-off differed from baseline | Plain volume HUD uses the exact T24 path again. Side-panel releases restore exactly as the baseline does; only a lone 1.5 s hold opens Settings. "Reset all" also resets density and the volume display. |
| VISIT.md | Defaults check before comparing; Home before each replug; Standard verification replug; all checks parked; T41 needs Honda Disabled/Never |

Accepted differences with everything off: the fine-location permission, frame-rate logging, the two launcher icons, and the side-panel long hold. Driving-state gating is not possible, because the car always reports parked (user decision). Build FF521CEA…; offline check PASS; host tests PASS (69 checks).
