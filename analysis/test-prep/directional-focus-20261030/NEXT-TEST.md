# Directional focus A — input-path isolation

Private helper APK: `analysis/parallel-aa-receiver/usb-helper/build/20261030-201558-444/rdx-usb-helper-v6h-directional-focus-a.apk`

SHA-256: `F6D485977DEF00B0C6BADE0E0CD7ED50E8615923E522B3CC73F7BF0D66C57F92`.

## What this tests

The previous page/move candidate initially changed a Spotify track, then failed after panel return. It sent no normal DPAD keys. Framework fallback evidence shows why consuming raw NUMPAD swipe codes can replace the v5 directional fallback with page/move semantics. Separately, both earlier candidates also forwarded hover/pad movement.

V5 already produced directional keys, so changing only the key labels would largely repeat that earlier test. This candidate explicitly translates raw swipes to directional keys and consumes them, and **does not forward hover to the phone**. This tests a single navigation input family: keys. It is a deliberate compatibility experiment, not the complete factory input path or a proven repair.

| Raw input | Forwarded input |
|---|---|
| 146 | Down, 20 |
| 148 | Left, 21 |
| 150 | Right, 22 |
| 152 | Up, 19 |
| Physical pad press/release | Select 23 DOWN/UP |
| Hover | Consumed locally, sampled diagnostics only |

Normal DPAD, Back and Enter-to-select are supported. Page/Move keys are not registered or forwarded in this candidate. No timing deduplication or synthesized extra key pair is added. One accepted raw DOWN/UP event is sent once; physical repeat behavior remains subject to device testing.

Geometry, video profile/DPI, native library, audio and session lifecycle are unchanged. Pad capability declaration/registration remains as before; this experiment changes delivery, not discovery geometry. An improvement would not separately prove which aspect of the changed input policy was decisive.

## Preparation and constants

Use parked Honda Home with the phone unplugged and ADB connected when the user announces readiness. Requalify target identity, current framework/services getter and stable Home/INACTIVE lock-task. Use the established CurrentSource/PhonePreference runner with the configured phone and **120 seconds**, no legacy force-stop loop or bypass.

Keep the same phone, AA layout with Spotify on the right, app/track, volume and Bluetooth Media audio setting. No Home/camera/ignition experiment in this window. The offline plan is `analysis/test-prep/runs/helper_20261031T001657_b88d6086f23f4b4cb83ffc6c1b1a950e/artifact-plan.json`; live readiness is not yet established.

## Full READY instructions

Only send after the runner reports READY, with actual remaining time.

> READY—about [actual seconds] remain before automatic cleanup.
>
> 1. Switch USB from the laptop to phone/Android Auto mode, return to Honda Home, and connect the OnePlus.
> 2. Open the same layout with Spotify on the right. Make one deliberate swipe at a time, lifting between swipes. Check that the selected item moves in the intended direction; tell me if nothing moves or it jumps unexpectedly.
> 3. Navigate down to Spotify's lower controls. Select next track once and previous track once. Note whether both activate correctly.
> 4. Using Android Auto's Back/app controls, leave that panel and return to Spotify as you did in the failing test. Try reaching the same lower controls again. If time permits, leave and return once more. Report initial / first return / second return separately. Do not use the car's HOME button for this comparison.
> 5. Confirm Back and a normal click still work, and listen for about five seconds. Leave Bluetooth Media audio and volume unchanged.
> 6. Pause music, unplug the phone, reconnect the laptop to ADB, and report the results. Wait for log collection and cleanup confirmation before disconnecting from the car.
>
> If controls stop responding or jump unexpectedly, stop repeated gestures and reconnect the laptop. If the timeout ends first, tell me which return checks you completed; unfinished checks are not a pass.

## Record and interpret

- Establish INPUT_KEY_ONLY_V1 and KEYSET_DIRECTIONAL_V1 in the fresh process. INPUT_HOVER_IGNORED is expected; it is not a transport error. Count sampled diagnostics accordingly, not as every physical hover event.
- Correlate raw code/scan/flags/repeat/source/device fields with normalized INPUT_KEY and native KEY 19/20/21/22 pairs. Flag unmatched release, duplicate DOWN or extra fallback keys; flags include Android's fallback bit if present. Do not assume a physical gesture emits only one event.
- Confirm no Page Up/Down/Move Home/End native keys and no VIDEO-mode native-pad forwarding. Host tests do not validate Android's full input pipeline; the capture is required.
- Pair user target activation and panel-return observations with key success. Native result=0 alone is insufficient. Exact failure time remains UNKNOWN unless supplied/correlated.
- Initial success with failed return remains NOT_FIXED. Two successful returns within the window support only this short test. They do not establish long-session stability, rotary, multitouch, voice, calls or OEM interruption.
- Pull/hash complete evidence; compare cleanup settings/processes against the run's original baseline before disconnect clearance.

## Preservation

Known-working v5 and prior swipe APKs remain unchanged. Previous source references are preserved here and in the swipe-navigation preparation folder. The PhonePreference guard requires matching CurrentSource provenance; do not bypass it for historical APKs. No source restoration or live action is performed by this plan.
