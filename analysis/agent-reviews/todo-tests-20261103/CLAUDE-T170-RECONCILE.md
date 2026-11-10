# T170 reconciliation (Claude, 2026-11-08)

Final build: T170-bundle 0D8DA9E4D59D8CC46921F9CCEF369555CA8FA61EF0DA22336C1DD5206286A1AD, PASS 217 bundle checks plus feature suites.

- USB swap buttons (user request): REMOVED after review. Verified in decompiled Diagnostics:
  - Developer Diagnostics is visible="false" (diag_menus.xml:251-253) and opens only after a 5-s hold of key 172/142 on the menu (MenuActivity.java:290-311). An app can't inject that hold.
  - Functional Setup has an unrelated "Apple CarPlay" item (diag_menus.xml:194-196).
  - Dealer MainActivity uses lock task.
  - So automation can't reach USB Mode Switch safely. Told the user.
- P5 nudge (user asked for the trigger): kept as a parked, opt-in variant (Wireless variant = Nudge).
  - FIXED: stop/deadline race, stale peer, variant snapshot, replug cancellation. The nudge is skipped while AaSessionService.sessionActiveNow(), re-checked before connect.
  - ACCEPTED RISK: Honda HFP impact is UNKNOWN (an ordinary app can't read Honda's Broadcom HFP state). Mitigations: never during a call (re-checked before connect), one try, 3-s deadline, closed at once, no AT/audio, no retries. The checklist says no calls during the test.
- Wi-Fi-off stop: OK (Codex).
- Developer page fit (15 items, 8 rows) matches the T150 page that fit on the car. Accepted.
- Loop stopped here (Claude).
