# To-do investigation and test plan — 2026-11-02 (Claude)

Scope: steering wheel + volume, voice/mic/calls, reconnect/startup, camera/Honda overlays. Static evidence only; no device, build or Git action. Baseline = D1A29 working build; Maps-only 21037 test still pending and comes first. Every test below is one change on top of the build that was last proven.

Labels: CONFIRMED (read in code/logs), SUPPORTED, UNKNOWN.

## 1. Steering-wheel / B-zone track buttons

Findings
- CONFIRMED: raw keys 138 (prev) / 139 (next), scan 66/67, source 257, reached our overlay during the 10-31 drive (`analysis/test-prep/media-input-fixes-20261031/observed-media-volume-keys.txt`, lines 2342–2347). D1A29 does not forward them.
- CONFIRMED: PhoneWindowManager treats {172,138,139} as B-zone keys. It broadcasts `com.honda.auto.HONDA_B_ZONE_KEY` (receiver permission MEDIA_CONTENT_CONTROL) and does **not** consume the key, so the focused window also gets it (`decompiled/Policy/.../PhoneWindowManager.java:2693–2701`). Exception: if focused window type is 2040 it returns -1.
- CONFIRMED: SystemUI routes the broadcast to SeekKeyHandler → selected audio source's MediaController → skipToNext/Previous (`SeekKeyHandler.java:217–266`, `HondaStatusBar.java:2518–2536`). Stock AA is such a source (GalMediaSessionService → GalMediaSessionCallback.onSkipToNext → sendKeyPress(87), 100 ms down/up, `GalMediaSessionCallback.java:139–206`).
- CONFIRMED: MEDIA_CONTENT_CONTROL, AMPLIFIER_SERVICE, VRCOMM_SERVICE, AUTOMOTIVE_VCS_SERVICE are `signature|system` (`adb/RDX-Audit/packages/android-package.txt:915,975,2357,3327`). We cannot be a Honda media source or receive the B-zone broadcast. Raw-key capture in our overlay (A2F478's MediaButtons) is the only available route.
- Risk SUPPORTED: double action. If the car's selected source is STREAMING (e.g. Bluetooth audio), SystemUI also sends skip via that MediaController (likely AVRCP to the same phone) → one press could skip twice.

Test S1 (one change): D1A29 + A2F478's MediaButtons/87-88 declaration only (no HUD, no profile true/true, no Down-branch change). Acceptance: one press = one skip, both directions, with phone Bluetooth Media audio OFF, then ON. Log raw key + emitted 87/88. Watch for double skip with BT ON.

## 2. Volume indicator

Findings
- CONFIRMED: volume keys 24/25 reach our overlay and are passed through; user says volume changes work, OEM indicator hidden.
- CONFIRMED: OEM volume dialog is type 2014 → layer 16; our AA overlay type 2010 → layer 24 (`PhoneWindowManager.java:1644–1736`).
- CONFIRMED: SystemUI reads `com.honda.auto.amplifiermanager.get_main_volume`, byte extra `bundle_key` (`VolumeManager.java:259–271`). Sender is not in the decompiled set; whether it was sent with a required receiver permission (AMPLIFIER_SERVICE is signature|system) is UNKNOWN. If protected, A2F478's VolumeFeedback HUD never receives anything.
- Alternative: overlay type 2003 (SYSTEM_ALERT) = layer 10, below the volume dialog (16) but also below the status bar (2000 → 15). Likely status bar draws over AA's top. Memory claims 2003 drew fullscreen on 10-27, but that photo test did not involve the live status bar stacking question → UNKNOWN.

Test V0 (no code change, ~1 min, parked, ADB): with D1A29 running, `logcat -s VolumeManager` while turning volume; check `dumpsys activity broadcasts | grep get_main_volume` for requiredPermission. Decides between V1a/V1b.
- V1a (if broadcast is unprotected): D1A29 + VolumeFeedback HUD only.
- V1b (if protected): no receiver HUD possible from amplifier; consider showing nothing, or test type 2003 window with photo of status-bar area. Separate test, user decision.

## 3. Voice / mic / calls

Findings
- CONFIRMED: stock mic capture is plain public API: `new AudioRecord(1 /*MIC*/, 16000, CHANNEL_IN_MONO(16), PCM_16BIT(2), max(minBuf,4096))`, retried up to 15× at 100 ms, opened/paused on `microphoneRequestCallback(open,…)` which returns an incrementing session id (`MicrophoneRecorder.java:82–123, 294–314`). Send path uses a Semaphore(maxUnacked) released by `ackCallback`.
- CONFIRMED: our helper manifest lacks `android.permission.RECORD_AUDIO` (normal grant at install on API 22, dangerous-level but no runtime prompt pre-M).
- CONFIRMED: talk/PTT button goes to Honda's VR service, then a registered `VrProvider` (stock GalVrProviderService, actions `com.honda.auto.voicerecognition.VrProvider`). Stock holds VRCOMM_SERVICE (signature|system). We cannot replicate this → UNKNOWN whether talk button produces any raw key to our window (likely not).
- Voice therefore must start from the phone side: AA on-screen mic button via touchpad select, or "Hey Google". Both need only mic capture.
- Calls: phone-call audio normally rides Bluetooth HFP (Honda BT stack), independent of our receiver → SUPPORTED that calls already work over BT. UNKNOWN: Honda's incoming-call UI layer vs our layer-24 overlay (could be hidden like volume) and touchpad focus during a call.

Tests
- M0 (no code): during next session, press the steering talk button once; existing INPUT_RAW_KEY logging shows whether any key reaches us.
- M1 (one change): add RECORD_AUDIO + port stock AudioSourceThread semantics into AudioSource (open/pause, 16k mono, unacked semaphore, session id). Acceptance: tap AA mic icon, speak a query, AA answers (response audio over existing PCM path).
- C1 (no code, parked): receive and place a call with AA running; photo of screen; note whether Honda call UI is visible and whether audio works.

## 4. Reconnect / startup without laptop

Findings
- CONFIRMED (Codex F04 still true): `UsbHelperService` detach receiver only logs (`:77–85`); poll loop exits forever at GRANTED/FAILED (`:210`); AUTO_GRANTED ignores while GRANTED (`:168`); AaSessionService never notifies the helper on stop. Unplug/replug in one helper process → no new session.
- CONFIRMED: BootBlockerReceiver only starts the blocker overlay, not UsbHelperService. Manifest UsbAttachActivity listens to USB_DEVICE_ATTACHED (possible cold entry).
- UNKNOWN: whether lock task / Honda launcher allows UsbAttachActivity to launch; whether A11Y clicker can stay enabled across reboot (Collect restores it off by design).

Tests
- R1 (one change): on session stop or DETACH of the active device, helper returns to WAITING and restarts polling; single active-session owner, no duplicate AOAP switch. Acceptance: session → unplug 10 s → replug → second session without laptop action; repeat 3×.
- R2 (no code, after R1): ignition off/on with helper left installed and A11Y left enabled; plug phone; log whether UsbAttachActivity fires and session starts. Decides whether boot-start of the helper (R3) is needed.

## 5. Reverse camera / Honda pop-ups — SAFETY, do early

Findings
- CONFIRMED: rear-camera mode makes PopUpManager show DummyHondaRearCameraDialog type 2041 → layer 38, above our 24 (`DummyHondaRearCameraDialog.java:22`, layer table). HOME is ignored while camera active (`PhoneWindowManager.java:2465`). So the camera window should sit above our overlay. Whether the camera image is a hardware plane or drawn in that window is UNKNOWN.
- CONFIRMED: no saved run contains a reverse/camera event while our overlay ran (only VcsProxy startup state lines).
- UNKNOWN: our overlay/video after camera exit; touch focus return.

Test K1 (no code, parked, foot on brake): AA running → shift to R → confirm camera image and guidelines fully visible → back to P → AA returns and touchpad works. Photo each stage. If camera is blocked even partly, stop using AA while driving until fixed.

## Proposed order

1. Maps route test (already packaged).
2. K1 reverse camera + C1 call + M0 talk-button + V0 volume broadcast — all no-code observations, can share one parked session on D1A29/21037.
3. R1 reconnect fix (small, big usability win).
4. S1 track buttons.
5. M1 mic.
6. V1a/V1b per V0 result.
7. R2/R3 laptop-free start.

Spotify row stays parked pending the stock-AA comparison Codex proposed.

## Reconciliation after Codex attack (CODEX-ATTACK.md) — supersedes conflicting text above

Claude spot-verified the starred items in primary source.

- *Status bar is type 2014 (layer 16), 581×720 on the right (`HondaStatusBarWindowManager.java:26`, `dumpsys-window.txt:313–317`). My "2000/top strip" was wrong. Type 2003 would put Honda's bar over the right third of AA → V1b (window-type change) dropped as a default option.
- *Mic is NOT "only AudioRecord". Stock first calls `IMicAnalogInputManager.setAudioProcessingActive(false)` + `setMicMode(SERVER_VOICE_REC)` (`GalAudioManager.java:54–60`), gated by `ANALOGINPUT_SERVICE` (`AnalogInputManager.java:334`, signature|system). We can't do that. Plain MIC capture may still work but with car echo/noise processing on, or may not work → M1 becomes an experiment with UNKNOWN outcome. RECORD_AUDIO is dangerous-level, granted at install on API 22. Guidance sink also lacks context (`AaSessionService.java:324`) — check Assistant response audio.
- Raw 138/139 capture doesn't prove which physical control (wheel vs console). Separate steering-wheel channel exists (`com.honda.auto.autovcs.buttons_pressed`). S1 must press each physical control separately and note which.
- S1 must test held presses: stock starts seek after 500 ms; saved adapter skips on any release → possible seek+skip. Adapter should ignore releases after a hold threshold, or test first and decide.
- "We can't be a Honda media source" overstated: discovery queries ordinary MediaBrowserService declarations; only selection is privileged. Not proof it works; parked as a later option.
- V0 must capture the full `dumpsys activity broadcasts` record (requiredPermission is on separate lines); missing record = still UNKNOWN.
- Incoming-call card is in Honda's 2014 status-bar area → hidden under our overlay. C1 must check ringtone, both audio directions, how to answer/hang up, and audio after the call.
- Reconnect R1 needs a proper design: session generation + device identity, one shutdown per detach, wait for cleanup before new session, ignore stale callbacks, distinguish AOAP re-enumeration from real detach, explicit STOP stays stopped, fail closed if native resources retained. Plus races listed in CODEX-ATTACK §4.
- R2 (ignition cycle) can't decide cold-start alone; need separate cold-boot observation.
- Camera: dummy window above us does not prove the image is visible; camera is composited natively (UNKNOWN plane). Current capture filters may drop camera tags, so "no camera event in logs" only means not captured. K1 needs: parking brake + foot on brake, observer for photos, stock-camera baseline first, immediate back-to-P, a known way to kill the overlay that does not rely on HOME (HOME ignored in reverse).

- **User-confirmed (2026-11-02): unplugging the phone definitely ends our session.** This is the K1 overlay-kill/recovery method; it does not depend on HOME.
- **User-confirmed (2026-11-02): reverse and a phone call have not yet been tried with our AA on screen.** K1/C1 stay first; folded into the Maps-test session (stock-camera baseline before Start, then reverse, calls, talk button, then routes).

### Revised order
1. **K1 reverse camera + C1 call check first** (parked, no new code, D1A29 or 21037) — before more driving with our app.
2. Maps route test (packaged).
3. M0 talk-button press + V0 full broadcast record (no code, same session as 1 if convenient).
4. R1 reconnect (after design review).
5. S1 track buttons (per-control, short + held presses, BT on/off).
6. M1 mic experiment.
7. Volume HUD per V0.
8. Laptop-free start (R2/R3, cold boot separately).
