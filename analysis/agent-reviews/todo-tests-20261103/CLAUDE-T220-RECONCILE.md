# T220 reconciliation (Claude, 2026-11-09)

Final build: T220-bundle 239E6AC02A5DD97D65D8348E2506EACFC35DD3D3BD421598A4A2939FECEE615B, PASS 237 bundle checks.

Contents:
- everyday wireless AA: owner switch WIRELESS_AA default ON; starts at boot (BootBlockerReceiver + PersistentBootService); no time limit; START_STICKY; Quiet + 5 GHz; 30-s retry; a dailyWatch health check every 30 s
- audio cushion: queue 64, buffer 0.5 s

Operator decisions: on by default and Quiet ON (overrides CODEX-WIRELESS-DAILY item 9; the release notes will say how to turn it off).

Reviews:
- CODEX-T220.md: F1 blocker (no recovery), fixed with dailyWatch plus server-slot freeing. Recheck: two residual gaps, both fixed: takeover of a running test schedules dailyWatch; a late reset callback never clears a newer run's 5 GHz flag.
- Accepted: F2 (the Developer variant is ignored while everyday mode runs); guidance latency with the larger buffer is unmeasured (check prompts at the car).
- Loop stopped.
