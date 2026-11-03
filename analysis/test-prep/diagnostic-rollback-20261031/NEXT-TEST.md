# Rollback comparison first — phone stays unplugged

Selected exact prior car-tested APK: `rdx-usb-helper-v6h-longdrive-current-a.apk`, SHA-256 **D1A29B34812B2C3188C57C840DB1DE4F44E1362FF8BD8E3D9A52B1317EDABCE4**.

The local production source has been restored to its exact27 recorded inputs. The newer candidate and five changed/added source files are preserved. No APK was rebuilt, and the device has not been changed by this offline rollback.

At the next authorized ADB connection on Honda Home:

1. Keep the phone unplugged. Run this directory's `Install-BaselineOnly.ps1`. It retains existing target/firmware and stable Home/lock-task checks, verifies CurrentSource, installs the exact old APK, pulls/verifies the installed hash and leaves the helper stopped. It does not start the auto-clicker, change accessibility settings or arm an AA test.
2. Wait for **BASELINE INSTALLED — helper/auto-clicker remain stopped**. Then perform the usual manual three-button Diagnostics entry, using the same sustained hold already attempted. Note whether it now opens. The operator should collect the normal launch/input state promptly; do not switch to the phone yet.
3. A successful manual entry means the rollback/reinstall changed the behavior, not that a particular media/volume/Maps feature is proven causal. If entry still fails, do not stack another APK or settings change; capture the complete passive key trace described by the shortcut investigation.
4. Only after this comparison and a normal return to Home should a separately authorized receiver test be prepared. The restored build intentionally has the older Spotify-row, volume-display, track-button and Maps-focus limitations. The old untimed preparation remains available for this exact source/build; no readiness bypass is added.

This first comparison has **no phone-connect cue** and does not need an AA session. Git updates remain paused. Nothing here resets OEM settings or clears application data.
