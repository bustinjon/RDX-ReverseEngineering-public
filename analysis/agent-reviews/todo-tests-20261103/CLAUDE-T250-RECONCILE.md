# T250 reconciliation (Claude, 2026-11-09)

Build: T250-bundle 6F3DDC2F4ED8259B284AA3D89135CCEF80A77712EF63B6DE3D8C6E8648E86CA2, PASS 245 bundle checks.

Contents:
- the Wireless AA switch on the main page (Codex staged UI); Screen size moved to Developer
- CODEX-FREEZE rank 1: NATIVE on minimize / PROJECTED on restore (Wi-Fi only)
- 1-MB TCP receive buffer
- T250_READ_GAP / T250_PCM_GAP logging

Finding behind it: in T240 19:44:00-25 the video froze AND AudioTrack logged repeated underruns. Codex E5: only 10.2 s of PCM arrived in 39.9 s. Audio and video starved together, so the data stopped arriving: the Wi-Fi link or the phone. Cause UNKNOWN; T250 logs it.

CODEX-T250.md: no blocker.
- SHOULD-FIX (inherited): a phone NATIVE request with a nonzero reason, or mode 3, after restore can leave AA blank. Pre-existing; watch the logs.
- The Developer page (17 items, 9 rows, 51-px buttons) fit is unverified; the test still checks 15.
- Accepted for this test; revisit after the drive logs.
