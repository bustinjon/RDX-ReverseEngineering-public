# T170 bundle: car results (2026-11-08, operator report + logs)

Build 0D8DA9E4D59D8CC46921F9CCEF369555CA8FA61EF0DA22336C1DD5206286A1AD. First Start refused (UNTRACKED_HELPER, the T160 copy was still running); Collect-T160 with UNDO cleared it. Collect: SAFE TO DISCONNECT (runs/helper_20261108T183827…), with UNDO.

| Item | Result | Notes |
|---|---|---|
| Wireless variants Secure / Insecure / Nudge | NO CONNECTION | Operator: no wireless AA message on the phone; it lists "DIRECT-…". Collect capture: 13:39:58 P4_ANNOUNCE groupReady=true, P4_WIFI_CREDENTIALS_SENT, P3_PAIRING_REQUEST alreadyPaired=true (Nudge run). The RDX.P4 tag was not in Collect's filter, and the head-unit saves from this run were gone by the next pull (19:38), so the per-variant results (SDP, nudge) are LOST. T180 fixes this: TAG RDX.WIRELESS plus logTags. |
| Station Wi-Fi retries | Not the cause | wlan0 wrong-key retries ended 13:36:56; group started 13:39:46 on 2412 MHz (CODEX-WIRELESS2 F6). |
| Music after Gemini | FAIL (intermittent) | Drive log 16:49:38: state 5 sent at takeover; both media restores were "internal, not forwarded"; music stayed paused until the next press at 16:50:13. Same bug as T160 12:53:39. Fixed in T180 (owed restore, CLAUDE-T180-RECONCILE.md). |
| Side-panel return / Home while driving after the visit | Off (expected) | Collect's UNDO revoked the grant and turned Start without laptop off. T180 adds a KEEP choice at Collect. |
