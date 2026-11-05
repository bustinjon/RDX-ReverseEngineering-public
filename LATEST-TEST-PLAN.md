# Current build, results and to-do list — November 4–5, 2026

## Current build

Original local APK SHA-256 `191E43A65D3935D036382D1671FA3286641732C26C48E453B9427D003A96F48C`. It is the earlier working long-drive build plus seven changes. Each change was car-tested on its own, one at a time, then added to the build:

| Change | Source | What it does | Car result (Nov 4) |
|---|---|---|---|
| Maps navigation focus | `GalReceiver.java` | Replies with the phone's requested focus (1 native / 2 projected) instead of always 1 | Routes stay active; logs show request=2 / reply=2 |
| Navigation voice | `AudioSink.java`, `AaSessionService.java` | (a) Guidance audio already received plays out after the phone's playback-stop, instead of being cleared. (b) When our guidance stream ducks our media stream, that internal duck is not reported to the phone as lost focus. That report made the phone stop and restart each prompt. | Prompts play in full; music ducks and returns. Guidance frames dropped: 181/205 → 11/184 |
| Microphone | `AudioSource.java`, manifest `RECORD_AUDIO` | 16 kHz mono capture with the stock open/pause/send/ack flow. Teardown keeps native objects if capture won't stop. | Assistant via the on-screen mic and the hotword both work, also with the fan on high. This is without the OEM mic-mode switch, which needs a privileged service |
| Console track buttons | `InputEvents.java`, `AaOverlayService.java` | OEM seek keys 138/139 (scan 66/67, source 257) → media 88/87. One pair per short press, holds ≥500 ms ignored, stock 100 ms press/release spacing | One track per press; no double skip with Bluetooth media on or off |
| Day/night | `NightModeWatcher.java`, `SensorSource.java` | Polls the head unit's display-mode service, read-only (`lcd_service` transaction 6, the same call the stock client makes) and reports night mode | Map colours follow the car within ~5 s |
| Home / return to AA | `HomeToggle.java`, `AaOverlayService.java`, `PermissionClickService.java`, accessibility config | Home minimizes AA to the OEM screens while the session and audio keep running; the side-panel button (key 172) brings AA back; holding Back also minimizes. The OEM policy consumes Home for our window type and hands it straight to its own launcher, so Home and the side panel are **observed** by the receiver's accessibility service (key-event filter, never consumed) | Works as intended; the Diagnostics shortcut still works |
| Volume display | `VolumeFeedback.java`, `AaOverlayService.java` | Passive "Volume N" box from Android's `MASTER_VOLUME_CHANGED_ACTION` (no permission; it mirrors the OEM knob). The OEM amplifier broadcast is permission-protected | Follows the knob and wheel volume; visual polish planned |

Also confirmed on Nov 4 with the receiver on screen (plus a ~25 min continuous drive on the current build: no drop-out, zero audio drops, memory flat at about 72 MB):
- **Reverse camera** shows normally, and AA comes back afterwards.
- **Phone calls** work over Bluetooth, including on-screen answer and the wheel call controls.
- **Replugging the phone reconnects AA** without a laptop. Detach and re-attach go through the existing attach-activity path.

The authenticated receiver APK is not distributed (it bundles separately supplied protocol material and a vendor native library).

## Findings that limit what is possible on this head unit

Read-only check of broadcast records, with permissions taken from the records themselves:
- The OEM main-volume broadcast and the vehicle parking-brake and gear-mode broadcasts are sent with receiver permissions held only by signature/system apps. A third-party receiver cannot show the volume level or read those signals.
- **Steering-wheel track and talk buttons** arrive as the OEM vehicle broadcast `autovcs.buttons_pressed` (`RIGHT_FWD` / `LEFT_REW` …), not as key events, and that broadcast requires a signature/system permission. Only console buttons reach the receiver.
- **The head unit fully resets at power-off and comes back with accessibility disabled**, so the receiver's USB-permission auto-clicker is off after every restart. `WRITE_SECURE_SETTINGS` is a development permission on this firmware (grantable once over ADB); an opt-in persistent mode that re-enables only the receiver's own accessibility service at boot is built but not yet car-tested.
- On a long press of the console seek keys, the OEM starts fast-forward on its selected source. With Bluetooth Audio selected, that paused the phone over Bluetooth; with FM selected there is no side effect.
- The OEM talk button goes to the OEM voice service. Use the on-screen mic or the hotword instead.
- The receiver reports the car as parked to the phone. Android Auto therefore keeps parked-mode features while driving; the operator chose to keep this for now.

## To-do

| Item | Status |
|---|---|
| Laptop-free start after power-off | Persistent mode built; car test next |
| OEM "unauthorized app" warning | Narrow fix built: the accessibility service presses only the exact Dismiss button of that one dialog (never "Remove all"); tested together with persistent mode |
| Car GPS to the phone | Built (standard `gps` provider, stock unit conversion); drive test next |
| Absolute touchpad inside AA (option) | Design: the native library exposes touchscreen registration and touch events |
| Steering-wheel buttons | Blocked by OEM permission |
| Spotify compact playback row | Parked; also reported in stock AA |
| Ignition cycle, cold start without laptop, multi-hour drive, update install | Long-run tests still to do |

## Offline checks anyone can run

With PowerShell 7 and JDK 17 on PATH:

```powershell
./tools/car-test/Test-PublicInputPcm.ps1
./tools/car-test/Test-PublicReceiverChanges.ps1
```

The first checks PCM and audio-policy handling plus the current input contract (eight declared keys including media 87/88). The second runs the archived media-candidate checks and the navigation-focus requests. Neither needs credentials or native libraries, and neither touches a device.

## Test method

Each change was a separate APK built from the last passing build. The car runner only accepts an APK whose recorded sources match the live source tree, so each test swaps its source in and restores it on collection. A Diagnostics-menu check runs before every phone handoff. **Plug the phone in only from the Home screen.** On this unit, plugging in while the Diagnostics menu was open left the USB-permission overlay stuck until a restart. Unplugging the phone always ends the session, which is the safety stop.

The [public diagnostic APK](downloads/headunit-diagnostics-0.1.0.apk?raw=true) is unchanged and does not project Android Auto. For another car, start with [START-HERE.md](START-HERE.md) and [PORTING.md](PORTING.md).
