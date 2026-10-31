# Hover restore A — car-test result and offline review

**Partial restoration:** the operator confirms Up/Down navigation works in the app grid. Down still cannot reach the skip controls in Spotify's right-hand one-third dashboard panel. Back was not tested in this run. The exact remaining root cause is **UNKNOWN**.

Evidence was pulled before analysis. The user was cleared to disconnect after all ten private images and the post-test APK were retrieved and cleanup was verified. Subsequent review used local files only. See [RESULTS.json](RESULTS.json), [collection.json](collection.json) and [input-timeline.tsv](input-timeline.tsv).

## 1. Files inspected

- PROJECT-RULES.md; this run's session.json, final-ready.json, installed APK copies, full capture/watchdog logs, postchecks and private images.
- `photos/VID20261031001810.mp4`, nine seconds, inspected through muted Windows video decoding and sampled frames. Original video is unchanged.
- Current InputEvents, AaOverlayService, AaSessionService and effective InputSource; matching factory ProjectionActivity, InputSource, VirtualPointer, GalIntegration and HMIPresenter; archived framework View/ViewGroup hover dispatch.
- Previous v5, page/move, directional-only and observer results; v5 full input capture; candidate build metadata and preservation manifest from hover-restore preparation.

## 2. Files changed

Only new collection/review evidence in this run directory: device-evidence, initial hashes, postchecks, post-test APK copy, ten private captures and image hashes, collection.json, private video review frames/metadata, RESULTS.json, input-timeline.tsv and this report. **No production source, build, prior report, runner or guard change during collection/review.**

## 3. Commands run

Targeted ADB get-state/pull for the selected run directory first; targeted settings/service/process checks; pull only the logged capture session through its standard legacy storage alias; retrieve installed package path/APK and verify its hash; explicit /proc checks for the helper, capture and watchdog PIDs. After disconnect clearance: local Node log/ZIP/hash analysis, source searches, image inspection and muted WPF video sampling. No subsequent device action, package replacement, new test or publication.

The initial process-absence regex incorrectly matched the two PID numbers recorded on separate lines. Explicit /proc checks confirmed all three PIDs absent. The corrected collection record preserves that explanation rather than hiding the failed check.

## 4. Tests run and results

| Check | Result |
|---|---|
| Post-test APK | Matches candidate `D404014AC8D4F58F2C79AA51DE8DF0D9146A80A801B1FC1AF8BA7A1B9511E612` |
| Input policy | INPUT_HOVER_RESTORE_V1 and six-key registration present in fresh process 5815 |
| Up/Down in app grid | PASS, explicitly confirmed by operator |
| Spotify right-third lower skip controls | FAIL, explicitly reported; failing layout captured |
| Back | NOT TESTED; no native key 4 events |
| AA feedback | 61 FOCUS_CHANGE, 9 SELECT callbacks |
| Native arrow keys | Up 13, Down 36, Left 10, Right 8 complete DOWN/UP pairs; all returns 0 |
| Select | 9 complete pairs and 9 SELECT callbacks; final tenth DOWN cut off by cleanup |
| Pad forwarding | 1,202 logged events: 106 DOWN, 1,000 MOVE, 96 UP |
| Pad contact sequence | 10 additional DOWNs while contact already active; no orphan UP; ends inactive |
| Local errors | No nonzero native-key returns, pad-send error logs or fatal-exception marker in the scoped capture |
| Preservation | All 27 current source hashes match the tested build; prior three APKs/four frozen anchors unchanged |
| Cleanup | Original empty accessibility service list / enabled=0 observed; helper 5815, logger 5762 and watchdog 5876 absent; no active helper services |

These checks establish observed behavior and local submission, not phone-side consumption of every event. Individual Left/Right visible-action checks were not explicitly reported for this attempt. No new host tests were required for this evidence-only review.

## 5. Findings

### A. The broad vertical-navigation regression is partially restored

The build changed only hover forwarding and its diagnostic marker from observer A. The operator explicitly distinguishes a working app grid from the failing right-hand Spotify panel. The current run contains positive focus feedback and changing selections in captures. Record this as partial restoration, not a fully fixed input stack or proof that every earlier control now passes.

### B. The remaining failure is an AA panel/focus-traversal problem after local event delivery

The saved video and native captures show the lower media controls are drawn. Sampled video frames show the title/information area outlined before and after the visible pad interaction, rather than a selected skip control. The app's TextureView samples show the same dashboard layout and title-region outline, with map focus in another sample. This disfavors missing/clipped controls as the explanation.

In a representative burst from 00:18:15.330 through 00:18:19.859, ten Down key pairs reach JNI with return 0; hover strokes also continue, with multiple strokes reaching raw y=719. No FOCUS_CHANGE callback is recorded in that burst. This narrows the observed failure but does not identify the phone-side branch or prove the absence of all transient focus changes.

### C. A concrete pad-contact anomaly is present, including after Select

The forwarded stream contains 106 DOWNs and 96 UPs. All ten excess DOWNs are repeated DOWNs without an intervening UP: one at initial contact, nine after the nine completed Select clicks. Example: Select UP at 00:17:47.989 is followed by two pad DOWNs at 00:17:47.991 at the same logged coordinates. The ordinary Select key itself has a completed DOWN/UP pair and positive SELECT feedback.

This is a real local sequence discrepancy worth isolating. It is **not proven to cause the Spotify failure**, and it is **not newly introduced by hover-restore**: the inspected earlier v5 capture contains 13 repeated pad DOWNs by the same state-sequence check. The app grid works despite these events, which is a counterexample to any claim that they universally disable navigation.

The factory installs its hover listener on a VirtualPointer child View. The helper forwards at the root FrameLayout dispatchHoverEvent override. The reviewed framework ViewGroup dispatch code has explicit already-hovered-child handling for HOVER_ENTER. This difference supports investigation of event normalization, but no stock runtime trace was collected to prove exactly which duplicate events stock suppresses on this car.

### D. Mixed motion/key delivery remains another plausible cause

One physical swipe can produce both pad motion and an explicit DPAD key near the gesture end. That combination is present in the repeated failing Down strokes. Some FOCUS_CHANGE callbacks occur before the corresponding gesture-end key is sent; for example the 00:18:13.608 pad DOWN, 13.729 focus callback and 13.789 DPAD_DOWN sequence. A callback's exact originating event is UNKNOWN because no correlation ID exists.

The mixed stream therefore deserves a separate isolation test. It is not automatically a double-trigger bug: factory code also combines pad motion with OEM swipe keys, and the earlier page/move candidate already failed after returning to the panel. Repeating those four mappings alone is not a supported fresh fix.

### E. Select cutoff and Back must not be mislabeled

The final unmatched Select DOWN is at 00:18:40.051. Scheduled cleanup force-stops the helper at 00:18:40.116, 65 ms later. The prior nine clicks have complete pairs and SELECT feedback. This endpoint truncation does not establish a Select-release regression. There are no Back submissions in this attempt, so Back remains untested.

### Ranked explanation and smallest proposed next test

The precise remaining root cause is UNKNOWN. The most concrete local discrepancy is duplicate pad DOWN delivery; confidence in its existence is high, confidence that it causes this panel-specific failure is limited. Mixed swipe-motion/DPAD semantics is another plausible explanation. The factory/current key-advertisement difference remains unresolved and unchanged from earlier builds; it cannot alone explain why restoring hover brought back grid navigation.

**Recommended next candidate, not implemented:** normalize only repeated hover ENTER/DOWN while a pad contact is already active, preserving the first DOWN, all MOVE events, the matching UP, explicit key mappings, Select, Back, window settings and capabilities. Validate against the recorded contact sequences before any build. Then compare app-grid navigation and the right-hand Spotify controls both before and after a normal Select/app return. This tests an observed anomaly without changing the working key path.

If that has no effect, isolate the extra gesture-end DPAD delivery in a separate candidate, retaining hover, Select and Back. Do not combine these two experiments or alter geometry/capabilities simultaneously. These are recommendations only; no further APK or live attempt was started.

## 6. Primary evidence for each finding

- Full capture: `device-evidence/rdx_55bdb829127e4c229f44186937b71a9d/capture.log`, SHA-256 `A52F7D0AD4508A3AE6F9AE4F8AF17CB1F284D7CFE2EFCEC16E18347204E49DE6`. Unique run marker line 35229; app PID 5815. New policy marker line 42414; key registration 42497.
- Focus callbacks begin at line 43563. RESULTS.json and input-timeline.tsv preserve scoped counts and line references. Operator explicitly confirmed app-grid Up/Down and right-panel failure in this conversation.
- Repeated initial DOWN: lines 43460-43461. Select UP and repeated hover DOWN: lines 44937-44939. Further duplicate locations are listed in RESULTS.json. Previous v5 comparison: run `helper_20261030T234615_99356193e031448eb0d3fb4ebd9b5be9`, capture SHA-256 `3A41DF093BE406D397730394693E58593488CF91AE06984B33C6B7194F199757`, app PID 5395.
- Down-burst example: line 46312 and subsequent Down pairs through 46494; surrounding TOUCH logs show raw-coordinate delivery. Pad bounds and all arrow pair counts are in RESULTS.json.
- Private native captures: frame_6_346202.png, frame_7_356381.png, frame_8_366545.png. Their hashes are saved in private-image-hashes.json. All ten saved PNGs were visually inspected; the first is black.
- Video: `photos/VID20261031001810.mp4`, SHA-256 `5BF1267AB4767C232F887317260DE56645DAD076D696B57E1A1877FA8D7F08B5`. Orientation-correct continuous playback samples and reported positions are in private-video-review/continuous/frames.json. Samples frame_06, frame_08, frame_16 and frame_17 show the title outline and drawn lower controls; frame_12 shows pad interaction. Samples are not a frame-by-frame proof of every intervening selection.
- Factory listener attachment: `decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/ui/ProjectionActivity.java:2226-2229`; hover translation at :574 onward; factory OEM mapping at :2308 onward. Helper root dispatch: `analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/AaOverlayService.java:167`. Framework child hover bookkeeping: `decompiled/Framework/sources/android/view/ViewGroup.java:952` onward.
- Matched factory dimensions: HMIPresenter.java:722-738 and GalIntegration.java:120-126; helper AaSessionService.java:304. Both use 1325x720, 60x40 mm, navigation/absolute enabled and tap-as-select false. Factory InputSource.translateKeycode at :81 is identity, so a missing non-identity translation was checked and ruled out in these sources.
- Final Select and scheduled stop: capture lines 47758 and 47763-47766. Cleanup completion in watchdog.log; explicit absent-PID checks and original accessibility values in postchecks-final.txt; post-test APK hash and cleanup verdict in collection.json.

## 7. Assumptions

The operator's statements identify the app-grid success and exact failing Spotify layout. Motion-event logs describe the helper's forwarding path; they do not expose the phone's internal focus graph. The hypothetical effect of contact normalization remains an assumption until an isolated test.

## 8. Unresolved uncertainties

Exact cause of the widget's inaccessible controls; causal role of repeated pad DOWNs versus mixed swipe-key delivery; phone-side capability/focus interpretation; Back behavior; independent visible Left/Right checks; and long-session stability. The video has no validated clock synchronization with head-unit logs, so its filename is not used as an exact log-time anchor. Private captures include AA content and must remain local/private.

## 9. Exact diff summary

Evidence/report files added to this run only. No production changes, no new candidate and no change to historical reports.

## 10. Preservation checks performed

Post-test installed APK equals the selected candidate. All 27 source inputs remain identical to its build report. The three prior APKs and four frozen PROJECT-RULES anchors match the saved before manifest. Original video/capture hashes are verified. Device cleanup finished; final settings match the original baseline and owned processes are absent. No credentials were inspected; no Git mutation, upload, guard bypass or milestone change occurred.
