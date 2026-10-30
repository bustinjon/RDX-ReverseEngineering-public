## V6 Permission Bypass — Run with ADB connected, BEFORE plugging in phone
## Tries multiple approaches to grant USB permission to our app
## Updated 2026-10-28: UsbPermissionActivity killed by AMS closeSystemDialogs Binder RPC
## (finishOnCloseSystemDialogs flag). Exact trigger unknown — NOT HMIPresenter's broadcast
## (Codex-verified). Force-stopping Honda AA before phone connection prevents the kill.

$ADB = "C:/Program Files (x86)/Android/android-sdk/platform-tools/adb.exe"

Write-Host "`n=== STEP 1: Check if shell has MANAGE_USB ===" -ForegroundColor Cyan
$manageUsb = & $ADB shell dumpsys package com.android.shell 2>&1 | Select-String "MANAGE_USB"
if ($manageUsb) {
    Write-Host "  MANAGE_USB found: $manageUsb" -ForegroundColor Green
    Write-Host "  Shell CAN directly grant USB permission!" -ForegroundColor Green
    $hasManageUsb = $true
} else {
    Write-Host "  Shell does NOT have MANAGE_USB" -ForegroundColor Yellow
    $hasManageUsb = $false
}

Write-Host "`n=== STEP 2: Check settings file access ===" -ForegroundColor Cyan
& $ADB shell "ls -la /data/system/users/0/usb_device_manager.xml" 2>&1
& $ADB shell "cat /data/system/users/0/usb_device_manager.xml" 2>&1
Write-Host "`n  Current USB device preferences shown above"

Write-Host "`n=== STEP 2b: Dump USB state (permissions + preferences) ===" -ForegroundColor Cyan
& $ADB shell "dumpsys usb" 2>&1 | Select-String -Pattern "permission|preference|package|Device"

Write-Host "`n=== STEP 2c: Check write access to settings directory ===" -ForegroundColor Cyan
& $ADB shell "ls -la /data/system/users/0/" 2>&1 | Select-String "usb"
& $ADB shell "touch /data/system/users/0/usb_test_write && rm /data/system/users/0/usb_test_write && echo WRITABLE || echo NOT_WRITABLE" 2>&1

Write-Host "`n=== STEP 2d: Try adb root ===" -ForegroundColor Cyan
& $ADB root 2>&1

Write-Host "`n=== STEP 3: Check config_disableUsbPermissionDialogs ===" -ForegroundColor Cyan
& $ADB shell "settings get global usb_permission_dialogs_disabled" 2>&1

Write-Host "`n=== STEP 4: Get our app's UID ===" -ForegroundColor Cyan
$uidLine = & $ADB shell "dumpsys package com.rdx.fullscreen.usbhelper" 2>&1 | Select-String "userId="
Write-Host "  $uidLine"

Write-Host "`n=== STEP 5: Install v6 APK ===" -ForegroundColor Cyan
$latestBuild = Get-Content "analysis/parallel-aa-receiver/usb-helper/latest-build.txt" -ErrorAction SilentlyContinue
if ($latestBuild) {
    $apk = Get-ChildItem "$latestBuild/rdx-*.apk" | Select-Object -First 1
    if ($apk) {
        Write-Host "  Installing $($apk.Name)..."
        & $ADB install -r $apk.FullName 2>&1
    } else {
        Write-Host "  No APK found in $latestBuild" -ForegroundColor Red
    }
} else {
    Write-Host "  No latest-build.txt — build first" -ForegroundColor Red
}

Write-Host "`n=== STEP 6: Enable AccessibilityService (auto-clicks permission dialog) ===" -ForegroundColor Cyan
Write-Host "  KEY approach: A11Y service detects UsbPermissionActivity and clicks OK"
Write-Host "  Dialog lives ~3-7 seconds before Honda pulls it down."
Write-Host "  Service has retry logic: 15 attempts x 150ms = 2.25s window."
$ourService = "com.rdx.fullscreen.usbhelper/com.rdx.fullscreen.usbhelper.PermissionClickService"
$rawA11y = & $ADB shell settings get secure enabled_accessibility_services 2>&1
$existingA11y = ($rawA11y | Out-String).Trim()
if ($existingA11y -match "^Error|^Exception") {
    Write-Host "  ERROR reading existing services: $existingA11y" -ForegroundColor Red
    Write-Host "  Setting our service as the only one" -ForegroundColor Yellow
    $existingA11y = ""
}
if ($existingA11y -and $existingA11y -ne "null" -and $existingA11y -ne "") {
    if ($existingA11y -match [regex]::Escape($ourService)) {
        Write-Host "  Already registered (full component match)" -ForegroundColor Green
    } else {
        $newVal = "${existingA11y}:${ourService}"
        Write-Host "  Appending to existing services..."
        Write-Host "  Old: $existingA11y"
        Write-Host "  New: $newVal"
        & $ADB shell settings put secure enabled_accessibility_services "'$newVal'" 2>&1
    }
} else {
    Write-Host "  No existing services, setting ours"
    & $ADB shell settings put secure enabled_accessibility_services "'$ourService'" 2>&1
}
& $ADB shell settings put secure accessibility_enabled 1 2>&1
Write-Host "  Verifying..."
$verifyServices = (& $ADB shell settings get secure enabled_accessibility_services 2>&1 | Out-String).Trim()
$verifyEnabled = (& $ADB shell settings get secure accessibility_enabled 2>&1 | Out-String).Trim()
if ($verifyServices -match [regex]::Escape($ourService)) {
    Write-Host "  CONFIRMED: Service registered in settings" -ForegroundColor Green
} else {
    Write-Host "  WARNING: Service NOT found in readback: $verifyServices" -ForegroundColor Red
}
Write-Host "  enabled_accessibility_services = $verifyServices"
Write-Host "  accessibility_enabled = $verifyEnabled"

Write-Host "`n=== STEP 7: Try writing settings file (FULL device descriptor) ===" -ForegroundColor Cyan
Write-Host "  NOTE: Codex confirmed XML must match COMPLETE DeviceFilter equality"
Write-Host "  (vendor-id, product-id, class, subclass, protocol, manufacturer, product, serial)"
# AOAP device descriptor from OnePlus 13: VID=0x18d1 (6353), PID=0x2D01 (11521)
# Full descriptor match required per UsbSettingsManager.DeviceFilter.equals()
$settingsXml = @'
<?xml version="1.0" encoding="utf-8" standalone="yes" ?>
<settings>
<preference package="com.rdx.fullscreen.usbhelper">
<usb-device vendor-id="6353" product-id="11521" class="0" subclass="0" protocol="0" manufacturer-name="" product-name="" serial-number="" />
</preference>
<preference package="com.rdx.fullscreen.usbhelper">
<usb-device vendor-id="6353" product-id="11520" class="0" subclass="0" protocol="0" manufacturer-name="" product-name="" serial-number="" />
</preference>
</settings>
'@
& $ADB shell "echo '$settingsXml' > /data/local/tmp/usb_prefs.xml" 2>&1
Write-Host "  Backing up existing settings file first..."
& $ADB shell "cp /data/system/users/0/usb_device_manager.xml /data/local/tmp/usb_device_manager.xml.bak 2>/dev/null && echo 'Backup saved to /data/local/tmp/usb_device_manager.xml.bak' || echo 'No existing file to back up'" 2>&1
$cpResult = & $ADB shell "cp /data/local/tmp/usb_prefs.xml /data/system/users/0/usb_device_manager.xml" 2>&1
if ($cpResult -match "Permission denied|Read-only") {
    Write-Host "  Cannot write settings file: $cpResult" -ForegroundColor Yellow
    Write-Host "  (Expected — shell lacks write access to /data/system)" -ForegroundColor Yellow
    Write-Host "  Falling back to accessibility service approach" -ForegroundColor Yellow
} else {
    Write-Host "  Settings file written! Reboot needed to reload." -ForegroundColor Green
    Write-Host "  Verifying..."
    & $ADB shell "cat /data/system/users/0/usb_device_manager.xml" 2>&1
}

Write-Host "`n=== STEP 8: Force-stop Honda AA (prevents CLOSE_SYSTEM_DIALOGS kill) ===" -ForegroundColor Cyan
Write-Host "  ROOT CAUSE: UsbPermissionActivity has finishOnCloseSystemDialogs flag."
Write-Host "  Something triggers AMS.closeSystemDialogs() during AA startup (exact trigger unknown)."
Write-Host "  Force-stopping Honda AA prevents the entire startup chain — dialog survives."
$fsResult = & $ADB shell am force-stop com.honda.androidauto.projection.sink 2>&1
Write-Host "  force-stop result: $fsResult"
$hondaState = & $ADB shell "dumpsys activity services com.honda.androidauto.projection.sink 2>&1 | head -3"
Write-Host "  $hondaState"
Write-Host "  NOTE: Honda AA will restart when phone is plugged in (StartReceiver fires)."
Write-Host "  The A11Y service must click OK before HMIPresenter fires." -ForegroundColor Yellow

Write-Host "`n=== STEP 9: Start our service ===" -ForegroundColor Cyan
& $ADB shell am startservice com.rdx.fullscreen.usbhelper/.UsbHelperService 2>&1

Write-Host "`n=== READY ===" -ForegroundColor Green
Write-Host "  Plug in the phone now."
Write-Host "  The AccessibilityService should auto-click OK on the permission dialog."
Write-Host "  Watch logcat for 'RDX.A11Y' tags."
Write-Host ""
Write-Host "  If A11Y approach fails, try these in a second terminal:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  OPTION A (keyboard navigate dialog — no coordinates):" -ForegroundColor Cyan
Write-Host '  & $ADB shell "while true; do sleep 2; input keyevent 22; sleep 0.3; input keyevent 66; done"'
Write-Host '  # DPAD_RIGHT (22) moves focus to OK button, ENTER (66) presses it'
Write-Host ""
Write-Host "  OPTION B (auto-tap at likely dialog positions):" -ForegroundColor Cyan
Write-Host '  & $ADB shell "while true; do sleep 2; input tap 1200 500; input tap 1300 500; input tap 1100 500; done"'
Write-Host ""
Write-Host "  OPTION C (dump UI to find exact button coordinates):" -ForegroundColor Cyan
Write-Host '  & $ADB shell "uiautomator dump /sdcard/ui.xml && cat /sdcard/ui.xml" | Select-String -Pattern "OK|Allow|button"'
Write-Host ""
Write-Host "  NOTE: service call usb 11 is a DEAD END — shell lacks MANAGE_USB." -ForegroundColor DarkGray

Write-Host "`n=== STEP 9b: Start parallel keyevent fallback (backup for A11Y) ===" -ForegroundColor Cyan
Write-Host "  Run this in a SEPARATE terminal while plugging in the phone:"
Write-Host '  $ADB = "C:/Program Files (x86)/Android/android-sdk/platform-tools/adb.exe"' -ForegroundColor Yellow
Write-Host '  & $ADB shell "for i in 1 2 3 4 5 6 7 8 9 10; do sleep 1; input keyevent 22; sleep 0.2; input keyevent 66; done"' -ForegroundColor Yellow
Write-Host "  (DPAD_RIGHT to OK, ENTER to press — tries 10 times over 12 seconds)"
Write-Host ""
Write-Host "  NOTE: service call usb 11 confirmed DEAD END — shell (UID 2000) lacks MANAGE_USB." -ForegroundColor DarkGray

Write-Host "`n=== MONITORING ===" -ForegroundColor Cyan
Write-Host "  Capturing existing RDX logs before monitoring (preserving evidence)..."
& $ADB logcat -d -s "RDX.USB:*" "RDX.SESSION:*" "RDX.AAOVERLAY:*" "RDX.TRANSPORT:*" "RDX.A11Y:*" 2>&1
Write-Host "`n  --- Live monitoring starts below ---" -ForegroundColor Green
Write-Host "  Tags: RDX.* + AcuraLifecycleCallbacks + HondaStatusBar (CLOSE_SYSTEM_DIALOGS detection)"
& $ADB logcat -s "RDX.USB:*" "RDX.SESSION:*" "RDX.AAOVERLAY:*" "RDX.TRANSPORT:*" "RDX.A11Y:*" "AcuraLifecycleCallbacks:*" "HondaStatusBar:*"
