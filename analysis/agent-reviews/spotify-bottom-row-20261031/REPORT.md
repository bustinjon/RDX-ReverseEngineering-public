# Why the compact Spotify playback row is unreachable — offline analysis

**Best-supported diagnosis boundary:** this is a failure to reach a particular playback-control row, not a demonstrated global Down-key failure. The head unit forwards input to a phone-rendered AA interface; its overlay does not contain separate Android views for Spotify's three buttons. Local window-focus or Select changes are therefore not justified by this evidence. **The actual cause remains UNKNOWN.**

**New artifact-backed finding:** the earlier “factory swipe mapping” APK still advertised arrow keys19–22. The archived Honda pad profile does not. That old negative result did not isolate the complete navigation capability profile, even though it did try page/move event mappings. The phone's interpretation of that profile remains untested.

## 1. Files inspected

- PROJECT-RULES.md and existing AGENTS.md instructions.
- Latest absolute-off run: `analysis/test-prep/runs/helper_20261031T134451_d21703de95744f9b95bf7d9fe79d8b52/`: input-result.json, collection.json, capture.log, private-image-hashes.json and eleven captured image references. Inspected private image content for frames2–11; retained locally, no private text/location transcribed into findings.
- Prior media review `analysis/agent-reviews/spotify-maps-media-20261031/REPORT.md`, prior main-pad trace and canonical offline alternatives. The current user's clarification is saved in operator-clarification.json.
- Current helper's InputEvents, AaOverlayService, AaSessionService and InputSource; current candidate.json binds all27 source inputs to the installed A58A candidate.
- Archived Honda input: `decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/presentation/HMIPresenter.java:722–744`, integration/GalIntegration.java:107–126, integration/AbstractGalIntegration.java:165–168, ui/ProjectionActivity.java:579–614,2308–2325 and protocol InputSource.java:81–97.
- Historical page/move APK `build/20261030-200012-348/rdx-usb-helper-v6h-swipe-navigation-v6.apk`, its build report, public DEX and APK-derived InputEvents/InputSource classes only.
- Google Android Auto DHU/media documentation linked below. No community bug report or Android Automotive OS mechanism is used as proof of a projected Android Auto defect.

## 2. Files changed

Only new offline review artifacts in this directory: saved inspection/verification scripts, extracted historical **public** DEX/class source, source excerpts, evidence indices/summaries, profile-comparison.json, operator-clarification.json, preservation.json, this report and DECISION-TESTS.md. No production source, APK, original logs/images, existing reports or instructions changed.

## 3. Commands run

Multi-step work was saved before execution:

[Code block omitted; consult project-authored source.]

Targeted Get-Content/rg source/result reads, view_image on saved captures, web searches and primary-document reads were also performed. Detailed searches/JADX output saved here. A helper-local VideoSink path lookup returned not found; no claim relies on that nonexistent path. Existing main-pad trace, media extraction, build and device collection were not repeated. A second evidence-script pass added the newly needed full factory registration search; it did not recollect or re-decode media.

## 4. Tests run and results

- Evidence assertions PASS: archived presenter lacks literal arrows19–22; current helper and historical page/move APK contain all four; the historical **packaged** InputSource calls nativeRegisterKeyCodes(InputEvents.supportedKeyCodes()). See profile-comparison.json/profile-check.txt.
- Historical APK hash verified: `2EF2FB9AAB41446D57D942E3F155F337E08D71282A85F8E148651B2A2B36FD03`; public DEX SHA-256 `9D3640826551235F9CCC4E7AAEDFD1025E62D8EFA13155E71F2BF019B6CB1F07`. No rebuild.
- Source/current artifact preservation PASS: all27 Java inputs and A58A APK unchanged; original capture and eleven private image hashes match collection evidence. See preservation.json.
- No behavior test, new APK build, ADB, phone/car operation, DHU installation or DHU execution. Standard SDK DHU executable path is absent; no full-disk availability claim.

## 5. Findings

### A. The whole playback row is the failure unit

The user clarified: **Play/Pause is also unreachable**, not just Previous/Next. Down works while browsing Spotify's compact menu/playlists; Up from the song title reaches the top-right button; Maps in the same right-third area supports directions by operator report. The latest snapshots show a focus outline on the compact title row (frames2/5/8/9/10), and a focus outline on a Spotify browsing-list entry (frame7). The playback row is visibly present. Still images do not prove the action that caused any particular focus position.

This weakens a skip-only availability explanation. It does not conclusively rule out an entire playback-state problem, disabled controls or phone-host state. A colored/filled Play/Pause button alone is not a focus indicator; it is filled even when the title row is outlined. Do not infer focus from the button's background color.

### B. What the latest experiment actually ruled out

The absolute-off run's original registration log at capture.log:35606 says `nav=true abs=false`. Installed SHA-256 is `A58A391BBC2A855E91F472403045490816E02598C5EBA09410EE85DCB078FA73`. That run has36 balanced native Down pairs and19 Up pairs, all key returns0. The target row still failed. Therefore **changing that single flag alone was insufficient** in this test. It does not establish that phone interpretation changed exactly as intended, or that menus improved compared with an unmeasured earlier menu baseline.

The prior true-flag run already traced all33 Down pairs through the same ordering as13 Up pairs. A native return0 is a local call result; it does not attest to wire payload, phone receipt or a specific phone focus transition.

### C. The overlay has no Spotify playback-button views

AaOverlayService creates a fullscreen container/TextureView for decoded AA video. Its key dispatcher sends mapped keys to the session; it does not route to individual Spotify controls. AaSessionService sends key/pad events through the common InputSource facade. There is no per-Spotify-button view hierarchy on this head-unit surface to fix with local child focusability flags.

This is why a local overlay focus loss is a weak complete explanation for one internal row while other phone UI elements respond. It does **not** exonerate the receiver's advertised input contract, raw-motion/key combination or native delivery. Those can influence how the phone traverses its own controls.

### D. Earlier page/move testing was not full factory-profile parity

| Profile | Main swipe events | Advertised navigation keys relevant here |
|---|---|---|
| Current helper | 146->20,152->19,148->21,150->22 | `{4,19,20,21,22,23}` |
| Historical page/move APK (2EF2…) | 146->93,152->92,148->122,150->123 | `{4,19,20,21,22,23,92,93,122,123}` |
| Archived Honda presenter/integration | Same page/move handlers | Presenter includes92/93 and23/66/4 plus other system/media keys; integration adds92/93/122/123. **No arrows19–22 in that declaration.** |

The old APK's supportedKeyCodes array and the native registration call were both inspected from its actual packaged DEX. So this is a verified historical difference, not an assumption based on today's source. Full factory parity also includes additional keys and other behavior; do not claim an abbreviated navigation subset is complete parity.

**Inference:** if this phone chooses navigation/focus behavior based on advertised key capabilities, those extra arrows could matter differently in a compact media layout than in a simple list. Whether this phone does so is **UNKNOWN**; its focus code was not inspected. This is a concrete untested distinction, not a proved cure. The old candidate's failure after returning to the widget remains real evidence against “page/move mapping alone fixes it.”

### E. Sequential rotation is distinct from a directional arrow, but not established as the RDX's factory path

Google's DHU exposes separate directional, rotation and touchpad inputs; its profiles can compare these models. This supports an independent traversal comparison, not a claim that a particular AA card must require rotation. [Google DHU documentation](https://developer.android.com/training/cars/testing/dhu).

Archived ProjectionActivity contains relative-event handlers for code65536, but the RDX presenter list above does not include that rotary code. Shared class declarations alone do not prove the RDX executes a rotary route. Our helper currently declares but does not use nativeSendRelativeEvent. Neither the helper nor stock source proves that injecting an undeclared rotary event is a valid test.

Android Automotive OS documentation describes FocusAreas for its own system. That is a different platform architecture; do not use it to assert this projected phone interface's focus algorithm. [AOSP rotary documentation](https://source.android.com/docs/automotive/hmi/rotary_controller).

### F. Head-unit playback-state logs are not the actual phone-session evidence

677 saved observations group under HondaStatusBar and RAAM.StreamingCallback (states3,2,1 with actions1659,1661,1540). These are head-unit media mirrors; their ownership/timing is not established as the phone Spotify session governing the compact AA card. Do not read a local OEM error/absence or action mask as a diagnosis of Spotify's AA controls.

Google documents media controls as dependent on session actions/state and notes that STATE_NONE makes playback UI inaccessible; it recommends media-session inspection. This justifies checking the actual phone session in a future authorized comparison, not changing it now. [Playback control/state documentation](https://developer.android.com/training/cars/media/enable-playback).

### G. Responsible renderer/app remains unassigned

Google's supported media architecture lets the car host produce browsing/playback interfaces from media services/session data, with templates also supported. Seeing Spotify branding is insufficient to blame Spotify's own handset view implementation. The current app/version/template path remains UNKNOWN. [Media app architecture](https://developer.android.com/training/cars/media).

No matching current-version bug was verified from a primary report. No recommendation to clear data, update/downgrade apps, replace AA, or retune geometry is justified here.

### H. Evidence-ranked conclusions and next discriminating work

1. **High confidence, symptom/locus only:** an entire compact playback row is unreachable while other directional navigation works. Local global Down suppression and skip-only availability do not adequately explain all observations.
2. **Established open distinction:** factory versus helper capability declarations differ; earlier page/move testing retained the arrows. Its causal effect is UNKNOWN.
3. **Still unresolved:** phone AA media-card focus defect, receiver input-contract/phone interaction and playback-session availability. The existing evidence cannot defensibly assign probabilities or uniquely order these causes.
4. **Weak complete explanations:** video clipping, globally inverted Y, generic Select breakage or blanket loss of overlay focus. Controls render, menus/Maps respond and the Java key path is active. Context-dependent receiver defects remain possible.

The most informative independent check is the same phone/layout/queue in DHU with directional versus sequential traversal, then a separate touch activation check if needed. That can be prepared without another car APK guess, but the DHU is not installed at the standard SDK path and a later authorized setup/phone connection would be needed.

For a future car build specifically targeting the newly found capability distinction, use a coherent profile comparison: stable page/move mappings in both references, same Select/Back/hover handling/geometry/absolute flag, then advertised arrows present versus absent. Do not omit native key20 while still emitting20; that is not a valid isolated test. A simpler single factory-style-navigation candidate combines mapping and declaration changes and must be described as such. **No candidate was built or selected for a live session during this review.**

Detailed decision cases: [DECISION-TESTS.md](DECISION-TESTS.md). Direct media commands remain a separate workaround and do not prove the row has become navigable.

## 6. Primary evidence for each finding

| Finding | Evidence |
|---|---|
| A | operator-clarification.json; current run collection.json/input-result.json; private frames2/5/7/8/9/10, bound to saved private-image-hashes.json |
| B | Current capture:35606; current input-result.json; installed/collection hash; previous `main-pad-order-20261031/trace.json` and validation.json |
| C | AaOverlayService.java:160–211 and TextureView creation immediately after; AaSessionService.java:189–215; InputSource.java:77–93. All27 input hashes preserved |
| D | profile-comparison.json; historical-profile-excerpt.txt:18–41; historical-registration-excerpt.txt:50–54; actual historical APK/DEX identity JSON; archived HMIPresenter.java:742–744 and GalIntegration.java:107–126 |
| E | Factory input search results, archived ProjectionActivity.java:2292/2299/2355; Protos.java:3155; helper nativeSendRelativeEvent declaration; linked official DHU documentation. No rotary hardware execution evidence |
| F | media-state-summary.json and source capture line ranges; media-state-observations.json explicitly labels ownership UNKNOWN; linked media-state docs |
| G | Linked official media architecture; app versions/template choice not established from this archive |
| H | Above evidence/counterexamples and DECISION-TESTS.md; these are recommendations with conditional interpretations, not observed test outcomes |

Current raw capture SHA-256: `18E7E5F60C7F5CFA993FFADDC69DE84063273C124CBB568DDEAD2B3F75FF7FE5`. Source notes/searches retained locally: source-index-style capture-index.json, presenter-input-contract.txt, factory-registration-excerpts.txt, factory-input-registration.txt and historical inspection outputs.

## 7. Assumptions

User clarification applies to the reported compact-row symptom. Saved captures document displayed state, not exact key causality. “Factory” in this report means the archived Honda source inspected; present stock runtime parity is not assumed. Prior APK-derived classes are decompiled evidence bound to their DEX hash, not a new runtime test.

## 8. Unresolved uncertainties

Actual phone AA/Spotify versions, focus hierarchy, enabled-state of each compact control, precise action/frame synchronization, wire-level event interpretation, capability-dependent focus selection, same-queue main-player comparison, alternate media provider behavior, rotary behavior and matched DHU result remain UNKNOWN. The whole-row observation is now clear; root cause and repair are not.

## 9. Exact diff summary

New offline analysis directory only: inspection/comparison/preservation scripts and their generated local metadata, source excerpts, historical public DEX/decompilation, summaries, operator clarification and two reports. No Java/native/manifest/settings/guard change, no new build, no edits to original media, previous reports, logs or instructions. The only historical APK access extracted classes.dex; no private assets/key material read.

## 10. Preservation checks performed

preservation.json records unchanged27 current Java inputs, installed-reference candidate APK A58A…, historical inspected APK2EF2…, current capture and all11 private frames. Prior collection/build/frozen-anchor checks were reused; no frozen artifact was modified or rebuilt and no presentation-driven repeat collection occurred. No Git mutation, device operation, guard bypass, milestone action, app installation, external sharing or spawned agent. Images/searches remain local/private.
