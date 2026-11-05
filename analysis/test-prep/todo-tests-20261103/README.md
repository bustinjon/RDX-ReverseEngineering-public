# To-do test suite — prepared 2026-11-03 (Claude)

One test per to-do item. **Current baseline: T24 volume `191E43A6…F48C` = Maps fix + nav voice + mic + console track buttons + day/night + Home minimizes / side-panel returns + volume display, promoted 2026-11-04. Run it any time with Start-B-current-baseline.cmd.** T09 dropped (volume signal is Honda-only), T12 dropped (reconnect already works), T14 deferred. Every code test is its own APK built from the current baseline with one change. One card per item is in [cards/](cards/).

## How a visit works

1. Pick 2–3 tests from the order below. Close the ordinary launcher first.
2. For each: **Start-…cmd** → READY → Diagnostics checkpoint → phone handoff → do the card's steps → unplug → ADB mode → **Collect-…cmd** → SAFE TO DISCONNECT.
3. Always Collect a test before starting the next one. Collect also puts the Maps-only source back.
4. Emergency stop at any time: stay parked and **unplug the phone**.

Every Start repeats the full handoff:
1. Parked at Home, phone unplugged during prep.
2. Wait for READY.
3. Switch USB through the Honda Diagnostics menu (the label may say Apple CarPlay/phone mode).
4. Return Home and plug in the phone.
5. Afterward, restore ADB mode, reconnect, run Collect, and wait for SAFE TO DISCONNECT.

If a Start fails before READY, run **Restore-Baseline-Source.cmd** before trying a different test.

## Suggested order (updated 2026-11-04 night)

Passed and in the baseline: Maps focus, nav voice, mic, console track buttons, day/night, Home minimizes / side-panel returns (T22, T22b), volume display (T24).
Blocked by Honda permissions: steering-wheel track/talk buttons (T23), Honda volume broadcast (T09), speed/gear (T14).

| Next visit | Run | Covers |
|---|---|---|
| 1 | Start-T30-persistent (type PERSIST after READY; power-off test; UNDO at Collect) | T30 persistent mode + T26 popup dismiss retest + T16/T17 laptop-free restart |
| 2 | Start-T25-car-gps on a real drive | T25 |
| 3 | New launcher (T31) for the long drive (T19); Start-B-current-baseline for T27 replug x5, T28 app-tile look, T29 transitions | T19, T27-T29, T31 |
| any | T07 Spotify in stock AA | T07 |
| design | T32 setup kit, T33 absolute touchpad, T34 volume look | — |

Rule: when a test passes, tell Claude. Its change becomes the new baseline for the next builds. Failed changes are dropped.

## Packages

| Test | Shortcuts | APK SHA-256 | Changed files vs Maps-only | Host checks |
|---|---|---|---|---|
| A watch-only | Start/Collect-A-watch-only | `21037DC3…4084` (copy) | none; extra log tags only | — |
| T09 volume display | Start/Collect-T09-volume-display | `2037BE50…BD60F` | AaOverlayService, +VolumeFeedback | 11 |
| T10 track buttons | Start/Collect-T10-track-buttons | `5EC55E44…B09499` | InputEvents, AaOverlayService | 63 |
| T11 mic | Start/Collect-T11-mic | `1A9A819E…B2D67667` | AudioSource, AaSessionService, manifest (+RECORD_AUDIO) | compile only |
| T12 reconnect | Start/Collect-T12-reconnect | `E74AC0D2…43F551F7` | UsbHelperService, AaSessionService, AudioSink, +ReconnectPolicy | 24 |
| T13 day/night | Start/Collect-T13-day-night | `16A46E02…AEA19A38` | AaSessionService, SensorSource, +NightModeWatcher | 10 |

Full hashes are in each `builds/<test>/build-result.json`. Each package passes `tools/Run-Test.ps1 -Test <test> -Action Check`. That check verifies the APK hash and confirms it differs from the live source in exactly the intended files. Code review status: [REVIEW.md](REVIEW.md).

## How it stays safe

- The car runner only accepts an APK whose recorded sources match the live tree (unchanged rule). So Start swaps in that test's verified source files, and Collect swaps the Maps-only files back (`tools/Switch-Source.ps1`). It refuses to run while another test's source is active, and refuses to overwrite unexpected edits.
- Packages are generated from the live-tested standalone launcher templates (`tools/New-TestPackage.ps1`). Only these change:
  - APK path and hash
  - profile label
  - repo-root depth
  - extra logcat tags
- The generator checks that the identity, firmware and stable-window block is byte-identical to the template.
- The Diagnostics checkpoint before the phone handoff is kept. If the Honda menu stops opening, you couldn't switch USB back to ADB.
- `Check-Signals.ps1` runs only `dumpsys activity broadcasts` and `service list`.
- No M5/M6/M7 action, guard change, frozen-artifact rebuild or readiness bypass.

## Notes

- The builder's `analysis/parallel-aa-receiver/usb-helper/latest-build.txt` now points at the last suite build. As before, don't pick builds from it. Use this table.
- The receiver reports "always parked" to the phone. User decision 2026-11-03: keep it for now (T14 deferred, optional).
- Tools: `tools/Save-Baseline.ps1`, `Build-Test.ps1`, `New-TestPackage.ps1`, `Run-Test.ps1`, `Switch-Source.ps1`, `Check-Signals.ps1`, `make-cards.cjs`.
