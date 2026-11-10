# To-do (updated 2026-11-10)

## Open
- Calls ringing on the phone instead of the car (T260, once): likely the car's hands-free link was down. T270_HFP_LOST / T270_CALL_STATE logging and auto-save are in place; analyze if it happens again.
- Second-phone test: extra allowed phones and per-device wireless modes.
- Long-run tests: many ignition cycles, multi-hour drive, update install over an existing install.
- Confirm T300_SCANS_RESTORED when wireless stops (T310 checklist).

## Closed 2026-11-10 (operator)
- Wireless freezes: fixed in T300 (car station scans every 10 s -> 5 min, channel 149). T310 makes it the default.
- Focus glitch on return to AA (inherited review item): considered fixed.
- Home + side panel + Back chord pops AA back: accepted (the side panel is mapped to AA).
- Full-screen Maps/Spotify instead of AA's split screen: dropped (Honda's hard-coded 1280x688).
- Spotify compact row (reachable with the cursor) and VLC/NewPipe popup video (other AA apps cover it): dropped.
- Rename to FS-AA: dropped; the app stays **Hackura**.
- Phone's "Connecting to Android Auto" while wireless is off: no car-side fix. Hackura already closes its Bluetooth listener and does not announce wireless over USB; the phone retries from its own memory of the car. Phone-side workaround only.

## For the final package (when done)
- Installer with uninstall / restore-stock (not a Settings button), and a clean-install test.
- Setup tool (each owner extracts the protocol material from their own car) and a user guide.
- Release notes: wireless AA starts with the car and pauses the head unit's own Wi-Fi (turn Wireless Android Auto off if the car needs Wi-Fi); the phone hotspot may cause freezes; reverse camera and calls work (operator daily use).
