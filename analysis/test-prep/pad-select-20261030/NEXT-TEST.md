# V5 click and audio-isolation test

Use the existing signed v5 candidate. No rebuild is needed for this test procedure.

APK: `analysis/parallel-aa-receiver/usb-helper/build/20261030-185210-531/rdx-usb-helper-v6h-pad-select-v5.apk`

SHA-256: `98E6A0015F249960B7730F210FAFB46BDFDAFE7A31686478FD619A930C3831A4`.

## Before starting the helper window

- Park at Honda Home, phone unplugged; connect laptop ADB when ready. Retain the configured Honda per-phone disabled preference.
- On the OnePlus, open **Settings → Bluetooth → ⓘ/gear beside the paired car → Media audio**. Record its original state. Leave Media audio on for phase A. Keep Bluetooth itself, pairing and Phone calls intact. If no separate switch exists, record that limitation; do not substitute unpairing or disabling Bluetooth entirely.
- Choose a familiar track and note the app/title. Pause it. Use the same track and ordinary listening volume for both phases. Have the Bluetooth details screen accessible before starting, so setup does not consume the bounded helper window.
- Operator performs the established identity/Home/qualified lock-task checks, installed APK hash verification, fresh accessibility/helper readiness and device capture. Use PhonePreference and the existing 120-second watchdog. Do not begin switching connections until READY.

## During the phone session

1. **Click:** move to a known selectable item, depress/release the pad once, and report whether the item activates. Repeat once if needed. Avoid repeated presses that obscure event pairing.
2. **Audio A:** with Bluetooth Media audio enabled, play the chosen track for approximately 10 seconds. Report audible/silent and approximate time. Pause playback.
3. **Audio B:** on the phone, open **Settings → Bluetooth → ⓘ/gear beside the paired car** and turn **Media audio off**. Leave **Phone calls** and Bluetooth itself on; do not disconnect or unpair. Verify Media audio remains off, then resume the same track for approximately 10 seconds. Report audible/silent, approximate time, and whether Android Auto remained connected. Pause playback afterward.
4. Restore the original Media audio setting. Reconnect the laptop for capture retrieval. If the test window ends first, record B as not completed; do not extend the watchdog or interpret post-cleanup silence as a playback failure.

If clicking still fails, start the track directly on the phone. Record this so a click failure is not mistaken for an audio failure. Do not change car source, volume or track between A and B. If disabling Media audio disconnects Android Auto, record the interruption and treat B as inconclusive.

## READY message to give the user

Only send this after the runner actually reports READY; include the actual remaining watchdog time. The user requested the steps again at the phone-connection cue.

> READY—switch USB to phone/Android Auto mode, return Home, and connect the OnePlus now.
>
> 1. Move to an item and press/release the touchpad; check whether it opens.
> 2. With Bluetooth Media audio on, play a familiar track for about 10 seconds, then pause. Start it on the phone if clicking fails.
> 3. On the phone: Settings → Bluetooth → ⓘ/gear beside the car → turn Media audio off. Keep Bluetooth and Phone calls on; do not disconnect or unpair.
> 4. Resume the same track for 10 seconds. Note whether sound and Android Auto continue.
> 5. Restore Media audio, reconnect the laptop, and wait for log collection and cleanup verification before disconnecting from the car.
>
> The helper automatically stops at its deadline. Report whether clicking worked and whether audio worked with Media audio both on and off.

## Evidence and interpretation

Retrieve the complete capture/watchdog files and hash them before further work. Check cleanup against the saved original accessibility settings and owned process IDs. Compare phase times against protocol focus requests/responses, PCM arrivals, AudioTrack-ready, played-byte/drop counters and any audio failures. A final summary spanning A+B cannot by itself identify which phase wrote bytes; use timestamped periodic counters and user observations.

| Observation | Supported conclusion |
|---|---|
| Pad press 0/1, select true/false, native key 23 success and item activates | V5 click path works for this test |
| PCM/write counters increase during B, sound is heard, Media audio remains off, AA stays connected | Strong evidence of audible receiver playback independent of the phone-to-car Bluetooth media link |
| PCM/write counters increase during B but sound is absent | Receiver has PCM; audible output routing/focus/volume remains unresolved |
| No PCM during B or Android Auto disconnects | Cannot isolate speaker routing; investigate playback/session interruption first |
| A audible, B silent, without verified B PCM delivery | Bluetooth dependency is possible; cause remains UNKNOWN |
| Media audio switch unavailable, re-enables itself, or B not completed | Bluetooth isolation UNKNOWN |

Do not claim that AudioTrack writes prove speaker output. This test isolates the phone-to-car Bluetooth media path only; it does not establish every internal head-unit route.

## Report for this preparation

1. **Files inspected:** PROJECT-RULES.md; v5 validation.json; prepared artifact-plan.json; prior REPORT.md/live-evidence.json in this directory.
2. **Files changed:** this new NEXT-TEST.md only.
3. **Commands run:** local Get-Content inspections and file creation; candidate Get-FileHash verification.
4. **Tests run and results:** no new runtime tests; procedure-only change. Existing candidate host/build verification is recorded in validation.json/results.txt.
5. **Findings:** v4 receiver PCM/write evidence does not establish the audible route. A controlled Bluetooth media comparison is required for that question.
6. **Primary evidence:** live-evidence.json lists the v4 focus/PCM summary strings and capture hash; REPORT.md section 6 gives capture line references. This procedure specifies new observations, not completed results.
7. **Assumptions:** the phone exposes a separate Media audio setting and permits a session to remain connected with it off; otherwise B is inconclusive.
8. **Unresolved uncertainties:** v5 click behavior and audio isolation have not been hardware tested.
9. **Exact diff summary:** add one test procedure covering preparation, click, two audio phases, restoration, evidence collection and interpretation; no APK/source/runner changes.
10. **Preservation checks:** existing candidate hash checked; no device commands, frozen-artifact changes, Git mutations, guard bypass or milestone action in this preparation.
