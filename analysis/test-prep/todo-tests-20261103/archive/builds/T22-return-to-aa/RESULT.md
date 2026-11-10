# T22 return to AA

## Run 1 — 2026-11-04 (build D1011793…, v2)
- Long Back: PASS. Shows Honda Home, music continues, AA button shown (OVERLAY_MINIMIZED). Short Back acts as Back in AA (shortBackPair).
- Double Home: FAIL. No HOME_KEY logged. With Honda's launcher in front, PhoneWindowManager hands Home to the launcher itself (the launcher is in mHomeAllowedPackages), so no "homekey" broadcast is sent.
- AA button: not reachable. The touchpad is absolute on Honda screens.
- Collected, cleanup verified.

## Run 2 — pending (build 9979E24E…, v3)
The accessibility service observes Home (never consumes it) and logs every key it can see, for a possible side-panel remap.
- Run 2 (v3, 9979E24E…): operator: works with Back or Home. Logs: 9 OVERLAY_MINIMIZED, 8 OVERLAY_RESTORED, A11Y_KEY saw Home (code 3, scan 172) x37, Back x13, the side-panel button = code 172 scan 362 (Guide, part of the Diagnostics shortcut), console 148/150/152. Diagnostics checkpoint passed with key filtering active. Collected, cleanup verified.
- **PASS. Promoted to the baseline.** The user's preference (Home goes Home, side-panel button opens AA) is T22b.
