# Protocol field confidence — host validation continuation

CONFIRMED means corroborated in the pinned local Honda/generated or public reference code; it does not mean captured from our future clean receiver. STRONGLY INFERRED describes interpretation supported by static call chains/reference behavior. UNKNOWN/PASSTHROUGH is retained as data where supported, never assigned invented meaning. See PROVENANCE.md for exact pinned roots, conflicts and license boundaries.

| Structure/field | Classification | Meaning and limit of evidence |
|---|---|---|
|Outer channel u8, flags u8, BE16 body bytes|CONFIRMED|AASDK FrameHeader/FrameSize and OHU framing agree. Transport reads do not delimit messages.|
|FIRST1, LAST2, CONTROL4, ENCRYPTED8|CONFIRMED|Separate bit meanings. CONTROL is not inferred from channel0. Other bits rejected by current subset.|
|FIRST-without-LAST extra BE32 total|CONFIRMED|Header count excludes4-byte total; plaintext logical total modeled only after future decryption. Ciphertext/TLS record association remains UNKNOWN.|
|BE16 message type before payload|CONFIRMED|Continuation bytes need not begin with another type.|
|Version major/minor and response status BE16|CONFIRMED|Base raw layout; no protobuf assumption. Real acceptable version range/optional suffix policy UNKNOWN. Current1.1 is synthetic model policy.|
|AuthComplete/status field1 scalar|CONFIRMED|HU notification after handshake; required0/1 subset. Broader status enums unsupported.|
|Ping timestamp1 int64|CONFIRMED|Wire and captured echo corroborated. Other ping fields UNKNOWN/PASSTHROUGH; automatic echo of unknown fields is not permitted by this library.|
|OpenRequest priority1 sint32; service ID2 int32|CONFIRMED for Honda/OHU/OAA|Pinned AASDK contradicts sint32 with int32. ZigZag chosen explicitly; negative tests distinguish encodings.|
|Discovery request phone_name4/brand5 strings|CONFIRMED|Known strict subset; other logos/features UNKNOWN/PASSTHROUGH. Modern optional/required presence can differ.|
|Discovery response repeated services1|CONFIRMED|Service descriptor1 ID; video service3; input service4. Control0 is implicit, not advertised as service.|
|Service ID↔outer channel binding|STRONGLY INFERRED identity mapping in references|Registry stores both identities explicitly. Arbitrary remapping in synthetic tests is not a proven phone feature.|
|Response identity strings2..5,7..10; driver enum6; native-media/VR bool11|CONFIRMED layouts|New encoder uses labeled synthetic values, no VIN/hardware lookup. Pinned old AASDK field6 boolean description conflicts with enum references. Unknown extensions remain raw.|
|MediaSink available_type1 value3|CONFIRMED|H264 baseline enum. No alternative codec is silently selected.|
|MediaSink repeated video_configs4|CONFIRMED|Bounded list, order retained; selected configuration index handling remains a later media protocol task.|
|VideoConfig resolution1:2=720p,3=1080p|CONFIRMED|Nominal1280x720/1920x1080. No dedicated1920x720 enum invented.|
|VideoConfig frame_rate2:1=60,2=30|CONFIRMED for Honda/OHU/OAA|Pinned AASDK has reversed values; conflict retained, not silently reconciled.|
|VideoConfig margin_width3, margin_height4, density5|CONFIRMED tags/types|Conservative0/32/229; experimental0/360/229. Encoder/decoder literal fixtures independent.|
|Active dimensions = nominal minus margins|STRONGLY INFERRED for phone behavior; confirmed local Honda callback arithmetic|Does not establish H264 SPS dimensions, coded padding, decoder crop, active placement, top/bottom split or touch offset.|
|Video depth/viewing-distance/aspect/real-density extensions6..9|UNKNOWN/PASSTHROUGH in this subset|Known names from references are not a reason to invent values. Raw representation retained, new advertisement omits them.|
|InputSource touchpad3, TouchPad width1/height2|CONFIRMED|Independent logical geometry1325x720 remains configurable; not changed by video profile.|
|TouchPad navigation3, physical width4/height5, absolute6|CONFIRMED tags/values; physical units STRONGLY INFERRED reference mm|60x40mm reference, navigation/absolute true. Does not prove future TTI coordinate transforms.|
|TouchPad tap7/sensitivity8 and other extensions|UNKNOWN/PASSTHROUGH|No synthesized values or final fullscreen input mapping.|
|Shutdown reason1; response empty|CONFIRMED supported subset|Pure session-stop model only, not an Android reboot/shutdown action.|
|ChannelClose9 payload; media/focus/ack/input-binding progression|UNKNOWN / not implemented|Explicitly rejected/not advertised rather than invented. Further independent fixtures/reference review required before M7.|

## Passthrough rules

ProtoWire.Message.encoded() now preserves exact input bytes for supported wire0/1/2/5, including unknown field tags, order, duplicates and nonminimal accepted varints. Field.encoded() returns a defensive copy. unknownFields(knownNumbers...) returns unknown raw fields only. No raw field executes code or dispatches a service.

DiscoveryCodec.Decoded.originalEncoding() preserves the original complete, validated advertisement, including nested unknown descriptors/configuration fields. It is an immutable inspection view, not an editable reconfiguration. Creating a fresh advertisement from typed VideoConfig/InputConfig still intentionally emits only understood fields. Typed control models still normalize/drop unknowns; callers needing lossless inspection must retain the generic ProtoWire.Message. A response is deliberately constructed from approved known fields rather than blindly forwarding a request's unknown extensions.

Groups/wire3/4, invalid wire6/7, excessive lengths/fields and unsupported known enums are rejected, not passed through. This is a bounded supported subset rather than universal protobuf compatibility. Crop placement remains UNSPECIFIED throughout.
