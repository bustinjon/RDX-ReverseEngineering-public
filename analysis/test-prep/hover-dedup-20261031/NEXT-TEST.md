# Hover duplicate-ENTER isolation A

Built and verified offline; not installed or hardware-tested. This plan authorizes no device action. Follow PROJECT-RULES.md and the current session's explicit authorization.

APK: `analysis/parallel-aa-receiver/usb-helper/build/20261031-003921-309/rdx-usb-helper-v6h-hover-dedup-a.apk`

SHA-256: `C458B51DA03A9B96776E233A220B03C04254C13F4AC7E2BB790325590DDA14FD`.

## What changed

The previous hover-restoration test restored app-grid Up/Down, but Spotify's right-third dashboard panel still would not navigate down to the lower skip controls. Its stream contained ten extra pad DOWNs, including one at initial contact and nine after completed Select clicks. Causation remains UNKNOWN. Canonical result: `analysis/test-prep/runs/helper_20261031T041524_80b16905aa3048e99d3f52f817379dbb/REPORT.md`.

This candidate suppresses only another hover ENTER while a pad contact is already active. The first ENTER, all MOVE events and EXIT remain forwarded. New overlays start with independent contact state. Existing idle MOVE/EXIT behavior is deliberately preserved. Key mappings, six-key registration, Select handling, Back, window flags, geometry, native library, audio, feedback, capture and lifecycle behavior are unchanged.

Markers:

- `INPUT_HOVER_DEDUP_V1 hoverForwarded=true directionalKeysUnchanged=true`
- `INPUT_HOVER_DUPLICATE_ENTER_DROPPED` for each suppressed ENTER.

Recorded replay preserves all 1,000 MOVE events and 96 releases in the last test, while reducing DOWNs from 106 to 96. The older v5 fixture also passes. These are offline sequence checks, not proof of phone behavior.

## Preparation

Use the established CurrentSource / PhonePreference process with a fresh 180-second watchdog and the same configured phone/layout. Requalify firmware/getter, stable Honda Home, INACTIVE lock-task, installed APK hash and accessibility helper normally; no bypass. Existing phone-scoped Honda setting must still apply. Prior confirmation is not a new observation of present state.

Offline plan: `analysis/test-prep/runs/helper_20261031T044031_663e4f7675a44ed2b43c9bafd4fe4996/artifact-plan.json`. Prepare was run with a nonexistent ADB executable and invoked no device command.

Capture capability remains default OFF and unchanged. For comparison, use the existing one-session private capture procedure under the existing approval, record whether armed, and remeasure the actual watchdog time before giving READY. Captures and raw logs stay private. Do not add voice, audio, OEM Home/camera or lifecycle experiments to this attempt.

## Full connection instructions

Give this cue only after actual live readiness, installation verification and any agreed capture arm. Fill in the measured remaining time.

> READY — approximately [actual seconds] remain before automatic cleanup.
>
> 1. Stay parked at Honda Home. Switch USB from the laptop to phone/Android Auto mode and connect the OnePlus. Keep the same settings. Let the helper handle permission prompts; report any that remain.
> 2. In AA's app grid, make one deliberate Right, Left, Down and Up gesture, lifting between gestures and using positions with an available neighbor. Confirm movement and normal Select, and note any missed movement or double jump. Avoid voice/reminder controls.
> 3. Open the usual dashboard with Spotify occupying the right third. Move focus into Spotify, then try Down toward the lower skip controls. If reachable, select next track once. If stuck, stop after two or three deliberate attempts and note which item stays highlighted.
> 4. Select the song/title area to enter Spotify's main app. Press Back once to check normal app navigation. If it fails, report that separately and use AA's app/dashboard controls to return; do not use the car's HOME button.
> 5. After returning to the right-third Spotify panel, try Down to the skip controls again. If reachable, select next track once. Report before-return and after-return results separately. If time is short, prioritize this comparison over further repetitions.
> 6. Pause playback if active, unplug the phone and reconnect the laptop to ADB. Report grid movement, Select, Back, and right-panel controls before/after return. Wait for log collection and cleanup verification before disconnecting from the car.
>
> If inputs stop responding, focus jumps repeatedly, unexpected voice UI opens or the app crashes, stop repeated input and reconnect the laptop. Record unfinished checks as untested.

## Evidence and acceptance

Confirm the new policy in the fresh process and verify suppression markers. The new forwarded TOUCH sequence should not contain another DOWN while contact is active; preserve complete MOVE/UP sequences and correlate ordinary Select DOWN/UP and SELECT feedback. Check the first contact and reentry after each completed click. Do not require exactly ten suppressions in a different physical session.

Success requires retaining grid navigation and Select while reaching the lower right-panel controls both before and after returning to the panel. Back is scored independently because the last run had no Back events. A cleaner contact stream without improved panel access is an informative negative result, not a repair. Missing/changed phone focus feedback is not a verdict by itself.

Pull and hash the complete capture, watchdog/cleanup outputs, installed APK and only the logged private image session. Verify cleanup and saved baseline before disconnect clearance. Do not alter source or install another candidate before collecting this evidence.
