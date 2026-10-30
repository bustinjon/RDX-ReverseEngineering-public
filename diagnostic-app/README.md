# Public Head Unit Diagnostics 0.1.0

[Download APK](../downloads/headunit-diagnostics-0.1.0.apk?raw=true) · [Build report](../downloads/headunit-diagnostics-0.1.0-build.json) · [Source](source/org/rdxresearch/diagnostics/DiagnosticActivity.java)

SHA-256: `6727EA2DBBD93F19E477DC9467573ADFCE50A9081C1B889BE771C31E03718473`.

This is an independent foreground diagnostic activity, not an Android Auto receiver. It is built from the source in this directory and contains no native libraries, assets, protocol credentials or original project signing identity. It requests **no permissions**, has no services/receivers, does not contact the network or USB devices, and does not read device identifiers, Bluetooth addresses, accounts, microphone or external storage.

## What it tests

- Display: grid, border and circle in the activity's available content area. That area excludes the test controls; it is not the entire negotiated Android Auto video area.
- Input: raw touch, hover, generic-motion action, pointer/button counts, key/scan codes and view coordinates. It does not inject input or change OEM input routing.
- Audio: user-requested 350 ms tone through local STREAM_MUSIC at a low relative level. Audio focus must be granted. System volume is not changed; API acceptance alone does not establish audible speaker output.
- Report: last 120 in-memory events with relative timing. View the report or explicitly copy it to the clipboard. No automatic upload or persistent log file.

Back/Exit closes normally. The activity also finishes after 120 seconds. Tone playback is stopped and focus abandoned on pause/exit. It does not replace the original car's two-minute helper watchdog or qualify any live Android Auto milestone.

## First test on an owner-authorized, parked head unit

1. Record the car/head-unit model, firmware and Android API level separately. APK requires API 21 or newer.
2. Review the source and build report, verify the downloaded APK hash, and obtain the owner's approval for installation and launch. Package is `org.rdxresearch.diagnostics`; it installs separately from the private receiver helper.
3. Launch **Head Unit Diagnostics** using the head unit's normal app-launch method. Do not replace a factory application or alter lock-task/security settings to make it launch. If the platform refuses it, preserve that finding.
4. Check the circle, border and grid; note clipping/stretching. Move the touchpad, physically press/release, and try ordinary navigation keys. Open Report to see the event distinctions.
5. At an ordinary listening volume, tap **350 ms tone**. Report whether it is audible and what audio source was selected. This tests local head-unit playback; it does not test Android Auto PCM transport or isolate the phone's Bluetooth audio path.
6. Copy the report before the 120-second timeout if needed, review its contents before sharing, then exit. Backgrounding/stopping this activity stops the tone. Remove the app through the normal installation mechanism if desired.

Compile/sign/archive checks passed on the build host. **Hardware behavior has not been tested.** No compatibility claim is made for another car's launcher, focus manager or display/input stack.

## Build your own APK (Windows, PowerShell 7)

Install JDK 17 and Android SDK platform/build tools from their normal sources. The build does not download dependencies or invoke ADB. Defaults are platform `android-33`, build tools `32.0.0`; pass the matching parameters for installed versions.

```powershell
$env:JAVA_HOME = 'C:/path/to/jdk-17'
$env:ANDROID_SDK_ROOT = 'C:/path/to/Android/Sdk'
# Set RDX_DIAGNOSTIC_SIGNING_PASSWORD privately to your own new signing password.
# Do not put it in commits, chat messages, command transcripts or shared reports.
./diagnostic-app/Build-PublicDiagnostic.ps1
```

Your signing keystore stays under ignored `diagnostic-app/build/local-signing/`. Keep the keystore and password privately if you need to sign updates with that identity. The build emits APK, source hashes and audit report under a timestamped ignored build directory. A locally rebuilt APK normally has a different signature/hash. The distributed APK uses an independent public-diagnostic test signing identity, not the working receiver's identity.
