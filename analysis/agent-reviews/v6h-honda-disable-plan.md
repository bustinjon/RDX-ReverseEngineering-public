# v6h Implementation Plan — Honda Disable Approach

**Date:** 2026-10-29
**Status:** Ready for implementation (pending user authorization for code changes)
**Confidence:** SUPPORTED — adversarial review passed 10 attacks, 1 fixable blocker

---

## Strategy

Instead of racing Honda (kill loop), we cooperate with Honda's own preference system. User sets their phone to "Never" in Honda's AA dialog → Honda voluntarily walks away on future connections → our app claims USB unopposed.

## Pre-requisite: User Sets "Never" in Honda AA

The user must connect their phone once via USB while Honda AA is in normal mode. Honda shows "Do you want to use Android Auto with this device?" dialog. User selects **"Never"**. Honda stores NEVER (0) in `gal_start_preferences` for the phone serial.

This only needs to be done once. The preference persists across reboots.

**Verification:** After setting NEVER, connecting the phone should NOT start Honda AA anymore. Honda's icon should show as disabled/grayed out.

---

## Code Changes

### 1. UsbHelperService.java — Add `hondaDisabled` flag

**What:** New boolean field `hondaDisabled`. New intent action `usb.HONDA_DISABLED` to set it. Modify three gates to allow non-AOAP phone handling when Honda is disabled.

**Changes:**

a. Add field:
[Code block omitted; consult project-authored source.]

b. Add action handler in `onStartCommand` (after the HONDA_STOPPED handler):
[Code block omitted; consult project-authored source.]

c. Modify poll loop gate (line 195):
[Code block omitted; consult project-authored source.]

d. Modify AUTO_GRANTED non-AOAP gate (line 138):
[Code block omitted; consult project-authored source.]

e. Modify permission callback non-AOAP gate (line 397):
[Code block omitted; consult project-authored source.]

f. Modify permission callback else-log (line 409):
[Code block omitted; consult project-authored source.]

### 2. PermissionClickService.java — Check "Always use" Checkbox

**What:** Before clicking OK/Allow, scan for and check the "Always use this USB device" checkbox. This saves our app as the default, avoiding future permission dialogs.

**Changes:**

In `tryClickInRoot()`, before the OK/Allow click loop, add:

[Code block omitted; consult project-authored source.]

**Note:** The checkbox text varies:
- `UsbConfirmActivity`: "Use by default for this USB device"
- `UsbResolverActivity`: "Use by default for this USB device" (same text, different layout)
- Both contain the word "default" — can also search for that

Revised search:
[Code block omitted; consult project-authored source.]

### 3. Run-CarTest.ps1 — Honda Disable Mode

**What:** New `-HondaDisabled` switch. When set, skip kill loop and send `usb.HONDA_DISABLED` to the service.

**Changes:**

a. Add parameter:
[Code block omitted; consult project-authored source.]

b. Replace Step 7 (kill loop) with conditional:
[Code block omitted; consult project-authored source.]

c. Update READY message:
[Code block omitted; consult project-authored source.]

---

## Expected Flow (Honda Disable Mode)

[Code block omitted; consult project-authored source.]

---

## Testing Plan

### Before Car Test
1. Build v6h APK with the three code changes
2. Verify on laptop: code compiles, APK installs on emulator/device

### Car Test Sequence
1. **First run (set "Never"):** Connect phone normally via USB. When Honda asks, select "Never". Verify Honda no longer auto-starts AA.
2. **Disconnect phone, reconnect ADB.**
3. **Run script:** `.\scripts\Run-CarTest.ps1 -HondaDisabled`
4. **Plug in phone.** Watch for:
   - Raw phone detected by our app
   - Permission dialog appears
   - A11Y auto-clicks "Always use" + OK
   - AOAP switch succeeds
   - AOAP device detected
   - Second permission dialog appears  
   - A11Y auto-clicks OK
   - AA session starts
   - Video on overlay!

### What to Watch in Logs
- `HONDA_DISABLED: Honda set to Never` — our service got the signal
- `Non-AOAP device detected: vid=22d9` — found the raw phone
- `Checked 'Always use' checkbox` / `Checked default-use checkbox` — checkbox auto-click
- `SUCCESS: USB permission for non-AOAP phone` — first permission
- `AOAP mode switch: opening` — AOAP switch initiated
- `AOAP device detected: vid=18d1` — phone re-enumerated
- `SUCCESS: USB permission for AOAP device` — second permission
- `Starting AA session` — success!

### Fallback
If Honda Disable doesn't work:
- Fall back to `-HondaDisabled:$false` (kill loop mode)
- The kill loop is the backup approach
- A11Y auto-click still needed regardless

---

## Risks and Mitigations

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| VBUS_DATA_CDP_OFF causes phone disconnect | LOW | Poll loop handles re-enumeration |
| "Always use" checkbox not accessible to A11Y | MEDIUM | User manually checks it; or search multiple text strings |
| UsbResolverActivity (chooser) for AOAP device | MEDIUM | A11Y needs to handle; user can select our app manually |
| Honda has per-device settings but no "Never" in UI | LOW | Verify in car test step 1 |
| Honda restarts after DEVICE_NOT_SUPPORTED | LOW | Decompiled code shows clean exit path |

---

## Files Modified

| File | Change |
|------|--------|
| `analysis/parallel-aa-receiver/usb-helper/source/.../UsbHelperService.java` | `hondaDisabled` flag + modified gates |
| `analysis/parallel-aa-receiver/usb-helper/source/.../PermissionClickService.java` | "Always use" checkbox auto-click |
| `scripts/Run-CarTest.ps1` | `-HondaDisabled` parameter |

## Files NOT Modified

| File | Reason |
|------|--------|
| `analysis/parallel-aa-receiver/src/.../GalReceiver.java` | Session/receiver code unchanged |
| `analysis/parallel-aa-receiver/src/.../VideoDecoder.java` | v6g decoder fix still included |
| All decompiled files | Read-only reference |
| `PROJECT-RULES.md` | No milestone advancement |
