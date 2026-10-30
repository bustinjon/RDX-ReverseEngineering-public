# API22 qualification file inventory — 2026-10-24

Run directory: `api22-qualification-20261024-155013-513/`. Exact file paths, sizes and SHA256 values are in `run-file-inventory.csv` there; `inventory-metadata.json` hashes that inventory. The inventory excludes its own CSV and metadata to avoid self-reference. It includes all final files under this run and its three fresh build directories, plus the explicitly created/modified project files below. Deleted disposable container paths/hashes are retained in test-credential-cleanup.json, not private key contents.

## Created project files

- `clean-receiver/API22-RUNTIME-INVENTORY.md`
- `clean-receiver/API22-TLS-RUNTIME-QUALIFICATION.md`
- `clean-receiver/API22-PROVIDER-DIFFERENTIAL.md`
- `clean-receiver/OFFLINE-FOUNDATION-STATUS.md`
- `clean-receiver/API22-PROVIDER-COVERAGE.csv`
- `clean-receiver/API22-QUALIFICATION-FILES.md`
- `clean-receiver/latest-api22-qualification.txt`
- `clean-receiver/tests/com/rdx/fullscreen/clean/Api22ProviderModelTests.java`
- `scripts/Review-RdxApi22Provider.ps1`
- `scripts/Validate-RdxApi22Qualification.ps1`

Paths beginning clean-receiver are relative to analysis/parallel-aa-receiver. Script paths are relative to the project root.

## Modified existing project files

- `scripts/Build-RdxCleanFoundation.ps1` — compile/run/report new host-only static model; no old tests removed.
- `clean-receiver/README.md`
- `analysis/parallel-aa-receiver/BUILD-VALIDATION-MATRIX.md`
- `clean-receiver/TLS-BACKEND-SELECTION.md`
- `clean-receiver/STATE-GUARANTEES.md`
- `clean-receiver/REAL-TLS-COVERAGE.csv` — explicit API22 runtime/static distinction added.
- `NOTES.md` — chronological entry only.
- `clean-receiver/latest-build.txt` — final clean build pointer.

Production source and all pre-existing test files are byte-for-byte unchanged. All69 historical APKs and M4/M5 reports are unchanged. No new APK, AVD, SDK image, provider binary, JNI wrapper or live-test report was created. LIVE-FOUNDATION-READINESS.md was not created because API22 did not pass a runtime test.

## Generated evidence/build directories

- `clean-receiver/api22-qualification-20261024-155013-513/` — original preservation snapshots; runtime inventory; saved Conscrypt DEX/disassembly and20 method excerpts;24-source-anchor table; hashes; desktop baseline/repeat; static-model output; cleanup; qualification result; exact commands and final file inventory.
- `clean-receiver/build/20261024-155015-221/` — pre-change baseline build.
- `clean-receiver/build/20261024-155830-693/` — first fresh build with model tests.
- `clean-receiver/build/20261024-160122-023/` — second fresh build with model tests.

The old generic real-TLS validator writes final-validation.json for the repeated **desktop** suite; qualification-final.json is the current task's authoritative verdict and includes static-model totals and zero Android runtime cases. Provider excerpts and source anchors are analysis outputs, not executed target code. No credential containers remain in the run directory.
