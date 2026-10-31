# A/B result review — path-dependent access to Spotify's playback row

**A and B both failed direct Down.** Removing the advertised arrow keys alone did not repair that criterion. The user's clarification establishes a more useful symptom: the bottom row can sometimes be entered and traversed, but moving Up can leave it with no working Down return path. This is not evidence that the buttons are permanently disabled.

**New timing evidence:** phone focus-feedback callbacks occur during several pad contacts **before the synthetic swipe-key diagnostic/dispatch**, not merely before a post-native result log. Input can therefore affect focus before that gesture's extra key pulse. Whether the extra key moves focus a second time or prevents entry to this row remains **UNKNOWN**. The smallest proposed next probe is Down-only key suppression while retaining pad motion, described in NEXT-PROBE.md; no implementation was changed here.

## 1. Files inspected

- PROJECT-RULES.md and existing AGENTS.md constraints.
- A run `analysis/test-prep/runs/helper_20261031T143425_89ea543e3cf14689aa757824d265ec16/` and B run `analysis/test-prep/runs/helper_20261031T144308_52b40ebcec4249d6975326904e645149/`: session/collection JSON, original capture.log, collected installed APK hash, private image hashes and captured frames.
- A private frames2–8 and B private frames1–4 visually inspected. A frame1 metadata/hash preserved but its blank/startup content was not needed. Private text/location/media titles are not transcribed into findings.
- Current page-profile build/scope/candidate reports and selected B source hashes.
- Current key/hover routing in InputEvents, AaOverlayService:166–211, AaSessionService:189–215, and InputSource:77–106 for interpreting when logs occur.
- Existing factory/negative-result evidence remains canonical in spotify-bottom-row-20261031 and main-pad-order-20261031; no original evidence recollected.

## 2. Files changed

Only this new analysis directory: saved comparison/order/audit/validation scripts, derived traces/summaries, operator clarification, this report and NEXT-PROBE.md. No production source, APK, source-profile selection, original log/image, existing report, guard or instruction change.

## 3. Commands run

[Code block omitted; consult project-authored source.]

These execute saved Node analysis/audit scripts and save verbose output locally. Targeted Get-Content result/rule reads and view_image on original saved frames were also used. One asynchronous clarification question was answered by the user; its answer is preserved in operator-clarification.json.

No ADB, app launch/install, car/phone connection, rebuild, new source selection or repeated collection. The timing audit was added because native KEY is a result log written after its call; pre-raw/pre-dispatch markers are needed for a sound ordering claim. Derived ordering evidence was corrected accordingly, rather than treating a result-log timestamp as a call-start timestamp.

## 4. Tests run and results

New evidence checks PASS, recorded in validation.json:

- Each runtime supported-key list matches its intended A/B declaration; both log nav=true abs=false and B-zone enabled=false.
- Installed post-test APK hashes match the pinned A/B builds; original capture and all12 private-frame hashes preserved.
- Each actual raw directional family count equals its native mapped pair count; no orphan releases or unreleased native keys; all key returns0; no direct raw DPAD19–22 inputs in either controlled log.
- Pre-send audit finds exactly one mapped diagnostic between each corresponding raw swipe-key diagnostic and native DOWN result. It checks focus callbacks preceding raw diagnostics independently of post-native result logging.
- All27 current B Java build inputs unchanged. No behavioral test executed by the analysis scripts.

| Measurement | A | B |
|---|---:|---:|
| Down raw146 -> native93 balanced pairs | 31 | 24 |
| Up raw152 -> native92 balanced pairs | 13 | 13 |
| Right raw150 -> native123 balanced pairs | 12 | 9 |
| Left raw148 -> native122 balanced pairs | 13 | 5 |
| Select23 pairs | 10 | 6 |
| Hardware Back4 pairs | 2 | 0 |
| Right contacts with FOCUS_CHANGE before raw150 dispatch | 11/12 | 7/9 |
| Down contacts with FOCUS_CHANGE before raw146 dispatch | 16/31 | 9/24 |
| Down contacts with feedback both before raw146 and within300ms after key release result | 4 | 1 |
| Additional raw38/39 events | 9 | 0 |
| Saved frames | 8 | 4 |
| First-to-last recorded input span (wall-clock, not full session duration) | 66.093s | 32.499s |

These callback counts are not success rates: callbacks lack node identity and action correlation, tests visited different UI states, and sampling was sparse. Cross-run wall-clock alignment is not established. Native return0 does not prove phone receipt or a focused-node result.

## 5. Findings

### A. Runtime comparison is valid as an artifact check, not a proof of a behavioral improvement

Both correct APKs were installed and their actual native declarations match the planned profiles. They emitted the same page/move code family for actual main-pad swipes. B omitted the advertised arrows as intended; no direct raw19–22 appeared to confound their different acceptance filters. Nevertheless, both failed direct-Down access by operator report. The omission alone is therefore not the demonstrated fix.

A and B did not visit an identical focus/action sequence. A additionally includes9 raw B-zone-family events and9 contacts extending beyond x1324; B includes neither. Although B-zone key mapping stayed disabled, that additional hover/input family cannot be treated as identical physical stimulus. B's observed input span and frame coverage are also shorter. Do not ascribe intermittent Right access solely to the omitted arrow declaration.

### B. Row access depends on path/history

The user clarified: startup Right can enter the row; after moving Up, Down cannot return. A playlist-menu return followed by a large Down swipe may have entered the row, after which movement within it worked. The latter route remains tentative/unreproduced. Actual Select activation of a particular playback button was not explicitly confirmed. See operator-clarification.json, which supplements rather than overwrites original collection notes.

This weakens “the whole row is always disabled” and supports investigating traversal/focus history and gesture interpretation. It does not identify whether the relevant logic is in AA's phone UI, the input contract, delivered gesture/key sequence, or their interaction.

### C. Physical Right here is MoveEnd123, not native DPAD_RIGHT22

Both A and B map physical raw150 to123. The reported Right route cannot be explained as a tested DPAD_RIGHT behavior. The continuous pad stream is also present. Without action-synchronized video or node-aware feedback, neither the release-time MoveEnd nor the pad stream can be assigned sole credit for the reported row entry.

### D. A focus response can precede this gesture's synthetic key

The definitive ordering boundary is the overlay's INPUT_RAW_KEY diagnostic, which occurs before dispatch. The sequence in source is RAW -> INPUT_KEY -> onAaKey -> nativeSendKeyEvent -> KEY result log. A focus callback before RAW cannot be caused by that same not-yet-dispatched synthetic key. It may still be a delayed response to prior input or reflect pad motion; no node identity is recorded.

For B,7/9 Right contacts and9/24 Down contacts have such pre-raw focus feedback. B contact6 includes focus callbacks during pad motion before raw146, followed by the native93 pair and later feedback after release. Exact raw/mapped/result/contact/feedback line references are in pre-send-audit.json. Source capture range54027–54058 covers that Down example; the Right contact10 example is around54120–54135. These are temporal associations, not proof that focus moved down then was undone.

This supports isolating the additional Down key delivery as a useful probe. It does not justify declaring that two streams are inherently wrong: archived Honda code also forwards both, and other contexts currently work.

### E. Sparse images cannot reconstruct the successful row-entry path

All three non-startup B images (frames2/3/4) show an outline around the compact title row, not an unambiguous bottom-control outline. That does not contradict a transient successful route between samples. It means the successful entry/path cannot be reconstructed from these four images. A's sampled images show title/top-right focus or other UI contexts, without a matched recorded Right-to-row sequence.

Captures include a filled Play/Pause button while focus is outlined elsewhere; button fill alone must not be classified as focus. Saved frame metadata can identify capture time/annotation, but does not establish one-to-one causality with a particular user gesture.

### F. The tentative Back route cannot be called a hardware-Back result

B records no native Back4 pair. It does record6 Select pairs, so an on-screen Back control selected through the UI is possible; an action outside the saved input interval is also possible. Neither is proved. Keep “playlist return plus large Down” as the user's path observation, not a confirmed Back mapping change or reproducible Back-specific fix.

### G. Smallest next probe — recommendation only

Consume only raw146's press/release without forwarding native93, preserving the continuous pad stream and every other control/declaration from B. This isolates the extra synthetic Down pulse while retaining working Up/Left/Right/Select/Back. It avoids repeating the already problematic hover-off/key-only direction, and avoids changing capabilities yet again.

If direct Down becomes reliable, that delivery is implicated under the tested profile; confirm repeatability and baseline comparison before shipping. If menus/Maps lose Down, the key was useful there and blanket suppression is not a fix. If the symptom persists, the pulse alone is insufficient and an independent controller/receiver comparison remains useful. See NEXT-PROBE.md for exact scope/evidence and limits. **No code or APK was changed for this proposal.**

## 6. Primary evidence for each finding

- Runtime/hash/profile claims: comparison.json, each run's collection.json, actual KEYSET/registration markers with lines, pinned candidate JSON and validation.json.
- Native counts/balance/emitted codes: trace-A.json/trace-B.json keyed to fresh boundaries and PID; Compare-Runs.js; validation checks against raw counts.
- Pre-dispatch timing: pre-send-audit.json contains exact raw/mapped/native result line references; current AaOverlayService.java:166–197 and InputSource.java:89–93 establish call/log ordering. B original capture:54027–54058 and ~54120–54135 contain the illustrative sequences. No focused-node data exists in callback1/2 enum logging.
- Operator path/history: original collection.json notes plus operator-clarification.json with this turn's clarification and remaining uncertainty.
- Visual claims: original private frames listed in comparison.json; their hashes match each run's private-image-hashes.json. No derivative image content was needed.
- Additional input/context differences: raw counts and contactsBeyond1324 in ordering-evidence.json; source native pad clamp remains at AaSessionService.java:209–215.
- Back limitation: trace-B nativeCounts has no4;6 Select23 pairs; original operator wording remains tentative.

A installed hash: `C3EDC256281D1F923CD65785DB0C0FA6B5E36E182FD602194245B89DB5875DDF`. B installed hash: `E931C7A4368465F52B218C5E973540F26D5C3D438F02751CC3C0B6FB15CEF383`. Both original capture hashes are in validation.json and collection.json.

## 7. Assumptions

User clarification refers to the B test just collected. Contacts are associated by logged event enclosure and raw-key mapping, not a separate physical event identity. Timing claims use pre-raw/pre-dispatch markers in the same contact; source/runtime parity relies on collected installed hashes and packaged/build provenance. No exact user-action/frame synchronization or unchanged queue between all observations is assumed.

## 8. Unresolved uncertainties

Exact starting/ending focused nodes, transient successful path, actual playback-button activation, effect of gesture distance, focus-history state, release-key causal effect, phone AA/Spotify version/logic, and root cause remain UNKNOWN. The A/B key-list difference did not fix direct Down. It may or may not affect other state transitions. StaticAudit PENDING. No claim that native keys were accepted by the phone merely because the local call returned0.

## 9. Exact diff summary

New offline comparison/audit scripts and derived traces/summaries, clarification and reports only. Own new derived ordering summary was corrected to distinguish pre-raw dispatch from post-native result logging. Original collection files/images/APKs and historical reports unchanged. No production source edit, build, source-profile switch, guard change, app setting, device command or installed artifact change.

## 10. Preservation checks performed

validation.json rechecks both collected installed APK hashes, both original capture hashes and all12 private frame hashes; all27 selected B source inputs remain identical to its build. Existing build/frozen-anchor preservation evidence reused; no frozen rebuild or modification. No key material/private APK assets read, Git mutation, ADB/USB/car/phone, new installation, guard bypass, milestone action, spawned agent or external publication. Further work from these logs can proceed offline.
