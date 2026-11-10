# T160 reconciliation (Claude, 2026-11-08)

Build: T160-bundle CA307734A62D880F836AEEBE2BE867E51D75E57B0AA3E26C978D4504E7F660F3, PASS 203 bundle checks plus feature suites.

## Codex review (CODEX-T160.md, NOT READY)
- 1 BLOCKER "teardown drops the final strip UP": REJECTED as a blocker. It only happens at session shutdown (AaSessionService:1152-1155: running=false, transport.close(), then overlay STOP). The AA connection to the phone ends with that transport, and the next session starts a fresh input channel, so a held touch on a closed session has no effect. The same order applies to every absolute-touch press since T33 and to T71 at the car, with no stuck-touch report. Minimize (the session continues) releases correctly (Codex: OK). Not changed.
- 2-4 OK: pane cutoff 1190 px sits between the T80 anchors 1177 (large pane) and 1870 (1/3 pane); the boot switch defaults off with no dependents; both Settings pages fit.

## Boot black screen (Claude, offline)
- Origin: v6b era (commit ff64ca8, 2026-10-28). It draws a black TYPE_SYSTEM_ERROR window, FLAG_NOT_TOUCHABLE, from boot+8 s to boot+16 s.
- Still runs at every boot: RdxBootBlocker shown/removed on 11-07 23:04, 11-08 00:23 and 01:13 (runs/*/preparation-capture.log).
- Timing in the 01:13 boot: detector starts on BOOT_COMPLETED at 01:13:33.3; its full scan runs 10 s later (CODEX-DETECTOR.md); black screen 01:13:42.8 to 01:13:51.0. So it covers the first ~8 s of the warning, then reveals it. Taps pass through to the hidden warning (risk of a blind "Remove all").
- The rear camera at start-up is rendered by Honda's early_camera/NativeCameraService; whether an Android TYPE_SYSTEM_ERROR window covers it is UNKNOWN.
- Decision: off by default in T160 (Developer > "Black screen at boot (old)"); auto-dismiss does the job.

## Wireless (CODEX-WIRELESS.md), verified
- T70 log (helper_20261106T161644, capture.log:5021-5101): P3 registered the AA Bluetooth and Wi-Fi services in the wired session; 0.7 s later the phone asked for the car's Wi-Fi credentials; T70 code (AaSessionService.java:587) deliberately answered with an empty network. CONFIRMED.
- P1 RFCOMM listen with the AA UUID succeeded locally (capture.log:5239); no phone connection was seen.
- Wi-Fi Direct group creation worked earlier (P2LOG), but no IPv4 address was read; T150 lacks the INTERNET permission needed for TCP.

## Wireless test P4 (added 2026-11-08 at the user's request)
- Review CODEX-T160-P4.md (NOT READY): 4 blockers + 6 should-fix, all fixed. Recheck CODEX-T160-P4-RECHECK.md: BSSID, callback blocking, group ownership and status parsing confirmed FIXED.
- Recheck then found: a parser loop on a negative length (real, FIXED, host test added); a TCP accept/shutdown race and a tcpReady race (FIXED); the profile name missing on an early stop (FIXED: the group name is read before removal); registration exceptions logged with messages (FIXED: class names only).
- Accepted, not changed: the band can't be set or read through the API-22 createGroup (the phone's reply, if any, will show a band refusal as status -8 in P4_BT_RECEIVED numbers=); the /24 subnet check matches Android's fixed Wi-Fi Direct owner network (192.168.49.x).
- Loop stopped here (Claude): only items the API can't control remain.
- Final build: T160-bundle A0B9B6C75B77C00BB54DD02B78AE8F43B0B761DC55D6E39FA6807669D9948017, PASS 215 bundle checks plus feature suites.
