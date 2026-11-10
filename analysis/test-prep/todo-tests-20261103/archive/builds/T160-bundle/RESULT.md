# T160 bundle: car results (2026-11-08, operator report, partial; logs pending)

Build A0B9B6C75B77C00BB54DD02B78AE8F43B0B761DC55D6E39FA6807669D9948017. First Start was refused (UNTRACKED_HELPER: the T130 copy was still running from daily drives); Collect-T130 with UNDO cleared it.

| Item | Result | Notes |
|---|---|---|
| Steady cursor (T140) | PASS | "Cursor seems to work better." Keep. |
| Side-strip scroll, large pane (T71 behaviour) | PASS | "Works well with the main screen panel." Keep exactly as it works now. |
| Highlight mode vs absolute touchpad | Absolute preferred | Highlight mode "kind of sucks". Absolute touchpad stays the default (it already is an ON-by-default option). |
| Wireless test (P4) | FAIL to start | Button showed "Wi-Fi Direct refused (2)" = BUSY from the framework. Likely cause to check in the log (P4_START stationWifiOn=): on Android 5.1, WifiP2pService answers BUSY while P2P is disabled, which happens when the head unit's Wi-Fi is off. The Nov 6 P2 probe succeeded. |
| Save logs | PASS | Two saves (10:59, 11:29) pulled with Pull-Hackura-Logs.cmd into headunit-logs-20261108-113200. |
| Wireless test cause (log) | CONFIRMED | 10:58:53 P4_START stationWifiOn=false, then P4_GROUP_CREATE_FAILED reason=2: the head unit's Wi-Fi was off. Retry with Honda Settings > Wi-Fi on. Fix for the next build: stop at once on refusal and show "turn on the head unit's Wi-Fi" (it currently waits out the 30-min window, harmlessly; P4_WINDOW_ENDED 11:28:53). |
| Wireless test retry, Wi-Fi Network mode on (11:34-11:37) | PARTIAL | P4_GROUP_READY 11:34:10 (p2p-wlan0-0, WPA2, owner address, TCP listening); phone sees "DIRECT-…" in its Wi-Fi list. Wired: P4_ANNOUNCE groupReady=true, P4_WIFI_CREDENTIALS_SENT 11:34:54 (real name and password, not blank), P3_PAIRING_REQUEST alreadyPaired=true. After unplugging at 11:35:39: no P4_BT_PHONE_CONNECTED and no TCP. The phone never opened the AA Bluetooth service. Pending: whether Bluetooth off/on was done, and the phone's "Wireless Android Auto" setting. Next candidate: head-unit-initiated Bluetooth trigger (as the open dongles do), reviewed for Honda HFP impact. |
| Wireless test, second retry (12:25-12:36) | NO CONNECTION | Operator: phone Bluetooth off/on before each check; the phone's Wireless Android Auto setting is ON (it uses it with the dongle). Phone listed "DIRECT-…" (new name each run, as expected). 12:35:34 P4_WIFI_CREDENTIALS_SENT again, P3_PAIRING_REQUEST alreadyPaired=true; still no P4_BT_PHONE_CONNECTED. Clean stop at 12:35:12: P4_GROUP_REMOVED, P4_PROFILE_DELETED. The Collect capture.log ends at 11:30, so Honda's own Bluetooth side for these runs isn't in the evidence. Conclusion: the phone accepts the details over USB but never opens our AA Bluetooth service by itself. Next: head-unit-initiated trigger (research first), and whether the service record is visible to the phone at all. |
| Collect | PASS | COLLECT + UNDO, SAFE TO DISCONNECT (runs/helper_20261108T155429…). |
| Drive log 11:29 | OK so far | AA audio, volume display, side panel, Hackura tap; no STUCK_SCREEN, no crash. |
| Boot black screen | not yet tested with T160 | The 10:49 boot ran the old T130 copy (RdxBootBlocker shown 10:49:40-10:49:48). T160 is checked at the power-off step. |
| Full-screen check, stuck screen, power-off/warning, reverse camera | pending | Operator doing a 30-minute drive test next; logs to follow. |
