# T300 result (car, 2026-11-10 ~12:00-12:31, operator report + head-unit log)

Collect: CAR LOGS COPIED (headunit-logs-20261110-123156), SAFE TO DISCONNECT, KEEP. The operator will run T300 daily.

| Check | Result | Evidence |
|---|---|---|
| Parked A/B (scans normal / reduced) | Both fine (operator) | Not in the saved log (an earlier boot, and no stall triggered an auto-save) |
| 30-s boot wait (fixed) | PASS | 12:18:05 T290_BOOT_DELAY waiting 13 s (uptime 16 s), 12:18:19 "over: starting" |
| Channel 149 default | PASS | 12:18:19 P4_5GHZ_REQUEST accepted (operating channel 149) |
| Fewer car Wi-Fi scans | **WORKS live** | 12:18:19 T300_SCANS_QUIETED 3/3 (all three keys previously unset). The car's SCAN_RESULTS went from every 10 s (T290) to **exactly every 5 min**: 12:18:29, 12:23:29, 12:28:29 |
| Freezes | **None** | 12:18:28-12:29:54 (11.5 min session): no T280_FREEZE, no READ_GAP, no auto-save |
| Phone hotspot on at 12:31 | No interruption (operator) | After the log save, so not logged. One trial only. The T290 hotspot test on ch149 with normal scans froze every ~2 s |

## Interpretation (likely, needs more drives)
- The car's 10-s station scans while wireless AA runs were a major freeze source. Reducing them removed the freezes in this session, and apparently the hotspot effect too.
- Next: run T300 daily. If drives stay clean, make "Fewer car Wi-Fi scans" ON by default (the restore at stop and boot is already in place). Confirm that T300_SCANS_RESTORED appears when wireless stops.

## Daily use 12:29-15:38 (Collect 15:38, headunit-logs-20261110-153805)
No new auto-save after 12:29, so no stall of 3 s or more happened while wireless AA ran. Operator: "everything is working". The 30-s boot wait was turned off by the operator at 11:52 (SETTINGS_FEATURE f_wireless_boot_delay=false). T300_SCANS_RESTORED has not been seen yet: no stop was captured.
