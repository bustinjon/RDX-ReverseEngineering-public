# T240 pre-run verification scope

Task: verify the existing T240 before the operator runs it. Read application/package/tooling as needed; create only this review's scripts, fake fixtures, logs and report. No application, APK, test spec, launcher, original test/evidence, shared tool, private material, Git or device changes. No rebuild, install, agent call or milestone operation.

Acceptance: independently check actual APK integrity/signature/alignment/manifest, all recorded source snapshots and tested DEX identity; inspect generated entry points and readiness path; run existing service checks plus adversarial bootstrap timing checks against the exact production classes represented by the APK. State limitations and any blockers. Preserve hashes of the bundle, launch files, host baseline and frozen anchors.
