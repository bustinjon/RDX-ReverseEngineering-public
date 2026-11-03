# Maps-only candidate installed — 2026-10-31

## 1. Files inspected

PROJECT-RULES.md; prior proven Install-BaselineOnly.ps1; this directory's candidate metadata, offline verification and installer provenance; retry-20261031-222126/baseline-install.json and comparison-latest.json. Installer checked current production hashes, target identity, firmware, mandatory readiness, accessibility and own-package state.

## 2. Files changed

Added INSTALL-SCOPE.md, Generate-Installer.ps1, Install-CandidateOnly.ps1, installer-provenance.json, this report and installation evidence. On the head unit, replaced the helper package with the pinned Maps-only APK using install -r and left the package stopped. No production source change this installation turn.

## 3. Commands run

Read-only project/script inspection; pwsh -File analysis/test-prep/one-change-nav-focus-20261031/Generate-Installer.ps1; pwsh -File analysis/test-prep/one-change-nav-focus-20261031/Install-CandidateOnly.ps1. The install-only procedure's exact ADB operations/output are journaled in retry-20261031-222126/commands.jsonl. User explicitly authorized this installation after the earlier device prohibition; authorization is recorded in INSTALL-SCOPE.md.

## 4. Tests run and results

Generator syntax/equivalence check PASS. Installer exit code 0. CurrentSource artifact checks and required firmware/lock-task checks PASS. Install confirmed Success. Pulled installed APK SHA-256 equals 21037DC393FCD162499589254D745DD0904A326BD7E5A33D69CF3FC69BFA4084. Helper services/process absent at completion, accessibility unchanged. Manual Diagnostics and Maps runtime tests remain PENDING.

## 5. Findings

The selected one-change Maps-focus candidate is installed and verified. Helper/auto-clicker remain stopped; receiver was not armed. This matches the stopped-helper condition of the successful rollback comparison. It does not reproduce the previous armed-helper failure condition.

## 6. Primary evidence for each finding

retry-20261031-222126/baseline-install.json records installed hash, helperAbsent=true, accessibilityUnchanged=true, helperArmed=false and phoneHandoffReady=false. install-output.txt confirms installation; installed-baseline.apk is the pulled candidate despite its inherited evidence filename. helper-after.txt and processes-after.txt hold the own-package snapshots. commands.jsonl, samples.json and artifact-plan.json record operations/checks. installer-provenance.json verifies that only the completion cue differs from the prior proven installer.

## 7. Assumptions

The explicit request "Install now" authorizes installation and verification only. User's Home report is accepted; only mandatory existing readiness observations were retained. Manual shortcut result must come from the next observation.

## 8. Unresolved uncertainties

Manual Diagnostics outcome, Maps route retention and the original failure's root cause are UNKNOWN. Installation may affect transient state. No claim is made about helper startup or native/phone acceptance of focus replies.

## 9. Exact diff summary

Generated installer differs from the proven parent only in one user-facing completion cue. Local candidate metadata supplies the Maps-only APK. No guard, production source, manifest, native library, OEM policy, accessibility setting or historical report edited. Device package replaced without package-data clear; own package force-stopped before and after install.

## 10. Preservation checks performed

CurrentSource checks verified the selected source/build record and pinned APK. Readiness code reused without bypass. Installation pulled/verifies the installed APK. No APK rebuilt, frozen artifact modified, credential read, additional milestone activated or Git command/publication performed. Offline 18-artifact/six-guard preservation results remain in verification.json; not represented as a fresh post-install rehash.
