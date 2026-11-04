# B-current-baseline (T13 build F8C1EF5C…) — T10 retest, 2026-11-04

- Honda source set to FM before AA started; AA auto-started its own music (Spotify) over it.
- Console Next/Previous: PASS (one track per press). Long press: no pause any more (Honda's FF mode now targets FM, not Bluetooth audio).
- Steering wheel 16:51:20-16:52: no effect on AA; dash showed "system error / function unavailable". Logs: SystemUI VolumeManager receives com.honda.auto.autovcs.buttons_pressed [RIGHT_FWD]/[LEFT_REW]/[NO_BUTTON_PRESSED]. The wheel is routed by Honda to its selected source; it never reaches the receiver.
- New issue: once Home is pressed, there is no way back to our AA (T08 effectively FAIL).
- New observation: AA starts music automatically on connect (a phone-side Android Auto setting, "Start music automatically").
