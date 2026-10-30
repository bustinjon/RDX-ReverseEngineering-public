# Target media data review — 2026-10-23, LOCAL ONLY

No device operations. This review precedes the new data-plane implementation. Previous evidence reports and frozen artifacts are preserved. Native source: saved libautoreceiver_jni.so SHA256031797DD4B0AECCA007A3AD7AF31C365BA3D47BEBDA8C94BFF13C5289F464C50; exact disassembly from media-8000-evidence/ copied into the current video-data-session/native-media-dispatch.txt.

|ID|Meaning / direction / channel|Layout / action|Accounting/state evidence|Confidence|
|---|---|---|---|---|
|0000|Timestamped media, phone→HU video sink|MediaSinkBase::routeMessage C5504 dispatch C552C→C5606; bytes after BE16 type: BE64 timestamp then opaque media bytes. C5638/C5646 pass offset10 including type; C569E places timestamp in ARM argument registers; C56A2 calls data virtual slot+28.|VideoSink::handleDataAvailable C9E50 forwards stored session at object+18, original timestamp and payload after offset10 to callback. No per-packet sequence/index is parsed here.|CONFIRMED envelope/session association; AU boundary UNKNOWN|
|0001|Codec configuration, phone→HU video sink|routeMessage C5530–C553E passes all bytes after type to virtual slot+24; VideoSink::handleCodecConfig C9E86 forwards to callback.|Java VideoSink.codecConfigCallback→ProjectionListener→ProjectionActivity message3→ProjectionRenderer.handleCodecConfig. No timestamp/session parsed in0001.|CONFIRMED configuration role, bytes opaque|
|8001|Start, phone→HU video|Stored session plus configuration-index selection, as prior review.|Callback association supplies session for later0000. Exact first-data ordering not enforced by dispatcher.|CONFIRMED local handling; global order STRONGLY SUPPORTED|
|8003|Config, HU→phone video|READY2/WAIT1; max-unacked; allowed indices.|Window16 set by Java VideoSink.create. Sender enforcement is not visible in this receiver alone.|CONFIRMED fields; full credit algorithm UNKNOWN|
|8004|ACK accounting, HU→phone video|session_id + count; no unique packet token/ACK sequence field in target schema.|native ackFrames C5836; ProjectionActivity.onFrameRendered→ackFrames(session,1). See renderer caveats below.|CONFIRMED count/session; exact packet↔output accounting not proven|
|8002|Stop, phone→HU video|Native calls playbackStop with stored session.|Java callback empty; renderer lifecycle is also application-controlled. Do not infer native Stop automatically drains MediaCodec.|CONFIRMED callback; complete drain/restart semantics UNKNOWN|
|8008|Focus indication, HU→phone video|Conditional separate policy, prior review.|Not an AU/decoder readiness acknowledgment.|CONFIRMED family; peer prerequisites UNKNOWN|

The four-byte outer framing flags are not redefined here. Native dispatch operates on reassembled/decrypted service messages; neither0000 nor0001 is an AAP continuation marker. Existing FIRST/LAST fields perform protocol fragmentation. H264 NAL fragmentation and full access-unit grouping are separate matters.

## Java decoder/configuration evidence

decompiled/AndroidAuto-current/sources/com/google/android/projection/protocol/VideoSink.java creates VideoFrame(sessionId,timestamp,data). VideoFrame.java stores timestamp; it is not declared to be a wall clock. Honda native argument is uint64 (`y` mangling). Unit remains UNKNOWN for the target wire envelope; public projects suggest media microseconds but do not override target uncertainty.

Honda ProjectionRenderer.handleCodecConfig at roughlyline214 copies the bytes into a VideoFrame(0,0,buffer) and queues them; it does not parse SPS/PPS or construct CSD from avcC in this Java path. DecodeInputThread's first codec input uses flag2 (codec config). It can split a queued buffer across multiple decoder input buffers. It sets presentationTimeUs from System.currentTimeMillis()*1000 at approximatelyline412 and calls queueInputBuffer at425, NOT from VideoFrame.timestamp. Thus wire timestamp propagation to the target decoder is NOT identity mapping. The clean future contract must preserve wire bits and an independently explicit decoder presentation-time choice.

ACK caveat is stronger than the listener name suggests: ackFrame polls a queued-input FIFO then invokes onFrameRendered. It is called after output dequeue (before output release), on first codec-config handling, and after repeated input-dequeue failure. Because FIFO membership/timing is asynchronous, the Java code does not establish a one-to-one displayed-picture association. No exact mapping from an SPS/PPS config item to a session credit is proven. Do not automatically emit session0 config ACK as if it were a normal selected-session picture credit.

## Public corroboration and limits

Pinned AASDK src/Channel/AV/VideoServiceChannel.cpp at191–201 decodes sizeof(Timestamp::ValueType) prefix for timestamped data and forwards remaining bytes; the other media family forwards raw bytes. Honda narrows raw0001 to codec-config role via its virtual handler. Public generic 'media indication' naming alone must not replace the target configuration finding.

SPS/PPS/AnnexB payloads, one-protocol-message-per-AU, one-MP4-sample-per-protocol-message, and synthetic PTS microseconds are NOT established by the native envelope. The host source will derive actual MP4 sample boundaries/avcC metadata, convert its known NAL length format to AnnexB, and explicitly bind each sample to one synthetic0000. That adapter is HOST-SIMULATION policy, not a claimed real phone packetization codec. A general H264 slice/AU assembler and real phone NAL format remain UNKNOWN.

## Safe implementation boundary

Implement raw0000 BE64+opaque bytes and raw0001 opaque config independently from a bounded AnnexB/SPS parser. Require explicit synthetic boundary policy before turning an opaque packet into an access unit. Preserve uint64 timestamp bits without guessing epoch/units. Use separately supplied fixture PTS microseconds for the fake decoder. Local tokens/generation are bookkeeping only; there is no corresponding wire sequence field.

Window simulation may count accepted service-data items with explicit local completions and count ACKs, but credit timing is a MODEL. Duplicate count-only ACKs cannot always be recognized when outstanding debt still exists; session mismatch and count beyond debt can be rejected, whereas idempotence needs an explicitly synthetic delivery identity. Missing ACK/deadline/backpressure values are injected host policy. Reconfiguration and implicit new Setup/Config remain unsupported until separately evidenced.

Remaining actual M7 blockers: streaming TLS/frame association, actual phone packet/NAL/AU format and timestamp units, target credit scheduling, config/data/start ordering, discontinuity/reconfiguration and real transport ownership/acceptance. None are resolved by a synthetic clip pipeline.
