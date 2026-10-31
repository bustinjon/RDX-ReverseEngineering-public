# Operator results and offline review — 2026-10-31

## 1. Files inspected

PROJECT-RULES.md; current run session, longdrive-session, collection and cleanup evidence; final pulled capture.log, preparation-capture.log and health.log; InputEvents.java, AaOverlayService.java, AaSessionService.java and SensorSource.java. Broad extracts include pre-run history; conclusions below use current helper PID 6800 and explicit source references.

## 2. Files changed

Added Review-LongDrive.ps1 and this offline-review directory's derived extracts/metrics/report. No application source, APK, existing device evidence or collection verdict changed. No ADB used during this review.

## 3. Commands run

Saved `Review-LongDrive.ps1` (initial extraction, then refined helper-PID metrics); read-only Get-Content, Get-ChildItem and scoped rg searches. Detailed matches saved to lifecycle-matches.txt, navigation-matches.txt and input-matches.txt; current-session conclusions saved separately in own-session-timeline.txt and own-input-summary.json.

## 4. Tests run and results

Offline evidence analysis only; no car test, build or behavior test. Twelve health samples span uptime 355.67–1019.54 seconds (about 11 minutes) with no initial-PID warning. RSS samples range from 50,160 to 71,096 KiB and end at 66,296 KiB; this short sample cannot establish a leak or multi-hour stability. Final collection independently passed cleanup and pinned APK verification.

## 5. Findings

**Operator observations, preserved separately from inferred causes:** Spotify right-third bottom playback row remains inaccessible as expected. Volume adjustment works, but its visual display does not appear. Next/Previous fail from both steering-wheel and physical controls. Maps ends a newly started route after approximately 30 seconds. Exact route-start/end times, whether AA/music continued, and drive length have not been supplied.

**Track controls:** verified receiver-side integration gap. Current supported key set is `[4,23,92,93,122,123]`, with no standard media Next/Previous mapping. Raw codes 138 (scan 66) and 139 (scan 67) did reach the overlay, but current mapping rejects them; code 172 also appeared without a matching forwarding path. Which physical controls produced these vendor events is UNKNOWN. No raw87/88 was observed in the current helper's saved events. Do not add only standard87/88 forwarding and assume this solves the actual car buttons; correlate the physical controls to raw signatures first, then verify native AA media-key support and prevent double delivery.

**Volume display:** overlay occlusion is a plausible hypothesis because AA is shown in a full-screen TYPE_SYSTEM_ERROR window; this is not established as the cause. Fifteen raw24 and fifteen raw25 events reached the overlay, consistent with working volume presses reported by the user. No runtime volume-window ordering evidence was collected, and filtered drive logging excludes many OEM volume/UI tags. Bringing an OEM window forward is therefore not yet a verified fix. Broadly lowering overlay priority could regress input isolation and should not be bundled into a blind fix.

**Maps:** no evidence establishes why navigation ends at approximately 30 seconds. The current AA session reached first frame at 13:41:27.751 and recorded its first shown transport-write termination at 13:50:12.135 (8m44s later), followed by surface loss at 13:50:13.210. Thus the saved session termination is not a 30-second startup cutoff. Whether that late USB failure coincides with the user's normal unplug is UNKNOWN. The route cancellation itself is not logged here; phone-side Maps/AA state is absent. A 30-second USB I/O timeout does not by itself explain an independently ending route.

**Sensor contract worth auditing for Maps:** SensorSource registers LOCATION and other vehicle sensors, declares its raw-GPS characterization, but the inspected Java path only calls reportInitialState with static parked/day/speed-zero defaults. Its nativeReportLocation is declared but not invoked in that Java file. Whether native code emits other data, whether the phone selects this sensor source, and whether it affects this route symptom are UNKNOWN. This is a concrete contract discrepancy to investigate, not proof of cancellation causality. Do not fabricate GPS or vehicle values as a workaround.

## 6. Primary evidence for each finding

- Operator observations: user's post-collection message; also summary.json.operatorReport, explicitly labelled an operator report rather than root-cause evidence.
- Key filtering: `analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/InputEvents.java:15–25`; overlay dispatch/logging at `AaOverlayService.java:166–196`. Current capture.log:430 declares the key set; :2342–2347 records codes138/139; :2812 and :2815 record172. Counts and absent87/88: own-input-summary.json.
- Volume: capture.log:2285–2290 and subsequent raw24/25 entries; counts in own-input-summary.json. `AaOverlayService.java:300–320` creates the full-screen TYPE_SYSTEM_ERROR window. No runtime stacking proof exists in the saved scope.
- Session timings: current capture.log:514, :3237 and :3245; own-session-timeline.txt reproduces exact entries. Remaining session state is not inferred from helper PID existence alone.
- Sensor declaration/defaults: `analysis/parallel-aa-receiver/src/com/google/android/projection/protocol/SensorSource.java:24,42,54–68,74–81`; caller `AaSessionService.java:357`. Java-scoped searches for reportLocation/nativeReportLocation found only the native declaration in this inspected implementation, not a reporting loop.
- Health: original health.log, summary.json and stored evidence hashes in the run root. Original filenames are beneath `longdrive-evidence/rdx_226d727ddd5b406c92924a6c548c8bb0/`.

## 7. Assumptions

User observations describe the collected long-drive candidate. The approximate 30-second interval is an operator estimate, not a measured timestamp. No assumption identifies vendor keys with specific physical buttons or the late USB failure with an intentional unplug.

## 8. Unresolved uncertainties and bounded follow-up

Clarify whether Maps actually exits turn-by-turn while AA/music remain connected, or the whole projection session restarts. A future targeted reproduction would record exact route-start/end time and phone-side Maps/AA logs plus receiver input/transport context. Preserve current working controls while identifying hardware Next/Previous signatures; do not implement a guessed vendor-key mapping. Inspect actual OEM volume-window creation/order before selecting a visibility fix. The sensor contract can be reviewed offline before deciding whether a separate single-variable sensor-advertisement comparison is justified. No additional car step or new build is started by this report.

## 9. Exact diff summary

One offline analysis script and derived text/JSON/report additions only. Current app code, APK, input behavior, audio, Gemini and vehicle settings unchanged. Original pulled logs and original collection verdict retained.

## 10. Preservation checks performed

Read existing installed APK hash and collection success evidence; source inspection only. No frozen artifacts rebuilt or rewritten, existing evidence altered, keys accessed, Git writes, milestone changes or device interactions. No full artifact rehash repeated because this review did not modify those files.
