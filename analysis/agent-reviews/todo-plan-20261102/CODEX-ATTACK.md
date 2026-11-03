The plan needs correction before use. The strongest issues are the omitted Honda mic configuration, the incorrect status-bar type, the incomplete reconnect reset design, and placing the camera check after a route test.

## 1. Files inspected

Read first: `PROJECT-RULES.md`, `AGENTS.md`.

Reviewed `analysis/agent-reviews/todo-plan-20261102/PLAN.md`; current helper/protocol source and manifest; Maps candidate metadata; saved media-adapter source; relevant audit dumps, key layouts and captures.

Primary source included:

- Policy: `PhoneWindowManager.java`, `GlobalKeyManager.java`, `PopUpManager.java`, `DummyHondaRearCameraDialog.java`.
- SystemUI: `SeekKeyHandler.java`, `HondaAudioSourcesManager.java`, `HondaBZoneButtonHandler.java`, `HondaStatusBar.java`, `HondaStatusBarWindowManager.java`, `VolumeManager.java`.
- Stock AA: `MicrophoneRecorder.java`, `GalAudioManager.java`, `AudioFocusManager.java`, `AudioPlayer.java`, `ProjectionActivity.java`, `GalVrProviderService.java`, `GalMediaSessionCallback.java`, `GalMediaSessionService.java`, corresponding selected smali and manifest.
- Framework/services: camera-state interfaces, window/input handling, package-permission grants, broadcast dumping/delivery, media-source discovery and registration.
- Audit: `packages/android-package.txt`, `logs/dumpsys-window.txt`, relevant saved key layouts and binaries.

## 2. Files changed

None.

## 3. Commands run

Only local, read-only commands:

- `Get-Content`, numbered source-range reads, `Get-ChildItem`, `Get-Command`.
- `rg --files`, `rg -n`, and binary literal searches using `rg -l -a`.
- `Get-FileHash -Algorithm SHA256`.
- `rz-bin.exe -zz` for targeted native-string inspection.
- Candidate source-hash comparison.

Incomplete commands: Python and `py` archive scans could not start because the installed Python executables were inaccessible. Several guessed paths/globs did not exist; these failures provide no negative evidence. A guessed hardware-composer binary was absent.

No ADB, device, build, Git, or network-publication commands ran.

## 4. Tests run and results

- **PASS:** all **27** current source hashes match the Maps candidate.
- **PASS:** Maps APK SHA-256 is `21037DC393FCD162499589254D745DD0904A326BD7E5A33D69CF3FC69BFA4084`.
- **PASS:** four frozen-artifact hashes match `PROJECT-RULES.md`; details below.
- No behavioral tests or live checks ran.

## 5. Findings

For compact citations below, these prefixes identify exact source directories:

| Prefix | Directory |
|---|---|
| `P/` | `decompiled/Policy/sources/com/android/internal/policy/impl/` |
| `S/` | `decompiled/SystemUI/sources/com/android/systemui/statusbar/auto/` |
| `A/` | `decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/` |
| `H/` | `analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/` |
| `R/` | `analysis/parallel-aa-receiver/src/com/google/android/projection/protocol/` |

### Plan section 1 — Steering-wheel / B-zone

**AGREE — Ordinary 138/139 events can reach the focused overlay after the broadcast.** There is no unconditional later consumption of these two codes. The method normally reaches `return 0L`.

**CORRECTION — “Does not consume” needs qualification.** After broadcasting at `P/PhoneWindowManager.java:2700`, the method still checks shortcuts and global keys. At line 2769, a handled global key or META modifier causes `return -1L`; ordinary fall-through returns zero at line 2780. Type 2040 is an earlier rejection at line 2694. The saved target dump reports `mKeyMapping.size=0` at `adb/RDX-Audit/logs/dumpsys-window.txt:95`, supporting ordinary delivery for that capture, not every possible configuration.

**CORRECTION — The raw capture does not identify the physical control.** The cited extract contains the events at physical lines **6–9**; “2342–2347” are embedded original-log line numbers. It proves code/scan/source/device delivery, but contains no synchronized statement that distinguishes steering-wheel from console presses.

A separate steering-wheel channel exists:

- `decompiled/HondaDiagnostics/sources/com/honda/auto/diagnostics/dealer/HardKeyActivity.java:150` receives `com.honda.auto.autovcs.buttons_pressed`.
- Its payload is `SteeringWheelCommands[]` at line 152.
- `decompiled/HondaManager/sources/com/honda/auto/autoinfomanager/autovcs/SteeringWheelCommands.java:8` defines volume, LEFT/RIGHT, rewind/forward, pickup and VR commands.

Whether those commands also generate 138/139 on this target is **UNKNOWN**. S1 should distinguish each physical control.

**AGREE, qualified — Double-skip is a credible conditional risk.** SystemUI processes short presses on release: `S/SeekKeyHandler.java:171` and `:200`. STREAMING selects transport controls at `:217`; skip calls occur at `:255` and `:262`. They require a controller, playback state and supported action, checked at `:408`.

However, `HondaAudioSourcesManager` does not itself prove an AVRCP destination. HondaStatusBar selects the first active controller at `S/HondaStatusBar.java:3244`. Therefore Bluetooth Media ON alone does not establish the duplicate path. Record the selected source/controller and actual phone track transition.

**DISAGREE — “We cannot be a Honda media source” and “only available route” are overstatements.** Protected source-selection calls are blocked, but discovery is broader:

- `decompiled/HondaManager/sources/com/honda/auto/msm/MediaSourceManager.java:96` queries ordinary `MediaBrowserService` declarations.
- `decompiled/Services/sources/com/honda/auto/mss/BrowserConnectionCallback.java:69` obtains application information and inserts a discovered source at line 84, without the claimed signature check in that path.
- Privileged selection is separately checked in `decompiled/Services/sources/com/honda/auto/mss/MediaSourceService.java:185`.

This is a counterexample to the permission inference, not proof that registering our helper would work.

**CORRECTION — S1 needs held/canceled/focus-interrupted presses.** The saved adapter emits a skip on any matching uncanceled release, with no duration check: `analysis/test-prep/diagnostic-rollback-20261031/saved-media-source/InputEvents.java:40`. Stock starts fast-forward/rewind after 500 ms at `S/SeekKeyHandler.java:164` and `:193`. A held press can therefore combine stock seeking with an extra helper skip.

### Plan section 2 — Volume

**AGREE — The cited layer ordering is correct:** 2003→10, 2010→24, 2014→16, in `P/PhoneWindowManager.java:1655`, `:1672`, `:1681`.

**CORRECTION — Honda’s actual status bar is type 2014, not 2000.**

- Construction: `S/HondaStatusBarWindowManager.java:26`.
- Captured target window: `adb/RDX-Audit/logs/dumpsys-window.txt:313`.
- Captured shown bounds: `[1339,0][1920,720]` at line 317.

Thus type 2003 risks covering AA’s **rightmost 581×720 region with Honda’s bar**, rather than merely drawing over AA’s top.

The separate OEM volume dialog explicitly uses 2014 at `S/HondaStatusBar.java:3126`. Its layer conclusion is confirmed.

**AGREE, qualified — Amplifier sender and receiver-permission requirement remain UNKNOWN.** The source/smali searches found consumers and definitions, not an identified send site. SystemUI registers without a sender-permission argument at `S/VolumeManager.java:462`; this does **not** establish whether the sender restricts recipients. `AMPLIFIER_SERVICE` protecting manager calls does not establish broadcast protection.

No matching literal was found in the native-library directories searched. That does not exclude dynamically constructed actions, other binaries, or unexamined compressed DEX.

**DISAGREE — V0 as written cannot reliably decide V1a/V1b.**

- `BroadcastRecord.dump` prints `requiredPermission` on separate lines: `decompiled/Services/sources/com/android/server/am/BroadcastRecord.java:86`.
- Full historical records require the detailed dump path: `decompiled/Services/sources/com/android/server/am/BroadcastQueue.java:1228`.
- Grepping only `get_main_volume` discards the surrounding permission information.

A missing record is inconclusive because history is bounded. VolumeManager logging proves its own receipt, not eligibility of an unprivileged helper. V0 needs the complete matching record and context; an unavailable record must leave the branch **UNKNOWN**.

### Plan section 3 — Voice / mic / calls

**AGREE — The AudioRecord parameters, retry count, semaphore and incrementing callback return value are correctly cited.** See `A/audio/MicrophoneRecorder.java:97`, `:194`, `:295`, `:311`, `:342`.

**DISAGREE — Stock voice operation is not established as requiring “only mic capture.”** The plan omits:

- Honda input configuration before recording: `A/ui/ProjectionActivity.java:2509`.
- Disabling analog echo/noise processing and setting `SERVER_VOICE_REC`: `A/audio/GalAudioManager.java:54` and `:58`.
- Input restoration through `releaseMic`: `A/audio/GalAudioManager.java:89`.
- Voice-start early recording and cancellation on preparation failure: `A/ui/ProjectionActivity.java:2530`.
- VR audio-focus state transitions: `A/ui/ProjectionActivity.java:2479`; `A/audio/AudioFocusManager.java:463`.
- MASM AudioState handling: `A/ui/ProjectionActivity.java:2625`.
- Mic-open coordination with TTS routing: `A/audio/AudioPlayer.java:198`.

The analog configuration is permission-gated: `decompiled/HondaManager/sources/com/honda/auto/analoginputmanager/AnalogInputManager.java:334`. `ANALOGINPUT_SERVICE` is `signature|system` in `adb/RDX-Audit/packages/android-package.txt:1289`.

Whether public MIC capture works adequately without those steps is **UNKNOWN**. Do not infer that our app must reproduce every stock step, or that it can.

**AGREE — RECORD_AUDIO is absent and API-22 granting is install-time.** The helper manifest requests only overlay, boot and accessibility-related permissions at lines 4–6. RECORD_AUDIO is dangerous at `adb/RDX-Audit/packages/android-package.txt:3211`. The captured PackageManager implementation grants requested normal/dangerous permissions through its installation path at `decompiled/Services/sources/com/android/server/pm/PackageManagerService.java:6187`; replacement resets `permissionsFixed` at line 6157.

Call it an **install-time dangerous permission**, not a normal permission. Actual grant and usable recording after installation still require verification.

**CORRECTION — M1 also encounters an existing voice-integration stub.** `R/GalReceiver.java:102` only logs voice-session notifications. Current initialization supplies context to the media sink at `H/AaSessionService.java:314`, but not the guidance sink at line 324. Both use public STREAM_MUSIC playback in `R/AudioSink.java:171`. Assistant response routing is therefore another item to validate.

**AGREE, qualified — PTT provider routing is supported; raw talk-key delivery remains UNKNOWN.** `A/service/GalVrProviderService.java:105` handles long press and requests VR focus; lines 119 and 128 handle PTT down/up. This does not prove the complete hardware-to-provider path or exclude an additional raw path.

**CORRECTION — Part of the call UI layer is already knowable.** HondaStatusBar shows an incoming-call B-zone card at `S/HondaStatusBar.java:686`, and creates that card in its B-zone container at line 2795. That status-bar surface is type 2014, below our overlay. Visibility of other call windows remains **UNKNOWN**. C1 should verify ringtone, both audio directions, controls, overlay focus and post-call audio recovery.

### Plan section 4 — Reconnect / startup

**AGREE — The principal UsbHelperService citations are accurate.**

- Detach only logs: `H/UsbHelperService.java:77`.
- AUTO_GRANTED ignores an AOAP device while GRANTED: line 168.
- Polling stops at GRANTED/FAILED: line 210.
- Session shutdown stops the overlay and itself without notifying the helper: `H/AaSessionService.java:626`.

**CORRECTION — “No new session” assumes the helper process persists and no alternative state-changing action intervenes.** A recreated helper has a fresh phase. Also, the raw-phone AUTO_GRANTED branch at `H/UsbHelperService.java:177` is not covered by the GRANTED check inside the AOAP branch.

**CORRECTION — Minimal reset design needs lifecycle identity, not just WAITING.**

Recommended design:

1. Serialize helper state changes on its handler; give each connection/session a generation and device identity.
2. On matching active-device detach, request session shutdown once and wait for matching cleanup completion before starting another session.
3. Ignore stale stop/permission callbacks. Recheck current attachment, identity and permission immediately before handoff.
4. On completed recoverable teardown, clear target/stability/retry/AOAP-switch state and schedule exactly one poll.
5. Distinguish expected AOAP re-enumeration from active-session detach. Preserve policy and safety gates.
6. Keep explicit operator STOP suspended; do not turn it into automatic restart.
7. Fail closed if workers or native resources were retained.

Required races follow directly from current paths: permission callbacks at `H/UsbHelperService.java:406`; AOAP re-enumeration at line 181; duplicate START rejection at `H/AaSessionService.java:82`; cleanup retaining resources at line 623; teardown resetting `stopping` at line 635.

Cover detach during REQUESTING, startup failure before `running`, rapid replug during shutdown, duplicate callbacks/polls, stale old-session completion, unrelated-device detach, and STOP versus recovery.

**AGREE — BootBlockerReceiver does not start UsbHelperService.** See `H/BootBlockerReceiver.java:14`. UsbAttachActivity hands off through AUTO_GRANTED at `H/UsbAttachActivity.java:36`.

**CORRECTION — R2 cannot decide R3 from ignition cycling alone.** A retained process is different from cold boot or process death. Activity launch, USB permission/default association and accessibility-service availability are separate observations. One successful ignition cycle does not establish laptop-free cold startup.

### Plan section 5 — Camera / Honda pop-ups

**AGREE — The dummy dialog is type 2041 and normally ordered above 2010.** See `decompiled/Policy/sources/com/honda/auto/policy/popup/DummyHondaRearCameraDialog.java:22` and `P/PhoneWindowManager.java:1730`.

**DISAGREE with any stronger inference — This does not prove camera-image visibility.** The dummy class contains no camera rendering or preview surface. Its creation is conditional on rear-camera availability at `decompiled/Policy/sources/com/honda/auto/policy/popup/PopUpManager.java:755`; mode-dependent show occurs at line 814.

Camera state comes from `nativecameraservice`, connected at `decompiled/Framework/sources/com/honda/auto/camera/CameraStateManager.java:36`. Actual image composition, plane and layer remain **UNKNOWN**.

**CORRECTION — Overlay flags do not overturn the cited window-layer ordering.** `FLAG_LAYOUT_IN_SCREEN` affects layout frames; see `P/PhoneWindowManager.java:3682`. Focusability affects input ownership. Neither establishes the native camera plane’s position. Our actual focusable flags and type are at `H/AaOverlayService.java:300` and `:309`.

**CORRECTION — “No saved run contains…” is too broad.** No synchronized reverse-image test was established in the captures inspected. Several capture paths filter out the relevant camera tags; for example `analysis/test-prep/maps-focus-next-20261031/Prepare-RouteTest.ps1:49`. Absence from those captures cannot prove absence of a camera event.

**CORRECTION — K1 needs a recovery procedure and controlled conditions.** Before any route test, establish stock camera behavior, stationary surroundings, parking brake, continuous service-brake application, and a separate observer for photos. Define immediate return to P and a known overlay-disable/recovery method. Do not depend on HOME: rear-camera HOME rejection exists at `P/PhoneWindowManager.java:2551`.

Static analysis cannot certify K1 as safe. Camera PASS must cover the complete image, guidelines, controls and recovery after exit.

### Ordering

**DISAGREE — Move K1 and call-interruption checks before any driven Maps route test.** Camera image visibility and the call card’s occlusion are unresolved. The plan itself places the route test first at `PLAN.md:66`, despite calling camera safety work “do early.”

The remaining order is broadly reasonable once the reconnect design is corrected. Keep a single identified baseline per observation set. Recheck camera/call behavior after window-type, focus, mic-routing or startup changes.

### New risks missed

- Type 2003 may expose Honda’s entire right-side status-bar region, not a top strip.
- Raw-event logs do not distinguish wheel and console controls.
- Long presses may combine stock seeking with helper skipping.
- Mic changes may contend with HFP/VR or fail to restore input state.
- Automatic reconnect may restart after intentional STOP or reuse retained native resources.
- Existing capture filters cannot answer several proposed camera, source-routing and volume questions.

## 6. Primary evidence for findings

Evidence is cited at each finding above. Earlier review verdicts were not used as proof.

Reviewed PLAN SHA-256:  
`A3DB2E34EEE8B11631DD4DE16CB5FB78CFA65051E169FE48F45F4DD2F5DB0818`

## 7. Assumptions

- Decompiled/audited files describe the captured Honda software, not guaranteed current runtime parity.
- Maps candidate metadata identifies the intended working tree; all 27 listed source hashes matched.
- Proposed procedure corrections are review recommendations, not authorization for live actions.

## 8. Unresolved uncertainties

**UNKNOWN:** amplifier sender/recipient permission; exact physical origin of captured 138/139; target AVRCP duplicate behavior; public-MIC usability without Honda analog configuration; complete call-window stacking; native camera composition; camera visibility with the overlay; cold-start/default USB/accessibility behavior.

The failed compressed-DEX scans leave additional sender-search coverage incomplete.

## 9. Exact diff summary

None. No files were modified.

## 10. Preservation checks

Frozen artifacts matched these SHA-256 anchors:

| Artifact | Result |
|---|---|
| Frozen M5 APK | `A22E96490B9557AFF022893A8B8B7A08BB13CEC236E52704CDDAFA90A8EE8F40` |
| Disabled M6 APK | `D4DAC2DD8B2AFF1FA7B64BFB32D2A5E889854CCEB4B4A9F7AD5AEF89FB28761F` |
| Receiver DEX | `2FDBC63F2F9D63B764697D311AF89D460AE6B8E14B0FADABA9C9339F7FE7C235` |
| API22 TLS qualifier APK | `86350131FFC5CBE5766E523AB03AE07D4C9F5EAD78F0570B68255C9A3999FC1F` |

No key/credential/private-test material was opened. No guard, milestone, artifact, device or publication state was changed. Whole-workspace before/after equality is **UNKNOWN** because no initial workspace snapshot or Git comparison was performed.