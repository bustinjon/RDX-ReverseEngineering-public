# End-to-end review, 2026-11-11 (T310 state), by a Fable subagent

This is a read-only review: no device, build, git-state or key-material access. Claude saved it because the subagent's Write was refused, and spot-checked findings 1, 4, 5 and 7 against the source (all confirmed). Paths are relative to the repo root:
- `SRC` = `analysis/test-prep/todo-tests-20261103/builds/T310-bundle/source/analysis/parallel-aa-receiver`
- `APP` = `SRC/usb-helper/source/com/rdx/fullscreen/usbhelper`
- `SUITE` = `analysis/test-prep/todo-tests-20261103`

## 1. Executive summary
- T310 is fine for continued car testing. There is no crash or data-loss bug that should stop daily use.
- The wireless code saves what it changes before changing it, and restores at stop, at the next start and at boot.
- Main gap (laptop side): Collect's UNDO, and a future uninstall, can leave three of the car's Wi-Fi scan settings changed with no restore path.
- The final package is not close yet. Current source lives only in a test bundle, there is no setup tool or installer, and the scripts are tied to this laptop and this car.
- Wireless robustness holes:
  - A vanished Wi-Fi Direct group is never detected.
  - A dead Wi-Fi session ends only on the kernel TCP timeout.
- On a clean install, per-device wireless rules don't work as designed: the USB-to-Bluetooth link is recorded only while a default-off switch is on.
- Privacy is mostly good, with three gaps:
  - Two log lines can print a USB serial.
  - The Wi-Fi passphrase is shown on the main Settings page.
  - Three services accept commands from any app.
- The public mirror passed a spot check. The sanitizer relies on a fixed list of three device IDs.

## 2. Findings, ranked
| # | Severity | Finding | Confidence |
|---|---|---|---|
| 1 | BLOCKER (final package) / SHOULD-FIX | UNDO or uninstall can leave the car's Wi-Fi scan settings changed, with no restore path | High (code path); survival across a power-off UNKNOWN |
| 2 | BLOCKER (final package) | No canonical tree, no setup tool, installer or uninstaller; machine- and car-specific scripts | High |
| 3 | SHOULD-FIX | A vanished Wi-Fi Direct group is never detected; wireless stays "ready" but dead | High (code) |
| 4 | SHOULD-FIX | Default settings never link USB identity to the Bluetooth address, so every Bluetooth peer counts as the main phone | High |
| 5 | SHOULD-FIX | Three exported services accept commands from any app | High |
| 6 | SHOULD-FIX | Two log lines print USB serials; raw head-unit logs are untracked but not git-ignored | High |
| 7 | SHOULD-FIX | Wi-Fi name and passphrase are shown on the main Settings page | High |
| 8 | SHOULD-FIX | No app-level liveness check for Wi-Fi sessions | Medium |
| 9 | SHOULD-FIX | ServicePolicyTest.java is never compiled or run | High |
| 10 | SHOULD-FIX | Docs don't match reality (PROJECT-RULES roadmap, T310 test.json steps, class comments) | High |
| 11 | SHOULD-FIX | Git hygiene: overwritten tracked log, ~6 MB logcats tracked, 3,213 untracked files | High |
| 12 | SHOULD-FIX | About 600+ lines of dead and obsolete code and switches | High |
| 13 | SHOULD-FIX | Sanitizer redacts device IDs from a fixed list | Medium |
| 14 | NICE-TO-HAVE | Run-Test failure paths: misleading message, source left active | Medium |
| 15 | NICE-TO-HAVE | Diagnostics always on in everyday mode | High |
| 16 | NICE-TO-HAVE | Everyday retry has no back-off or de-duplication | High |
| 17 | NICE-TO-HAVE | Small robustness items (timeline receiver, decoder config race, restore counter, shutdown joins) | Medium |
| 18 | NICE-TO-HAVE | Host-test gaps on the wireless lifecycle and restore ordering | High |

## 3. Details and evidence

### 1. UNDO / uninstall leaves scan settings changed
- The scan settings are written at `APP/WirelessProbeService.java:945-966`. The only restore is `restoreScans` (`:967-977`), which needs WRITE_SECURE_SETTINGS.
- Collect force-stops the app (`tools/car-test/CarTest.Core.ps1:138`), which skips `shutDown()`.
- UNDO then revokes the grant (T310 `test.json` postCollectAdb). From then on the restore fails with "kept for retry".
- No laptop tool resets the keys. The restore has never been seen on the car (`builds/T300-bundle/RESULT.md`).
- Fix:
  - Stop wireless through the app first (it restores), verify the three keys, then force-stop, revoke or uninstall.
  - Add a laptop-side `settings delete` fallback.
  - Apply the same ordering to the paused networks and the channel request.

### 2. Release readiness
- The current source exists only as a 36-file overlay in T310. The baseline tree is from before T24: no WirelessProbeService, AppSettings or SettingsActivity, and AaSessionService has 670 lines against 1,760.
- The public mirror carries the old source.
- No setup-tool, installer or uninstaller code exists.
- `SUITE/tools/Build-Test.ps1:11-12` hard-codes the JDK and SDK paths, and the car's ADB serial is hard-coded in 20 or more scripts.
- `versionCode` is fixed at 1, and the video decoder name is hard-coded.
- Owner setup steps are undocumented: main-phone identity, `pm grant`, and Honda's Never setting.

### 3. Vanished group
- There is no receiver for P2P connection changes.
- `dailyWatch` heals only closed listeners, or a group that never came up (`:183-193`). `network` is cleared only by `shutDown()`.
- If Wi-Fi or the driver restarts, the app stays "ready" with stale details until Wireless AA off/on or a car restart.

### 4. Per-device rules on defaults
- The link is written only in `onPairingRequest` (`APP/AaSessionService.java:1034`). That code is registered only with announce or Wireless test on (`:863-866`), both default off.
- With no link, every Bluetooth peer is treated as the main phone (`HondaPhonePolicy.java:20-21`).
- The bootstrap listener is the insecure kind.

### 5. Exported services
- `OverlayTestService`, `AaOverlayService` and `AaSessionService` are exported with no permission (manifest lines 46, 53, 58). Any app can STOP, START_TCP, DIAG, or arm a capture.
- Fix: require DUMP (adb shell still works), and drop OverlayTestService.

### 6. Serials in logs
- `APP/UsbHelperService.java:775-776` and `:555-564`. 23 such lines are in archived head-unit logs, which are untracked and not ignored.

### 7. Passphrase on screen
- `APP/WirelessProbeService.java:695` sets `status` with the name and key, and `SettingsActivity.java:140` shows it on the main page. Move it to the Developer page or show it on request.

### 8. Dead sessions
- The TCP pipe has no read timeout, and the unrecoverable-error callback is only logged. Stuck protection is off for Wi-Fi.
- 20 sessions ended with ETIMEDOUT, 39-124 s after the last freeze.
- A parked test is needed: take the phone out of range and time it.

### 9. Unrun test
- `ServicePolicyTest.java` is not in `hostTest.sources` and is not called from BundleTests. It needs host-stubs.

### 10. Docs
- `PROJECT-RULES.md:24`: "T100 ... visit is next".
- T310 `test.json` steps mention a TEST-PLAN.md that doesn't exist.
- Stale comments: `WirelessProbeService.java:27-38`, `AppSettings.java:6-12`, `:86-90`.

### 11. Git hygiene
- `analysis/logs/car-test-20261028-1100.txt` is tracked and was overwritten by a later capture (HEAD 15,080 lines, working copy 18,314). This conflicts with evidence rule 3.
- About 15 tracked ~6 MB logcats sit under `analysis/parallel-aa-receiver/m5-retry-live-*`.
- There are 3,213 untracked files.

### 12. Dead code
- `variant` is always 4, which makes these dead:
  - nudge (`:475-510`, `:569-573`)
  - Honda reconnect (`:360-460`, `:564-568`)
  - the secure listener branch
  - `WIRELESS_VARIANTS`
- `startTcp` and `phoneServerAddress` have no callers.
- Boot blackout: the service and switch remain.
- "Wireless announce" has no button. "Wireless test" still has one and interrupts everyday wireless.
- Candidates:
  - the boot wait (operator turned it off)
  - the stutter fix and the channel-36 option
  - OverlayTestService, ReceiverActivity, ProjectionSession
  - BZONE/CAPTURE hooks and FocusCapture
  - the DIAG path
  - tryDirectGrant / tryForceStopHonda (not caller-checked)

### 13. Sanitizer
- Device IDs come from a literal list (`publication/update-20261110/prepare-update.cjs:12`, `audit-update.cjs:6`).
- There are no patterns for Wi-Fi names, Bluetooth names, 172.16-31 addresses or "serial=".
- Indented code fences are not stripped (13 public Markdown files contain them).
- The mirror spot check was clean. One third-party email address is present, source unchecked.

### 14. Run-Test failures
- `SUITE/tools/Run-Test.ps1:146-155`: a Collect failure prints a Prepare-style message with no warning that the source is still switched.
- An UNDO hook failure throws before Restore-Baseline (`:51` before `:83`).

### 15. Diagnostics in everyday mode
- The GAL ping is logged every second (`GalReceiver.java:88`).
- The freeze recorder and the timeline run on every Wi-Fi session.
- An auto-save is triggered on every call state change.
- READ_PHONE_STATE and FINE_LOCATION are needed only for diagnostics or tests.

### 16. Retry
- With Wi-Fi off, `P4_DAILY_RETRY` repeats every 30 s forever. Each extra startDaily adds another chain.

### 17. Small items
- The timeline receiver has no try/catch (`AaSessionService.java:1344-1354`).
- VideoDecoder config/configFed are not synchronized (`VideoDecoder.java:31`, `:44-52`).
- The restoreStation counter includes stale entries.
- `shutdown()` joins block the main thread (`AaSessionService.java:1666-1689`).

### 18. Host-test gaps
- Not covered:
  - the onStartCommand state machine
  - save/change/restore ordering
  - dailyWatch
  - accept/stop races
  - the AudioSink play loop
  - shutdown

## 4. Recommended next steps, in order
1. Fix the UNDO order and add a laptop-side scan-key check and reset. Confirm `T300_SCANS_RESTORED 3/3` with the T310 off/on step.
2. Promote T310 to the baseline once drives are clean.
3. Next bundle, as small separate changes: group-loss detection, always link USB to Bluetooth on wired sessions, DUMP on the three services, serial-free log lines, the passphrase off the main page.
4. Parked out-of-range test (finding 8).
5. Wire in or delete ServicePolicyTest, and add lifecycle host tests.
6. Cleanup bundle: dead code, and one switch for diagnostics.
7. Update PROJECT-RULES.md and the T310 test.json steps, decide on the overwritten log (operator authorization), and add ignore rules for raw captures.
8. A pattern-based sanitizer.
9. Final package: parameterise the serial and paths, write the uninstaller and restore-stock, build the setup tool against fake fixtures, run the clean-install test, write the user guide.

## 5. Coverage
- **Read in full:** PROJECT-RULES, AGENTS; T310 WirelessProbeService, AaSessionService, AppSettings, SettingsActivity, HondaPhonePolicy, PersistentMode, PersistentBootService, BootBlockerReceiver, HelperActivity, AudioSink, VideoDecoder, GalReceiver, the manifest; Run-Test, Build-Test, Switch-Source, the T310 Collect-Test, test.json, VISIT.md, the publication scripts.
- **Searched only:** UsbHelperService, AaOverlayService, PermissionClickService, the tests, CarTest.Core, the public mirror, saved logs.
- **Not inspected:** AaMediaSourceService, HondaNavBridge, InputEvents, AbsoluteTouch, VideoSink, SensorSource, UsbBulkTransport, Prepare-Test, New-TestPackage, Publish-Update, the Codex reviews, the M4-M7 tooling, the native library and key material.
- Nothing was run.
