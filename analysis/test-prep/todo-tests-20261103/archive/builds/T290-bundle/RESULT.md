# T290 result (car, 2026-11-10 ~09:40-09:56, parked, operator report + head-unit logs)

Collect: CAR LOGS COPIED (headunit-logs-20261110-095646), SAFE TO DISCONNECT, KEEP. Laptop capture: runs/helper_20261110T144407… (to 09:53:22).

| Check | Result | Evidence |
|---|---|---|
| Channel 149 really used | PASS | wpa_supplicant P2P-GROUP-STARTED freq=5745 at 09:46:54, 09:49:26 and 09:53:11 (5180 = ch36 before) |
| Startup freeze ~10 s (operator 09:45) | Recorded, both channels | ch36: session 09:45:14, freezes 09:45:19-28 and 09:45:28-38. ch149: session 09:47:02, freezes 09:47:10-17 and 09:47:17-20. Both about 8-9 s after connect. These starts were manual Wireless off/on, **not** a boot |
| ch149 after startup, hotspot off | No freezes 09:47:21-09:49:20 (2 min) | operator: "working fine" |
| ch36 after startup | 1 more freeze (09:45:50-52) in 80 s | short sample |
| Stutter fix | Not measured | operator cycled it at 09:49:17-20 and 09:52:51 (applies after off/on); only the 09:49:26 session ran at 32 frames, then the hotspot test |
| Phone hotspot on (operator 09:50) | **Freezes in a ~2-s cycle**: 21 freezes 09:50:13-09:51:35, each 2.1-4.5 s, then stop when the hotspot goes off | T280_FREEZE_START/END every ~2.1 s. This is the same periodic cadence as the T260/T270 "trickle" pattern |
| Boot delay (car off/on ~09:53:33) | **FAIL (bug)**: AA never started | 09:53:54 and 09:54:26 T290_BOOT_DELAY waiting. The boot channel-reset path (WirelessProbeService:542) calls stopSelf 3 s after reset when !running, and onDestroy removes bootDelayed. Fix: schedule the delayed start like dailyRetry (main-looper handler independent of the service) |

## Freeze recorder (all freezes in this test)
- **sockRxQ=0 in every freeze**: no data sits unread in the car. **Hackura's reader is not the bottleneck (confident).**
- sockTxQ 120-830 bytes during freezes: the car's own sent data stays unacknowledged, so the link is stalled in both directions or the phone is not servicing it.
- The p2p interface gets 3-5 packets per sample during a freeze, with no rx errors or drops.
- **The car's station Wi-Fi scans every 10.0 s for the whole session** (supplicant SCANNING, then SCAN_RESULTS every 10 s), because Quiet leaves the station disconnected. The first scans line up with the startup freezes, but 12 scans in a row (09:47:21-09:49:11) on ch149 had no freeze. So car scans are **not sufficient** on their own; whether they contribute on ch36 or at startup is UNKNOWN.
- No Bluetooth profile events during the freezes, apart from A2DP sink PLAYING_STATE at session start.

## Interpretation
- The phone hotspot is a confirmed, repeatable trigger (operator toggle plus logs): the phone's Wi-Fi time-shares between the hotspot and the car's group.
- The startup freeze happens about 8-9 s after every connect on both channels, which points to phone-side post-connect activity (network validation or a scan after joining) or the car's first scan (UNKNOWN).
- Channel 149 looked better in this short sample. More drives are needed.
- The boot-delay idea doesn't address the startup freeze (it happens on manual starts too). The operator also finds 2 min too long.
