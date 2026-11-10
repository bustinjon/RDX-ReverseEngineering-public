# T200 bundle: car results (2026-11-08 23:05-23:12, operator report + logs)

Build 2D88C7599006EC6CDFF13FFC336F041D164C88385DF448C1A2D1446954481918. Collect: SAFE TO DISCONNECT, KEEP. Logs: headunit-logs-*/logcat-now.txt (pulled over ADB with operator authorization) and runs/helper_20261109T040612…. The operator kept the USB port in ADB mode the whole time, and wireless AA still worked: useful for development (laptop stays connected).

| Item | Result | Evidence |
|---|---|---|
| **Native wireless Android Auto** | **PASS** | Wireless test on; no Bluetooth toggle needed. 23:07:10 P4_BT_PHONE_CONNECTED, 23:07:17 P4_TCP_CONNECTED, then P4_TCP_HANDOFF, then T200_TCP_SESSION_START via=phone-wireless, 23:07:20 FIRST FRAME. The session ran until 23:11:49 (9452 frames), ending when the operator turned the test off (ETIMEDOUT after the group was removed). |
| Freezes / "went Home" | FAIL (our bug) | STUCK_SCREEN fired at 23:07:32, 23:09:52 and 23:10:08 (VIDEO_FPS windows 0.2-2.0). Over Wi-Fi the phone sends frames only on change. Fixed in T210: no stuck check for Wi-Fi sessions. |
| Return to AA looks frozen ~5 s | FAIL | After OVERLAY_RESTORED the video resumed only after 5-10 s (fps 0.2/2.0, then catch-up bursts of 38-56 fps). Fixed in T210: request a fresh picture on restore. |
| Phone call 23:09 | Partial | AA stopped ~15 s: the stuck-screen protection minimized AA at 23:09:52 during the call. Calls work (operator). Fixed by the T210 stuck change. |
| Settings bounces back to AA after ~3 s | FAIL | SETTINGS_REFUSED at 3 s while ActivityManager logged "AM_FixUp inhibitTaskStart" (Honda delays the start). Fixed in T210: wait 8 s. |
| Home / side panel / restore | PASS | HOME_KEY minimize and side-panel or Hackura restore all logged. |
