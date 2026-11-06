# T90: Claude's reconciliation of the Codex review (CODEX-T90.md)

Codex verdict: READY FOR CAR TEST (parked), no BLOCKER.

| Item | Codex | Action |
|---|---|---|
| 1 keepsExtras | OK | none |
| 2 Scroll clamp | OK | none |
| 3 PTT | SHOULD-FIX: console key 84 is forwarded with T93 off; VISIT overstated delivery | Fixed: AaSessionService.onAaKey drops 84 unless T93 is on. VISIT now says delivery is unknown. Not reproduced, accepted as known: stock's VR-focus coordination (requestVrFocus, isRecognizerActive). Honda voice may also open; the car test shows it |
| 4 Dash refresh | OK | none |
| 5 Migration | OK | none |
| 6 Checklist | OK | none |

Rebuilt: T90 123ED19747FC95074DCECAA138679901903CE9807AA665AD3FBC25FD1C22D2AD, PASS 158 bundle checks plus the feature suites, baseline restored.
