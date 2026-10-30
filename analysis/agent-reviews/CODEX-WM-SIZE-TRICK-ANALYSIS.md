1. **Files inspected**

   Primary sources:

   - `decompiled/Services/sources/com/android/server/wm/{WindowManagerService,DisplayContent,DisplaySettings}.java`
   - `decompiled/Services/sources/com/android/server/display/{DisplayManagerService,LogicalDisplay,DisplayDevice}.java`
   - `decompiled/Services/sources/com/android/server/input/InputManagerService.java`
   - `decompiled/Framework/sources/android/view/{IWindowManager,Display,DisplayInfo,SurfaceControl,KeyEvent}.java`
   - `decompiled/Policy/sources/com/android/internal/policy/impl/PhoneWindowManager.java`
   - `decompiled/Policy/sources/com/honda/touchpad/VirtualPointer.java`
   - Honda `CollisionAlertDialog`, SystemUI `HondaStatusBarWindowManager`, Diagnostics `MenuActivity`, `USBModeSwitchActivity`, `DisplayAdjustmentActivity`, and Honda `FactoryReset`.
   - `decompiled/AndroidAuto-current/`: `DimensionUtils`, `ProjectionRenderer`, `ProjectionActivity`, its `VirtualPointer`, `Settings`, `HMIPresenter`, `AbstractGalIntegration`, `GalIntegration`, `VideoSink`, and `activity_main.xml`.
   - Corresponding `ProjectionRenderer.smali`.
   - Saved `wm.jar`, package/UID dumps, `adb/AA-live-logcat.txt`, specified before/display/window dumps, Notes, project rules, and preservation-manifest entries.

2. **Files changed**

   **None.**

3. **Commands run**

   Read-only commands: `Get-Content`, numbered source reads, `rg`, `rg --files`, `Get-ChildItem`, `Get-Command`, `git status --short`, scoped `git diff --stat/--numstat`, `Get-FileHash`, and `jar tf`.

   In-memory Node scripts:

   - Decoded `wm.jar`’s DEX command dispatch and relevant method calls.
   - Reproduced Java float arithmetic, viewport rounding, and display-projection integer arithmetic.
   - Counted log lines by LF, accounting for encoding and CR-CR-LF.

   Unsuccessful inspection attempts included Python launch failures, a constrained-PowerShell method invocation, and a JShell/JADX attempt that failed on denied Java preferences access. No decompiled output was saved.

   **No ADB, fastboot, device interaction, build, or milestone action occurred.**

4. **Tests run and results**

   - **Arithmetic reproduction: PASS.** The implementation reproduces the saved baseline `Rect(290,0 - 1630,720)` and calculates the proposed sizes below.
   - **Saved `wm.jar` inspection: PASS.** Found `size`, `density`, `overscan`, their reset branches, and corresponding `IWindowManager` calls.
   - **Frozen-artifact hashes: PASS**, all four match `PROJECT-RULES.md`; hashes appear in item 10.
   - **Scoped tracked-file diff: empty.**
   - **Live behavior: NOT TESTED.**

5. **Findings**

   **Verdict — SUPPORTED: this trick should not produce full-width, horizontally stretched AA.** This firmware aspect-fits the **whole logical display** into the physical panel. Making the logical display taller therefore adds physical side bars around the desktop. AA becomes almost full-width *inside that narrower desktop*, leaving approximately the same 1340-pixel physical video width as before. [E2–E4, E8]

   **Q1 — CONFIRMED: the saved firmware supports shell `wm size` and `wm density`.**

   The saved `wm.jar` dispatches:

   - `size` → `runDisplaySize` → `setForcedDisplaySize(0, …)` or `clearForcedDisplaySize(0)`.
   - `density` → `runDisplayDensity` → `setForcedDisplayDensity(0, …)` or its clear method.
   - `overscan` → `runDisplayOverscan` → `setOverscan(0, …)`.

   Its usage text explicitly lists all three. Density parsing rejects values below **72**. [E1]

   WMS requires `android.permission.WRITE_SECURE_SETTINGS` for size, density, overscan, and their relevant resets. Size/density are restricted to display 0. These methods contain no additional Honda-specific authorization gate. The saved package dump grants `WRITE_SECURE_SETTINGS` to shared UID **2000**, `android.uid.shell`; the saved shell identity independently reports UID 2000. Root is therefore not required by these inspected paths. [E2, E5]

   Overscan shares the permission/Binder interface but uses **different persistence**: `/data/system/display_settings.xml`, indexed by display identity. Reset supplies zero offsets, removing the saved entry; a later boot can consequently use resource defaults. Size/density use Settings.Global instead. [E2, E6]

   **Q2 — CONFIRMED: taller logical sizes are permitted; the framework does not stretch them across the panel.**

   The actual clamping code is:

   ```java
   int width2 = Math.min(Math.max(width, 200),
                        displayContent.mInitialDisplayWidth * 2);
   int height2 = Math.min(Math.max(height, 200),
                         displayContent.mInitialDisplayHeight * 2);
   ```

   For the saved initial **1920×720**, the independent limits are **200–3840 wide** and **200–1440 high**. Both proposed sizes are accepted without aspect-ratio correction. There is no “cannot exceed physical height” restriction here. [E2]

   The changed base dimensions become `DisplayInfo.logicalWidth/logicalHeight`; app dimensions are calculated through Honda policy. WMS sends that override to DisplayManagerService, and LogicalDisplay uses the override when configuring the device. Apps therefore see changed logical dimensions, subject to their window insets and compatibility behavior. [E3]

   The decisive projection code is:

   ```java
   displayRectWidth =
       (displayInfo.logicalWidth * physHeight) / displayInfo.logicalHeight;
   displayRectHeight = physHeight;
   ```

   This is the branch selected for both proposed sizes. It centers that rectangle and passes **logical source rectangle → fitted physical destination rectangle** to `SurfaceControl.setDisplayProjection`. [E4]

   | Forced logical size | Physical destination on 1920×720 panel |
   |---|---|
   | 1920×1031 | `Rect(290,0 - 1630,720)` — **1340×720** |
   | 1920×1000 | `Rect(269,0 - 1651,720)` — **1382×720** |

   Thus the proposed independent scaling of X by 1 and Y by about 0.70 is absent. Both axes shrink by approximately 0.70 or 0.72. Integer rounding introduces only a tiny ratio difference. The saved `wm` command also has no scaling-mode subcommand. [E1, E4]

   **Q3 — CONFIRMED persistence; recovery beyond working ADB is partly UNKNOWN.**

   - Size is stored as Settings.Global **`display_size_forced`**, formatted `width,height`.
   - Density is stored as **`display_density_forced`**.
   - `displayReady()` reads both at startup. A normal reboot is therefore **not a recovery reset**.
   - Empty settings fall back to `ro.config.size_override` / `ro.config.density_override`.
   - The clear methods restore initial dimensions/density immediately and empty the corresponding setting. [E2]

   The direct recovery commands are:

   ```text
   adb shell wm size reset
   adb shell wm density reset
   ```

   Density reset is needed only if density was changed. Overscan is independent.

   **SUPPORTED:** physical **HOME+BACK+GUIDE held for three seconds** remains a geometry-independent *launch mechanism* for Dealer Diagnostics: policy checks keycodes 3, 4, and 172 and starts the Diagnostics intent. The Developer menu unlock checks GUIDE, with a five-second delay on the designated detail menu. [E10]

   **UNKNOWN:** whether the resulting Diagnostics screens, touchpad navigation, and USB Mode Switch remain practically usable under the altered geometry. USB Mode Switch still requires selecting a menu item; its ADB choice writes `dev.adb=1`. It does not reset forced size. “Display adjustment” controls LCD contrast/brightness/color/tint/illumination, rather than WMS resolution. [E11]

   **UNKNOWN:** Honda factory reset’s complete handling of these settings. The inspected reset code ultimately requests `reboot,factoryreset`; the actual recovery-side wipe behavior was not established. Do not treat that menu as a proven size-recovery route. [E12]

   No timed rollback or boot-time forced-size reset was found in the inspected WMS paths. A separate native/vendor watchdog remains **UNKNOWN**. The supported worst-case concern is a **persistent unusable HMI with no established independent recovery if ADB is lost**.

   **Q4 — SUPPORTED: Honda layout changes globally; exact touchpad and camera consequences remain UNKNOWN.**

   Honda subtracts a resource-defined B-zone width from app width:

   ```text
   fullWidth − overscanLeft − overscanRight − BzoneWidth
   ```

   At the saved density and 581-pixel B-zone, right overscan `−581` cancels that reservation. Increasing logical height does not itself remove the B-zone. The specified October dump actually records **app 1339×720**, with a **581×720 type-2014 SystemUI window** at X=1339; it is not a capture of the fullscreen-overscan state. [E7]

   SystemUI obtains the B-zone width from the same resource and requests full available height. Honda’s policy derives screen, content, dock, stable, and navigation frames from logical dimensions and overscan. Consequently, size affects ordinary HMI windows and overlays too. Density can additionally alter resource dimensions and dp layout; continued cancellation by a fixed `−581` is not established after density changes. [E7]

   Input evidence has two distinct levels:

   - **CONFIRMED:** DisplayDevice builds an input viewport containing both logical and physical rectangles. DisplayManagerService forwards it to InputManagerService, which passes both rectangles and device dimensions into native input handling. [E9]
   - **UNKNOWN:** the complete Honda touchpad absolute-coordinate transformation inside native input/vendor code. The Java viewport plumbing does not prove that every Honda input path honors it.
   - **CONFIRMED:** Policy’s `com.honda.touchpad.VirtualPointer` merely draws at the delivered event X/Y; it supplies no independent physical-to-logical correction.
   - AA’s separate VirtualPointer clamps to the texture bounds and subtracts texture offsets before renderer conversion. It also does not establish the upstream native mapping. [E9]

   **SUPPORTED risks:** smaller physical controls, changed resource/layout selection, and input offsets or unreachable regions if any vendor path assumes physical coordinates. A broken HMI is possible, but **not established**.

   CollisionAlertDialog uses a type-2033 window and sizes it from `Display.getMetrics()`, so its Android overlay geometry participates in the change. **UNKNOWN:** alignment with the actual rear-camera image or other native/LCD planes. Camera correctness cannot be inferred from AA or ordinary window behavior. [E13]

   **Q5 — CONFIRMED conditional arithmetic; runtime relayout timing matters.**

   Assuming the initial AA texture/container actually becomes **1920×H**, `isScaled()` remains true, and negotiated video remains **1280×688**:

   | Calculation | H=1031 | H=1000 |
   |---|---:|---:|
   | Aspect-fit factor | `1031/688 ≈ 1.4985465` | `1000/688 ≈ 1.4534884` |
   | `makeViewport` result | `Rect(1,0 - 1919,1030)` | `Rect(30,0 - 1890,1000)` |
   | Requested texture dimensions | **1918×1030** | **1860×1000** |
   | Transform scale X | **1** | **1** |
   | Transform scale Y | **45/43 ≈ 1.0465117** | **45/43 ≈ 1.0465117** |
   | Initial transform pivot | **(959,515)** | **(930,500)** |
   | Touch X, while surface frame remains 1920×H | `1280/1920 = 2/3` | `2/3` |
   | Touch Y at that point | `688/1031 ≈ 0.6673133` | `688/1000 = 0.688` |
   | Approximate physical texture width after display projection | **1338.6042 px** | **1338.8125 px** |

   The **1031-high viewport becomes 1030 high**, because `makeViewport` rounds dimensions to even integers. These are texture-box predictions, not measurements of every visible decoded-content pixel. [E8]

   There is an important timing qualification. Renderer creation can occur **before** the texture-size callback. The saved log demonstrates exactly that sequence: codec creation uses the original 1920×720 frame, then the size-change callback arrives later. Touch factors are assigned during codec creation and are not refreshed merely because the surface changes while that codec remains running. [E8]

   If codec creation instead occurs after the requested relayout:

   - **1031 case:** frame 1918×1030; touch factors `1280/1918 ≈ 0.6673619` and `688/1030 ≈ 0.6679612`. A second `makeViewport` calculation yields 1916×1030, giving transform pivot **(958,515)**.
   - **1000 case:** frame 1860×1000; touch factors `1280/1860 ≈ 0.6881720` and **0.688**; pivot remains **(930,500)**.

   Which factors are retained in a new forced-size session is **UNKNOWN without its event sequence**. The smali confirms these divisions are floating-point; JADX’s displayed integer-looking division must not be evaluated as Java integer division. [E8]

   **CONFIRMED: emulated-screen dimensions are preferences, not display dimensions.**

   `Settings` supplies defaults **1240×606**, advertised DPI **160**, and scale-to-screen **true**. ProjectionActivity reads DisplayMetrics only for average **physical** X/Y DPI. Forced logical dimensions do not populate the emulated width or height. [E14]

   The separate SDR configuration uses `HMIPresenter`’s hard-coded modes:

   - 1280×688, 229 DPI, 60 fps → 1280×720 codec resolution, height margin 32.
   - 800×430, 143 DPI, 60 fps → 800×480 codec resolution, height margin 50.

   Physical `xdpi/ydpi` supplies `realDensity`; it is separate from forced logical density. The saved display reports physical DPI 200×200. Therefore, **SUPPORTED:** size/density changes alter local layout rather than these advertised resolution/margin/density fields. No inspected path connects the emulated-screen preference dimensions to the advertised configurations. [E14–E15]

   **Q6 — SUPPORTED prediction and documentation-only reversible test**

   Best prediction: a narrower, aspect-preserved Honda desktop with AA still approximately **1340 physical pixels wide**, plus potentially changed HMI/input behavior. Density cannot remove the projection’s aspect-fit constraint. A full-width stretched result would contradict the inspected Java projection path and require additional native/vendor behavior not established here.

   A minimal future test should change **size only**, retain the existing density, and record the exact starting overscan. If there is already a size override, restore that recorded size instead of using reset.

   **Documentation only — none of these commands was run:**

   ```text
   # Immediate recovery command, prepared before changing size:
   adb shell wm size reset

   # Before:
   adb shell wm size
   adb shell wm density
   adb shell settings get global display_size_forced
   adb shell settings get global display_density_forced
   adb shell dumpsys display
   adb shell dumpsys window
   adb shell dumpsys input

   # Optional timed reset: start in a separate terminal FIRST.
   adb shell "sleep 30; wm size reset"

   # One candidate per trial:
   adb shell wm size 1920x1031

   # Immediately after: repeat display/window/input captures and collect:
   adb shell logcat -d -v threadtime

   # Restore:
   adb shell wm size reset
   ```

   Repeat with `1920x1000` only after confirming restoration. Do not combine a first size trial with density changes. If overscan must be changed to establish the fullscreen baseline, document that separately:

   ```text
   adb shell wm overscan 0,0,-581,0
   ```

   Afterwards restore the **recorded** overscan; `wm overscan reset` restores the default path, whereas `0,0,-581,0` restores the user’s stated fullscreen setting.

   Capture before/after/restored panel photographs and AA logs showing surface dimensions, viewport, transform, and emulated screen. Compare `mOverrideDisplayInfo`, `mCurrentLayerStackRect`, `mCurrentDisplayRect`, and input viewport rectangles. A physical photograph is necessary to distinguish logical screenshot geometry from actual panel occupancy.

   The delayed reset is a convenience, **not guaranteed recovery** if its shell dies or WMS stops responding.

6. **Primary evidence for each finding**

   Links below use the workspace root. Line numbers were counted with `rg` or explicit numbered reads.

   | ID | Primary evidence |
   |---|---|
   | **E1** | `adb/RDX-Audit/full-system/framework/wm.jar`, SHA-256 **A1DCD0E801CF2149F0E72650E561FDD3F1E74CCFF9E51038D487D575E31A9968**. In extracted DEX: `onRun` code item `0xA70`, dispatch instructions `0x23–0x43`; size code item `0x864`, setter/reset invokes `0x81/0xE0`; density `0x5F8`, invokes `0x55/0x88`, minimum 72 at `0x5F`; overscan `0x750`, setter `0x20`; usage `0xB48`. Offsets are DEX code-item byte offsets plus instruction offsets in 16-bit code units. |
   | **E2** | [WindowManagerService.java:5855](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/wm/WindowManagerService.java:5855), lines 5855–6084: permissions, clamps, persistence, reconfiguration and resets. Boot read: lines 5670–5683; settings/property fallback: 5880–5914. |
   | **E3** | [WindowManagerService.java:5397](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/wm/WindowManagerService.java:5397), lines 5397–5435; `DisplayManagerService.java:333–339`; `LogicalDisplay.java:39–65`; `Display.java:240–265`; `DisplayInfo.java:227–248`. |
   | **E4** | [LogicalDisplay.java:130](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/display/LogicalDisplay.java:130), lines 130–156; `DisplayDevice.java:65–76`; `SurfaceControl.java:323–333`. Saved physical device/projection: specified `before/display.txt:59–79`. |
   | **E5** | [dumpsys-package-full.txt:14385](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/adb/RDX-Audit/logs/dumpsys-package-full.txt:14385), shared UID and granted permission at 14447; `adb/RDX-Audit/security/shell-id.txt:1`. |
   | **E6** | [DisplaySettings.java:39](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/wm/DisplaySettings.java:39), lines 39–97; XML serialization at 236–266; WMS persistence calls at 6082–6083. |
   | **E7** | [PhoneWindowManager.java:1764](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Policy/sources/com/android/internal/policy/impl/PhoneWindowManager.java:1764), lines 1764–1781 and 3101–3157; resource initialization at 1252. `HondaStatusBarWindowManager.java:23–36`. Specified `before/display.txt:79`, `before/window.txt:163–167`. |
   | **E8** | [DimensionUtils.java:14](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/video/DimensionUtils.java:14), lines 14–28. `ProjectionRenderer.java:243–324,525–541,638–660`; corresponding smali lines 611–676 and 1036–1067. Raw `adb/AA-live-logcat.txt:11971–12027` demonstrates pre-callback codec creation. |
   | **E9** | [InputManagerService.java:327](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Services/sources/com/android/server/input/InputManagerService.java:327), lines 327–339; `DisplayDevice.java:87–105`; `DisplayManagerService.java:820–832,957`. Policy VirtualPointer lines 61–77; AA VirtualPointer lines 65–111; ProjectionActivity lines 517–519. |
   | **E10** | [PhoneWindowManager.java:2098](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Policy/sources/com/android/internal/policy/impl/PhoneWindowManager.java:2098), lines 2098–2161 and 6003–6057; `KeyEvent.java:52,138,143`. Diagnostics `MenuActivity.java:49–55,289–311`. |
   | **E11** | [USBModeSwitchActivity.java:16](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/HondaDiagnostics/sources/com/honda/auto/diagnostics/developer/USBModeSwitchActivity.java:16), lines 16–20,39–63. `DisplayAdjustmentActivity.java:52–81`. |
   | **E12** | [FactoryReset.java:327](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/HondaManager/sources/com/honda/factoryreset/FactoryReset.java:327), lines 327–329. This establishes the reboot request, not recovery-side settings deletion. |
   | **E13** | [CollisionAlertDialog.java:104](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/Policy/sources/com/honda/auto/policy/popup/CollisionAlertDialog.java:104), lines 104–112,152–159. |
   | **E14** | [Settings.java:48](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/settings/Settings.java:48), lines 48–73; `ProjectionActivity.java:2231–2243`; `DimensionUtils.java:38–59`. |
   | **E15** | [HMIPresenter.java:819](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/presentation/HMIPresenter.java:819), lines 819–832; `AbstractGalIntegration.java:152–162`; `GalIntegration.java:66–67`; `VideoSink.java:78–118`; `DisplayInfo.java:228–246`. |

7. **Assumptions**

   - The supplied saved framework/decompilation represents the target D.1.6.4 paths; runtime binary parity was not newly established.
   - Numerical AA predictions assume a 1920×H initial container, scale enabled, primary 1280×688 video, rotation 0, and unchanged 1920×720 physical device.
   - Calculated physical texture bounds assume the native compositor honors the projection rectangles supplied by this framework.

8. **Unresolved uncertainties — ranked**

   1. **UNKNOWN:** native compositor/HWC behavior that might override the supplied projection.
   2. **UNKNOWN:** complete Honda touchpad absolute mapping under unequal physical/logical geometry.
   3. **UNKNOWN:** practical recovery through Diagnostics if ADB becomes unavailable.
   4. **UNKNOWN:** camera/native-plane alignment and all safety-popup layouts.
   5. **UNKNOWN:** forced-size AA relayout ordering and retained touch factors.
   6. **UNKNOWN:** vendor watchdogs and factory-reset clearing of the forced settings.

9. **Exact diff summary**

   **None produced.** Scoped `git diff --stat` and `--numstat` returned no changes.

   Concurrent changes appeared under `analysis/agent-reviews/`; their contents were ignored as instructed.

10. **Preservation checks performed**

   SHA-256 verification matched all four frozen anchors:

   | Artifact | Verified SHA-256 |
   |---|---|
   | M5 APK | `A22E96490B9557AFF022893A8B8B7A08BB13CEC236E52704CDDAFA90A8EE8F40` |
   | Disabled M6 APK | `D4DAC2DD8B2AFF1FA7B64BFB32D2A5E889854CCEB4B4A9F7AD5AEF89FB28761F` |
   | Receiver DEX | `2FDBC63F2F9D63B764697D311AF89D460AE6B8E14B0FADABA9C9339F7FE7C235` |
   | API22 qualifier APK | `86350131FFC5CBE5766E523AB03AE07D4C9F5EAD78F0570B68255C9A3999FC1F` |

   No key-material files were opened. No artifacts were rebuilt, no repository files were written, and no agents were spawned.