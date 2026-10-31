# Current candidate and independent review

The latest authored source checkpoint is **v6h-media-input-a**. It is an offline-tested candidate, not a successful car result. The earlier Maps-only candidate and the previous drive are documented separately in the research reports.

## What changed

- Navigation focus now replies with the requested valid protocol state:1=native,2=projected. Requests/replies/rejections are logged.
- Track-button adapter handles the observed Honda138/scan66/source257 -> Previous88 and139/scan67/source257 -> Next87, plus standard87/88. Recognized events are consumed; one balanced pair is sent on an owned noncancelled release. Repeat/orphan releases do not generate extra skips. Long-press seek and unseen steering-wheel paths are not implemented.
- Volume indicator listens to the OEM amplifier feedback action used by the inspected SystemUI, with its byte payload. It displays actual received values temporarily within AA. It does not adjust volume, estimate values, change global window ordering or provide an OEM dialog patch.
- Spotify comparison restores ordinary PageDown and enables factory-matching absolute touchpad navigation. The declared key set is `[4,23,87,88,92,93,122,123]`. This is a hypothesis-driven input-profile comparison; no claim of a Spotify cure is supported yet.

## Offline checks anyone can run

With PowerShell7 and JDK17 on PATH:

```powershell
./tools/car-test/Test-PublicInputPcm.ps1
./tools/car-test/Test-PublicReceiverChanges.ps1
```

The first preserves PCM/audio-policy checks and verifies the current input contract. Its large assertion total includes repeated per-byte checks. The second runs77 actual pure-Java media/input/volume checks and10 navigation-focus requests using a fixture that replaces only the native reply endpoint. Neither needs receiver credentials/native libraries or performs device actions.

## What a qualified car comparison must establish

After independently qualifying the target and obtaining explicit authorization, compare basic movement/Select/Back, compact Spotify title-to-playback traversal, physical and steering-wheel Next/Previous separately, actual amplifier-feedback reception/indicator visibility, and two Maps routes remaining active beyond90 seconds. Record input signatures and route timing; keep other settings stable. Save evidence before cleanup and verify restoration. Do not infer phone acceptance from a local native return alone.

The original test setup supports an explicitly selected untimed session with rotating logs and manual cleanup, after ordinary readiness checks. Original target-specific preparers/evidence prerequisites are not a portable installation flow; dummy serials and historical numeric transaction values must not be reused or bypassed for another car. Begin with PORTING.md and the credential-free diagnostic app.

## Available APK

The existing [public diagnostic APK](downloads/headunit-diagnostics-0.1.0.apk?raw=true) remains unchanged. It tests local display/input/audio and does not project Android Auto. The current authenticated receiver APK is excluded because it bundles separately supplied protocol material and a vendor native library. Review the public source, identify prerequisites, and build independently only after target qualification.
