# T220 bundle: car results (2026-11-09 ~08:45-08:55, operator report + logs)

Collect: SAFE TO DISCONNECT, KEEP. Logs: headunit-logs-20261109-085532 and runs/ (latest capture).

| Item | Result | Evidence |
|---|---|---|
| Everyday wireless starts by itself; also after power off/on | PASS | 08:49:41 BOOT_RECEIVED; 08:50:31 P4_START (daily); 08:51:21 T200_TCP_SESSION_START via=phone-wireless; 08:51:24 FIRST FRAME. The operator confirmed it connected after power off/on. |
| Audio drop-outs | FIXED | Every PCM id=4 line shows dropped=0 (T210: 32). Operator: no cut-outs. |
| Home / controls | PASS | Operator: works fine from Home for all controls. |
| Quiet Wi-Fi did not pause the station | BUG | P4_STATION_RESTORED 0/1 "kept for retry" (a stale paused network id that can't be re-enabled), then P4_STATION_PAUSE_SKIPPED, so the head unit stayed on the phone hotspot (operator saw it). Fix in T230: drop ids that no longer exist or keep failing. |
| First connect slow (~50 s) | Partly fixed | 08:50:32-33: the phone knocked 6 times before the group was ready (P4_BT_NO_NETWORK); 08:51:09 the phone reported type 6 status -11 (join failed, likely busy hosting the hotspot the head unit was on); the second try at 08:51:21 succeeded. Fix in T230: wait for the group instead of closing; the Quiet fix removes the hotspot conflict. |
| P4_DAILY_HEAL bluetooth listener 08:53:21 | Noted | The health check reopened the listener after the session took the bootstrap thread; session unaffected. |

Operator request: per-device USB / Wireless / Both setting in Phone & devices (T230).
