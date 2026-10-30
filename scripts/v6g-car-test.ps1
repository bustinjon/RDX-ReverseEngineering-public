## V6g Car Test — Honda Kill Loop + Deferred requestVideo validation
## Run with ADB connected, BEFORE plugging in phone
## Approach: Continuously force-stop Honda AA during the USB attachment window
## so our app wins the AOAP race. Kill loop runs on-device, survives ADB disconnect.

$ADB = "C:/Program Files (x86)/Android/android-sdk/platform-tools/adb.exe"

Write-Host "`n=== STEP 1: Verify ADB connection ===" -ForegroundColor Cyan
$devices = & $ADB devices 2>&1
Write-Host $devices
if (-not ($devices -match "device$")) {
    Write-Host "  No device connected. Connect ADB first." -ForegroundColor Red
    exit 1
}

Write-Host "`n=== STEP 2: Verify v6g APK installed ===" -ForegroundColor Cyan
$pkg = & $ADB shell pm list packages 2>&1 | Select-String "rdx.fullscreen"
if ($pkg) {
    Write-Host "  $pkg" -ForegroundColor Green
} else {
    Write-Host "  RDX package not found. Installing..." -ForegroundColor Yellow
    $latestBuild = Get-Content "analysis/parallel-aa-receiver/usb-helper/latest-build.txt" -ErrorAction SilentlyContinue
    if ($latestBuild) {
        $apk = Get-ChildItem "$latestBuild/rdx-*.apk" | Select-Object -First 1
        if ($apk) {
            & $ADB install -r $apk.FullName 2>&1
        }
    }
}

Write-Host "`n=== STEP 3: Enable AccessibilityService ===" -ForegroundColor Cyan
$ourService = "com.rdx.fullscreen.usbhelper/com.rdx.fullscreen.usbhelper.PermissionClickService"
& $ADB shell settings put secure enabled_accessibility_services "'$ourService'" 2>&1
& $ADB shell settings put secure accessibility_enabled 1 2>&1
$verify = (& $ADB shell settings get secure enabled_accessibility_services 2>&1 | Out-String).Trim()
if ($verify -match [regex]::Escape($ourService)) {
    Write-Host "  A11Y service registered" -ForegroundColor Green
} else {
    Write-Host "  WARNING: A11Y service NOT confirmed: $verify" -ForegroundColor Red
}

Write-Host "`n=== STEP 4: Probe Honda SharedPreferences (diagnostic) ===" -ForegroundColor Cyan
Write-Host "  Checking if shell can access Honda's start preferences..."
$lsResult = & $ADB shell "ls -la /data/data/com.honda.androidauto.projection.sink/shared_prefs/ 2>&1" 2>&1
Write-Host "  $lsResult"
$catResult = & $ADB shell "cat /data/data/com.honda.androidauto.projection.sink/shared_prefs/gal_start_preferences.xml 2>&1" 2>&1
if ($catResult -match "Permission denied|No such file") {
    Write-Host "  SharedPreferences not accessible (expected)" -ForegroundColor Yellow
    Write-Host "  Using kill loop approach instead" -ForegroundColor Yellow
} else {
    Write-Host "  SharedPreferences READABLE:" -ForegroundColor Green
    Write-Host "  $catResult"
    Write-Host "  If writable, we could set status=NEVER for our phone serial" -ForegroundColor Green
}

Write-Host "`n=== STEP 5: Start logcat capture (survives ADB disconnect) ===" -ForegroundColor Cyan
& $ADB shell "pkill -f 'logcat.-f'" 2>&1 | Out-Null
& $ADB shell "rm -f /data/local/tmp/v6g-test.log" 2>&1 | Out-Null
& $ADB logcat -c 2>&1 | Out-Null
& $ADB shell "nohup logcat -v threadtime -f /data/local/tmp/v6g-test.log > /dev/null 2>&1 &" 2>&1
Start-Sleep -Seconds 1
$logPid = (& $ADB shell "pidof logcat" 2>&1 | Out-String).Trim()
if ($logPid) {
    Write-Host "  Logcat capturing (pid=$logPid) to /data/local/tmp/v6g-test.log" -ForegroundColor Green
} else {
    Write-Host "  WARNING: logcat process not found" -ForegroundColor Red
}

Write-Host "`n=== STEP 6: Start safety timer (60 seconds) ===" -ForegroundColor Cyan
& $ADB shell "nohup sh -c 'sleep 60; am startservice -a aa.overlay.STOP -n com.rdx.fullscreen.usbhelper/.AaOverlayService; sleep 2; am force-stop com.rdx.fullscreen.usbhelper' > /dev/null 2>&1 &" 2>&1
Write-Host "  Safety timer: overlay auto-kill in 60 seconds" -ForegroundColor Green

Write-Host "`n=== STEP 7: Start Honda kill loop (30 second window) ===" -ForegroundColor Cyan
Write-Host "  This continuously force-stops Honda AA to prevent it from claiming USB."
Write-Host "  Pushing kill script to device and running with nohup..."
& $ADB push "$PSScriptRoot/device-kill-honda.sh" /data/local/tmp/kill-honda.sh 2>&1
& $ADB shell chmod 755 /data/local/tmp/kill-honda.sh 2>&1
& $ADB shell "nohup sh /data/local/tmp/kill-honda.sh > /dev/null 2>&1 &" 2>&1
Write-Host "  Kill loop started on device (~300 iterations, ~30 seconds)" -ForegroundColor Green

Write-Host "`n=== STEP 8: Start our service ===" -ForegroundColor Cyan
& $ADB shell am startservice com.rdx.fullscreen.usbhelper/.UsbHelperService 2>&1

Write-Host "`n=== READY — PLUG IN PHONE NOW ===" -ForegroundColor Green
Write-Host ""
Write-Host "  Kill loop is actively suppressing Honda AA for ~30 seconds." -ForegroundColor White
Write-Host "  Our service is running and will claim USB when the phone connects." -ForegroundColor White
Write-Host "  Safety timer kills overlay after 60 seconds." -ForegroundColor White
Write-Host ""
Write-Host "  After test: reconnect ADB and pull logs:" -ForegroundColor Yellow
Write-Host "    adb pull /data/local/tmp/v6g-test.log analysis/logs/car-test-20261028-v6g.txt" -ForegroundColor Yellow
