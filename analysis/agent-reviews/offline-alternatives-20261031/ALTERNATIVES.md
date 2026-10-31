# Alternative solutions to the right-third Spotify problem

Evidence references resolve in [EVIDENCE.md](EVIDENCE.md). This is an offline decision document; no alternative was installed or built tonight.

## Recommendation

Keep C458 as the current short-test reference for working movement, Select and Back. Stop treating the remaining failure as a global input regression. Pursue two useful outcomes separately:

1. Provide reliable track commands through the AA protocol, so playback is usable without reaching the widget buttons.
2. Determine why dashboard focus differs from the full Spotify player, using explicit input-family comparisons and the newly identified B-zone path.

The strongest practical alternative is the factory-style **media-command bridge**. The strongest new local input finding is **unmapped B-zone keys 38/39**, not another reason to retune Select or guess screen scaling.

## What the evidence now rules out or narrows

- Duplicate ENTER filtering worked: 18 suppressed, zero duplicate DOWN forwarded, same widget failure. Filtering alone is not the solution. [E1–E2]
- Main movement, Select and Back work by operator report; all corresponding native pairs complete. The main player can focus Next, while the narrow dashboard card cannot reach it. This is layout-dependent. [E1,E20]
- Controls are visibly rendered. That disfavors a simple video-cropping explanation, but does not rule out input-coordinate errors. [E20]
- The raw-coordinate domain is not always 1325 wide: 15 consecutive contact IDs use fixed x=1723; current native forwarding clamps that to 1324. Those contact groups carry B-zone raw keys, with no associated native arrow submission. Physical device identity remains unlogged. [E2–E5]
- A previous candidate already tried factory page/move mappings and failed after returning to the panel. Renaming it as a new fix would repeat evidence we already have. [E9]

## A. Send media commands directly — recommended practical route

**Mechanism:** add a controlled Next/Previous command path through native AA input. Factory GalMediaSessionCallback implements Next as key 87 and Previous as 88, each with DOWN/UP and a scheduled release. That route is independent of where the on-screen focus sits. [E6]

**Delivery choices:** first qualify the actual hardware-button route. If media keys reach the focused overlay, a narrow key path may be sufficient for an experiment. If they are dispatched through Android media routing, use an API-21 MediaSession callback adapter. The matched factory uses a media-session service too; the generic API's availability is established, but Honda's exact dispatch to an ordinary app is not. [E6,W2]

**Required contract:** register the new supported keys as well as accepting/sending them. Current six-key registration and InputEvents.key reject 87/88, so calling the session's existing onAaKey with these numbers alone would silently do nothing. Keep movement and Select code unchanged. Produce one balanced pair per command, route only during the active AA session, and release the media-session owner when AA ends. [E5]

**Prevent double actions:** choose one owner for a media command. Do not forward the same physical event from both overlay dispatch and a media-session callback. Log route, code and event identity. A general time-based debounce can discard deliberate rapid skips; prefer a single route or exact event-identity suppression. Keep call/voice buttons separate until their paths are known.

**Proof:** with focus still on the inaccessible dashboard title, one press changes exactly one track; trace the native AA command and phone result. An AVRCP/Bluetooth action is not proof of the new AA path. Use the previously agreed media-audio isolation method in a separately authorized future test, preserving call-profile requirements.

**Limit:** this solves the task of changing tracks. It does not certify that every widget, keyboard or notification is navigable. It directly advances to-do item 1 instead of holding the whole project behind one card.

An optional later user-selected right-pad media mode could use B-zone swipes as Next/Previous shortcuts. It must be explicit and scoped to active AA/media, not an unexpected global replacement for navigation.

## B. Complete the missing B-zone input path — concrete gap, qualified fix candidate

The archived HondaBZoneHoverRootLayout handles raw **38** as B-zone Bottom and **39** as B-zone Top on key release. HondaStatusBar uses these callbacks to change OEM cards/pages. That mapping was independently checked against the archived APK DEX; its parity with the current vehicle's SystemUI is UNKNOWN. Our helper's omission is direct current-source evidence: InputEvents.key returns false, overlay dispatch falls through, and no normalized AA key is sent. [E4–E5]

The latest capture includes these raw events during the fixed-x=1723 strokes: source=257, device=1, scan 36/37. This is stronger than merely seeing a generic clamp. It identifies a different input family omitted by the earlier primary-pad-only analysis. Exact physical-pad identity is still awaiting operator confirmation and device descriptor evidence. [E2–E3]

**Small candidate:** a session-scoped B-zone adapter can translate verified Top/Bottom events to AA Up/Down, preserving the main pad and existing six-key registration. That translation is our proposed adapter behavior; factory card paging does not itself prescribe AA DPAD semantics.

**Important counterexample:** main-pad AA Down already reached JNI during an earlier failing-widget burst. Translating 38 into that same key may reproduce the failure rather than cure it. This is a real completeness fix to test, not a proven end-to-end solution. [E8]

**Input identity:** 38/39 are also ordinary Android J/K keycodes. Do not permanently remap all J/K input from every keyboard. Identify the Honda input descriptor/vendor/product/source/scan behavior; do not use the transient number device=1 as a persistent identity. A controlled candidate can be explicitly scoped to this known car-input experiment, with no external keyboard, while production gating is qualified.

**Acceptance:** distinguish primary-pad and right-pad behavior; log both raw press/release phases, mapped code and actual native submission. The current raw diagnostic only prints unhandled DOWN events, so release delivery for these omitted keys still needs confirmation. Preserve working Left/Right/Select/Back and check that the OEM UI underneath does not also page.

## C. Test gesture interpretation instead of absolute pad interpretation

Our registration is navigation=true and uiAbsolute=true, matching the older factory pad configuration. Google's DHU documentation explicitly distinguishes absolute UI positioning from gesture interpretation with the corresponding input flag. A gesture-mode comparison is therefore a documented alternative, not a guessed coordinate stretch. [E7,W1]

**Single change:** compare uiAbsolute=false against the tested true baseline, holding dimensions, keys, media and video constant. New capability settings require a fresh phone session. Do not combine this with B-zone remapping or coordinate scaling. Effect on this RDX remains UNKNOWN.

This is particularly useful if proper B-zone delivery still cannot enter the media-card children. It asks whether the phone's navigation interpretation is wrong for the expanded display.

## D. Use sequential rotary navigation for nested controls

Factory code already sends relative events with rotary code **65536** and signed increments. The helper declares the native relative-event method but does not expose/use it. A controller-style experiment could traverse controls sequentially rather than repeatedly asking for a geometric Down neighbor. [E7]

Plan a complete controller profile, including supported-key/capability declaration and controlled relative-event delivery. Do not send an undeclared event and infer failure means the UI is unreachable. Keep Back/Select semantics, use one input interpretation per gesture, and reconnect for capability negotiation. This is an alternative interaction model, not proof of factory RDX behavior.

## E. Separate the two physical/input domains before changing coordinates

The 178 saturated-x samples across 15 strokes are a measurable issue. Blanket normalization is still premature: if one source already uses 0..1324 and another uses a wider/fixed coordinate, globally scaling both breaks the working source. [E3]

A diagnostic-only follow-up should record source/device descriptor, pointer identity, getX/getRawX, axis ranges, view dimensions and the actual native coordinates. Include axis 24 because Honda's B-zone root explicitly inspects it. Correlate a few deliberate gestures per pad with the same focused item. No raw screen content or microphone recording is necessary for that diagnostic.

Then choose a source-specific transform or semantic adapter. Do not hardcode x=1723 as a universal device classifier from this one trace, and do not treat a correctly drawn image as input calibration.

## F. Move comparisons to a phone-only bench before another car session

Google's desktop head unit can compare touchpad and controller behavior. Use the same phone/app versions and wide geometry to ask whether this dashboard card is reachable in another receiver. Proposed cases are in bench-cases.csv. [W1]

This does not reproduce Honda USB, OEM focus or every advertised key. A bench failure across models would point toward the phone/UI or selected interaction model; a bench pass with an equivalent model would focus attention on our contract/delivery. No DHU, phone connection or installation was started tonight.

## G. Practical workaround with no receiver change

Use the main Spotify player for track controls and return to the dashboard afterward. The last capture shows Next selected there. This is supported by actual evidence and preserves the working receiver while the panel issue is studied. It is a workaround, not completion of fullscreen input polish. [E20]

## H. Independent receiver or whole-app replacement

Open Headunit is the useful source-level/behavior comparison; HUR is a packaged receiver comparison. Neither has been runtime-qualified for this RDX, exact release/ARMv7/API 22 environment, input devices or OEM audio. An independent receiver may help distinguish our protocol implementation from phone UI behavior, but replacing the working stack also reopens already solved integration work. [W5–W6]

A wireless path addresses transport/startup, not the demonstrated widget focus failure. Open Headunit's maintainer documents differing modern wireless startup methods and legacy-trigger limitations; actual phone version and receiver compatibility must be recorded. This is not a recommendation to buy hardware, root the phone or install anything tonight. [W5]

Replacing Honda's system AA package remains a separate signing/dependency/recovery problem. The current side-by-side receiver already produces the desired display/media/input behavior in short tests; no evidence makes a system-app replacement the smallest next repair. See the older alternatives report for that feasibility analysis rather than treating it as new work authorized here.

## Proposed decision order for the lead

1. Preserve C458 and its source hashes; take no new car action tonight.
2. Confirm which pad was used and finish the B-zone trace. Do not promise its mapping alone fixes the widget.
3. Develop the direct media-command plan alongside a small input-model bench comparison. These serve usability and diagnosis separately.
4. Choose one controlled widget experiment: verified B-zone adapter, gesture flag, or isolated motion-only stream. Do not combine them.
5. Consider rotary navigation if spatial focus cannot reach nested children. Use a pointer/touchscreen mode only after its coordinate contract is established; it has larger UI/gesture consequences.

These are recommendations for review, not milestone assignments or completed implementation.
