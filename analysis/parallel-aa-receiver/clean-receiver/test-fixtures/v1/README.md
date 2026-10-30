# Golden protocol fixtures v1

28 host-only fixtures. Each `.bin` has matching `.json` metadata: purpose, encoded bytes, expected decoded representation, SHA256, byte length and provenance. `manifest.json` aggregates metadata; `cases.tsv` is the dependency-free Java test index. No credentials or private Honda identity is included.

Generated once with `scripts/New-RdxProtocolGoldenFixtures.ps1`, using manually derived bytes and simple PowerShell binary authoring. That script does **not** invoke the production Java parser/writer and refuses to overwrite an existing v1 directory. New golden revisions should use a new version directory rather than changing v1 expectations to accommodate a failing implementation.

Kinds distinguish structural envelope acceptance (`frame`) from complete logical-message acceptance (`wire`). FIRST/middle/LAST are structurally valid individually; an unfinished or unexpected sequence fails the logical layer. Zero-body envelope is structurally accepted but is not a valid complete typed AA message. ENCRYPTED fixture is opaque fake bytes; no decryption occurs. Maximum body fixture is exactly16384 bytes; over-limit header16385 must fail before body allocation.

Video fields have independent literal vectors:

* Conservative: `080210011800202028e501` → nominal1280x720, margins0/32, DPI229, FPS60; active1280x688.
* Fullscreen opt-in: `08031002180020e80228e501` → nominal1920x1080, margins0/360, DPI229, FPS30; active1920x720.

Both retain placement **UNSPECIFIED**. No180px split, touch offset, encoded raster or phone acceptance is implied. Touchpad fixture independently preserves1325x720/60x40mm/navigation+absolute.

Reference sources are pinned in `../../PROVENANCE.md` and `../../fixtures/PROVENANCE.md`: AASDK framing, Honda Protos.java and corroborating OHU/OAA schemas. FPS60=1/30=2 and ZigZag priority deliberately follow Honda/OHU/OAA rather than conflicting pinned AASDK schemas. `capture-open` is the public OAA OEM VW capture seq4's protobuf payload; its BE16 type is removed and no absent outer header is invented.

ReferenceWireOracle is a separate **host-test-only batch DataInputStream/DataOutputStream implementation**. It imports no production frame classes/constants/codec and uses its own batch cursor/TreeMap/ByteArrayOutputStream state. Production parser is incremental/exact-reservation. Tests compare both representations, generated logical messages and production writer bytes. Agreement validates implementation against an independent local oracle, not the reverse-engineered specification against a real phone.

SHA/metadata and literals are verified by host tests and the final validation script. Unknown supported-wire protobuf fields retain raw bytes without gaining meaning or becoming executable. This fixture version is pure data, not an external transport/session.
