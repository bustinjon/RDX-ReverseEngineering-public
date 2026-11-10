# T240 built test bundle — November 9, 2026

**BUILT AND VERIFIED OFFLINE. No car test has run.** APK SHA-256: **14CBCFFA0F02AC85AB271C3DE8E9DE2EC3560198F6C71291D6F4E52E6FA77004**. Start-T240-bundle.cmd and Collect-T240-bundle.cmd are alongside the other suite launch files; the APK is builds/T240-bundle/rdx-t240-bundle.apk. This implements the per-device wireless policy correction identified in the [T230 review](../../../../agent-reviews/t230-latest-test-20261109/REPORT.md), without treating its other findings as fixed.

## 1. Files inspected

PROJECT-RULES.md; supplied AGENTS.md instructions; canonical T230 review/evidence; T230 source/build/test manifests and Java snapshots; suite VISIT.md; Build-Test.ps1, Switch-Source.ps1, New-TestPackage.ps1, Run-Test.ps1; standard scripts/Build-RdxUsbHelper.ps1; preservation manifest. Inspection of the builder was limited to its code, not the private source/asset/key files it references.

## 2. Files changed

New T240 bundle snapshot, test.json, BundleTests.java hook, WirelessPolicyTest.java, ServicePolicyTest.java and isolated host Android fixtures; scope, test plan, pending RESULT.md, report, manifests/diff/preservation/validation evidence. New suite tools Prepare-T240.ps1, Validate-T240.ps1, Finalize-T240.ps1, Build-T240.ps1 and Verify-T240Package.ps1. New Start/Collect-T240-bundle.cmd; generated APK, build/candidate/package manifests and normal package scripts. The standard authorized builder regenerated its local private/native staging and new timestamped build outputs/latest-build pointer. The copied T230 feature tests and 32 of its 36 snapshot files are unchanged. No T230 file, original log, canonical historical result, shared builder or readiness implementation was edited. Root tracked sources were temporarily swapped by the existing builder, then restored and verified.

## 3. Commands run

Read-only Get-Content/rg/path/hash inspection. Saved procedures:

[Code block omitted; consult project-authored source.]

Validation invokes the existing JDK17 compiler/runtime/jar and Android SDK D8 against Android API33, source/target7 and DEX minAPI21. Source comparison uses git diff --no-index, which does not change Git state. A few isolated javac/javap diagnostics investigated the validation harness's classpath failure; their output stays under offline/. Final validation uses a production JAR separated from test classes. After explicit user authorization, Build-T240 invoked the existing local private-material/signing/package workflow. Package verification invoked Run-Test.ps1 -Action Check, an offline-only action. No ADB/fastboot, device/USB access, network, Git mutation or agent call.

## 4. Tests run and results

- All **48 effective production Java inputs** compile. Unchanged inherited inputs are checked against T230's recorded source hashes.
- **29 new pure owner/policy checks PASS**, used by the actual service boundary predicates.
- **18 actual-service checks PASS** with fake Android preferences/action delivery/Bluetooth objects and real unconnected Java sockets. They exercise policy dispatch to both services, another owner's exemption, in-flight cancellation and token invalidation, repeated notifications, USB preservation, refused handoff ownership, Off between queue and consumption, selective bootstrap socket closure, and the actual existing shutdown route with an owned socket and no initialized native workers.
- Existing feature suites PASS: 15 touch, 5 frame-rate, 11 phone-policy, 11 Home, 10 persistent, 9 dismiss-label, 24 reconnect, 8 location, plus 245 bundle checks.
- Production-only DEX generation PASS; host fixtures/tests are excluded from the production JAR.
- T230's 36 snapshot entries plus source manifest and APK are unchanged. Five preservation-manifest entries covering all four frozen hashes verify. Host baseline verifies after the authorized build's temporary source swap/restoration.
- Initial harness attempts failed because of a wrong build-report property, then a directory-classpath compilation issue. These were validation-script problems, corrected before the passing run. See saved compile logs; do not count intermediate failures as a passed test or an application regression.
- First standard build failed during implicit host source lookup and restored baseline. Build-T240 supplies the same 48 effective production inputs explicitly in T240's spec; shared build tooling is unchanged. That retry passed the host suites and packaged successfully. Initial failure logs remain under packaging/initial-host-compile-failure-*.
- APK API22 signature, alignment, candidate/build/file hash identity, all 48 source hashes against the offline-tested inputs, mandatory readiness preservation, Start/Collect targets and offline runner Check: **PASS**. The APK's public classes.dex also exactly equals the offline-validated production DEX: **D927D860D321E00D1AB6BE9700162BDB04D8730629D7DD4E5333FDF1912E4A03**. Car/runtime behavior: **UNKNOWN**.

Use offline-latest.txt to locate the final passing result.json, host-test-output.txt, service-test-output.txt, compile.txt, source-hashes.json and production-jar-entries.txt. packaging/verification.json records the successful package/source/DEX/shortcut checks. build-result.json is BUILT_AND_PACKAGED with baselineRestored true. Earlier failed outputs remain saved, not substituted for final results.

## 5. Findings / implemented behavior

**The device-mode callback now persists successfully before notifying live services.** Main phone wirelessOff and mainDisabled changes use one editor commit; failed persistence reports an error and skips reconciliation. The notification carries no stale captured mode: handlers reread current preferences.

**The bootstrap service closes only AA Bluetooth channels whose resolved owner is now disallowed.** Its listeners, Wi-Fi group, Bluetooth adapter and HFP/pairings are not globally stopped by this policy action. It rechecks after the network readiness wait and after each blocking bootstrap read, before responding. Closed matching held channels are cleared to avoid retaining their ownership as live admission evidence.

**The AA service captures a wireless owner at admission.** Its new policy action leaves USB and another permitted owner alone, cancels a forbidden outbound connect, or invokes the existing coordinated shutdown for the active forbidden wireless owner. Initial handoff and queued handoff consumption both read current policy, so an Off change between those steps closes the socket before overlay/session startup. A rejected initial handoff leaves socket closure to its caller, as before.

**TCP admission is more conservative.** A current AA Bluetooth bootstrap must supply a resolvable, consistent owner. Unknown/ambiguous/no-bootstrap arrivals are refused instead of accepting every same-subnet connection. This may affect cached-network reconnects and must be checked in the car. It is not cryptographic TCP-to-Bluetooth identity binding.

## 6. Primary evidence for each finding

- Settings persistence/notification: snapshot SettingsActivity.java, device-mode callback; source lines and markers indexed in policy-source-evidence.json.
- Bootstrap selective closure/admission/rechecks: snapshot WirelessProbeService.java, policyChanged, peerOwner, tcpOwner, reconcilePolicy, ACTION_POLICY_CHANGED branch, TCP listener and bootstrap loop. The actual branch/socket checks are in ServicePolicyTest.java and its passing saved output.
- Captured-owner stop and handoff: snapshot AaSessionService.java, tcpOwner/handoffOwner, synchronized acceptPhoneSocket, ACTION_ACCEPT_TCP, outbound connection callback and ACTION_POLICY_CHANGED. Actual cancellation, queued-Off rejection and active-stop assertions run in ServicePolicyTest.java.
- Owner resolution and decision rules: snapshot HondaPhonePolicy.java, nested Wireless; WirelessPolicyTest.java's 29 checks plus actual service fixture cases.
- Exact source changes: t230-source-diff.patch; per-file baseline/candidate hashes: source-manifest.json. Final 48 compile-input hashes: offline source-hashes.json.
- Preservation: t230-preservation-before.json, final offline result.json and baseline-verification.txt, frozen-preservation.json. preparation-result.json records status/counts. Actual T230 failure remains evidenced in its canonical review; no historical result is rewritten.
- Built artifact: candidate.json, build-report.json, build-result.json, package-verification.json and packaging/verification.json. Build authorization: packaging/build-authorization.json. Offline runner output: packaging/offline-package-check.txt. Matching public classes.dex hashes establish the packaged implementation matches the separately validated production DEX.

## 7. Assumptions

T240 is the requested policy-only follow-up to the T230 review. Existing T230 features must be retained. The normal Android service-delivery model is assumed; the fixture records actions and invokes entry points explicitly, rather than simulating Android's full lifecycle. The next parked test should use the established serial-to-Bluetooth link, created by the prior wired-pairing step.

## 8. Unresolved uncertainties

No Android/car/native-worker run has occurred. Driver-visible disconnect latency, HFP behavior, reconnection timing and freeze behavior remain UNKNOWN. Fixtures do not prove framework scheduling, preference disk failure handling through the actual Settings UI, the 10-second wait race, or native resource teardown under load.

The inherited first-pair fallback associates an unlinked Bluetooth peer with the configured main phone while that main phone has no saved link. T240 makes that association explicit and refuses no-main/ambiguous cases, but cannot prove the unlinked peer is physically that phone. Concurrent-phone/IP attribution is not authenticated. A live TCP channel without a current bootstrap may now be refused; that is a deliberate conservative boundary to evaluate, not a demonstrated regression-free result.

The separately evidenced stale unversioned session-end cleanup race and main-thread teardown stalls are **unchanged**. T240 may expose the existing brief stop hitch when policy now actually stops AA. USB active-session revocation is outside this wireless fix; changing USB permission continues the inherited helper behavior. No feature promotion, public release or subsequent milestone is implied.

The operator explicitly granted the pending exception to run the existing local APK build and create its test file in this suite. That existing builder extracted/packaged protocol material and used the local signing key as designed. No private contents were displayed or manually inspected; package inspection opened only public classes.dex. The exception does not authorize publication or device installation. Build provenance is verified; staticAudit remains PENDING, and the car result remains UNKNOWN.

## 9. Exact diff summary

Four production Java snapshots differ from T230: SettingsActivity (atomic main-mode save and notification), WirelessProbeService (owner resolution, selective reconciliation and admission rechecks), AaSessionService (captured-owner live/pending enforcement), HondaPhonePolicy (pure shared decisions). Remaining snapshot files are byte-identical. Test fixtures live outside source/ and are not APK inputs. Exact additions/deletions are preserved in t230-source-diff.patch; preparation-result.json lists all four paths. No unrelated input/audio/navigation refactor.

## 10. Preservation checks performed

T230 APK remains D4251090D1AFE7EB4FC74162044038E0A14B63A67B7DB88A72C9E1E28336D893; all 38 saved T230 pins rechecked after the APK build. Four frozen hashes verified across five manifest entries. Root baseline verified after the build's source restoration. No original logs changed; none were recopied for this task. Only the existing builder processed private material under the explicit exception; it was not displayed or manually inspected. No device command, Git mutation, readiness bypass, milestone operation or agent delegation. Whole-workspace equality is UNKNOWN because unrelated pre-existing modifications/pruning are outside scope.
