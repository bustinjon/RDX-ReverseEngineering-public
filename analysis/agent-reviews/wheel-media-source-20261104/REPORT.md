# Steering-wheel track buttons / receiver as a Honda audio source — research, 2026-11-04 (Claude)

Static evidence only; no device action.

## Findings

| # | Finding | Label | Evidence |
|---|---|---|---|
| 1 | Wheel Next/Previous arrive as the broadcast `com.honda.auto.autovcs.buttons_pressed` with `SteeringWheelCommands` (`RIGHT_FWD`, `LEFT_REW`, `NO_BUTTON_PRESSED` on release), not as key events | CONFIRMED (car log) | B-current-baseline run, 16:51:25–16:51:48, SystemUI VolumeManager log lines |
| 2 | Stock AA reads that broadcast only for `PICK_UP`; SystemUI VolumeManager reads it only for `VOL_UP/VOL_DOWN` | CONFIRMED | `AndroidAuto-current/.../ui/ProjectionActivity.java:323-325`; `SystemUI/.../VolumeManager.java:212-226` |
| 3 | No decompiled framework/SystemUI component maps `RIGHT_FWD/LEFT_REW` to media; each OEM source app probably handles them itself when it is the active source. With FM selected while AA played, the dash showed "function unavailable" | SUPPORTED | `RIGHT_FWD` appears only in Diagnostics and the enum |
| 4 | Honda discovers audio sources as **any** service handling `android.media.browse.MediaBrowserService`; no system/signature filter | CONFIRMED | `HondaManager/.../msm/MediaSourceManager.java:90-105` (`queryIntentServices`) |
| 5 | The 13-entry component list in SystemUI only orders sources; unknown components are logged and sorted last (no crash) | CONFIRMED | `SystemUI/.../HondaAudioSourcesManager.java:18-36,63-77` |
| 6 | Stock AA is itself one of these sources (`GalMediaSessionService`, index 12) | CONFIRMED | same file, line 75 |
| 7 | The MSS service API is gated by `auto.permission.MSS_API_TEST` or a system app, but discovery and user selection go through SystemUI, not through our call | SUPPORTED | `Services/.../mss/MediaSourceService.java:170-193` |
| 8 | Whether our app could receive `buttons_pressed` is UNKNOWN. The same autovcs family (parking_brake, transmission_mode) requires `AUTOMOTIVE_VCS_SERVICE` | UNKNOWN | signal checks 2026-11-04; `buttons_pressed` was added to Check-Signals |

## What a receiver media source could give

- Our app listed as a Honda audio source; when selected, console seek/hold would target us instead of FM/Bluetooth Audio, avoiding the hold side effects and the "function unavailable" mismatch.
- Possibly the Honda media card and B-zone showing AA track info, if metadata is published.
- Wheel track buttons **only if** `buttons_pressed` is receivable, or if the selected-source path routes them (finding 3 says it does not, centrally).

## Next steps

1. Signal check, ADB only: confirm the `buttons_pressed` requiredPermission.
2. If it is receivable, or as a standalone improvement: build T23 = a minimal MediaBrowserService plus MediaSession in the helper whose transport controls (next/previous/play/pause) are forwarded to the phone as media keys through the existing input path. One change, car-tested on its own. Also check that selecting it does not stop AA audio. Honda audio arbitration when a source is selected is UNKNOWN.
