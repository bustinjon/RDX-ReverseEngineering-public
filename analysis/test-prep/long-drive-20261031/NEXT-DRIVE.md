# Untimed current-condition drive

APK: `analysis/parallel-aa-receiver/usb-helper/build/20261031-131813-848/rdx-usb-helper-v6h-longdrive-current-a.apk`.

Use `Prepare-LongDrive.ps1` in this directory when the head unit is connected by ADB and live preparation is explicitly authorized. **Do not run Prepare-TimedStage.ps1 alone or use the old short-test preparation:** those still schedule cleanup after 180 seconds. The APK itself has the same code as the current Down-motion-only candidate.

1. Park, leave the phone unplugged, put the Honda screen on Home, and connect the laptop to the head unit for ADB. Keep the existing per-phone Honda Android Auto setting disabled as in the successful helper tests.
2. The operator runs `pwsh -File analysis/test-prep/long-drive-20261031/Prepare-LongDrive.ps1`. It performs the existing readiness checks, installs/verifies the APK, confirms the permission auto-clicker, then removes this run's scheduled cleanup and starts rotating diagnostics.
3. Wait for **READY — untimed long-drive session; no scheduled cutoff**. A NOT READY message means preparation failed; do not switch to the phone for that attempt.
4. Disconnect the laptop's ADB connection. Use the same Honda USB mode/menu procedure as the preceding tests to select Android Auto, return Home if that procedure requires it, then connect the phone to the car USB port. Permission prompts should be handled by the existing auto-clicker. Keep the prior audio settings for a comparison in the current condition.
5. Use AA normally for the drive. The known Spotify compact-card bottom-row navigation issue remains. Note any disconnect, frozen video, lost input/audio, or unusual delay and the approximate elapsed drive time. No navigation retest sequence is required for this stability run.
6. When finished, unplug the phone normally. Reconnect the laptop for ADB and authorize collection. The operator runs `Collect-LongDrive.ps1` in this directory to save evidence, stop diagnostics/helper, and restore the recorded accessibility baseline. Wait for **SAFE TO DISCONNECT** before removing ADB.

There is no scheduled session cutoff after the untimed READY cue. Normal disconnects, transport errors, process termination, or ignition/reboot can still end the session. This is not an auto-reconnect or reboot-persistence test implementation.

Diagnostics retain a nominal 32 MiB rotating log tail, a separately retained early rotation, the preparation log, and bounded minute-by-minute memory samples. Middle log history can be overwritten. Existing image capture samples only the first two minutes; it does not record the full drive. Collection writes private vehicle/phone evidence under the run directory; it is not a public release artifact.
