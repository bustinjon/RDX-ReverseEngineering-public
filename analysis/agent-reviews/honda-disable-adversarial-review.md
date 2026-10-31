# Honda Disable Approach — Adversarial Review

**Date:** 2026-10-29
**Reviewer:** Claude Opus (adversarial self-review)
**Hypothesis under test:** Setting Honda's `StartPreferences` to NEVER for the user's phone serial causes Honda to walk away from USB, letting our app win the race.

---

## Files Inspected

- `decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/service/GalService.java`
- `decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/settings/StartPreferences.java`
- `decompiled/Services/sources/com/android/server/usb/UsbSettingsManager.java`
- `decompiled/SystemUI/sources/com/android/systemui/usb/UsbConfirmActivity.java`
- `decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/common/GalUsbReset.java`
- `decompiled/AndroidAuto-current/resources/res/xml/usb_device_filter.xml`
- `analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/UsbHelperService.java`
- `analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/PermissionClickService.java`
- `analysis/parallel-aa-receiver/usb-helper/res/xml/device_filter.xml`

---

## Attack #1: mAllowedDeviceSerial Override — REFUTED

**Claim:** Honda's `mAllowedDeviceSerial` field could override the NEVER preference, allowing Honda to start GAL even when NEVER is set.

**Evidence:** `mAllowedDeviceSerial` is set only in `switchToAccessory()` (GalService line 976). `switchToAccessory` is called only from `setupGui(GALVIEW)` (line 1630), which is only reachable when `mDeviceAccepted == DEVICE_ACCEPTED` (line 794). For NEVER devices, `acceptDevice()` returns `DEVICE_NOT_ACCEPTED` at line 1061 — Honda never reaches `switchToAccessory`. Additionally, `mAllowedDeviceSerial` is an instance variable, not persisted — it resets on process restart.

**Verdict:** NEVER setting CANNOT be bypassed by mAllowedDeviceSerial. **CONFIRMED safe.**

---

## Attack #2: SharedPreferences Writability — CONFIRMED BLOCKED

**Claim:** Shell (uid 2000) or our app (uid 10049) could write Honda's `gal_start_preferences.xml` directly.

**Evidence:** `StartPreferences` uses `getSharedPreferences("gal_start_preferences", 4)` — mode 4 is `MODE_MULTI_PROCESS`, NOT `MODE_WORLD_READABLE` (mode 1) or `MODE_WORLD_WRITEABLE` (mode 2). File lives under `/data/data/com.honda.androidauto.projection.sink/shared_prefs/`. Honda is uid 1000. Shell uid 2000 and our uid 10049 cannot access uid 1000's data directory. The v6g-car-test.ps1 probe (step 4) confirmed "Permission denied" on the head unit.

**Verdict:** We CANNOT write Honda's preferences programmatically. **User must set NEVER through Honda's UI.**

---

## Attack #3: VBUS_DATA_CDP_OFF Disruption — MINOR RISK

**Claim:** Honda's `handleExternalHighSpeedDevice` (line 855) runs for ALL non-accessory USB devices BEFORE the preference check. It reads `/sys/bus/usb/devices/3-1/speed` and sends `VBUS_DATA_CDP_OFF` via the GAL socket if speed ≥ 480 Mbps. This could disrupt our app's USB access.

**Evidence:** `VBUS_DATA_CDP_OFF` is sent to `/data/misc/gal/socket` (GalUsbReset.java). "CDP" = Charging Downstream Port — this is a power signaling change, not a full USB reset. The command fires for raw phone attachment AND for AOAP re-enumeration. Our app's poll loop handles re-enumeration (UsbHelperService lines 236-241).

**Impact for Honda Disable scenario:**
1. Phone plugs in as raw → Honda sends VBUS_DATA_CDP_OFF → possible brief power fluctuation → phone stays connected
2. Phone re-enumerates as AOAP → Honda sends VBUS_DATA_CDP_OFF again → same
3. In both cases, Honda then checks preference → NEVER → walks away

**Verdict:** Our poll loop handles re-enumeration. Power signaling change unlikely to cause data disconnect. **MINOR RISK — monitor in testing.**

---

## Attack #4: Phone Re-enumeration Timing After AOAP Switch — SUPPORTED SAFE

**Claim:** After our app sends the AOAP switch control transfers, the phone detaches and re-enumerates. Honda will receive the USB_DEVICE_ATTACHED broadcast for the new AOAP device.

**Evidence:** For AOAP devices with NEVER preference, Honda's `onUsbDeviceConnected` (line 740-753):
[Code block omitted; consult project-authored source.]
Honda walks away immediately. It does NOT open the USB device, claim interfaces, or start GAL. The only side effect is VBUS_DATA_CDP_OFF (Attack #3).

**Verdict:** Honda walks away cleanly for AOAP + NEVER. **SAFE — no interference with our app claiming the device.**

---

## Attack #5: UsbSettingsManager Chooser Competition — MANAGEABLE

**Claim:** Both Honda and our app match AOAP devices (vid 6353) in their USB device filters. When an AOAP device attaches, UsbSettingsManager.resolveActivity (line 645) sees multiple matches and shows a chooser dialog (UsbResolverActivity).

**Evidence:**
- Honda's `usb_device_filter.xml`: matches vendor-id 6353 (Google AOAP)
- Our `device_filter.xml`: matches vid 6353 + specific PIDs (11520, 11521, 11524, 11525)
- For raw OnePlus (vid 8921): only OUR app matches → `UsbConfirmActivity` (single match)
- For AOAP (vid 6353): both match → `UsbResolverActivity` (chooser) UNLESS saved default exists
- If user checks "Always use" for our app, UsbSettingsManager saves default → auto-launch + auto-grant

**Impact:** First time requires two A11Y auto-clicks (raw permission + AOAP chooser/permission). After "Always use" is saved, subsequent runs auto-grant for that device type.

**Verdict:** Manageable. A11Y must handle both UsbConfirmActivity and UsbResolverActivity. **"Always use" checkbox is the optimization target.**

---

## Attack #6: Alternate startGal Paths — REFUTED

**Claim:** Honda might reach `startGal` through paths other than the preference check.

**Evidence:** All paths to `startGal(device)` in GalService:
1. Line 745: `onUsbDeviceConnected` AOAP + ALWAYS/mAllowedDeviceSerial → preference gated
2. Line 912: `startGalAfterSwitch(device)` → only called after `switchToAccessory` completes, which requires ACCEPTED state
3. Line 1630: `setupGui(GALVIEW)` → only reachable from DEVICE_ACCEPTED flow

Every path is gated on the device being ACCEPTED or ALWAYS. NEVER devices never reach `startGal`.

**Verdict:** REFUTED — no bypass. **CONFIRMED safe.**

---

## Attack #7: REFRESH Broadcast — REFUTED

**Claim:** `StartPreferences.set()` broadcasts `com.honda.androidauto.projection.sink.action.REFRESH`. This might trigger GalService to re-check the device.

**Evidence:** `REFRESH` intent is registered only in `DeviceListActivity` (Settings UI component). GalService has no receiver for `REFRESH`. GalService reads preferences directly from SharedPreferences in `onUsbDeviceConnected` and `acceptDevice`.

**Verdict:** REFRESH is UI-only. **CONFIRMED safe.**

---

## Attack #8: Honda DEVICE_NOT_SUPPORTED State Interference — REFUTED

**Claim:** When Honda sets `changeState(DeviceState.DEVICE_NOT_SUPPORTED)` for a NEVER device, this might block USB access for other apps.

**Evidence:** `changeState` updates GalService's internal `mDeviceState` field. It does NOT close USB connections, release USB interfaces, or lock the USB device. Honda never opens the USB device for NEVER phones (acceptDevice returns before line 1067 `UsbHostSetup.openDevice`).

**Verdict:** Internal state machine change only. **No interference with our app.**

---

## Attack #9: Second VBUS_DATA_CDP_OFF on AOAP Re-attach — MINOR RISK

**Claim:** Honda fires `handleExternalHighSpeedDevice` for the AOAP device too, sending a second VBUS_DATA_CDP_OFF during a session.

**Evidence:** `handleExternalHighSpeedDevice` runs on every `onUsbDeviceConnected` call (line 719) before the isAccessory check. The AOAP device has USB 2.0 (480 Mbps), so it triggers VBUS_DATA_CDP_OFF again.

**Verdict:** Same analysis as Attack #3. Our app handles re-enumeration. **MINOR RISK — monitor in testing.**

---

## Attack #10: forceStopSucceeded Gate Blocks Our AOAP Switch — CONFIRMED BLOCKER (fixable)

**Claim:** UsbHelperService gates non-AOAP phone handling on `forceStopSucceeded`. With Honda Disable approach, Honda is running but disabled — `forceStopSucceeded` is false.

**Evidence:**
- Poll loop (line 195): `if (target == null && forceStopSucceeded && !aoapSwitchSent)` — non-AOAP scan is gated
- Permission callback (line 397): `isNonAoapPhone(device) && forceStopSucceeded` — AOAP switch after permission is gated
- AUTO_GRANTED (line 138): `isNonAoapPhone(device) && forceStopSucceeded` — same gate
- `tryForceStopHonda()` (line 437): our app lacks FORCE_STOP_PACKAGES, always fails
- AOAP device handling (poll line 186-194) is NOT gated — this path works regardless

**Impact:** With Honda NEVER set, phone arrives as raw. Honda walks away. But our app's poll loop won't scan for non-AOAP phones because `forceStopSucceeded` is false. Nobody does the AOAP switch. Deadlock.

**Fix:** Add a `hondaDisabled` flag. Set it via new intent action `usb.HONDA_DISABLED`. Gate non-AOAP handling on `forceStopSucceeded || hondaDisabled`.

**Verdict:** CONFIRMED BLOCKER — but straightforward code fix. Once our app can handle the raw phone, the rest of the flow works: AOAP switch → phone re-enumerates → AOAP path (ungated) → startAaSession.

---

## Summary of Findings

| # | Attack | Verdict | Impact |
|---|--------|---------|--------|
| 1 | mAllowedDeviceSerial override | REFUTED | None |
| 2 | SharedPreferences writability | CONFIRMED BLOCKED | User must use Honda UI |
| 3 | VBUS_DATA_CDP_OFF disruption | MINOR RISK | Monitor in testing |
| 4 | AOAP re-enumeration timing | SAFE | Honda walks away |
| 5 | UsbSettingsManager chooser | MANAGEABLE | A11Y must handle |
| 6 | Alternate startGal paths | REFUTED | None |
| 7 | REFRESH broadcast | REFUTED | None |
| 8 | DEVICE_NOT_SUPPORTED state | REFUTED | None |
| 9 | Second VBUS_DATA_CDP_OFF | MINOR RISK | Monitor in testing |
| 10 | forceStopSucceeded gate | BLOCKER (fixable) | Code change needed |

---

## Confirmed Viable Approach

### Pre-requisite (Manual User Step)
User connects phone normally via USB. When Honda's "Do you want to use Android Auto with this device?" dialog appears, selects **"Never"**. This stores `NEVER (0)` in Honda's `gal_start_preferences` for the phone's serial number.

### Required Code Changes

**1. UsbHelperService.java — Add `hondaDisabled` flag**
- New intent action `usb.HONDA_DISABLED` → sets `hondaDisabled = true`, logs "Honda Disable mode active"
- Modify three gates:
  - Poll loop (line 195): `forceStopSucceeded || hondaDisabled`
  - Permission callback (line 397): `forceStopSucceeded || hondaDisabled`
  - AUTO_GRANTED (line 138): `forceStopSucceeded || hondaDisabled`

**2. PermissionClickService.java — Check "Always use" checkbox**
- Before clicking OK, scan for and check the "Always use this USB device" checkbox
- Standard Android checkbox ID in UsbConfirmActivity: `android:id/always_use`
- In UsbResolverActivity: `com.android.internal.R.id.always_use`
- Saves our app as default → future sessions skip permission dialog for that device type

**3. Run-CarTest.ps1 — Honda Disable mode**
- New parameter: `-HondaDisabled`
- When set: skip kill loop, send `am startservice -a usb.HONDA_DISABLED` to our service
- Keep A11Y, logcat, safety timer setup as-is

### Expected Flow

[Code block omitted; consult project-authored source.]

### Open Questions

1. **Can the user access the "Never" option?** Honda's ASK_USER dialog should present Always/Just-once/Never. The first phone connection with default preference (ASK_USER) triggers this dialog. SUPPORTED but needs verification in car.
2. **Does VBUS_DATA_CDP_OFF cause a brief disconnect?** If so, our poll handles it, but adds 1-2 seconds of jitter. Need to verify in testing.
3. **UsbResolverActivity (chooser) layout for A11Y auto-click?** When both Honda and our app match the AOAP device, the chooser appears. A11Y needs to select our app, check "Always use", and click OK. This is more complex than the simple UsbConfirmActivity case.
4. **Does the "Always use" default persist across reboots?** UsbSettingsManager reads from `/data/system/users/0/usb_device_manager.xml` only at construction — defaults should persist, but need to verify.

### Risk Assessment

- **VBUS_DATA_CDP_OFF disruption**: MINOR — we handle re-enumeration
- **Two permission dialogs**: LOW — A11Y handles both
- **Chooser complexity**: MEDIUM — A11Y needs to handle UsbResolverActivity
- **Honda watchdog not in decompiled code**: LOW — no evidence of additional mechanisms
- **Overall approach viability**: HIGH — all major attack vectors refuted or manageable
