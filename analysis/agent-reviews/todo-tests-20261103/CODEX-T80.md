**Verdict: READY FOR CAR TEST for the parked checks in VISIT.md:16. No confirmed BLOCKER.** The SHOULD-FIX findings below limit the claimed fixes; offline review does not establish their live behavior.

1. **Files inspected**

   Path abbreviations used below:

   - `B` = `analysis/test-prep/todo-tests-20261103/`
   - `H70/H80` = `B/builds/T70-bundle/source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/`, and the corresponding T80 path.
   - `P70` = T70’s corresponding `usb-helper/source/com/google/android/projection/protocol/`.
   - `A80` = `B/builds/T80-bundle/source/analysis/parallel-aa-receiver/src/com/google/android/projection/protocol/AudioSink.java`.
   - `STOCK` = `decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/`.
   - `SMALI` = `decompiled/AndroidAuto-current-smali-full/com/google/android/projection/protocol/`.
   - `NAVLIB` = the supplied scratchpad `navlib/smali/com/honda/auto/navigation/` directory.
   - `L55/L10/L44` = the supplied `helper_20261106T155525_*`, `161008_*`, and `161644_*` runs’ `longdrive-evidence/rdx_*/capture.log`, respectively.

   Read PROJECT-RULES.md, AGENTS.md, the T70 prompt and both Claude reviews; compared T60→T70 and T70→T80 overlays with baseline fallback. Inspected affected Java/XML, BundleTests, test.json, saved test/build records, VISIT.md, T70 RESULT.md, the three capture logs, supplied stock references, supporting Framework AudioTrack/AudioAttributes, navigation-library smali, JNI strings, and preservation manifests.

2. **Files changed:** none.

3. **Commands run**

   Read-only `Get-Content`, `rg`, `Get-Command`, `Test-Path`, and in-memory Node scripts for line-numbered reads, source comparisons, manifest/SHA-256 verification, and ABI checks. Python launcher attempts failed with access errors; Node completed the comparisons. Some initial path/glob queries failed and were corrected. No Git, network, build, device, ADB, or credential-material operations.

4. **Tests run and results**

   - **PASS:** 40 static JNI descriptor/field/export checks; six T70/T80 facade byte comparisons.
   - **PASS:** candidate, saved-baseline, and working-baseline checks for all T60 **24/24**, T70 **33/33**, and T80 **35/35** manifest entries.
   - Existing host suites were **not rerun**: saved outputs report T70 **111 bundle checks**, T80 **123 bundle checks**, plus their feature suites (`B/builds/{T70,T80}-bundle/host-test-output.txt:1–9`).
   - Static comparison found **22 changed Java/XML files** for T60→T70 and **13** for T70→T80.

5. **Findings**

   T70 prompt items:

   | Item | Status | Finding |
   |---|---|---|
   | 1. JNI ABI/services | **OK** | Checked native signatures, callbacks, handles, credential-object fields and exports match. Service 14’s phone behavior remains UNKNOWN. |
   | 2. Switches off/removals | **OK** | Optional registrations and strip handling are gated; intended metadata/default/removal differences remain. A dead `showPermissionOverlay()` definition remains, without a call. |
   | 3. Strip tap/release safety | **OK** | Checked grabs immediately move 36 pixels; zero-direction re-grabs are guarded; release paths cover lift/cancel, leaving, minimize and teardown. |
   | 4. T72 threading/art/state | **SHOULD-FIX** | Session mutation is marshalled to main, but the 2 MB compressed-art cap does not bound decoded dimensions or queued bitmap memory. |
   | 5. T73 checkbox/persistence | **SHOULD-FIX** | Hackura-label gating fixes the original Honda-default defect. Current operator notes omit the lasting-default/undo warning. |
   | 6. Persistent/auto-accept | **OK** | Disabled mode returns early; latch resets on start failure; component-list edits preserve other entries. The global accessibility-enable write can enable other listed services. |
   | 7. Launch/refusal behavior | **OK** | Self-recovery is disabled. The icon can remain refused after an unclean end, but normal replug handoff bypasses that refusal. |
   | 8. Migration/settings/tests | **SHOULD-FIX** | Migration logic is one-time and intentionally resets defaults; T80’s checklist and test.json disagree about GRANT and power-off cleanup order. |
   | 9. T74 reflection/Binder | **SHOULD-FIX** | Checked signatures and reply formats match; teardown unregisters by app name. `focused` crosses threads without synchronization. |

   T80-specific items:

   | Item | Status | Finding |
   |---|---|---|
   | 2. Home/side panel | **OK** | Exact Home reason, accessibility suppression and receiver lifecycle are sound. Side-panel fallback works only while the overlay receives keys. |
   | 3. Dongle/policy | **OK** | New non-OnePlus switching requires an explicitly added serial in cooperative mode. Main-phone and AOAP handoff gates remain. |
   | 4. Media lifetime/selection | **SHOULD-FIX** | Lifetime fix is coherent; unknown phone state nevertheless advertises PLAYING before actual phone playback is established. |
   | 5. Play/pause forwarding | **OK** | Balanced 100 ms key pairs, supported-key registration and running checks are present. No direct self-callback loop found. |
   | 6. Strip v2 | **SHOULD-FIX** | Dwell bookkeeping can count time across separate contacts and depends on another position event. Tests omit these cases. |
   | 7. Navigation stream | **SHOULD-FIX** | Firmware Java supports stream 10; there is no automatic MUSIC fallback if initialization fails. |
   | 8. Defaults/safety notes | **SHOULD-FIX** | Default-ON T73 is implemented deliberately, but its persistent effect needs explicit current documentation, including for the dongle. |

6. **Primary evidence for each finding**

   **T70-1:** `P70:MediaPlaybackStatus.java:19–44`, `BluetoothEndpoint.java:15–42`, `WifiProjectionEndpoint.java:10–33`, `CarWifi.java:10–15`, `NavigationStatus.java:24–55`; matching declarations in `SMALI:MediaPlaybackStatus.smali:27,46–57,107,141`, `BluetoothEndpoint.smali:29,58–78,137`, `WifiProjectionEndpoint.smali:15,53,61,113`, `CarWifi$CarWifiCredentials.smali:24–28`, `NavigationStatus.smali:45,160–166,237–285`. JNI strings: `analysis/libautoreceiver_jni.so.strings.txt:102–112,331–334,476–477,13445–13452,13578–13605`. IDs 8/9/10 match `STOCK:integration/AbstractGalIntegration.java:35–42`; navigation configuration matches `integration/GalIntegration.java:62`. Children are destroyed after worker-stop checks and before receiver destruction (`H80:AaSessionService.java:835–869`). Native crash freedom is **UNKNOWN**, not proved by these checks.

   **T70-2/3:** Optional gates: `H70:AaSessionService.java:425–431`, `AaOverlayService.java:224–235`, `PermissionClickService.java:147–149`. Retired recovery assignment: `UsbHelperService.java:539`; unused hint definition: `:370`. Strip direction guard/grab/release: `ScrollStrip.java:50–76`; overlay UP/CANCEL: `AaOverlayService.java:480–483`; minimize/teardown release: `:893`. T80 retains those protections (`H80:ScrollStrip.java:65–103`, `AaOverlayService.java:504–505,789,924,962`).

   **T70-4:** `H80:AaMediaSourceService.java:53–85` posts state/metadata changes to main and drops inactive callbacks. Decode catches runtime/OOM failures but uses no dimension/sample-size bound (`:69–70`); the bitmap is placed under two metadata keys (`:83`). Wire-state mapping is at `:155–158`; registration is switch-gated (`H80:AaSessionService.java:427–429`).

   **T70-5 / T80-8:** SystemUI+USB validation and Hackura-label guard precede checkbox traversal (`H80:PermissionClickService.java:130–189`). Stock uses the requesting application label and saves its package when checked (`decompiled/SystemUI/sources/com/android/systemui/usb/UsbPermissionActivity.java:51,94–96`). Schema 80 enables REMEMBER_PHONE through OPTIONS (`H80:AppSettings.java:27,36,47,53–57`). VISIT lists it ON (`B/VISIT.md:5,27–34`) but supplies no default-clearing procedure; post-Collect hooks revoke permission/check accessibility, without clearing USB defaults (`B/builds/T80-bundle/test.json:70–74`). Turning the switch off cannot undo an already-saved SystemUI default through this code.

   **T70-6/7:** `H70:PersistentBootService.java:23–28,35,44–54`; component preservation and secure-setting writes: `PersistentMode.java:36–39,68–85`; Settings button: `SettingsActivity.java:87–94`. Refusal conditions: `UsbHelperService.java:623–632`; direct replug handoff: `:537–550`, polling permission handoff `:343–347`.

   **T70-8:** Migration is guarded by schema and writes the schema with defaults (`H80:AppSettings.java:45–57`); DPI and volume-display keys are retained, while volume size resets. Tests assert default constants/options (`B/builds/T80-bundle/BundleTests.java:16–26`), without exercising actual persisted migration. `test.json:62–68` says GRANT; `B/VISIT.md:21` says skip it. `test.json:63` requires After-PowerOff before Collect; `VISIT.md:67–70` puts it after failed cleanup.

   **T70-9:** Reflection calls: `H70:HondaNavBridge.java:106–115,129–152,160–197,202–225`. Matching library methods include `NAVLIB:managers/NavigationManager.smali:436,560`, `NavigationAppManager.smali:461,1028,1176,1308,1436,1654,1718`. Binder codes/replies/caller checks: `H70:HondaNavProviderService.java:23–55`, `HondaNavBridge.java:230–232`; matching proxy reads: `NAVLIB:providers/INavigationInfoProviderService$Stub$Proxy.smali:94–104,817–836,1450–1462,1813–1832`. Saved runtime evidence: `L55:7493,7498,8508–8509` records registration, provider bind, focus abandon and unregister result 0. However `focused` is written by the listener invocation handler (`HondaNavBridge.java:132`) and read/written on the worker (`:128–143,203–210`) as a plain boolean (`:80`).

   **T80-2:** Receiver accepts only `"homekey"` while `keysObserved` is false (`H80:AaOverlayService.java:108–114`); registration follows successful window attachment (`:550–560`), unregistration occurs on removal (`:965–968`). Stock sends `"homekey"` from `decompiled/Policy/sources/com/android/internal/policy/impl/PhoneWindowManager.java:2949–2977`. Own minimize changes window flags/alpha and sends no such broadcast (`H80:AaOverlayService.java:786–797`). Home is idempotent while minimized (`H80:HomeToggle.java:18–22`). Accessibility sets/clears the flag at connection/destruction (`PermissionClickService.java:328,344`). Window side-panel handling is at `AaOverlayService.java:334–339`; minimized windows are non-focusable (`:792`), so long hold there remains unavailable without accessibility. `L10:162–165` confirms code 172 previously reached the visible overlay.

   **T80-3:** `H80:UsbHelperService.java:683–686` accepts OnePlus or cooperative extra serials; all switching paths retain raw-policy checks (`:232,296,504,710–718`). **Yes**, configured main phones—and legacy OnePlus devices when Honda-stop policy permits—can switch without Add-Phone; that predates this delta. Arbitrary new-vendor devices cannot use the added path without an extra serial. AOAP polling/callbacks retain serial checks and reach `startAaSession` (`:215–231,287–300,476–503,537–549`). AOAP VID/PIDs are accepted by `analysis/parallel-aa-receiver/src/com/rdx/fullscreen/projection/UsbBulkTransport.java:19–24`. Actual dongle serial continuity is **UNKNOWN**; saved raw attaches are at `L10:8144–8191`.

   **T80-4:** Start after `running=true`: `H80:AaSessionService.java:450–459`; shutdown marks false and notifies (`:830–831`). Notification stops/deactivates the media service (`AaMediaSourceService.java:38–48`); boot binds remain inactive, and destruction releases the session (`:113,123–126,193–195`). No normal-path active-session leak found. Unknown `phoneState=-1` becomes PLAYING (`:34,155–158`), so silent AA startup can become the top displayed source. SystemUI follows controller 0 (`decompiled/SystemUI/sources/com/android/systemui/statusbar/auto/HondaStatusBar.java:3244–3266`). `MediaSourceSelector.java:262–272,390–410` checks an existing selection command; it alone does not prove unsolicited auto-selection. Actual FM/BT interruption is **UNKNOWN**.

   **T80-5:** Callbacks forward 126/127 (`H80:AaMediaSourceService.java:99–101`); forwarding checks live state (`:166–170`). `AaSessionService.java:123–128` schedules DOWN/UP 100 ms apart, and `:254–257` rechecks running/key support. Supported keys: `InputEvents.java:20`; native registration: the protocol `InputSource.java:65`. Stock advertises the same play/pause codes (`STOCK:presentation/HMIPresenter.java:743`). Focus changes notify the phone’s focus protocol rather than invoking these MediaSession callbacks (`H80:AaSessionService.java:395–403`). Shutdown cancels queued releases only as the connection ends (`:825,830–833`).

   **T80-6:** Dwell is updated only on `track()` calls (`H80:ScrollStrip.java:48–53`); `leave()` clears drag/strip state but retains dwell fields (`:100–103`). Thus two brief visits to the same position separated by a long lift can qualify as continuous rest. A stationary interval without another event is not independently recorded. Overlay tracking also reads the previous cursor before updating it (`AaOverlayService.java:244,624–626`). Tests explicitly provide a second event after 350 ms (`B/builds/T80-bundle/BundleTests.java:88–92`), with no lift/no-event coverage. Mid-screen grabs and preserved anchor are implemented at `ScrollStrip.java:86–96`. Original header grabs are evidenced by `L55:5181–5187`.

   **T80-7:** Firmware defines stream 10 (`decompiled/Framework/sources/android/media/AudioManager.java:198`); AudioTrack’s legacy constructor accepts attributes (`AudioTrack.java:139–190`), with stream 10 mapped to speech/navigation usage (`AudioAttributes.java:293–306,465–466`). No stream-specific signature-permission gate appears in those Java paths; native-policy acceptance remains **UNKNOWN**. AppOps can mute playback (`AudioTrack.java:510–524`). T85 still requests MUSIC focus (`A80:48,194`). Initialization failure exits the guidance worker and releases focus—there is **no automatic fallback** (`A80:203–222`); disabling T85 and reconnecting restores the default MUSIC stream (`H80:AaSessionService.java:412–414`).

7. **Assumptions**

   Overlays use `baseline-source` for omitted paths; the requested car-test verdict concerns the parked checklist, not milestone authorization. Existing test outputs are historical records, not tests executed by this review.

8. **Unresolved uncertainties**

   Live T80 Home delivery, dongle serial continuity/switch completion, media ordering and FM/BT interaction, third-party stream-10 routing/volume behavior, and hardware stationary-hover event cadence are **UNKNOWN**. Native ABI checks do not prove native crash freedom.

9. **Exact diff summary:** none; no files changed.

10. **Preservation checks performed**

   All frozen hashes matched PROJECT-RULES.md: M5 `A22E9649…EE8F40`; M6 `D4DAC2DD…FB28761F`; both receiver DEX copies `2FDBC63F…7FE7C235`; TLS qualifier `86350131…3999FC1F`.

   T70 APK SHA-256 matched its current build record: `62A805794A1C3D6EE39F2F632DE02FD29DFF12ABC60036D47490D2624C25A4DA`.
   T80 APK SHA-256 matched its build record: `3A0E7E290811B075464A1756BD145087A01177410FFAA777CD0A176F7153AB62`.
   All manifest-listed working paths matched baseline. No frozen artifacts, readiness guards, milestone state, or private material were modified.