# Current build, next test and to-do list — November 3, 2026

## Which build is which

| Build | Original local APK SHA-256 | Status |
|---|---|---|
| Working long-drive build | `D1A29B34812B2C3188C57C840DB1DE4F44E1362FF8BD8E3D9A52B1317EDABCE4` | Used for real driving: full-width picture, touchpad movement/select and audio work, with the limits in [current findings](CURRENT-FINDINGS.md) |
| Maps-only build (current source) | `21037DC393FCD162499589254D745DD0904A326BD7E5A33D69CF3FC69BFA4084` | Exactly one method differs from the working build: the navigation-focus reply. Installed and passed the Diagnostics checks; **Maps route outcome not yet tested** |
| Combined media/volume/profile build | `A2F4785466AD41E2459051A096B917881349EC2B64E06303D19F66DA38D4FB0F` | **Rolled back.** Installed around a Diagnostics-menu failure; its new features never got a meaningful car evaluation. Source archived under [saved-media-source](analysis/test-prep/diagnostic-rollback-20261031/saved-media-source/) for later one-at-a-time reintroduction |

Authenticated receiver APKs are not distributed (they bundle separately supplied protocol material and a vendor native library). Sanitized public builds need not reproduce these container hashes.

## Navigation-focus change (in current source)

The old callback always replied native focus (1), so a phone request for projected focus (2) could never be honored. The current callback logs the request, rejects anything other than 1 or 2, and echoes a valid request. This is a confirmed contract defect; whether it caused the observed ~30-second route cancellation is not yet known.

## Next car session (parked first, no new code)

Safety items come before more driving with the receiver on screen.

1. **Reverse camera (parked, parking brake on, foot on brake, observer with camera).** Stock baseline first with the receiver not running. Then with the receiver showing Android Auto: shift to R, check the whole camera picture and guidelines are visible with nothing drawn over them, return to P, check Android Auto and the touchpad recover. HOME is ignored by the head unit while the camera is active, so the stop method is **unplugging the phone**, which the operator has confirmed always ends the session. If the camera is blocked even partly, stop using the receiver while driving until fixed.
2. **Phone call (parked).** Incoming and outgoing: ringtone, whether any answer/decline prompt is visible (the OEM call card sits in a status-bar window that our overlay covers), answering with the wheel button, audio both directions, and whether media audio returns afterward.
3. **Talk button.** One press; existing raw-key logging shows whether anything reaches the receiver window (expected: nothing, because the OEM voice service handles it).
4. **Volume broadcast record.** Capture the full broadcast record for the OEM amplifier volume action while turning volume, including any required permission. Decides whether a volume indicator is possible.
5. **Maps route test.** Two routes, each active at least 90 seconds, no media app experiments in the same run, with navigation-focus request/reply logs.

## To-do list after that (one change per car test)

| Order | Item | What we know | What it takes |
|---|---|---|---|
| 1 | Reconnect without the laptop | Unplug/replug within one helper run never starts a second session: detach only logs, polling stops forever after permission is granted, session stop never notifies the helper | Needs a reviewed design first: session generation and device identity, one shutdown per detach, wait for cleanup before a new session, ignore stale callbacks, tell accessory re-enumeration apart from real unplug, explicit stop stays stopped |
| 2 | Track buttons (Next/Previous) | Raw OEM keys 138/139 reach the overlay; the OEM framework also broadcasts them to its own media switcher (privileged receiver) and still delivers them to the focused window | Reintroduce only the archived key adapter. Test each physical control separately (wheel vs console not yet proven), short and held presses (stock starts seeking after 500 ms), with phone Bluetooth media audio off and on to catch a double skip |
| 3 | Microphone / voice | Stock capture is a standard 16 kHz mono recorder, but stock first switches the car's mic mode through a privileged OEM service we cannot call. The talk button goes to a privileged OEM voice provider | Experiment only: add record permission and the stock open/pause/ack flow; start voice from the phone side (on-screen mic or hotword). Outcome unknown (noise/echo processing may stay on, or capture may fail) |
| 4 | Volume indicator | The OEM volume dialog sits below our overlay. Moving our window lower would put the OEM status bar (right-hand 581 px) over the picture, so that option is dropped | Depends on step 4 of the next session: if the volume broadcast is readable, reintroduce only the archived passive indicator |
| 5 | Laptop-free start | The helper is not started at boot; a USB-attach activity exists but launching it under the OEM launcher is unproven | After reconnect works: ignition off/on observation, then a separate cold-boot observation |
| — | Spotify compact playback row | The same failure was reported in stock Android Auto on this car, so a shared phone/media-card focus issue is now the leading explanation | Parked. Next useful comparison: another media app in stock Android Auto from a fresh start, receiver services stopped |

Plan detail, evidence and the adversarial review: [to-do plan](analysis/agent-reviews/todo-plan-20261102/PLAN.md), [review of the plan](analysis/agent-reviews/todo-plan-20261102/CODEX-ATTACK.md).

## Offline checks anyone can run

With PowerShell 7 and JDK 17 on PATH:

```powershell
./tools/car-test/Test-PublicInputPcm.ps1
./tools/car-test/Test-PublicReceiverChanges.ps1
```

The first checks PCM/audio-policy handling and the input contract. The second runs the media/input/volume checks against the **archived** media candidate source and the navigation-focus requests against the **current** receiver source, using a fixture that replaces only the native reply endpoint. Neither needs receiver credentials/native libraries or performs device actions.

## Available APK

The [public diagnostic APK](downloads/headunit-diagnostics-0.1.0.apk?raw=true) is unchanged. It tests local display/input/audio and does not project Android Auto. Start with [START-HERE.md](START-HERE.md) and [PORTING.md](PORTING.md) for another car; original target-specific preparers are not a portable installation flow.
