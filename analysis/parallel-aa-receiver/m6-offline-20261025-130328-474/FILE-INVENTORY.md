# M6 exact retained-file inventory — 2026-10-25

[FILE-INVENTORY.csv](FILE-INVENTORY.csv) records each retained created/modified session file with relative path, size, SHA256, category and reason. This covers the separate M6 project (including intermediate builds), both new receiver builds, session evidence and changed/new current documents/tools. Unchanged protected files are separately checked against the pre-session snapshots and [PROJECT-INTEGRITY.json](../PROJECT-INTEGRITY.json).

The CSV and SEAL.json exclude their own bytes to avoid circular hashes. SEAL.json pins the CSV and project-integrity manifest. This document is included in the CSV. Nine newly generated test PKCS12 containers were deleted before sealing; credential-cleanup.json records hashes and paths. No raw private test keys are in the inventory/report. Intermediate failure diagnostics are preserved; they are not final PASS artifacts.

The main receiver remains57 modules with unchanged DEX; M6 is a separate9-module disabled APK. No ADB/hardware or live task was executed. Next LIVE M5 RETRY ONLY; M6 LIVE-DISABLED; M7 NOT AUTHORIZED.
