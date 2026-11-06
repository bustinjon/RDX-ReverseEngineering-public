# Car visit 2026-11-05 evening (T60 bundle, build 7039AA7E…)

Full operator notes and log evidence: `VISIT-NOTES-20261106.md`. Three Start/Collect rounds, each ending SAFE TO DISCONNECT with cleanup verified.

## Results
| Test | Result |
|---|---|
| Start | The first attempt was refused: the readiness check looks for the accessibility service label "RDX USB", and the service had inherited the new app label. Fixed by giving the service its old label; rebuilt; READY |
| Hackura Home tile and app-list entry | PASS: brings a minimized AA back; with no phone it opens Settings. Shows "Hackura" on Home and as the audio source after the restart. The icon is brighter than Honda's tiles (dim it) |
| Volume panel size | Medium preferred: make it the default |
| Absolute touchpad, top-aligned rows | PASS, "works perfectly". Centred was not needed |
| Honda audio source | Listed as "Android Auto"; selecting it shows a blank screen, but the steering-wheel track buttons now work. **Gone after a power-off:** Honda's boot-time probe was refused because the root check read the per-session switch (always off before a session). The fix is to read the saved switch |
| Layout probe 320 / 400 | FAIL: both too large ("low-resolution computer"), split screen remains. Drop it |
| Self-recovery | FAIL/drop: its restart budget counted the operator's own replugs; once exhausted it refused replugs and Hackura taps. The operator sees no value in it |
| P2 Wi-Fi Direct | PASS: group up as owner, removed after 60 s, persistent profile deleted 1/1 |
| P1 Bluetooth listener | The car side works (the AA UUID listener coexists with HandsFreeLink). The phone never connected; likely it was never told that this car supports wireless (P3) |
| Start without laptop (power-off) | FAIL. BOOT_COMPLETED was sent at 21:44:04 but did not start the app; it only started when Honda's media-source scan bound it. Also, accessibility writes throw SecurityException even while WRITE_SECURE_SETTINGS is granted (seen before any power-off too). The Honda warning was not dismissed; USB popups were denied |

## Next build (T70)
- Defaults: Medium volume, audio source on, absolute touchpad on. Root check reads the saved switch.
- Remove: self-recovery, layout probe, "TAP OK" permission overlay. Hackura shows why a launch is refused.
- Dim icon.
- New test switches:
  - side-panel strip scroll (the pad's side-panel strip reports x=1723)
  - track info to Honda (MediaPlaybackStatus service 10 to the media session)
  - wireless announce (P3: Bluetooth service 8 plus Wi-Fi projection)
  - remember this phone (auto-tick "Use by default" on the USB popup)
- Persistent mode: log the full write exception; start the boot path from the media-source bind; Settings "Turn on auto-accept" button.
