# Next car comparison — A then B

Offline prepared only. First **A: arrows advertised**, then collect/clean up, then **B: arrows omitted** in a fresh phone session. Both send identical page/move codes for the large-pad gestures. Full hashes/paths: REPORT.md and candidate-*.json. Final selected source is A.

## Agent preparation after a user-confirmed ADB connection

- Phone unplugged; vehicle parked. Accept the operator's Honda Home confirmation without adding extra Home loops. Existing required readiness checks remain intact.
- Execute `Prepare-arrows.ps1` for A; after collection, use `Prepare-padonly.ps1` for B only when the user is ready for that second session. Each first selects the exact source snapshot, verifies27 input hashes and pins the correct APK for the existing CurrentSource runner.
- Existing setup installs/verifies the candidate, A11Y, logger/watchdog and capture. B-zone stays OFF in both; no external keyboard. UI/menu automation has not been qualified and is not silently added.
- Do not use the old generic preparation files that arm B-zone. Do not manually install B while the source/current plan selects A.

## Full phone-connection instructions at each real READY cue

1. Say **READY — plug in phone** and state the measured remaining watchdog time. The timer is180seconds from preparation, not180seconds after connection.
2. Switch USB from ADB to the existing phone-connection mode, return normally to Honda Home, then plug in the phone. Let A11Y accept prompts.
3. Keep stock Honda AA disabled for this paired phone as before. Keep audio/Bluetooth and phone/app settings unchanged.
4. **TEST NOW — large left pad only.** Briefly check Up/Down/Left/Right, Select and Back in the grid. If a newly broken basic control appears, stop and reconnect for logs.
5. Use a known multi-track playlist. Spotify in the right third: title row -> Down toward **any** bottom control, including Play/Pause; then Up toward the top-right button. Report whether the entire row remains unreachable or any button gains focus. If possible compare the same track in the main player without changing the queue.
6. Briefly check Down within Spotify's right-third browsing list and navigation within Maps at the right. If time remains, leave/return to the compact playback card once and repeat. Same sequence for A and B.
7. Reconnect ADB for collection. Pull logs/private captures first; then verify A11Y restoration/owned-process cleanup and say **SAFE TO DISCONNECT**. Do not switch profiles while an old test watchdog is still active.

## Evidence and interpretation

- A SHA: `C3EDC256281D1F923CD65785DB0C0FA6B5E36E182FD602194245B89DB5875DDF`; B SHA: `E931C7A4368465F52B218C5E973540F26D5C3D438F02751CC3C0B6FB15CEF383`.
- Check fresh runtime key list: A=`[4,19,20,21,22,23,92,93,122,123]`; B=`[4,23,92,93,122,123]`. The existing log marker may still say KEYSET_DIRECTIONAL_V1; inspect the actual list, not just the name.
- Both must log `nav=true abs=false` and B-zone `enabled=false`. Physical swipe146 must map to93,152->92,148->122,150->123; balanced native pairs and return codes recorded. Select23/Back4 preserved.
- Verify no direct raw19–22 entered during the controlled sequence. Their acceptance differs by design; if present, separate that confound from key-declaration interpretation.
- A fails/B succeeds: profile difference is implicated, not yet final causality. Repeat after leaving/returning, and an A recheck can help exclude phone-state drift in a later authorized session.
- Both fail: preserve the negative result; don't add geometry/media/rotary changes during the same session. A's basic movement fails: stop and review rather than completing a misleading contrast.
- No Gemini, microphone, audio feature, new media provider, screen scaling, absolute-mode change or OEM modification in this experiment.
