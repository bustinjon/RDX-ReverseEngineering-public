# M6 scaffold audit — 2026-10-25

Before this run M6 had no APK or active transfer adapter. The57-module clean receiver contained:

|File/class under clean-receiver/source/com/rdx/fullscreen/clean|Methods/behavior|
|---|---|
|AoaNegotiator|EXECUTION_ENABLED=false; planQuery/planIdentity/planStart and identificationBytes build metadata only. queryVersion/sendIdentity/start always throw.51/52/53,0xC0/0x40,zero wValue,indices0–5,UTF8-NUL and255-byte string policy.|
|AoaRequestPlan|Immutable metadata and cloned payload; no execution.|
|AndroidUsbTransport / UsbTransport|open/read/write throw; close inert. No openDevice/claim/transfer implementation.|
|AndroidUsbInventory / UsbInventory|Constructor stores supplied manager; explicit snapshot reads device inventory/hasPermission only.|
|UsbPermissionController|Interface contract only; M5 remains separate.|
|DeviceIdentity|Older path/VID/PID/permission observation, not a sufficient attachment-generation identity for active M6.|

FoundationTests already verifies request planning and disabled execution. All existing source/tests, old DEX, M5 artifacts,69 historical APKs and live reports remain unchanged. The old M6 documentation described documentation-only/not-ready status; it is retained with a current supersession pointer.

New standalone `m6-aoa/source/com/rdx/fullscreen/m6aoa/` has9 production modules, deliberately excluded from receiver DEX:

- AoaRequest: private opcode constructor; factories protocol/string/start; independent fixtures; identity validation.
- UsbIdentity: immutable VID/PID/id/path/generation/time/interface-summary/optional serial-hash observation. Production intentionally does not collect phone serial/manufacturer/product text.
- AndroidUsbEnvironment: inventory/permission/open/transfer/close and typed result boundary; no Android imports.
- M5PassProof: strict canonical schema, detached RSA review signature, exact M5 identity, counts/status and evidence-stream SHA256.
- M6Journal: bounded chained append/replay, file flush+fsync; no constructor I/O.
- M6Controller:19-state serialized AOA-only core; no Android imports, no AA/TLS/media path.
- LiveExecutionPolicy: EXECUTION_ENABLED=false; compiled gate always throws; no setter/override.
- AndroidAoaAdapter: future real51/52/53 glue, independently blocked before any inventory/permission/open/transfer action.
- M6AoaService: one explicit exported test Service; ARM is blocked before manager lookup, receiver registration or worker scheduling. No boot/manifest USB association.

Host-only M6Tests/Fake/Memory, M5ReviewProofTool and M6EvidenceTool are excluded from APK. No APK contains test private keys; only the public project reviewer certificate is packaged. No existing foundation execution flag changed. [Validation](M6-OFFLINE-VALIDATION.md), [freeze](M6-AOA-FROZEN.md).
