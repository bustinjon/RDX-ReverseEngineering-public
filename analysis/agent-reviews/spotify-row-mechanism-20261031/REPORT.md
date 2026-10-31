# Spotify row versus Maps — refined mechanism and evidence limits

**The failure is now localized to a directed navigation path:** the AA app-grid selection can reach Spotify's playback row with Right; after focus moves Up to the title/upper target, Down cannot get back. The newest capture actually outlines Play/Pause, then later outlines the title on the same card. This rules against a permanently unfocusable row and makes a fixed lower-right screen dead zone a poor fit.

**Why Maps can work at the same spot:** the receiver sends touchpad/navigation input to a phone-rendered UI, not taps to a fixed Spotify button on the head unit. Maps and the media card have different focus targets and traversal rules. Equal pixel positions do not guarantee equal navigation from the currently selected item. This explains why the Maps observation is compatible with a row-specific navigation defect; **the exact responsible phone/native implementation remains UNKNOWN**.

No source, APK, app setting, device state or guard was changed in this review.

## 1. Files inspected

- Existing PROJECT-RULES.md/AGENTS.md constraints; prior paired-result and Down-probe reports.
- Down-only run `analysis/test-prep/runs/helper_20261031T162415_49f9bbe40ccd43578fa70712dff86c9d/`: session, collection/input-result JSON, capture.log, original four private images/hash manifest.
- Five recent original run registrations/capture files used in test-matrix.json (DB9B, A58A, C3ED, E931 and2865 installed hashes).
- Current InputSource.java, InputEvents, AaOverlayService coordinates/TextureView code and AaSessionService source; all27 inputs checked against2865 build.
- Archived ProjectionActivity input/lifecycle handlers, HMIPresenter/input integration and GalService foreground notification. Archived Protos.java:1967–1972 and InputSource callback interface.
- Previously extracted historical2EF2 public DEX, identity manifest, and newly decompiled historical AaSessionService live registration. No private APK assets.
- Scoped project phone-APK filename/decompiled-manifest search; latest operator media metadata. No current phone AA/Spotify implementation was located by those searches; this is not a whole-machine or exhaustive renamed-APK search.
- Official Android navigation/DHU documentation linked below.

## 2. Files changed

Only new offline analysis directory: saved source/search/probe/matrix/validation scripts, source excerpts, historical public-class decompilation, structured traces, coverage matrix, availability metadata, focus-origin clarification, this report and FOCUS-ORIGIN-TEST.md. No production code, current source selection, old evidence/report, original media or APK changed.

## 3. Commands run

[Code block omitted; consult project-authored source.]

Also targeted Get-Content/rg reads, view_image on saved probe frames, official-source browsing, and an asynchronous clarification request answered by the user. Detailed script output is saved; stdout is concise. No ADB, device inventory, new collection/build/install, source selection or app-data changes.

## 4. Tests run and results

- New saved-evidence checks PASS: all26 probe pad contacts close;16 raw146 events each belong to a closed contact with positive Y movement324–481;2 have FOCUS_CHANGE feedback within the contact. All16 occurred with no native93/20 pulse, as independently recorded in input-result.json. Thus withholding the extra Down key alone was insufficient for the reported return-path symptom.
- Matrix script verifies one unique runtime key list/pad registration per five identified fresh runs, bound to their collection hashes. The historical2EF2 live call is independently confirmed `this.inputSource.registerTouchPad(...true,true)` in its packaged-Dex-derived AaSessionService:262.
- Verified coverage does not contain page/move + no declared arrows + absolute=true. This is a gap within the identified set, not an exhaustive claim about every project build.
- Preservation checks: current27 Java inputs/current APK, original logs used by the matrix, and four private probe frames remain unchanged. See preservation.json.
- No behavioral test, new APK, phone code inspection, actual focus-tree dump or code-level cause confirmation. StaticAudit PENDING.

## 5. Findings

### A. We have a positive visual control, not only repeated negative observations

`frame_2_405787.png` visibly outlines the Play/Pause button. `frame_3_415963.png` and `frame_4_426153.png` outline the title, with the same card/item still shown. Earlier screenshots' filled Play/Pause shape alone was not sufficient evidence of focus; this new outlined state is distinct. The exact transition between samples is operator-reported, not continuously filmed in these four captures.

The user now specifies the successful origin: **the bottom-left app-grid button is selected at startup**. That is more precise than “Right works at startup.” We have not tested whether restoring that exact origin later restores the same Right route. It may be origin-dependent rather than dependent on elapsed time/startup; do not assume either is proved.

### B. The broken relation is title/upper focus -> playback row, not every object in that region

The observations are compatible with this partial graph (reported/visually supported, not a dump of AA's actual node tree):

[Code block omitted; consult project-authored source.]

In Android's documented directional navigation model, layout and per-direction links influence which element receives focus; reverse movement is not guaranteed merely because controls share coordinates. This is a general mechanism showing why the observation is plausible, **not proof that this AA renderer uses a particular Android View algorithm or nextFocusDown attribute**. [Android directional navigation](https://developer.android.com/develop/ui/views/touch-and-input/keyboard-input/navigation).

Maps is a useful counterexample to a fixed input dead region. It is not a matched test of the media card's internal navigation links. Spotify's browsing list working also cannot establish that the separate transport-control component has the same traversal behavior. Another media provider in the same card has not been compared, so “Spotify app code bug” is not established.

### C. The head-unit overlay does not own those individual UI nodes

The Java live path is a TextureView for decoded video plus native touchpad/key forwarding. It does not create Android Spotify-button views or select a target from the displayed phone app's controls. InputSource uses nativeSendTouchPadEvent; this is not the direct touchscreen-tap path. Native registration influences phone interpretation, but the head-unit's local child-focus attributes cannot simply repair a missing link between phone-rendered nodes.

Same screen position is therefore not equivalent to the same input recipient/navigation state. A receiver contract problem can still affect one phone widget more strongly than another, so this architecture alone does not prove the phone software is defective.

### D. The Down pulse theory was tested and did not fix it

The current probe records16 raw146 gestures,26 balanced pad contacts and365 MOVE records; native93/20 are absent while Up92/Right123/Left122/Select23 remain active. The Down motions are not merely tiny events: their logged Y displacements range324–481 in the720-high pad domain. Native result0 for other keys and pad logging establish local activity, not a particular phone response.

Only2 of16 Down contacts have FOCUS_CHANGE feedback in their contact interval. Callbacks lack a node ID/owner/bounds, so this does not prove14 gestures were dropped or identify where the two focus changes landed. The operator result establishes the target failure. Up's additional92 delivery and other state/profile interactions remain distinct untested causal questions; a negative Down-only probe does not eliminate every possible mixed-input interaction.

### E. A real combination remains uncovered

Read [test-matrix.md](test-matrix.md) for runtime-backed rows; all underlying log line references/hashes are in test-matrix.json. In brief:

| Navigation family | Declared arrows19–22 | Requested UI absolute | Evidence/result |
|---|---|---|---|
| DPAD | Present | true | DB9B, target failed |
| DPAD | Present | false | A58A, target failed |
| Page/move | Present | true | Historical2EF2, failed after return; older hover implementation differs |
| Page/move | Present | false | MatchedA/C3ED, target failed |
| Page/move | Absent | false | MatchedB/E931, target failed |
| Page/move; Down pulse withheld | Absent | false | Current2865, return path still failed |
| Page/move; normal Down pulse | Absent | **true** | **Not covered by verified comparisons** |

Archived Honda pad registration requests true with page/move-style navigation and no declared arrows19–22. Earlier absolute-flag and key-declaration changes were tested on different profiles. Their separate failures cannot rule out an interaction of those settings.

Google documents absolute-versus-gesture interpretation as an input configuration distinction. That supports treating this as a meaningful requested-mode difference, not proof of how this phone implemented it. [DHU input configuration](https://developer.android.com/training/cars/testing/dhu).

A later controlled configuration candidate should be based on **originalB** and change only its live absolute flag to true, with its normal Down pulse restored. Relative to current2865 source, that requires restoring the knownB dispatch and changing the registration, so it would honestly be two source edits versus current, one experimental flag versus B. It is still a navigation subset rather than complete factory parity, and a missing matrix cell is not evidence of a cure.

### F. Instrumentation currently cannot identify the actual focus owner

The helper subscribes to feedback1/2 only, and its callback receives a single event enum. Archived protocol definitions also contain drag-select3, drag-start4, drag-end5 (Protos.java:1967–1972), but the helper has not subscribed to those. Absence of drag events from current logs is not evidence that no dragging/panning occurred. Adding such observation later could help classify gestures; it is not itself a known fix and would still lack node bounds/owner.

Map content changes between probe images while the media card remains visible, but images alone cannot distinguish gesture panning from normal map initialization/location/camera updates. Do not claim Down was sent to Maps from that appearance alone. Event-synchronized video plus suitable feedback or phone-side focus data would be needed.

The inspected factory foreground callback merely notifies Android Auto state listeners in the reviewed method. No new source evidence ties an OEM input-mode setting to this particular row; the broader OEM pipeline remains outside what that narrow inspection can exclude. Local KeyEvent source metadata is not an explicit argument of the current native key/pad send calls, although it can affect upstream dispatch.

### G. What can be concluded now

1. **High confidence:** the row is reachable/focusable from at least one route; title/upper-target -> row via Down is the failing path in the reported tests. A fixed lower-right dead region or permanently disabled row does not fit all evidence.
2. **Established negative:** correct suppression of the extra Down key was not enough. Neither the advertised-arrow omission nor false absolute flag individually fixed the target in the tested configurations.
3. **Best current mechanism class:** focus-origin/history/navigation-model interaction at the compact media component. This localizes a mechanism class, not a responsible source method. Exact cause/owner remains UNKNOWN.
4. **Not established:** that Spotify's own app implementation is defective, that Google's renderer has a specific nextFocusDown bug, that native coordinates are universally correct, or that a specific factory-mode combination will cure it.

### H. Smallest next action has changed with the user's clarification

First use the **same APK** to distinguish “startup only” from “that focus origin”: after the failure, restore focus to the bottom-left grid icon without restarting AA, then move Right. This is more informative and cheaper than another immediate code change. Merely focusing the icon and activating/opening the launcher are different operations and must be recorded separately.

If that restores row access, there is a reproducible alternate focus path and no restart requirement for that recovery. If identical origin restoration fails, interaction mode/history beyond the visible node matters. This then directs a tighter Up-transition or input-contract investigation. The coherent absolute=true configuration above remains a specific later comparison; an independent same-phone receiver/controller test or actual phone focus-node evidence is needed to assign code ownership.

The scoped search found no phone AA/Spotify source/APK candidate by name/manifest. Head-unit UI dumps would describe the receiving overlay, not automatically reveal the phone's media-button focus tree. Do not pretend to have a code-level root cause from these logs. Detailed no-code plan: [FOCUS-ORIGIN-TEST.md](FOCUS-ORIGIN-TEST.md).

## 6. Primary evidence for each finding

- Positive row/title focus: current probe originals frame_2_405787.png, frame_3_415963.png, frame_4_426153.png; hash preservation.json/collection private-image-hashes.json. User focus-origin clarification saved separately in focus-origin-clarification.json.
- Raw/pad/feedback metrics: probe-gesture-trace.json, probe-analysis-output.txt and original capture SHA-256 `66EDD24E813C259B25567F8EB323CA3D74AA9CF60DD7E6C288B6F00EF5CEA5FA`; current run input-result.json confirms zero native93/20.
- Receiver architecture: InputSource.java:60–93, AaSessionService.java:189–215 and AaOverlayService.java:166–211/TextureView creation; saved coordinate excerpts. These are build-bound current source, not phone UI code.
- Combination matrix: test-matrix.json has each installed/capture hash and runtime keyset/registration line; historical-session-registration.txt cites actual historical APK-derived AaSessionService:262 and its verified DEX identity. Archived GalIntegration.java:107–126/HMIPresenter.java:722–744 remain canonical source references.
- Feedback blind spot: current InputSource.java:66–67/105–106; archived Protos.java:1967–1972 and InputSource.java:221–224. No node metadata callback exists in that inspected interface.
- Phone code availability: phone-evidence-availability.json defines the limited search; no broad claim about unsearched renamed artifacts.
- General focus/configuration mechanism: official sources linked near claims, expressly bounded rather than substituted for the missing AA implementation.

## 7. Assumptions

User's grid-origin clarification applies to the reported successful route; it does not establish retesting that origin later. Visual focus outlines represent the selected UI element; they are not an accessibility-tree measurement. Runtime registration logs prove requested arguments, not the phone's private interpretation. Identified-run matrix is deliberately not exhaustive of all project history.

## 8. Unresolved uncertainties

Recovery after returning focus to the grid icon, exact phone focus hierarchy/rectangles, routing versus direct manipulation, role of Up92/history, actual phone AA/Spotify versions, optional drag feedback, real OEM/native-mode effects and the untested settings interaction remain UNKNOWN. The precise root cause is not yet proved. Maps' successful earlier path does not answer these media-target questions. StaticAudit PENDING.

## 9. Exact diff summary

Only new read-only analysis scripts/outputs, source excerpts/public historical decompilation, matrix/clarification/validation and reports. No code, new test APK, source selection, live preparation, key/profile/geometry change, app update/data clear, guard edit or original evidence/report modification.

## 10. Preservation checks performed

preservation.json binds current27 Java inputs/current2865 APK, raw logs used by the matrix and four original private probe images to recorded hashes. Historical public DEX reused and verified without reading private assets. Existing frozen/build/collection audits reused, no presentation-driven recollection or rebuild. No key material, Git write, ADB/car/phone/USB, install, guard bypass, milestone action, spawned agent or external publication. All image content remains local/private.
