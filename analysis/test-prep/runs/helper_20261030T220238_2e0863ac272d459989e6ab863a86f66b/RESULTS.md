# Geometry car test — 2026-10-30

**Geometry correction confirmed by the operator. Touch and audio remain incomplete.** The log independently confirms the intended display matrix and a rendered frame. Approximately 65 seconds separate first render and the phone's USB detach. The later transport write error follows that detach; it is not evidence of an earlier spontaneous connection failure.

## 1. Files inspected

Project rules, candidate/build verification, current helper runner, Home/lock snapshots, retrieved capture/watchdog/session evidence, postchecks, overlay/session/input/audio source, and prior touchpad investigation with stock ProjectionActivity as primary reference.

## 2. Files changed

Evidence and this report added only. No source edits this turn. Authorized device actions installed the geometry APK, configured the helper, ran one bounded attempt, and cleaned up temporary processes/settings.

## 3. Commands run

Targeted ADB identity/process/settings checks, reviewed framework hash verification, qualified lock-task/Home observations, APK installation and installed-byte verification, PhonePreference setup with 120-second watchdog, evidence retrieval, and cleanup checks. No Honda force-stop/kill-loop, privileged input-routing modification, app build, signing, Git staging/commit, or milestone action.

## 4. Tests run and results

- Installed candidate: CFFC54940CD46857E7B9C49208D6851FE7FA8A50C83E11F0CAC36EFFB6444F33.
- Geometry: expected matrix logged twice; actual decoder format confirmed; zero geometry-rejection markers.
- First rendered frame: 18:03:40.601 device wall time.
- Operator: picture “worked” and “looks good”; touch controlled Home instead of AA; no audio.
- Overlay touch markers: zero in this run; input service registered successfully.
- Audio setup callbacks: two; playback-start markers: zero. Audio source/sink registration is not playback proof.
- Phone detach: 18:04:45.663. Write error: 18:04:46.035, 372 ms later. Shutdown completed at 18:04:47.089.
- Planned watchdog force-stop: 18:04:52.743. No matching GAL error/bad-record-MAC marker after this run's boundary.
- Cleanup: no helper process; owned capture and watchdog PIDs absent; accessibility empty list/0, matching baseline. Frozen hashes 4/4 match.

## 5. Findings and next implementation work

### Geometry works for the observed configuration

The decoder again reports a visible 1920×1080 picture. The overlay logs active 1920×720, view 1920×720, source offset (0,180), and matrix (1,1.5,0,-180), followed by decodedFormatConfirmed=true. The operator confirms the resulting picture looks good. This validates the centered-margin correction for this phone/configuration, not every fallback or resize case.

### Input is registered but not captured by the overlay's current path

The overlay uses FLAG_NOT_FOCUSABLE and only an OnTouchListener. It has no hover/generic-motion or key handler. Session forwarding requires that touch listener to call onAaTouch; zero RDX.AAOVERLAY TOUCH markers occur. The stock implementation and earlier review identify hover movement and DPAD_CENTER selection as relevant Honda paths. These source gaps support the user's observation that controls reach Home. However, no focused-window snapshot or raw event trace was captured during the active video; the precise target/routing mechanism remains UNKNOWN. The post-test Diagnostics focus does not establish focus during video.

Next input work should capture/forward the correct app-level focus, hover, and selection events while video is active, and verify cleanup restores normal UI control. Do not guess touchbridge Binder transactions, properties, or kernel modes from the repeated mode-change log messages. Native touchpad registration and geometry mapping alone do not route events to the app.

### Audio playback is unimplemented

The effective shared AudioSink explicitly registers service configurations but its dataAvailableCallback only acknowledges each frame. It does not queue/play PCM through AudioTrack or any other audio output. This implementation cannot provide sink playback. The capture has setup callbacks but no playback-start marker; actual PCM arrival is UNKNOWN because this stub does not instrument it.

Next audio work requires a bounded PCM playback queue, correct stream formats, audio focus/routing, lifecycle cleanup, and diagnostics for received/played/dropped bytes. Do not treat a volume change or an advertised audio service as a substitute for implementing playback. Microphone capture remains a separate stub/gap.

This attempt is complete. No input/audio implementation or second test was started under this result report.

## 6. Primary evidence for each finding

- device-evidence/capture.log:34604,34609 input initialization/registration; :34611–34613 audio registrations; :34735,:34739 audio setup.
- :34876 selected video; :34879 initial transform; :34966 decoder crop; :34968 confirmed transform; :34969 first render.
- :37409 phone detach; :37490 subsequent transport write failure; :37585 shutdown complete; :38011 watchdog stop.
- RESULTS.json: run-scoped counts/excerpts, capture SHA-256, operator report, and timing intervals. The unique run boundary excludes buffered earlier logs.
- AaOverlayService.java:201 OnTouchListener, :208 non-focusable window, :283 touch callback. AaSessionService.java:191–203 handles/forwards only DOWN/UP/MOVE from that callback.
- AudioSink.java:54–55 acknowledges and discards data. Initialization/setup logs do not imply playback.
- Prior primary-reference navigation: analysis/agent-reviews/codex-touchpad-investigation.md, F2–F5; decompiled/AndroidAuto-current/.../ui/ProjectionActivity.java contains stock hover/key handling.
- post-settings.txt, post-processes.txt, post-helper.txt, termination-check.txt, watchdog.log: cleanup evidence. preservation.json: frozen anchors.

## 7. Assumptions

The same disabled OnePlus 13 was tested. The reported Home interaction is the user's observation; no direct raw event trace was taken. A physical phone swap is consistent with the logged detach, but its precise initiation is not recorded independently.

## 8. Unresolved uncertainties

Exact active input recipient/event types, solution for focus/hover/keys, PCM arrival and routing, microphone behavior, and reliability beyond this short observation remain UNKNOWN. No claim of complete functional Android Auto or milestone completion is made.

## 9. Exact diff summary

Test evidence/report files only; no source/APK change. Temporary preparation processes and accessibility settings cleaned up. Persisted helper phone policy remains intentional. No unrelated package changed, files deleted, or Git staging/commit.

## 10. Preservation checks performed

Installed hash matches the pinned candidate. Four frozen artifact hashes match. Existing source and historical evidence retained. Cleanup targeted only the owned logger; the firmware's system logger remains. No credential access, privileged routing mutation, or milestone advancement this turn.
