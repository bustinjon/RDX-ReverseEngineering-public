#!/bin/bash
# Pre-test ADB diagnostics — run with ADB connected BEFORE phone plug-in
# Usage: adb shell < scripts/pre-test-diagnostics.sh
# Or paste blocks individually into: adb shell

ADB="C:/Program Files (x86)/Android/android-sdk/platform-tools/adb.exe"

echo "=== A. MANAGE_USB permission check ==="
"$ADB" shell dumpsys package com.android.shell | grep -i MANAGE_USB

echo ""
echo "=== B. Lock Task Mode state ==="
"$ADB" shell dumpsys activity activities | grep -i -E "lock.?task|mLockTask"

echo ""
echo "=== C. Our USB filter registration ==="
"$ADB" shell dumpsys package com.rdx.fullscreen.usbhelper | grep -i -A5 USB_DEVICE

echo ""
echo "=== D. LTM blocks our activity? ==="
"$ADB" logcat -c
"$ADB" shell am start -n com.rdx.fullscreen.usbhelper/.UsbAttachActivity 2>&1
sleep 2
"$ADB" logcat -d -s ActivityManager:I | grep -i -E "Lock.Task|violation|Starting|Displayed|START_"

echo ""
echo "=== E. Honda's USB activity filters ==="
"$ADB" shell dumpsys package com.honda.androidauto.projection.sink | grep -B3 -A10 USB_DEVICE_ATTACHED

echo ""
echo "=== F. Current USB defaults and permissions ==="
"$ADB" shell dumpsys usb | head -60

echo ""
echo "=== G. Probe MANAGE_USB with harmless call ==="
echo "(SecurityException = no MANAGE_USB; boolean result = yes)"
"$ADB" shell service call usb 13 s16 com.honda.androidauto.projection.sink i32 0 2>&1

echo ""
echo "=== H. Our app installed? ==="
"$ADB" shell pm list packages | grep rdx

echo ""
echo "=== I. Boot blocker + overlay services registered ==="
"$ADB" shell dumpsys package com.rdx.fullscreen.usbhelper | grep -A2 "Service\|Receiver"

echo ""
echo "=== J. Test am force-stop (CRITICAL — determines strategy) ==="
"$ADB" shell am force-stop com.honda.androidauto.projection.sink 2>&1
echo "Exit code: $?"
"$ADB" shell dumpsys activity services com.honda.androidauto.projection.sink | head -5
echo "(Empty = force-stop worked; services listed = Honda still running)"

echo ""
echo "=== DIAGNOSTICS COMPLETE ==="
echo ""
echo "Next steps (v5 — dual-path: force-stop determines which path):"
echo ""
echo "  1. Force-stop Honda from ADB (our app can't do this itself — needs shell uid):"
echo "     adb shell am force-stop com.honda.androidauto.projection.sink"
echo "     (If this fails with SecurityException, skip — Path B will be used automatically)"
echo "  2. Install v5 APK:"
echo "     adb install -r <path-to-apk>"
echo "  3. Start our service (detects Honda's stopped state + probes VBUS):"
echo "     adb shell am startservice com.rdx.fullscreen.usbhelper/.UsbHelperService"
echo "     (Or if force-stop worked, tell service explicitly:)"
echo "     adb shell am startservice -a usb.HONDA_STOPPED com.rdx.fullscreen.usbhelper/.UsbHelperService"
echo "  4. Plug in phone"
echo "  4. Watch logs:"
echo "     adb logcat -s RDX.USB:I RDX.SESSION:I RDX.AAOVERLAY:I RDX.INPUT:I RDX.TRANSPORT:I AHU.GAL_RECEIVER:E AHU.USB_HOST_CONNECTION:W"
echo ""
echo "  KEY LOG LINES TO WATCH FOR:"
echo "    'force-stop Honda: SUCCESS' → Path A active (AOAP-first, clean session)"
echo "    'force-stop Honda: FAILED'  → Path B active (steal from Honda, retry transport)"
echo "    'AOAP switch complete'      → Phone should re-enumerate as AOAP"
echo "    'AOAP alive: protocol'      → Phone AOAP stack responding"
echo "    'Write fail ... rc=... ms=' → Transport diagnostic (NAK vs STALL)"
echo "    'Write recovered'           → Halt-clear fixed it (STALL was the issue)"
echo "    'VBUS reset response: OK'   → GAL socket accessible (huge win)"
echo "    'FIRST FRAME RENDERED'      → SUCCESS — video is live!"
echo ""
echo "  After test — if force-stop was used, reboot restores Honda naturally."
echo "  Or manually: adb shell am start -n com.honda.androidauto.projection.sink/.ui.ProjectionActivity"
