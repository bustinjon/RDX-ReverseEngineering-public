# RDX Android Auto fullscreen research

Public research snapshot, updated 2026-11-05. Start with [START-HERE.md](START-HERE.md) for the public diagnostic APK and Codex handoff, then [current findings](CURRENT-FINDINGS.md) and the [porting guide](PORTING.md). No private-repository history is included.

The latest bounded experiment on one Honda/Acura Android 5.1.1 head unit displayed Android Auto with corrected geometry, accepted touchpad movement and physical select presses, and played audio while the phone's Bluetooth **Media audio** option was disabled. These are operator-reported outcomes supported by the receiver's input and PCM diagnostics. They do not establish compatibility with another model/year, a production-ready receiver, or an internal hardware audio-route trace.

On November 4 the receiver was car-tested one change at a time on that unit. Working with the receiver on screen: reverse camera, Bluetooth calls, Maps routes, navigation voice, Assistant (on-screen mic and hotword), console track buttons, day/night map colours, and reconnect on replug. Not possible on this unit: steering-wheel buttons, because that OEM signal needs a system permission. Since then, Home minimizes AA and a side-panel button brings it back, a volume display works, and a ~25 min drive ran without a drop-out. Still open: laptop-free start after power-off (the head unit resets accessibility). See [current build, results and to-do](LATEST-TEST-PLAN.md).

## What is included

- Project-authored Java JNI facades, video geometry/decoder integration, overlay, USB helper, permission click service and PCM playback.
- PowerShell/shell host tools, readiness checks, cleanup watchdog and host tests.
- Sanitized research reports and implementation reviews. Reports are historical and may describe superseded approaches; current findings distinguish tested results from the latest untested candidate.
- Latest test instructions and sanitized result reports under `analysis/test-prep/`.
- [PUBLIC-MANIFEST.json](PUBLIC-MANIFEST.json), with SHA-256 values for exported project files.

## What is deliberately absent

The only included APK is the separately authored, credential-free [public diagnostic app](diagnostic-app/README.md). The working Android Auto receiver APKs remain excluded, along with proprietary native libraries, firmware/framework/APK dumps, bulk decompiled source, protocol credentials, keystores/private keys, signing passwords, raw car/phone logs, photos, and private Git history. Report code blocks were omitted because some quote vendor decompilations. Code intended for analysis is supplied in the authored source trees instead. References to local-only evidence may therefore lead to unavailable paths.

Device serials in exported text/code are dummy values: head unit `00000000`, phone `11111111`. Personal Windows user paths and MAC/LAN addresses were sanitized. These are publication substitutions, not valid target settings. Do not weaken identity or readiness checks to run a different car.

## Reading and host checks

The effective helper Java sources are under `analysis/parallel-aa-receiver/usb-helper/source/`, overriding shared Java files by basename during the existing build. Shared sources are under `analysis/parallel-aa-receiver/src/`.

Run the portable input/PCM host test (JDK 17 required):

```powershell
./tools/car-test/Test-PublicInputPcm.ps1
./tools/car-test/Test-PublicReceiverChanges.ps1
```

The public copy was tested after export. Other historical scripts retain environment-specific paths and may depend on withheld local evidence. They are provided for analysis, not as an automatic procedure for an unidentified car.

## Builds and signing

The helper build requires Android SDK/build tools and local private prerequisites that are not distributed: compatible receiver native library and independently authorized protocol credentials. This repository alone cannot produce a functioning authenticated receiver APK. Obtain and assess those prerequisites separately; do not share another person's credentials.

Sanitized build tools take a new local signing password from `RDX_SIGNING_PASSWORD`; no original signing material is included. The published source differs from the private tested APK because identifiers, signing configuration and report content were sanitized. Build-source hashes from private reports are historical, not hashes of these exported files.

No license grant has been added on behalf of third parties. Vendor code/binaries remain excluded; project licensing has not yet been selected by the owner.
