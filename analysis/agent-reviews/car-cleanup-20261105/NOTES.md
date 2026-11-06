# Car cleanup and Home screenshot — 2026-11-05 (user-authorized: "clean up those leftover apps")

- Third-party apps before: com.rdx.fullscreen.projection ("RDX Parallel AA - TEST", 0.1.0-experimental-offline, installed 2026-10-28) and com.rdx.fullscreen.usbhelper ("RDX USB", the working AA).
- The projection app has no runtime role in the working AA: usbhelper only compiles in the shared Java classes. Only the old M5/live-01/02 prototype scripts reference it.
- Backup pulled first: com.rdx.fullscreen.projection-backup.apk, SHA-256 F2AF9A12CD15201EA804BDFEF7D85AC0598EE07B7CB721B59E521EA417B74161 (local only; contains protocol material; never publish). The dumpsys record is saved alongside.
- `adb uninstall com.rdx.fullscreen.projection` returned Success. Only com.rdx.fullscreen.usbhelper remains.
- An M5 retry would need the frozen M5 APK reinstalled. It was not this build (different hash), so nothing frozen was touched.
- screen-20261105.png: Honda Home with RDX USB already pinned top-left (generic Android icon), next to Android Auto, Bluetooth Audio, FM Radio, USB Audio, Settings, AcuraLink, System Updates.
