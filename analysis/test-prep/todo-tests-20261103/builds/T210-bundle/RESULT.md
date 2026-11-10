# T210 bundle: car results (2026-11-09 06:50, operator report + Collect log)

Collect: SAFE TO DISCONNECT, KEEP. Evidence: runs/helper_20261109T114915….

| Item | Result | Evidence |
|---|---|---|
| Native wireless AA | PASS | 06:50:18 T200_TCP_SESSION_START via=phone-wireless; 06:50:21 FIRST FRAME (connected by itself). |
| False freeze / jump to Honda Home | FIXED | No STUCK_SCREEN in the session. |
| Settings bounce | FIXED | No SETTINGS_REFUSED. |
| Audio dropouts | FAIL | Operator: "some audio dropoffs". The media sink dropped 5 packets in the first 250, 13 by 1750, then 28-32 (T190 phone-hotspot session: 0). Cause (likely): the 16-frame queue (~0.6 s) and 0.2-s AudioTrack buffer are too small for Wi-Fi bursts. Some drops are late packets after talk takeovers (expected). Fix in T220. |
