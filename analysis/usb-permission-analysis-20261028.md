# USB Permission Root Cause Analysis — 2026-10-28

## Source: Decompiled from THIS head unit's firmware

### Files examined
- `decompiled/SystemUI/sources/com/android/systemui/usb/UsbPermissionActivity.java`
- `decompiled/Services/sources/com/android/server/usb/UsbSettingsManager.java`

---

## Root Cause: The permission dialog IS launching but is invisible behind Honda

### How requestPermission works on this head unit

1. Our app calls `UsbManager.requestPermission(device, pendingIntent)`
2. IPC → `UsbService.requestPermission()` → `UsbSettingsManager.requestPermission()`
3. `UsbSettingsManager` checks `hasPermission()` — returns false for us
4. Calls `requestPermissionDialog()` which does:
   ```java
   intent.setClassName("com.android.systemui", 
       "com.android.systemui.usb.UsbPermissionActivity");
   intent.addFlags(FLAG_ACTIVITY_NEW_TASK);
   mUserContext.startActivityAsUser(intent, mUser);
   ```
5. `UsbPermissionActivity` shows an AlertDialog with OK/Cancel
6. If user taps OK → `mPermissionGranted = true` → `finish()`
7. `onDestroy()` calls `service.grantDevicePermission(device, uid)` + fires PendingIntent

### Why it's always denied

The dialog launches but **Honda's ProjectionActivity is fullscreen in front**. 
The dialog appears **behind Honda's activity** and the user never sees/taps it.

Variable timing confirms the dialog IS showing (0.4s to 23.4s per attempt):
- Fast denials (~0.4s): LTM may block the dialog from starting entirely
- Slow denials (4-23s): Dialog launched, waited for user, timed out or was dismissed

Our overlay (TYPE_SYSTEM_ERROR, FLAG_NOT_TOUCHABLE) is above everything,
but taps pass through INTO Honda's activity, not the invisible dialog behind it.

---

## Key Findings from UsbSettingsManager

### 1. UID 1000 always has permission (line 822)
[Code block omitted from public report; see authored source where available.]
Honda (UID 1000) NEVER needs permission. Our app always needs it.

### 2. `mDisablePermissionDialogs` flag (line 401)
[Code block omitted from public report; see authored source where available.]
Framework config boolean `config_disableUsbPermissionDialogs`.
**CONFIRMED FALSE** on this head unit (we see the dialog being launched).
If it were true, ALL apps would auto-get permission.

### 3. `grantDevicePermission` has NO internal permission check (lines 967-977)
[Code block omitted from public report; see authored source where available.]
Just adds UID to a HashMap. The permission check is in the IPC layer (UsbService),
which requires MANAGE_USB or system UID.

### 4. Default package auto-grants (resolveActivity, line 687-700)
[Code block omitted from public report; see authored source where available.]
If our package is set as the default handler for AOAP devices in the settings file,
we get **AUTO-GRANTED** on device attach. No dialog needed.

### 5. Settings file location (line 400)
[Code block omitted from public report; see authored source where available.]
Path: `/data/system/users/0/usb_device_manager.xml`
This stores the device→package preference map. Loaded at boot.

### 6. Permissions are in-memory only (not persisted)
`mDevicePermissionMap` is NOT written to the settings file.
`mDevicePreferenceMap` (default handlers) IS persisted.
Permissions are cleared on device detach (line 619).

---

## Ranked Solutions (updated with Codex-reviewed findings)

### 1. AccessibilityService auto-click (HIGHEST FEASIBILITY — v6 APK)
- `PermissionClickService` watches for `UsbPermissionActivity` window state changes
- When detected, finds OK button via `findAccessibilityNodeInfosByText("OK")`
- Clicks it programmatically with `performAction(ACTION_CLICK)`
- Enable from ADB: `settings put secure enabled_accessibility_services com.rdx.fullscreen.usbhelper/com.rdx.fullscreen.usbhelper.PermissionClickService`
- **Key advantage**: Works regardless of Z-order — accessibility services can interact with ANY window

### 2. `service call usb 11` — direct IPC grant (HIGH if shell has MANAGE_USB)
- Transaction 11 = grantDevicePermission, requires MANAGE_USB
- Full parcel: `i32 1 s16 /dev/bus/usb/BBB/DDD i32 VID i32 PID i32 0 i32 0 i32 0 s16 "" s16 "" s16 "" i32 0 i32 TARGET_UID`
- Grant implementation uses only `getDeviceName()` so minimal descriptor fields suffice
- Shell MANAGE_USB status: UNKNOWN — must check in car
- **Risk**: Standard AOSP shell UID 2000 lacks MANAGE_USB

### 3. Write settings file + reboot (MEDIUM FEASIBILITY)
- From ADB: write `/data/system/users/0/usb_device_manager.xml`
- **IMPORTANT**: Codex confirmed XML must match COMPLETE DeviceFilter equality
  (vendor-id, product-id, class, subclass, protocol, manufacturer, product, serial)
- Read at construction only — requires reboot + re-attach
- Setting our app as default does NOT suppress Honda's broadcast — Honda still gets notified
- **Risk**: shell write access unknown; incomplete descriptor match = no auto-grant

### 4. Keyboard navigate dialog (MEDIUM FEASIBILITY)
- `input keyevent 22` (DPAD_RIGHT) → `input keyevent 66` (ENTER)
- No coordinate guessing needed
- **Risk**: Dialog may not have keyboard focus; may need multiple attempts

### 5. `input tap` from ADB (LOW-MEDIUM FEASIBILITY)
- Auto-tap at likely OK button coordinates while dialog is showing
- **Risk**: Tap may hit Honda's window instead of the dialog behind it

### DEAD ENDS (Codex confirmed)
- **AppOps**: No USB operation in API 22 operation table
- **`settings put`**: No per-device grant setting exists
- **`pm grant MANAGE_USB`**: signature|system protected, non-changeable
- **`/data/system/usb/` edits**: No active-grant store used by this implementation

---

## Confirmed: openDevice() also requires permission

`UsbHostManager.openDevice()` (line 178-190) calls `checkPermission(device)` → `hasPermission(device)`.
No bypass possible — must have explicit permission grant or be UID 1000.

## IPC Transaction Codes (from IUsbManager.Stub)

| Code | Method | Requires |
|------|--------|----------|
| 2 | openDevice | per-device permission |
| 5 | setDevicePackage | MANAGE_USB |
| 7 | hasDevicePermission | none |
| 11 | grantDevicePermission | MANAGE_USB |
| 13 | hasDefaults | MANAGE_USB |
| 14 | clearDefaults | MANAGE_USB |

## Next Car Session Commands

### Test 1: Check settings file accessibility
[Code block omitted from public report; see authored source where available.]

### Test 2: Try writing default handler
[Code block omitted from public report; see authored source where available.]

### Test 3: Auto-tap approach
(Run this in background while permission dialog is showing)
[Code block omitted from public report; see authored source where available.]

### Test 4: Bring our activity to front first
[Code block omitted from public report; see authored source where available.]
Then request permission from the service.

### Test 5: Check MANAGE_USB for shell
[Code block omitted from public report; see authored source where available.]
