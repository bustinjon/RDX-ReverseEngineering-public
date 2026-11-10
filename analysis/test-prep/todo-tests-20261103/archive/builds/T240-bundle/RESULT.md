# T240 result (car, 2026-11-09 19:42-19:47, operator report + Collect log)

Build 14CBCFFA…; Codex-built (T230 + device-mode Off/USB-only ending the active wireless session). First Start: NOT READY (ADB timeout launching the log monitor); Recover-T240-interrupted: RECOVERY COMPLETE; second Start OK. Collect: SAFE TO DISCONNECT, KEEP. Evidence: runs/helper_20261110T004153….

| Check | Result | Notes |
|---|---|---|
| Wireless connects | PASS | ~15 s (19:43); T200_TCP_SESSION_START 19:43:26. |
| Both -> USB only ends wireless | PASS | Operator: dropped immediately. |
| USB connects in USB only | PASS | 19:45 (USB session 19:45:45). |
| Wireless only connects | PASS | Operator: basically immediately (19:46:17). |
| Off ends wireless | PASS | Operator: immediate drop. |
| USB + Wireless reconnects wireless | PASS | Operator: basically immediately. |
| Freeze after returning to AA | FAIL | 19:44:03 OVERLAY_RESTORED via=hackura plus restore-wifi request, then VIDEO_FPS 0.0 (1 frame in 22 s) until ~19:44:25. |
| Audio | 0 dropped in this test | Operator asks to investigate an audio drop (when it happens is not in these logs). |

Operator requests: move the Wireless Android Auto switch to the main Settings page (T250); investigate the freeze and the audio drop.
