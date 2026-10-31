# Media/input fixes comparison

Candidate **v6h-media-input-a**, SHA-256 **A2F4785466AD41E2459051A096B917881349EC2B64E06303D19F66DA38D4FB0F**. Includes the preceding navigation-focus fix.

Changes: forward known Honda Previous/Next signatures and standard media keys; show a temporary noninteractive volume indicator from actual OEM amplifier feedback; restore ordinary PageDown and request factory-matching absolute pad navigation. Spotify improvement remains experimental.

Use this directory's `Prepare-MediaTest.ps1` and `Collect-MediaTest.ps1` only after explicit authorization for the connected head unit. Preparation is untimed after its final READY cue. Do not run Prepare-TimedStage.ps1 alone or reuse older candidate preparation; their artifact/profile selections differ and the short stage alone retains its watchdog.

## Full instructions to repeat at the actual phone handoff

1. Park, phone unplugged, laptop connected by ADB and Honda on Home. Keep this phone's stock Honda AA preference disabled. Keep audio/Bluetooth/queue settings as in the last test. Accept the user's Home statement and retain only required readiness checks.
2. Operator runs `pwsh -File analysis/test-prep/media-input-fixes-20261031/Prepare-MediaTest.ps1`. Wait for **READY — untimed long-drive session; no scheduled cutoff**; NOT READY means no handoff.
3. Disconnect the laptop. Switch USB from ADB to Android Auto/phone mode through the established Honda menu, return to Honda Home and connect the phone. Existing permission prompts should auto-accept.
4. **TEST NOW:** check ordinary Up/Down/Left/Right, Select and Back. Put Spotify in the right third; from its title/upper selection try Down into the whole playback row. If startup Right reaches the row, move Up and try Down back into it. Repeat once after opening/closing the playlist menu. Report whether Play/Pause, Previous and Next become reachable.
5. With media playing, tap physical Next and Previous separately, then steering-wheel Next and Previous separately. Note which hardware works and whether a single short press causes one playback action. This candidate does not implement long-press seek. Stop this portion if buttons produce duplicate or unexpected actions.
6. Adjust volume up and down. Check for a small temporary `Volume N` indicator near the top centre, reflecting actual car amplifier feedback, and confirm adjustment still works. The original Honda dialog is not being raised; the new indicator appears within AA and should disappear after about3 seconds. It must not take input focus.
7. Start a Maps route to a destination away from the current position; note start time and make no input for at least90 seconds. End navigation normally, start another route and repeat90 seconds. Report actual route cancellation separately from any screen change; AA/music should keep running. This tests the retained navigation-focus fix.
8. Unplug the phone normally and reconnect ADB for evidence collection. Operator runs this directory's `Collect-MediaTest.ps1`, saves logs first, verifies cleanup, then issues **SAFE TO DISCONNECT**.

There is no scheduled cutoff after untimed READY. Normal disconnect/error/lifecycle behavior still applies. No live steps were run while preparing this file.

## Evidence criteria

- Installed APK matches A2F478…D4FB0F; current-run registration shows keys `[4,23,87,88,92,93,122,123]`, pad nav=true/abs=true; ordinary Down produces93 again. No arrows19–22 added.
- `INPUT_MEDIA_RAW` logs both phases with scan/source/device. Honda138/scan66/source257 maps to88; Honda139/scan67/source257 maps to87. One owned, noncancelled short press produces a balanced pair on release, recorded as `INPUT_MEDIA_KEY` and native key results. Repeats/orphan/cancelled releases must not skip again. A different steering-wheel path may still be unresolved if it never reaches these handlers.
- `VOLUME_FEEDBACK_REGISTERED`, actual `VOLUME_FEEDBACK_RECEIVED` and `VOLUME_FEEDBACK_SHOWN` distinguish reception from attempted rendering. No received amplifier data means the broadcast delivery path still needs investigation; do not estimate the volume from button counts. Existing TextureView screenshots capture the AA video, not this added HUD, so operator observation is required for visibility.
- Navigation logs should show requested projected2/reply2; any native1 request must receive1. Route staying active beyond90 seconds supplies behavior evidence. Missing callbacks leave the focus hypothesis inconclusive.
- Use current run/PID/timestamps: restarting logcat can replay old messages. This combined candidate tests usability; an improvement alone does not isolate which input-profile difference changed Spotify traversal.
