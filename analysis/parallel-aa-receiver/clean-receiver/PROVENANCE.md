# Protocol-core provenance — 2026-10-23

This revision is independently authored Java and synthetic tests. No upstream implementation file, generated protobuf class, credentials, certificate or private key was copied into the library. This is **not a formal clean-room separation**: public schemas, source behavior and the existing Honda decompilation were consulted. Protocol facts and small test vectors are distinguished below from implementation code. No claim is made that consulting a GPL/AGPL source eliminates downstream licensing questions. Review distribution obligations before incorporating upstream code or publishing a combined receiver.

## Pinned local references

All references were already present locally; no download or network access was needed in this session. SHA-256 inventory: `protocol-core-session/reference-hashes.json`.

| Reference | Local root relative to analysis/parallel-aa-receiver/offline-followup/public | Use | License/context |
|---|---|---|---|
| Open Headunit e9377ff | open-headunit/andreknieriem-open-headunit-e9377ff | control.proto/media.proto/input.proto, AapMessage/AapTlsWriter, fragmentation behavior | AGPLv3 as checked in; behavioral/schema reference only |
| AASDK 046b3b3 | aasdk/f1xpl-aasdk-046b3b3 | FrameHeader/FrameSize/MessageInStream/MessageOutStream, enum constants, control send direction, schema comparison | GPLv3-or-later headers; no C++/generated implementation imported |
| Open Android Auto 61eab61 | open-android-auto/mrmees-open-android-auto-61eab61 | proto definitions, touchpad extension, public OEM plaintext capture | GPLv3-or-later schema headers; capture provenance is upstream's claim, not our vehicle observation |
| Current Honda APK decompilation | decompiled/AndroidAuto-current/sources/com/google/android/projection/proto/Protos.java | field tags, required presence, enum values, ZigZag priority, touchpad dimensions/flags | Proprietary artifact already preserved locally; no generated implementation imported |
| Pulled D.1.6.4 platform | adb/RDX-Audit/framework/core-libart.jar and framework.jar | resolve actual DEX method definitions/inheritance for API compatibility | Read-only static inspection, hashes in validation.json |

## Explicit conflicts and decisions

1. **FPS enum conflict:** AASDK `VideoFPSEnum.proto` says 30=1/60=2. Honda `VideoFrameRateType` says **60=1/30=2**; Open Headunit control.proto and OAA video schema agree with Honda. New codec uses Honda's values. This is a recorded reference conflict, not a universal verdict about every AASDK version. A phone trace or independently decoded service-discovery message would validate actual future interoperation.
2. **Channel-open priority conflict:** AASDK's pinned proto calls field1 `int32`; Honda `ChannelOpenRequest.writeTo` explicitly calls `writeSInt32`, and Open Headunit/OAA say `sint32`. New codec uses ZigZag. Negative/extreme cases are tested. Captured zero alone cannot distinguish the two encodings.
3. **Driver position:** legacy AASDK calls field6 a left-hand-drive boolean; Honda/OHU/OAA describe a driver-position enum. New synthetic advertisement explicitly serializes 0 (left); decoder accepts 0..3. Do not translate a boolean without identifying its schema/version.
4. **Input descriptor:** AASDK/OHU's small TouchConfig contains only width/height. Honda TouchPad adds navigation3, physical width4/height5, absolute6. OAA corroborates those tags, while marking its own confidence limits. We serialize only the Honda-supported 1..6 subset; tap/sensitivity remain omitted.
5. **Authentication direction:** HU emits plaintext AuthComplete after TLS, then phone requests discovery. AASDK sendAuthComplete and OHU AapTransport corroborate this. The first local fake-conversation draft had the direction reversed; it was corrected before final validation. No live result relied on it.
6. **Ping encryption:** pinned AASDK sends some ping traffic plaintext; public application-data references can show encrypted paths. This library deliberately models plaintext at the post-TLS test seam and does not decide a real adapter's encryption policy.
7. **Service ID versus channel ID:** registry keeps them separate and supports synthetic non-identity mappings. The public capture and reference implementations typically use identity mappings. A synthetic 101→2 mapping tests lookup/isolation, **not proof that phones negotiate arbitrary channel remapping**. Future real transport must establish binding semantics; conservative identity mapping remains available explicitly.

## New code ownership and boundaries

ProtoWire is a small independently written protobuf wire subset, not protoc output. ControlMessages and DiscoveryCodec encode field-number/type facts from the above schemas. Java fixtures are manually authored literals; three payloads are tiny non-secret public capture excerpts. Tests do not derive all expectations from our writer. See `fixtures/PROVENANCE.md`.

There is no bundled upstream schema implementation/runtime, no new dependency license copied into an APK, no new receiver APK, and no real TLS adapter. AGPL/GPL implementation reuse remains a future explicit decision. This document records technical provenance, not legal clearance.

## 2026-10-23 independent batch-oracle continuation

ReferenceWireOracle and IndependentValidationTests are newly authored host-only code; no upstream implementation copied. Oracle uses standard Java DataInput/DataOutput batch parsing, separate record types/state and no production parser/writer/constants. New immutable test-fixtures/v1 data was authored with PowerShell literals based on the same pinned reference facts, including28 golden cases and a small already-documented public capture OpenRequest. Binary bytes, logical expectations, SHA256 and per-case provenance are recorded; no private identity/credentials.

This improves independence of implementation checks, not independence of the underlying reverse-engineered specification. Existing FPS/priority/driver/crop/channel-binding disagreements above remain. Supported protobuf wire bytes can now be retained losslessly; unknown fields remain UNKNOWN/PASSTHROUGH, not newly understood. [Field-confidence inventory](FIELD-CONFIDENCE.md) and [validation](OFFLINE-PROTOCOL-VALIDATION.md) describe scope. No new network download, upstream source edit, active transport or vehicle operation occurred.

## 2026-10-24 secure-body provenance

Outer header visibility, pre-encryption fragmentation,0x3F00 plaintext fragment threshold, shared body SSL wrapper and plaintext post-handshake AuthResponse derive from the saved Honda native trace described in TLS-NATIVE-EVIDENCE-INVENTORY.md. No native library executed. Local AASDK/OpenHeadunit/OpenAndroidAuto files were used for prior behavioral cross-checks only. No GPL/AGPL implementation code copied.

OuterFrameContext/RawAaFrame/DecryptedAaFragment/SecureBodyAdapter/SyntheticTlsState/SecureBodyPipeline/SecureStartupPolicy/SecureSessionSimulation are project-authored clean implementation. Prefix0xA5 fake expansion and independent SecureBodyOracle are HOST SIMULATION conventions with NO claim of TLS ciphertext format. Test fixtures secure-body-v1 are manually specified bytes and scenario metadata; originals are not generated with production codecs. Original six MP4 files and94 prior fixtures were preserved; MP4 sample->AU and AnnexB interpretation remain explicit existing host policies.

Conservative underflow rejection, bounded drain iteration256, ciphertext65535, plaintext16128, message1MiB,2active fragmented channels and2MiB reassembly reservation are local robustness policies, not negotiated phone limits or proof of Honda recovery. Native rekey/close/underflow ambiguity remains unresolved.
# 2026-10-24 host real TLS implementation

MemoryTlsEngine/TlsPumpResults/TlsRecordLedger/RealTlsBodyAdapter are clean project implementations of the saved adapter design using public Java SSL APIs. No Honda JNI, Open Headunit implementation, OpenSSL source or Conscrypt implementation was copied. Saved native/platform traces inform constraints only. SunJSSE executes on the host with newly generated disposable certificates; no protocol credentials are included in production artifacts. Five visible-record malformed fixtures are manually authored independent expectations, not real authenticated ciphertext. TLS provider/library licensing is not inferred from a public protocol schema.

