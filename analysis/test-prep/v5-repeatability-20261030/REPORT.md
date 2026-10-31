# V5 repeatability test preparation

Prepared three independent, bounded attempts using unchanged known-working v5. See [TEST-PLAN.md](TEST-PLAN.md). No live test or device command run.

## 1. Files inspected

PROJECT-RULES.md; scripts/Run-CarTest.ps1; prior pad-select NEXT-TEST.md and validation.json; successful v5 run `analysis/test-prep/runs/helper_20261030T230138_7ab757e6aae544d4b459621dc6365130/RESULTS.json`; current v5 APK/build provenance through the existing artifact planner.

## 2. Files changed

New TEST-PLAN.md, RESULTS-TEMPLATE.json, PREPARATION.json and this report in this directory. Three generated offline artifact plans are listed in PREPARATION.json. No production source, existing script, private/public APK, public repository or historical report changed.

## 3. Commands run

Local Get-Content/Get-FileHash; parse result template; three sequential calls to the existing Run-CarTest script in **Prepare** mode with CurrentSource, PhonePreference, the configured phone, 120-second window and deliberately nonexistent ADB path. Existing planner verified recorded Java input hashes against current sources. No live wrapper or device loop added.

## 4. Tests run and results

PASS: known-working APK hash matched; each of three artifact plans reports 25 sources, zero differences and LiveReadiness=NOT_ESTABLISHED. StaticAudit remains PENDING. Result template parsed and has three unrun attempts. All four frozen anchors matched. No application/runtime checks were repeated because no application or tool code changed.

## 5. Findings

The requested test can use the proven v5 bytes unchanged. Attempt 1 samples center/side input and media; attempt 2 repeats connection, samples top/bottom input and observes unplug during playback; attempt 3 observes physical HOME and any already existing return path. Each attempt requires fresh readiness, evidence retrieval and cleanup verification. These independently prepared runs do not establish unattended reconnect.

## 6. Primary evidence

PREPARATION.json contains actual APK SHA-256 `98E6A0015F249960B7730F210FAFB46BDFDAFE7A31686478FD619A930C3831A4`, each prepared directory, source comparison counts and frozen-anchor checks. The previous v5 RESULTS.json records operator success, nine paired select-key sends, PCM counters and verified cleanup. TEST-PLAN.md specifies complete READY instructions and bounded evidence criteria; it is a plan, not live evidence.

## 7. Assumptions

Same head unit/phone and per-phone Honda disabled preference, fixed audio configuration and ordinary test track. These must be rechecked or recorded for the specific attempt. Only existing UI controls are used; no AA return tile is assumed to exist.

## 8. Unresolved uncertainties

Repeatability, sampled input accuracy, Home foreground behavior, available AA return path, input leakage and disconnect audio cleanup remain UNKNOWN until observed. Exhaustive coordinates, ignition, camera overlays, longer sessions, voice, calls and steering-wheel mapping remain outside this preparation. A post-cleanup Home snapshot cannot prove in-session Home behavior. No new live readiness or authorization is asserted.

## 9. Exact diff summary

Add a three-attempt procedure, explicit full phone-connection prompts, per-attempt result template initialized NOT_RUN/UNKNOWN, offline preparation provenance and preservation records. Keep raw pad versus video coordinates distinct. Preserve the 120-second watchdog and existing helper runner without changes. No new APK required.

## 10. Preservation checks

Original working v5 SHA-256 and 25-source provenance matched. All four frozen artifacts match their canonical hashes. No ADB, keys/credentials read, Git mutation, public push, factory modification, readiness bypass or milestone advancement.
