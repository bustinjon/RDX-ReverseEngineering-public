# Independent fixture inventory

Executable literal bytes live in `tests/com/rdx/fullscreen/clean/IndependentFixtures.java`. They are **not generated with AaFrameWriter/ProtoWire**. Writer/parser randomized roundtrips form a separate test family.

## Manually derived outer-envelope fixtures

Header layout is independently cross-checked in AASDK FrameHeader.cpp/FrameSize.cpp and FrameType/EncryptionType/MessageType headers, plus OHU AapMessage.kt and reassembly code. Tags: FIRST=1, LAST=2, CONTROL=4, ENCRYPTED=8. Extended length is present only for FIRST without LAST, is BE32, and is not included in the BE16 body count. Unfragmented complete=3; flags0/2 are valid structural continuation forms. CONTROL is not required simply because channel=0.

| Literal | Origin/expected meaning |
|---|---|
| VERSION `00030006000100010001` | Manually derived outer header plus BE16 type1, raw major1/minor1; not protobuf, not captured wire |
| DATA `0203000480000800` | Channel2 complete plaintext, type0x8000, 2-byte synthetic protobuf-like body |
| FIRST `0201000200000005000b` | Channel2 first body2, total plaintext5, type0x000b |
| MIDDLE `0200000108` | Channel2 one-byte continuation; no independent type |
| LAST `020200029601` | Last continuation completes `000b089601` |
| INTERLEAVED | Hand-authored channel2 and7 fragmented messages, completion order preserved independently |
| EMPTY `02030000` | Structurally empty envelope; invalid complete typed message in our policy |
| MAX_EIGHT / OVER_EIGHT | 8-byte configured body maximum and9-byte rejection; additional tests exercise actual16384 policy |
| RESERVED `001300020001` | Reserved flags bit4 must fail |
| UNKNOWN_CHANNEL `63030002000b` | Structural parser accepts channel99; registry-aware core rejects unregistered channel |
| CONTROL_FLAG `00070004000b0801` | CONTROL independent of FIRST/LAST |
| OPAQUE_ENCRYPTED `000b0003999897` | Opaque fake ciphertext envelope; assembler refuses plaintext interpretation |

Partial headers/extensions are prefixes of the literal FIRST fixture. Configured maxima and malformed sequences are hand-derived constructions. A zero-body continuation is structurally accepted; its usefulness/phone generation is unproved.

## Independently derived protobuf fixtures

Honda Protos.java field constants/serialization, corroborated by pinned OHU/OAA schemas, yield:

* Conservative: `08 02 10 01 18 00 20 20 28 e5 01`: resolution2, FPS1=60, widthMargin0, heightMargin32, DPI229.
* Fullscreen: `08 03 10 02 18 00 20 e8 02 28 e5 01`: resolution3, FPS2=30, widthMargin0, heightMargin360, DPI229. No placement/crop/touch offset field is invented.
* Touchpad: `08 ad 0a 10 d0 05 18 01 20 3c 28 28 30 01`:1325×720, navigation true,60×40mm, absolute true.
* Complete DISCOVERY literal: hand-counted nested lengths, service2/video and service7/input, tiny synthetic identity strings P/M/Y/H/U/B/V. Decoder must recover those service/capability values.
* ENCODED_DISCOVERY: same hand-counted services with explicit synthetic encoder identity (RDX research/Offline core/2021/empty serial/Independent/Pure Java/offline/0.3-protocol). Full encoder byte equality is checked, not merely roundtrip equality.
* Ping150=`08 96 01`; status0=`08 00`; priority-1/service7=`08 01 10 07`; request P/B=`22 01 50 2a 01 42`; stop reason1=`08 01`. Malformed/unknown/boundary variants are separate tests.

## Three public captured plaintext excerpts

Source: pinned OAA `captures/oem-vw-mib3oi-2026-04-06/messages.jsonl` and its README. Upstream describes an on-phone post-decryption/pre-encryption hook. **No outer channel, flags, TLS record, USB packet or handshake is captured there.** Do not reconstruct those absent fields as an observed packet.

| seq | type | Plaintext bytes, including BE16 type |
|---|---|---|
|4|7|`000708001001`|
|58|11|`000b08e7c9dccace6a1000`|
|59|12|`000c08e7c9dccace6a`|

Extraction respects `payload_len`; the base64 backing data can contain trailing padding bytes beyond that declared length. Request field2 in seq58 is unknown to our minimum ping model and is ignored; timestamp is preserved into seq59. Sequence4 proves zero-priority/service1 bytes but does not disambiguate ZigZag versus int32. No vehicle identity, media payload, credential or key was imported into tests.

`scripts/Validate-RdxProtocolCore.ps1` independently rereads the original first59 JSON lines and compares these three literals; `protocol-core-session/capture-fixture-validation.json` records results. Reference source hashes are recorded separately. This is public non-RDX evidence and does not prove compatibility with our phone/head unit.
