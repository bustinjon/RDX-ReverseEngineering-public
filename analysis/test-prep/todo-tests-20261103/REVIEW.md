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
