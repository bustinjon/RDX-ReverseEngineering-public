# T230 reconciliation (Claude, 2026-11-09)

Final build: T230-bundle D4251090D1AFE7EB4FC74162044038E0A14B63A67B7DB88A72C9E1E28336D893, PASS 245 bundle checks.

Contents:
- per-device USB / Wireless / Both / Off (operator request)
- the Quiet stale-network fix
- bootstrap waits 10 s for the group

CODEX-T230.md:
- BLOCKER (owner lockout before linking): FIXED. An unlinked peer follows the main phone's wireless setting until the main phone is linked; after that, unknown peers are refused. This also fixes the "unlinked Off" SHOULD-FIX.
- Extras-full cycle: FIXED (skips to Wireless only).
- Accepted: the 500-ms refresh after an async USB add/remove (UI only); a null configured-network list keeps ids queued (conservative).

Loop stopped after one round (the fixes are small and host-tested).
