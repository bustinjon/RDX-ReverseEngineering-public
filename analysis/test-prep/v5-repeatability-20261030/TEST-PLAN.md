# V5 repeatability, input and Home test

Preparation only. No device command has been run for this plan. Use the known-working **private v5 receiver**, not the public diagnostic APK. No new receiver build or milestone transition.

APK: `analysis/parallel-aa-receiver/usb-helper/build/20261030-185210-531/rdx-usb-helper-v6h-pad-select-v5.apk`

SHA-256: `98E6A0015F249960B7730F210FAFB46BDFDAFE7A31686478FD619A930C3831A4`.

## Fixed conditions

- Parked at Honda Home, phone unplugged, laptop ADB connected only when the user announces readiness for the specific attempt.
- Use the existing PhonePreference strategy, configured phone and Honda per-phone disabled setting. No force-stop loop, factory replacement, ignition cycle, camera maneuver or settings change in this test.
- Keep the same phone, app/track, ordinary volume and Bluetooth Media audio state across all three attempts. Record that original media setting. Bluetooth isolation already has a bounded v5 result; this plan does not repeat that variable.
- Existing 120-second watchdog per attempt. Its clock begins before the phone connects; announce the actual remaining time when READY. Incomplete checks are NOT_RUN, not failures or successes. Do not extend the deadline.
- Raw pad coordinates remain 1325x720; displayed active video is 1920x720. This test observes available controls, not a new coordinate transformation.
- Do not begin the next attempt until the current run's evidence is saved and cleanup verified. Each attempt needs a fresh user readiness message; never run the three attempts as an automatic device loop.

## Operator preflight for each attempt

1. Reverify target identity/fingerprint. Qualify the read-only lock-task getter against current framework/services hashes, then observe stable Home/INACTIVE lock-task. Do not reuse an unqualified transaction number.
2. Recheck this exact APK and recorded Java inputs using the existing CurrentSource artifact planner. Static audit remains PENDING; do not relabel that audit as passed.
3. Start the existing helper runner with PhonePreference and 120 seconds. Confirm installed bytes, fresh accessibility/helper readiness, active capture and independent cleanup watchdog.
4. Only after the runner reports READY, send the complete attempt-specific instructions below with actual remaining time. Never give the phone-connection cue early.

## Attempt 1 — fresh connection and center/side input

Connection criteria: the expected receiver appears, geometry is as previously reported, and permission prompts are handled automatically. Record any manual acknowledgment or warning.

User instruction message at READY:

> READY—about [actual seconds] remain before automatic cleanup.
>
> 1. Switch USB from the laptop to phone/Android Auto mode, return to Honda Home, and connect the OnePlus.
> 2. Confirm Android Auto appears with the expected proportions. Note any prompt you have to acknowledge manually.
> 3. Move to a known menu/app item near the center, press/release once and confirm it opens. Use Back to return.
> 4. Try existing selectable controls near the left and right sides. Note any highlight offset, missed click, double action or Honda Home response underneath. If no suitable control is present, report that position as not tested.
> 5. Play the familiar track for about five seconds and confirm sound, then pause.
> 6. Unplug the phone and reconnect the laptop to ADB. Tell me what worked. Wait for me to save logs and verify cleanup before disconnecting from the car.
>
> Do not rush checks past the watchdog deadline; tell me which ones you completed.

## Attempt 2 — replug and top/bottom input

This is a new independently prepared run after attempt 1 cleanup. It tests a repeated connection without changing firmware, settings or rebooting either device. Installing identical APK bytes through the existing runner remains part of preparation; this does not prove autonomous unattended reconnect.

User instruction message at READY:

> READY—about [actual seconds] remain before automatic cleanup.
>
> 1. Switch USB from the laptop to phone/Android Auto mode, return to Honda Home, and reconnect the same OnePlus.
> 2. Confirm Android Auto reconnects and note whether prompts are automatic again.
> 3. Try existing selectable controls near the top and bottom of the AA interface, then Back. Note offset, missed/double selection or any Honda Home action underneath. Report unavailable targets as not tested.
> 4. Play the same track for about five seconds. Unplug the phone while it is playing; note whether the AA picture disappears, what screen returns, and whether the receiver audio stops.
> 5. Reconnect the laptop to ADB. Report the results and wait for log collection/cleanup confirmation before disconnecting from the car.
>
> This is the second bounded attempt, not a continuous reconnect test or a longer session.

## Attempt 3 — physical HOME and available return path

HOME behavior is exploratory, not a feature assumed to exist in v5. HOME can mean foreground switch rather than complete receiver shutdown; record music behavior separately. A missing AA return tile is a product gap, not evidence that USB failed.

User instruction message at READY:

> READY—about [actual seconds] remain before automatic cleanup.
>
> 1. Switch USB from the laptop to phone/Android Auto mode, return to Honda Home, and connect the OnePlus.
> 2. Confirm AA appears and one normal click works. Start the same track at ordinary volume.
> 3. Press the car's physical HOME button once. Tell me whether Honda Home becomes visible, whether AA stays over it, and whether music continues, pauses or stops.
> 4. If Honda Home is visible, move over an ordinary Home control and check its highlight. Do not open settings or activate a call. If an existing, known control returns to our AA session, try it once and report the result. If none exists, report “no return control”; do not start stock AA or improvise a new launch method.
> 5. Pause music if possible. Unplug the phone, reconnect the laptop to ADB, and wait for logs and cleanup verification before disconnecting from the car.
>
> If AA prevents Home access, stop interacting and reconnect the laptop. The independent watchdog still ends the helper window.

## Evidence and verdicts

Record each attempt in RESULTS-TEMPLATE.json with the actual run directory. It starts with all outcomes UNKNOWN/NOT_RUN. Preserve raw logs privately and hash them. Use the unique RDX.PREP boundary and session/process identity to avoid counting older logcat entries as this run.

- Connection: compare fresh device/permission/session events, first-frame/render evidence, user picture report and errors before detachment. Separate an intentional unplug from a spontaneous transport failure.
- Input: correlate INPUT_PAD_PRESS, INPUT_PAD_SELECT and native KEY code=23 return values with reported UI activation. Count DOWN/UP pairs. Native success is not proof the intended UI target activated. Available edge targets are a sample, not exhaustive coordinate calibration.
- Home: combine the operator's observation during phone connection with later foreground/window evidence where available. A post-cleanup Home snapshot cannot establish what was visible while the phone was connected. Do not label hidden-Home input leakage disproven solely because select events reached AA.
- Audio: use PCM/playback/focus diagnostics plus operator audibility. Preserve drops and incomplete writes; do not call the result zero-drop unless counters support it. HOME music continuation is an observation until intended background behavior is specified.
- Cleanup: require watchdog outcome and current helper/overlay/capture/watchdog state plus accessibility settings compared with the run's baseline. If required evidence is missing, cleanup is UNKNOWN until checked.

Three successful independently prepared connections support repeatability under these fixed conditions only. They do not establish ignition behavior, unattended reconnect, long-session stability, voice, calls, steering-wheel mappings or reverse-camera interruption. Those remain outside this test.

## Local preparation command

For each attempt the prepared artifact plan uses the existing runner's **Prepare** mode. No new live wrapper, APK, helper action, bypass or automated device loop is added. Live preparation still uses the established script only after current-session readiness/authorization.
