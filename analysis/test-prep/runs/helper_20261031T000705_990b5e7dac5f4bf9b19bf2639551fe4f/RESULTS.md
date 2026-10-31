# Swipe candidate result — initial success, failure after panel return

**Not a complete fix.** Operator initially changed a song in the right Spotify panel, then left/returned and could no longer navigate down to its controls. Operator clarifies that Android Auto uses directional focus navigation rather than an absolute screen pointer. Exact UI transition timestamps are UNKNOWN.

All ten evidence files retrieved and hashed. Cleanup verified; user told they can disconnect. No new test/build/device change after retrieval.

## 1. Files inspected

Run session/artifact metadata, complete capture, watchdog/PID files and postchecks; current key mappings/overlay consumption; prior v5 failure summary; archived Framework ViewRootImpl/KeyEvent and Generic.kcm/Virtual.kcm keymaps. No phone contents, keys or credentials read.

## 2. Files changed

Local evidence inventory, postchecks, RESULTS.json and this new report only. No production source/APK, historical report, settings or Git changes.

## 3. Commands run

Authorized targeted ADB pull of the remote run directory and settings/process cleanup checks. Local hash, unique-boundary/process log aggregation, key-balance counting and read-only framework/keymap inspection. No subsequent ADB action after disconnect clearance.

## 4. Tests run and results

- Installed candidate hash matches `2EF2FB9AAB41446D57D942E3F155F337E08D71282A85F8E148651B2A2B36FD03`.
- Registration marker lists all ten intended keys.
- Native successful paired sends: Back=1; select=18; Page Up=5; Page Down=26; Move Home=13; Move End=21. All logged native results zero; no duplicate DOWN/orphan UP/held key at capture end in the logged sequence.
- **Zero native DPAD 19/20/21/22 events** in this run. Prior v5 failure run had 4/28/6/12 respective DOWN events, all paired with UP.
- No INPUT_FOCUS=false, sendTouchPad error, fatal audio playback or worker-stop marker found after this run boundary. These absences do not establish phone UI focus state or successful target activation.
- Last periodic media counter: received=1250, playedBytes=10216960, dropped=1. Not a final total or a zero-drop run.
- Independent watchdog CLEANUP_FINISHED; original empty accessibility services/enabled=0 match current settings; helper and owned capture PID 5486/watchdog PID 5600 absent.

## 5. Findings

### F1 — Extra mappings reached native code but did not provide reliable panel return

The user-reported initial track action plus later recurrence contradicts a simple claim that missing page/move registration was the sole problem. Events continued later in the capture with successful returns. No synchronized phone UI/focus trace identifies the exact successful-to-failed transition.

### F2 — Handling a raw key can remove its framework-generated directional fallback

The four OEM raw codes are Android NUMPAD_2/4/6/8 numeric values. Archived Generic and Virtual keymaps give those keys ordinary directional fallbacks. ViewRootImpl's SyntheticKeyboardHandler consults the KeyCharacterMap for an unhandled key and enqueues the fallback event.

V5 did not consume these raw keys and logged a raw OEM event followed by a regular DPAD event. V6 consumes the raw event, sends its page/move translation and returns true; its capture has page/move events and no regular DPAD events. This supports a framework fallback interaction rather than the earlier assumption that all raw and directional events were independently generated hardware events.

The active device's selected KeyCharacterMap and modifier state were not captured, so exact live fallback attribution remains an inference supported by code/keymaps and both traces. Nonetheless, the observed semantic difference is established: this experiment did **not** add page/move events while leaving the prior directional event stream unchanged.

### F3 — Host mapping checks did not model Android dispatch/fallback

The host test preserved DPAD for an explicitly supplied synthetic sequence containing both raw and DPAD events. It did not exercise ViewRootImpl's decision to synthesize the second event only after the first is unhandled. Passing those assertions therefore does not establish identical UI-navigation behavior on the head unit. This is a validation limitation discovered by the hardware test; the historical test output remains valid within its narrower scope.

### F4 — Treat this as a focus-navigation problem, with coordinates only one input

User clarification plus prior native pad registration uiNavigation=true require observing selected-focus transitions and panel entry/return. Mapping the visible control directly to a screen-coordinate target is insufficient. No coordinate scaling change or automatic focus reset is justified by this result alone.

## 6. Primary evidence

- F1: operator's latest report; capture 31826 registration marker; 34941–34989 and 35938–36028 show later Page Down DOWN/UP with result=0; RESULTS.json counts and key balances.
- F2: `decompiled/Framework/sources/android/view/KeyEvent.java:184–190` maps NUMPAD codes 146/148/150/152; `ViewRootImpl.java:2990–2992` unhandled-key path and `:3604–3620` synthetic fallback. `adb/RDX-Audit/full-system/usr/keychars/Virtual.kcm:347–385` and corresponding Generic.kcm entries show directional fallbacks. V5 actual counts are in `analysis/test-prep/runs/helper_20261030T234615_99356193e031448eb0d3fb4ebd9b5be9/RESULTS.json`; v6 actual counts in this run RESULTS.json. Current AaOverlayService.java:138–145 consumes accepted raw keys.
- F3: tools/car-test/InputPcmTest.java synthetic gestureSequence/expectedSequence assertions; no Android ViewRootImpl runtime in the host test.
- F4: operator's explicit directional-selection explanation; native pad declaration already uses navigation=true. No new synchronized phone UI evidence available.
- Capture SHA-256: `330F3AC0B9B02C56A9B8C46DFDB18F6509F921291CA6277B3E2B17A9353B1246`. Unique RDX.PREP boundary line 27993; session process 5537. device-evidence-hashes.json preserves complete inventory. session.json/postchecks.txt/watchdog.log establish cleanup baseline and outcome.

## 7. Assumptions

Operator initially activated an actual Spotify track control, as reported. Which panel exit/entry action preceded the failure, exact timestamps and remaining directional behavior after recurrence are UNKNOWN. Clarification requested separately; no dependent implementation started while waiting.

## 8. Unresolved uncertainties

Phone UI focus graph/selected target on panel return, active device keymap/modifier state, whether a compatibility combination of directional/page events is appropriate, and whether native pad movement plus discrete keys interact. Avoid blindly forwarding both event forms or deduplicating by time: either can change semantics. A future focused comparison should explicitly specify event policy and record panel entry/return, with no geometry/audio change. This report does not itself implement or start that experiment.

## 9. Exact diff summary

Save one actual candidate run and derive paired key counts, absent DPAD evidence, partial user outcome and framework fallback hypothesis. No code/APK or previous report changes. Correct the experiment's interpretation in this new report rather than rewriting historical preparation evidence.

## 10. Preservation checks performed

Installed candidate matched the selected SHA-256. Ten retrieved evidence files hashed. Cleanup compared against recorded accessibility baseline and owned process IDs. No APK rebuild, credentials read, factory app change, guard bypass, Git publication or milestone action.
