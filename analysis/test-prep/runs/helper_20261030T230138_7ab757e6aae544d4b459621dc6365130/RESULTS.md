# V5 car test — 2026-10-30

User reports **click worked and audio worked with Bluetooth Media audio both enabled and disabled**. Saved evidence confirms select-key delivery and receiver PCM playback. This supports audible operation independent of the phone's Bluetooth media link, subject to the operator-reported setting state. Phase transition timestamps and internal speaker route are UNKNOWN. No milestone status is changed by this helper test.

## 1. Files inspected

PROJECT-RULES.md; v5 candidate/build provenance; qualified framework/services copies and Home/lock-task observations in `analysis/test-prep/pad-select-20261030/device-preflight/`; this run's artifact-plan.json, session.json, device-evidence/capture.log, watchdog.log, PID files and postchecks.txt.

## 2. Files changed

Local run evidence, device-evidence-hashes.json, postchecks.txt, RESULTS.json and this new report. On the head unit, v5 installed and temporary helper/accessibility/capture/watchdog state created through the authorized runner; cleanup completed. No source changes.

## 3. Commands run

Targeted ADB identity checks; framework/services pull and SHA-256 qualification; read-only activity getter 217 and foreground samples five seconds apart; established PhonePreference runner with 120-second watchdog; full remote run-directory pull; local file hashes; settings/process cleanup checks. No Honda force-stop loop, factory app replacement, Git mutation or milestone action.

## 4. Tests run and results

- Home foreground and INACTIVE lock-task observed before preparation; expected head-unit fingerprint and qualified framework hashes matched.
- Installed APK hash: `98E6A0015F249960B7730F210FAFB46BDFDAFE7A31686478FD619A930C3831A4`, matching v5 candidate.
- Fresh runner readiness passed. User reports click and both audio phases successful.
- All ten remote run files copied successfully and hashed.
- Watchdog CLEANUP_FINISHED; original accessibility services empty, enabled=0, matched postchecks; helper and owned capture/watchdog PIDs absent.

## 5. Findings

1. V5's pad press-to-select path works for the tested interaction, combining user-reported activation and native key success logs.
2. The receiver obtained protocol audio focus and wrote PCM through AudioTrack. User reports sound with Bluetooth Media audio off, supporting operation without that media transport. This does not prove every internal head-unit route or exactly align each PCM sample with the two phases.
3. Media logs contain two incomplete writes adjacent to playback stops, with two cumulative dropped frames at the last periodic counter. Do not describe this run as zero drops. No AUDIO_PLAYBACK_FAILED or AUDIO_WORKER_NOT_STOPPED markers were found after the unique run boundary. Guidance track initialization is observed; no final guidance byte summary was captured.
4. Evidence retrieval and cleanup are complete; the user can disconnect from the car.

## 6. Primary evidence for each finding

- Finding 1: capture lines 34189–34231 and 36546–36554 pair INPUT_PAD_SELECT down/up with KEY code=23 results of zero. RESULTS.json records the successful select-event counts; user reported click worked.
- Finding 2: capture 31913–31931: request=1, Android focus granted, protocol state=1; 32124: media AudioTrack ready; 33039 onward: increasing PCM/write counters. Last periodic sample at 37287: received=1000, playedBytes=8135680, dropped=2. User reported both media options worked. Guidance AudioTrack ready at 35904.
- Finding 3: capture 34199/34200 and 35810/35812 place incomplete media writes next to playbackStop callbacks. This association is observed, not proof of their sole cause. RESULTS.json records fatal playback marker count.
- Finding 4: device-evidence/watchdog.log says CLEANUP_FINISHED. postchecks.txt matches session.json original settings and contains no helper or owned capture PID 5252/watchdog PID 5385. device-evidence-hashes.json records the preserved ten-file inventory.

## 7. Assumptions

Bluetooth Media audio remained disabled during the reported second phase, as instructed. This phone-side setting was operator-observed, not independently captured through ADB.

## 8. Unresolved uncertainties

Exact A/B phase times, final media frame/byte totals after the last periodic counter, internal hardware output routing, guidance audibility and broader reliability remain UNKNOWN. This single bounded test does not establish long-session behavior, microphone/voice, multitouch or rotary support. No follow-on implementation or live test started.

## 9. Exact diff summary

No source/APK rebuild. New local run preparation, installed-byte verification, captured device evidence and result summaries only. Candidate identity remains v5; historical reports preserved.

## 10. Preservation checks performed

Installed bytes matched the approved candidate. Capture and every retrieved evidence file hashed. Independent cleanup completed; original accessibility state restored/already matched, helper and owned processes absent. Frozen artifacts, native library, M5 readiness guard and project milestone state were not modified. No credentials read or printed during this live test.
