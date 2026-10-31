# Current-condition long-drive build — 2026-10-31

## 1. Files inspected

`PROJECT-RULES.md`; the current Down-motion-only candidate/build report and preparation script; `scripts/Build-RdxUsbHelper.ps1`; `scripts/Run-CarTest.ps1`; `scripts/device-car-test-watchdog.sh`; `tools/car-test/CarTest.Core.ps1`; current helper Java inputs, especially InputEvents, AaSessionService, FocusCapture and FocusCaptureBudget; previous collection implementation; public entries of the current and new APKs; the 15 preservation artifacts recorded in `before.json`. No key material was inspected.

## 2. Files changed

Added this `analysis/test-prep/long-drive-20261031/` preparation/report directory and its generated evidence. Built a new directory, `analysis/parallel-aa-receiver/usb-helper/build/20261031-131813-848/`, and the standard builder updated `usb-helper/latest-build.txt`. No Java, manifest, native code, shared runner, M5 guard, or historical report was edited. No installation occurred.

## 3. Commands run

Saved procedures executed: `Build-LongDrive.ps1`, `Generate-TimedStage.ps1`, `Test-WatchdogDisarm.ps1`, `Validate-LongDrive.ps1`. The builder invokes the existing signing pipeline opaquely. Validation invokes `scripts/Run-CarTest.ps1 -Mode Prepare -CandidateRole CurrentSource -HondaStrategy PhonePreference` with a nonexistent ADB path; it cannot connect in this mode. Read-only commands included Get-Content, rg, Get-FileHash and public ZIP-entry SHA-256 calculations. A brace-expanded rg path was rejected by PowerShell parsing and replaced with ordinary rg file filters; no device action resulted. One guessed validation filename and one guessed build-output path did not exist; existing evidence paths were used instead.

## 4. Tests run and results

`validation.json`: PASS, all 27 recorded Java hashes unchanged; all seven non-signature APK entries byte-identical to the preceding current APK; all 15 preservation artifacts unchanged. Build report and build-directory signature/alignment verification record API22 signature and alignment PASS. PowerShell files parse; four device shell payloads pass Bash syntax and LF/no-BOM checks. Nine simulated watchdog ownership fixtures pass, including PID reuse, invalid paths, malformed/system PID and refusal to stop. Fixture kill/sleep functions signal no actual host or device process. Offline current-source/cooperative-phone artifact plan passes. No Android execution or multi-hour test occurred; untimed handoff, shell behavior on the target, manual collector, and stability remain hardware UNVERIFIED.

## 5. Findings

- The short test's end is imposed by its external 180-second watchdog. A new APK alone would still be stopped by that old preparation. The new wrapper completes ordinary readiness first, verifies/stops only that run's owned timer, then declares untimed READY. It does not change the M5 readiness guard.
- New APK: `rdx-usb-helper-v6h-longdrive-current-a.apk`, SHA-256 **D1A29B34812B2C3188C57C840DB1DE4F44E1362FF8BD8E3D9A52B1317EDABCE4**. The APK container hash differs from the previous build, while the executable/resource/native/manifest payload is identical. Current input behavior, including raw146 Down key-pulse suppression and the unresolved Spotify row issue, remains the test condition.
- Long-drive diagnostics rotate instead of accumulating an unbounded logcat file. They do not stop/restart the app. The logcat ring targets eight 4096 KiB files (nominal 32 MiB), with additional fixed preparation/early-rotation logs and bounded health files. This is not a total-device-storage cap. Minute samples track the original helper PID; they do not follow or recover a restarted process.
- Manual collection saves logs before cleanup, retains all ring-file hashes, pulls the installed APK and available private focus images, and verifies accessibility restoration/helper termination. Ownership checks tolerate historic PID reuse without signalling unrelated processes. Collection cannot claim success if the accessibility baseline has changed externally.
- The two-minute screenshot budget ends sampling, not AA. See `ERRATUM.md` for the correction to earlier analysis.

## 6. Primary evidence for each finding

- Timeout: `scripts/device-car-test-watchdog.sh:12–13` sleeps then invokes cleanup; `Prepare-TimedStage.ps1:123` requests 180 seconds. Untimed conversion: `Prepare-LongDrive.ps1:33–66`, with watchdog ownership logic in `disarm-own-watchdog.sh` and saved fixture outcomes in `clock-ownership-tests.json`.
- APK parity/preservation: `candidate.json`, `before.json`, `validation.json`, `apk-public-entry-hashes.json`, and empty `apk-entry-differences.json`. Prior current APK SHA-256 **28659795FC5228988FB56E0D006328DE0D13F65421560C27DFCEB28CDDF8367A**. Input suppression: `analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/InputEvents.java:25`; live pad registration: `AaSessionService.java:304`.
- Readiness unchanged: `stage-provenance.json`; generated timed stage substitutes only pinned APK path/hash and profile label in the previous preparation. No guard bypass option was added.
- Logging: `configure-untimed.sh:25–40`; `longdrive-monitor.sh:19–45`. Cleanup and PID ownership: `collect-owned-processes.sh:10–40`, `Collect-LongDrive.ps1`, and existing cleanup generation in `tools/car-test/CarTest.Core.ps1:131`.
- Screenshot correction: `FocusCapture.java:37–46`, `FocusCaptureBudget.java:4–15`, paths as in section 1.

## 7. Assumptions

User requests the exact current app condition for a longer run, including unresolved compact Spotify focus behavior. The next explicitly authorized live preparation uses the previously tested head unit, phone preference, firmware and USB/menu procedure. The old short-run scripts remain timed deliberately. Manual-duration authorization does not authorize device commands in this offline build turn.

## 8. Unresolved uncertainties

Multi-hour stability is UNKNOWN. An external watchdog removal is not proof that every native/library/lifecycle failure or timeout has been excluded. Current I/O/startup failure deadlines remain. Target support and operation of rotating logcat, detached monitor, manual cleanup and image pulling require connected validation before relying on the run. The monitor is additional diagnostic load, with no recovery logic. Earliest-rotation retention is best effort; if the monitor fails, its copy may be absent. Mid-session detailed logs may be overwritten. Full static audit remains PENDING as recorded by the builder; offline checks do not confer production readiness.

## 9. Exact diff summary

App-code diff versus prior current candidate: **zero**, confirmed through 27 source hashes and seven identical public APK-entry hashes. New files comprise build/generation/validation fixtures, a wrapper and generated unchanged-readiness timed stage, four shell payloads, a manual collector, candidate/provenance/validation evidence, this report, `NEXT-DRIVE.md` and `ERRATUM.md`. Existing shared timed scripts and guard files have no task edits. Generated build output and latest-build pointer are the normal builder outputs; no Git staging/commit/push occurred.

## 10. Preservation checks performed

All 15 prior/frozen artifact hashes match their before snapshot, including the frozen M5, M6, receiver DEX and TLS qualifier. All 27 Java input hashes match before and the previous candidate. New APK hash matches candidate metadata. Preserved files were not rebuilt. See `validation.json` for per-file hashes. No ADB, fastboot, phone/car/USB interaction, milestone advancement, or key inspection occurred. Operator instructions are in `NEXT-DRIVE.md`.
