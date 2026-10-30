# Honda Malicious Detector — How It Works and Suppression Options

## Detection Logic (from decompiled MDService.java + PackageLocalRepository.java)

**Trigger:** `MDBroadcastReceiver` listens for:
- `BOOT_COMPLETED` → starts MDService → 10-second delay → scans ALL installed packages
- `PACKAGE_ADDED` / `PACKAGE_INSTALL` → scans the specific package

**Detection criteria:** `PackageLocalRepository.isSystemApp(ApplicationInfo)`:
- Checks `ApplicationInfo.flags` for:
  - `FLAG_SYSTEM` (0x1) — installed in /system/app
  - `FLAG_UPDATED_SYSTEM_APP` (0x80) — system app updated
  - `FLAG_PRIVILEGED` (0x40000000) — privileged app in /system/priv-app
- If ANY of these flags is set → **exempt** (system app)
- If NONE set → **detected** as "non-authorized third party package"

**Dialog behavior:**
- On runtime install (PACKAGE_ADDED): **No dialog shown.** Only records `setUserDidInstallThirdPartyApp()` preference.
- On boot (10s delay scan):
  - If previously installed third-party AND currently detected → dialog WITH "Remove" button
  - If previously installed third-party AND NOT currently detected → dialog WITHOUT "Remove" button (just warning)
  - If never installed third-party AND currently detected → dialog WITH "Remove" + sets the persistent flag
  - If never installed AND none detected → nothing (clean state)
- The `didUserPreviouslyInstallThirdPartyApp` preference **persists across uninstalls**

**Dialog itself:** `HondaDialog` with TYPE_SYSTEM_ALERT. Two buttons:
- "OK" — dismisses, no action
- "Remove" (when present) — calls `deletePackage` via reflection on ALL detected third-party packages

## Suppression Options (without modifying com.honda.maliciousdetector)

### Option A: Boot overlay blocker (RECOMMENDED first try)
Our TYPE_SYSTEM_ERROR overlay has higher z-order than the detector's TYPE_SYSTEM_ALERT dialog.
- Register a BOOT_COMPLETED receiver
- Start a service that shows a TYPE_SYSTEM_ERROR overlay 8-10s after boot
- The overlay covers the detector's dialog (which appears at 10s)
- Dismiss overlay after 5s — by then the dialog is behind or timed out
- PRO: Simple, reliable, no system access needed
- CON: Brief visual disruption on boot, dialog still exists behind overlay

### Option B: Install to /system
Put APK in `/system/app/` or `/system/priv-app/` so `FLAG_SYSTEM` is set.
- Requires remount of /system partition (currently read-only)
- PRO: Permanent fix, app becomes exempt from all checks
- CON: Requires root/remount — feasibility unknown on this head unit

### Option C: Touch injection to dismiss
After dialog appears, inject a tap on the "OK" button coordinates.
- Use `InputManager.injectInputEvent()` via reflection or `Instrumentation`
- PRO: Dialog actually dismissed
- CON: Fragile — button position depends on dialog layout, needs system permission for injection

### Option D: Accept the dialog
The dialog only appears on boot. "OK" button is safe. Only "Remove" is dangerous.
- PRO: Zero effort
- CON: Annoying, user must dismiss every boot, accidental "Remove" press would uninstall
