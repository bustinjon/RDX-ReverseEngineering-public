# M5 permission-only retry0.2

**Built, independently audited and host-tested. READY for a separately authorized bounded M5 retry; not a live M5 PASS.** M4 PASS, prior M5 INCONCLUSIVE, M6 disabled. No device used during this revision.

Current artifact: build/20261023-180320-335/rdx-m5-permission-0.2.0-m5-single-port-300s-development.apk. SHA256 A22E96490B9557AFF022893A8B8B7A08BB13CEC236E52704CDDAFA90A8EE8F40. Package com.rdx.fullscreen.m5permission; code3/min21/target22; one headless .PermissionService; same development signer.

See [final APK audit](M5-RETRY-INDEPENDENT-AUDIT.md), [offline validation](../M5-RETRY-OFFLINE-VALIDATION.md), [operator procedure](../M5-USB-PERMISSION-TEST.md). Historical0.1.0/0.1.1 builds and live result remain preserved; previous source/manifest/plans under history/pre-0.2.0-300s/.

Production source: PermissionMachine (pure state model), PrivateJournal (own private-file persistence), PermissionService (explicit Android adapter). Constructor/installation alone never enumerates/requests.300000ms total monotonic bound; unique18D1:2D01/pinned path; one request max; all open/claim/transfer/AOA/GAL/media/native/shell/system APIs absent. Detach is terminal, not a reconnect trigger.

Private journals never automatically overwrite/clear. Same run_id refuses replay across Service/process recreation. Explicit LIST_RESULTS/DUMP_RESULTS log checksummed private evidence without any USB operation. Host converter verifies completeness/hash; retrieve before uninstall.8runs/64KiB each; full capacity refuses new arm.

Host reproduction from project root: scripts/Test-RdxM5Retry.ps1, Build-RdxBoundedHarness.ps1 -Harness m5-permission, Audit-RdxBoundedHarness.ps1 -Harness m5-permission, Validate-RdxM5Retry.ps1, Test-RdxM5Dump.ps1. Current56 deterministic assertions,9 timings,20000x120 seeded event steps (2400000 invariants),8dump cases PASS. See latest-* pointers for immutable evidence directories. New live retrieval/runtime remains unmeasured.

Five minutes would still have expired before the prior actual7min42sec connection; prepare phone/cable/USB-mode UI before arming and announce deadline. No implicit retry, M6 authorization or real-device compatibility claim follows from host tests.
