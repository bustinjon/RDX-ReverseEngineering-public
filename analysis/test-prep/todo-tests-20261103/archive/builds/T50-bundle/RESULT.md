
# Car visit 2026-11-05 (build FF521CEA…), operator report
- Everything off: behaves like today. Long side-panel hold opens AA Settings (with and without AA running).
- Switches apply only after unplug/replug (operator first expected a live change; now clear).
- T34 new volume look: PASS, "this is perfect". Promote.
- T38 density: Smaller OK (some may prefer it), Standard best, Larger too big. Keep Standard as default; keep Smaller as an option.
- T33 absolute touchpad: FAIL/needs work. Taps misaligned (pad-to-screen mapping likely not matched to the fullscreen 1920x720 picture). Cursor ring much too dark. Operator wants this ring kept as an option, plus a preferred mode where the cursor moves around the screen with the finger.
- Operator decision: on-car Settings switches are the standard way to test from now on. Keep the Settings menu in the product (density, volume display, etc.; not every test switch).
- Pending this visit: T39 Honda audio source, T25 car GPS, T35 tile return.
- T35 tile return: FAIL (the Android Auto tile did not bring our AA back). Check the log for STOCK_AA_WINDOW and RESTORE_REQUEST.
- T39 Honda audio source: "AA Fullscreen" was not seen. The operator was unsure where Honda's source list is.
- T25 car GPS: tested at 16:43; can't tell by eye. The log decides.
- Discovery: swiping left on Honda Home shows an installed-apps list with "RDX Parallel AA - TEST" (receiver) and "RDX USB" (helper app label). It looks like an app can be added to the Home screen from there. That could be the permanent visible entry, renamed "Hackura" (operator idea).
- Operator request: volume panel size option, Small / Medium / Large. Small = the current T34 panel (440x68).

## Log analysis (Claude, capture.log + preparation-capture.log; Collect: cleanup verified, baseline restored)
- Switch snapshots worked. Each replug logged FEATURE_SWITCHES with the switches as set, and MEDIA_SOURCE_COMPONENT changed only at START. SIDE_PANEL_LONG opened Settings about 15 times with no failure.
- T37 frame rate: VIDEO_FPS 57–59.5 while AA is visible. It is about 12 while AA is minimized or Settings is in front (the phone or decoder sends fewer frames; medium confidence on the cause). The video is already ~60 fps, not 30.
- T25 car GPS: PASS on forwarding. Sessions at 16:37:42 (35 fixes) and 16:43:01 (53 fixes): GPS_FIX acc ~5 m, delivered=true, failures=0, stopped cleanly at unplug. Medium confidence that the phone used them; not visible in our log.
- T35 tile return: FAIL. During the tileReturn=true session (16:38:24–16:39:14), no stock-AA ProjectionActivity started at all, so our trigger never fired. The Honda AA tile does not open stock AA in this setup (Honda AA set to Never).
- App list: Honda launches explicit components. "RDX USB" -> usbhelper/.HelperActivity (16:42:06, 16:44:49, 16:45:10, 16:47:53; flags 0x14004000/0x14000000), even though HelperActivity has no LAUNCHER filter in this build. "RDX Parallel AA - TEST" -> projection/.ReceiverActivity (16:40:39, 16:45:29). The running session kept going (GAL pings OK). RestoreActivity ("AA Fullscreen") is never used by Honda's list.
- T39 Honda audio source: PARTIAL. With the switch on (16:39:21), Honda's raamservice and SystemUI bound and got a root. HondaAudioSourcesMgr (SystemUI) briefly selected our component (16:39:32.862 "setSelectedAudioSourceComponent ... AaMediaSourceService ... FOUND"). It then logged "Component name not indexed: ...AaMediaSourceService" and went back to "NO audio source selected" when our service was destroyed (16:39:33.3). The index is system_server MSS_MediaSourcesDatabase (/data/system/mediasources.db, 8 elements), updated on package add (16:23:59, our install). At install time our component was disabled, so it was never indexed. Medium confidence: it must be enabled when the package is installed or the device boots to be listed.
- T33 absolute touch (16:36:12 session): operator reports misalignment and a too-dark ring. Mapping to be checked offline.
