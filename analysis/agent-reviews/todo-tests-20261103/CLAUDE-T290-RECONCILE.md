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

## Additions: channel 36/149 and audio stutter fix (operator request; CODEX-T290B.md)
Final build: T290 9FD3E7F680203D0FD17F54ECAF3573CC0A185DBBB6A8DDAE48847E127A382190, PASS 261.
- Restart race (SHOULD-FIX): removed the automatic restart. The buttons only save, and the operator applies a change with the main Wireless AA switch (off, 5 s, on; car-proven) or a car restart.
- Stranded variant (SHOULD-FIX): every start now uses DAILY_VARIANT (Quiet + 5 GHz). The Wireless test toggle no longer picks up an old saved variant.
- Audio overflow with higher max-unacked: ACCEPTED for the A/B test. The 64-frame queue still bounds the backlog (about 2.7 s), drops are counted in AUDIO_SUMMARY, and the default stays Off (16).
- Channel 149 refusal falls back to the driver default, and P4_5GHZ_REQUEST refused is logged. The laptop capture (wpa_supplicant freq=) verifies the real channel at the Start visit.
- Two Developer buttons were removed (phone head-unit server, variant selector) to keep 18 items with 24-px text.
Loop stopped.
