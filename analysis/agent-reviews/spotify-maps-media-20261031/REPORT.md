# Maps photo / Spotify video review — 2026-10-31

The new video shows use of the **large left touchpad** and visible focus moving from Spotify's title row to the top-right control. It supports a media-card navigation problem, but does not establish whether the cause is phone-side focus logic, receiver input semantics, or their interaction. The exact cause remains **UNKNOWN**. No code/device changes made.

## 1. Files inspected

- `PROJECT-RULES.md` and existing AGENTS.md instructions.
- `photos/IMG20261031091747.jpg`, SHA-256 `F1B3D424226AFF51B47A5694A9E36A33793FC6093B4AD9C24B8FC92FD2DA6795`.
- `photos/VID20261031091635.mp4`, SHA-256 `174EFA595DC539BAE9CA52071FE9F66840187124D35787B72877DE3C69158932`.
- Current test `analysis/test-prep/runs/helper_20261031T131432_b7c47627e1bd469a90efe3e189e593b9/`: REPORT.md, input-observation.json, collection.json, capture.log and private capture filenames. Private capture image content was not required for this review.
- Current helper `AaSessionService.java:189` and `InputSource.java:89`; build input hashes in bzone-keys-20261031/candidate.json.
- `tools/ffmpeg/provenance.json` and its matching local FFmpeg/ffprobe binaries. Generated `video-probe.json`, `video-summary.json`, selected extracted frames and contact sheet here.

## 2. Files changed

Only new local review artifacts in `analysis/agent-reviews/spotify-maps-media-20261031/`: Review-Media.ps1, Correlate-Input.js, Finish-Review.ps1, metadata/hashes, extracted frames/contact sheet, bounded input evidence and this report. Original photos/video, logs, production source, APKs and existing reports unchanged.

## 3. Commands run

Targeted Get-Content, Get-ChildItem, rg, Get-Command and view_image reads; Review-Media.ps1 invokes verified existing local ffprobe/ffmpeg to inspect/extract the video, with logs saved locally. Correlate-Input.js reads only saved log records and writes the nominal-time comparison. Finish-Review.ps1 verifies preservation and records results. No device command or dependency installation/download.

Python availability checks failed: the sandbox could not launch the configured Store Python; the required elevated retry reported no suitable Python runtime. `py -0p` lists the stale/unavailable runtime. The existing project-local verified FFmpeg handled the review. No Python-based processing ran.

## 4. Tests run and results

- Local FFmpeg/ffprobe hashes match recorded provenance. Video probe and frame extraction PASS. Video stream: 1920x1080 coded, display rotation -90 degrees, 30 fps, 9.593-second video stream (9.685333-second container). Decoder auto-rotation was retained.
- Frames extracted at 2 fps (half-second sampling), scaled to 960 pixels wide; contact sheet samples every two seconds. Selected frames inspected: 001, 003, 005, 009, 013, 017, 019. Sampling cannot exclude brief intervening focus transitions.
- Original media hashes preserved; current Java build inputs remain identical to the built candidate. Final checks in preservation.json.
- No new app, Android, JNI, car, phone, focus-tree or behavioral test was run.

## 5. Findings

1. **Physical input clarified for the filmed demonstration.** Frames 013 and 017 show the finger on the large left pad; the narrow right pad is visible separately. This resolves which pad is shown in the video, not which pad was used throughout the full session. The latest new adapter specifically handles narrow-pad B-zone keys, so this demonstration does not by itself test its operation.
2. **Visible navigation within the Spotify card.** Frame003 (nominal ~1s), frame005 (~2s), frame009 (~4s) and frame017 (~8s) show a bright outline around the title/metadata row. Frame019 (~9s) shows an outline around the top-right control instead. The bottom playback controls are visibly rendered. Their light-filled play button is not by itself proof of focus: it appears filled while the title row is outlined. No skip-control selection is established by these samples.
3. **Maps comparison is useful but evidence types differ.** The photo shows Maps occupying the right third and Spotify occupying the main left region; Spotify's main playback row is visible. A single photo cannot demonstrate movement. The statement that all Maps options accept Up/Down/Left/Right comes from the operator's preceding report. Together with visible title-to-top-right movement in the Spotify video, this makes a universally broken Down key or universally inaccessible right-third region a poor fit. It does not eliminate a receiver bug that affects one UI layout or interaction pattern.
4. **New B-zone adapter was enabled but unexercised in the saved log.** Current run input-observation.json records enabled marker at capture.log:37189, PID5551, zero INPUT_BZONE_RAW and zero INPUT_BZONE_KEY entries after the run boundary. Ordinary raw Down code146 occurred 33 times across that run. This is consistent with the filmed main-pad use. It is not a hardware rejection of correctly delivered new B-zone pairs.
5. **The smallest remaining investigation is a precise main-pad/media-card trace**, rather than another global Up/Down remap or assuming the right pad was used. Compare one title-row-to-lower-controls attempt with its hover/pad stream, directional key stream and focus feedback; contrast with the working Maps interaction. The existing broader alternatives report already discusses mixed pad-plus-key input and controlled controller/capability comparisons. No further test or implementation is started here. Phone-side AA dashboard/media layout remains a candidate; calling this a proven Spotify app defect would exceed the evidence.

## 6. Primary evidence for each finding

| Finding | Primary evidence |
|---|---|
| 1 | `frames/frame_013.jpg`, `frames/frame_017.jpg`, original video hash above; full-session pad usage remains UNKNOWN |
| 2 | `frames/frame_003.jpg`, `frame_005.jpg`, `frame_009.jpg`, `frame_017.jpg`, `frame_019.jpg`; video metadata in video-probe.json |
| 3 | Original Maps photo and preceding operator statement retained in current run collection.json; photo alone is not motion evidence |
| 4 | Current run input-observation.json (run boundary30808, PID5551, enabled marker37189, raw/mapped B-zone empty, code146 count33); original capture SHA-256 `1155CD10064732026B62202DA1D08B6C558E6A3F71347C50987F048D9135FB93` |
| 5 | Above visual/log comparison plus `AaSessionService.java:189` (key send), `:197` onward (pad send) and `InputSource.java:89` (native key result log). These demonstrate receiver paths, not the phone's focus decisions. Canonical alternatives report E8 preserves earlier main Down submissions during the symptom |

`nominal-video-input.json` includes selected log line numbers and native key return counts in a broad 09:16:30–09:16:50 window. This is **not an exact action-by-action synchronization**. Filename suggests recording began 09:16:35, whereas stream creation_time is 13:16:45Z (possibly finalization). Clock offset and timestamp semantics are UNKNOWN. Do not equate every key in that window with a particular visible swipe. Native return0 proves a local send return, not phone receipt or UI focus movement.

## 7. Assumptions

User identifies these newest files as the Maps/Spotify evidence for this session. Frame times are nominal sampled output positions; exact original presentation timestamps/action timing not established. UI outlines are treated as visible focus indicators, not an accessibility-tree inspection.

## 8. Unresolved uncertainties

Exact down-attempt timing, all intermediate video frames, exact pad gesture-to-key correspondence, phone-side focus hierarchy/capabilities, whether hover movement interferes with key navigation, and why the lower media controls are skipped remain UNKNOWN. Working Maps motion is operator-reported, not proven by its static photo. Narrow-pad behavior across the rest of the session remains UNKNOWN. No root-cause fix is claimed.

## 9. Exact diff summary

New review directory only, containing evidence extraction/correlation/preservation scripts, original-file hash manifests, video metadata, derived frames/contact sheet, nominal log-window evidence, preservation result and this report. No original media edits, existing live-report edits, instruction-file edits or production code changes. No new build.

## 10. Preservation checks performed

Original media rehashed against media-hashes-before.json; saved capture hash checked against collection.json; all 27 Java build input hashes and built candidate APK compared with candidate.json. Nine preserved artifacts compared with the build's before.json. See preservation.json. No ADB, USB, phone/car operation, key-material inspection, frozen rebuild, Git mutation, readiness bypass or milestone action. Derived media remains local/private and is not published.

Canonical prior alternatives: `analysis/agent-reviews/offline-alternatives-20261031/REPORT.md`. Current live collection report remains unchanged; this report adds the video-based physical-pad clarification.
