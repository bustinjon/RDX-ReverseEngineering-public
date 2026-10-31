# Navigation-focus fix and separate test build — 2026-10-31

## 1. Files inspected

PROJECT-RULES.md and root AGENTS.md scope; canonical investigation `analysis/agent-reviews/maps-route-20261031/REPORT.md` and its installed DEX/stock enum evidence; current GalReceiver.java; long-drive candidate, baseline, builder, signed build reports, known working untimed wrapper/stage/collector and device shell payloads. Baseline records all27 Java inputs,16 prior/frozen artifacts and six shared guard/runner files. No key material was inspected during this task.

## 2. Files changed

Production: only `analysis/parallel-aa-receiver/src/com/google/android/projection/protocol/GalReceiver.java`, navigationFocusCallback. Added this candidate's scope, tests/fixtures, build/validation/provenance, isolated preparation/collector and instructions under `analysis/test-prep/maps-nav-focus-20261031/`. Standard builder created `analysis/parallel-aa-receiver/usb-helper/build/20261031-142134-610/` and updated latest-build.txt. No install or device commands.

## 3. Commands run

Saved procedures: Snapshot-Baseline.ps1; Test-NavigationFocus.ps1; Build-Candidate.ps1; Test-OriginalDefect.ps1; Generate-Preparation.ps1; Verify-Candidate.ps1; Verify-CompiledAndPreparation.ps1. JDK javac/java ran host fixtures; the existing builder signed opaquely; SDK dexdump disassembled public DEX. `git diff --no-index` saved the exact baseline/source comparison; this performs no Git write. Offline `Run-CarTest.ps1 -Mode Prepare` used a nonexistent ADB path. Read-only Get-Content/rg/Get-ChildItem inspected saved evidence. Full outputs remain in this directory/build directory.

## 4. Tests run and results

- Ten requests passed using the real callback source in a host fixture. Only its private nativeSetNavFocus endpoint was replaced by a recording sink; unused source-type dependencies were stubbed. Projected2/native1, repeated requests, five invalid boundary values, exact-once replies and numeric logging passed. This tests Java behavior, not actual JNI/phone execution.
- Negative control restoring the always-native reply, while retaining current validation/logging, failed with the expected `Requested state not preserved` assertion. The behavior test detects the original defect.
- Source verification:26 of27 recorded Java inputs unchanged; the sole changed file's text outside navigationFocusCallback is unchanged. Exactly one compiled .class differs: GalReceiver.class.
- APK verification: five public non-DEX entries (native library, manifest and resources) are identical to the prior candidate; only public classes.dex differs. Signature v1/API22 and alignment evidence PASS. Private credential/signature entries are excluded before entry content is opened; this task does not assert independent per-entry credential equality.
- Compiled callback verification PASS: on both valid branches the native invoke uses the original request register v4. Invalid path returns before the native call. All three numeric log strings are present. First static-check iteration was too broad: it rejected compiler reuse of v4 inside the rejected branch after the request was logged. The corrected check follows valid branches separately and confirms the invalid branch terminates; no production change was required.
-16 prior/frozen artifact hashes and six shared guard/runner hashes match baseline. Offline CurrentSource/PhonePreference artifact plan PASS. Generated PS scripts parse; stage and wrapper are independently compared with their parent templates, and copied shell/collector hashes match the live-tested versions.

Hardware route outcome remains UNKNOWN; candidate is not installed.

## 5. Findings

The old callback always replied native focus1. The new callback logs the requested numeric state, rejects values outside1/2, logs the valid reply, and passes the requested state to the existing nativeSetNavFocus method. Thus projected2 can be granted while native1 remains representable. JNI method identity/descriptor and all unrelated callbacks remain unchanged.

APK: **rdx-usb-helper-v6h-nav-focus-a.apk**, SHA-256 **21037DC393FCD162499589254D745DD0904A326BD7E5A33D69CF3FC69BFA4084**. This isolates the confirmed focus bug for the next route comparison. It does not establish that the previous approximate30-second Maps cancellation was caused by that bug.

The new candidate keeps untimed launch semantics from the successful long-drive workflow, with rotating diagnostics and manual cleanup. Ordinary readiness still runs first. The copied short stage must not be run alone. No new bypass was added to the M5 guard, and no milestone is advanced.

## 6. Primary evidence for each finding

- Scope/root defect: SCOPE.md and `analysis/agent-reviews/maps-route-20261031/REPORT.md`, especially its installed callback disassembly and stock enum references.
- Production change: `GalReceiver.java:85–95`; exact-source.diff; before.json and GalReceiver.before.txt.
- Behavior: NavigationFocusTest.java, Test-NavigationFocus.ps1, host-test-result.json, host-fixture/test-output.txt. Negative control: negative-control-result.json and negative-control/test-output.txt.
- Artifact/source/preservation: candidate.json, validation.json, public-apk-entry-hashes.json, public-apk-entry-diff.json; build-directory signature-verification.txt and alignment-verification.txt.
- Compiled semantics: compiled-callback-only.txt, candidate-dexdump.txt, compiled-and-preparation-verification.json and compiled-class-diff.json. Request register allocation is five registers/two incoming registers; valid invoke uses `{v3,v4}` where v3=this and v4=request.
- Untimed preparation: preparation-provenance.json and the independent equivalence checks in Verify-CompiledAndPreparation.ps1. Candidate preparation files do not execute during generation/verification.

## 7. Assumptions

User's “Continue work” authorizes the narrow fix proposed in the prior completed review and a separate test build. It does not authorize installation or a device test in this turn. Stock enum values1/2 are the expected JNI protocol contract already established by the canonical investigation.

## 8. Unresolved uncertainties

Maps route retention and phone acceptance of replies require the future route comparison. Native JNI/phone runtime behavior is not simulated by the host fixture. Unknown request values are logged and ignored; none were established in the prior run because the old callback did not log navigation-focus requests. Sensor-advertisement issues, OEM volume-display ordering, physical media-key mapping and Spotify compact-row focus remain separate unresolved work and unchanged. Full static audit remains PENDING per the standard builder; these scoped checks are not a complete APK audit. See NEXT-TEST.md for the two-route90-second comparison and evidence criteria.

## 9. Exact diff summary

One existing production line replaced by the expanded callback: **+10/-1 lines**. No other production method or class changed. Ten behavior cases and one negative control added as external fixtures. Isolated test preparation copies the known workflow, changing only the APK path/hash and diagnostic profile label in its timed stage and only the profile label in its wrapper; collector and four shell payloads are byte-identical copies. Standard build outputs/latest pointer and analysis artifacts added; no Git staging/commit/push.

## 10. Preservation checks performed

All16 prior/frozen artifacts, including long-drive D1A29… and the M5/M6/receiver-DEX/TLS anchors, retain their recorded hashes. Six shared guard/runner files are unchanged.26 unrelated Java inputs and all other compiled classes match baseline; new candidate provenance matches current27 inputs. Five non-DEX public APK entries match. Private credential/signature entry contents were not opened by this task's comparator, and no signing material was read. No frozen rebuild, device operation, milestone change or unrelated feature edit occurred.
