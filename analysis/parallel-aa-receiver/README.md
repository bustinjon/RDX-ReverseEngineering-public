# Parallel Android Auto receiver — current index

Start with [INDEX.md](INDEX.md), [OFFLINE-FOUNDATION-FREEZE.md](OFFLINE-FOUNDATION-FREEZE.md) and [PROJECT-STATE.json](PROJECT-STATE.json). Next LIVE **M5 RETRY ONLY**;M6disabled until M5PASS plus separate authorization. API22 runtime remains unavailable. The frozen qualifier is emulator-only and must not be installed on the vehicle.

# RDX parallel Android Auto receiver — local experimental build

**Latest live result:** [test02](LIVE-TEST-02-RESULTS.md) resolved diagnostic lock task through normal RETURN UI and passed M0/M1/M2 using an [isolated synthetic-only revision](live-test-02/prototype/README.md): UID10050/untrusted_app, Surface1339x720, clean exit/uninstall. Original receiver-capable source/APK below remains unchanged and its native stages untested. M3 deferred; no constructor-safe load-only probe was established. Factory code/package preserved; normal Honda lifecycle preference setter observed, so do not claim all Honda private data untouched. [Current next plan](NEXT-LIVE-TEST.md).

Package `com.rdx.fullscreen.projection`, version0.1.0-experimental-offline, minSDK21/targetSDK22, ARMv7, DEX035. New development signer; no shared UID or Android permission requests. No original Honda app DEX/resources/components are packaged. Stock AndroidAuto.apk and Candidate A/B are untouched.

**Historical live test01:** original0.1.0 ordinary install/removal passed as UID10049; Activity launch was blocked by existing Honda Diagnostics Lock Task Mode before process startup. Its Surface/native/GAL/USB/decoder stages did not run. [Results](LIVE-TEST-01-RESULTS.md). The package is currently uninstalled. This is a staged diagnostic/receiver prototype, not a proven working Android Auto app.

**Keep this directory/APK local.** It includes an unchanged proprietary receiver library and a binary asset containing existing head-unit protocol credentials for same-unit research. Private credential contents are not included in README/reports/logs. The development APK signing key is independently generated and is not an OEM signing key.

## Contents

- [AndroidManifest.xml](AndroidManifest.xml): one ordinary launcher Activity, no receiver/service/provider, no shared UID, no permissions. Touchscreen/USB-host features optional. Native and USB startup are manual.
- [Source](src): small public-SDK Activity/Surface/USB/MediaCodec implementation and Google-named JNI facades. No Honda framework/API imports.
- `libs/armeabi-v7a/libautoreceiver_jni.so`: unmodified current library, SHA256 `031797DD4B0AECCA007A3AD7AF31C365BA3D47BEBDA8C94BFF13C5289F464C50`.
- `assets/private-test-material/platform.creds`: sensitive binary protocol credential container; do not publish. The build extracts only the actual static platform provider values, not unrelated fallback/test keys.
- `signing/rdx-parallel-development.p12`: local DEVELOPMENT/TEST APK-signing key. Alias rdx-parallel-development. Test-only password and creation command are in the build script. Do not use it for any production identity.
- [Signed APK](build/rdx-parallel-aa-0.1.0-development.apk), [build report and hashes](build/build-report.json), [API22 signature verification](build/signature-verification.txt), [badging](build/badging.txt), compiler/D8/aapt/signing logs.
- [Static JNI/manifest validation](evidence/prototype-static-validation.json), [final host validation](evidence/final-validation.json), [credential metadata without private contents](evidence/protocol-credential-metadata.json), [runtime milestone status](milestones.json), [artifact hashes](hashes.json).
- [Read-only observations](evidence/device/commands.json) and native/permission evidence under evidence/. Raw device dumps can contain incidental identifiers/public ADB-key metadata; do not repost them unnecessarily.

## Offline build / validation

From project root:

[Code block omitted from public report; see authored source where available.]

Local tools only: Java17 at installed Adoptium path, Android SDK build-tools32, public android-33.jar, Java7 class output and D8 min-api21. No Gradle/network dependency. CompileSDK33 is a local build choice, not a requirement for the API22 device. APIs used by source are public API21/22 methods; runtime is not proved by host compilation.

Signatures verify for API22 using v1/JAR. Development signer SHA256 is in build-report.json and differs from Windriver. Native library is byte-for-byte compared inside the APK; JNI class/method/field/callback compatibility is compared with original DEX. No ARM library was run on the host or vehicle.

## Stage controls

| Control | Intended future behavior | Current evidence |
| --- | --- | --- |
| Default launch | L1 synthetic TextureView Surface, UID/API/ABI/geometry log. No native load, decoder allocation or USB access. | Launch attempted; Lock Task Mode error5 prevented process creation. Surface not reached. |
| L1 inventory / `--es stage inventory` | List TI decoder capabilities and allowed AOAP device presence/grant status only. | Source implemented; not run. |
| L1 TI allocate/release | Allocate named TI decoder, release immediately; no configure/start/feed. | Source implemented; not run. |
| L2 native only / `--es stage native` | Explicit local load, native GAL/SSL credentials and video-service configuration. No USB start or decoder allocation. |22 native signatures/19 callbacks/16 fields/buffer-pool descriptors checked on host; dynamic success unknown. |
| L3 USB grant | Request ordinary per-device system permission; no automatic open. Permission dialog may pause/clean L2, so reinitialize afterward. | Public framework path and UI classes identified; not requested. |
| L3 start AOAP | Only allowed Google AOAP VID/PIDs/interface0; open/claim(false), then protocol threads. | Implemented, but ownership/routing/phone success unproved. Not a ready phone test. |
| Stop/Exit/background | Close our transport, prepare native shutdown, bound joins, release own decoder/native objects after workers stop. Retain objects rather than free under live threads if timeout occurs. | Teardown not demonstrated; own-package stop/uninstall is the future fallback. No stock stop/reset. |

No USB attach/boot receiver, default-app chooser claim, mode-switch control transfers, forced claims, reset socket, Honda Binder methods, settings/properties, vehicle IDs, or stock-package data operations exist in the prototype. It does not implement audio/BT/navigation/voice/vehicle/input forwarding. Input events are logged locally only.

The video service has Candidate A first: active1920x720,229dpi,60fps, encoded profile enum3/1920x1080, margins0/360, index0. Original fallback800x430/143dpi/60fps remains index1. Numeric values match stock schema. Real DPI comes from own resources. A locally added config is not advertised/selected until a phone session proves it.

## Known limitations before any phone test

- No AOAP conversion is implemented. A normal non-accessory phone is never opened or switched. This avoids hidden bus/TCU access and re-enumeration changes but leaves initial connection setup unresolved.
- Stock auto-start/claim/reset can race a custom receiver. A busy non-forcing claim aborts; permission does not grant exclusive ownership. Foreground selection alone does not disable Honda's broadcast receiver.
- Video-only service discovery may be rejected by the phone; standard input/audio endpoints may be needed later. Do not import Honda integration by default.
- Dynamic JNI, native SSL, worker shutdown, decoder allocation/configuration, H264 framing/SPS/crop and actual visible video are untested. Synthetic pixels and host ABI checks do not prove these.
- Decoder uses declared codec raster then logs actual output crop; TextureView fits observed aspect ratio. No arbitrary360px crop/stretch is forced. Hardware capacity/shared decoder resources can fail.
- Stock policy may provide1339x720. Full1920x720 needs separate window evidence/optional display experiment. The APK contains no overscan command. Overscan writes persistent display_settings.xml and must be independently restored.
- Normal app may be stopped by OEM power/state transitions. No Honda prefix impersonation or persistence service is used.

## Future test and rollback

The [original plan](../PARALLEL-AA-FIRST-LIVE-TEST.md) was attempted under explicit authorization; normal install and uninstall passed but default launch was blocked before app startup. Review [NEXT-LIVE-TEST.md](NEXT-LIVE-TEST.md) for a separately bounded repeat after normal diagnostic exit. Existing L2 also initializes GAL, so it does not qualify for load-only M3. Native initialization, codec allocation, phone access and overscan remain separate decisions.

The eventual normal cleanup target is `com.rdx.fullscreen.projection`. It is never the factory package. App uninstall does not restore global overscan or undo Honda's own natural USB bookkeeping; full phone coexistence is not yet ready to test.
