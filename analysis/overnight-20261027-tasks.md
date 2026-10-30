# Overnight Analysis Tasks — 2026-10-27

## Context
- Protocol stack fully initializes (DIAG all 5 steps PASS)
- InputSource JNI crash fixed (onInputFeedback signature was (II)V, native expects (I)V)
- BLOCKER: USB permission denied — stock Honda AA (`com.honda.androidauto.projection.sink`) is a system app (uid=1000, pkgFlags=SYSTEM) with USB_DEVICE_ATTACHED intent filter. It claims the AOAP device before our app gets permission.
- Phone detected as AOAP (vid=18d1 pid=2d01, OnePlus 13, config "accessory_adb") but granted=false 5 times.
- Secondary annoyance: Honda malicious detector popup on boot.

## Task 1: USB Permission — How to Win the Race (HIGH PRIORITY)

Investigate ALL options for getting USB permission to our app when a system app is competing:

### 1a. Pre-grant via ADB
- Can `adb shell appops` grant USB device access?
- Does Android 5.1 have a `/data/system/usb_device_manager.xml` or similar that stores persistent USB permissions? Can we write to it?
- Can we use `service call usb <N>` to call grantDevicePermission from shell?
- Research: what transaction code is grantDevicePermission in IUsbManager on API 22?

### 1b. Manifest USB device filter
- Add `<meta-data android:name="android.hardware.usb.action.USB_DEVICE_ATTACHED" android:resource="@xml/device_filter" />` with a filter matching vid=0x18d1 pid=0x2d01
- Does Android 5.1 auto-grant permission to the app with the matching device_filter if only one app matches? Or does it show a chooser?
- If Honda's sink ALSO has a device_filter, what happens? Does priority go to system apps?

### 1c. Disable Honda AA sink temporarily
- Can `pm disable-user --user 0 com.honda.androidauto.projection.sink` work from adb shell (uid 2000)?
- Can `pm disable com.honda.androidauto.projection.sink` work?
- What side effects would disabling Honda's AA sink have?
- Can we re-enable it after our session?

### 1d. Force-stop Honda AA before phone plugin
- `am force-stop com.honda.androidauto.projection.sink` before the phone connects
- Does this prevent it from receiving USB_DEVICE_ATTACHED?
- On Android 5.1, does force-stop clear the intent filter registration?

### 1e. Claim USB interface directly
- Our UsbBulkTransport calls `claimInterface(iface, false)` — the `false` means non-forcing
- What if Honda's sink claimed first? Would `claimInterface(iface, true)` (forcing) steal it?
- Is the permission denial happening at the system level (UsbManager won't grant) or at the interface level (can't claim)?

### 1f. Auto-start on USB attach via manifest
- Add `<intent-filter>` for USB_DEVICE_ATTACHED to a BroadcastReceiver or Activity
- Include `<meta-data>` with device_filter.xml for vid=0x18d1
- Does Android deliver the intent to ALL matching apps, or just the "default" one?
- On API 22, can a non-system app register for USB_DEVICE_ATTACHED?

## Task 2: Malicious Detector Suppression (MEDIUM PRIORITY)

Implement Option A (boot overlay blocker):
- Add BOOT_COMPLETED receiver to AndroidManifest.xml
- Create a simple service that shows a TYPE_SYSTEM_ERROR overlay 8s after boot
- The overlay covers the detector's TYPE_SYSTEM_ALERT dialog (10s after boot)
- Dismiss after 5s
- Needs to be small, reliable, no user interaction needed

## Task 3: UsbBulkTransport Contention Analysis (MEDIUM PRIORITY)

If we solve the permission problem:
- Stock Honda AA will still try to use the AOAP device
- What happens if both our app and Honda's sink try to claim the same USB interface?
- Can we detect if another app has claimed the interface?
- Does our non-forcing claim fail gracefully if Honda claimed first?
- What if we claim with `force=true` to steal from Honda?

## Evidence files
- Logs from test: search logcat for RDX.USB entries from this session
- Honda AA package: `com.honda.androidauto.projection.sink`, system app, uid=1000
- Honda AA has USB_DEVICE_ATTACHED intent filter
- Our service: `analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/UsbHelperService.java`
- Malicious detector analysis: `analysis/honda-malicious-detector-analysis.md`
