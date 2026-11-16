# Codex review: T340 "choose the main phone on the car" (read-only)

CLAUDE PROPOSES, CODEX ATTACKS. Find counterexamples; do not edit files.

Context: Hackura is an Android Auto receiver app on an Android 5.1 Honda head unit. UsbHelperService decides which
USB phone it takes over (switch to AOAP, request permission, start the AA session). Until T330 a main phone serial had
to be set from a laptop (usb.CONFIGURE_HONDA_NEVER); with no serial the service ran an old "legacy" mode that grabs any
phone and force-stops Honda's Android Auto. Only OnePlus (vendor 0x22d9) phones were switched by vendor.

T340 change (diff: analysis/agent-reviews/t340-phone-on-car/t340.diff; full files under
analysis/test-prep/todo-tests-20261103/builds/T340-bundle/source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/):
1. No main phone and no explicit legacy flag (legacyAnyPhone, set only by usb.CONFIGURE_LEGACY) = setup mode:
   takes over nothing, does not force-stop Honda, only records plugged-in devices (recentDevices) for Settings.
2. Settings > Phone & devices in setup mode lists recorded devices; tapping one sends usb.SET_MAIN_PHONE, accepted
   only while in setup mode. The service then saves the serial, resets its search state and polls again.
3. Devices are switched to AOAP by serial for any brand when they are the main phone or an added device.
4. Every plugged-in device is recorded (filter: valid serial, not vendor 0x1d6b root hubs, not hub class 9, not
   an AOAP-identity 18d1:2d00-2d05 device), once per serial per service lifetime.
5. Wireless daily start is skipped while no main phone is set.

Attack these:
- Can setup mode ever take over a phone or touch Honda (force-stop, VBUS reset, permission request, AOAP switch)?
  Check every path: tick, handleAttached, AUTO_GRANTED, ATTACH_BROADCAST, permission callback, LAUNCH, sticky restarts,
  AttachReceiver, tryDirectGrant.
- Existing installs: a car already configured by the laptop (phoneSerial set) must behave exactly as T330 for the main
  phone. Any behaviour change for it? What about installs where prefs hold phoneSerial=null from an old CONFIGURE_LEGACY
  (no legacyAnyPhone key written then): they become setup mode. Is that acceptable or a hazard?
- SET_MAIN_PHONE races: service not running, startupInitialized false/true, phase states, poll already running,
  a session starting, duplicate taps, a spoofed intent from another app (is UsbHelperService exported? check
  AndroidManifest.xml in the bundle source).
- Switching other brands by serial: any device on the allow list that is not a phone (e.g. USB stick) - harm?
  recordable() edge cases; getSerialNumber() exceptions on Android 5.1 without permission.
- rememberDevice now runs every 500 ms over the device list: cost, SharedPreferences writes, exceptions.
- Wireless skip: any path where a running wireless session or restore duty is broken by the new early return?
- Settings UI: anything that lets the owner end up with no way back (e.g. main phone chosen wrong). Note: changing the
  main phone later needs the laptop or uninstall/reinstall; is that acceptable?

Report: files inspected, findings ranked by severity with file:line evidence, counterexamples, assumptions,
unresolved uncertainties. "All good" without evidence is rejected.

## Update (full T340 diff regenerated 2026-11-13)

Additional T340 changes now in the diff, also attack these:
6. Device names + list for the installer: new actions usb.LIST_DEVICES and usb.RENAME_DEVICE (UsbHelperService),
   logDevices() emits "T340_DEVICE i=.. serial=.. main=.. product=<urlenc> name=<urlenc>" then "T340_DEVICES_END".
   HondaPhonePolicy.withName/nameFor/cleanName/displayName store "serial|name;.." in prefs DEVICE_NAMES. cleanName
   allows only [A-Za-z0-9 ._()-], max 30. SettingsActivity shows names + a "last plugged in" marker and a setup-mode
   "Make main phone" list.
7. rememberDevice now records EVERY plugged-in device each tick (not just setup mode), keyed by serial, with
   retainAll(present) so the list re-orders to newest-plugged-in-first. Attack: unbounded growth, SharedPreferences
   write churn every 500ms tick, serial==null, getSerialNumber() throwing without permission on Android 5.1.

## Security note to verify (do not take on trust)
- Manifest: `<service android:name=".UsbHelperService" android:exported="true" android:permission="android.permission.DUMP"/>`.
  So usb.SET_MAIN_PHONE / LIST_DEVICES / RENAME_DEVICE from another app require the DUMP signature/system permission;
  SettingsActivity reaches them in-process (same UID). Confirm a third-party app cannot set the main phone, rename, or
  list devices without DUMP. Confirm the installer (adb shell, shell UID) CAN (it holds DUMP / shell).
- Names/products are URL-encoded in the log and decoded by the installer; confirm no shell-injection path via the
  installer's `--es name '<value>'` (installer already validates [A-Za-z0-9 ._()-], max 30 before sending).
