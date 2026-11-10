# T190 bundle: car results (2026-11-08 night, operator report + live ADB capture)

Build A9AC31E7B858B06CD1010361A8E710247B5FB80D5E8EF44508AD617E46B2CF6D. Start auto-stop worked. Collect: SAFE TO DISCONNECT, daily features KEPT. Live capture (operator-authorized ADB while AA ran over Wi-Fi): live-wifi-aa-20261108-224900/ (screenshot, logcat, wifi/p2p/bt dumps, top). Private: contains network names; don't publish.

| Item | Result | Evidence |
|---|---|---|
| Re-pair with the test running (Quiet + 5 GHz), 22:32 | **PASS: wireless bootstrap works** | Operator re-paired, and also turned on "Wireless Tethering" in the car's Wi-Fi settings. From 22:33:07 the phone repeatedly ran the full exchange: P4_BT_PHONE_CONNECTED, type 1 sent, type 2 received, type 3 sent, phone type 7 status 0 and type 6 status 0, then P4_TCP_CONNECTED fromGroupNetwork=true (10+ times). The phone shows "Connecting to Android Auto", joined DIRECT-…; the AA app now lists "Honda – Wireless Android Auto available". |
| Why no picture over the native path | Expected (probe) | P4_TCP_FIRST_BYTES count=0: the phone waits for the head unit to start the AA protocol; the probe waited 5 s and closed, so the phone retried. T200 hands the accepted socket to the AA session. |
| Honda reconnect (T210) | Not needed | Step 3 passed. Calls still worked. |
| AA over Wi-Fi via the phone head-unit server (T200 test path), 22:44 | **PASS** | SETTINGS_T200 found=true via=phone hotspot; T200_TCP_CONNECTED 22:44:46.58; FIRST FRAME 22:44:49.94. Screenshot 22:49: full-screen AA (Maps, Spotify, rail) over Wi-Fi. Stopping the server kept the running session (expected). |
| Session quality over Wi-Fi | Same as USB | VIDEO_FPS 10.6-12.1; audio 9500 packets, 0 dropped; 475 GAL pings; Wi-Fi RSSI -21 dBm, 65 Mbps (2.4 GHz phone hotspot); Hackura 8% CPU. |
| Settings kept across update | (operator didn't report a problem) | |

**Conclusion:** wireless Android Auto without a dongle is proven in both halves on this car: the phone completes the native Bluetooth/Wi-Fi hand-off after a fresh pairing, and a Hackura AA session runs over TCP. T200 joins them.
