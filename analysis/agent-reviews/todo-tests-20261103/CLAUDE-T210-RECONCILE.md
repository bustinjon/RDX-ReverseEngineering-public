# T210 reconciliation (Claude, 2026-11-08 night)

Final build: T210-bundle 94E3382D92CBD14736C75E2923702F56C2ABC471BB3939972A2BC1E38A6A920D, PASS 234 bundle checks.

Fixes from the T200 car log:
1. no stuck-screen check for Wi-Fi sessions
2. requestVideo on restore for Wi-Fi sessions
3. Settings refusal wait 3 s -> 8 s
4. CODEX-T210 SHOULD-FIX: an already-open Settings (resumedNow) is never treated as refused

CODEX-T210.md: fixes 1-2 OK, no blockers; fix 4 added for its SHOULD-FIX.
Next design job: CODEX-WIRELESS-DAILY.md (automatic wireless at start-up).
