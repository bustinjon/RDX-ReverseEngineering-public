# Offline alternatives and remaining-work review — 2026-10-31

**Recommended alternative:** add factory-style AA media Next/Previous commands so track control does not depend on reaching the dashboard widget buttons. In parallel, investigate the omitted B-zone input family and compare input interpretations before another broad remapping attempt. No production code, APK or device was changed tonight.

Read [ALTERNATIVES.md](ALTERNATIVES.md) for solution comparisons and [TODO-PLAN.md](TODO-PLAN.md) for plans covering all ten original categories. [EVIDENCE.md](EVIDENCE.md) links primary sources; evidence IDs below resolve there. This is proposed work for user/lead review, not milestone progression.

## 1. Files inspected

PROJECT-RULES.md and AGENTS.md; current 27-source C458 build/provenance; the v5 → page/move → directional-only → observer → hover-restoration → contact-filter test sequence; latest complete capture/collection records; current input, audio, sensor, USB and overlay implementations; manifest/entry points; matched factory AA input/media/mic implementations; archived SystemUI B-zone DEX; detector research and its evidence pointers; TLX PDF review/artifact comparison; older handoff/alternatives; local Git status and preservation manifests.

This is a review of the relevant implementation and research history, not a claim that every file in the archive was individually re-audited. The TLX's underlying research bundle and current vehicle SystemUI bytes were not newly acquired. Private credential material was not inspected.

## 2. Files changed

Only new analysis artifacts in this folder: REPORT.md, ALTERNATIVES.md, TODO-PLAN.md, EVIDENCE.md, bench-cases.csv, coordinate-study.json/CSV, source/preservation snapshot, local Git metadata and archived B-zone inspection output. Supporting scripts: Review-Evidence.ps1, Coordinate-Study.js, Inspect-BZoneArchive.ps1 and Verify-Review.ps1.

No production source, existing APK, manifest, runner/guard, historical report or milestone state was changed. No app installation, ADB/device use, commit/push or publication occurred for this review.

## 3. Commands run

Targeted rg/Get-Content source/evidence reads; Review-Evidence.ps1 for source/artifact hashes and local Git metadata; Coordinate-Study.js for recorded input-family analysis; Inspect-BZoneArchive.ps1/JADX on selected archived SystemUI DEX; official documentation/upstream project research; Verify-Review.ps1 for final preservation. Detailed diagnostics are saved in this folder rather than pasted into chat.

## 4. Tests run and results

- C458 remains the tested APK: `C458B51DA03A9B96776E233A220B03C04254C13F4AC7E2BB790325590DDA14FD`. All 27 current Java inputs match its build provenance. [E1,E18]
- Latest live evidence remains: movement/Select/Back pass, right-third Spotify lower controls fail; 18 duplicate ENTERs suppressed, no duplicate pad DOWN forwarded. This review did not rerun the car test. [E1–E2]
- Coordinate analysis reproduces 149 contact IDs, 15 consecutive fixed-x=1723 strokes and 178 raw samples above 1324. Those strokes have raw 38/39 events but no associated native directional key. Native source clamps x to 1324. [E2–E5]
- Archived SystemUI APK was independently decompiled for the B-zone class and confirms its 38/39 mapping. Current vehicle SystemUI binary parity is UNKNOWN; do not silently promote archived behavior into a current-binary assertion. [E4]
- Current microphone behavior was checked against matched factory code: factory session numbering begins at zero, contradicting the assumption that returning zero necessarily rejects a microphone request. Current helper still captures/sends no microphone PCM. [E10]
- Eight preserved APK/frozen-artifact hashes match the pre-review baseline; current tested APK, manifest and sources remain unchanged. Final results are in after.json.
- No new hardware, phone, audio-capture or protocol runtime test was performed; no production compilation/rebuild was needed.

## 5. Findings

### F1. Keep a useful baseline and split “usable playback” from “complete widget traversal”

The user now explicitly confirms working movement, Select and Back. The full Spotify player can select Next; the one-third widget cannot reach its lower controls. Duplicate-contact filtering fixed the recorded sequence anomaly but not that layout-specific defect. Preserve C458 as a short-test reference, not a completed production receiver. [E1,E20]

The practical alternative is source-backed: factory GalMediaSessionCallback sends Next/Previous as native AA keys 87/88. Implementing that command route would solve track operation independently of the selected widget and directly advances the steering-wheel/media-controls task. Current acceptance/registration filters exclude these keys, so a complete adapter must update both, then establish one dispatch owner. [E5–E6]

### F2. The missing input family is more specific than “Down does not work”

The failing capture contains raw keys 38/39 in a contiguous fixed-x=1723 motion family. Current InputEvents accepts the main-pad NUMPAD codes but excludes 38/39. The first confirmed local key-path divergence is therefore **mapping/acceptance in InputEvents/overlay dispatch, before JNI**, for this family. It is not another observed loss of the existing AA Down key. [E2–E5]

Archived SystemUI identifies these as B-zone Top/Bottom gestures. That is corroborating source evidence, with current binary parity still unqualified. Actual physical-pad identity was requested from the operator; no answer is assumed. Raw diagnostic logging currently proves DOWN receipt for omitted codes, not their complete release sequence.

A scoped B-zone adapter is a reasonable candidate, but it is not a proven fix. Earlier main-pad Down already reached JNI during an inaccessible-widget burst. Mapping another gesture to the same AA Down could merely repeat the failure. This counterexample is why direct media commands and alternative input interpretations remain important. [E8]

### F3. Coordinate and interaction-model assumptions need explicit treatment

Raw x=1723 becomes native x=1324 under the current clamp. The assumption that all incoming pad events already inhabit the declared 1325-wide domain is false for this recording. The 15-stroke group has a stable x, making it structurally different from ordinary two-axis motion; do not blindly apply a global scale to both families. Source/device/motion-range metadata is needed to decide whether a source-specific transform or a semantic adapter is appropriate. [E3,E5]

Gesture interpretation, motion-only delivery and sequential rotary navigation are distinct alternatives. The factory provides a relative-event path and code 65536; our helper declares but does not use that native method. Google's [DHU documentation](https://developer.android.com/training/cars/testing/dhu) supports a bench comparison of the input concepts. These are proposed comparisons, not demonstrated RDX fixes. [E7,W1]

### F4. The voice plan needs an actual capture and session contract

The mic stub advertises capability, logs “denied” and returns zero without recording. Factory MicrophoneRecorder starts session IDs at zero. Therefore the log text is not proof of protocol rejection. Correct open/reject/session/ACK semantics must be established, rather than merely adding a voice-button key and expecting Gemini to hear. [E10]

The manifest lacks RECORD_AUDIO, and factory cabin input uses Honda mic ownership/processing APIs. Permission, actual source routing, capture, credit/ACK handling, voice lifecycle, response audio and release are separate work packages. Availability of those Honda APIs to this app is UNKNOWN. Gemini selection remains on the phone; no separate head-unit cloud-assistant client is proposed. [E10–E11,W3–W4]

### F5. Reconnect is a more concrete production gap than another transport race theory

Cooperative phone configuration is now persisted and loaded before side effects; older handoff claims about an unfinished mode are superseded by current source. But helper polling ends at GRANTED/FAILED, detach only logs, and session shutdown has no evident helper-phase reset. Repeated fresh starts under a process-killing watchdog do not prove natural replug recovery. [E12]

Plan a single connection owner with generation-checked callbacks and an explicit session-end return to waiting/recovery. Transport abort already posts shutdown to the handler; an unsupported self-join claim was checked and not retained.

### F6. Startup/OEM/security work is not completed by a fullscreen overlay

The launcher/USB attach entries already exist. They do not establish a Honda Home tile, clean HOME/resume or camera preemption. The boot service masks a warning with a timed high-level overlay; it does not prevent detection. No normal-app narrow detector exemption has been verified. [E15–E17]

Use separate visibility/session ownership, retain the detector issue as unresolved if no supported exemption exists, and plan truthful vehicle capabilities. Current static parked/day/zero-speed sensor values are not live car data. [E14]

### F7. Use the to-do list as concrete work packets, not one giant replacement

TODO-PLAN.md defines deliverables, dependencies, offline validation and future acceptance for all ten items. The near-term useful alternatives reuse the current receiver: media-command control, B-zone/source-domain handling, and input-model comparison. Whole-app/HUR/Open Headunit or wireless replacement remains a qualified comparison route with its own API/ABI/OEM integration unknowns, not a necessary restart of this project. [W5–W6]

Current private source has uncommitted/untracked changes; the separate public snapshot is clean locally. Server visibility and completeness of the current source baseline are not inferred from that. Preserve a reviewed baseline and keep private receiver prerequisites separate from the public diagnostic track. [E18]

## 6. Primary evidence for each finding

EVIDENCE.md maps E1–E20 to exact files, line locations and hashes. Particularly important checks:

- B-zone omission: InputEvents.java:5-25; latest capture raw 38/39 scan 36/37, source 257, device 1; full details in coordinate-study.json. Archived B-zone dispatch at HondaBZoneHoverRootLayout.java:157-166, independently checked in systemui-archive/verification.json.
- Direct media alternative: matched factory GalMediaSessionCallback.java:139-203. This is a factory implementation path, not a guessed external API.
- Zero return counterexample: factory MicrophoneRecorder.java:24 and :311-313 versus current AudioSource.java callback; no RECORD_AUDIO in current manifest.
- Reconnect gap: helper detach receiver :68-85 and poll stop :207-213; session shutdown :589-638. Current policy persistence :107-151 is explicitly credited.
- Latest capture hash `1C30CD45060A522FDB06A2F1950A0A48EC1744D98F2A0BF64562B9096628D1F2`; test APK C458 hash above; original private setup photo and image hashes remain in the existing run evidence.
- External sources are official API/help documentation or upstream projects, linked in EVIDENCE.md. Claims of compatibility remain qualified and no community troubleshooting answer is treated as proof.

## 7. Assumptions

The end goal remains a usable full-width AA receiver integrated with the RDX controls/OEM behavior. The original ten-item list defines the requested planning scope. Operator reports establish observed control success; they do not establish every physical input source, future lifecycle behavior or phone-side focus internals. The unanswered pad-identity question is not filled in by assumption.

## 8. Unresolved uncertainties

Exact dashboard focus root cause; which physical pad produced each recorded input family; current SystemUI binary parity; raw release behavior for omitted B-zone keys; effectiveness of gesture/controller profiles; ordinary-app OEM mic permissions; genuine Home/camera interruption policy; narrow detector exemption; reconnect/ignition and long-session behavior; remote Git visibility. No car step is requested tonight.

## 9. Exact diff summary

Review/planning/evidence files only under this folder. No receiver, manifest, APK, runtime settings, public repository, guard or historical report edits.

## 10. Preservation checks performed

before.json pins all 27 Java inputs, manifest, tested APK and eight prior/frozen artifacts. after.json verifies them unchanged. Archived SystemUI input is separately hashed, with no live acquisition or modification. No ADB/USB/phone/car access, signing-material inspection, build, installation, Git mutation, publication or milestone advancement occurred during this task.
