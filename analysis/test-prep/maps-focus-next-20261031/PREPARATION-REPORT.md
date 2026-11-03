# Next Maps-only test preparation

## 1. Files inspected

PROJECT-RULES.md; Maps candidate/source/compiled verification, prior Diagnostics activation/collection records; fixed working-launcher timed stage, untimed wrapper, collector, hash manifest and delivery report; original artifact/guard preservation records; current 27 Java inputs. No credentials or APK entries inspected.

## 2. Files changed

Added only this directory's scope, generator, verified APK copy, matching build/candidate metadata, generated preparation/collector scripts and copied shell payloads, operator/connected wrappers, Windows shortcuts, offline verification, this report and test instructions. No production source or working launcher edits.

## 3. Commands run

Read-only saved-source/evidence inspection; Generate-NextTest.ps1; bundled PowerShell Run-NextTest.ps1 -Action Check. Later the user explicitly confirmed ADB connected at Home and ready, authorizing Prepare-ConnectedTest.ps1 for recovery/preparation. Its first attempt refused the already-open launcher lock before ADB. User then confirmed closure and preparation was retried. Connected outcomes are recorded separately in connected-latest.json/connected-* evidence when available.

## 4. Tests run and results

Generation PASS: selected APK hash matches; all 27 current source hashes match Maps candidate; exactly one changed input versus D1A29, GalReceiver.java; required original firmware/stable-window preflight retained; generated scripts parse; unchanged working-launcher hash manifest verifies before/after. Eighteen original artifact hashes and six guard hashes preserved. Offline CurrentSource plan PASS. Run-NextTest -Action Check exit 0, no device commands in the offline checks. Existing ten callback host cases and compiled evidence reused because source/APK bytes are unchanged. No hardware result implied by these checks.

## 5. Findings

No new APK compilation is needed: the isolated navigation-focus APK already exists and its Diagnostics tests passed in stopped/helper/auto-clicker conditions. The remaining first checkpoint is capture arming with the same candidate, before phone connection. The subsequent runtime question is whether Maps retains two routes beyond 90 seconds. One candidate method change is maintained; unrelated features remain baseline behavior.

## 6. Primary evidence for each finding

verification.json, candidate.json, build-report.json and offline-artifact-plan.json pin the copied APK and 27 Java inputs. Original Maps exact-source.diff, compiled-and-preparation-verification.json and host-test-result.json provide unchanged callback/compiled behavior evidence. Previous auto-clicker Diagnostics success and cleanup are in one-change-nav-focus-20261031/retry-20261031-223038/collection.json. connected-20261101-003150/failure.txt records the initial host lock refusal; no target commands were started in that attempt.

## 7. Assumptions

The user's build request authorizes offline next-test preparation. Their later ADB/Home confirmation separately authorizes recovery of the preceding launcher session and preparation of this candidate, stopping at the manual Diagnostics checkpoint. Home confirmation is accepted beyond mandatory readiness checks. Existing configured phone/Honda cooperative settings remain the comparison baseline; preparation verifies fresh cooperative startup and refuses early phone activity.

## 8. Unresolved uncertainties

Maps runtime outcome and capture-armed manual Diagnostics result remain UNKNOWN until the current test. Preceding car power-off does not prove cleanup; the connected wrapper attempts explicit saved-session recovery first. New Windows next-test shortcuts are offline-checked, not yet independently car-tested. Full static audit remains PENDING in inherited metadata. Collector allows a historical source role solely for retrieval if source changes later; preparation still requires matching CurrentSource, with no readiness bypass.

## 9. Exact diff summary

Production diff: none this turn. Existing Maps-only APK copied byte-for-byte. Compared with fixed working-launcher templates, timed stage substitutions are candidate path/hash, profile and shared runtime ADB path; untimed wrapper substitutes profile/ADB path; collector substitutes ADB path and retains repaired short pulls. Required preflight and core/guards unchanged. Windows/operator scripts add prior-launcher recovery, explicit manual Diagnostics checkpoint and route instructions. Working launcher default remains D1A29.

## 10. Preservation checks performed

Generator checks 18 original artifacts, six shared guards and all current 27 Java hashes after generation; working-launcher manifest verifies before/after. No rebuild, signing material read, native/manifest/source edit, frozen artifact modification, M5 guard bypass, Git update or milestone advancement. Only the separately authorized connected preparation may touch the target; offline build/check results are kept distinct from its runtime evidence.
