# Swipe navigation candidate — targeted Spotify retest

Use private helper candidate `v6h-swipe-navigation-v6`, not the public diagnostic APK. The suffix v6 is a helper revision label, not project milestone M6. No milestone transition.

APK: `analysis/parallel-aa-receiver/usb-helper/build/20261030-200012-348/rdx-usb-helper-v6h-swipe-navigation-v6.apk`

SHA-256: `2EF2FB9AAB41446D57D942E3F155F337E08D71282A85F8E148651B2A2B36FD03`.

## Hypothesis and fixed conditions

The last v5 attempt could not navigate down to Spotify controls on the right despite reaching full raw pad bounds and delivering 28 native Down pairs. Stock Honda also maps OEM swipe keys to page/move keys and registers them; v5 omitted that behavior. This candidate restores those semantics. Causal relevance remains UNKNOWN until tested.

| Raw key | Forwarded key | Meaning |
|---|---|---|
| 146 | 93 | Page Down |
| 148 | 122 | Move Home |
| 150 | 123 | Move End |
| 152 | 92 | Page Up |

Back/DPAD/select and Enter conversion remain available. Both key directions use the existing overlay dispatcher. Normal DPAD events are retained; no time-based deduplication is added. The native supported-key list now includes 92,93,122,123. Direct occurrences of these protocol key codes are also accepted unchanged.

Keep the same phone, AA layout with Spotify on the right, track, normal volume and Bluetooth Media audio setting. Do not change DPI, video mode, input scaling, overscan, Honda preference or layout as part of this comparison. Geometry/audio/lifecycle code is unchanged from v5. Keep the 120-second watchdog and existing PhonePreference preparation.

## Before connection

Wait for the user to connect ADB at Honda Home with the phone unplugged. Repeat target identity, qualified framework getter, stable Home/INACTIVE lock-task and installed-artifact checks. Use CurrentSource with this APK/hash; its 25 recorded Java inputs must match. The offline prepared plan is `analysis/test-prep/runs/helper_20261031T000106_6be3e2e3eee74dafa3f1f323ac1910b0/artifact-plan.json`; it does not establish live readiness.

## Complete READY prompt

Only send after the runner reports READY. Insert actual remaining time.

> READY—about [actual seconds] remain before automatic cleanup.
>
> 1. Switch USB from the laptop to phone/Android Auto mode, return to Honda Home, and connect the OnePlus.
> 2. Bring up the same layout as the failed test, with Spotify on the right. Tell me if the layout is different; we should not mistake a layout change for a fix.
> 3. Move into Spotify. Make one deliberate downward swipe, lift your finger, and watch where the highlight goes. Repeat only as needed to reach the lower controls. Note whether it stays trapped, moves correctly, or jumps past multiple controls.
> 4. If reachable, select the next-track control once, then the previous-track control once. Report whether each intended action occurs exactly once. Do not treat a moving highlight alone as a successful click.
> 5. Try one upward swipe and a left/right movement, then a normal click and Back. Note any new jumps or double actions. Play music for about five seconds to confirm sound still works; leave Bluetooth Media audio unchanged.
> 6. Pause music, unplug the phone, and reconnect the laptop to ADB. Report what happened and wait for log collection and cleanup verification before disconnecting from the car.
>
> If the interface starts jumping unexpectedly, stop repeated swipes and reconnect the laptop. If the deadline ends first, report which checks were completed.

## Evidence and verdict

- Verify KEYSET_OEM_SWIPE_V1 contains the ten registered protocol keys.
- At the unique run boundary/process, correlate raw OEM key codes with native mapped codes 93/122/123/92 and their DOWN/UP results. Check for unmatched releases and regular DPAD events from the same gesture.
- Compare user-reported reachability/action to the last v5 failure. Native return=0 establishes submission, not the correct target or one action per physical gesture.
- Record selected Spotify layout/control, direction tested, reachability, missed/extra steps, one-action-per-select, Back and audio. Uncompleted directions are NOT_RUN.
- If keys transmit but lower controls remain unreachable, the missing mapping is not a sufficient repair. Do not immediately stack scaling/DPI/window changes onto the result.
- Pull/hash the complete logs; compare current helper/overlay/accessibility/owned capture/watchdog state with the run baseline before giving disconnect clearance.

## Preservation and rollback reference

Known-working v5 APK remains unchanged at SHA-256 `98E6A0015F249960B7730F210FAFB46BDFDAFE7A31686478FD619A930C3831A4`. The two original source files were preserved with exact v5 build hashes under v5-source-reference/; see v5-source-reference.json.

The PhonePreference runner requires a matching CurrentSource plan and rejects HistoricalBaseline. Do not bypass this check to reinstall v5. Any later v5 restoration must restore/review the original source pair and re-establish source provenance through the existing guard. No restoration is performed by this plan.
