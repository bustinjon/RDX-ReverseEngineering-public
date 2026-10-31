# Hover restore A — bounded input regression test

Built offline, not installed or hardware-tested. This document is a plan for the lead/operator; it authorizes no device action. Follow AGENTS.md and PROJECT-RULES.md.

APK: `analysis/parallel-aa-receiver/usb-helper/build/20261031-000234-450/rdx-usb-helper-v6h-hover-restore-a.apk`

SHA-256: `D404014AC8D4F58F2C79AA51DE8DF0D9146A80A801B1FC1AF8BA7A1B9511E612`

## Controlled change

Restore the v5 hover handler: Android hover ENTER/MOVE/EXIT (9/7/10) becomes native-pad DOWN/MOVE/UP (0/2/1), through the existing handleTouch/session/InputSource path. Keep current explicit directional mappings, event consumption, physical Select handling, Back mapping, window flags, feedback and capture code unchanged. This is not a complete v5 rollback.

Expected marker: `INPUT_HOVER_RESTORE_V1 hoverForwarded=true directionalKeysUnchanged=true`.

| Input | Key path retained |
|---|---|
| Raw 146 / 148 / 150 / 152 | Down 20 / Left 21 / Right 22 / Up 19 |
| Back 4 | Back 4 |
| Enter 66 / ordinary pad press | Select 23 |
| Hover | Existing raw-coordinate native-pad path restored |

The operator clarified that the earlier version had working Up/Down and Back was untested. Exact association of that earlier passing observation with an APK remains UNKNOWN. V5 is a preserved comparison baseline, not proof of universal success: its later test already had a lower-right Spotify Down problem. Current failed Back presses all followed a voice/reminder session; test ordinary app Back separately.

## Preparation by the lead/operator

- Use the existing guarded CurrentSource / PhonePreference process with a 180-second cleanup window, fresh target/Home/lock-task checks and the configured phone identity. Reconfirm the actual Honda per-phone setting at the session; an offline plan is not evidence of its present state.
- Use this APK and hash, and verify installed provenance. Do not bypass readiness or restore historical source over the candidate.
- The offline plan is `analysis/test-prep/runs/helper_20261031T040331_08271fcda90645c8a1eedcc1a0ee694b/artifact-plan.json`. Prepare mode was exercised with a nonexistent ADB executable and invoked no device command.
- Keep the phone, AA layout and other settings constant. Do not combine this attempt with audio, voice, OEM Home/camera or lifecycle experiments.
- Existing private capture capability is unchanged and defaults OFF. Record whether it is armed; if used under existing approval, preserve that fact with the evidence. Do not change capture policy during the attempt. Captures and raw logs remain private.

## Full connection cue

Send this only after the authorized live process has actually reported READY. Fill in the measured remaining time. This build task did not establish live readiness.

> READY — approximately [actual seconds] remain before automatic cleanup.
>
> 1. With the car parked at Honda Home, switch USB from the laptop to phone/Android Auto mode and connect the configured phone. Keep the same settings as the previous test. Let the existing permission helper handle prompts; report any prompt that remains.
> 2. Open AA's app grid. Use a position with a visible neighboring icon in the tested direction. Make one deliberate Right swipe, then Left, lifting between swipes. Record whether focus moves correctly and whether it jumps unexpectedly.
> 3. In a column with another row, swipe Down once, then Up once. Record each result separately. An attempted move past a grid edge does not count as a failure. Avoid voice/reminder controls.
> 4. Select Spotify or another ordinary app once. Press Back once and check whether it returns to the preceding AA screen. If it fails, try once more, then stop repeating Back. Report whether any voice/reminder UI opened before the failure.
> 5. If the basic checks pass and time remains, open the same layout with Spotify on the right. Reach the lower track controls, select next track once, leave using AA controls, return, and repeat the Down/Up check. Report initial and after-return behavior separately. Do not use the car's HOME button for this comparison.
> 6. Pause playback if active, unplug the phone and reconnect the laptop for the authorized log collection. Report Left, Right, Up, Down, Select and Back individually. Wait for log retrieval and cleanup verification before disconnecting from the car.
>
> If the app crashes, inputs stop responding, focus jumps repeatedly or unexpected UI opens, stop repeated gestures and reconnect the laptop. If the timeout ends, report unfinished steps as untested.

## Evidence and verdict

Correlate the fresh process and run boundary, policy marker, restored TOUCH nativePad=raw logs, raw/mapped key pairs, native return values and operator-visible actions. Check for unexpected duplicate movement, unmatched key release or OEM input leakage. Confirm unchanged six-key registration and Select behavior; native result=0 alone does not prove AA handled a command.

If Up/Down improve but Left/Right double-move or Select fails, the candidate fails the regression acceptance criterion. If basic controls pass but the lower-right failure returns after panel re-entry, record partial restoration rather than a complete fix. Back remains independently unproven until ordinary app navigation is observed.

Preserve/hash the complete logs and installed APK, then verify the existing cleanup against the saved baseline. No new live result exists for this candidate yet.
