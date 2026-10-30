# Overnight Research Findings — 2026-10-28

## Session Summary

Five parallel agents ran verification and research. All findings below are consolidated.

## 1. InputSource JNI Signatures — VERIFIED 12/12 MATCH

Every native method signature matches stock smali exactly. Array order (pointerId, x, y), parameter reordering in registerTouchPad, return types, and the onInputFeedback callback are all correct. No remaining JNI issues.

One note: our `sendTouchPad` is single-pointer only. Fine for this head unit's touchpad.

## 2. AOAP Dispatch Path — CONFIRMED: USB_DEVICE_ATTACHED

Proof from our own on-car test logs: phone in AOAP mode (VID=0x18d1, PID=0x2d01) fired `USB_DEVICE_ATTACHED`, not `USB_ACCESSORY_ATTACHED`. Honda's stock AA also uses `USB_DEVICE_ATTACHED`. Our `device_filter.xml` is correct — no accessory filter needed.

The "AOAP = accessory" confusion was a naming issue. The phone re-enumerates as a USB **device** with AOAP VID/PID. From the host's perspective, it's just another USB device on the bus.

## 3. Honda USB Component — CRITICAL FINDING

Honda's USB filter is on a **BroadcastReceiver**, not an Activity:
[Code block omitted from public report; see authored source where available.]

Key implications:
- AOSP `resolveActivity()` only queries activities, not receivers
- Honda never got auto-granted through the activity resolution path
- Honda gets USB permission via `MANAGE_USB` (uid=1000 system app)
- Honda also has `accessory_filter.xml` matching "Android Open Automotive Protocol"

### Disable commands for test:
[Code block omitted from public report; see authored source where available.]

### USB permission strategy update:
Since we're not a system app (no MANAGE_USB, no uid=1000), the sole-activity auto-grant path gives us `UsbConfirmActivity` (a confirmation dialog), not silent grant. This is still better than the previous situation — the dialog will appear cleanly without the malicious detector on top (boot blocker handles that).

## 4. Session Lifecycle Bugs — FIXED

Three high-severity bugs found and fixed:

### Bug A: UsbHelperService only checked PID 0x2d01
If phone has ADB disabled, it enumerates as 0x2d00 — we'd never detect it.
**Fix:** Now uses `UsbBulkTransport.isAllowedPhone()` which checks all 4 AOAP PIDs (0x2d00, 0x2d01, 0x2d04, 0x2d05).

### Bug B: Native callbacks race with shutdown
`frame()`, `discovery()`, `focus()`, `config()`, `codecConfig()` run on native/reader threads. If shutdown starts concurrently, they'd call methods on destroyed objects.
**Fix:** Added `if (!running) return;` guards and capture-to-local pattern on every callback.

### Bug C: onSurfaceTextureDestroyed released surface too early
Returning `true` tells Android to release the SurfaceTexture immediately. If MediaCodec is still feeding frames → crash.
**Fix:** Returns `false` now — keeps SurfaceTexture alive until `removeOverlay()` explicitly releases it.

### Also fixed:
- Removed redundant `shutdown()` post in `byeBye()` (abortIo already schedules it)
- Removed duplicate `import android.os.IBinder` in UsbHelperService

## 5. Post-Video Roadmap

### Stock Honda service registration:
| ID | Service | We have it? | Required? |
|---|---|---|---|
| 1 | VideoSink | YES | Core |
| 2 | InputSource | YES (fixed) | Core |
| 3 | SensorSource | NO | Likely required — night mode & driving status |
| 4 | AudioSink (media) | NO | Likely required for usability |
| 5 | AudioSink (guidance) | NO | Likely required for usability |
| 7 | AudioSource (mic) | NO | Optional |
| 8 | BluetoothEndpoint | NO | Optional |
| 9 | NavigationStatus | NO | Optional |
| 10 | MediaPlaybackStatus | NO | Optional |

### Can video work without audio?
LIKELY YES — service discovery is capability advertisement, not hard requirements. The phone will render video even if audio sinks aren't registered. However, if the phone sends audio and nobody acks it, unacked frames could back up. We'll find out during the test.

### Priority after first frame:
1. **SensorSource stub** (medium effort) — prevents "driving restrictions" overlay on phone
2. **AudioSink** (medium effort) — silent without it
3. **AudioSource/Bluetooth** (hard) — voice/calls, defer

### Protobuf dependency:
SensorSource, AudioSink, AudioSource all reference `com.google.android.projection.proto.Protos`. Options: extract from stock APK's classes.dex or write minimal stubs.

## Build Status

APK built, signed, verified for API 22:
- SHA256: `F0ACB4BAC42DC70D2A03E7F154DEAD5FCE96DE3FB8EC3B449649F706B5C63A17`
- 16 source files, native lib, device_filter.xml, boot blocker all packaged

## Test Plan (11AM or 5PM)

### Phase 1: ADB diagnostics (2 min)
[Code block omitted from public report; see authored source where available.]

### Phase 2: Disable Honda + install (2 min)
[Code block omitted from public report; see authored source where available.]

### Phase 3: Start service + plug phone (1 min)
[Code block omitted from public report; see authored source where available.]

### Phase 4: Reconnect ADB, check logs
[Code block omitted from public report; see authored source where available.]

### Expected outcomes:
- **Best case:** Video renders on fullscreen overlay, touch works
- **Good case:** USB permission granted, handshake starts, phone negotiation visible in logs
- **Acceptable case:** USB permission dialog appears cleanly (no malicious detector blocking), user taps OK
- **Problem case:** Permission still denied → check if GalService was already running → force-stop Honda package

### Phase 5: Restore Honda (after test)
[Code block omitted from public report; see authored source where available.]
