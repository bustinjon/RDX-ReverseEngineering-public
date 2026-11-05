# B-current-baseline (T13 build F8C1EF5C…) — T10 retest, 2026-11-04

- Honda source set to FM before AA started; AA auto-started its own music (Spotify) over it.
- Console Next/Previous: PASS (one track per press). Long press: no pause any more (Honda's FF mode now targets FM, not Bluetooth audio).
- Steering wheel 16:51:20-16:52: no effect on AA; dash showed "system error / function unavailable". Logs: SystemUI VolumeManager receives com.honda.auto.autovcs.buttons_pressed [RIGHT_FWD]/[LEFT_REW]/[NO_BUTTON_PRESSED]. The wheel is routed by Honda to its selected source; it never reaches the receiver.
- New issue: once Home is pressed, there is no way back to our AA (T08 effectively FAIL).
- New observation: AA starts music automatically on connect (a phone-side Android Auto setting, "Start music automatically").

# Long drive — 2026-11-04 (build 191E43A6…, current baseline)
- First attempt: Start stopped after READY because of a runner bug (strict-mode lookup of the new optional hook keys); fixed, collected, restarted.
- About a 30 min drive. One continuous AA session 18:32:12–18:57:39 (~25.5 min), ended only by the operator's unplug. No drop-out, no reconnect needed.
- Audio: media received=35679 dropped=0; guidance received=708 dropped=0; 16 guidance drains; no playback failures or incomplete writes.
- Maps focus request/reply ×2 (projected). No crash (AndroidRuntime lines are only setup shell commands).
- Memory: VmRSS 50 MB before the session, about 72 MB from session start, flat 71.9–73.2 MB for 25 min, so no leak.
- Collected, cleanup verified. T19 (multi-hour) still open; this is the first sustained-drive pass.
