# Offline M7 Honda media Config implementation — 2026-10-23

**PASS for the bounded host-only subset.** M4 PASS; original M5 timing-INCONCLUSIVE; frozen M5 retry READY and next separately authorized LIVE milestone. M6 disabled. M7 remains an offline foundation, not a live pass. No APK was created or rebuilt. No ADB, vehicle, phone, USB hardware, real TLS, Honda JNI, decoder, Surface or MediaCodec execution occurred.

Source of truth: [MEDIA-8000-8003-EVIDENCE-REVIEW.md](MEDIA-8000-8003-EVIDENCE-REVIEW.md), preserved unchanged. This implementation report records subsequent work without rewriting that analysis.

## 1–5. Baseline, final counts and seed

|Measure|Reproduced baseline|Final|
|---|---|---|
|Production Java modules/files|36|39|
|Deterministic checks|475|612 =475 prior +137 new|
|Property assertions|1,541,937|3,956,937 =1,541,937 prior +2,415,000 new|
|Randomized cases/sequences|37,500|52,500 =37,500 prior +15,000 new|
|Golden fixtures|50 =28 original +22 session|70, including20 new Honda-media fixtures|
|Transcript files|18|29 =18 prior +11 new|
|Compilation|Java7/D8min22 PASS|Java7/D8min22 PASS|

Baseline fresh build: `build/20261023-205826-897`. All original test files remain byte-for-byte unchanged and pass against the final sources. All original50 fixture inputs remain unchanged. The only modified pre-existing production file is SimulatedSessionEngine.java; three new modules were added. The generic historical MediaControlMessages inspection codec and its fixtures remain intact.

New seed: decimal **20353395894340919**, hex **0x484f4e44414d37**. New property workload:15,000 sequences ×20 event opportunities =300,000 opportunities, eight assertions per opportunity plus15,000 reset assertions =2,415,000 assertions. Sequences begin at randomized supported video/media stages so they exercise WAIT/READY/selection, not only early failure. Prior seeds/suites remain unchanged.

## 6–10. Distinct target media models/codecs

`MediaConfigStatus` is a separate enum: STATUS_WAIT=1 and STATUS_READY=2. It never aliases control success0. `HondaMediaMessages` defines MediaSetup, MediaConfig, MediaStart, MediaAck and a narrow ProjectedFocus model, plus distinct immutable CodecType and VideoConfigurationIndex types. A configuration index cannot be passed to the Setup constructor as a codec, despite both having numeric wire representations.

Setup8000 requires field1, parsed as a uint32 codec value. Honda video supports3=H264_BASELINE. Unknown codec values remain inspectable/lossless but produce B_UNSUPPORTED_VIDEO_CODEC, without advancing or destroying the known registry. Required-field/wire/byte-limit failures invalidate the framed session under the existing malformed-wire policy. Duplicate singular fields retain original bytes and use protobuf last-value semantics, matching the existing ProtoWire policy; duplicates are not silently erased.

Config8003 requires status field1, permits absent max-unacked field2, and supports repeated unpacked uint32 indices field3. Parsing preserves original bytes, including unknown fields, unknown numeric status and nonminimal supported varints. `status==null` explicitly means unrecognized; rawStatus remains available. Unknown/zero status is rejected by `validateAdvertisement`, never converted to READY. Absent status is malformed. Empty index lists are retained but permit no Start selection in this model. Duplicate/out-of-catalog indices are rejected by local advertisement policy; this is not a universal protobuf illegality claim. The native serializer's unpacked representation is implemented; packed alternatives are outside this narrow codec subset.

Config count is bounded8. Present max-unacked must be positive for this local advertisement policy; missing window remains supported per Honda schema. Tests cover READY one/two indices, WAIT, absent window, empty list, duplicate indices, excessive count, malformed varints/types, uint32 overflow, unknown status/fields and original-byte roundtrip. No WAIT-as-failure interpretation exists.

## 11–14. Session composition and Start selection

The unchanged11-state control/lifetime graph remains responsible for version/discovery/open/stop/error. A single new `HondaMediaFlow` state object owns media progression. This avoids rewriting the prior inspection-only behavior or changing old tests to fit new semantics.

Explicit constructor selection:

[Code block omitted from public report; see authored source where available.]

`true` opts into Honda target semantics. Existing2/3-argument constructors retain historical raw inspection mode. No constructor sends/progresses/reads a clock. `state()` reports the parent control state, `mediaState()` reports the typed media state, and `progression()` reports the furthest current media/control label. A parent MEDIA_SETUP_PENDING can therefore coexist with media MEDIA_CONFIGURATION_SELECTED; it is a hierarchical state model, not a claim setup remained unprocessed.

Media states:

|Before|Explicit event|After|Confidence/limit|
|---|---|---|---|
|IDLE + opened video|valid inbound8000 codec3|MEDIA_SETUP_RECEIVED|Payload CONFIRMED; state name implementation structure|
|MEDIA_SETUP_RECEIVED|advertiseMediaConfig(WAIT)|MEDIA_CONFIG_WAIT_ADVERTISED|WAIT wire CONFIRMED; choice is explicit synthetic policy|
|MEDIA_SETUP_RECEIVED|advertiseMediaConfig(READY)|MEDIA_CONFIG_ADVERTISED|Honda READY response CONFIRMED; no decoder allocation|
|MEDIA_CONFIG_WAIT_ADVERTISED|explicit synthetic WAIT/READY policy|WAIT or MEDIA_CONFIG_ADVERTISED|Production trigger UNKNOWN; no automatic retry/timer|
|MEDIA_CONFIG_ADVERTISED|valid Start with allowed index|MEDIA_CONFIGURATION_SELECTED|Selection/callback ordering supported; global wire ordering partly inferred|
|MEDIA_CONFIG_ADVERTISED|optional projected focus policy|unchanged|Conditional event, no peer prerequisite inferred|
|MEDIA_CONFIGURATION_SELECTED|explicit accounting event|unchanged|ACK accounting only|
|any live media state|parent fatal error/EOF/orderly close|CLOSED|Terminal containment policy|

[Code block omitted from public report; see authored source where available.]

There is NO MEDIA_RUNNING state. Start parser retains known session_id/configuration_index and unknown bytes. The target subset restricts session IDs to nonnegative signed-int range, as did the previous codec; broader signed-session semantics remain outside scope. Configuration indices are separate uint32 values, validated against the actual list advertised by Config, not merely catalog size. A two-configuration catalog and an allowed subset containing only index1 prove index0 is rejected even though catalog0 exists.

Duplicate Setup/Start cannot repeat selection. Start before Setup, before Config, after WAIT, with an unadvertised index, or on the wrong service cannot silently advance. Local semantic rejections preserve state where safe; malformed wire or wrong service/control channel follows the existing whole-session invalidation policy. Inbound Config/ACK/focus-indication on video is rejected as wrong direction. No reverse-direction Setup encoder is exposed as an automatic session action.

## Callback ordering and explicit policies

Callbacks here are bounded DATA event records, not executable application/decoder callbacks. The transcript records:

1. `onMediaSetup codec=3; NO_DECODER` after valid inbound Setup;
2. `ConfigSerialized` only on later explicit advertiseMediaConfig input;
3. outbound8003 bytes;
4. `onConfigurationSelected index=...` after valid Start;
5. `onMediaStartObserved ...; NO_PLAYBACK_CLAIM`.

Tests compare event positions and exact output bytes. In Honda's native accepted Setup path, callback→Config is directly automatic. This host model deliberately separates the explicit local policy input so WAIT/READY handling and the UNKNOWN production readiness trigger remain visible. It does not insert a fictional extra PHONE message between Setup and Config.

## 15–17. Optional focus and ACK accounting

`optionalProjectedFocus(true)` is allowed after READY Config, emits8008 with projected1/unsolicited=true and does not change media state. False produces no bytes. Calling it before Config cannot bypass setup/readiness. Both Config→Start and Config→Focus→Start pass. Only the confirmed projected/unsolicited subset is modeled; other focus modes/reason policies remain unimplemented.

`accountMedia(count, AccountingReason)` is explicit after an observed selected session. Reasons are CODEC_CONFIG_ACCOUNTED, INPUT_FAILURE_ACCOUNTED and OUTPUT_ACCOUNTED; these are host accounting inputs, not decoder invocations. It emits8004 session/count with local count bound1..32 and leaves MEDIA_CONFIGURATION_SELECTED unchanged. Tests cover all three reasons, including INPUT_FAILURE_ACCOUNTED, plus no automatic ACK after Start, early ACK rejection and terminal non-resurrection. Neither API contains a displayed-frame counter. ACK does not establish decoder success, presentation, Start acknowledgment or media running. Full window/credit scheduling is not implemented.

## 18–21. Independent fixtures and transcripts

New versioned directory: `test-fixtures/honda-media-v1/`. Twenty literal wire .bin vectors, matching human-readable JSON files and manifest.json. Script `scripts/New-RdxHondaMediaFixtures.ps1` uses manually authored wire hex and validates envelope length; no production writer/codec is imported. It refuses to overwrite an existing manifest. Every fixture records raw bytes, direction, channel, expected states, confidence, evidence source, unknown-field policy and SHA256. These are synthetic independently authored vectors, not captured phone packets.

Representative independent vectors:

[Code block omitted from public report; see authored source where available.]

Eleven new saved transcripts: A-conservative; B-experimental; C-wait; C2-explicit-readiness-policy; D-bad-codec; E-bad-index; F-duplicate-setup; G-start-before-config; H-optional-focus; I-input-failure-accounting; J-two-config-selection. Old18 transcripts remain generated unchanged. New transcripts are under each final build/honda-media-transcripts/.

Conservative and explicit experimental paths both reach MEDIA_CONFIGURATION_SELECTED. WAIT path remains MEDIA_CONFIG_WAIT_ADVERTISED after Start; only a separate explicit synthetic READY policy permits progression. Config's window16 is normal target evidence in the fixture, not a runtime capability measurement here.

Capability payloads remain unchanged:

* Conservative: `08 02 10 01 18 00 20 20 28 e5 01`; active1280x688,229dpi,60fps.
* Experimental: `08 03 10 02 18 00 20 e8 02 28 e5 01`; nominal1920x1080,total margins0/360,active1920x720,229dpi,30fps.

Experimental requires explicit catalog opt-in. Crop placement remains UNSPECIFIED; no180/180 split or touch offset is inferred. Input mapping remains independent. No phone acceptance claim follows from these host results.

## 22–24. Deliberately unresolved boundaries

Still UNKNOWN: immediate preceding Setup packet, universal next packet after Config, peer focus requirements, exact Start/codec-config/data ordering, production WAIT→READY trigger, and reconfiguration/repeated-start semantics. Strict rejection of repeated starts is a local safe subset policy, not proof all generations forbid restart. Empty-list peer meaning and newer packed/ACKless/timestamp modes remain outside scope.

TLS remains an opaque existing adapter boundary. No credentials, certificate material, socket, handshake or real decryption was introduced. Correct media semantics do not solve streaming TLS/fragment plaintext association. The pre-existing explicit plaintext simulation bypass is logged and does not establish authentication.

DecoderBoundary remains interface-only and unchanged. No configure/start/queue/flush/stop implementation or object was instantiated; no H264 decoding, Surface or rendering. This library only records selection/accounting events.

## 25–26. Build, API, side effects and reproducibility

Fresh final builds:

* `build/20261023-210415-497`
* `build/20261023-210529-773`

Java source7/target7 compile uses installed SDK33 public stubs. D8 min-api22 PASS. Independent method-reference validation against actual saved D.1.6.4 API22 core-libart.jar/framework.jar resolves all84 external method references. The directory containing these local files is named adb; no adb executable was run. Final DEX contains no host tests/fake transport and no active USB/transfer/native/TLS/MediaCodec/shell API references. No manifest/components or receiver APK were produced.

Both final builds have identical classes, JAR entry payloads and DEX:

`408F91F5803BAA37D6E80113D7571B2E1F7384FB3546723D07D294BB2E07F7CD`

All29 transcript payloads and all fixture inputs also match. JAR container hashes differ because ordinary jar cf retains ZIP timestamps; these were documented, not normalized away. Reproducibility evidence is under the session directory below.

Constructor review: MediaConfigStatus assigns constants; message value constructors only validate/assign/clone bounded data; HondaMediaFlow initializes local state/list; SimulatedSessionEngine's new constructor creates that object only when explicitly selected. No constructor advances state, sends bytes, opens/enumerates a device, starts a thread, negotiates TLS, creates Android components or allocates a decoder. Host time comes from the existing injected clock, and tests use no sleeps.

Policy methods capture bytes through the existing bounded outbound queue, never an external transport. Existing frame16KiB, logical/proto64KiB,8 fragmented channels,16services,8video-configs,128message-step,32outbound and transcript1024rows/1,048,576-character bounds remain. New flow event queue is bounded64 events and drained per engine event. These are local safety bounds, not proven protocol maxima or whole-JVM heap limits. The existing error/closed parent clears/closes media; explicit reset constructs fresh parent/media objects.

## 27. Exact files and commands

Added production modules:

* source/com/rdx/fullscreen/clean/MediaConfigStatus.java
* source/com/rdx/fullscreen/clean/HondaMediaMessages.java
* source/com/rdx/fullscreen/clean/HondaMediaFlow.java

Modified production module: source/com/rdx/fullscreen/clean/SimulatedSessionEngine.java. Added test: tests/com/rdx/fullscreen/clean/HondaMediaTests.java. No original test was edited/deleted/weakened.

Added scripts: scripts/New-RdxHondaMediaFixtures.ps1 and scripts/Validate-RdxM7MediaConfig.ps1. Modified scripts/Build-RdxCleanFoundation.ps1 to run the additional suite, record results and fixture hashes. Existing Compare-RdxProtocolBuilds.ps1 and old validators remain unchanged for historical use. Use the NEW media validator for current totals.

Created20 .bin +20 .json +manifest under test-fixtures/honda-media-v1/. Updated README.md, MESSAGE-STATE-COVERAGE.csv (adds unresolved_semantics column and separates8007/8008), project BUILD-VALIDATION-MATRIX.md and NOTES.md. Created this report. The evidence directory also contains baseline snapshot, final validation, API results, protected hash inventories, reproducibility data and exact file inventory.

Evidence directory: `media-config-session-20261023-205924-824/`.

Commands used for verification, from project root:

[Code block omitted from public report; see authored source where available.]

Baseline and both final builds executed the complete old suite plus the new suite when present. First new build had98 new deterministic checks;39 additional boundary/multiconfig/closed/chunk tests raised this to137 before the two final builds. An initial new-validator preservation check correctly stopped on the intentionally modified engine; its permitted change was then explicitly scoped to SimulatedSessionEngine.java. No parser/test assertion or old fixture was weakened to pass validation.

## 28–32. Preservation, conclusion and next steps

All69 historical APK hashes and both M4/M5 live-report hashes match their protected inventories. Frozen M5 retry remains byte-for-byte:

`A22E96490B9557AFF022893A8B8B7A08BB13CEC236E52704CDDAFA90A8EE8F40`

**NO ADB, VEHICLE, PHONE, USB HARDWARE, REAL TLS OR MEDIACODEC WAS USED.** No installation, settings/display change, active transport or M6 execution occurred.

Most important result: Honda's codec Setup and readiness Config now drive an explicitly bounded, independently tested host media state model; selection cannot confuse codec3 with configuration index3, WAIT cannot become READY, and failure-path ACK cannot become a display/running claim.

Recommended next OFFLINE task: narrowly review saved native media-data0000/codec-config0001 framing and access-unit/accounting association, then document the future TLS-to-protocol adapter contract. Do not implement uncertain sequencing to manufacture a running session. This recommendation was not executed.

**Next LIVE milestone remains M5 RETRY ONLY**, with separate authorization. M6 stays disabled; M7 host simulation does not establish real-phone acceptance. No new reason to revisit deferred M3 was found.
