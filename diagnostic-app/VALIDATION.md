# Public diagnostic 0.1.0 validation

## 1. Files inspected

DiagnosticActivity.java, AndroidManifest.xml, Build-PublicDiagnostic.ps1, generated build-report.json and final APK archive entries. Existing repository publication manifest and preservation anchors were also checked locally.

## 2. Files changed

New standalone diagnostic activity, manifest, build script, instructions, START-HERE Codex handoff, downloadable APK and build report. README and public .gitignore updated to identify the single allowed diagnostic APK. Existing receiver implementation and private APKs unchanged.

## 3. Commands run

JDK 17 javac/jar, Android D8/aapt/zipalign/apksigner, a new independent test signing identity, archive-entry checks, source/APK/DEX hash and sensitive-marker checks. Local publication scanning and PowerShell parsing. Explicit Git staging/commit/push in the separate public snapshot only. No ADB or device commands.

## 4. Tests run and results

- API 21 minimum / target 22 compile, DEX, packaging: PASS.
- Signature verification for API 21 and alignment: PASS.
- Manifest requests no permissions: PASS.
- Archive contains only AndroidManifest.xml, classes.dex and signing metadata: PASS. No assets/native libraries/credential files.
- Source hashes match compiled manifest and Java source, recorded in distributed build report.
- Exported APK SHA-256: `6727EA2DBBD93F19E477DC9467573ADFCE50A9081C1B889BE771C31E03718473` (16,731 bytes).
- Android runtime and physical head-unit behavior: NOT TESTED. Compile/static checks do not establish UI/tone behavior on a particular device.

## 5. Findings

A public, independently authored diagnostic APK can be shared without the private receiver's protocol material or vendor native library. It provides local display/input/tone observations; it does not establish a full Android Auto connection.

## 6. Primary evidence

[Distributed build report](../downloads/headunit-diagnostics-0.1.0-build.json) lists hashes, archive entries, permission output and verification flags. Manifest contains no uses-permission, services or receivers. Activity source shows foreground controls, bounded in-memory event buffer, user-requested clipboard copying, tone stop on pause/destroy and 120-second finish callback.

## 7. Assumptions

Target supports API 21+, standard activity launch and relevant public Android UI/audio APIs. OEM-specific launch or audio policies may reject or alter behavior.

## 8. Unresolved uncertainties

Head-unit installation/launch compatibility, physical input delivery, tone audibility/routing and actual timeout/lifecycle behavior need an owner-authorized hardware test. No claim of universal compatibility or automatic Android Auto support.

## 9. Exact diff summary

Add separate package `org.rdxresearch.diagnostics` with grid/circle/input reporting, 350 ms local tone, report/copy/exit controls and automatic finish. Add standalone source build and one downloadable test APK. No credential substitution, OEM app replacement, private helper modification or expanded receiver functionality.

## 10. Preservation checks

Four original frozen artifact hashes checked unchanged locally. Original repository stays private. No original signing identity, private keys/passwords, protocol credentials, vendor binaries or private Git history copied. Diagnostic signing private material remains in ignored local build storage; only the signed APK/public certificate is published. No readiness-guard change or milestone action.
