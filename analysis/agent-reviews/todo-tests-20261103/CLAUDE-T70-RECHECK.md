# T70 recheck after fixes (Claude subagent, read-only), 2026-11-05

Scope: only the five fixes, under `builds/T70-bundle/source/.../usb-helper/source/com/rdx/fullscreen/usbhelper/` (`T70:` below).
No device, ADB, build or Git writes. This report is the only file written.

## Verdict: READY FOR CAR TEST

| Item | Status | Evidence |
|---|---|---|
| B1: T73 ticks only when the dialog names Hackura | FIXED | `T70:PermissionClickService.java:147-149` gates `tickUseByDefault` on `namesOurApp(root)`; `:162-168` searches for the label. |
| S1: T73 undo and side effects documented | ACCEPTED, DOCUMENTED | `VISIT.md:47`: every plug-in goes to Hackura afterwards, Collect does not undo it, and the undo route is given. |
| S2: unregister by app name | FIXED | `T70:HondaNavBridge.java:26` `APP_NAME = "Hackura"` is used to register (`:109`) and to unregister (`:219`). |
| S3: strip press UP/CANCEL releases | FIXED | `T70:AaOverlayService.java:480-483`: when the strip consumed the event and the action is UP or CANCEL, `scrollStrip.leave()` runs. |
| S4: no zero-distance edge re-grab | FIXED | `T70:ScrollStrip.java:50`: the edge branch requires movement toward that edge; with `dy == 0` it falls through to `:57-58` (clamped MOVE, never `grab(0)`). New host test at `BundleTests.java:75-79`. |

## Label check (the main regression risk)

- `getApplicationInfo().loadLabel(...)` reads the **application** label, `android:label="Hackura"` (`AndroidManifest.xml:17`). The service
  label "RDX USB" is a ServiceInfo label and is not consulted, so the lookup resolves to "Hackura".
- SystemUI builds the prompt from the same application label of the requesting package: `decompiled/SystemUI/.../UsbPermissionActivity.java:50-51`
  (`getApplicationInfo(mPackageName).loadLabel`) with `usb_device_permission_prompt` = "Allow the app %1$s to access the USB device?"
  (`decompiled/SystemUI/resources/res/values/strings.xml:41`). Our dialog therefore contains "Hackura". Honda's dialog contains Honda's
  app label, so it never matches. The checkbox ticked is the one that `setDevicePackage` reads (`UsbPermissionActivity.java:68,96`).
- `findAccessibilityNodeInfosByText` is a case-insensitive substring match. No Honda or SystemUI USB text contains "hackura".
- Residual case, no action needed: a chooser dialog that lists Hackura among several apps would pass `namesOurApp`. The tick
  still does nothing there, because the clicker presses only "OK" or "Allow" and Lollipop's chooser has neither.
- If the car shows a localized SystemUI, the label is still the untranslated "Hackura", so the match holds.

## Other regressions checked

- S3: UP calls `point()` and then `leave()`. When an UP arrives outside the strip while it is active, the non-strip branch (`:228`) releases it. No double UP: `leave()` sends UP only while `dragging`.
- S4: with `dy < 0` the target cannot reach the bottom edge (and vice versa), because the anchor is clamped. The clamp at `:57` keeps every MOVE on screen. The edge re-grab still works for real slides (existing test `BundleTests.java:66-71`).
- S2: the provider component is still passed as `appIntentString` (`:109`), matching stock.

## Preservation

- The T70 APK on disk hashes to sha256 `1BD53F5520DB8F75…`, which matches `build-result.json`
  (BUILT_AND_PACKAGED, 111 bundle checks PASS, baselineRestored=true).
- The frozen anchors were verified in the first review, and none of the five fixes touches them.
