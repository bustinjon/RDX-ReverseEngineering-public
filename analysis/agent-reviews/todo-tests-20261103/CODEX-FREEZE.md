1. **Files inspected**

Paths below use these aliases:

- `S` = `analysis/test-prep/todo-tests-20261103/builds/T240-bundle/source/analysis/parallel-aa-receiver`
- `H` = `S/usb-helper/source/com/rdx/fullscreen/usbhelper`
- `P` = `S/src/com/google/android/projection/protocol`
- `D` = `decompiled/AndroidAuto-current/sources`
- `L` = `analysis/test-prep/runs/helper_20261110T004153_09e0a10d905f4ea3a861207213d5f8bd/longdrive-evidence/rdx_bbe8d8c118fd436ebceecf22a09bd6ef/capture.log`
- `E` = `analysis/test-prep/todo-tests-20261103/builds/T200-bundle/headunit-logs-20261108-231319/logcat-now.txt`

Inspected `PROJECT-RULES.md`, `AGENTS.md`; `H/{AaSessionService,AaOverlayService,HomeToggle,PermissionClickService,FrameRate}.java`; `P/{VideoSink,AudioSink}.java`; `S/src/com/rdx/fullscreen/projection/VideoDecoder.java`; stock `ProjectionActivity.java`, `ProjectionRenderer.java`, protocol `VideoSink.java`; filtered portions of `L` and `E`.

2. **Files changed:** none.

3. **Commands run**

- `Get-Content -LiteralPath` for rules and numbered source excerpts.
- `rg --files`, `rg -n` for scoped source discovery, focus/surface/audio paths, and timestamp-filtered log evidence.
- PowerShell arithmetic and filtered event counts; results appear below.
- Unsuccessful attempts: literal wildcard passed to `rg`; unavailable `python.exe`; PowerShell object/method operations rejected by constrained language mode. Corrected queries and simple arithmetic succeeded.
- No Git, build, device, or credential commands.

4. **Tests run and results**

No executable tests or builds. Static review and log checks returned: **one decoder start, one surface creation, one surface destruction, zero logged audio-focus-change callbacks, zero video-focus callbacks** during 19:43:26–19:45:00. Destruction occurred during shutdown.

5. **Findings**

- **F1 — HIGH: minimize/restore retains the existing surface and decoder.** Minimize changes window flags and alpha; restore reverses them. Neither reconfigures the codec. “Decoder recreated and now awaiting an IDR” is unsupported for this incident. [E1]
- **F2 — HIGH: the immediate re-minimize is a shortcut-release ordering conflict.** Home, Guide, and Back are pressed together. Guide release restores AA; the subsequent Home release minimizes it. These are distinct key events, not evidence of a duplicated Guide event. `HomeToggle` permits this sequence. [E2]
- **F3 — HIGH: T210’s restore request does not establish a focus transition or request an explicit keyframe.** It sends PROJECTED again while local `nativeFocus` is false. **UNKNOWN:** whether the native library suppresses it, the phone ignores it, or the phone sends an IDR. Stock suppresses redundant PROJECTED requests locally; that does not prove phone behavior. [E3]
- **F4 — HIGH: codec output stalls; network-frame starvation remains UNKNOWN.** Output count increases from 441 to 442 over **24.803 s**, with the next output **21.958 s after restore**. FPS logging occurs only on codec-output release, so it cannot distinguish absent input, decoder delay, or actual presentation. Recovery follows without a logged codec restart. [E4]
- **F5 — MEDIUM: sparse wireless updates could explain delayed refresh, but are unproven.** T240 comments assert change-driven video; the logs contain no ingress/NAL telemetry to verify this. A stale compositor texture or shared transport/callback stall remains possible. [E1, E3, E4]
- **F6 — HIGH: `dropped=0` does not establish continuous audio.** Across **39.923 s**, accepted media PCM increases by 1,957,888 bytes—only **10.197 s** at 48 kHz/stereo/PCM16. This establishes inadequate sustained PCM submission across that interval, not its cause. Also, the shutdown summary is `dropped=1`, following an incomplete write. [E5]

6. **Primary evidence, ranked fix, and logging to add**

| Evidence | Exact locations |
|---|---|
| E1: retained surface/codec | `H/AaOverlayService.java:892` minimize; `:907` restore; `:559` destruction callback. `VideoDecoder.java:33` codec creation; `:97` creation only when null; `:113` continued draining; `:118` release on worker exit. `H/AaSessionService.java:665` actual surface loss shuts down protocol. `L:1814`, `:1964`, `:2529` lifecycle logs. |
| E2: shortcut conflict | `L:2085` Home DOWN; `:2086` Guide DOWN; `:2088` Back DOWN; `:2100` Back-hold minimize; `:2105` Guide UP; `:2107` restore; `:2108` Home UP; `:2111` Home decision; `:2112` minimize. Second sequence: `:2120`, `:2121`, `:2122`, `:2143`, `:2150`, `:2152`. `H/PermissionClickService.java:315` handles Home UP; `H/HomeToggle.java:18`, `:26`, `:58` implement the conflicting transitions. |
| E3: focus semantics | `H/AaSessionService.java:1324` restore-wifi branch; `P/VideoSink.java:37` sends `(1,true)`; `:38` answers focus. Stock `D/com/honda/androidauto/projection/sink/ui/ProjectionActivity.java:1546` PROJECTED, `:1558` NATIVE, `:1598` PROJECTED transition guard, `:1607` redundant-request suppression. Stock `D/com/google/android/projection/protocol/VideoSink.java:174` updates local state and calls native. |
| E4: output stall | `L:2171` 441 outputs at 19:44:00.897; `:2182` restore; `:2184` request; `:2326` 442 at 19:44:25.700; `:2361` 568 at 19:44:35.794. `H/FrameRate.java:10` reports only when another output arrives; `VideoDecoder.java:85` counts output release, not confirmed screen presentation. T200 comparison: `E:25592`, `:26501`, `:26953`. |
| E5: audio accounting | `L:2130` received=500/playedBytes=4055040; `:2348` received=750/playedBytes=6012928; both dropped=0. `H/AaSessionService.java:831` media format. `P/AudioSink.java:219` counts bytes accepted by `write`; `:2507` is **not** a source reference—shutdown evidence is `L:2507` incomplete write and `L:2508` dropped=1 summary. |

**Ranked corrective options — proposals, not validated fixes**

| Rank | Proposal and exact methods | Risks / confidence |
|---|---|---|
| **1** | **Keep the current decoder/surface; send unsolicited NATIVE on successful minimize and PROJECTED on successful restore.** Add a mode-taking sender beside `P/VideoSink.java:37`; invoke through the session handler from `H/AaOverlayService.minimizeOverlay:892` and `restoreOverlay:907`. Replace the repeated-PROJECTED logic at `AaSessionService.overlayRestored:1321`. Track desired visibility, last-sent mode, and session generation; cancel stale restore/retry work. Review incoming focus handling at `:1302` to prevent delayed callbacks from undoing a newer visibility decision. | **MEDIUM:** strongest stock-supported approach. Forces a focus transition; a fresh IDR is still **UNKNOWN**. Risks include quick-toggle ordering and assistant/video-focus interactions. Keep audio independent. |
| **2** | Preserve/re-present the retained texture on restore; first measure texture updates and composition. Existing `AaOverlayService.java:892` already keeps the surface alive, so merely “keep decoder alive” adds nothing. A dedicated compositor retaining the last texture would require changes around surface creation `:540` and restore `:907`. | **LOW–MEDIUM:** useful if composition is the failure; larger implementation and GPU/lifecycle risk. Does not repair missing incoming video. |
| **3** | Display a cached decoded-image snapshot while waiting for fresh video; clear it on confirmed texture update. Candidate hooks: `AaOverlayService.java:570`, `:907`. | **LOW:** masks blank/stale presentation but cannot restore live video. `VideoDecoder.java:85` releases output immediately; there is no retained decoded frame to simply resend. Do not replay an arbitrary compressed P-frame. |

**Separate key fix:** make Guide restore chord-aware in `HomeToggle.SidePanel.onKey:44` and both callers (`PermissionClickService.java:318`, `AaOverlayService.java:428`). Suppress/defer Guide restore for an overlapping Home/Back chord; preserve Honda key delivery. Home should retain precedence for that chord. This addresses the demonstrated sequence without broadly ignoring subsequent Home presses. **HIGH confidence for this specific conflict.**

**Logging to add — metadata only, no identifiers or payloads**

- **Video:** at `AaSessionService.frame:1280`, count incoming access units/bytes and interarrival gaps; record NAL-type counts, including IDR/SPS/PPS. At `VideoDecoder.feed:60` and `drain:75`, log queue depth, input waits, output gaps, and outstanding acknowledgements.
- **Presentation/focus:** correlate restore generation, desired/last-sent focus, surface generation, codec generation, output release, and `onSurfaceTextureUpdated` (`AaOverlayService.java:570`). This separates no-input, no-output, and no-presentation cases.
- **Keys:** add event/down times, action, canceled/repeat state, observer route, chord membership, and resulting transition at both key entry points. Existing bounded accessibility logging is at `PermissionClickService.java:314`.
- **AudioTrack starvation/underrun suspicion:** sample playback-head position on API 22, with monotonic time, play state, accepted PCM frames, and estimated buffered duration. Handle counter wrap and pause/flush/reset generations. Head-progress anomalies are diagnostic evidence, not definitive underrun counts. Hooks: `AudioSink.playLoop:182`, write at `:219`.
- **Focus pauses/flushes:** log cause, duration, queued bytes discarded, and phone-focus forwarding. Pauses/queue clears can occur without incrementing `dropped`: `AudioSink.java:42`, `:65`, `:166`; forwarding is `AaSessionService.java:1176`.
- **Empty queue:** log empty-duration transitions, queued audio milliseconds, PCM arrival gaps, and source timestamps around `AudioSink.java:124`, `:185`. Empty polling currently increments no drop counter.
- **TCP stalls:** time header read, body read, and `receiver.incoming` separately in `AaSessionService.readLoop:1091`; instrument individual blocking reads in `tcpPipe:76`. Add independent “read pending” sampling so an unfinished read is visible. Shared serialized delivery can delay both streams.
- **Other zero-drop gaps:** log write duration/errors and worker liveness (`AudioSink.java:217`, `:224`); aggregate silence levels and stream volume/mute/routing changes. `playedBytes` proves acceptance by AudioTrack, not audibility.

7. **Assumptions**

The supplied T240 source snapshot represents the running implementation. APK/source parity was not established.

8. **Unresolved uncertainties**

Actual phone encoder behavior, IDR policy, incoming-video gaps, compositor behavior, and the cause of the PCM deficit are **UNKNOWN**. No logged audio-focus callback in this interval excludes neither unlogged routing changes nor upstream pauses.

9. **Exact diff summary:** none.

10. **Preservation checks performed**

All successful operations were reads, searches, or arithmetic. No files, frozen artifacts, credentials, devices, Git state, or milestones were modified. Frozen-artifact hash parity was not checked.