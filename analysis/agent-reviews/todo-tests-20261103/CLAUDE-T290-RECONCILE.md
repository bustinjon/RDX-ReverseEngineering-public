# T290 reconciliation (Claude, 2026-11-09)

## Evidence review (CODEX-FREEZE2.md)
Verdict: WEAKENED. Accepted after primary checks:
- The 41.9-s boot gap was a Honda telephony transient focus (honda_acm, playRingtone), not a radio stall. Verified at P:7773-7792 and 13518-13521.
- The PBAP overlap was overstated.
- Rates are per ~1.04 s.
- The loopback attribution and the "phone side" conclusion are UNPROVEN.
- The CPU exclusion is weakened (no per-core or lock evidence).

Retained:
- During freezes, delivery through p2p-wlan0-0 collapses (0-4 packets per sample) with no netdev errors or drops.
- 21:37 shows a freeze with no logged BT/Wi-Fi event.

## Build
Final build: T290-bundle 315126AF725F375B7AFE83C0E6884F2C4A20DE0CD137EF4516A01F9D5E179454, PASS 259. It implements ranks 1-3:
- Recorder: timestamp/dt, readPhase/readBytes, session-socket rx/tx queues, p2p tx, lo, TcpExt loss counters.
- Event timeline: BT/Wi-Fi/phone broadcasts.
- Boot-delay A/B switch (OFF by default).

Ranks 4 (channel) and 5 (receive buffer) are deferred.

## CODEX-T290.md
- BLOCKER (privacy): fixed with the safeExtra allowlist and a host test.
- Pending boot callback: fixed (cancelled when a start proceeds).
- Socket attribution: fixed (matches the session peer port; outbound T200 sessions are skipped).
- Accepted: turning the delay switch OFF during an active wait does not cancel that wait. It applies from the next start, and VISIT says to set it while parked.
- Registration on a non-main thread and protected-broadcast behaviour on API 22 are UNKNOWN. Registration is try/caught, and T290_TIMELINE_ON/FAILED is logged.

Loop stopped.
