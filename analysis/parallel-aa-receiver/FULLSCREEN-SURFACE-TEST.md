# Standalone geometry grid — 2026-10-23

Package `com.rdx.fullscreen.gridtest`, version `0.1.0-grid`, min21/target22. Built and independently aapt/JADX/DEXDUMP audited. Static PASS for a separately authorized phone-disconnected grid session. No new runtime geometry claim.

`.GridActivity` creates a full-parent SurfaceView and EXIT button. It draws100px coordinate lines and x labels0 through1900, emphasizes1338/1339/1919 with distinct colors, and y labels every100px. Lines beyond the actual Surface are deliberately clipped; their absence under1339px policy is expected. Log tag `RDX.GRID` records actual Surface dimensions, view/decor dimensions, visible window frame, app and real display metrics, densityDpi, xdpi/ydpi, orientation and refresh rate. On-screen text reports these geometry values. FLAG_FULLSCREEN affects this window's decoration only, not global overscan or WindowManager configuration.

No permissions, USB, native libraries, AA/GAL, system settings/properties, shell execution or overscan/size/density mutation exists in the APK. Honda ApplicationFixup's normal Activity-resume side effect still applies; do not claim private-state neutrality.

Future commands only: install the exact matrix APK; `adb -s SERIAL shell am start -n com.rdx.fullscreen.gridtest/.GridActivity`; inspect grid/logs/window; press EXIT; uninstall only `com.rdx.fullscreen.gridtest`; verify absence with pm path/ps and unchanged display baseline. Do not combine this initial test with phone or decoding.

Full1920x720 requires its own later overscan authorization: record exact previous overscan/window state, measure stock grid, apply separately reviewed change, measure again, restore **exact prior** state, then verify. No overscan command is embedded or automatically executed. Uninstall cannot undo global display state. Do not assume a zero rollback value or infer full Surface from physical-display width.
