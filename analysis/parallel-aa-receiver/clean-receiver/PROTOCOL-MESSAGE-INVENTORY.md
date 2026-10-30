# Minimum session inventory and implemented subset

All code here is pure local data/byte-array machinery. No message is sent to a device. A fake transcript does not prove that omitted services suffice for a real phone.

| Stage/message | Initial-session classification | Implemented payload/direction |
|---|---|---|
|Version request1 / response2|Required to begin negotiation|Raw BE16 major/minor, response adds status. Exact base4/6-byte payload; optional version suffix rejected/deferred. Fake policy uses1.1 only, not a negotiated production default.|
|Encapsulated TLS3|Required for real protocol authentication|Boundary inventoried, no handshake bytes/credentials/crypto implementation. TlsAdapter production default throws.|
|AuthComplete4|Required local completion signal|Required status field1; HU→phone plaintext after TLS. Explicit pure emit method, no automatic handshake.|
|Discovery request5|Required|Phone name4/brand5 required in strict subset, parse/encode. Extra image/features ignored as unknown fields within caps.|
|Discovery response6|Required|Repeated service descriptors1, identity fields2..11, video service3, input service4. Video config resolution/FPS/margins/density1..5; touchpad1..6. Encode/decode. Synthetic identity only.|
|Channel open7 / response8|Required for selected services|Priority1 ZigZag, service ID2; required status1 response. Registry mapping explicit. Fake accepts requests on modeled service channel. Real remapping semantics remain unproved.|
|Channel close9|Unknown exact payload/lifecycle requirements|Type inventoried; no fabricated payload codec. Not required to construct initial discovery fixture. Core rejects unsupported message.|
|Ping11/12|Likely required for sustained session|Required int64 timestamp1, unknown extras ignored. Fake echo only after auth state. Timer, timeout policy and encryption choice deferred.|
|Shutdown15/16|Orderly termination|Reason1..5 field1; empty response. Local stop states, no device shutdown operation.|
|Video setup/start/config/ack/stop0x8000..0x8004|Required before actual video, beyond present handshake model|Schemas inventoried from media.proto/AASDK; no wire-media parser yet. Pure VideoProtocolBoundary supports explicit open/select/access-unit callback/backpressure/ack/stop. It does not fabricate media acknowledgment bytes.|
|Video focus, input binding|Likely required before usable video/input; needs reference/session validation|Inventoried, not serialized. No claims READY means streaming.|
|Audio/microphone/assistant/sensors/navigation/phone/Bluetooth/HUD|Optional later candidates, not proved dispensable to all phones|Not advertised, stubbed or started. Unknown service kinds can be parsed as IDs and ignored by discovery inspector; known unsupported codecs are rejected.|

Control channel0 is implicit, never advertised as another service or allocated from the registry. Minimal advertisements contain VIDEO and optionally INPUT only. Input width/height are independent of video nominal/active dimensions. There is no final fullscreen touch mapping.

ProtoWire supports wire types0/1/2/5, unknown-field skipping/discard, last singular occurrence, bounded strings and repeated fields. Groups are deliberately rejected; unknown fields are not preserved on reserialization. Required fields in implemented message models are checked; unknown enum values and unexpected known-field wire types fail. This strict subset is not a drop-in general protobuf runtime. Input optional fields in Honda's broader schema are required by our **fully configured touchpad subset**, rather than defaulted silently.

DiscoveryCodec recognizes only supported720p/1080p nominal video and FPS30/60. Newer codec/dimension extensions are not accepted automatically. It serializes no audio, sensors, private vehicle IDs, real credentials, depth/aspect extensions or invented input offsets. Driver position explicitly0; metadata is labeled synthetic. Actual private stock credentials remain outside this codebase.
