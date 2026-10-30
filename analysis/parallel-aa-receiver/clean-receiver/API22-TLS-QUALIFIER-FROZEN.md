# API22 TLS qualifier frozen — 2026-10-25

**STATIC APK PASS + DESKTOP HARNESS FUNCTIONAL PASS. NO ANDROID RUNTIME EXECUTION. NEVER INSTALL ON RDX/PHONE/PHYSICAL DEVICE.**

|Field|Frozen value|
|---|---|
|APK|`analysis/parallel-aa-receiver/api22-tls-qualifier/build/FINAL/rdx-api22-tls-qualifier.apk`|
|SHA256|86350131FFC5CBE5766E523AB03AE07D4C9F5EAD78F0570B68255C9A3999FC1F|
|Package/version/code|com.rdx.fullscreen.api22tls /0.3.0-final-offline-qualifier /3|
|minSdk/targetSdk|22/22|
|Signer SHA256|C001F59B25081DDFC73937155CA3580717E817C45C66E68B9E059737B0B28831 — independent development signer, not Honda|
|Permissions|ZERO, including no INTERNET/storage/USB/settings permissions|
|Component|One exported `.TlsQualificationActivity`; explicit action/fresh run id/API22 goldfish-ranchu gate|
|Flags|debuggable and testOnly; allowBackup=false; no boot receiver, service, intent filter or auto-start|
|DEX|031882097123710E60C34A56A9E6AC637EA9D4EA4865DA89071D688BDFFBDC06|
|Classes/references|97 DEX classes;220 external method references resolve in saved API22 definitions|
|Runtime|NOT RUN on any Android runtime; no install/cleanup claim|

Final source inputs are the two qualifier Java files plus a reviewed26-module pure foundation subset, not the whole receiver library. Host credential/MP4 exporters and host runner classes are excluded. The final DEX/manifest/string audit finds no USB enumeration/request/open/claim/transfer, AOA, Honda package/JNI/GAL, MediaCodec/Surface, socket/HTTP/WebView, Runtime.exec/ProcessBuilder/su, settings or WM mutation paths. Signature verifies for API22 v1 and alignment passes.

Two clean builds `20261025-123949-546` and `20261025-124329-839` have identical DEX, class/JAR-entry payloads, binary manifest and assets. APK container hashes differ through ZIP/signature container metadata; the SECOND APK is copied byte-for-byte into FINAL. [Machine freeze](../api22-tls-qualifier/FROZEN.json) and [payload comparison](../api22-tls-qualifier/qualifier-reproducibility.json) pin the exact result. FINAL is never overwritten automatically.

The same final core passes20 desktop functional groups: real in-memory TLS1.2/GCM/mutual test trust,7 negative trust cases, hostile handshakes, exact application sizes, underflow/overflow/accounting, record-completion observations, actual production adapter on SunJSSE, AA/control/media,500 mechanics +200 combined cases,240 opaque profile units and clean/abrupt close. This is **HARNESS FUNCTIONAL TEST ONLY**, not API22 provider evidence. No ciphertext golden bytes are stored.

Private results include schema-versioned JSON and per-case durable checkpoints. Close probes run last, so saved-provider close concerns do not erase preceding evidence. No output/empty buffer result automatically means PROVEN_QUIESCENT; AndroidOpenSSL's production profile remains unqualified. Comparator never silently promotes a runtime to A.

Assets contain clearly labelled PUBLIC TEST MATERIAL: disposable locally generated certificates and PKCS8 leaf keys. No CA private key, Honda identity, Honda key or phone credential is packaged. Public certificate SHA/subject/issuer/validity/SAN/key algorithm are recorded in `assets/test-credentials/PUBLIC-TEST-MATERIAL.txt`; hashes pin all build assets. Leaf validity must be checked when running later; do not suppress date checks.

After an isolated local API22 image becomes available, from project root:

[Code block omitted from public report; see authored source where available.]

Use the actual verified emulator serial. No physical ADB device may be present. Read [RUN-API22-QUALIFICATION-LATER.md](RUN-API22-QUALIFICATION-LATER.md) first. This command was not executed during the freeze.
