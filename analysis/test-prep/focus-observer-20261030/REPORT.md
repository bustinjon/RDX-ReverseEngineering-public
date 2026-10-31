# Focus observer A preparation

Built/signed/locally checked. No car connection or live test run. See NEXT-TEST.md for capture control, full connection cue and private evidence procedure.

## 1. Files inspected

PROJECT-RULES.md; three prior input results; latest directional focus source; matching stock InputSource callback/native declaration and Protos FeedbackEvent enum; HMIPresenter/GalIntegration input-key declarations; private helper manifest; current build/provenance and frozen anchors. Native receiver string-presence check found both nativeRegisterFeedbackEvents and onInputFeedback, corroborating existing stock Java signatures without invoking native code.

## 2. Files changed

- Effective helper InputSource.java: request/log SELECT and FOCUS_CHANGE feedback.
- AaOverlayService.java: explicit one-session capture arm and capture lifecycle/key metadata hooks.
- New FocusCapture.java and FocusCaptureBudget.java.
- New tools/car-test/FocusCaptureBudgetTest.java; plan/report, results, validation and new private APK.

No InputEvents/mapping change, shared video/geometry/audio/session source, native library, manifest, existing APKs, live runner/guard, Git/public snapshot or prior report change.

## 3. Commands run

Local source review; native symbol-name presence checks; JDK 17 host tests; existing Build-RdxUsbHelper.ps1 with label v6h-focus-observer-a using the authorized signing process; source/APK/DEX/native/signer/frozen comparisons; Run-CarTest Prepare with nonexistent ADB path and 180 seconds. No device command or publication.

## 4. Tests run and results

- **PASS: 25799 input/PCM assertions** and **PASS: 10019 capture-budget assertions**. These include repeated per-byte/time-step checks, not independent scenario counts.
- Capture tests cover burst rejection, twelve-attempt cap, 120-second expiry, close rejection and backwards-clock rejection. They do not execute Android TextureView, storage, threading, service intents or JNI.
- All 27 Java inputs compile; zero current-source differences. Four new/modified production inputs are exactly InputSource, AaOverlayService, FocusCapture and FocusCaptureBudget.
- API-22 signature/alignment pass; packaged DEX matches generated DEX; capture/feedback/key-only marker strings present; native bytes and public signer match v5.
- V5/directional A APK hashes and four frozen anchors unchanged. StaticAudit remains PENDING. Hardware feedback/capture behavior untested.

## 5. Findings

Previous captures establish successful local key submission without the intended UI result. More remapping cannot identify selected UI state from those logs. This observer adds two correlated evidence sources: optional low-rate AA TextureView samples and phone-reported focus/select feedback. It retains the failing key-only policy deliberately rather than claiming a repair.

A second static discrepancy was found: the matched stock key advertisement omits DPAD 19..22 while our current candidates include them. That is reserved for a separately controlled experiment after focus evidence, not changed here. Its effect on phone navigation mode is UNKNOWN.

## 6. Primary evidence

- Private helper InputSource nativeRegisterFeedbackEvents declaration matches stock `decompiled/AndroidAuto-current/sources/com/google/android/projection/protocol/InputSource.java:40,100–102`; Protos.java:1967–1972 defines feedback 1/2. Existing callback now logs their names.
- Matching HMIPresenter.java:742–744 key array and GalIntegration.java:108–115 show the stock advertisement difference. Prior run RESULTS.json shows 22 Up pairs with failure and no pad forwarding.
- FocusCaptureBudget.java contains enforced numeric/time bounds and close behavior. FocusCapture.java implements UI-thread readback, one outstanding write, background PNG encoding, app-specific storage and logged metadata. AaOverlayService's arm branch, VIDEO consumption of arm state, texture-update hook and removal hook control lifetime.
- validation.json: APK `analysis/parallel-aa-receiver/usb-helper/build/20261030-204702-954/rdx-usb-helper-v6h-focus-observer-a.apk`, SHA-256 `853991C05DEF75FAF3EA592D26389968F455229D6F9EFBC02E13D824FDC91BF5`, source/provenance/signature/native/frozen flags. Actual host output saved in input-results.txt/capture-results.txt.
- User explicitly approved private captures in this conversation. No capture has yet been armed or saved on a device.

## 7. Assumptions

App-specific external storage and TextureView bitmap readback are usable on this head unit; failure is logged rather than taken as permission to change platform access. Phone implements the requested optional feedback. User follows the same Spotify layout/test with short pauses for image sampling.

## 8. Unresolved uncertainties

Image fidelity versus transformed/final compositor output, feedback availability, storage retrieval, readback overhead, active selected control, and the actual navigation root cause. Capability registration changes feedback negotiation, so this is not an assertion of bit-identical wire traffic. Missing feedback alone is inconclusive. Existing exported helper services are unchanged except the new opt-in action; this is a private test build, not a production permission/security redesign.

## 9. Exact diff summary

Add one-session, default-off AA image observation: at most twelve 960x360 capture attempts, ten-second spacing and 120-second capture window after first texture update; sampled image metadata tied to input ordinals; writer closure on overlay removal. Register feedback events 1/2 and log callback meanings. Keep current keys-only policy and all geometry/audio/lifecycle protocol handling otherwise unchanged. Add bounded-capture host tests and a 180-second offline plan.

## 10. Preservation checks performed

Known-working/prior APKs and four frozen hashes match; native/signer/source provenance verified. No ADB, credential contents printed/read by inspection tools, new permission, public upload, Git mutation, factory change, guard bypass or milestone advancement. The private APK still contains existing protocol prerequisites and is not suitable for public distribution. Captured images/raw logs must remain private under the user's approval.
