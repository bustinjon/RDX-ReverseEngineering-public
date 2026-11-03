# Auto-clicker activation comparison

User "continue" follows the explicit proposal to enable only the auto-clicker and retry Diagnostics on the same APK. This authorizes that ADB/accessibility step; it does not authorize phone handoff, AA session or milestone advancement.

Keep USB helper running with the same PID, same pinned APK, no overlay/session. Add only this app's PermissionClickService to enabled accessibility services, preserving other components and original values for restoration. Verify user 0 binding and a fresh onServiceConnected callback using existing core checks. Retain existing mandatory preflight; no bypass. Save diagnostics under this directory; no verbose chat output. On failure restore only owned settings if still unchanged externally. Do not modify production source, rebuild, publish Git or read credentials.
