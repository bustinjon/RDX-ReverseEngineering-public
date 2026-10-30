# Honda phone-preference fix — 2026-10-30

**Source implementation and local validation complete. Replacement APK is not built or installed. No car needed until a new APK is available.** The new path leaves Honda alive and relies on the operator setting this phone to Disable/Never in Honda's own UI. That preference's actual runtime effect is still unverified.

## 1. Files inspected

PROJECT-RULES.md and AGENTS.md; v6h proposal and adversarial review; prior resumption review; captured force-stop/restart interval; helper service and manifest/filter; runner/core/tests; builder source-selection and signing/credential handling code. Credential values were not opened.

## 2. Files changed

- Modified `analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/UsbHelperService.java`.
- Added sibling `HondaPhonePolicy.java`.
- Modified `scripts/Run-CarTest.ps1`, `tools/car-test/CarTest.Core.ps1`, and `tools/car-test/Test-CarTestOffline.ps1`.
- Added `tools/car-test/HondaPhonePolicyTest.java` and this local evidence directory. Prior unrelated edits were preserved.

## 3. Commands run

Local file/log searches and reads, hashes, PowerShell parsing, in-process runner simulations, Java compilation and pure Java policy tests. Compiled the same helper/shared Java selection as the builder, without running packaging, asset collection, signing, or ADB. Ran the actual runner's Prepare branch against the old APK and confirmed it refuses PhonePreference mode.

## 4. Tests run and results

- **42 runner simulations PASS, 0 FAIL**: `runner-tests-final/results.json`.
- **15 Java policy checks PASS**: `policy-test.txt`.
- **All 21 effective Java sources compile**: `compile-inputs.txt`, `javac.log`, and classes directory. Obsolete Java-7/deprecation warnings remain.
- Three changed PowerShell files parse successfully.
- Actual historical APK rejected for PhonePreference before device access.
- Four frozen artifacts match; preservation comparison found no unexpected baseline changes.

Initial runner tests exposed an outdated ordering assertion that searched only for the old bare startservice command; corrected to recognize explicit legacy configuration. The first standalone policy-test compile had a classpath resolution failure; compiling the pure policy and its test together succeeded. These failures were not counted as passing runs.

## 5. Findings and implementation

**Restart mechanism:** capture.log:29988–29989 records telephony reconnecting/binding after binder death; :30026–30027 records the status bar rebinding; :30037–30039 records voice-service reconnection. Honda's GalService process restarts at :30085, 275 ms after the force-stop at :29982. These clients make continued process suppression a poor fit. The exact request that won the restart race is UNKNOWN.

**New helper path:** private preferences persist the operator-selected phone serial. Configuration is applied before any startup force-stop/reset or polling. In cooperative mode, those legacy actions are omitted. Raw-phone selection/AOAP switching and AOAP/session handoff require the configured serial; missing, unreadable, or different identities are rejected. Cold/sticky startup loads the saved policy. Reconfiguration of a running service is refused, requiring a fresh service instance. Configuration commit failure stops startup. Cooperative mode uses the standard USB permission path and does not attempt the legacy reflective direct-grant fallback.

**New runner path:** `HondaStrategy=PhonePreference` requires an explicit valid `PhoneSerial`, `HondaPhoneDisabled` operator confirmation, and a matching CurrentSource APK whose source metadata includes HondaPhonePolicy. It rejects the old baseline and missing prerequisites before any device operation. The runner starts neither Honda force-stop nor a Honda kill loop in this mode; it retains fresh accessibility/capture/helper checks, the independent cleanup watchdog, PID-scoped logger cleanup, and the minimum 30-second remaining cleanup window. It verifies the fresh policy marker and refuses legacy force-stop/reset logs in cooperative startup. Legacy mode and its stopped-state guard remain intact.

This is a separate policy for Honda's documented per-phone decline path, not a claim that Honda is stopped. The mode flag does not read or prove Honda's private preference. The user reported their phone was still enabled and offered to disable it; completion has not yet been confirmed.

**Next steps:** obtain scoped permission for the local credential/signing build, build and pin the new APK, confirm the phone's Disable/Never preference and serial, then request the car for one controlled validation. Do not use the old APK or the old force-stop experiment to test this source change.

## 6. Primary evidence for each finding

- Restart evidence: `analysis/test-prep/runs/helper_20261030T180252_b9555031f7164592b2ccb24966624c28/capture.log`, lines 29982,29988–29989,30026–30027,30037–30039,30085.
- Policy and integration: the new HondaPhonePolicy class and UsbHelperService onCreate/onStartCommand, rawPolicyAllows, policyAllows, permission callback, switchToAoap, and startAaSession.
- Runner: Assert-CTPhonePreferencePlan and Invoke-CarTestPreparation in CarTest.Core.ps1; new explicit CLI parameters in Run-CarTest.ps1.
- Test results and current implementation hashes: [validation.json](validation.json), [runner results](runner-tests-final/results.json), [policy checks](policy-test.txt), [compile log](javac.log).
- Existing preference analysis: `analysis/agent-reviews/CLAUDE-RESUME-20261102.md`, F03–F06, with primary Honda/framework references. Those limitations still apply.

## 7. Assumptions

The user's “Let's fix it” authorizes source/runner changes addressing the demonstrated restart problem. Their offer to change Honda's per-phone preference supports this cooperative path; no package disable, factory APK replacement, or milestone change is authorized or performed.

## 8. Unresolved uncertainties

Honda's actual per-phone preference, raw/AOAP serial continuity, chooser behavior, CDP side effects, and runtime startup/persistence behavior are unverified. Host tests validate policy decisions and runner orchestration; they do not execute Android SharedPreferences or real USB transitions. Video, input, audio, callback deadlines, and reconnect recovery remain separate gaps. This change does not claim complete standalone projection.

The build is pending because AGENTS.md prohibits reading key material, and the existing helper builder reads credential material and uses signing assets. A scoped user exception is needed before that local build; values should remain out of logs. Frozen artifacts must remain untouched.

## 9. Exact diff summary

Four existing code files modified (helper service, runner, core, runner tests), two source/test files added (phone policy and Java test), plus generated local validation evidence. No APK, previous report/log, instructions, M5 guard, or milestone record edited. No Git staging, commit, push, deletion, or device action this turn.

## 10. Preservation checks performed

Four frozen SHA-256 anchors match. The original 263-file inventory was compared, allowing only the previously authorized runner/shell changes and this helper change; no unexpected differences were found. Current implementation hashes are in validation.json. No credential values accessed, no signing or packaging performed, and no milestone advanced.
