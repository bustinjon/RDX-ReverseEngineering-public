# M4 independent artifact audit — 2026-10-23

**PASS — READY FOR BOUNDED LIVE M4 TEST. No installation or vehicle operation performed.**

Artifact: `build/20261023-081948-336/rdx-usb-probe-0.1.0-development.apk`.
SHA-256: `BAD93C688F7019E4205DC86EF34E6078B695623DB85770C789F29B0A3CFF4148`.
Package `com.rdx.fullscreen.usbprobe`, versionCode 1, versionName `0.1.0-m4-passive`, minSdk21/targetSdk22.
Development signer SHA-256 `c001f59b25081ddfc73937155ca3580717e817c45c66e68b9e059737b0b28831`; v1 verification for API22 and zip alignment PASS.

## Independent evidence

The existing artifact was audited without rebuilding. `latest-audit.txt` identifies the successful evidence directory containing JADX source, aapt packaged manifest, independent SDK dexdump disassembly, DEX string/method/class inventories and machine-readable `audit.json`. The earlier bundled-Java access-denied attempt remains preserved; successful audit used the installed JDK17. No APK code or ARM native code was executed.

ZIP contains exactly manifest, classes.dex and three JAR-signature entries. No assets, additional DEX or native library. DEX defines only the Service and its anonymous Runnable. Java7 synthetic accessors are expected compiler output; no support library or injected component exists. The build-recorded source SHA matches current source; final decompiled behavior was manually compared to it. This establishes source/artifact correspondence by hash and semantic inspection, not reproducible-byte identity across different toolchains.

## Prohibited behavior checks

| Check | Actual artifact result |
|---|---|
| Activity / Activity alias | ABSENT |
| Requested permissions / shared UID | ABSENT |
| Intent filters / USB_DEVICE_ATTACHED / BOOT_COMPLETED / package receivers | ABSENT |
| openDevice | ABSENT |
| requestPermission | ABSENT |
| claimInterface | ABSENT |
| controlTransfer | ABSENT |
| bulkTransfer | ABSENT |
| releaseInterface / USB reset | ABSENT |
| System.loadLibrary / System.load | ABSENT |
| Native libraries / libautoreceiver_jni.so | ABSENT |
| MediaCodec / decoder | ABSENT |
| GAL / projection protocol / TLS / AOA commands | ABSENT |
| /data/misc/gal/socket | ABSENT |
| Runtime.exec / ProcessBuilder / reflection / dynamic class loader | ABSENT |
| su / Shizuku / root helper | ABSENT |
| wm overscan / wm size / wm density | ABSENT |
| settings put / setprop / reboot / force-stop / pm clear | ABSENT |
| Honda package/data-control code | ABSENT |
| Automatic sticky restart | ABSENT: onStartCommand returns 2, START_NOT_STICKY |

The word permission occurs in descriptive logs and hasPermission, not a permission-request method. Searches use actual method descriptors and token-aware strings; arbitrary substrings such as `su` inside another word are not classified as commands.

## Allowed behavior and manual control-flow review

`getDeviceList`, `hasPermission`, UsbDevice/UsbInterface/UsbEndpoint descriptor getters; getSystemService("usb"); own PID/UID/API/nativeLibraryDir; clocks; logging; Java iteration and threading; Service start/stop lifecycle. All method references were reviewed, including inherited calls referenced with the custom Service's class name.

Explicit action `com.rdx.fullscreen.usbprobe.SNAPSHOT` is required. Null/wrong action stops an idle Service. Duplicate invocations during an existing Service window are ignored and never queue another window. The worker samples at most 15 times, sleeping 1000ms between samples (at most 14 sleeps), then logs END and calls stopSelf. Cancellation interrupts sleep; onDestroy sets a volatile flag. Runtime/descriptor errors are logged without escalation. The DEX branch/back-edge and sleep constants were inspected independently of JADX.

Bounded iterations do not impose a hard deadline on a blocked framework Binder call. Stop/cleanup observation remains part of the future test; no force-stop of Honda components is involved. stopSelf does not guarantee the cached process immediately exits; uninstall must remove it.

Service component: `com.rdx.fullscreen.usbprobe/.UsbInventoryService` in `:probe`. No UI is resumed by the harness. Honda's install detector can still react, and connecting a phone may independently activate factory AA. This clearance concerns the harness's bounded passive behavior, not zero OEM side effects or a proven live M4 PASS.
