# T140: Claude's reconciliation of CODEX-T140.md (NOT READY)

| Finding | Verified | Action |
|---|---|---|
| BLOCKER release could go to a position never sent (hover moved lastX while pressed) | Yes | UP uses the last sent position |
| BLOCKER reset cleared hn but not hi, so a stale slot could be the aim | Yes | reset clears hi |
| Ring condition changed behaviour with steady off | Yes | Only applies when steady is on |
| VISIT promised a still ring; ring uses raw finger coordinates | Yes | Wording fixed |
| Drag may pass the bottom of the active area (frame clamp only) | Yes | Accepted: frame clamp keeps it on the phone's screen |
| Added after the review: auto-dismiss now its own option, 90 scans every 2 s | - | In the recheck |

## Recheck (CODEX-T140-RECHECK.md, NOT READY on item 1)
Fixed: release() (minimize/teardown) also uses the last sent position; VISIT waits 3 minutes before a manual Dismiss. Auto-dismiss: OK (only the detector's exact Dismiss; independent of persistent mode). Review loop stops here: the remaining fix is one line with its own test.
