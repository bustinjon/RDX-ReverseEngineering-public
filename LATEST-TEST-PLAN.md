# Current build, results and to-do list — November 4–8, 2026

## Feature-bundle visits (Nov 7–8)

Five more one-install builds. The receiver app is now called Hackura on the head unit.

| Feature | Result |
|---|---|
| Start AA when plugged in while driving | PASS. The OEM's Android refuses every non-OEM activity while the car moves (`ActivityStackSupervisor` → `AutoSSMonitor`), so the USB attach activity never ran. A manifest receiver on the USB-attached broadcast starts the session instead |
| Return to AA while driving | Side-panel press PASS. The app tile and the OEM now-playing card are refused while moving (both open an activity); a dead end |
| Home after a cold start, and from any OEM menu | PASS. The OEM swallows Home for our window type with no broadcast, so only the accessibility key filter sees it. "Start without laptop" never worked because `WRITE_SETTINGS` was missing from the manifest; with it, accessibility comes back after every power-off. While AA runs, Home now opens the OEM home screen itself |
| AA's exit icon | PASS. Labelled "Honda Home"; tapping it asks for native video focus, and the receiver now minimizes to the OEM home screen (before, video stopped and AA looked frozen) |
| Steering-wheel talk button opens Gemini | PASS. The OEM voice provider is exported and reports its state; on a press the receiver takes the voice audio focus, which makes the OEM voice abort itself, then sends the assistant key. A hold opens Gemini too (watching the OEM's other voice provider). Each is a switch |
| Console skip buttons | PASS. A press reached the phone twice (key path and the OEM audio source); duplicates are dropped |
| Startup map smearing | Fixed so far. The first video frames were dropped while the decoder started; it now drains output and retries |
| Day / Night / Auto | PASS. Hold console skip-forward, or Settings |
| Settings | New layout: main page, Buttons (every mapping switchable), Phone & devices (each device enabled/disabled, the main phone included), Developer. No scrolling, large text |
| Side-panel strip scroll | Retired after four versions; the phone ignores the injected drags |
| OEM "Non authorized apps" warning | Cannot be prevented: only system or privileged apps count as authorized, and once any user app has been installed the warning returns at every boot, even after removal. Auto-dismiss (Dismiss only, never "Remove all") under test |
| Wireless dongle | PASS, including reconnecting after a power-off; two hour-long drives stable |

## Feature-bundle visits (Nov 6, afternoon)

Two more one-install builds on the same day.

| Feature | Result |
|---|---|
| OEM audio source | PASS. The receiver's session now lives for the whole AA session, so the OEM selects it automatically when AA starts and the instrument display keeps the track across Home and back. Steering-wheel track buttons work through it |
| Knob and wheel power button | PASS. Pause and resume both reach the phone (the OEM's play/pause session calls are forwarded as media keys) |
| OEM home-screen card | PASS. Shows the receiver's music and navigation |
| Wireless AA dongle | PASS (first wireless session). Any device the operator explicitly added is switched into accessory mode; the phone stays in a pocket. An earlier failure was our tooling: the test runner's Start wiped the added-device list |
| Separate navigation volume | PASS. Guidance plays on the OEM navigation stream (10), so prompts and music have their own volumes as in stock AA. Now on by default |
| Steering-wheel talk button to the phone assistant | Dead end. The OEM's voice service accepts only system apps as voice providers, and the press/hold broadcasts never reached the receiver (0 received while the OEM logged every press). Use the on-screen mic or the hotword |
| Instrument display always showing the track | Dropped. Re-sending the track every 10 s has no visible effect; the display reacts only to a real track change |
| Side-panel strip scroll | Still failing in the narrow pane: the synthetic drags are too fast and open a list item. One more try planned with slow one-to-one drags |
| AA's "exit to car" launcher icon | Tapping it dropped the session. It showed our old test name. Next: use the stock name and return to the OEM home screen |

## Feature-bundle visit (Nov 6)

Next one-install bundle. New defaults: absolute touchpad and the OEM audio source on, Medium volume panel, a dimmer icon. The own Home tile is now the only way back to AA; a short side-panel press is ignored. Self-recovery, the layout probe and the "tap OK" hint are removed.

| Feature | Result |
|---|---|
| **Remember this phone** (the auto-clicker ticks Android's "Use by default" once, only on a popup naming the receiver app) | PASS. No USB popups on later plug-ins. **After a 2-minute power-off, plugging in started AA with no laptop and no popups**, without the persistent mode. The earlier power-off failure is solved this way |
| New defaults | PASS |
| OEM audio source | Works once selected by hand (steering-wheel track buttons work). After Home and back to AA the instrument display shows "No device connected" |
| Track info to the OEM screens (media-status service) | PASS: title/artist reach the OEM screens with the steering-wheel controls. Same "No device connected" after Home and back |
| Maps turn-by-turn to the OEM screens (navigation-status service bridged into the OEM navigation framework) | PASS |
| Side-panel strip scroll | Works when the app is in AA's 2/3 pane, not in the 1/3 pane |
| Phone battery/signal | Already shown via Bluetooth; nothing to build |
| Wireless announce (Bluetooth + Wi-Fi projection services) | No reaction on the phone |
| Wireless AA dongle (wired side added to the allowed list) | Not started: the receiver only switches the phone's vendor into accessory mode, so the dongle was never switched and kept re-enumerating. The phone did see the dongle ("Android Auto is available") |
| After a power-off with the phone remembered | AA starts, but Home and the side-panel long hold do nothing: they are read by the accessibility service, which is off after a restart |
| Opening the Home tile while driving | The OEM blocks it ("not available while driving"); works parked |

## Feature-bundle visits (Nov 5)

Two one-install test builds. Each feature is a switch on an on-car settings screen ("Hackura settings") and applies at the next phone plug-in, so one visit covers many tests.

| Feature | Result |
|---|---|
| New volume panel (rounded, Small/Medium/Large) | PASS. Medium preferred, becomes the default |
| Screen density | Standard best, Smaller kept as an option, Larger dropped |
| Absolute touchpad (finger position = screen position, a press taps under a ring cursor) | First try misaligned. Fixed by measuring touch rows from the top of AA's UI area instead of centring them. The second try "works perfectly" |
| Own Home tile / app-list entry "Hackura" with its own icon | PASS: one tap brings a minimized AA back; with no phone it opens the settings. Replaces the old helper screen |
| OEM audio-source entry | Listed. Selecting it makes the steering-wheel track buttons work. It dropped out of the list after a power-off: the OEM's boot-time probe arrived before any AA session, and the entry wrongly answered "off". Fix: read the saved setting |
| Car GPS to the phone | Forwarding works (fixes about 5 m, no failures) |
| Narrower layout to avoid AA's split screen (320/400 dp) | FAIL, both look too large; dropped. Full-screen Maps/Spotify need another route |
| Self-recovery after a dropped session | Dropped. It counted the driver's own replugs against its restart budget and then refused to start |
| Wi-Fi Direct probe | The head unit can create and remove a Wi-Fi Direct group as owner (wireless AA groundwork) |
| Bluetooth probe on the wireless-AA UUID | The listener coexists with the OEM hands-free profile. The phone never connected, most likely because the car has not yet announced wireless support during a wired session |
| Laptop-free start after power-off | FAIL. The boot broadcast did not start the receiver app, and writing the accessibility setting is refused even with the development permission granted. So the USB popups and the OEM warning return after a restart |


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
- **Steering-wheel track and talk buttons** arrive as the OEM vehicle broadcast `autovcs.buttons_pressed` (`RIGHT_FWD` / `LEFT_REW` …), not as key events, and that broadcast requires a signature/system permission. Track buttons reach the receiver only through the OEM audio source; the talk button does not reach it at all.
- **The head unit fully resets at power-off and comes back with accessibility disabled**, so the receiver's USB-permission auto-clicker is off after every restart. `WRITE_SECURE_SETTINGS` is a development permission on this firmware (grantable once over ADB); an opt-in persistent mode that re-enables only the receiver's own accessibility service at boot was car-tested on Nov 5 and failed. The boot broadcast did not start the app, and the settings write threw a SecurityException even while the permission showed as granted.
- On a long press of the console seek keys, the OEM starts fast-forward on its selected source. With Bluetooth Audio selected, that paused the phone over Bluetooth; with FM selected there is no side effect.
- The OEM talk button goes to the OEM voice service. Use the on-screen mic or the hotword instead.
- The receiver reports the car as parked to the phone. Android Auto therefore keeps parked-mode features while driving; the operator chose to keep this for now.

## To-do

| Item | Status |
|---|---|
| No more USB popups / laptop-free start after power-off | Done via "Remember this phone" (Nov 6) |
| Home and side panel after a restart | Done (Nov 7) |
| Wireless AA dongle | Done (Nov 6–7) |
| OEM audio source | Done (Nov 6) |
| Side-panel strip scroll | Retired (Nov 7) |
| Home tile while driving | Dead end (the OEM refuses all non-OEM activities while moving); the side panel returns to AA |
| AA exit icon returns to the OEM home screen | Done (Nov 7) |
| Add allowed devices from the on-car settings screen | Done (Nov 7–8) |
| Steering-wheel talk button | Done (Nov 8) |
| Steady cursor, auto-dismiss of the OEM warning | Built; car test next |
| Stuck-screen protection, "Save logs" button | Next |
| Clean-install test (uninstall, reinstall as a new user) | Next |
| Full-screen Maps and Spotify instead of AA's split screen | Research |
| Setup tool (owner extracts the protocol files from their own car), user guide | Final step |
| Separate volume for navigation/assistant | Done (Nov 6) |
| Track info and turn-by-turn on the OEM screens | Done (Nov 6) |
| Wireless Android Auto without a dongle | Announcing support during a wired session had no effect; parked |
| Full-screen Maps/Spotify instead of AA's split screen | Open; density change ruled out |
| Extra allowed phones | Built; needs a second phone |
| Steering-wheel track buttons | Done, through the OEM audio source |
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
