# V5 repeatability attempt 1 — lower-right navigation failure

User reports Back and audio working, but cannot move down to Spotify's lower controls on the right. **Partial input failure**, not an overall input PASS. Logs saved and cleanup verified; user told they can disconnect. No new APK built or device test started.

## 1. Files inspected

PROJECT-RULES.md; current v5 InputSource/InputEvents and overlay event paths; this run's session/artifact plan, capture, watchdog, PID files and postchecks; factory ProjectionActivity.java swipe mappings and GalIntegration.java pad registration; stock Protos.java key enum values; prepared repeatability plan.

## 2. Files changed

Local run evidence, device-evidence-hashes.json, postchecks.txt, RESULTS.json and this new report. Repeatability result record added separately. No production source/APK, live script or public repository changes.

## 3. Commands run

Authorized targeted ADB evidence-directory pull and settings/process postchecks. Local hash, boundary-filtered log aggregation and read-only source inspection. No further device actions after confirming disconnect readiness. No Git operations.

## 4. Tests run and results

- Attempt 1 connected and delivered visible Spotify/media according to the user; Back and audio operator-reported working.
- Lower-right downward navigation failed per operator. Exact UI control positions and movement timestamps not captured independently.
- Native logs: 28 Down DOWN/UP pairs, 12 select DOWN/UP pairs and two Back DOWN/UP pairs, all result=0.
- 964 logged movement samples span x=0..1324/y=0..719. Of 103 right-side samples (x>=1000), maximum y=719. No sendTouchPad error diagnostic found.
- Last periodic media counter: received=1500, playedBytes=12263424, dropped=0. This is not a final total. No AUDIO_PLAYBACK_FAILED/AUDIO_WORKER_NOT_STOPPED marker after the run boundary.
- Ten evidence files copied/hashed; watchdog CLEANUP_FINISHED; original accessibility services empty and enabled=0 match current settings. Helper/capture PID 5341/watchdog PID 5457 absent.

## 5. Findings

1. Back and media remain functional under the repeated setup, but v5 has a reported lower-right navigation limitation.
2. Raw movement is not uniformly clipped above the bottom/right limits, and Down events are not entirely lost before native submission. Those counterexamples argue against immediately changing the pad-to-video scale; they do not prove target activation or coordinate correctness.
3. A concrete compatibility gap exists: the factory maps raw OEM swipe codes 146/148/150/152 to protocol key codes 93/122/123/92. V5 accepts only Back, DPAD and Enter-to-select and ignores these OEM gesture codes. The same gesture sequences also produce regular DPAD keys in this capture. Whether adding the missing semantics fixes Spotify is UNKNOWN; forwarding and registration need targeted evaluation to avoid unintended duplicate actions.
4. No evidence establishes whether Honda Home receives underlying input during this run. Center/left accuracy and automatic-prompt behavior were not explicitly reported; do not fill those as PASS.

## 6. Primary evidence

- Finding 1: operator report in this conversation; capture 37023/37862 has progressing media counters, and RESULTS.json preserves the reported failure.
- Finding 2: RESULTS.json boundary line 26485 and aggregate bounds/counts; capture 37613–37790 contains repeated code=20 DOWN/UP with result=0. Capture SHA-256 `3A41DF093BE406D397730394693E58593488CF91AE06984B33C6B7194F199757`.
- Finding 3: local factory `decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/ui/ProjectionActivity.java:2308–2326`; `Protos.java:2978–2979` and `:3008–3009` identify page/move codes. Effective helper `InputEvents.java:5–6` lacks those mappings; InputSource.java:64 registers only 4,19..23. Capture 37613–37619 and 37715–37721 shows raw 146 followed by forwarded 20; RESULTS.json counts 28 raw 146 events.
- Finding 4: capture/observations lack synchronized in-session factory foreground evidence and explicit reports of those checks.

## 7. Assumptions

Operator's location description refers to visible Spotify controls on the right portion of the Android Auto interface. Mapping that report to a specific gesture or captured timestamp is UNKNOWN.

## 8. Unresolved uncertainties

Missing gesture semantics versus AA focus traversal/layout versus another coordinate/input issue; exact failed control/action sequence; underlying Home input; final audio totals. Attempts 2 and 3 remain NOT_RUN. No new v6 fix or repeated live attempt is authorized merely by this report.

## 9. Exact diff summary

Add preserved raw evidence and derived result summaries for one actual attempt. Record the lower-right failure and a primary-source-supported missing gesture mapping. No input scaling, key registration, video geometry, audio, helper lifecycle or watchdog change.

## 10. Preservation checks performed

Runner installed hash matches known v5 `98E6A0015F249960B7730F210FAFB46BDFDAFE7A31686478FD619A930C3831A4`. Full retrieved evidence inventory hashed. Cleanup matches the saved baseline and owned process identities. No original key material read, Git mutation, frozen artifact rebuild, guard bypass or milestone advancement.
