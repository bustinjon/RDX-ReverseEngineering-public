# T200 reconciliation (Claude, 2026-11-08)

Final build: T200-bundle 2D88C7599006EC6CDFF13FFC336F041D164C88385DF448C1A2D1446954481918, PASS 234 bundle checks plus feature suites.

- Joins the two halves proven in T190: the phone-initiated TCP 5288 connection (after the native WPP bootstrap) is handed to AaSessionService (ACTION_ACCEPT_TCP / beginTcpSession), and the normal AA session runs on it.
- Review CODEX-T200.md:
  - OK: the HU speaks first; same path as the head-unit-server session that worked; the HU stays the TLS client; ping 8 -> pong 9 echo.
  - BLOCKER (credentials re-sent on a type 2 during projection): FIXED by ignoring it while tcpSessionNow (open-headunit holding state).
  - SHOULD-FIX items FIXED:
    - stop ends the Wi-Fi session
    - the Bluetooth accept cap is 200
    - the held bootstrap channel is released at session end
    - handoff rollback
- Recheck CODEX-T200-RECHECK.md: one new issue (an uncaught startService in the stop call would skip cleanup), FIXED with try/catch. Loop stopped.
- Not yet daily-use: wireless runs only while Developer > Wireless test is on (30-min window, extended while a session runs). Making it automatic at boot is the next step after a car PASS.
