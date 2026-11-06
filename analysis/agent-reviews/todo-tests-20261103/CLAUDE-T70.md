# T70 bundle: independent review (Claude subagent, read-only), 2026-11-05

Scope: `builds/T70-bundle/source` diffed against `builds/T60-bundle/source` (19 files: 13 changed, 6 new facades, plus
HondaNavBridge, HondaNavProviderService and ScrollStrip). Checked against stock smali/decompiled sources, the native strings, the
navlib smali and the car package dump. No device, ADB, build, network or Git writes. Nothing under private-test-material was opened.

Path prefixes: `T70:` = `analysis/test-prep/todo-tests-20261103/builds/T70-bundle/source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/`;
`PROTO:` = same tree `.../usb-helper/source/com/google/android/projection/protocol/`; `SMALI:` = `decompiled/AndroidAuto-current-smali-full/com/google/android/projection/protocol/`;
`NAVLIB:` = the scratchpad `navlib/smali/com/honda/auto/navigation/`; `STOCK:` = `decompiled/AndroidAuto*/sources/com/honda/androidauto/projection/sink/`.

## Verdict: NOT READY FOR CAR TEST (1 BLOCKER, in T73 only)

If the T73 row is dropped from VISIT.md, or B1 is fixed, the rest can go to the car once the SHOULD-FIX items are fixed or accepted.
Every other switch is off by default and, with all switches off, the session matches T60 apart from the intended changes (item 2).

## BLOCKER

**B1. T73 ticks "Use by default" in any SystemUI USB dialog, including the one Honda's own app asks for.**
`T70:PermissionClickService.java:146` calls `tickUseByDefault` for every window that passes `isUsbPermissionWindow`
(`:130-139`). That check only asks for package `com.android.systemui` and the text "USB". Nothing checks that the dialog
names our app ("Hackura", the application label at `AndroidManifest.xml:17`). Honda's GalService raises its own permission dialog:
`STOCK:service/GalService.java:1035-1043` (`usbManager.requestPermission(device, …)` when it has no permission). The project's own
race notes say both dialogs appear on the same plug-in, and the clicker already presses OK on whichever one shows.
*Failure scenario:* with T73 on, Honda's dialog appears second and gets ticked. In API 22, OK plus the ticked box calls
`setDevicePackage` for Honda's package, so Android saves Honda as the default for this phone's AOAP/raw device. From then on, every
plug-in launches Honda's handler with permission already granted, and Hackura loses the race for good. This survives a power-off, and
turning the T73 switch off does not undo it. VISIT.md:43 gives the undo as "Honda Settings > Apps > Hackura > Clear defaults",
which would be the wrong app, and Honda Settings may not show it at all. Collect never clears USB defaults (`builds/T70-bundle/Collect-Test.ps1`:
no default/clear step). The same unguarded tick also fires in the UsbConfirm/UsbResolver dialogs ("USB" text, SystemUI).
*Fix:* tick only when the dialog text contains "Hackura". Log and skip otherwise.

## SHOULD-FIX

**S1. T73 undo and side effects are not handled even when the right app is ticked.** Once Hackura is the default, every AOAP
attach starts `UsbAttachActivity`, which sends `usb.device.AUTO_GRANTED`, which calls `startAaSession`
(`T70:UsbHelperService.java:215-231`). An explicit activity start clears the force-stopped state, so the force-stop protection the
harness relies on (FLAG_EXCLUDE_STOPPED_PACKAGES) stops working, and stock AA never sees USB_DEVICE_ATTACHED for this phone again.
*Scenario:* after the visit the user wants stock AA, or the next harness `Start` assumes a force-stopped Hackura. Instead the phone
is grabbed by our session on every plug-in. Collect should undo this (for example `IUsbManager.clearDefaults(our pkg)` under the
grant, or uninstall), and VISIT.md should say so.

**S2. T74 `unregisterNaviApp` gets the wrong key.** `T70:HondaNavBridge.java:218` passes `HondaNavProviderService.class.getName()`.
The library parameter is `appName` (`NAVLIB:managers/NavigationAppManager.smali:1718`), and stock passes the app name
(`STOCK:navigation/GalNavigationFocusManagerService.java:241`, `unregisterNaviApp("Android Auto")`). Registration used "Hackura"
(`:108`). *Scenario:* after every T74 session (and after the visit), "Hackura" stays registered in Honda's navigation framework, as a
nav app the framework can still bind or list. Later sessions see `-3` and carry on, so the failure is silent. Fix: pass `"Hackura"`.

**S3. T71: a press released inside the strip never lets go of the drag.** The press path always calls `sideScroll(x, y, false)`
(`T70:AaOverlayService.java:480`), including for ACTION_UP and ACTION_CANCEL. Only the hover path maps lift to `leave()` (`:588-590`).
*Scenario:* the finger hovers onto the strip, presses (Android sends HOVER_EXIT, then DOWN), slides (the drag starts), then releases
the button and lifts at the same moment. UP is consumed as a `point()` and no hover exit follows, so the phone keeps pointer 0 down
(a list held or scrolling). It is released only by the next hover outside the strip, by minimize or by teardown. Fix: pass
`leaving = (action == UP || action == CANCEL)` at `:480`.

**S4. T71: the edge re-grab can produce a tap.** `T70:ScrollStrip.java:50-54` sends UP and then `grab(Math.signum(dy), …)`. When
`dy == 0` exactly, which happens once the finger returns to `startRawY` while the anchor sits at `EDGE` (anchor y < 40 is clamped
by `clamp`), `grab(0)` sends DOWN and a MOVE with zero distance (`:68-70`). If the next event is a lift, `leave()` sends UP at the same
point, which is a tap at the top row (`:76`). The case is narrow (whole-pixel raw y makes the equality reachable), but it breaks the
"never a tap" claim. Fix: keep the previous drag direction, or skip the edge branch when `dy == 0`. No host test covers it
(`builds/T70-bundle/BundleTests.java:50-77`).

## Items

1. **JNI ABI: OK.** The facades match the stock smali exactly: field `mNative*`, `nativeInit(IJ)I` / `(IJIIIII)I` / `(IJLjava/lang/String;)I`,
   `nativeSetDeviceInfo(Ljava/lang/String;[I)V`, the callbacks `mediaPlaybackStatusCallback(ILjava/lang/String;IZZZ)V`,
   `mediaPlaybackMetadataCallback(…[BLjava/lang/String;II)V`, the navigation callbacks `(I)V`, `(Ljava/lang/String;II[BII)V`, `(IIII)V`,
   `onPairingRequest(Ljava/lang/String;I)V`, `onWifiCredentialsRequest()Lcom/google/android/projection/protocol/CarWifi$CarWifiCredentials;`,
   and the `wifiSsid/wifiPassword/wifiSecurityMode` fields. Evidence: `SMALI:*.smali` and `analysis/libautoreceiver_jni.so.strings.txt:13445-13452,13486-13488,13578-13605`.
   The create order matches stock (init, then SetDeviceInfo, and init, then nativeStart, as in `SMALI:BluetoothEndpoint.smali:83-110`
   and `NavigationStatus.smali:171-205`). The NavigationStatus arguments (500, ENUM=2, 0, 0, 0) match `STOCK:integration/GalIntegration.java:62`
   and the Protos `ENUM(1,2)` entry. The ids 8/9/10 equal the stock constants (`STOCK:integration/AbstractGalIntegration.java:35-42`).
   14 is unused by stock, and stock never registers Wi-Fi projection, so how the phone reacts to it is **UNKNOWN** (P3 is off by default).
   On failure, registration logs and skips, and `destroy()` is a no-op if `nativeInit` failed (`created` guard). Teardown runs after the
   reader, writer and ping threads have joined, destroys the children before `receiver.destroy()` (as stock `GalReceiver.destroy` does),
   and skips everything if the workers are not confirmed stopped (`T70:AaSessionService.java:846-864`). The Bluetooth pairing reply
   re-checks `running` on the main thread (`:567-570`). The override of `GalReceiver` only adds `register(long,String)` (diffed against
   `analysis/parallel-aa-receiver/src/.../GalReceiver.java`), and the build gives usb-helper/source precedence (`scripts/Build-RdxUsbHelper.ps1:55-60`).
2. **All switches off: OK.** `sideScroll` returns false when the switch is off (`AaOverlayService.java:225`), the strip `leave()` is a no-op,
   track/nav/wireless are not registered (`AaSessionService.java:425-431`), the T73 tick is gated, and car GPS is unchanged. The intended
   differences are: `dpi` replaces `layoutDpi`, touch is always top-aligned, recovery is always false, there is no TAP OK overlay, a short
   side-panel press does nothing, onGetRoot uses the saved setting, and there are launch toasts. Two further visible differences: the
   media session always carries base metadata "Hackura"/"Android Auto" and its tag is now "Hackura" (`AaMediaSourceService.java:99,109-111`),
   which VISIT 2.4 expects. No live references to probe, touchCentered or self-recovery remain (grep of the T70 tree and scripts). The
   only leftovers are a stale test label "Short side panel = restore" (`BundleTests.java:42`) and the dead reconnect branch in `startAaSession`.
3. **ScrollStrip:** S3 and S4 above. Otherwise OK: below the threshold nothing is sent; a press beginning on the main area is never
   taken over (`isPressed`, `:227`); a press starting in the strip and sliding out gives `press()` returning -1, so there is no tap;
   minimize and teardown call `leave()` (`:890`). The tests cover the pure logic but not the overlay wiring.
4. **T72: OK.** The callbacks marshal to the main thread (`AaMediaSourceService.java:52-84`). The registration needs the switch, so there
   is no metadata when it is off. Stale callbacks are dropped by `enabledLive()`, and the reset happens on session end (`:43`).
   The state mapping 1/2/3 matches Protos `STOPPED(0,1)/PLAYING(1,2)/PAUSED(2,3)`. The art decode runs on the native callback thread,
   capped at 2 MB, without scaling, the same as stock (`STOCK:service/media/GalMediaSessionService.java:254`). Note: ART and ALBUM_ART
   both carry the same bitmap, so it is parceled twice.
5. **T73: BLOCKER B1 and SHOULD-FIX S1.** The persistence claim (VISIT.md:43, 49) is plausible for the right package: our
   `UsbAttachActivity` filter covers 18d1:2d00/2d01 and 22d9 (`usb-helper/res/xml/device_filter.xml`). It is not verified on this firmware.
6. **Persistent / auto-accept: OK.** `startOnce` runs on the main thread only (from a receiver and a service onCreate), returns early
   when persistent mode is off (`PersistentBootService.java:24`), and re-arms only if `startService` throws. The latch is per process,
   not per boot: if Honda rebinds after our process dies, the boot path runs again, which matches what START_STICKY already does.
   The Settings button calls `ensureAccessibilityResult`, which only appends our component (`PersistentMode.java:39-42`). It also
   writes `accessibility_enabled=1`, which re-enables any other listed services; that behaviour predates T70.
7. **Launch toasts: OK.** `launchRefusal` cannot block forever. With recovery always false, `reconnect` is never armed
   (`UsbHelperService.java:553` is unreachable), and an unclean end clears on the next replug because the replug path does not go through
   `launchRefusal`. The WAITING wording "waiting for the USB permission" is wrong when the helper is simply polling, but harmless.
8. **AppSettings: OK.** The migration is idempotent and gated by `schema < 70` on every `prefs()` call (`AppSettings.java:44-58`). It
   uses one process (no `android:process` in the manifest), keeps dpi and volume_display, and intentionally overwrites the T60 switch
   values. Settings, BundleTests and VISIT.md agree on the defaults (`BundleTests.java:16-24`, VISIT 2.1).
9. **T74 (apart from S2): OK.** The reflection signatures exist and are public: `NavigationManager.getInstance(Context)` and
   `getNavigationAppManager()`, `NaviAppAttribute(String appName, String appIntentString)` and its setters,
   `requestGuidingFocus/abandonGuidingFocus(GuidingFocusListener)I`, `setGuidanceStatus/setManeuvers(List)/setRouteInfoVolatile`,
   and the Maneuver, Distance and RouteInfoVolatile setters (`NAVLIB:managers/*.smali`, `navigationinfo/*.smali`). The enum `$1` classes
   are Parcelable.Creator, not constant bodies, so `g.getClass()` lookups are safe. Every ManeuverType name produced exists. Focus is
   granted when the result is 1 (`NavigationAppManager.smali:1176-1260`). The binder replies match the Proxy:
   `readException`, then `createTypedArrayList` (count, then a 1 flag and the parcelable each), parcelable returns are a flag plus the
   body, and isProviderEnabled is an int. The default `writeInt(0)` safely decodes as 0, false, null or an empty list for every other
   method (`NAVLIB:providers/INavigationInfoProviderService$Stub$Proxy.smali`). `com.honda.navigationframework` and
   `navigationservice` run as uid 1000 (`adb/RDX-Audit/logs/dumpsys-package-full.txt:10949,8535`), so exported=false can be bound,
   and the caller check passes them. Both permissions are `prot=normal` (`:3433-3445,3703-3713`). If the library is absent, `fail()`
   sets `dead`. Posts after `quitSafely` are dropped without a crash. The service binder is fetched synchronously through
   `ServiceManager.getService` (`NavigationAppManager.smali:625-700`), so the single attempt is fine. Minor: `focused` is written from
   the listener transport thread and is not volatile. On release, stock sets NO_ROUTE where we set IDLE (`GalNavigationFocusManagerService.java:239`).

## Preservation checks (sha256, first 16 hex characters)

| Artifact | Expected | Actual |
|---|---|---|
| Frozen M5 APK `m5-permission/build/20261023-180320-335/…development.apk` | A22E96490B9557AF | A22E96490B9557AF |
| M6 `m6-aoa/build/FINAL/rdx-m6-aoa-only-disabled.apk` | D4DAC2DD8B2AFF1F | D4DAC2DD8B2AFF1F |
| Receiver DEX (both `clean-receiver/build/*/dex/classes.dex`) | 2FDBC63F2F9D63B7 | 2FDBC63F2F9D63B7 |
| API22 TLS qualifier APK | 86350131FFC5CBE5 | 86350131FFC5CBE5 |
| `builds/T70-bundle/rdx-t70-bundle.apk` vs `build-result.json` | 292A5D6984E19FA2 | 292A5D6984E19FA2 |

The working tree is back on baseline (`build-result.json` baselineRestored=true; ScrollStrip, HondaNavBridge and the GalReceiver
override are absent from the live `usb-helper/source`). This review changed no files apart from writing this report.
