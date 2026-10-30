# Android Auto configuration trace, 2026-10-22

## Result and scope

**Offline follow-up:** the current priority is HMI mode construction, not preference writes. [Complete HMI/protocol/renderer/input analysis](HMIPresenter-video-mode-analysis.md), [two built offline candidates](fullscreen-candidate/candidate.json), [2022+ reference requirements](2022-reference-needed.md) and [OEM update/signing paths](honda-update-paths.md) supersede the earlier snippet-only artifact status. No ADB or internet command was run in this follow-up. Device/PID/window observations below are captures from the earlier read-only pass, not fresh observations.

The installed APK's Java negotiation mode is hardcoded. No usable shell-accessible override was found in the audited preference writers, exported AA components, Honda Diagnostics, Honda Settings, FactorySettings API or runtime fixup library. This is a conclusion about these paths and this build, not a proof that all possible privileged execution paths are impossible.

Device: serial `00000000`, firmware `D.1.6.4`; installed AA version `5.1.1-14`, UID 1000, PID 2442. All observations were read-only. The current surface policy is back to the stock 1339x720 app area.

Historical archives differ from current packages, but their code matches byte-for-byte. [Archive entry hashes](../logs/2026-10-22-investigation/archive-entry-hashes.json) prove matching DEX for AA, Diagnostics, Settings, Honda manager, services and both framework DEX entries. Current/historical manifest and resources must still be distinguished. Current AA manifest was decoded separately. Historical Diagnostics/Settings manifest findings are backed by matching code, but their current manifests have not been fully re-decoded; do not extend those export assertions beyond the available package evidence.

## The four preferences: exact read path

All following AA paths are relative to `decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/`.

1. `ui/ProjectionActivity.java:1327`: `new Settings(this)`.
2. `settings/Settings.java:44`: `PreferenceManager.getDefaultSharedPreferences(context)`, mode-private package-default preferences. The expected framework filename is `com.honda.androidauto.projection.sink_preferences.xml` under the app's `shared_prefs`; it was not read from the device as shell.
3. `ui/ProjectionActivity.java:2231-2243`, in `prepareStartGAL()`: read the four values, calculate physical DPI as mean of `DisplayMetrics.xdpi` and `ydpi`, construct `DimensionUtils.ScreenSettings`, and pass that object to `ProjectionRenderer`.
4. `video/ProjectionRenderer.java:121`: store the settings and log width/height. Logging these values does not mean they drive negotiation.
5. `video/ProjectionRenderer.java:264`: `updateCodec()` passes incoming logical video bounds plus the settings to `DimensionUtils.makeViewport()`.
6. `video/DimensionUtils.java:14`: start from `videoSize.right/bottom`. If scaling is enabled, apply the smaller of surface-width/video-width and surface-height/video-height; round to even dimensions, clamp to surface and center. This consumes `settings.isScaled()` only. It does not consume stored emulated width, height or DPI.

| Preference | Storage type / default | Parse fallback | Effective behavior |
| --- | --- | --- | --- |
| `screen_width` | String `"1240"` | 800 on NumberFormatException | Stored/logged in ScreenSettings; no active negotiation consumer found. |
| `screen_height` | String `"606"` | 480 on NumberFormatException | Same. |
| `screen_dpi` | String `"160"`, parsed integer then returned float | 160.0 on NumberFormatException | Stored advertised DPI in ScreenSettings; not the HMI mode's advertised DPI. |
| `scale_checkbox` | Boolean true | No explicit type-error fallback | Controls aspect-preserving viewport scaling. False means unscaled incoming logical size, still centered/clamped. |

If any dimension or emulated DPI is zero, `prepareStartGAL()` forces both emulated dimensions to zero and emulated DPI to measured physical DPI. That changes this settings object, not the hardcoded HMI video modes.

`DimensionUtils.makeRequestedVideoSize()` would choose emulated or surface dimensions, but has no call site in the decompiled current APK. `ScreenSettings.getEmulatedDpi()` and `getPhysycalDpi()` likewise have no negotiation consumers. The name `mAdvertisedDpi` inside this legacy object is misleading in the active implementation.

## Every identified writer and override of these preferences

1. **Framework preference persistence in private SettingsActivity.** `res/xml/pref_general.xml` declares the three EditTextPreferences and CheckBoxPreference. Android preference widgets persist numeric input as strings and scaling as a boolean. XML supplies scale default true and preset default 4. The default dimensions themselves are in `Settings` getters, not XML defaults.
2. **`SettingsActivity.handlePresetChange()`**, `settings/SettingsActivity.java:96-140`: commits width/height/DPI as strings. Presets: 0 -> 0/0/0; 1 -> custom (replace individual zero values with 800/480/160); 2 -> 800/480/133; 3 -> 800/480/155; 4 -> 800/480/160; 5 -> 1280/720/215. Custom enables dimension editors; native disables scaling editor; other presets disable dimension editors. Preset handler does not assign scale true/false itself. A preset resource default of 4 is not proof that the handler has run on the vehicle.
3. **`SettingsBroadcastReceiver.onReceive()`**, `settings/SettingsBroadcastReceiver.java:16-35`: copies arbitrary String, Integer or Boolean extras to the same default preferences and commits. It is absent from the current manifest and has no construction/registration/call site found in AA code. Thus it is not an exported working broadcast endpoint. An integer extra for a dimension would also be the wrong storage type for `getString`; the getter catches NumberFormatException, not ClassCastException.
4. **Fallback/default logic**, `Settings.java:48-73` and `ProjectionActivity.prepareStartGAL()` zero handling described above. These are read-time fallbacks/snapshot transformations, not persistent preference writes.
5. **General privileged filesystem/backup/restore access** could in principle replace the private XML, but no working access route exists in this read-only session. This is an external capability, not a newly discovered app writer. Historical backup confirmation failed. External file edits may also require cache reload/process restart; do not assume editing XML updates an existing renderer.

`SettingsUtils` only reads values and updates UI summaries. SimulationSettings writes separate simulation keys. `StartPreferences` edits the separate `gal_start_preferences` file for device names, authorization/autostart/first-run state; it does not override these four keys. No SharedPreference change listener wiring these values into negotiation was found. `SettingsActivity` is private; no AA internal caller launches it. Its SimulationSettings child is also private.

## Actual hardcoded negotiation path

1. `presentation/HMIPresenter.java:819-832`: allocates a new VideoMode. Primary is 1280x688, density 229, 60fps. Secondary is 800x430, density 143, 60fps. Only branch condition is the boolean `primary`. No resource, preference, FactorySettings, Binder, model or property lookup is in this method.
2. `integration/AbstractGalIntegration.java:152-162`: obtains the singleton HMIPresenter directly, reads measured real DPI, calls both modes, calls `nearestVideoConfiguration`, registers both with `VideoSink`, and sets H264 baseline codec type. It uses primary framerate for both calls.
3. `integration/GalIntegration.java:66-67`: delegates with decoderAdditionalDepth=0.
4. Google `com/google/android/projection/protocol/VideoSink.java:78-109`: selects codec enum by width threshold <=800, <=1280, <=1920. Builds width/height margins and density/realDensity/fps fields. The primary becomes `VIDEO_1280x720`, widthMargin=0, heightMargin=32; secondary becomes `VIDEO_800x480`, widthMargin=0, heightMargin=50.
5. `VideoSink.java:116-118`: appends each protobuf configuration and passes its fields into `nativeAddSupportedConfiguration` in `libautoreceiver_jni.so`.
6. `VideoSink.sourceVideoConfigCallback(index)`: looks up the selected local configuration and reconstructs codec dimensions from its enum. `integration/ProjectionListenerWrapper.java:25-26` subtracts margins before forwarding to the Activity.
7. `ui/ProjectionActivity.java:2090-2092`: logs the resulting logical active dimensions and calls renderer `prepareStart(width,height)`.

**Precision correction to the historical notes:** `onSourceVideoConfigChanged width 1280 height 688` is a margin-subtracted logical active area reconstructed from a selected configuration. It is not independent evidence that the H.264 encoded raster itself is 1280x688. The selected codec profile is 1280x720 with 32px margin. Actual H.264 SPS/crop behavior was not independently parsed here. The same distinction applies to proposed 1920x720 active content inside a 1920x1080 profile.

Raw DEX instructions independently confirm the literals: [HMIPresenter.smali](../decompiled/AndroidAuto-current-smali/com/honda/androidauto/projection/sink/presentation/HMIPresenter.smali), method at line 1028, primary constants 0x500 / 0x2b0 / 0xe5 and shared fps 0x3c. Only field writes to VideoMode dimensions in AA were these hardcoded branches. No supported-configuration setter is exposed through AA's Binder interfaces.

## FactorySettings audit

Current `honda-manager` and `services` DEX hashes match the decompiled originals. `IFactorySettingsService` maps read-only transactions 1=getAllEcus, 2=getAllApps, 3=getAllProps, 14=getCurrentValue(String); 4/5/6/7 return car/ECU/app/property metadata. Implementation reads from `/persistdata/honda/factorysettings/factorysettings_database.db`, using read-only SQLite mode for enumeration/value reads. Setter 15, enable transactions 9/12/13 and reapply 17 are mutating and were NOT called. `getAllData` (16) can invoke reapply during startup; its name is not authorization to call it as a read.

[Get-RdxFactoryReadOnly.ps1](../scripts/Get-RdxFactoryReadOnly.ps1) used only transactions 1/2/3/14, preserving raw replies and decoding Android Parcel string lists/strings. Read 81 property names and current values plus ECU/app names. A first parser version failed on the single-line null Parcel response for AM_PRESETS; the parser was corrected and the read-only capture completed. [Names](../logs/2026-10-22-investigation/factory-property-names.json), [values](../logs/2026-10-22-investigation/factory-property-values.json), [apps](../logs/2026-10-22-investigation/factory-app-names.json).

No resolution/width/height/DPI/AA/GAL/fullscreen property was enumerated. `WIRELESS_PROJECTED_ENABLED=0` exists; the archive string scan finds its consumer in CarPlay, not AA. CAMERA_WIDE_SETUP, CTM_WIDE_CONFIG and GUIDES_WIDE_* are camera settings, not projection mode. This does not prove the absence of every opaque OEM flag, but it removes the named-property hypothesis as a justified write experiment.

AA direct FactorySettings consumers: `GalService.retrieveCarInfo()` reads make; `AutoSensors` reads region; `HondaLinkAssistPreferences` reads `E911_ENABLED` and uses the E911 Bluetooth assistance provider. No path from these reads to HMI mode dimensions exists in the audited Java code.

Writes enforce `auto.permission.WRITE_FACTORY_SETTINGS`; sharing UID 1000 does not grant that permission to shell. No factory write was tested. A read-only `DiagnosticsService` transaction 43 (isValidationModeEnabled) returned Permission denied; actual Validation Debug state remains unknown.

## Exported components, providers and shared UID routes

- **AA:** Current manifest exports public ProjectionActivity/device management and media/icon/voice/state services. SettingsActivity, SimulationSettingsActivity and navigation focus service are private. Only StartReceiver is declared; SettingsBroadcastReceiver is not registered. No ContentProvider is declared. Bundled support-v4 FileProvider is a library class only.
- **GalService:** `original_intent` parcelable is processed for USB lifecycle, not arbitrary settings. Remote state Binder exposes foreground/active queries and listeners. Local GalServiceBinder exposes an in-process service object; it is not an arbitrary remotely invocable Java method interface. Icon Binder handles launcher metadata; media/voice services handle playback and voice input. None writes the four keys or overrides VideoMode.
- **Dynamic AA broadcasts:** Hardware/USB/window/media/BT events handle their own domains. The failed-to-decompile IntentController was re-read using JADX simple mode; it handles GPS simulation/night/lockout commands, no display preference writes. No speculative broadcasts were sent.
- **Honda Diagnostics:** Menu targets are code-defined classes, not shell-supplied arbitrary AA targets. Exported InLineActivityService opens a fixed diagnostics activity. ClosingActivity can forward a nested Intent as a broadcast but is private, has no discovered exported arbitrary forwarding path, and would not register the missing AA receiver. No AA preference writer/context broker was found. Standard diagnostics privileges do not become shell privileges.
- **Honda Settings:** Connections UI starts the public `com.honda.gal.settings` device list. Developer OptionWithButtons/List activities switch on recognized system/debug keys, not arbitrary AA preferences. They do not create an AA package context. The Fallback activity only logs and finishes. Notification app-package extras select notification controls, not arbitrary target activities or files. No generic UID-1000 AA configuration broker was identified.
- **Binder Diagnostics/EngineeringAccess:** Interfaces expose diagnostic state/test/vehicle sessions and callbacks. EngineeringAccess is not a generic command execution API. Diagnostics includes broad reset/enable/write operations, which were not invoked and do not supply a narrow resolution setter.
- **Providers:** Captured active-provider inventory and full package dump. SettingsProvider runs UID 1000 but its Global/System/Secure namespaces are separate from AA's private XML; AA does not read the four keys through it. E911 and connections providers serve specific data. No public AA provider endpoint exists in the current manifest.
- **Honda app-fixup:** Pulled and decompiled current `/system/framework/com.honda.app-fixup.jar`. Framework loads it from a fixed `/system` path, not a shell-writable override location. AA's reference is an exemption from audio lifecycle fixup. No projection resolution hook found.
- **Cross-archive check:** Scanned 106 available local APK/JARs; one corrupt ampvcs archive skipped and recorded. Width/DPI/scale strings appear together only in AA. Diagnostics' screen_height hit is the unrelated `top_screen_height` dimension. SystemUI/speech/fixup references to the AA package are not by themselves settings access. This is a string presence survey of available artifacts, not full decompilation of every installed UID-1000 component.
- **Native/socket limit:** Current GAL socket inode is 6712 (historical 6986 obsolete). `/data/misc/gal/socket` metadata, `/proc/2442/fd` and `/proc/2442/maps` are denied. No arbitrary socket traffic, native injection or ptrace attempt was made. Native GAL has not been fully reversed; Java registration proves the supplied modes, not every internal native behavior.

## Completed JDWP test

Current PID 2442 existed before and after an 8-second streaming `adb jdwp` observation. No PID was advertised; stdout/stderr were empty. Terminating the host-side streaming client is not stopping the AA process.

Read-only settings: `debug_app=com.honda.androidauto.projection.sink`, `wait_for_debugger=0`; activity dump confirms persistent mDebugApp and mDebugTransient=false. No debug setting was changed and no process restarted.

The captured current log at line 350 says PID 2442 "can be debugged on port 8100". This is a false positive for actual debugger availability: current matching framework `ActivityThread.handleBindApplication` logs it for debugMode=1 after `Debug.changeDebugPort(8100)`, but `android.os.Debug.changeDebugPort` is an empty deprecated method. Matching services `ActivityManagerService.startProcessLocked` enables the zygote debugger flag from `ApplicationInfo.FLAG_DEBUGGABLE`, absent on AA; mDebugApp is only used later for the bind-application debugMode. Thus the setup has already reached the logged bind stage without exposing JDWP. Repeating set-debug-app/force-stop is not justified by these findings.

No forwarding/attach/instrumentation was attempted. `ActivityManagerService.startInstrumentation` checks target/instrumentation signatures and force-stops the target if accepted. Installing a self-signed instrumentation helper is not an established workaround and would require a head-unit change.

## Candidate and stopping point

[Offline candidates / test plan](fullscreen-candidate/TEST-PLAN.md): A changes only primary dimensions to 1920x720, preserving 229dpi/60fps/fallback; B additionally uses 240dpi as a UI-scale hypothesis (720px at 240dpi = 480dp, close to both stock modes). Neither density is confirmed as Honda's factory fullscreen value. Both offer VIDEO_1920x1080 with margins 0/360 at list index 0, preserving fallback at index 1. TI codec XML declares a 1920x1088 maximum; 1080-profile 60fps reaches its stated block-rate ceiling and successful real playback remains untested.

Two unsigned, unaligned analysis APKs have now been built against the current APK. Independent decompilation, exact DEX-byte validation and unchanged-payload comparison passed. See [byte report A](fullscreen-candidate/dex-patch-report.json) and [byte report B](fullscreen-candidate/dpi240/dex-patch-report.json). They have no valid package signatures and are not installable OEM updates. No signing bypass, root access, temporary hook, trusted install method or verified rollback mechanism has been established. No settings/property change, app launch, restart, install, filesystem write, remount, reboot or flashing operation was performed on the head unit.

The recursive offline survey of all local Honda software/nested dumps found eight identical receiver DEX copies and no newer HMI implementation; [coverage and explicit errors](local-software-search/README.md). Missing official 2022+ artifacts are specified in the reference plan. Red Bend's `/persistdata/app` system-component staging and the matching PackageManager scan are a concrete OEM path for further static investigation, not an established safe deployment method; signatures and recovery remain unresolved.

HMI-only changes are conditionally sufficient for viewport geometry on an already full 1920x720 Activity surface. They do not remove the stock 1339x720 window policy, prove decoder padding/crop or fix the independent type-2 1325x720 TTI input registration. The existing renderer has no hardcoded 290px margins. Width/height preferences remain presentation-side stored/logged data with no active viewport-size consumer; scaling uses the negotiated active video dimensions.

Current offline work stops before any head-unit access. A future modified-mode experiment requires a trusted, reversible execution method and explicit approval. There is no justification to run broad factory-setting writes or repeat failed preference broadcasts/debug-target restarts as a substitute.
