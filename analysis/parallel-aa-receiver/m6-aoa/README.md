# M6 AOA-only offline package

**LIVE DISABLED. Next LIVE M5 RETRY ONLY.** [Frozen record](../M6-AOA-FROZEN.md), [validation](../M6-OFFLINE-VALIDATION.md), [permission strategy](../M5-M6-USB-PERMISSION-STRATEGY.md), [future checklist](../M6-FUTURE-LIVE-CHECKLIST.md).

Nine Java7 modules: immutable request/device types, signed M5 evidence gate, fsync/hash-chain journal,19-state event core and blocked Android glue. Host-only fake USB, fixed50k corpus and independent request/device/evidence expectations are separate from the APK. The frozen APK contains zero permissions, one explicit test Service and no AA/GAL/TLS/decoder/claim/bulk/reset path.

`scripts/Build-RdxM6Aoa.ps1` builds **only disabled** releases and runs host tests/static API22 audit. `Freeze-RdxM6Aoa.ps1` compares two fresh payloads and refuses overwrite. `FROZEN.json`/reproducibility.json are authoritative; do not rebuild frozen M5 or edit FINAL in place.

Proof schema: proof-schema.json; canonical13 LF lines plus detached RSA signature and compact reviewed evidence ZIP. APK assets contain only the public project reviewer certificate. No Honda or private review/TLS key is embedded. Host tests use a separate ephemeral key and synthetic evidence; no real reviewed M5 PASS exists.
