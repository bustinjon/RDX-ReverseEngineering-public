# Start here with Codex

[Public diagnostic APK](downloads/headunit-diagnostics-0.1.0.apk?raw=true) · [Diagnostic instructions/source/build](diagnostic-app/README.md) · [Current findings](CURRENT-FINDINGS.md) · [Porting guide](PORTING.md)

The diagnostic APK is ready to download and rebuild. It checks local display/input/audio behavior only. It does not authenticate or project Android Auto. The working receiver still requires separately supplied native/protocol prerequisites and target-specific qualification.

Copy this into a new Codex session:

```text
Use https://github.com/bustinjon/RDX-ReverseEngineering-public to learn the research and help me test my own head unit and build an APK locally.

Read START-HERE.md, diagnostic-app/README.md, README.md, CURRENT-FINDINGS.md, LATEST-TEST-PLAN.md and PORTING.md first. Distinguish the latest offline-tested candidate from previous car observations and unknowns; the v5 procedure is historical.

Begin with the public diagnostic app. Review DiagnosticActivity.java, AndroidManifest.xml, Build-PublicDiagnostic.ps1 and the distributed build report. It tests local display geometry, raw input and a short tone; it is not an Android Auto receiver. Ask for my car model/year, head-unit firmware/API level, phone model, host OS and installed SDK/JDK tools. Explain what the APK can establish on my target.

Help me build/sign the diagnostic APK using my own local signing identity. Keep its password and key out of chat, logs and Git. Verify APK hash, signature, permissions and archive contents. Preserve the original source in a separate branch/directory, document changes and run applicable host tests. Do not claim hardware success from compilation.

For a full receiver, inspect usb-helper/source and shared src, Build-RdxUsbHelper.ps1, VideoGeometry, AaOverlayService, InputEvents/InputSource, AudioFocusPolicy, GalReceiver, AudioSink, readiness checks and cleanup watchdog. Effective helper sources override shared sources by basename.

The public repository excludes private protocol credentials and proprietary native libraries. Inventory the exact missing prerequisites for a functioning Android Auto build and explain what I must independently provide. Do not invent credentials or reuse another person's private material.

Do not assume the original car's serials, packages, binder transaction numbers, geometry, event behavior or audio routing apply to mine. Published dummy serials are placeholders. Qualify target details from my own evidence and preserve identity/readiness checks; do not add bypasses.

Do not run ADB, install or launch apps, change car/phone settings, replace factory apps or start live tests until I authorize the specific action. Plan parked, bounded tests with evidence collection and restoration. Give complete instructions at the connection cue, collect logs afterward, and verify cleanup before telling me to disconnect.

Maintain a concise handoff listing evidence paths, findings, source changes, artifact hashes, test results, missing prerequisites and the next authorized step.
```
