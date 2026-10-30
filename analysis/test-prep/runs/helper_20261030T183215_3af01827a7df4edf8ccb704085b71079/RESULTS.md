# Phone-preference car test — 2026-10-30

**Visible Android Auto confirmed.** The user saw Android Auto with top/bottom black bars and stretching. Logs independently record a selected video stream, decoder startup, and first rendered frame. Honda's per-phone NEVER path worked during this short observation. Geometry remains incorrect; longer stability is untested.

## 1. Files inspected

Project rules, signed candidate/build record, runner and helper setup journal, current device identity/framework hashes, Home/lock-task snapshots, retrieved capture/watchdog files, postchecks, and overlay/decoder geometry source.

## 2. Files changed

Added this run's evidence, handoff, RESULTS.json, postchecks, and this report. No source code or historical report edited. Device changes were the authorized APK installation, persisted phone policy, temporary accessibility setup, and timed cleanup.

## 3. Commands run

Targeted ADB for head unit 00000000: identity/state checks, reviewed framework/services retrieval, qualified lock-task getter and Home checks, installation/setup via Run-CarTest in PhonePreference mode, evidence retrieval, and cleanup postchecks. No Honda force-stop or kill loop executed; the setup journal confirms zero of each. No build, signing, Git staging/commit, or milestone action this turn.

## 4. Tests run and results

| Stage | Observed result |
|---|---|
| Candidate | DCCA5D8C4EA9E54D765C7554FAD3CD32C7175EA333AB1B29E03AAEA473C98F7D installed and verified |
| Phone identity | Configured 11111111; car logs identify the same phone |
| Honda policy | Raw-phone log says NEVER, do nothing; AOAP attach also reads preference 0 |
| Automatic prompts | Two successful A11Y click markers; user reports no manual acknowledgement |
| USB/protocol | Helper session and USB open recorded; video configuration selected |
| Decoder/render | Decoder starts; FIRST FRAME RENDERED, selected=true |
| Physical observation | Android Auto seen, stretched, black bars above/below |
| Termination | Planned watchdog force-stop approximately 7.221 seconds after first render |
| Cleanup | Helper, capture PID, and watchdog PID absent; accessibility matches original empty list/0 |

No matching GAL error, bad-record-MAC, or transport-ended marker occurs after this run's unique boundary. This is bounded evidence over a short capture, not a long-duration reliability result.

## 5. Findings and recommendations

### Connection and Honda cooperation are established for this attempt

At 14:33:19.342 Honda explicitly logs the OnePlus 13 preference as NEVER. At 14:33:20.548 it reads preference 0 after re-enumeration and transitions to disconnected. Our USB transport opens at 14:33:21.597. Video is selected at 14:33:24.200 and the first frame is rendered at 14:33:24.777. This is direct evidence for the cooperative strategy, beyond an operator assertion or a successful command return.

### The short display is explained by the planned cleanup

READY was sampled at 18:32:36.944 UTC with 51 seconds conservatively remaining. Phone arrival/permission activity occurred around 14:33:19 device wall time (UTC-4). The watchdog force-stopped the helper at 14:33:31.998. Only 7.221 seconds separated the first-render marker and that stop. There is no captured earlier transport/protocol failure explaining termination. The next separately authorized test should allow a longer bounded swap/observation interval using the existing SafetySeconds parameter; preserve the watchdog and readiness checks.

### Geometry is now the primary visible defect

The selected codec raster is **1920×1080**, with configured active area **1920×720**. The decoder reports a hardware storage surface of 2048×1184 but crop bounds (32,24)–(1951,1103), yielding **1920×1080 visible pixels**. Those hardware crop bounds remove decoder padding; they do not establish the active AA content rectangle.

AaOverlayService creates a 1920×720 TextureView surface and does not configure a content transform or explicit buffer geometry. Its surface callbacks only publish/log the Surface. The decoder forwards rendered frames to that surface. This mismatch is consistent with compressing a padded 1920×1080 image into the wide display, retaining top/bottom bars and distorting the UI. This is an inference from the user's observation, logged dimensions, and source; actual black-bar pixel boundaries were not captured.

Recommended next work: apply a display transform based on negotiated codec/active dimensions, keeping hardware crop and AA content margins distinct. If the 360-pixel total vertical margin is centered, the candidate active rectangle is y=180 through y=900 of the 1080-high image; that centering still needs verification. Do not change the decoder's coded dimensions to 1920×720 or crop using the 2048×1184 storage dimensions. Validate the resulting visible aspect ratio and touch mapping together. No geometry change was made in this test.

### Cleanup settings message is qualified by postchecks

The watchdog records ACCESSIBILITY_NOT_RESTORED_SETTINGS_CHANGED, then CLEANUP_FINISHED. This means its compare-and-restore condition did not match, not that restoration was proven by the message. Independent postchecks show the actual values already equal the original values: empty enabled-service list and accessibility_enabled=0. Capture and watchdog PIDs are absent, as is the helper process. The system's own logger was left running.

## 6. Primary evidence for each finding

- device-evidence/capture.log:42125,42137 Honda raw preference 0/NEVER; :42624,42627 AOAP preference/state.
- :42326,:42824 automatic click markers; :42937 session creation; :43105 USB open.
- :43078 local codec/active configuration; :43553 selected configuration; :43666 decoder start; :43744 hardware format/crop; :43746 first frame.
- :44576 planned helper force-stop at 14:33:31.998; device-evidence/watchdog.log and deadline corroborate bounded cleanup.
- session.json and test-handoff.json: candidate, policy, READY timing, zero Honda stop/loop calls.
- post-settings.txt, post-processes.txt, post-helper.txt, termination-check.txt: actual cleanup state.
- AaOverlayService.java:43–55 dimensions, :124–145 texture creation/surface callbacks; no setTransform or setDefaultBufferSize in this implementation. VideoDecoder.java:76–77 computes hardware visible crop; AaSessionService logs the resulting crop and first frame.
- RESULTS.json: run-scoped event counts/excerpts and capture SHA-256. Counts exclude prior buffered logs before the unique run marker.
- Operator report: “worked momentarily,” black bars top/bottom, stretched Android Auto, no manual prompt acknowledgements.

## 7. Assumptions

The user confirmed the same OnePlus 13, newly re-paired and disabled in Honda. Prior ADB/helper-test authorization covers this one test and cleanup. No further test or milestone is inferred.

## 8. Unresolved uncertainties

Actual content-margin position, touch accuracy, audio/microphone behavior, longer stability, reconnect behavior, chooser/default persistence, and behavior for another phone remain UNKNOWN. A render callback alone is not physical proof, but this attempt also has the user's independent image observation. No pixel capture of the displayed AA image was taken.

## 9. Exact diff summary

Evidence/report files added only; source and APK unchanged this turn. Persisted helper phone configuration remains intentional. Temporary services/logger are stopped and accessibility values match baseline. No unrelated package disabled, files deleted, Git staging/commit, or milestone-state change.

## 10. Preservation checks performed

Exact APK hash is recorded by installation verification. Historical evidence retained; only this run's capture retrieved. The prior frozen anchors are checked in preservation.json. No credentials queried or printed during the connected test. No milestone advanced.
