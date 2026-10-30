# Overnight Research Findings — 2026-10-27

## Root Cause: USB Permission Denied

The USB permission dialog (`UsbPermissionActivity`) is a normal activity window (TYPE_APPLICATION, z-order ~2). Honda's malicious detector dialog is TYPE_SYSTEM_ALERT (z-order 2003). **The detector dialog draws on top of the permission dialog and intercepts taps.** The user was hitting "OK" on the detector, not on the USB permission grant.

This is consistent with the earlier finding (project memory) that `requestPermission` DID work when the dialog wasn't being blocked.

## AOSP 5.1 USB Device Dispatch (from source analysis)

When an AOAP device attaches, `UsbSettingsManager.deviceAttached()`:
1. Sends `ACTION_USB_DEVICE_ATTACHED` broadcast to all dynamically registered receivers
2. Queries activities with matching `<meta-data android:name="android.hardware.usb.action.USB_DEVICE_ATTACHED">` device_filter XML
3. Resolution:
   - If a stored default package exists → auto-launch + **auto-grant permission** (no dialog!)
   - If exactly 1 match → auto-launch + **auto-grant permission** (no dialog!)
   - If 2+ matches → show UsbResolverActivity chooser
4. Permission is granted via `grantDevicePermission(device, matchedUid)` before startActivity

**Honda's sink is likely the sole matching activity**, so it gets auto-launched and auto-granted with no dialog.

## Solution: Three-Step Fix

### Step 1: Disable Honda's USB-filter activity component
[Code block omitted from public report; see authored source where available.]
- Shell (uid 2000) has CHANGE_COMPONENT_ENABLED_STATE permission
- Disabling one component is safer than disabling the whole package
- Persists across reboots (stored in package-restrictions.xml)
- Reversible: `pm enable` restores it
- Need to find the exact activity name first: `dumpsys package com.honda.androidauto.projection.sink`

### Step 2: Add our own USB device filter activity
- Create a transparent activity with USB_DEVICE_ATTACHED intent-filter
- Add device_filter.xml matching vid=0x18d1 pid=0x2d01
- With Honda disabled, we're the SOLE match → system auto-grants permission
- No dialog, no touch issues, no race condition

### Step 3: Boot blocker for malicious detector
- Already coded (BootBlockerReceiver + BootBlockerService)
- Covers boot+8s to boot+16s with TYPE_SYSTEM_ERROR overlay
- Prevents the detector dialog from interfering with anything

## Lock Task Mode Analysis (from overnight Codex research)

**Critical finding:** LTM can block UsbAttachActivity even though system_server does the launching.
The check is `ActivityStackSupervisor.isLockTaskModeViolation(TaskRecord)` — it's task-based, not caller-based.
Returns error code 5 (START_RETURN_LOCK_TASK_MODE_VIOLATION), same as what we saw with activities before.

**BUT:** The USB auto-grant happens BEFORE `startActivityAsUser()` and is NOT rolled back.
So even if LTM blocks the activity launch, the permission grant may still persist in memory.
Our polling service's `hasPermission()` check would then succeed and skip the dialog entirely.

**Counter-signal:** The USB permission dialog (`UsbPermissionActivity` from SystemUI) DID launch under LTM
in earlier tests. So either SystemUI is whitelisted or LTM is looser than expected. Need to verify.

**Important: DEVICE_ATTACHED vs ACCESSORY_ATTACHED.**
A phone in AOAP mode re-enumerates as an accessory. The relevant event might be `USB_ACCESSORY_ATTACHED`
(via `accessoryAttached` → `resolveActivity` with accessory_filter → `grantAccessoryPermission`),
not `USB_DEVICE_ATTACHED`. Need to check which path the phone actually triggers. If it's the accessory
path, our device_filter.xml won't match — we'd need an accessory_filter.xml instead.

**If both Honda and us match:** `count==2`, chooser appears, nobody auto-granted. Must disable Honda first.

## Fallback Strategies (ranked)

**Plan A: Disable Honda's USB activity + our UsbAttachActivity as sole match**
- Auto-grant before launch, grant persists even if LTM blocks activity
- Service picks up permission via polling
- RISK: LTM blocks activity but that's OK if grant persists

**Plan B: Boot blocker + requestPermission with clean screen**
- Suppress malicious detector → permission dialog appears alone
- User taps OK on the real permission dialog
- "Use by default" checkbox makes it persistent (calls setDevicePackage internally)
- RISK: Dialog touch reliability on the head unit, checkbox may be dead

**Plan C: Shell has MANAGE_USB → pre-grant via service call**
- If shell has MANAGE_USB, call grantDevicePermission directly
- Build small helper to call setDevicePackage to set us as persistent default
- RISK: Shell likely doesn't have MANAGE_USB on 5.1 (SPECULATIVE)

## Key Facts (CONFIRMED vs LIKELY)

- **CONFIRMED:** USB permissions are in-memory only, cleared on device detach
- **CONFIRMED:** Multiple UIDs can hold permission for same device simultaneously
- **CONFIRMED:** `requestPermission` works on this head unit (previous session)
- **CONFIRMED:** `pm grant` / `appops` cannot grant USB permission
- **CONFIRMED:** `service call usb 11` (grantDevicePermission) needs MANAGE_USB (signature|system)
- **LIKELY:** Auto-grant happens before startActivity and is not rolled back on LTM block
- **LIKELY:** Shell has CHANGE_COMPONENT_ENABLED_STATE for `pm disable`
- **LIKELY:** Honda's sink is sole activity match, gets auto-granted
- **LIKELY:** IUsbManager tx codes: 5=setDevicePackage, 7=hasDevicePermission, 11=grantDevicePermission, 14=clearDefaults
- **SPECULATIVE:** Shell may have MANAGE_USB on this build (needs verification)
- **SPECULATIVE:** AOAP phone may trigger ACCESSORY_ATTACHED not DEVICE_ATTACHED

## Pre-Test ADB Diagnostics (run BEFORE phone test)

[Code block omitted from public report; see authored source where available.]

## Pre-Test Build Checklist

1. Connect ADB
2. Run diagnostics A-F above
3. Build and install updated APK (16 sources, device_filter, boot blocker)
4. Run diagnostic D (LTM test on our activity)
5. Find and disable Honda's USB activity (E, G)
6. Start UsbHelperService
7. Plug in phone
8. Expected: system auto-grants to our uid → service detects permission → session starts
9. After test: `pm enable` to restore Honda's AA
