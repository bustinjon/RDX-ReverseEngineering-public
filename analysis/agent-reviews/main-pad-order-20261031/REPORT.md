# Main-pad Down regression investigation — offline continuation

**Result:** no missing, reversed or differently ordered Up/Down key path was found in the saved current test. All **33 Down** native key pairs and **13 Up** pairs occur inside their corresponding pad contacts, before the pad UP. All return zero. All Down contacts have positive raw Y displacement; all Up contacts have negative displacement. This narrows the investigation without establishing phone receipt, phone focus behavior or root cause.

The user's PowerShell rule is now recorded as two bullets in `PROJECT-RULES.md` under Working rules. Multi-step work for this continuation is in saved scripts; completed collection, media extraction, build and host tests were not repeated.

## 1. Files inspected

- `PROJECT-RULES.md`; prior canonical alternatives `analysis/agent-reviews/offline-alternatives-20261031/ALTERNATIVES.md`.
- Latest run `analysis/test-prep/runs/helper_20261031T131432_b7c47627e1bd469a90efe3e189e593b9/`: capture.log (remote suffix `rdx_f58c2f6d2edb4597a1790e7158704665`), input-observation.json and previously saved nominal video comparison in the media review.
- Current helper source: `InputEvents.java`, `AaOverlayService.java:160–211`, `AaSessionService.java:189–215`, `com/google/android/projection/protocol/InputSource.java:60–99` (all under usb-helper/source).
- Archived factory `decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/ui/ProjectionActivity.java:579–614,2267–2333`; factory `com/google/android/projection/protocol/InputSource.java:96–153`.
- Built candidate's `candidate.json` and its 27 input hashes for preservation. No key material or private APK assets inspected.

## 2. Files changed

- `PROJECT-RULES.md`: two Working rules bullets persist the user's explicit PowerShell-file/quiet-output/no-repeat requirements.
- New analysis scripts and generated evidence in this directory only: Analyze-Input.js, Run-Analysis.ps1, Validate-Trace.js, Validate-Trace.ps1, trace.json, nominal-input-events.json, key-contact-order.csv, factory-excerpts.md, factory-key-summary.json, summary.json, analysis-output.txt, validation.json, validation-output.txt and this report.
- No production code, existing evidence, original media or APK changed.

## 3. Commands run

Targeted source/document reads using Get-Content/rg; the multi-step analysis and validation executed by filename:

[Code block omitted; consult project-authored source.]

Both wrappers save detailed output locally and emit one concise result. No ADB or car steps. No new media decode, log retrieval, build or re-run of completed host tests. Brief saved result summaries were read after execution.

## 4. Tests run and results

New evidence-validation checks **PASS**: fresh boundary matches prior observation; native Up/Down pair counts match independently saved raw146/raw152 counts; all map to the expected codes; every Up/Down pair belongs to exactly one enclosing logged contact and precedes its UP; all native key return values zero; 27 Java inputs unchanged; original capture hash unchanged. These are checks of saved evidence, not behavior tests.

| Saved-run measurement | Down | Up |
|---|---:|---:|
| Raw gesture -> native mapping | 146 ->20 | 152 ->19 |
| Balanced native pairs | 33 | 13 |
| Pairs strictly between corresponding pad DOWN and UP | 33 | 13 |
| Contacts with positive Y displacement | 33 | 0 |
| Contacts with negative Y displacement | 0 | 13 |
| Native key press duration (log resolution) | 0–4 ms | 1–4 ms |
| Nonzero key native return values | 0 | 0 |
| Pair followed by a FOCUS_CHANGE within 200ms | 4 | 4 |

The feedback counts are **temporal associations only**, not success rates. UI states, repeat actions and contact streams differ, and the callback contains no focused-node identity or causal event ID. The zero-ms press means equal log timestamps, not proof of identical native timestamps.

## 5. Findings

### Where the observed paths first differ

Expected direction-specific fields differ (raw146/scan80/AA20 versus raw152/scan72/AA19 and Y displacement). No unintended mapping/order difference between the two directions is established in this trace. The first point causing the **different UI outcome remains UNKNOWN**. The observable chain reaches the JNI key call for both directions; native return0 does not prove the generated wire event, phone receipt or phone focus result.

For a concrete Down example, contact48 begins at capture.log:40864 with raw `(425,160)`, ends `(313,616)`, and maps raw146 at :40876 to native20 DOWN at :40878 and UP at :40880; pad UP follows at :40881. The full trace/CSV records every association without assuming the broad video window is precisely synchronized.

### Counterexample to a tempting diagnosis

Both motion and key streams are observed, but the archived Honda implementation also forwards hover as pad events (`ProjectionActivity.java:579–614`) and handles swipe keys (`:2308–2325`). Therefore, “two streams exist” is insufficient evidence that duplication causes the bug. Our raw146->20 mapping differs from archived factory raw146->93 (PageDown); analogous mappings differ for Up/Left/Right. The earlier page/move candidate already failed after returning to the widget, as preserved in the alternatives report E9. Do not present either “stop all hover” or “restore factory mappings” as a newly proven repair. A previous key-only comparison also broke Up; preserve that counterexample.

### Evidence ranking, without invented probabilities

1. **Established:** the symptom depends on UI context: main-pad title-to-top-right movement is visible; Maps right-third navigation is operator-reported as working; Spotify's lower compact-card controls remain unreachable by report. The Java/native key call path is active and directionally consistent. These claims have high confidence within their stated evidence limits.
2. **Unresolved leading explanations, not distinguishable by this evidence:** phone AA dashboard/media-card focus behavior; receiver input contract/interpretation (including absolute pad navigation); and their interaction. They cannot be honestly ordered as root causes without a controlled comparison. The AA dashboard's media card should not be assumed to be an ordinary Spotify-rendered Android view.
3. **Disfavored as the complete explanation:** a globally missing Down mapping, globally inverted Y axis, universally inaccessible right-third area, or wrong APK. The trace, Maps report and installed-hash collection check supply counterexamples. This does not eliminate context-specific receiver behavior.
4. **Not tested here:** the new B-zone adapter. It was armed/enabled, but zero matching raw38/39 events were logged; the video shows large-pad use. No conclusion about correctly delivered B-zone pairs is justified.

### Smallest next comparison for lead review — not executed or built

A single **pad-interpretation capability comparison** is more informative than another global directional remap: change only the `uiAbsolute` registration flag from the current true to false, preserving dimensions, motion forwarding/dedup, key mappings/registration, Select/Back, audio/video and session handling. This is an unproven experiment, not a claimed fix. A fresh phone session is needed to observe the negotiated configuration; record the flag in that run. Keep any B-zone mode identical and explicit between references so it does not become another variable. The existing alternatives report section C contains this previously documented option; this continuation supplies additional main-pad ordering evidence in support of considering it, not a new implementation.

The smallest discriminating user sequence would be one Spotify title-to-bottom-controls attempt, one title-to-top-right attempt, and the same directions on Maps, using the **large pad** in each case. Then verify Select/Back and grid movement. If the capability comparison harms working controls or fails to change the symptom, keep the baseline; do not combine it with key-only, rotary, media-key or coordinate changes. A direct media-command bridge remains a separate usability workaround, not proof that the navigation defect is repaired.

## 6. Primary evidence for each finding

- All ordering/displacement/count claims: `trace.json` stats, strokes and per-key line references; `key-contact-order.csv`; validation.json axis metrics/checks. Parser restricts to the fresh boundary and PID5551.
- Concrete contact48 example: original capture lines40864–40881, copied as structured event records in nominal-input-events.json. Capture hash: `1155CD10064732026B62202DA1D08B6C558E6A3F71347C50987F048D9135FB93`.
- Current mapping/consumption: helper `InputEvents.java:5–25`, overlay `AaOverlayService.java:186–197`; session `AaSessionService.java:189–215`; native wrapper `InputSource.java:89–93` and feedback `:105–106`.
- Factory counterexample: `factory-excerpts.md` preserves original file line numbers; factory hover forwarding :579–614 and key mapping :2308–2325. Archived/current runtime equivalence is UNKNOWN; this proves the archived design contains both, not how the present car ran that design.
- Current absolute-navigation registration: helper `InputSource.java:60–71`, registration log in the saved capture; canonical alternatives section C. Changing the flag has not been tested here.
- UI/pad observations: `analysis/agent-reviews/spotify-maps-media-20261031/REPORT.md`, frames013/017 (large pad), frames017/019 (title-to-top-right outline), and current run collection.json (operator's Maps comparison).
- Installed candidate identity/cleanup: current run collection.json; installed SHA-256 `DB9B0598467DE2BD1C7D363E52F5A0E6C759641F6490A66ED18632F402371206`.

## 7. Assumptions

Enclosing pad-contact associations are based on logged event ordering, not a measured physical hardware event identity. Native mappings are associated with the immediately preceding mapped event within20ms. Video clock alignment remains approximate. Source/runtime parity for the helper uses the prior installed APK/hash plus unchanged recorded source inputs, not a new APK rebuild.

## 8. Unresolved uncertainties

Actual native wire payload/phone receipt; focus hierarchy; why the lower children are unreachable; which input stream triggers each feedback; negotiated flag semantics in this phone release; precise video synchronization; B-zone behavior; and full live source/decompiled-factory equivalence remain UNKNOWN. No fix or additional live step is claimed. Current staticAudit remains PENDING.

## 9. Exact diff summary

`PROJECT-RULES.md`: adds two bullets immediately under Working rules, requiring saved `.ps1` for commands longer than roughly3–5 statements/multi-step procedures, script reuse, detailed output under analysis, concise stdout, and no repetition for presentation compliance. No other instruction text changed.

New directory contains only saved-log analysis/validation code, source excerpts, derived evidence and this report. No changes among the 27 build inputs; no changes to handler/flags/native registration, APK, original media/logs, frozen artifacts or historic reports. No Git operations.

## 10. Preservation checks performed

validation.json verifies all27 Java inputs against candidate.json and rechecks the capture hash because this new trace relies on those originals. Previous media/extraction/build/device checks were reused, not repeated. Frozen artifacts were neither rebuilt nor modified; their existing preservation checks remain in the canonical prior report and were not rerun just for this rule. No key material inspected; no ADB/car/phone/USB, guard bypass, milestone action, agent spawn or Git mutation.
