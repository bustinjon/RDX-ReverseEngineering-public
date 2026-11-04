**Review does not pass. T11, T12, T13, and source-lifecycle tooling have blockers.** T09 has no identified blocking code defect; T10 retains conditional double-skip and input-state risks.

Paths below are relative to `C:/Users/REDACTED\Desktop\RDX-ReverseEngineering`. For candidate citations:

- `C09` = `analysis/test-prep/todo-tests-20261103/builds/T09-volume-display`
- `C10` = corresponding `T10-track-buttons` directory
- `C11` = corresponding `T11-mic` directory
- `C12` = corresponding `T12-reconnect` directory
- `C13` = corresponding `T13-day-night` directory
- `H` = `source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper`
- `P` = `source/analysis/parallel-aa-receiver/src/com/google/android/projection/protocol`
- `Tools` = `analysis/test-prep/todo-tests-20261103/tools`

**1. Files inspected**

Read `PROJECT-RULES.md` and `AGENTS.md` first.

Independently diffed all **12 candidate files** against their baseline copies, treating baseline `ABSENT` entries as additions. Inspected candidate manifests, source manifests, build reports, test specifications, host-test sources and saved results.

Also inspected:

- All six scripts in `Tools`, launcher shortcuts, and generated preparation/collection scripts.
- The standalone launcher templates and associated shell helpers.
- `tools/car-test/CarTest.Core.ps1`, `tools/windows-launcher/Launcher.Support.ps1`, and `scripts/Run-CarTest.ps1`.
- Stock seek/media, microphone, sensor-dispatch, LCD Binder/service, and GAL lifecycle implementations.
- Archived A2F478 HUD source, current `InputSource`, `AudioSink`, transport cleanup, USB attachment activity, and preservation manifests.

**2. Files changed**

None.

**3. Commands run**

Only local, read-only operations:

- `Get-Content`, `Get-Command`, `Get-ChildItem`.
- `rg --files`, `rg -n`, and filtered source-range searches.
- `node -e` using filesystem reads for numbered excerpts, independent line diffs, SHA-256 calculations, provenance comparisons, and template comparisons.
- An inert PowerShell argument-binding check.
- A PowerShell AST parsing attempt, which the constrained language mode rejected.

No device, ADB, build, Git, network, or agent-delegation actions ran. No reviewed operational script was executed.

**4. Tests run and results**

| Check | Result |
|---|---|
| Candidate source copies versus source manifests | PASS: all 12 entries |
| Candidate Java changes versus Maps provenance | PASS: only intended candidate Java files differ; none removed |
| Five candidate APK hashes versus metadata | PASS |
| Live Maps Java provenance | PASS: 27/27 |
| Ten baseline tracked paths, including expected absences | PASS |
| Generated PowerShell versus standalone templates | PASS: 18 comparisons after allowed substitutions |
| Generated shell helpers versus templates | PASS: 24 byte-identical comparisons |
| Nine standalone files versus launcher package manifest | PASS |
| Four frozen-artifact anchors | PASS |
| Readiness script/core/schema versus integrity manifest | PASS |
| PowerShell syntax parsing | **UNKNOWN**: constrained language blocked parser access |

Saved host outputs report 57 track-button, 11 volume, 10 day/night, and 18 reconnect-policy checks passing. These were **inspected, not rerun**. They do not establish Android lifecycle, JNI, recording, or service-integration safety.

**5. Findings — candidates and tooling**

**T10-track-buttons — SHOULD-FIX**

- **The 500 ms hold exclusion is implemented correctly for matched releases.** Repeats are consumed; canceled releases do not send; short releases produce a balanced pair. Evidence: `C10/H/InputEvents.java:44–64`.
- **Consuming 138/139 does not suppress the stock path.** Policy broadcasts the event before focused-window delivery; SystemUI processes that broadcast separately. A short press can therefore trigger both the helper skip and the selected stock controller’s skip when that controller supports it. Actual duplicate delivery to the phone remains **UNKNOWN**. Evidence: `decompiled/Policy/sources/com/android/internal/policy/impl/PhoneWindowManager.java:2693–2700`; `decompiled/SystemUI/sources/com/android/systemui/statusbar/auto/HondaStatusBar.java:2523–2532`; `SeekKeyHandler.java:171–173,200–202,254–263,408–420`; `C10/H/AaOverlayService.java:171–183`.
- **Lost-release ownership can suppress another device’s controls.** Ownership persists until a matching release or overlay removal. There is no focus-loss reset. After device A loses its release, device B’s same-direction presses remain consumed without sending. Evidence: `C10/H/InputEvents.java:48–64`; `C10/H/AaOverlayService.java:553–554`.
- **Declaring 87/88 has broader local effects than service discovery.** It also makes `InputEvents.key()` and generic dispatch accept those codes. It does not register Android media ownership or alter Honda’s broadcast routing. Evidence: `C10/H/InputEvents.java:15–27`; `analysis/parallel-aa-receiver/usb-helper/source/com/google/android/projection/protocol/InputSource.java:60–68`.

Stock AA confirms 87/88 are skip commands, but sends their press/release 100 ms apart; this candidate sends them consecutively. Whether that timing matters is **UNKNOWN**. Evidence: `decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/service/media/GalMediaSessionCallback.java:139–154,184–202`.

**T09-volume-display — OK, with unresolved runtime reception**

- **No blocking threading or cleanup defect identified in the added HUD path.** It uses the existing overlay, makes the HUD nonfocusable/nonclickable, unregisters its receiver, and removes handler callbacks during teardown. Evidence: `C09/H/AaOverlayService.java:564–585,598–624`.
- Independent comparison found `VolumeFeedback.java` byte-identical to the archive and both HUD methods text-identical. Stock SystemUI uses the same action and byte extra. Evidence: `analysis/test-prep/diagnostic-rollback-20261031/saved-media-source/VolumeFeedback.java:5–17`; archived `AaOverlayService.java:575–606`; `decompiled/SystemUI/sources/com/android/systemui/statusbar/auto/VolumeManager.java:262–263`.
- **Broadcast eligibility remains UNKNOWN.** Receiver registration alone does not prove the OEM sender permits this app to receive it. The signal checker’s inference is insufficient, as discussed below.

**T11-mic — BLOCKER**

- **Capture termination is not established before native destruction.** `shutdown()` interrupts and joins for 1500 ms without checking `isAlive()`. `destroy()` then calls `nativeShutdown()`. A capture thread blocked in JNI, or paused after its `shuttingDown` check, can overlap native destruction. A blocked read can also retain the recorder beyond teardown. Evidence: `C11/P/AudioSource.java:47–54,80–81,125,176–181`. Require confirmed worker termination or retain native resources and fail closed.
- **Recorder exceptions can leak a successfully constructed recorder.** If `startRecording()` throws, local `r` has not yet been assigned to `record`, and the catch does not release it. Evidence: `C11/P/AudioSource.java:94–110`.
- **Recording failure never becomes a bounded failure state.** After 15 failed preparations, the outer loop immediately attempts another batch while unpaused. Missing permission or persistent initialization failure produces continuing retries and an apparently accepted microphone session without PCM. A zero-length read can also spin without incrementing the error count. Evidence: `C11/P/AudioSource.java:65–76,91–118,124–132`.
- **SHOULD-FIX — ACK accounting crosses microphone sessions.** Every open replaces the semaphore, while ACKs ignore their session argument. Late ACKs can credit a newer session. The send-before-acquire sequence and timeout continuation also provide no strict outstanding-frame ceiling. Stock shares much of this behavior; that is precedent, not proof of correctness. Evidence: `C11/P/AudioSource.java:60–76,139–145`; stock `MicrophoneRecorder.java:186–200,295–313,342–343`.
- **Destroy hang assessment:** the Java join is bounded; no definite Java monitor deadlock was established. Native-call completion is unbounded and **UNKNOWN**, so teardown cannot be certified bounded.
- **Permission/routing:** RECORD_AUDIO is declared, but its actual grant and usable public-MIC routing are **UNKNOWN**. Stock additionally configures Honda input and cancels voice preparation on failure. Evidence: `C11/source/analysis/parallel-aa-receiver/usb-helper/AndroidManifest.xml:7`; stock `ProjectionActivity.java:2509–2513,2530–2538`; `audio/GalAudioManager.java:42–89`.

**T13-day-night — BLOCKER**

- **OK — transaction 6 is the read-only getter.** Its Binder branch only enforces the interface descriptor, calls `getLCDMode()`, and returns the ordinal. The service getter only reads `mCurrentLCDMode`. No caller-permission check appears in that transaction path. Evidence: `decompiled/HondaManager/sources/com/honda/auto/lcd/IHondaLCDManagerService.java:245–250`; `decompiled/Services/sources/com/honda/auto/lcd/HondaLCDManagerService.java:1645–1646`. Enum order is DAY, NIGHT, SCREEN_OFF: `HondaLCDManager.java:58–61`.
- **BLOCKER — timed join is treated as confirmed shutdown.** The synchronous Binder read can outlast `stop()`’s one-second join. The loop does not recheck `running` after the read before invoking the listener. Session cleanup then destroys `SensorSource` regardless of watcher liveness. Its `created` check is unsynchronized and cannot protect an in-flight JNI call. Evidence: `C13/H/NightModeWatcher.java:45–65,80–86`; `C13/H/AaSessionService.java:617–627`; `C13/P/SensorSource.java:84–93`.
- **Own-thread JNI safety is UNKNOWN.** Stock routes sensor updates through a handler under a GAL lock; this candidate calls JNI directly from its polling thread. Evidence: stock `sensors/SensorManager.java:188–195`; `C13/H/AaSessionService.java:359–363`.
- **SHOULD-FIX — failed reporting suppresses retries.** The watcher records a value before delivery; the JNI result is merely logged. A failed report is not retried while the LCD mode stays unchanged. Evidence: `C13/H/NightModeWatcher.java:61–64`; `C13/P/SensorSource.java:84–87`.

**T12-reconnect — BLOCKER**

- **Fail-closed and cooldown decisions do not guard session starts.** AUTO_GRANTED checks only `phase == GRANTED`; FAILED and cooldown WAITING states can start immediately. `startAaSession()` does not check `reconnect.disabled()`. After an unclean shutdown retains native objects, a later AUTO_GRANTED can therefore initiate another session. Evidence: `C12/H/UsbHelperService.java:173–189,489–519`; `ReconnectPolicy.java:23–26,33–40`; `AaSessionService.java:628–645`.
- **Duplicate handoffs corrupt generation tracking.** A permission callback can start a session even after another path has handed off. Each handoff increments generation; `AaSessionService` rejects duplicate START without reconciling that generation. The real session’s eventual completion is then stale, leaving the helper GRANTED with polling stopped. Evidence: `C12/H/UsbHelperService.java:220–225,451–456,489–498`; `AaSessionService.java:84–87`; `ReconnectPolicy.java:35`.
- **“Clean” does not establish all workers stopped.** The completion flag covers transport threads and decoder. Existing audio destruction only logs a surviving playback worker and returns, allowing `clean=true`. Evidence: `C12/H/AaSessionService.java:607–627,645`; `analysis/parallel-aa-receiver/src/com/google/android/projection/protocol/AudioSink.java:97–106`.
- **Explicit session STOP is treated as recoverable failure.** With the helper alive and phone attached, STOP leads to a clean completion and automatic rearm. No operator-stop reason is transmitted. Evidence: `C12/H/AaSessionService.java:112–114,645,651–656`; `UsbHelperService.java:501–519`.
- **SESSION_ENDED can be lost.** It is a nonsticky dynamic broadcast without acknowledgement or reconciliation. Destruction before `running=true` also skips `shutdown()` and notification. Package scoping does not authenticate a sender. Evidence: `C12/H/UsbHelperService.java:72–77,112–113,672–674`; `AaSessionService.java:651–669`.
- **A stopped helper can restart on attachment.** SESSION_ENDED itself does not recreate it, but the manifest attachment activity explicitly starts it; its reconnect generation/budget then resets. Evidence: baseline manifest `:14–23`; `analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/UsbAttachActivity.java:28–39`.
- **OK — stock supports fresh GAL construction without requiring process restart in the shown lifecycle.** It destroys the old integration and constructs new integration/receiver objects. This supports the design direction, but does not validate this candidate’s cleanup. Evidence: stock `ui/ProjectionActivity.java:1966–1969,1994–2011`; `integration/AbstractGalIntegration.java:102–137`; `integration/GalIntegration.java:51–52`.

Normal session starts are serialized by `sessionActive`, and transport close releases the interface before cleanup notification. Nevertheless, the retained-resource restart path above defeats the claimed safety boundary. Evidence: `C12/H/AaSessionService.java:84–87,603–605`; `analysis/parallel-aa-receiver/src/com/rdx/fullscreen/projection/UsbBulkTransport.java:128–130`.

**Tooling — BLOCKER**

- **Cannot confirm complete source/APK matching.** CurrentSource verification checks recorded Java inputs only. It ignores the manifest, extra Java files, resources and other inputs. `Switch-Source` also exits successfully for an already-active test without revalidating its files. A mismatched T11 manifest therefore need not fail the car runner. Evidence: `tools/car-test/CarTest.Core.ps1:17–28`; `Tools/Switch-Source.ps1:39`; generated `C11/Prepare-TimedStage.ps1:99–103`.
- **Candidate source can remain active without a clear warning after prepare failure.** Switching precedes recovery/preparation. Restore occurs on successful collection or the handled Diagnostics failure, but the general catch only reports NOT READY. Switch output is redirected to a log. Evidence: `Tools/Run-Test.ps1:64–74,81–97`.
- **Build-Test can restore another active test’s source.** If switching is refused because another candidate is active, its unconditional `finally` still invokes baseline restoration. Build-Test and Switch-Source do not share Run-Test’s session lock. This can invalidate the source match of an ongoing candidate run. Evidence: `Tools/Build-Test.ps1:25–27,49–54`; `Switch-Source.ps1:20–40`; `Run-Test.ps1:41`.
- **OK — mandatory readiness checks are preserved.** Independent full-template comparisons passed for every package, beyond the generator’s narrower substring assertion. Evidence: comparison output reported all 18 expected-substitution matches and 24 shell byte matches; `Tools/New-TestPackage.ps1:33–63`.
- **OK — Check-Signals’ device commands are read-only:** `get-state`, `dumpsys activity broadcasts`, and `service list`. It writes local evidence files. Evidence: `Tools/Check-Signals.ps1:18,25–28`.
- **SHOULD-FIX — signal verdicts overstate permission evidence.** It accepts any action-text hit, scans an arbitrary following 12 lines, and treats no permission found as “likely readable.” Summary/registration hits lack the required context, and adjacent records can contaminate attribution. A named required permission also does not alone prove this app lacks it. Evidence: `Tools/Check-Signals.ps1:30–41`; `decompiled/Services/sources/com/android/server/am/BroadcastQueue.java:1228–1278,304–307`. The specific broadcasts dump does request detailed records, but also includes summaries: `ActivityManagerService.java:9631`.

**6. Primary evidence**

Each finding above includes primary source locations. Independent comparison and hash-check command outputs support the validation results; prior review prose was not treated as proof.

**7. Assumptions**

- Decompiled code represents the captured firmware; current runtime parity is not established.
- Metadata identifies intended artifacts; matching hashes do not establish behavioral safety.
- Baseline defects are identified where the new feature depends on them; none were changed.

**8. Unresolved uncertainties**

**UNKNOWN:** JNI locking and native-call termination; actual RECORD_AUDIO grant and Honda mic routing; OEM broadcast eligibility; real duplicate skips and physical key delivery; camera/call visibility; actual teardown/reconnect timing; runtime GAL reinitialization reliability.

These candidates have not received behavioral or live safety validation in this review.

**9. Exact diff summary**

No review edits.

Candidate differences independently observed:

| Candidate | Baseline differences |
|---|---|
| T10 | Overlay wiring; MediaButtons; 87/88 declaration |
| T09 | Overlay HUD/receiver; added VolumeFeedback |
| T11 | AudioSource capture implementation; RECORD_AUDIO |
| T13 | Added watcher; session wiring; SensorSource report method |
| T12 | Added policy; helper integration; session-completion broadcasts |

**10. Preservation checks performed**

All four frozen artifacts matched their full `PROJECT-RULES.md` SHA-256 anchors. The readiness script, core, and schema matched `PROJECT-INTEGRITY.json`. Live source matched all 27 Maps Java hashes and all ten baseline tracked-path expectations.

No key/credential/private-test material was opened. No files, guards, milestone state, or devices were modified. Whole-workspace before/after equality is **UNKNOWN** because no initial complete snapshot was taken.