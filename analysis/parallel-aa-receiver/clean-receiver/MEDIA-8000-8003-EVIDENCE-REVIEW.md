# Target-generation media 0x8000 / 0x8003 review

2026-10-23. Local static evidence and PREVIOUSLY SAVED logs only. No production code, fixtures, APKs or live reports changed. No host property suite rerun. M4 PASS; original M5 timing-INCONCLUSIVE; frozen M5 retry READY and next separately authorized LIVE milestone; M6 disabled; M7 host foundation only.

## Conclusion

Honda resolves the two principal M7 conflicts. On its video sink, **0x8000 is inbound Setup declaring a codec**, and **0x8003 is outbound Config**, including readiness, unacknowledged-frame window and allowed configuration indices. Setup field 1 is NOT a configuration index for this target. H.264 baseline codec value is 3. Config status 2 is **STATUS_READY**, status 1 is **STATUS_WAIT**, and 0 is not a recognized Honda Config.Status value. Calling 1 FAIL loses target semantics.

Classification **A for the narrow setup/config implementation**: message semantics and direction are sufficiently understood to implement an offline target profile. Complete running-session progression remains limited by ordering/flow-control evidence; do not interpret A as live M7 readiness. Exact peer behavior between READY, focus, Start and the first data/config payload still lacks a decrypted target transcript. The current compiled engine remains MEDIA_SETUP_PENDING because this session made no implementation changes.

## Evidence inventory / reproducibility

All paths below are relative to project root unless explicitly shortened. Native excerpts, original machine bytes, decoded addresses, PLT call resolution, vtable relocations, input SHA256 values and saved-log excerpts are under `analysis/parallel-aa-receiver/clean-receiver/media-8000-evidence/`.

|Key|Source|Purpose|
|---|---|---|
|H-N|analysis/parallel-aa-receiver/libs/armeabi-v7a/libautoreceiver_jni.so|Actual saved Honda receiver; SHA256 031797DD4B0AECCA007A3AD7AF31C365BA3D47BEBDA8C94BFF13C5289F464C50|
|H-P|decompiled/AndroidAuto-current/sources/com/google/android/projection/proto/Protos.java|Setup, Config.Status, Start, Stop, Ack and MediaCodecType definitions/serialization|
|H-V|decompiled/AndroidAuto-current/sources/com/google/android/projection/protocol/VideoSink.java|JNI callbacks, max-unacked16, configuration and focus plumbing|
|H-A|decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/ui/ProjectionActivity.java|Local setup/config/focus events and ackFrames(session,1)|
|H-R|same Honda tree, video/ProjectionRenderer.java|ACK scheduling including dropped/config/output paths|
|H-L|analysis/parallel-aa-receiver/m4-single-port-20261023-170305-676/20261023-171629-247-attempt2-reconnect-logcat.stdout.txt|Saved runtime order; not a wire capture|
|A|analysis/parallel-aa-receiver/offline-followup/public/aasdk/f1xpl-aasdk-046b3b3/|aasdk_proto/AVChannelSetup*.proto and src/Channel/AV/VideoServiceChannel.cpp|
|O|analysis/parallel-aa-receiver/offline-followup/public/open-android-auto/mrmees-open-android-auto-61eab61/|oaa/av/AVChannelSetup*.proto; newer phone descriptions|
|OH|analysis/parallel-aa-receiver/offline-followup/public/open-headunit/andreknieriem-open-headunit-e9377ff/|app/src/main/java/com/andrerinas/openheadunit/aap/AapControl.kt and protocol/proto/Media.java|
|S|clean-receiver/test-fixtures/session/media-setup.json/.bin|Existing synthetic 0103000480000803; bytes consistent, UNKNOWN semantic annotation now historically superseded|

Method: existing RdxElf.cs reads ELF as bytes; project-local analysis copy of Disassemble-RdxLoadInitializers.ps1 invokes installed llvm-mc disassembler. Nothing loads/executes the ARM library. `disassemble.ps1`, `.hex`, `.asm`, `.annotated.txt`, `calls.txt`, `vtable.txt` retain evidence. Thumb direct calls resolved using PC+4 (word-aligned for BLX) plus signed immediate and ELF PLT relocations. Vtable uses relocation symbols, not zero-filled on-disk entries. Literal pools at function tails are not executable instructions. Relevant function byte mapping reported complete.

An initial script-copy filter failed to substitute and produced unrelated constructor excerpts in the NEW evidence folder; these are not evidence for media conclusions. Corrected filter produced the media functions. Initial Python launcher availability check was access-denied; existing C#/LLVM tooling sufficed. An initial all-files call pass included constructor literal-pool noise; final calls.txt is restricted to media/video functions. No dependencies were installed/downloaded, and no permission escalation was needed.

## Native Honda trace: IDs, direction, callers and order

|ID|Handler/source and native VA|Sender → receiver / channel|Payload and behavior|Preceding/following evidence|Confidence/type|
|---|---|---|---|---|---|
|8000|MediaSinkBase::routeMessage C5504; compare C550C, Setup constructor C555C, ParseFromArray C5566, virtual dispatch C56F6–C56FE; VideoSink::handleSetup CA338|Phone → HU / opened video service|Parses Setup field1, passes it to video handler; handler requires 3|Direct handler calls setup callback, then sendConfig(2). Exact preceding phone message ORDER UNKNOWN; channel must be routable|CONFIRMED Honda native + protobuf|
|8003|MediaSinkBase::sendConfig C5774; ID immediate C57CE; marshallProto C57E0; queueOutgoing C57F6|HU → phone / bound service channel from endpoint|Config status argument, endpoint max-unacked, allowed indices; empty override falls back to enumerating supported configurations|Called directly by video handleSetup CA34C with r1=2, after callback; optional focus follows|CONFIRMED Honda native + protobuf|
|8001|routeMessage dispatch C554C/C5592; handleStart C547A|Phone → HU / video|Start session_id and configuration_index; saves session, calls configuration handler, then playbackStart if handler result0|Configuration callback precedes playbackStart locally. Remote Start-after-Config ordering STRONGLY SUPPORTED, not a checked state guard in this dispatch|CONFIRMED handler; STRONGLY SUPPORTED cross-message order|
|8002|routeMessage C5544/C55CC; handleStop C549C|Phone → HU / video|Stop base empty; callback gets stored session|Calls playbackStop; no separate stop acknowledgment shown|CONFIRMED native + schema|
|8004|MediaSinkBase::ackFrames C5836; ID C585E; marshall C5868, queue C587E|HU → phone / video sink|Ack session_id field1, ack count field2|Explicit Java renderer callback → nativeAckFrames → outgoing message; not a Start acceptance response|CONFIRMED native + Java|
|8007|routeMessage C554E/C56A6; VideoFocusRequestNotification parse; VideoSink::handleVideoFocusRequest C9EB8|Phone → HU / video|Focus request mode/reason family|Routes to application focus request; not necessarily required before setup or Start|CONFIRMED dispatch; ordering UNKNOWN|
|8008|VideoSink::setVideoFocus CA2D0; ID CA2F8; marshal CA304, queue CA31A|HU → phone / video|VideoFocusNotification mode plus unsolicited boolean|handleSetup may call setVideoFocus(1,true) AFTER sendConfig, conditional on auto-start; also explicit Java focus changes|CONFIRMED native; conditional order|
|0001|MediaSinkBase::routeMessage C5530–C553E|Phone → HU / media sink|Body after type passed to handleCodecConfig|Relationship to Start/data is not enforced in this dispatcher|CONFIRMED dispatch; order UNKNOWN|
|0000|MediaSinkBase::routeMessage C552C/C5606 onward|Phone → HU / media sink|Timestamp/data handler path|No complete AU/frame/config ordering recovered here|CONFIRMED family; complete data contract UNKNOWN|

These are SERVICE-SPECIFIC IDs, not globally unique control response codes. Open Headunit generated sources also use 32771 for sensor/navigation/input/media-playback messages on other services. Matching the number without channel/service context is invalid.

Native vtable `_ZTV9VideoSink` is at 1C0180; address point +8. Slot +20 (hex) maps via relocation to handleSetup, +34 to handleMediaConfiguration, +2C to playbackStart, +30 to playbackStop. This links the indirect calls to actual video behavior rather than inferring from method names alone. sendConfig's direct BLX resolves to MessageRouter::marshallProto and queueOutgoing, establishing outbound direction.

VideoSink::handleSetup: compares codec against3; mismatch returns -8. Match calls callback, then unconditionally calls sendConfig(2) on the normal return path; it does not branch on the callback integer result. Java setupCallback calls onCodecSetup and returns0. Thus callback return0 is not wire readiness0. The later optional auto-start branch queues focus(1,true). Channel-not-open gating in sendConfig can suppress actual queueOutgoing; construction of a Config alone is not proof of a transmitted message.

## Payload fields and status domains

|Message|Field/tag/wire|Target meaning|Requiredness/evidence|
|---|---|---|---|
|Setup8000|1 /08 /varint|MediaCodecType; PCM1,AAC-LC2,H264-BP3,AAC-LC-ADTS4|Required; H-P Setup.isInitialized requires hasType; H-N video accepts3|
|Config8003|1 /08 /varint|Config.Status: WAIT1, READY2|Required; H-P isInitialized checks hasStatus only|
|Config8003|2 /10 /varint|uint32 max_unacked|Optional in Honda schema; native sendConfig sets it; Java create sets window16|
|Config8003|3 /18 /varint repeated|uint32 allowed configuration indices|Unpacked writer; native default enumeration0..N-1 or explicit allowed list; empty-list protocol meaning not generalized|
|Start8001|1 /08 /varint;2 /10 /varint|session_id;configuration_index|H-P Start; native uses stored session then selected index callback|
|Ack8004|1 /08 /varint;2 /10 /varint|session_id;ack count|H-P Ack; native serializes both; no timestamp fields evidenced for this target|
|Stop8002|empty base|Stop current stored session|No invented session field|

H-P Config.Status.valueOf accepts ONLY1 and2. Default is WAIT1. There is no valid NONE0 and no target name FAIL1. General/control success0 is a different enum/domain. Native/API function return0 is a third usage: local call success. Do not conflate any of these domains. Newer OAA and AASDK OK2 matches the successful ready value, but FAIL1 is not Honda's symbolic meaning.

Independent manual wire interpretation (logical type bytes then protobuf, NOT live captured packets):

* `80 00 08 03`: Setup(H264-BP). Existing fixture full envelope `01 03 00 04 80 00 08 03` agrees.
* `80 03 08 02 10 10 18 00`: Config(READY,window16,allowed index0).
* `80 03 08 02 10 10 18 00 18 01`: same with allowed indices0,1; illustrative two-config case, not a claimed captured Honda packet.
* `80 01 08 01 10 00`: illustrative Start(session1,index0).
* `80 04 08 01 10 01`: illustrative Ack(session1,count1).
* `80 02`: empty-base Stop.

Tag arithmetic is independently `(field<<3)|wire`; all listed scalar tags are wire0. Unknown fields must remain raw passthrough in the clean model. Unknown enum values must not silently become READY. This review does not claim Honda's old generated Java parser preserves unknown fields; the clean implementation's preservation policy is separate. Existing synthetic fixture bytes remain untouched; only their semantic uncertainty is resolved by this new report.

## Saved runtime evidence

H-L line39991: 17:14:23.877 onCodecSetup; same time setView NOVIDEO and onGalVideoStarted. At17:14:29.255 requestVideoFocus PROJECTED / setVideoFocus, followed by onVideoFocusModeChange. At17:14:29.256 line41453 source configuration1280x688 and prepareStart renderer. At17:14:29.274 surface available/update codec. At17:14:29.422 first-frame-rendered log; additional decoder thread logs follow. These are different thread/asynchronous UI observations, not raw packet timestamps.

This establishes setup callback before source selection/render preparation in this recorded session, and shows onGalVideoStarted is NOT proof of decoded video: it appears while view=NOVIDEO. Logs do not expose8000/8003/8001 wire bytes. Native trace links callback families to dispatch, but exact send/receive timing cannot be assigned from these lines. There was a roughly5.379-second gap between setup callback and source-config callback; no hard protocol timeout/order guarantee follows.

ACK caution: H-A onFrameRendered calls display.ackFrames(session,1). H-R ackFrame polls queued input and calls that listener. Its callers include output-buffer processing BEFORE releaseOutputBuffer, codec-config handling, and input-dequeue failure after repeated failures. Therefore ACK is flow-control/accounting, not proof of display presentation and not a required immediate reply to Start. Global Start/data/ACK ordering still needs a target wire trace or further bounded native/data analysis.

## Public comparison

|Question|Honda|AASDK|OAA|Open Headunit|Resolution|
|---|---|---|---|---|---|
|8000 field1|Codec enum, video accepts3|Named config_index|media_codec_type|MediaSetupRequest.type|Resolved for target: codec, not index. Cause of AASDK name may be historical misidentification; generation difference not proven|
|8003 direction on video|HU queueOutgoing|HU sendAVChannelSetupResponse|Comment phone→HU on video|HU Config send in mediaSinkSetupRequest|Resolved for Honda: HU→phone. OAA comment cannot override target native code; exact reason for its disagreement UNKNOWN|
|Status2|READY|OK|OK|READY|Ready/successful setup status corroborated|
|Status1|WAIT|FAIL|FAIL|WAIT/READY naming in generated media model|Use Honda WAIT; do not implement fatal failure solely because1|
|Config field2|required presence not needed for Java isInitialized; emitted natively|required|optional|explicitly emitted|Honda optional schema / normal emission distinguished|
|Focus after Config|conditional auto-start|separate sender function|broader newer behavior|gainVideoFocus after Config|Conditional path supported; unconditional focus must not be imported|

Public implementation agreement is secondary corroboration. No upstream implementation was copied. Existing licenses/provenance remain applicable. No web research or downloads were used.

## Proposed target-generation sequence

State names below are proposed HOST MODEL states, not names recovered from Honda.

|Step|Before|Direction/channel/ID|Payload|Expected next / value|After|Confidence / why|
|---|---|---|---|---|---|---|
|0|VIDEO_SERVICE_AVAILABLE|UNKNOWN STEP: exact preceding peer packet|Opened/routable video endpoint prerequisite|Setup may arrive|unchanged|Channel prerequisite supported; immediate previous message ORDER UNKNOWN|
|1|VIDEO_SERVICE_AVAILABLE|phone→HU/video/8000|required codec3|local setup callback then Config|MEDIA_SETUP_PENDING|CONFIRMED direct dispatch|
|2|MEDIA_SETUP_PENDING|HU→phone/video/8003|READY2,window16,allowed indices for advertised configs|No separate Config acknowledgment established|MEDIA_CONFIG_ADVERTISED (or narrowly defined MEDIA_READY)|CONFIRMED direct sendConfig(2); local ready does not mean running|
|3|configuration advertised|optional HU→phone/video/8008|projected1,unsolicited=true when auto-start policy active|Peer behavior UNKNOWN|unchanged|CONFIRMED conditional native call after Config|
|4|configuration advertised|UNKNOWN STEP: peer scheduling/focus dependence|No fabricated readiness acknowledgment|Start candidate|unchanged|ORDER UNKNOWN globally|
|5|configuration advertised|phone→HU/video/8001|session and selected config index|local sourceVideoConfig callback then playbackStart|MEDIA_START_OBSERVED|CONFIRMED dispatch/local order; response-to-Config ordering STRONGLY SUPPORTED|
|6|start observed|phone→HU/video/0001 and0000|codec config / timestamped data|decoder boundary only|DATA_OBSERVED, not proven displayed|Families confirmed; first-data/config ordering UNKNOWN|
|7|data accounting event|HU→phone/video/8004|session,count|flow-control credit|unchanged|CONFIRMED explicit callback path; not presentation proof|
|8|active session|phone→HU/video/8002|empty Stop|local playbackStop stored session|STOP_OBSERVED|CONFIRMED handler; full session-close behavior separate|

Immediate operation after valid setup in Honda is callback then Config. Immediate wire operation after Config can be optional focus; otherwise peer's next packet is not proven. Start handler does not itself send an ACK. MEDIA_READY is supportable only if defined as local configuration/readiness advertised; MEDIA_RUNNING must not imply decoder/phone/render success. The current engine has not been advanced. No requirement to simulate a complete session has overridden an evidence gap.

## Precise subsequent implementation plan (not executed)

1. In MediaControlMessages introduce target-specific CodecType and ConfigStatus domains: H264_BP3; WAIT1/READY2, no accepted0. Add Config codec with required status, optional uint32 maxUnacked and bounded repeated indices. Preserve raw unknown fields/enum data for inspection; unsupported values cannot advance state. Existing general ControlMessages.Status remains unchanged.
2. Tighten the target Setup semantic validator to require field1 and codec3 on video; retain a generic lossless decoder if needed. Missing/wrong-wire/unknown codec are distinct from supported H264. Document target narrowing of previous permissive scalar inspection.
3. Extend SimulatedSessionEngine with explicit local readiness policy/event and MEDIA_CONFIG_ADVERTISED. Do not send merely on construction. After valid inbound Setup and explicit simulated local acceptance, generate8003 with READY2/window/allowed indices from the actual catalog. Do not automatically allocate a decoder or assume decoder resources from ready status.
4. Parse Start, validate selected index belongs to the advertised allowed set, store session, emit abstract configuration-selected before playback-start observation. Use MEDIA_START_OBSERVED rather than claiming real MEDIA_RUNNING. Invalid index/early/duplicate/wrong-channel Start tests must distinguish local strict policy from checks actually observed in Honda.
5. Optional modeled focus indication remains explicit policy, default no automatic foreground takeover. Do not treat8007 as compulsory before Start. If adding focus codecs first inspect complete Honda notification schemas and reason enum mappings.
6. ACK remains explicit accounting input to the pure core, never an automatic response to Start and never a displayed-frame metric. Keep decoder boundary inert. Stop uses stored session, no invented stop-reply.
7. Add independent literal fixtures above; two-config READY and WAIT; missing status,0/unknown status, wrong wire type, truncated varint, duplicate fields, excessive/invalid indices, optional missing window, unknown fields roundtrip. Preserve old fixtures as historical; revise semantic metadata chronologically rather than overwrite evidence.
8. Positive synthetic path: video open → codec3 setup → explicit local accept → READY Config → explicit optional focus → Start selection callback order. Negative: setup before open, unsupported codec, Config on wrong direction/channel, Start before advertisement, unadvertised index, duplicate Start/Stop, ACK without observed session, terminal state events. Keep timeout/bounds/property/Java7/API22 suites and frozen artifacts checks.
9. Update state/confidence/coverage tables. Leave TLS, transport, SPS/AU ordering, focus preconditions, wait→ready transition triggers, retry/reconfiguration semantics, and phone acceptance UNKNOWN until separately evidenced. No active USB/M6 implementation follows from this report.

## Files / preservation / limits

Created this report and media-8000-evidence/ analysis outputs; appended chronological NOTES only. Production codecs, original22 session fixtures, previous reports/builds and M4/M5 live reports were not edited. Frozen M5 SHA256 rechecked exactly A22E96490B9557AFF022893A8B8B7A08BB13CEC236E52704CDDAFA90A8EE8F40. No APK rebuilt. The existing475/1541937 test results remain historical validated results, not new tests run here.

Most important new fact: actual Honda native code independently proves codec3 Setup → outbound Config READY2, resolving both principal public-reference disputes. Biggest remaining integration blocker is actual transport/security plus peer ordering/data behavior, not inability to identify8000/8003. A future narrow offline implementation is justified; next LIVE milestone remains the frozen M5 retry under separate authorization. NO ADB, vehicle, phone, USB hardware, real TLS or MediaCodec execution was used.
