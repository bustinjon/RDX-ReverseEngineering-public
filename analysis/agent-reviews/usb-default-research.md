# USB Permission Persistence Research

Research: how to make USB permission permanent so the A11Y auto-clicker isn't needed every connect.

## 1. UsbPermissionActivity — "Always use" checkbox

**File:** `decompiled/SystemUI/sources/com/android/systemui/usb/UsbPermissionActivity.java`

The dialog has a `CheckBox mAlwaysUse` (line 30, inflated at line 68 from view ID `16909008`). The checkbox text for devices is resource `2131492910` (likely "Use by default for this USB device").

**What happens on OK click with checkbox checked (lines 84-121, `onDestroy()`):**

1. `service.grantDevicePermission(device, uid)` — grants permission for this session (line 93)
2. `service.setDevicePackage(device, packageName, userId)` — **saves our app as the default** for this device (line 96)

Without the checkbox, only step 1 happens. The permission is transient (cleared on device detach at `UsbSettingsManager.java:619`).

**With the checkbox**, `setDevicePackage` writes a `DeviceFilter → packageName` mapping to `usb_device_manager.xml`. On the next USB attach, `deviceAttached()` (line 604-616) finds our package as `defaultPackage`, and `resolveActivity()` auto-grants permission + launches our `UsbAttachActivity` with NO dialog.

## 2. What the saved DeviceFilter looks like

When `setDevicePackage(device, ...)` is called, it creates `new DeviceFilter(device)` which captures ALL 8 fields from the live UsbDevice:

For our AOAP device (from v6g-retry logs):
[Code block omitted; consult project-authored source.]

On reconnect, the same phone in AOAP+ADB mode produces an identical filter → HashMap lookup succeeds → auto-grant.

**Caution (from DeviceFilter.equals(), line 242-267):** If ANY of the first 5 numeric fields is -1, `equals()` returns false. The actual AOAP device has all fields set (0 is not -1), so this is fine.

## 3. Settings file location

**Line 400:** `new AtomicFile(new File(Environment.getUserSystemDirectory(user.getIdentifier()), "usb_device_manager.xml"))`

For user 0: `/data/system/users/0/usb_device_manager.xml`

The old single-user path (`/data/system/usb_device_manager.xml`, line 47) doesn't exist on this head unit (confirmed in test). The per-user path should exist.

**Can ADB shell write it?** The directory is owned by system (uid 1000). Shell (uid 2000) cannot write to it. Even if we could write the XML, `readSettingsLocked()` is only called at construction time (line 406) — the service would need to be restarted to pick up changes. **DEAD END for ADB-based pre-grant.**

## 4. UsbConfirmActivity — the other "Always use" path

`UsbConfirmActivity` (same checkbox, same mechanism) is shown when there's exactly 1 matching app but no saved default (line 704-706). It calls both `grantDevicePermission` and `setDevicePackage` on OK click (lines 88-96).

Our `UsbAttachActivity` is declared with `USB_DEVICE_ATTACHED` intent-filter and `device_filter.xml` matching AOAP devices (vid=6353 pid=11520/11521/11524/11525). So we ARE a matching app.

**But Honda is also a matching app** for the same USB devices. When there are multiple matches, the system shows `UsbResolverActivity` instead (line 713) — an app chooser. If the user picks us in the resolver and checks "Always use", we become the saved default.

## 5. Practical approach: modify PermissionClickService

The checkbox is a standard `android.widget.CheckBox` (inflated from the system layout `17367087`). In the A11Y tree, it should appear as a `CheckBox` node that's clickable.

**Required change in `PermissionClickService.java`:**

Before clicking OK, find and check the "Always use" checkbox. The checkbox likely has text containing "default" or "always" (resource `2131492910`).

[Code block omitted; consult project-authored source.]

**API 22 compatibility:** `AccessibilityNodeInfo.isChecked()` is available since API 14. `getClassName()` since API 14. `ACTION_CLICK` since API 16. All safe.

**Timing concern:** The checkbox click and OK click happen in the same `tryClickInRoot` call. The checkbox click changes the CheckBox state (the `onCheckedChanged` listener in UsbPermissionActivity just shows/hides a hint text). The `mAlwaysUse.isChecked()` check in `onDestroy()` reads the final state. Since `onDestroy()` runs after the activity finishes (triggered by the OK click), the checkbox state should be set before the read.

## 6. UsbAttachActivity filter match for saved defaults

Our `device_filter.xml` contains:
- `<usb-device vendor-id="6353" product-id="11521" />` — matches AOAP+ADB exactly

The `getDeviceMatchesLocked()` call uses `DeviceFilter.matches(UsbDevice)` (line 176-211) which is MORE PERMISSIVE than `equals()` — fields set to -1 in the filter are wildcards. Our filter has only vid and pid, so it matches any AOAP device regardless of manufacturer/serial.

**But the saved default uses `DeviceFilter(device)` from the actual device** — with all 8 fields populated. So the saved default is phone-specific (includes OnePlus serial). The match in our `device_filter.xml` is broad, but the saved preference is exact.

This means: "Always use" saves a default for THIS specific phone. A different phone would need to go through the dialog again (once).

## 7. Ranked approaches

### Approach 1: Modify PermissionClickService to check "Always use" [RECOMMENDED]
- **Effort:** Small code change (add `tryCheckAlwaysUse` before OK click)
- **Effect:** After ONE successful auto-click, all future connects for the same phone auto-grant with no dialog
- **Risk:** Low — if checkbox not found, falls back to current behavior (OK-only click)
- **Requires:** The A11Y service must be alive (already fixed in Run-CarTest.ps1)

### Approach 2: Manual "Always use" via touchpad
- **Effort:** None (just tap the checkbox + OK on the head unit during first test)
- **Effect:** Same as approach 1 — persistent default saved
- **Risk:** Need to tap fast enough before closeSystemDialogs kills the dialog
- **Note:** Good fallback if approach 1 doesn't work on first attempt

### Approach 3: Pre-write usb_device_manager.xml
- **Status:** DEAD END — shell can't write to `/data/system/users/0/`, and the file is only read at UsbService construction (boot time)

### Approach 4: `service call usb` to call setDevicePackage directly
- **Status:** DEAD END — requires MANAGE_USB permission (shell uid 2000 doesn't have it)

### Approach 5: Check `mDisablePermissionDialogs` config
- **Status:** UNKNOWN — if Honda's firmware sets `config_disableUsbPermissionDialogs=true`, the single-match auto-select applies even for non-system apps (line 671-676). Can't tell from decompiled code alone. Could test by checking if our app gets auto-launched when it's the sole matching app.
- **Note:** Even if this is true, Honda is ALSO a matching app, so the single-match path wouldn't apply while Honda is active. Only relevant with Honda Disabled for the phone.

## 8. Combined strategy

1. **Honda Disable** for user's phone (one-time head unit setting) → eliminates Honda from the USB race
2. **PermissionClickService checks "Always use"** → first connect goes through auto-click, all subsequent connects are instant
3. **A11Y service must be alive** → already fixed in Run-CarTest.ps1 (removed the force-stop of our package)
4. After the first successful connect with "Always use", the system auto-grants and launches `UsbAttachActivity` directly → UsbHelperService gets `AUTO_GRANTED` intent → starts AA session with zero dialog latency
