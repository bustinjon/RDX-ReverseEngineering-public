# T270 result (car, 2026-11-09 ~20:36-20:42, operator report) - PARTIAL, head-unit auto-saves not pulled yet

Start: the first two tries were refused (Home focus lost after the force-stop, same as T230). The manual fix (open a Honda app, then Home) worked on the third try. Collect: two tries failed with "Command failed: shell", and the third gave SAFE TO DISCONNECT, KEEP.

Capture (runs/helper_20261110T013616…) ends at **20:37:38-39**. That is the car's shutdown sequence:
- Honda Home starts.
- The P2P group is removed and wpa_supplicant terminates.
- The Bluetooth VM exits.
- `Force stopping com.rdx.fullscreen.usbhelper … from pid 1729`.
- redbend dies.

At Collect, system_server has a new pid (2302 → 2307), so the head unit restarted between the drive and Collect. None of the operator's drop times (20:38:38 onward) are in the laptop capture. The capture's logcat dump also picked up the earlier T260 daily drive (20:21-20:26), which the T260 capture missed.

| Check | Result | Evidence |
|---|---|---|
| Short blips 20:38:38-50 | Not logged (after shutdown) | Operator report |
| Freeze on Home 20:39:15 → 20:39:35 | Not logged | Operator report |
| Freeze on Home 20:39:55 → 20:40:18 | Not logged | Operator report. Starts about 20 s after the previous freeze ended, which is exactly when a T270 AutoSave (`logcat -d`) would run. HYPOTHESIS, check against the auto-save file names. |
| Freeze on Home 20:40:22 → 20:40:40 | Not logged | Operator report |
| Freeze 20:41:03 → 20:41:40 (song change) | Not logged | Operator report |
| Audio latency | **Regressed**: ~3 s behind | Expected from the 1.5-s cushion plus the 0.5-s AudioTrack buffer. The cushion did not stop the short blips. |
| Collect freezes AA | Operator observation | Collect runs `logcat -d`, dumpsys and an APK pull on the head unit. Heavy system work coinciding with stalls. |
| Wireless toggle off/on in Settings 20:37:26-28 | Group create refused (busy, reason=2), retry in 30 s | capture.log |

## T260 drive (20:21-20:26), recovered from this capture
- Every T250_READ_GAP is `hidden=true` (Honda Home in front), 0.7-2.8 s.
- Music arrives in bursts every ~2.1-2.7 s (T250_PCM_GAP, queued=0) for minutes while hidden. This is a periodic pattern, not single drops.
- 20:25:45 phone reset the TCP connection (ECONNRESET). The session reconnected 20:25:58.

## Next
1. Pull the head-unit auto-saves (Pull-Hackura-Logs.cmd). The file names give the exact save times, which tests the AutoSave-causes-freeze hypothesis.
2. T280 candidates:
   - Remove the cushion, or cut it to about 0.3 s.
   - Make AutoSave light: filtered tags, last N lines, low priority, or off while driving.

## Head-unit auto-save (pulled 21:33, T280-bundle/headunit-logs-20261109-213337)
Only one auto-save: `hackura-20261109-203935-auto-stall-body-3023ms.txt`, requested at 20:39:15 and written 20:39:35. That rules out the "save caused the 20:39:55 freeze" hypothesis, because the save ran 20 s earlier.

App logcat on 5.1 holds only Hackura's own lines (no READ_LOGS), so auto-saves cannot show other processes. T280's /proc FreezeRecorder does not depend on logcat.

- 20:38:38: T250_PCM_GAP 815 ms and T270_INCOMING_SLOW 819 ms. The receiver itself was slow once, which explains one short blip.
- 20:39:10.1: a READ_GAP of 2831 ms **started before** the Home press at 20:39:12.2, so Home is not the trigger.
- 20:39:13-20:39:34: a run of **T270_BODY_GAP 1.8-3.0 s on 8231-byte frames**, about one frame every 2.1-2.7 s. Data trickles mid-frame rather than stopping. That is consistent with heavy packet loss and TCP retransmit backoff on the phone→car radio link. INFERENCE: the loss itself is not measured yet.
- The cushion could not help: the queue kept running dry (PREBUFFERED queuedMs=42-85 after the 2.5-s wait).
- VIDEO_FPS 11.8 at 20:39:08.

The group is on 5 GHz (freq=5180 in most past captures).

The operator reports **Bluetooth audio glitches 21:30-21:32 with wireless AA disabled**. That points toward the radio environment, the phone, or the car's Wi-Fi/BT chip rather than Hackura's stream handling (UNCONFIRMED).
