# Exact retained session file inventory

[file-inventory.csv](file-inventory.csv) lists each retained created/modified file with project-relative path, byte size, SHA256, category and reason. [file-inventory-seal.json](file-inventory-seal.json) pins the CSV hash, row count and bytes. This inventory covers the extended run beginning2026-10-25T05:50:31Z, including intermediate builds, preserved qualifier candidate, final binaries, scripts, source, reports, test assets and output logs.

Discovery uses the new session/qualifier/new receiver-build directory trees (including copied inputs whose file timestamps predate the run), plus changed files in bounded project-owned analysis/scripts/tools locations and NOTES/current-build pointers. No whole-project pre-run content snapshot was available; unchanged protected APK/live-report/source/test baselines are independently checked against the snapshots taken before work. New/modified timestamp identification is explicit rather than an invented Git diff.

The CSV and its own seal JSON are excluded from the CSV to avoid recursive self-hashing. They do not belong to PROJECT-INTEGRITY.json. [PROJECT-INTEGRITY.json](../PROJECT-INTEGRITY.json) independently pins current critical source/fixture/report/script inputs, frozen artifacts and69 historical APKs; it excludes itself. The integrity checker performs no automatic repair.

Deleted temporary working PKCS12 containers are recorded by path/hash in [working-credential-cleanup.json](working-credential-cleanup.json), not falsely listed as retained files. Public test PKCS8 leaf assets intentionally remain reproducible inputs; no private key content is printed here. Root private keys are not packaged. No secure-erasure claim is made.

Run from project root: `tools/Test-RdxOfflineIntegrity.ps1`. Its final positive and wrong-expected-hash negative self-tests are recorded under `final-tool-qa/`. The negative self-test changes only a disposable manifest copy; no frozen artifact is altered.
