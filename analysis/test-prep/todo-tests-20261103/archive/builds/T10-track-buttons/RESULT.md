# T10 track buttons — 2026-11-04 (build 1DFE0A24…, on T11 baseline)

- Console Next/Previous: PASS. Each short press gave exactly one INPUT_MEDIA_KEY pair (138->88, 139->87; source=257 device=1). No double skip with BT Media audio on or off.
- Hold: correctly not sent by us (INPUT_MEDIA_NOT_SENT heldMs=3493/3302). The pause after a hold comes from Honda: SeekKeyHandler "Starting FF mode" on the selected Honda source com.honda.tjba.btaudio (Bluetooth audio), then AA media playback stopped. Not caused by the receiver. Possible mitigation: select a non-Bluetooth Honda audio source while using AA.
- Steering wheel (16:33:00, ~16:35): FAIL / not reachable. No key event reached the overlay and SeekKeyHandler logged nothing. The wheel arrives as com.honda.auto.autovcs.buttons_pressed (stock AA reads it only for PICK_UP; SystemUI VolumeManager reads VOL_UP/DOWN). The autovcs family requires AUTOMOTIVE_VCS_SERVICE (signal check). buttons_pressed has been added to Check-Signals to confirm.
- **PASS for console buttons. Promoted to the baseline.** Wheel track buttons parked: the only plausible route is registering as a Honda media source (research).
