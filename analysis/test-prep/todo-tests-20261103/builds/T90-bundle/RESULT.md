# T90 bundle: car results (2026-11-06, about 16:46-16:56)

Collect: SAFE TO DISCONNECT with UNDO. Evidence: runs/helper_20261106T214625_*.

| Item | Result | Notes |
|---|---|---|
| Dongle (Add-Phone kept across Start) | PASS | POLICY_EXTRAS kept 16:46:41. Dongle 2717:ff40 switched to 18d1:2d00; AA sessions 16:48:46-16:49:20 and 16:49:44-16:51:43 |
| Talk button probe | FAIL (dead end) | Honda received PTT_DOWN/LONG_PRESS/PTT_UP at 16:52:12 and 16:52:33, but Hackura got 0 PTT_BROADCAST: the broadcast does not reach third-party apps. Honda gave the hold to com.honda.siri ("not an iOS device"), because stock AA's provider declines when stock AA is not connected |
| Gemini | PASS | Answered this time (the Nov 6 15:50 failure was not reproduced) |
| Strip scroll v3 (T91) | FAIL | 1/3 pane: opens the second playlist. Injected drags are fast (edge reached in about 50 ms at gain 1.5) and re-grabs make a DOWN/MOVE/UP within the same ms |
| Dash refresh (T94) | FAIL | MEDIASRC_DASH_REFRESH every 10 s (16:53:33-16:55:03); no visible effect. Drop |
| "RDX paral..." icon in the AA launcher | ISSUE | This is AA's "exit to car" icon, labelled from our CarInfo.displayName "RDX parallel AA test" (stock sends no displayName, so AA shows the make). Tapping it at 16:55: the phone dropped USB at 16:55:09, with no video-focus request logged; a replug recovered |

Requests: rename or remove the icon; an AA launcher icon that returns to Honda Home.
