# v6h-pad-absolute-off-a — single-flag comparison

Offline comparison build. **Only the live touchpad registration's `uiAbsolute` flag changes from true to false.** This requests a different pad interpretation while preserving the existing key, pad, Select/Back, audio and video implementation. It is an experiment; Spotify focus behavior remains UNKNOWN until a separately authorized test.

APK: `analysis/parallel-aa-receiver/usb-helper/build/20261031-093640-830/rdx-usb-helper-v6h-pad-absolute-off-a.apk`  
SHA-256: `A58A391BBC2A855E91F472403045490816E02598C5EBA09410EE85DCB078FA73`

## 1. Files inspected

- PROJECT-RULES.md and AGENTS.md.
- Live/diagnostic touchpad registration in `analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/AaSessionService.java:267,304`.
- Existing bzone-keys-20261031 build/verification/preparation scripts, candidate.json and preservation baseline.
- Existing builder entrypoint `scripts/Build-RdxUsbHelper.ps1`, existing `Run-CarTest.ps1` used only in Mode Prepare.
- Current candidate's 27 recorded Java inputs, selected APK entries (classes.dex, manifest, resources and native library), public signature-verification output, and APK-derived AaSessionService.java.
- Canonical motivating analysis: `analysis/agent-reviews/main-pad-order-20261031/REPORT.md` and `analysis/agent-reviews/offline-alternatives-20261031/ALTERNATIVES.md` section C. No prior evidence collection repeated.

## 2. Files changed

- One production file, one line: AaSessionService.java:304.
- New offline preparation/report/scripts/evidence under this directory, new timestamped builder outputs and normal usb-helper/latest-build.txt update. The existing offline runner also generates a new artifact-plan directory identified by offline-prepare.txt.
- No input handler, InputEvents, native library, manifest, resources, frozen artifact or old report modified. Diagnostic-only registration at line267 intentionally remains unchanged.

## 3. Commands run

All multi-step work was saved before execution:

[Code block omitted; consult project-authored source.]

The build wrapper calls the standard `Build-RdxUsbHelper.ps1 -Version v6h-pad-absolute-off-a` and saves detailed output. Verification uses selected-entry hash comparison, the packaged DEX, JADX, exact source comparison, signature/alignment evidence and existing runner in Mode Prepare with a nonexistent ADB path. Future-script generation only substitutes the pinned artifact path/hash in the existing live script and parses it; it does not execute it. Targeted Get-Content/rg reads and a scoped source edit were also used. No ADB or installation.

## 4. Tests run and results

Final result is recorded in validation.json and final-preservation.json:

- Exact scope PASS: the saved previous Java source, with exactly one live-call true->false replacement, equals the new source byte-for-byte. Only AaSessionService.java differs among 27 recorded build inputs.
- Packaged-code PASS: APK-derived live field call is `this.inputSource.registerTouchPad(1325,720,60,40,true,false)`. Packaged/generated DEX hashes agree.
- Manifest, resources and native-library entry hashes unchanged from prior tested DB9B candidate.
- API22 v1 signing/alignment verification PASS; same public signer as the baseline.
- Ten previous/frozen artifact hashes preserved, including DB9B and all four PROJECT-RULES anchors.
- Existing offline CurrentSource artifact planner PASS with zero source differences; no device command invoked.
- Future live script parser/hash checks PASS only; not executed.
- Existing baseline input/PCM, hover/Select and B-zone host results retained rather than repeated: those implementations/test inputs did not change. These old tests do not validate the new flag's phone-side effect. No hardware result claimed.

The first packaged-code assertion incorrectly matched a diagnostic local variable renamed by JADX as `inputSource` and reported the old true flag. Inspection showed the live **field** call already contained false; the unrelated diagnostic local retained true, as intended. The checker was corrected to match `this.inputSource` specifically and verification rerun. See verification-failure.txt, packaged-code and Verify-Comparison.ps1. No production/APK change was made to resolve this checker issue.

`staticAudit` remains PENDING. Targeted validation is not a full audit or a reproducible-build claim.

## 5. Findings

The candidate implements the requested single-variable comparison. Normal live registration keeps width1325, height720, physical60x40mm and navigation=true; absolute changes to false. Key registration and mapped events, hover forwarding/dedup, Select/Back and audio/video paths are identical to DB9B. The B-zone opt-in remains unchanged and the future script retains the previous explicit arm/capture setup for parity; use the large pad for the discriminating test.

The diagnostic-only `testInput.registerTouchPad(...true,true)` call remains true so the production diff is precisely the live-session flag. The diagnostic mode is not the test session and cannot serve as runtime evidence that the live flag was false. A future collected run must show `Touchpad registered: ... nav=true abs=false`, and the installed A58A… APK hash.

Whether the phone interprets the request as desired and whether this changes compact media-card focus remain UNKNOWN. No fix, new live readiness or milestone result is declared.

## 6. Primary evidence for each finding

- Exact change: scope-check.json, AaSessionService.before.java, AaSessionService.java.diff and live source line304.
- Packaged change: `packaged-code/sources/com/rdx/fullscreen/usbhelper/AaSessionService.java:262`; verifier's live-field match; candidate.json/validation.json bind it to the APK hash above.
- Unchanged production inputs/entries and signing: validation.json, candidate.json, saved build signature-verification.txt and scope-check.json.
- Preservation: before.json, validation.json and final-preservation.json.
- Offline-only artifact planning: offline-prepare.txt explicitly states no device command invoked. Future-script-validation.json records executed=false.
- Why test this flag: canonical main-pad-order report traces all33 Down and13 Up native pairs; media review shows large-pad use. These narrow the problem but cannot prove a flag correction is the fix.

## 7. Assumptions

User's “Do that” authorizes this exact offline build and verification, not another car session. A later comparison retains the same phone, widget layout and other settings. Existing future-script stock-phone preference planning assumes the prior disabled configuration; it must be checked/confirmed before live use.

## 8. Unresolved uncertainties

Actual phone-side capability interpretation, Spotify lower-control reachability, Maps/grid/Select/Back regressions, repeated widget entry, precise focus feedback and hardware behavior remain UNKNOWN. Diagnostic mode remains absolute=true by design. StaticAudit PENDING. No ADB/install/test run performed in this build task.

## 9. Exact diff summary

[Code block omitted; consult project-authored source.]

Only AaSessionService.java:304 changes in production. The previous diagnostic call is untouched. New saved scripts/reports/evidence and normal generated build/latest pointer/Prepare-plan artifacts are listed above. Future Prepare-LiveTest.ps1 is the existing bzone preparation script with only the old APK path/hash replaced; existing readiness, cleanup, timer, A11Y, capture and arm behavior retained. No guard edits or bypasses.

## 10. Preservation checks performed

Pre-edit checks bind all27 Java inputs to DB9B and verify ten saved artifacts. Post-build checks bind the new27 inputs to A58A…, confirm only the intended file changed, compare selected public APK entries, confirm signing/alignment and recheck ten preserved artifacts. Original logs/media are reused read-only; no key material/private APK assets inspected. No frozen rebuild, ADB, USB/car/phone operation, Git write, milestone action or spawned agent. Detailed final hashes: final-preservation.json.

Next authorized comparison: [NEXT-TEST.md](NEXT-TEST.md).
