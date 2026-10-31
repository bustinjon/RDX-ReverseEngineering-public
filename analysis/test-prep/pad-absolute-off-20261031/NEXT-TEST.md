# Future absolute-off comparison — not yet run

Pinned APK: v6h-pad-absolute-off-a, SHA-256 `A58A391BBC2A855E91F472403045490816E02598C5EBA09410EE85DCB078FA73`. Baseline: DB9B…371206 with the live absolute flag true. This candidate requests false; all input handlers/other registration parameters remain unchanged. The diagnostic-only mode still uses true and is not the test path.

No device connection is needed for the completed build. Do not execute the saved Prepare-LiveTest.ps1 until the user requests the next test and connects ADB.

## Preparation and full phone-connection cue

1. Vehicle parked, Honda Home visible, phone USB unplugged, laptop connected to head-unit ADB. Confirm prior stock Honda AA phone preference remains disabled. Keep audio/Bluetooth settings the same; do not introduce another comparison variable.
2. Use the existing generated Prepare-LiveTest.ps1: pinned candidate/source/installed-hash checks, firmware identity, stable Home/inactive lock-task, temporary A11Y, logger/watchdog and capture/B-zone arms. No guard bypass. It is currently syntax checked only.
3. Only after a real READY result, tell the user **READY — plug in phone**, state actual remaining timer time, and repeat: switch USB from ADB to phone mode, return to Honda Home, plug in the phone, let A11Y accept the prompts. The configured180-second watchdog begins during preparation, not at phone connection. No promise of three minutes after connecting.

## Minimal comparison using the large left pad

1. In the grid, briefly verify Up/Down/Left/Right, Select and Back. If a newly broken control appears, stop and collect; no further setting changes.
2. Spotify in the right third: start from the title row, try a deliberate Down swipe/release toward the previous/next row, then an Up swipe/release toward the top-right control. State which control gains focus. Use the **large pad**, as in the saved video. Do not substitute the narrow pad during this comparison.
3. Put Maps in the right third and compare the same directions. If time permits, leave/return to the Spotify widget once and repeat. Report first entry separately from returned entry.
4. Reconnect ADB for logs/private captures before disconnecting from the car. Agent collects first, verifies baseline A11Y restoration and owned-process cleanup, then says **SAFE TO DISCONNECT**. A crash/exit is a result to preserve, not a reason to cycle settings repeatedly.

## Evidence/decision criteria

- Verify installed SHA-256 A58A…8FA73 and fresh-session `Touchpad registered: ... nav=true abs=false`. Captured native-argument logging does not alone prove the phone's internal interpretation.
- Compare raw146->20/152->19, pad contacts, key order, native return and feedback with the previous main-pad trace. Record exact demonstrated pad. Keep B-zone arm state identical/explicit; no additional mapping edits.
- Pass requires reachable Spotify lower controls, repeatability after return and preserved Maps/grid movement, Select and Back. Initial partial access is not a final fix.
- If the symptom persists with the intended false flag, record that negative result and retain the old APK. Do not stack coordinate/key/media/rotary changes onto this comparison.

No Gemini, microphone, audio, media-command or unrelated changes belong in this build/test.
