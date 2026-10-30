# Local API22 runtime inventory — 2026-10-24

**Selected path E: saved target Conscrypt implementation; no runnable API22 environment found. API22 RUNTIME TEST UNAVAILABLE.** No emulator or physical device was contacted, and ADB was never executed. Nothing was downloaded.

Machine-readable inventory: [runtime-inventory.json](api22-qualification-20261024-155013-513/runtime-inventory.json). Reproduce with `scripts/Review-RdxApi22Provider.ps1 -Session <existing evidence directory>`.

|Location / asset|Result|
|---|---|
|ANDROID_HOME / ANDROID_SDK_ROOT / ANDROID_AVD_HOME|Unset in this session|
|Installed SDK|`C:\Program Files (x86)\Android\android-sdk`|
|Platforms|android-33 revision3 and android-34 revision2; no android-22 platform|
|Build tools|32.0.0; existing javac/D8/dexdump used locally|
|Command-line tools|7.0; no sdkmanager/network query performed|
|Platform tools|Present, including adb.exe; not executed|
|SDK emulator directory / emulator binary|Absent|
|SDK system-images directory / API22 system image|Absent|
|`C:/Users/REDACTED\.android\avd`|Present but empty|
|Android under AppData\Local; C:\Android; C:\AndroidSDK|Absent|
|Local Gradle caches|No `C:/Users/REDACTED\.gradle\caches`|
|VirtualBox|Program installed; VM directory empty; registration points to missing Ubuntu\Ubuntu.vbox, not an Android runtime|
|Other checked VM locations|Genymobile, VMware, Documents\Virtual Machines, BlueStacks_nxt, C:\LDPlayer absent|
|Existing emulator/VM processes|No emulator, QEMU, VirtualBox VM, HD-Player or LDPlayer process found during inventory|
|Image/archive search|Known SDK, .android, Downloads and VirtualBox VMs searched for system/ramdisk/userdata/kernel images, emulator/QEMU executables, AVD configs, .vbox files and Android22/5.1 named archives; no candidates|
|Project runtime material|Saved framework/provider artifacts, source/decompilation and analyses; no runnable Android image|

This is a bounded search of known installation and archive locations, not a claim that every byte on every disk was inspected. A broad user-profile directory listing was access-denied; the explicit SDK/AVD/VM/archive searches above completed without recorded scan errors. An unregistered image elsewhere would require a user-supplied local path. No image creation is possible from SDK API stubs alone.

## Saved target provenance, not runtime identity

Saved `adb/RDX-Audit/full-system/build.prop` identifies API22, Android5.1.1, armeabi-v7a and fingerprint `Acura/gen1CBD_HS/gen1CBD_HS:5.1.1/LMY48P/168:user/release-keys`. This file was read from disk; the target was not queried.

Saved `adb/RDX-Audit/full-system/framework/conscrypt.jar` SHA256:
`F9937C3490DAE58DDCC68D427739854EE6AB761B3860173B0D283EED1805FDE8`.
Extracted classes.dex SHA256:
`BDB40C2FF4C0D98C2B8CDBA5CCB554677EFD0B2D62A63EDB69D5211ADEC46DB8`.

Existing target decompilation was reused, and the DEX was disassembled with the installed dexdump. Neither Conscrypt native code nor Honda JNI was loaded. No conformance APK was built or installed because no isolated Android runtime exists to execute it.
