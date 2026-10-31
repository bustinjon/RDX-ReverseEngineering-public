# Focus observer A — correlate key requests, phone feedback and AA image

Private APK: `analysis/parallel-aa-receiver/usb-helper/build/20261030-204702-954/rdx-usb-helper-v6h-focus-observer-a.apk`

SHA-256: `853991C05DEF75FAF3EA592D26389968F455229D6F9EFBC02E13D824FDC91BF5`.

This is an observability build, **not a new navigation fix**. It keeps directional-focus A's explicit arrow/keys-only input policy, video/geometry/audio/native library unchanged. It requests protocol SELECT/FOCUS_CHANGE feedback and optionally samples its own AA TextureView. Feedback registration changes advertised feedback capabilities; complete wire negotiation is not claimed byte-identical.

The user explicitly approved up to 12 private, low-resolution AA screen captures in this conversation. Do not upload these PNGs or raw logs to GitHub or send them to anyone. Images can contain visible song titles or other AA content. Use the agreed Spotify test screens.

## Capture bounds and control

- Default OFF. Explicit `aa.overlay.CAPTURE_ARM_ONCE` applies only to the next VIDEO session in the same process and is rejected if an overlay already exists.
- At most 12 capture attempts; 960x360 PNG; minimum ten seconds between attempts; maximum 120 seconds after first texture update. One bitmap/write can be outstanding. Bitmap readback occurs on UI thread, PNG encoding on one worker. Readback duration logged.
- Capture errors disable/skip image evidence without intentionally stopping the AA session. Storage/bitmap behavior is hardware-unverified.
- App-specific external-files directory `focus-captures/session_<uptime>` is logged by FOCUS_CAPTURE_SESSION. No storage/network permission added and no upload implemented. This is a distribution privacy rule, not a claim that old Android external storage is inaccessible to every other privileged app.
- Overlay removal closes the capture budget, stops ticks and shuts down the writer. A force-stop can interrupt a PNG write; use saved markers/hash/viewability to establish complete evidence.

## Operator preparation

1. Wait for explicit readiness with ADB connected, normal Honda Home visible, phone unplugged. Qualify target/current framework getter and stable Home/INACTIVE lock-task normally.
2. Run the established CurrentSource/PhonePreference preparation with this APK/hash and a **new 180-second watchdog**. The previous two-minute run showed phone detection only six seconds before expiry; do not extend an already active deadline.
3. Before giving the final READY cue, explicitly arm the next capture session using the existing targeted shell path:

   `am startservice -a aa.overlay.CAPTURE_ARM_ONCE -n com.rdx.fullscreen.usbhelper/.AaOverlayService`

   Confirm FOCUS_CAPTURE_ARMED_ONCE after this run's unique RDX.PREP marker and no active-overlay rejection. Do not invoke VIDEO or start protocol here. The normal phone handoff will start it. If phone activity occurred prematurely or the arm failed, clean up and prepare a separate attempt.
4. Recheck current watchdog time and active capture/helper state, announce actual remaining time. Capture arming does not prove captures will succeed.

Offline artifact plan: `analysis/test-prep/runs/helper_20261031T004920_12e9e5cebe7040a6aebdaf281087c62c/artifact-plan.json`. No device commands have been run for this preparation.

## Full READY instructions

Only send after runner readiness plus confirmed one-session capture arm. Include actual remaining time.

> READY—about [actual seconds] remain. This test will privately save up to 12 small AA-screen images, as you approved.
>
> 1. Switch USB from the laptop to phone/Android Auto mode, return to Honda Home, and connect the OnePlus.
> 2. Open the same layout with Spotify on the right. Stay on the agreed test screens while recording; do not type private information. Keep volume and Bluetooth Media audio unchanged.
> 3. Move to the area where Up previously failed. Make one deliberate Up swipe, lift your finger, and stop touching the pad for about 12 seconds. Note which item was selected before and afterward.
> 4. Try one Down swipe and wait about 12 seconds again. Tell me whether the selection changes or stays trapped.
> 5. Use Android Auto's Back/app controls to leave and return to Spotify. Try Up once more and pause for about 12 seconds. Do not use the car's HOME button for this comparison.
> 6. Pause music, unplug the phone and reconnect the laptop to ADB. Report the selected item and result for each step. Wait for me to collect logs/images and verify cleanup before disconnecting from the car.
>
> If the deadline ends first, tell me which checks completed. If nothing responds, stop repeated gestures and let the image capture record the state.

## Evidence collection and interpretation

- Pull the full remote run capture and watchdog/cleanup files; verify the original accessibility state and owned helper/capture/watchdog processes. If returned before deadline, run reviewed existing cleanup and stop only the identity-matched owned sleeping watchdog so it cannot terminate a later attempt.
- Parse this run's FOCUS_CAPTURE_SESSION path. Pull **only that session directory** into the run's `private-focus-captures/` folder. Do not read credential directories or unrelated app/phone data. If storage is denied, record UNKNOWN; do not change permissions or bypass access.
- Collect images before another APK install/uninstall or any source experiment. Hash every file and visually inspect complete PNGs. Source snapshots can differ from final compositor output and do not show native overlays; use them for AA content/focus correlation only.
- Correlate capture uptime, last-key ordinal/raw/mapped/direction with native key returns and INPUT_FEEDBACK. Event 1=SELECT, 2=FOCUS_CHANGE per matching stock enum. A feedback event is positive evidence of that reported event; it does not identify a control. Absence is UNKNOWN, not proof the phone ignored the key.
- A clear unchanged visible selection plus key submission and no/positive feedback narrows the focus problem; report exact observed combinations without inferring a root cause. Native result zero alone is not target activation.
- Record capture overhead and decoder drops; image sampling may perturb timing. An initial successful action still does not prove repeatable panel return.

## Candidate comparison finding retained for later

Current matched stock HMIPresenter.getDeviceKeyCodes (line 743) does not list DPAD 19..22, whereas our candidates advertise them. GalIntegration additionally advertises page/move keys. That is another protocol-contract difference, not proof of the current failure. Do not change key advertisement simultaneously with this observer experiment.
