# RDX standalone geometry grid

com.rdx.fullscreen.gridtest 0.1.0-grid. Source/manifest under this directory. Java-only/no permissions. Build, signer, hash and independent-audit evidence are linked in [matrix](../BUILD-VALIDATION-MATRIX.md). The APK only measures/renders geometry and contains no global display mutation. [Separate geometry procedure](../FULLSCREEN-SURFACE-TEST.md) includes known Honda Activity lifecycle effects. Not part of the next M4 phone observation.

Host build: `scripts/Build-RdxBoundedHarness.ps1 -Harness grid-test`; audit: `scripts/Audit-RdxBoundedHarness.ps1 -Harness grid-test`. No ADB or installation in either script.
