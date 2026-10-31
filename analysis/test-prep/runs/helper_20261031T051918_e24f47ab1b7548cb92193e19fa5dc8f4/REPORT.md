# Duplicate-ENTER isolation — live result

**Movement, Select and Back pass by operator report. Spotify's right-third dashboard panel still cannot navigate down to its skip controls.** The contact filter worked, but it is not a sufficient repair for that remaining defect. No further production change was made during collection/review.

All logs were pulled first. Eleven private captures and the installed APK were then saved. Cleanup was verified and the user was given SAFE TO DISCONNECT. Further review was offline. Machine-readable evidence: [RESULTS.json](RESULTS.json), [collection.json](collection.json), [inspection-excerpts.json](inspection-excerpts.json), [input-timeline.tsv](input-timeline.tsv).

## 1. Files inspected

PROJECT-RULES.md; current session/final-ready records; full capture and watchdog logs; installed-posttest.apk; postchecks and collection record; THISSETUP.jpg; five selected native captures; current build source/provenance; preceding contact-anomaly report and preservation manifest. Native photo/capture review was limited to the named samples; all eleven retrieved image files have hashes.

## 2. Files changed

New evidence/review files in this run directory, including initial/final log pulls, hashes, private captures, post-test APK, cleanup/postchecks, analysis JSON/timeline and this report. Added collection/analysis scripts under `analysis/test-prep/hover-dedup-20261031/`. No production source, candidate APK, prior report or guard was changed during this task.

## 3. Commands run

Executed `analysis/test-prep/hover-dedup-20261031/Collect-CurrentTest.ps1`. It used existing journaled command/cleanup functions, pulled the complete selected run before cleanup, stopped only an identity-matched owned watchdog if still present, invoked the existing cleanup, repulled final logs, retrieved only the logged private image session, pulled/hashed the installed APK and checked settings/services/processes.

Then executed `Analyze-CurrentTest.js` offline and inspected THISSETUP plus selected captures. Detailed command output is saved in commands.jsonl, postchecks.json, manual-cleanup.txt and the evidence directories. No device commands were needed after disconnect clearance; no new live test was started.

## 4. Tests run and results

| Check | Result |
|---|---|
| Installed APK | Matches `C458B51DA03A9B96776E233A220B03C04254C13F4AC7E2BB790325590DDA14FD` |
| Policy | INPUT_HOVER_DEDUP_V1 confirmed in fresh app process 8808 |
| Duplicate ENTER suppression | 18 suppression markers |
| Forwarded duplicate pad DOWN | **0**; prior run had 10 |
| Pad stream | 149 DOWN, 1562 MOVE, 148 UP; no orphan UP; final open contact immediately precedes scheduled force-stop |
| Left / Right keys | 11 / 14 complete pairs, all native results 0 |
| Up / Down keys | 14 / 37 complete pairs, all native results 0 |
| Back | 3 complete pairs, all native results 0; operator confirms works |
| Select | 17 complete pairs; 17 SELECT feedback callbacks; operator confirms works |
| Movement | Operator confirms movement works |
| Phone focus feedback | 72 FOCUS_CHANGE callbacks |
| Right-third Spotify lower controls | **FAIL**, explicitly reported and layout photographed |
| Local input-send errors | No nonzero native-key result or pad-send error log in scoped process |
| Collection | Full logs, eleven captures and installed APK retrieved and hashed |
| Cleanup | Original accessibility values matched; helper/services/logger/watchdog absent |

No new host tests were run for this evidence-only review. Native return 0 is a local submission result, not proof of a particular phone UI action.

## 5. Findings

### Contact filtering succeeded without fixing the right panel

Eighteen duplicate ENTER events were suppressed, and the forwarded sequence contains no duplicate DOWN. The operator nevertheless reports the same inaccessible right-panel controls. This is negative evidence against duplicate-DOWN removal alone being the repair. It does not prove duplicate contacts can never affect other behavior.

Working movement/Select/Back makes this candidate a supported short-test reference for those controls. Do not describe the remaining issue as a global Down or Back regression. The last open pad contact is followed immediately by scheduled cleanup; it is not evidence of a newly stuck contact during normal operation.

### Control reachability depends on layout

THISSETUP.jpg shows the right-third Spotify widget's title/information region outlined and its lower playback/skip controls visibly drawn. Native captures show the same widget pattern. In contrast, frame_5_943263.png shows the Next control selected in Spotify's main player occupying the larger left panel. That supports a narrower failure of focus traversal in the dashboard widget, rather than globally missing skip-button functionality or missing rendered pixels.

### Raw-coordinate clipping is now quantified, but its cause is not established

The helper logged 178 forwarded pad events with raw x greater than 1324, with a maximum of 1723. AaSessionService clamps x to 1324 before native send, matching its registered 1325-wide pad. The logs therefore establish a difference between incoming coordinates and delivered coordinates for those events. They do **not** identify the physical pad/device responsible or prove those events caused the failing Down action. Motion source/device identifiers are not logged here.

Do not rescale coordinates from a photograph or assume the right-hand physical pad was used. If this discrepancy is pursued, first correlate source/device and raw-versus-native coordinates with a deliberate gesture on each relevant pad.

### Remaining hypotheses and next isolation

The exact root cause is UNKNOWN. Mixed motion plus gesture-end DPAD delivery and phone-side widget focus semantics remain plausible. The input-coordinate range discrepancy is also a concrete unresolved lead. The previous page/move-key variant already failed after panel return, so merely repeating that mapping is not a supported solution.

The previously proposed next behavior-isolation test remains: consume the raw OEM swipe keys without sending their extra DPAD events, retaining hover, Select/Back, registration and geometry. This would test one navigation input stream at a time. Alternatively, collect motion source/native-coordinate diagnostics before changing behavior if physical-pad identity is the next question. Do not combine coordinate scaling, capability changes and key-policy changes in one attempt. These are recommendations only; nothing further was built or installed.

## 6. Primary evidence for each finding

- Capture: `device-evidence/rdx_7af26727dcdd45778868a2a86049dff6/capture.log`, SHA-256 `1C30CD45060A522FDB06A2F1950A0A48EC1744D98F2A0BF64562B9096628D1F2`. Unique run boundary line 33919; fresh process 8808; policy marker line 40669. Scoped counts and suppression examples are saved in RESULTS.json and inspection-excerpts.json.
- Last pad event: capture line 49819. Force-stop/kill: lines 49820-49821. This bounds the final unclosed contact at the cleanup endpoint.
- Operator explicitly reported all movement, Select and Back working, with the right-third Spotify Down failure, in this conversation. Native key counts and paired transitions are independently recorded in RESULTS.json and input-timeline.tsv.
- Photo `photos/THISSETUP.jpg`, SHA-256 `195826E670CC17B26CD4C254A320F50CA8A7AEC3A6FF361ECC16562D41429656`. Shows the exact failing arrangement and visible lower controls.
- Native images inspected: frame_3_922932.png, frame_4_933103.png, frame_5_943263.png, frame_7_963656.png and frame_10_994272.png. Frame 5 shows Next selected in the main player; frames 4/7 show the dashboard title-region outline. Hashes are in private-image-hashes.json. One reviewed sample contains Messages content; all raw samples remain private and its contents are not transcribed here.
- Raw x examples and native clamp discrepancy: RESULTS.json/rawXOutsideDeclaredPad and inspection-excerpts.json; current `analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/AaSessionService.java:197` onward clamps raw x/y before InputSource.sendTouchPad. Registration remains at :304. The mapping source is unchanged in this candidate.
- Build/input invariants: `analysis/test-prep/hover-dedup-20261031/validation.json`, original build-report.json and post-test installed hash in collection.json. Analyze-CurrentTest.js independently verifies all 27 source hashes and eight preservation artifacts.
- Cleanup: manual-cleanup.txt, postchecks.json, collection.json and journaled explicit process checks in commands.jsonl. The original accessibility values match; no active helper services or owned processes remained when disconnect was cleared.

## 7. Assumptions

The operator's report establishes which controls were visibly usable and the exact failed panel. Logs establish local event submission and contact filtering. No assumption is made about physical-pad identity, phone internals or the exact event responsible for a focus callback.

## 8. Unresolved uncertainties

Phone-side focus traversal in the dashboard widget; mixed input semantics; origin/effect of raw x beyond the declared pad range; repeatability after panel return; and long-session stability. The photograph alone has no validated timestamp synchronization with the head-unit log. The current short pass does not establish general production readiness.

## 9. Exact diff summary

Collection and analysis evidence only. No production code or APK changes during this task, and no historical report rewritten.

## 10. Preservation checks performed

Post-test installed APK matches the selected candidate. All 27 source inputs still match its build report. Four previous APKs and all four frozen anchors match the before manifest. Photos/raw logs/captures remain private; no publication or Git mutation occurred. Cleanup was verified before SAFE TO DISCONNECT. No guard bypass or milestone change was made.
