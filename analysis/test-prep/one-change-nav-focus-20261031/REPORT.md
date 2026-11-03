# Isolated Maps-focus candidate prepared after rollback

## 1. Files inspected

PROJECT-RULES.md; AGENTS.md; rollback REPORT.md, NEXT-TEST.md, candidate.json, rollback-result.json, verification.json; Maps-only candidate.json, REPORT.md, before.json, exact-source.diff, host-test-result.json, compiled-and-preparation-verification.json, NEXT-TEST.md and Test-NavigationFocus.ps1. Preparation read the 27 Java inputs and preserved corrected GalReceiver source, and hashed the pinned artifacts/guards without opening credential entries.

## 2. Files changed

Only production file changed: analysis/parallel-aa-receiver/src/com/google/android/projection/protocol/GalReceiver.java. Restored its existing, verified Maps-only implementation from the saved archive. Added this directory's scope, preparation, candidate metadata, baseline source backup, host fixture/results, verification, next-test instructions and report. No APK rebuilt or installed.

## 3. Commands run

Read-only Get-Content, Get-ChildItem and rg inspections; apply_patch for scoped preparation/documents; pwsh -File analysis/test-prep/one-change-nav-focus-20261031/Prepare-Offline.ps1. The saved procedure checked baseline hashes, copied the one verified source, ran the existing callback fixture through JDK javac/java, verified source inventory and artifact preservation, and wrote concise results. No device/Git commands or delegated agents.

## 4. Tests run and results

Preparation exit code 0: PASS. Current effective Java inventory equals all 27 recorded Maps-only inputs. Candidate metadata differs from the rollback in exactly one Java input; 26 inputs are identical. Ten callback cases passed against the current real Java callback with only its native reply endpoint replaced by a recorder. Both pinned APK hashes match. All 18 preserved artifacts and six shared guards match their pre-existing preservation records. These are offline checks; hardware outcome UNKNOWN.

## 5. Findings

The existing 21037DC393FCD162499589254D745DD0904A326BD7E5A33D69CF3FC69BFA4084 APK can be reused without rebuilding. Its source is now the selected current source. The isolated behavior change is request-dependent navigation-focus replies, with validation/logging within that callback. Media keys, volume HUD and touchpad modifications remain absent. The user reported successful Diagnostics access after the D1A29 rollback; that is user observation, not an independently collected launch log. The successful comparison left the helper stopped, whereas the earlier failed run was armed; these states must not be conflated.

## 6. Primary evidence for each finding

This directory's verification.json records exact source inventory, changed input, 10 host cases, pinned APK hashes and preservation counts. host-test-result.json and host-fixture/test-output.txt record callback behavior; candidate.json pins the selected existing artifact. GalReceiver.baseline.txt preserves the prior source. Canonical exact callback diff and compiled-class/public-entry isolation evidence remain under analysis/test-prep/maps-nav-focus-20261031/; do not duplicate them. Rollback retry-20261031-220228/baseline-install.json records helperAbsent=true and helperArmed=false at installation; it is not a post-test state assertion.

## 7. Assumptions

The user's instruction to continue one change at a time authorizes preparing the already isolated Maps correction within the current regression scope. It does not override AGENTS.md's device prohibition or authorize new milestone work. The first live comparison should preserve the stopped-helper baseline condition.

## 8. Unresolved uncertainties

Root cause of the earlier Diagnostics failure remains UNKNOWN. Reinstallation/transient OEM state, helper activation and permission-clicker lifecycle remain confounders. Whether the focus correction prevents route cancellation is UNKNOWN. Host fixtures do not validate native execution or phone acceptance. Current device state was not queried. Full APK audit remains PENDING in the historical candidate record. No install-ready replacement for the baseline-pinned installer was generated.

## 9. Exact diff summary

One production method restored to the existing Maps-only implementation: +10/-1 lines relative to baseline, using the preserved original bytes. Other 26 recorded Java inputs unchanged. Added only scoped offline preparation/evidence/documents. No build/latest pointer, manifest, native library, input handler, service, volume code or historical report change.

## 10. Preservation checks performed

All 18 prior/frozen artifacts and six shared guard/runner hashes verified before and after the source change. D1A29 baseline and 21037 candidate APKs verified. Baseline GalReceiver backup hash matches the rollback record; corrected source hash matches candidate metadata. Newer source archive was read/copied but not edited. No credential content read, frozen rebuild, guard bypass, device command, milestone advancement or Git publication.
