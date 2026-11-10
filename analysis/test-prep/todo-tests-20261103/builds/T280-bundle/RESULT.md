# T280 result (car, 2026-11-09 ~21:34-21:42, parked at home, operator report)

The Start fix worked: Honda Settings opened, then Home, then READY. Collect ran twice (CAR LOGS COPIED, SAFE TO DISCONNECT, KEEP). Music is back with no delay (cushion off).

| Check | Result | Evidence |
|---|---|---|
| No added audio delay | PASS | operator |
| Home 21:35:55 | No freeze | operator |
| Freeze 21:37:38-21:37:46 | Recorded | auto-save 213801 |
| Car reboot, wireless auto-start, freeze ~21:40:23-21:40:50 | Recorded | auto-save 214051 |
| BT audio glitches 21:30-21:32 with wireless AA off | Operator report | not logged |
| Phone shows "Connecting to Android Auto" with wireless off | Operator report | phone-side retry |

## Freeze recorder findings (T280_*)
- **The car's radio interface receives almost nothing during a freeze.** Before a freeze, p2p-wlan0-0 rx is 180-680 packets/s (220-900 KB/s). During it, 0-4 packets/s and 0-5 KB/s, with rxErr=0 and rxDrop=0. The roughly 38 TCP segments/s on both sides are the steady local (loopback) baseline, not phone traffic.
- **The car's own TCP retransmits** 1-2 segments around the start of each freeze (retrans+=2, +1). So car→phone packets go unanswered too: both directions stop at the radio link or the phone.
- **The CPU is not the cause.** During freezes cpuBusy is 15-50% with iowait about 0. TOP_CPU over 4.25 s (21:40:29): tjba.navigation 67 ticks, system_server 52, logd 23, surfaceflinger 20. Nothing dominant. Load is high after boot (12.9 at 21:40:25), but the CPU was idle during the freeze itself. The 21:37 freeze (load 2.9, CPU 20%) had no boot load.
- After the 21:40:31 recovery the link stays weak: 1.2-2.7-s BODY_GAPs until 21:40:50, and VIDEO_FPS fell to 0.5.
- The laptop capture shows no wpa_supplicant/P2P events during the 21:37 freeze. The group is on freq=5180 (ch36).

## Interpretation (INFERENCE, medium confidence)
The phone stops putting AA traffic on the car's 5 GHz link for seconds at a time. The car is idle and waiting. Likely causes are on the phone's radio side:
- off-channel time: multi-channel concurrency with another Wi-Fi network, such as home Wi-Fi in the driveway
- background scans
- Bluetooth/Wi-Fi coexistence

That also fits the BT-only glitches. A startup buffer would not help: the freezes happen with an idle CPU and 18 s to 2 min into the session.

## Next tests (no new build needed)
1. Drive away from home: are freezes rarer than in the driveway?
2. In the driveway, with home Wi-Fi forgotten or auto-connect off on the phone, and Location > Wi-Fi scanning off: do the freezes disappear?

## Boot-specific clue (operator question: why after reboot?)
The T270 laptop capture holds the 20:19 boot of the T260 drive, unfiltered:
- Honda pulls the phonebook over Bluetooth (BluetoothPbapClient /telecom/pb, TEL_VCardImportThread) from 20:20:04, and call history (/telecom/cch) at 20:21:10.
- MAP (messages) registers at 20:20:27, and A2DP+AVRCP connect at 20:20:23.
- The AA Wi-Fi session started at 20:20:12. Music then went silent for 41.9 s (gap ending 20:21:14), followed by repeated stalls until 20:23:13.

The T280 reboot freeze (21:40:23-50, 18 s into the session) fits the same window, but that boot was not captured by the laptop.

The manual-start session was not freeze-free either: the recorder caught 21:37:38-46 (2 short freezes). INFERENCE: Honda's Bluetooth sync after boot makes freezes more likely through BT/Wi-Fi coexistence on the phone, but it is not the only trigger.

Test: on the phone, Bluetooth > car > turn off Contacts and Messages sharing, reboot the car, and compare.
