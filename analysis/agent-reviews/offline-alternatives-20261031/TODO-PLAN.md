# Implementation plans for the remaining RDX work

Plans only. Your ten original categories are retained; no milestone or live step is advanced. C458 is the current tested reference. Evidence IDs resolve in [EVIDENCE.md](EVIDENCE.md); input alternatives are evaluated in [ALTERNATIVES.md](ALTERNATIVES.md).

## Status and dependency map

| Original item | Current evidence | Proposed first deliverable | Depends on |
|---|---|---|---|
| 1. Steering-wheel controls | Back works in the latest test; media/voice/call button routing not qualified | One-owner AA Next/Previous command adapter | Confirm hardware event route and supported-key declaration |
| 2. Microphone / Gemini | Mic service is advertised but captures/sends no PCM; voice callback only logs | Correct mic/session/ACK contract and source-ownership design | Recording permission, accessible mic source, voice-session events |
| 3. Honda Home / OEM integration | Working overlay, no proven Home/resume/camera policy | Visibility state separate from USB/protocol session | OEM event/overlay priority investigation |
| 4. Connection / lifecycle | Short guarded starts work; natural reconnect is unqualified | Explicit session-end → helper recovery ownership | Stable lifecycle callbacks and generation IDs |
| 5. Unauthorized-app popup | History persists; boot cover is masking, not prevention | Supported-exemption feasibility decision | Verified detector behavior and available privilege |
| 6. Fullscreen / input | Movement/Select/Back pass; dashboard card remains inaccessible | B-zone/source-domain audit and one input-model comparison | Input descriptor evidence and isolated candidates |
| 7. Audio polish | Real receiver media playback works in short tests | Focus/duck/resume/call interruption matrix | Session visibility and voice/call ownership |
| 8. Vehicle data | Many sensors advertised with static initial values | Minimal truthful capability plan | Actual accessible signal feeds, or explicit omission |
| 9. Productionize | Research APK/services/timers remain | Reproducible app/lifecycle/installation design | Core input, audio, lifecycle and interruption acceptance |
| 10. Infrastructure | Evidence/build hashes exist; current source not fully committed | Reviewed source baseline and reusable run lifecycle tools | File classification, user-approved commit/publication scope |

Suggested emphasis for lead review: obtain a useful media-command path, isolate the remaining input model, and design lifecycle/voice ownership. Do not require optional GPS/HVAC work before those basics, and do not mistake the present three-minute tests for production qualification.

## 1. Steering-wheel controls

**Media commands first.** The factory MediaSession callback translates Next/Previous into native AA keys 87/88 with balanced press/release; this bypasses dashboard focus. Current InputEvents and key registration omit them. [E5–E7]

Implementation outline:

- Qualify whether physical media commands arrive as window KeyEvents, media-session callbacks or Honda-specific events. Do not assume steering-wheel events all reach the focused view.
- Add an AA media-command adapter with an explicit active-session owner. Update acceptance and native registration together. Preserve the existing directional/Select/Back paths.
- Choose one dispatch owner. A MediaSession callback and an overlay callback must not both emit the same command. Use event identity/state, not broad timing suppression, for duplicates that actually occur.
- Keep callbacks inactive outside AA and release session/focus ownership on stop. Do not fabricate permanent PLAYING state simply to steal media buttons from Honda.

**Voice button:** factory ProjectionActivity:1170-1183 uses key 84 and a separate long-key path; cancellation at :2495-2505 also sends 84. The current helper exposes neither a working voice lifecycle nor acceptance of 84. Trace short/long press ownership before implementing so one hold does not start and immediately cancel the assistant. Existing JNI declarations include the long-key method, but that is not runtime proof of the hardware route.

**Back/Home:** retain the now-working Back behavior. HOME is a visibility/OEM integration question, not a reason to remap Back. Call buttons should remain with the verified hands-free owner until their actual routing is known.

Offline acceptance: balanced pairs, exactly one command for each accepted physical action, no post-stop/stale-generation sends, short/long press distinctions and no changes to existing keys. Future live acceptance: one press → one AA track change with widget title focused; no simultaneous Honda/Bluetooth action; normal Back remains correct.

## 2. Microphone / Gemini integration

**Important correction:** our stub logs “denied” and returns zero, but factory MicrophoneRecorder starts its session IDs at zero and returns an incremented ID. Therefore zero is not established as a rejection code. The proven fact is that our stub records and sends no microphone audio. A capability that appears open but produces no frames could leave the phone waiting; that behavior must be resolved from the JNI/protocol contract. [E10]

The current manifest lacks RECORD_AUDIO. Standard AudioRecord capture requires it. The factory uses 16 kHz PCM16 mono: Android constants 16 and 2 mean CHANNEL_IN_MONO and ENCODING_PCM_16BIT, not sixteen channels or two-bit audio. [E10,W4]

Proposed work packages:

1. Specify the open/close return semantics, session IDs, maxUnacked credit, ACK session identity, timestamp expectations and rejection path. Factory sends microphone data with timestamp 0L; do not automatically copy the input-event clock convention into this ABI.
2. Design IDLE → PREPARING → READY → STREAMING → STOPPING transitions. Bound queues/credits and waits, reject stale ACKs, stop on disconnect/focus loss and release recording resources deterministically. No ambient/background recording or raw mic logging by default.
3. Qualify a microphone source before claiming cabin-mic integration. Factory GalAudioManager requests SERVER_VOICE_REC and manages processing through Honda's mic manager. Whether an ordinary research app has the required access is UNKNOWN. Do not assume normal RECORD_AUDIO grants that OEM route. [E11]
4. Tie voice start/end/cancel to capture and audio-focus ownership. The current GalReceiver notification only logs; it does not perform factory preparation/restoration. Preserve incoming-call/HFP ownership.
5. Validate source selection, intelligible PCM, phone recognition, assistant response audio, ducking and recovery independently.

Gemini/Assistant selection belongs to the phone's AA environment, not a new cloud API client in the head unit. Google's help documents voice, microphone icon and steering-wheel initiation; provider availability must be checked for the actual phone. [W3] If cabin access is blocked, evaluate a clearly identified phone-mic fallback before buying hardware or modifying the OEM audio stack; fallback compatibility remains UNKNOWN.

Offline acceptance: open/close/reopen, ACK starvation/late ACKs, cancellation during capture and teardown leave no recording worker or stale session. Future acceptance: the intended mic is actually heard, one command is recognized, response plays once, music ducks once and resumes, and recording stops when the session ends. Calls are a later, separate routing check.

## 3. Honda Home / OEM integration

The manifest already has a launcher activity and USB attach entry. That does not prove Honda Home exposes a custom tile. A standard activity/shortcut is the first interface to qualify; native tile/icon customization is optional if the launcher supports it. [E15]

Introduce a visibility owner independent of protocol lifetime: AA_VISIBLE, OEM_VISIBLE, INTERRUPTED and RESUMING. HOME should release AA's video/input surface to Honda; resuming should reuse an appropriate active session instead of unnecessarily renegotiating USB. Define whether music continues when Home is shown, subject to OEM focus/interruption requests.

The present SYSTEM_ERROR overlay achieved display coverage but has no proven reverse-camera/system-overlay policy. The boot cover is also a high-level overlay. Determine actual current RDX priorities and supported preemption events before treating these windows as a final UI architecture. TLX shared libraries do not establish identical input or camera priority. [E15,E17]

Deliverables: entry/exit intent contract, visibility/session separation, interrupt ownership table and restore rules. Future acceptance: HOME reliably reveals Honda; AA returns without duplicated owners; reverse camera and system interruptions take over promptly and release cleanly. Do not perform these car checks tonight or bypass Home/lock-task readiness to simplify them.

## 4. Connection and lifecycle robustness

The cooperative phone policy is now persisted and loaded before startup side effects, including sticky/null-intent restart. That supersedes the older handoff's claim that the mode was only a sketch. [E12]

There is still a concrete lifecycle gap to address: the helper stops polling at GRANTED/FAILED, its detach receiver only logs, and session shutdown resets the session service without an evident helper-phase reset. A normal replug or failed session can therefore leave the helper believing a session is already granted. The repeated test watchdog kills the process, so successful fresh test starts do not prove natural reconnect.

Design one owner for a connection generation. Session-end/detach/permission-denial should report to that owner and return it to an appropriate waiting/recovery state. Reject callbacks belonging to the previous USB device/session; bound backoff and prevent simultaneous native sessions. Preserve the existing credential/permission policy and do not silently fall back to global Honda force-stop when user configuration is absent.

A counterexample was checked: transport abort already posts shutdown to the handler. Do not claim the current source necessarily self-joins the reader worker, or rewrite it based on that unconfirmed suspicion. Native objects retained after worker-stop failure still need explicit recovery/measurement. [E12]

Offline tests: attach/permission/re-enumeration/detach, denial, stale callback, session error, rapid replug, sticky restart and configuration loss. Future acceptance: repeat plug/unplug, phone reboot, ignition cycle and receiver failure recover without laptop timing or stale owners. Keep the lab watchdog separate from eventual user-operated lifecycle behavior.

## 5. Honda unauthorized-app popup

No verified supported per-package exemption has been found in the existing detector analysis. Its historical bit can persist after uninstall, and clearing history alone would not make an installed ordinary app pass a subsequent current-package scan. An unused “approved key” field is not an active allowlist. [E16]

The present boot service covers the warning for eight seconds after an eight-second delay. It does not prevent detection or clear history. Treat that as research UI masking, not completion of this item. [E15]

Plan: keep the detector behavior and observed app flags documented; determine whether a supported OEM configuration/installation category can exempt only our app. If none is accessible with existing privileges, report this item unresolved rather than globally disabling the detector, claiming an unsupported whitelist, or replacing system software. Remove research-only warning-cover behavior from the final startup design after the user/lead chooses an explicit supported warning policy.

Acceptance: any proposed narrow exemption must survive boot/update while still allowing the detector to report an unrelated ordinary unauthorized app. No detector patch, data clearing or global suppression is authorized or performed by this plan.

## 6. Fullscreen and input polish

Preserve the current movement/Select/Back result and contact normalization. The remaining dashboard issue is evaluated in ALTERNATIVES.md; do not revert to global input rewrites. [E1]

New B-zone work: raw 38/39 appear in fixed-x=1723 strokes and are ignored by the helper. Archived B-zone code assigns their card/page role; current SystemUI binary parity is UNKNOWN. Add source-aware diagnostics and, if selected, a scoped adapter. Do not identify a device permanently by ID 1 or globally consume J/K from external keyboards. [E2–E5]

Input-model options should each get their own comparison: B-zone semantic adapter, gesture interpretation, motion-only delivery, or sequential controller navigation. Supported capabilities and actual sends must agree. A pointer/touchscreen model is a larger fallback requiring a defined active/encoded/display coordinate transform and a new click contract; it must not emit both a touch click and key-23 click.

Coverage after the panel case: hold/repeat, cancellation, edge navigation, main/narrow input domains, app keyboard, notifications, map panning and no input leakage to Honda underneath. Log numeric source/device/coordinate metadata; do not rely on private screen content as the input classifier.

Future acceptance: lower right-panel controls reachable before/after app return, exactly one click/action, all directions and Back preserved, no underlying OEM activation. Repeated native result 0 without the requested UI action remains insufficient.

## 7. Audio integration polish

Keep the proven media output. Current media/guidance protocol types are separate, but both AudioTracks use Android STREAM_MUSIC. Guidance requests transient-may-duck focus; media has its own focus observer and duck volume behavior. That is working implementation to validate, not an audio stub to replace wholesale. [E13]

Plan a matrix for music + guidance, guidance completion, assistant response, calls, OEM source change, volume, AA hide/resume and unplug. Measure received/played/dropped frames, queue occupancy, focus transitions, worker lifetime and final audio release. Check that ducking happens once and restores fully; multiple focus owners can otherwise obscure the cause of silence or over-attenuation.

Calls may use a different Honda/Bluetooth hands-free route; media playback through AA does not prove call-mic routing. Preserve a known route until a separately observed call test proves a replacement. Do not change all stream types, focus and mic ownership in one candidate.

Acceptance: navigation and assistant remain intelligible, music resumes, volume behaves predictably, no stale audio after exit, and sustained sessions show bounded queues/memory. Audible sound alone is not proof of a particular transport route.

## 8. Vehicle data / optional integrations

Current SensorSource advertises fifteen types and reports parked/day/zero speed, including parking brake=true and gear=PARK. These are bench defaults, not measured vehicle state. Keep that distinction explicit; do not promote them to production telemetry. [E14]

Start with a minimal truthful capability inventory. Implement only verified accessible values; otherwise determine the protocol-supported unavailable/unknown or omission behavior. Day/night is useful and can have an explicit user choice while OEM light-state access is qualified. Phone GPS is already present in projection; head-unit GPS/IMU/RPM/HVAC should be justified by actual benefit.

For gear/parking/driving state, trace real feeds and permission/access boundaries before advertising production truth. No simulated parked status should be used to claim vehicle-state completion. No CAN/property writes or driving tests are part of this offline review.

Offline acceptance: unavailable/stale/out-of-order values, correct units/scales and no fixture defaults in a production profile. Future acceptance: compare received values against observable vehicle state while parked before any broader use.

## 9. Productionize

Separate development diagnostics, user receiver and deployment procedure. Keep the lab guard/watchdog intact; do not turn a guard bypass into “production mode.” A future user-operated receiver should have explicit setup/start/stop, persisted cooperative policy and failure messages rather than requiring a laptop to arm each connection.

Consolidate entry points after lifecycle ownership is designed: the current launcher still contains older diagnostic paths, services are broadly exported for testing, and boot starts the warning-cover service rather than proving receiver autostart. Restrict production service exposure, keep captures opt-in and avoid continuous verbose input/private-screen logging.

Plan build identity visible in logs/UI: current versionCode remains 1 and the USB banner still says v5 across differently labeled candidates. Preserve cryptographic APK/source provenance, but stop relying on those ambiguous labels. Pin build tools, native bytes, manifest/resources, public signer identity and source inputs; never publish signing/protocol prerequisites with the diagnostic artifact.

Acceptance is staged by evidence: repeated starts/exits, recovery, bounded memory/threads/queues, then long-session and interruption testing. Multi-hour driving behavior remains untested; the short laboratory pass cannot substitute for it. User/lead decides when to authorize each stage.

## 10. Project infrastructure and workflow

The private working directory has HEAD a313153f4dcfa162ba878915f15a2fa24b2b2264 plus modified/untracked research work. The separate public snapshot reports clean locally. Neither fact establishes server-side visibility or that current C458 source has been committed. [E18]

Proposed deliverables:

- A user-reviewed source baseline for the 27 actual build inputs, resources/manifest, tools and public/native hashes; classify private material before any commit. Do not use broad staging. No commit/push occurred tonight.
- Keep public diagnostic and private receiver tracks distinct. Share sanitized reports/source/test instructions and licensed prerequisites appropriately; do not ship private protocol/signing assets by copying the full build folder.
- One reusable prepare/collect/cleanup workflow with a run ID, source/APK checks, saved outputs and concise READY/TEST NOW/SAFE TO DISCONNECT cues. Keep transient paths out of reusable code where feasible.
- Make every refused attempt close its owned lifecycle. A sleeping old watchdog must not terminate a later attempt. Check process identity and successful cleanup state; a cancel marker written before cleanup succeeds is not enough to prove cleanup completed. Current late-timer issue was handled explicitly, not solved generically. [E19]
- Parse/check multi-step PowerShell files before device execution. The earlier inline-variable/parser mistakes were local tooling failures, not car-protocol failures. Keep diagnostics in files as requested.
- Claude/Codex handoff should record exact task/file scope, current source/APK hash, known passes/failures and one-writer ownership. Old handoff notes remain dated; link this review rather than copying the research archive into AGENTS.md.

Acceptance: another session can identify/rebuild the intended source without private evidence leaks; wrong/stale APKs refuse readiness; cleanup cannot hit another run; device work stops at the agreed result; no unattended milestone progression.

## Tonight's boundary

This package contains review, source-backed alternatives, evidence analysis and proposed work. No app code was changed, no APK built, no device contacted, no root/system replacement attempted and no new live step authorized or started.
