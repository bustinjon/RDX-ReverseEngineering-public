# T100: Claude's reconciliation of the Codex reviews

Codex passes: CODEX-T100.md (NOT READY), CODEX-T100-RECHECK.md (NOT READY), CODEX-T100-RECHECK2.md (READY FOR CAR TEST, parked review scope; live behaviour unknown).

| Finding | Verified | Action |
|---|---|---|
| Claim E wrong: log has Video focus request=2 reason=0 at 16:54:49.715 | Yes. Claude's grep was case-sensitive. VIDEO_FPS stops after 16:54:45 | Exit icon froze AA (we answered native focus and stayed on top); the 16:55:09 detach was probably the operator's replug. T100 minimizes and goes Home |
| BLOCKER exported receiver trusted the intent | Yes | DUMP sender permission, action check, device read from UsbManager, only the path passed. Codex confirmed the system sender passes |
| BLOCKER queued strip UP lost at teardown; touches could bunch | Yes | Pacer is a queue spaced from the real send, flushed on release |
| BLOCKER direct press could overtake queued strip touches | Yes | flushStrip before any direct press |
| attachHandled set too early; duplicate raw switch | Yes | Set only after a real start or switch, on all three switch paths |
| Focus ignored stock's reason and visibility; no real Home | Yes | Mode 2, reason 0, selected only; starts Honda's HOME activity |
| Video retry after re-minimize | Yes | Retry needs no native focus and not minimized |
| Settings watchdog false restore | Yes | 3 s, cancelled by Home. A launch slower than 3 s still restores AA: accepted |
| USB UI missing Disabled/Never note; full list silent | Yes | Note and "list is full" row |
| VISIT needed a parked gate before the drive | Yes | Added |

Accepted as known: a flush bypasses the 16 ms spacing (only at minimize, teardown or a press within 32 ms of leaving the strip). Allow in Settings only helps devices in device_filter (OnePlus, the dongle, AOAP identities).


## Added after that review: skip guard and talk-button takeover

CODEX-T100-TALK.md (NOT READY), CODEX-T100-TALK-RECHECK.md (READY FOR CAR TEST, parked scope; hashes not recomputed in that pass).

| Finding | Verified | Action |
|---|---|---|
| BLOCKER SkipGate shared release counter could leave a key held | Yes | Per-key window and releases, reset per session, Codex's trace added as a test |
| BLOCKER takeover has no proof of a button press | Yes | Accepted by design: operator asked to replace Acura voice during AA, default-off switch. Added call-mode stand-down and no Assistant unless dismiss succeeded. Honda denies voice focus during calls |
| TalkGate re-fired after 4 s | Yes | Latched until NOT_ACTIVE, 30 s safety |
| Binder calls on the session handler | Yes | Dismiss on its own thread, closed flag |

Known limits: a call starting within the 400 ms before the Assistant key; a dismiss that returns but does not finish in Honda's native engine; Acura voice may flash first.


## Added after that: Home after a cold start

Operator report: from a cold start Home does nothing. T80's homekey receiver was wrong: Honda returns -1 for TYPE_SYSTEM_ERROR with no broadcast (car logs: reason=null only). Only the accessibility key filter sees Home. Persistent mode was blocked by a missing WRITE_SETTINGS (car log, removal path); now declared.

CODEX-T100-PERSIST.md: A and B confirmed for the cited paths, READY as a hypothesis test, no BLOCKER. Open: what turns accessibility off at boot (force-stop handling and failed binding are candidates), the app-op state, and whether the service really connects. Action: Settings now shows connected / not connected; VISIT re-checks after the last 300 s boot check.

Final build: see build-result.json for the T100 SHA-256.
