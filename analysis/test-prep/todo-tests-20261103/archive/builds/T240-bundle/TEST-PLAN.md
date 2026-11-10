# T240 parked test: per-device wireless policy

**Purpose:** prove that the current phone's USB-only / Off setting disconnects wireless AA, leaves other allowed devices alone, and prevents automatic reconnection until wireless is permitted again. This is not a freeze fix or a long-drive qualification.

**APK built and verified offline:** `rdx-t240-bundle.apk`, SHA-256 `14CBCFFA0F02AC85AB271C3DE8E9DE2EC3560198F6C71291D6F4E52E6FA77004`. `build-result.json` says BUILT_AND_PACKAGED with `baselineRestored: true`; packaging/verification.json records PASS. Use `Start-T240-bundle.cmd` / `Collect-T240-bundle.cmd` in the suite folder when the car step is separately authorized. No live action is authorized by this document.

## Preparation after separately authorizing the car step

1. Park. Leave Honda on Home. Unplug the phone and any dongle. Phone hotspot off; Bluetooth and Wi-Fi on. The configured phone must remain Disabled/Never in Honda's stock Android Auto settings.
2. Set the Diagnostics USB menu to ADB and connect the laptop. Use the T240 Start shortcut once it has been packaged. Wait for READY; complete the existing diagnostic-menu checkpoint, return Home and enter PASS when prompted. Do not skip or bypass readiness.
3. Wireless testing can keep the laptop connected in ADB mode. If the phone's USB-to-Bluetooth link has not already been established, follow the existing runner's handoff instructions: unplug laptop, switch Diagnostics USB mode from ADB to Android Auto, return Home, connect the configured phone by USB once, allow AA to start for 20 seconds, then unplug it. Restore ADB and reconnect laptop when practical. Keep Honda's phone preference Disabled/Never. Do not treat the first-pair owner fallback as a proved physical identity.
4. Wait for wireless AA. Confirm the configured phone's row currently says USB + Wireless. If not, cycle to it, wait for connection, then begin recording. Save the wall-clock time of each change.

## Smallest proving sequence

1. While wireless AA is active, open Hackura Settings > Phone & devices. Tap the configured phone's row once: **USB + Wireless → USB only**. AA must end without touching the global Wireless Android Auto switch. Wait 20 seconds: it must not reconnect wirelessly. Record disconnect latency and whether Settings briefly stalls.
2. Tap the same row: **USB only → Wireless only**. Wireless AA should return. Allow up to 90 seconds; report actual latency. Return to Settings.
3. Tap: **Wireless only → Off**. Wireless AA must end again. Wait 30 seconds: no automatic reconnection. The Bluetooth adapter and pairings must remain intact; there is no adapter-off/forget action in this change. HFP call behavior needs its own actual observation.
4. Tap: **Off → USB + Wireless**. Require one normal reconnection. Confirm picture, navigation input and media still work. Do not change unrelated settings.

Stop here for the minimal test. Do not diagnose the previously observed teardown hitch as fixed by T240; existing native teardown remains synchronous. Report a persistent freeze separately with its timestamp.

## Optional boundary checks only if the minimal sequence passes

- Disable a different, already-configured device row while the main phone runs wireless. The main session must stay alive. Do not add/delete devices merely for this check.
- Immediately select Off while a wireless connection is starting. It must not complete after the change. This candidate rechecks after the network wait, after each bootstrap read, at TCP handoff and when that queued handoff is consumed.
- Leave Off for 30 seconds and let the phone retry its saved Wi-Fi connection. It must not enter AA. A TCP arrival without an attributable live AA Bluetooth bootstrap is refused in T240; note any reconnect that worked in T230 but now fails.
- With per-device Both restored, try the separate global Wireless Android Auto switch off/on. Record it as a separate result.

## Collect

Unplug the phone. Restore Diagnostics USB to ADB and reconnect laptop if needed. Run the T240 Collect shortcut, enter COLLECT, and choose KEEP only if retaining daily setup is wanted; UNDO runs the existing persistent/grant undo. Wait for SAFE TO DISCONNECT. A collection result is not a functional PASS, and host source restoration does not reinstall the old APK.

Evidence must contain T240_SESSION_POLICY_STOP, the matching terminal session/socket-close path and T240_BOOTSTRAP_POLICY_RECONCILED; denied retries should contain the T240 policy refusal markers. Verify installed APK hash against candidate.json. Record observations in RESULT.md. No further car tests or feature changes are implied.
