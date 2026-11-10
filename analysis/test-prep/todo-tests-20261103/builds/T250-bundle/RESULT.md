# T250 result (car, 2026-11-09 ~20:05-20:15, operator report + live ADB capture)

Collect: SAFE TO DISCONNECT, KEEP. Live capture (operator-authorized): live-20261109-201311 (screenshot of the Developer page plus full logcat).

| Check | Result | Evidence |
|---|---|---|
| Wireless switch on the main page | Done | Operator used it. |
| Audio pause after going Home | FAIL | 20:09:03 OVERLAY_MINIMIZED + T250_VIDEO_FOCUS native; 20:09:04 T250_READ_GAP 2497 ms; T250_PCM_GAP every 2-5 s (queued=0) plus AudioTrack underruns until ~20:09:30. The operator heard 20:09:10-20:09:28. Later minimizes had no gaps. Cause UNKNOWN (phone/BT side suspected; FM 100.7 was set on the panel at 20:09:02). Codex: CODEX-STALL.md. |
| Visual flash when returning | FAIL (T250 change) | The NATIVE-on-minimize focus change makes the phone redraw; it did not prevent the stall. Reverted in T260. |
| Home back and forth | OK | Operator: seems OK. |
| Audio blip ~20:10:45 | noted | |
| Developer page | Small buttons, empty space | Screenshot: 17 items in 2 columns. T260 uses 3 columns. |

Operator requests: remove "(test)" from "Talk button hold: Gemini"; bigger Developer buttons (T260).
