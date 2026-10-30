# Offline M7 video data plane — 2026-10-23

**OFFLINE SYNTHETIC MEDIA PIPELINE PASS.** Not an Android Auto session pass, decoder pass, TI performance result or display pass. M4 PASS; original M5 timing-INCONCLUSIVE; frozen M5 retry READY and next separately authorized LIVE milestone. M6 disabled. M7 remains an offline foundation.

## Baseline and final validation

Baseline freshly reproduced before modifications in `build/20261023-213552-437`:39 production modules,612 deterministic checks,3,956,937 property assertions,52,500 randomized cases,70 independent fixtures and29 transcripts. Java7/D8min22 PASS. Prior tests were not edited, deleted or weakened.

Final results:

|Measure|Result|
|---|---|
|Production Java modules/files|45 =39 prior +6 new|
|Deterministic checks|66,293 =612 prior +65,681 new|
|Property assertions|6,791,914 =3,956,937 prior +2,834,977 new|
|New randomized stream/event sequences|25,000 ×12 event opportunities|
|Additional malformed transport cases|5,000 seeded garbage cases|
|Total randomized cases|82,500 including prior52,500|
|New seed|24287405566545207 /0x564944454f4d37; garbage uses seed XOR0x1234; chunking seed123|
|Independent fixtures|94 total =70 prior +24 new|
|Saved transcripts|46 total =29 prior +17 new|
|Long workload|60,000 events:30,000 event session +5cadence runs of6,000 each|
|Existing clips|All6 original MP4 hashes unchanged;2,700samples independently compared|
|Target methods|103 external method references resolved in saved D.1.6.4 API22 definitions|
|Artifact|JAR/DEX only; no APK/components|

Property failures carry a replayable generated event-prefix string (not a claim of globally minimized/shrunk failure). No failures occurred in the final suites. Assertions cover admission/credit bounds, terminal cleanup, default conservative profile, unknown protobuf bytes and independent envelope/credit oracle agreement. Deterministic long-run bounds contribute many of the65,681 checks; this count is not65,681 unrelated test scenarios.

## Honda envelope findings

[Focused source/evidence review](MEDIA-DATA-0000-0001-EVIDENCE-REVIEW.md) contains exact addresses and source paths. Prior control/media evidence reports remain unchanged.

* **0000**: CONFIRMED phone→HU video data. After BE16 type comes BE64 timestamp, followed by opaque bytes. Native handler supplies the stored Start session separately. It is not a continuation marker or a packet sequence field.
* **0001**: CONFIRMED phone→HU codec configuration. Opaque bytes after the type go to codec-config callback, with no timestamp field parsed.
* **8001**: Start selects configuration/session used by subsequent data callbacks.
* **8003**: WAIT1/READY2 and max-unacked remain distinct from control status0.
* **8004**: session/count accounting only. No wire-unique ACK or packet token was discovered.
* **8002**: native playbackStop callback, not proof of real decoder drain.
* **8008**: optional focus; not data readiness.

New important timestamp evidence: Honda Java preserves VideoFrame.timestamp but the renderer queues decoder input with a locally generated System.currentTimeMillis()*1000 timestamp, not that stored wire value. Therefore wire bits, fixture presentation time and future decoder PTS remain distinct. Wire timestamp units/epoch remain UNKNOWN for this target; full uint64 bits, including high-bit-set values, are preserved.

## Layer/type separation

Six new production modules:

1. **MediaPayload**: confirmed raw0000/0001 envelope. Timestamp stores uint64 bits in Java long with unit UNKNOWN. Config is opaque and has no invented timestamp. Max payload1,048,574 bytes leaves room for the BE16 type within1MiB logical message.
2. **H264**: explicit bounded AnnexB NAL inspection plus conversion of a separately known AVCC length-prefixed source. Distinguishes SPS7,PPS8,IDR5,non-IDR1,AUD9,SEI6. SPS baseline/main/extended subset extracts profile,level,coded dimensions and crop pixels. High-profile extensions explicitly unsupported. PPS association validates initial IDs/header subset; this is not a complete PPS/slice conformance validator or video decoder. VUI contents beyond presence are not decoded.
3. **VideoDecoderContract**: separate format/CSD/configure/start/queue/flush/stop interface, input outcomes, output-format/error observer. Format retains SPS coded/raster/crop/profile/level through immutable configuration, MIME video/avc, and raw CSD. Queue takes an AU, raw wire timestamp and separately explicit fixture PTS if supplied. Keyframe is an AU property; configure is a distinct call. No implementation, TI allocation or software fallback is provided.
4. **MediaAccountingWindow**: bounded count-credit model with LOCAL session/generation/serial tokens, not wire tokens. Completion is explicit, duplicate local completion rejected; FIFO completed credits drain as count ACK. Separate sender-style count ACK operation rejects stale session and count beyond debt. Capacity1..32 is local policy; zero is rejected locally, not declared universally malformed by Honda protobuf.
5. **VideoDataPlane**: selected-control gate, explicit synthetic boundary policy, bounded queue, configuration state, fake-sink outcomes and accounting. Default UNKNOWN boundary policy cannot invoke a decoder or invent an AU. Only explicit HOST_ONE_MESSAGE_PER_MP4_ACCESS_UNIT interprets AnnexB config/MP4-sample packets.
6. **PlaintextVideoBridge**: independent explicitly attached media frame parser/reassembler over already-decrypted WHOLE PROTOCOL FRAMES. Supports arbitrary chunks, fragment bounds, EOF and injected incomplete-frame/fragment deadlines. Encrypted/control flags are rejected, opaque encrypted input cannot bypass validation. It is not a TLS implementation or a solution for actual encrypted-frame/decrypted-byte association.

Only one old production module changed: SimulatedSessionEngine adds read-only selected-session/channel accessors. Existing control and HondaMediaFlow behavior/tests remain unchanged. New data-plane objects explicitly attach after selection rather than feeding unlimited data through the bounded128-step control transcript engine.

Protocol packet ≠ NAL ≠ access unit ≠ decoded picture ≠ displayed frame. **There is no general arbitrary-slice AU assembler here.** MP4 sample tables provide independently known AU boundaries; the host adapter maps each sample into one synthetic0000. The native envelope does not prove a real phone uses this mapping or AnnexB. This uncertainty is an explicit interface boundary, not a hidden assumption in MediaPayload.

## Codec configuration / SPS comparison

Honda Java sends config bytes through the input queue, marking the first input as codec config. It does not parse SPS/PPS in that path. Our host H264 configuration parsing is an explicit synthetic inspection adapter; production raw config bytes remain opaque at the envelope layer. No real-phone CSD format is claimed.

All six existing clips were read without regeneration. A bounded host-only **Mp4FixtureReader** parses nonfragmented single-avc1-track boxes, avcC, stsz/stsc/stco, stts/stss and identity timing. Nonidentity edits/composition shifts/extended boxes/multiple descriptions are rejected as unsupported. It preserves sample order, NAL lengths, sync flags and rational timestamps; sample bytes are converted into deterministic AnnexB, not decoded. Its MP4 table sample sizes, PTS and sync flags agree with fresh demux-only ffprobe output for every sample. avcC SPS/PPS agree byte-for-byte with the independently saved FFmpeg first.h264 extraction.

|Fixture|Frames / IDRs|SPS profile / level|Coded|SPS display raster|SPS crop pixels L/R/T/B|Max AU bytes|
|---|---|---|---|---|---|---|
|1280x720 @30|300 /10|66 /31|1280x720|1280x720|0/0/0/0|57,291|
|1280x688 @60|600 /10|66 /32|1280x688|1280x688|0/0/0/0|47,013|
|1920x720 @30|300 /10|66 /40|1920x720|1920x720|0/0/0/0|75,858|
|1920x720 @60|600 /10|66 /42|1920x720|1920x720|0/0/0/0|67,877|
|1920x1080 @30|300 /10|66 /40|1920x1088|1920x1080|0/0/0/8|102,211|
|1920x1080 @60|600 /10|66 /42|1920x1088|1920x1080|0/0/0/8|85,647|

All are saved constrained-baseline/yuv420p/no-B fixtures. ffprobe shows display raster; the independent SPS parser and saved trace_headers establish coded1088 and crop8 for1080 clips. Clip metadata, per-sample ledgers and NAL distribution are saved with transcripts. Source MP4 files/hashes remain in their original manifest and current session/clip-verification.json. FFmpeg was not invoked for a new encode/decode; only installed project-local ffprobe demux/metadata inspection was used during this run.

Some valid fixture AUs exceed64KiB. The new explicit data bridge therefore permits1MiB reassembly while leaving the existing64KiB control message limit unchanged. It uses protocol FIRST/LAST to reconstruct a logical message; this is not H264 slice assembly.

## Window, accounting and backpressure

Window1,2,16,32, zero/33 rejection, maximum admission, credit freeing, stale-session ACK, impossible count, local duplicate completion, generation reset and missing-credit timeout are tested. An independent CreditOracle (only integer debt/capacity, no production imports) is differentially compared with count-window behavior in generated sequences.

**Count-only wire ACK duplication is not generally detectable.** If debt remains, applying the same session/count twice is indistinguishable from two legitimate ACKs. A test demonstrates this explicitly rather than claiming idempotence. Local completion tokens can be deduplicated because they have synthetic identity; do not conflate that with Honda wire fields.

The host model counts accepted service-data items; fake input ACCEPTED and INPUT_REJECTED can complete local accounting and later emit count credit. BACKPRESSURE from the fake sink retains a bounded AU until an explicit pump. Direct packet admission returns BACKPRESSURE when capacity is exhausted; the framed-byte adapter then invalidates explicitly as WIRE_ADMISSION_FULL because upstream pause/replay is not implemented. It never silently drops an admitted transport message. RESET_REQUIRED/configuration rejection invalidates media state and clears config/queue/debt. This is a deliberate synthetic completion policy, NOT an exact reconstruction of Honda's asynchronous decoder-output ACK FIFO. The native Java code's config/failure/output paths make a displayed-picture identity unjustified. Config0001 does not automatically acquire selected-session credit in our model; its exact target accounting remains UNKNOWN.

Queue cap: configured window up to32 entries AND1MiB aggregate AU data. Bridge body16KiB/logical1MiB,2 fragmented channels/2MiB reservations,256 fragments/message, internal feed slices32KiB, external injected chunk up to32MiB. Local data event ring128rows; no unbounded transcript retained in production. Fixture reader caps file32MiB/samples10,000; H264 caps1MiB/256NALs and bounded Exp-Golomb. These are policy bounds, not phone-negotiated protocol maxima or a precise whole-heap bound; temporary arrays/object overhead are additional.

## Synthetic streams, segmentation and failure behavior

All6 complete10-second clips pass service discovery→video open→Setup3→READY2→Start selection→explicit synthetic AnnexB config→sample data→fake queue→accounting→Stop. Conservative uses1280x688@60; the other conservative sanity clip1280x720@30 deliberately has a different fixture raster, demonstrating the host model does not equate advertised geometry with encoded geometry. Experimental streams explicitly opt into nominal1920x1080/margins0,360/dpi229/fps30 and separately feed720 or1080 rasters (including60fps stress inputs). A synthetic60fps input under a30fps advertisement is a queue stress case, not phone negotiation/acceptance evidence.

Every clip transcript contains original control progression, config hex, SPS summary, per-AU index/fixture timestamp/length/hashCode/accepted-accounted totals, bounded final event ring and cleanup. A separate per-sample CSV preserves sample bytes/timestamps/keyframe flags. HashCode is a deterministic test ledger identifier, not a cryptographic provenance claim; input/fixture files have SHA256 inventories.

Seven segmentation modes (whole buffer,1/2/3/7byte,seeded random,fixed997) deliver six REAL AUs identically. Every configuration/header/SPS/PPS byte split is tested. A real >64KiB IDR is split at all outer headers/media prefix/chosen interior positions. A full1920x720@30 clip (>8MiB,300samples) delivered in one transport chunk matches packet-at-a-time AU count and rolling sink digest. Whole long clips were not all replayed one-byte-at-a-time; the hostile small-chunk torture uses real representative prefixes while complete clips and full large-chunk batching are tested separately. Internal quota-safe slicing preserves feed bounds.

|Condition|Disposition / limit|
|---|---|
|Malformed header/length, out-of-order fragment, truncated EOF|Fatal simulated stream; parser/reservations/media state cleared|
|Opaque/encrypted flag entering plaintext seam|Reject; REAL_TLS_ADAPTER_REQUIRED / no bypass|
|Wrong video channel / unknown video ID|Local strict fatal/unsupported policy, not a universal native behavior claim|
|Media before typed Start|Reject with no queue/config|
|Data before accepted config|Reject; no AU admitted|
|Duplicate complete data / backwards or repeated wire timestamp|Not reliably diagnosable as duplicate/reorder from target envelope; bytes delivered as separate host items|
|Dropped whole message|No sequence field to prove loss; cannot fabricate detection|
|Large/high-bit-set timestamp|Preserve raw bits; no guessed wall-clock or wrap correction|
|Missing timestamp on0000|Envelope malformed if fewer than8bytes; all8-byte values valid raw bits|
|Duplicate/new config after acceptance|RECONFIGURATION_UNKNOWN; no implicit hot switch|
|After Stop/ERROR/reset|No queue/revival; fresh selected-control/plane/bridge required|

Reset tests cover config/no config, before first IDR, outstanding debt and backpressure. Old config/AU/token/timestamp/channel state is not inherited by the fresh object. Historical counters on terminal objects remain diagnostic only. Stop/flush are abstract local cleanup policies; native Stop callback alone does not prove decoder-resource draining.

## Long-session stability

30,000-event repeated real1920x720@60-AU session uses periodic backpressure, accounting every7events and occasional variable protocol fragmentation/chunks. Five additional6,000-event cadence runs cover1280x688@60,1920x720@30/60,1920x1080@30/60 with periodic pressure and full new-session reset every1,000events.

Across these60,000 long events: max observed queue depth3, max queued AU bytes128,088, max outstanding credit7. All accepted totals matched intended event counts. Final queue, buffered bytes and debt were zero. Window capacity32 was separately tested to its limit. These measurements describe fake sink/queue policy only; they are not TI decoder throughput, latency or display measurements.

## Independent tests / corpus

`VideoWireOracle` independently defines type bytes, BE64 and fragment headers, without production parser/writer/status constants; `CreditOracle` uses a structurally separate count model. Differential tests cover random raw timestamp bit patterns, payload equality and credit admission/ACK disposition/debt. Existing independent framing oracle remains unchanged.

24 new fixtures:6 actual SPS/PPS configurations independently extracted from SAVED first.h264 files, plus18 handwritten valid/malformed/invalid-state vectors. Metadata records bytes, SHA256, provenance and expected disposition. Corpus covers empty/truncated config/data, SPS/PPS truncation, AVCC NAL-length overflow, forbidden/empty NAL, unsupported ID, impossible credit, unadvertised index, reconfiguration, before-Start/after-Stop and AUD/SEI. All94 fixtures and all prior test files are checked unchanged. Oversized input, NAL max-1/max/max+1, raw media max/max+1 and uint64 boundaries are additionally constructed in tests rather than storing huge fixtures.

## State guarantees and remaining blockers

[Complete state guarantee table](STATE-GUARANTEES.md) covers all parent/media/data states. Furthest new state is **ABSTRACT_INPUT_ACCEPTED**: at least one known-source AU received ACCEPTED from the injected fake sink. It does NOT guarantee real TLS bytes, real phone packetization, actual decoder configuration/input/decoding, rendering, display, or future health. Rejected input can be credited without entering this state. There is no MEDIA_RUNNING or displayed-frame counter.

Remaining M7 blockers:

* Actual phone NAL/CSD format and packet↔NAL/AU association; no arbitrary slice AU assembler claimed.
* Raw wire timestamp units/epoch and proper future decoder timestamp selection.
* Exact target config/failure/output ACK scheduling and sender credit behavior; count-only duplicate ambiguity.
* Streaming TLS/frame/plaintext association; no cryptography/credentials/handshake implemented.
* Full native Start/config/data/focus/reconfiguration/discontinuity ordering.
* Real ordinary-app transport ownership, separate live M5/M6 prerequisites, real TI decoder behavior and phone acceptance.

## Build, API and preservation

Java source7/target7 and D8min22 PASS;103 external method references resolve against saved actual D.1.6.4 API22 platform definitions. Installed SDK33 stubs compile the code; reference validation supplies the separate API22 check. Saved platform files reside under a folder named adb, but no adb executable was run. No host reader/oracle/fake/test class is included in production JAR/DEX. Constructor review: data/config/window/bridge fields only, no I/O, clock reads, automatic sends, threads, Android components, native loads, decoder allocation, socket or TLS activity. Explicit test calls alone invoke the provided fake sink.

Current session evidence root: `video-data-session-20261023-213714-604/`. It contains baseline snapshot, native dispatch, raw ffprobe JSON, clip hashes, independent2,700-sample comparison, final validation, protected inventories, reproducibility and exact file hashes. `latest-video-data-session.txt` identifies it; final build pointers and payload hashes are recorded there. Two final fresh builds are compared; ZIP timestamp-only container differences are documented independently from payload equality.

All69 historical APKs, both M4/M5 live reports and all four protected prior protocol evidence reports remain unchanged. Frozen M5 SHA256:

`A22E96490B9557AFF022893A8B8B7A08BB13CEC236E52704CDDAFA90A8EE8F40`

Created6 production modules,4host test modules,24fixture pairs+manifest,New-RdxVideoDataFixtures.ps1,Validate-RdxM7VideoData.ps1,this report,the evidence review,state-guarantee and coverage documents. Modified only old SimulatedSessionEngine accessors, build integration, README, build matrix, message coverage and chronological NOTES. Exact primary/generated paths and hashes are in the current session file inventory.

**NO ADB, VEHICLE, PHONE, USB HARDWARE, REAL TLS OR MEDIACODEC WAS USED.** No APK installation/build, Honda package/data change, display/settings change or active M6 operation occurred.

Most important new finding: codec-config0001 and timestamped0000 are distinct, but neither establishes an AU boundary; Honda also replaces the stored wire timestamp when queuing decoder input. The clean architecture now preserves these distinctions under bounded synthetic streaming rather than embedding unproven packetization/timing.

Recommended next OFFLINE investigation: narrow existing native crypto/framing association review to define the real TLS adapter's per-frame plaintext metadata contract, keeping CSD/AU format UNKNOWN until target evidence exists. This next task was not executed. **Next LIVE milestone remains M5 RETRY ONLY**, separately authorized. M6 stays disabled; M3 remains deferred.


## Final artifact references

Final fresh builds: build/20261023-215511-295 and build/20261023-215612-402. Byte-identical DEX SHA256:

`9EF47DB973CCD13726E149F96BDE10DDDB3DC234F94EA3B95C074BF8EB07597B`

Class/JAR-entry payloads match; JAR container hashes differ only with ordinary ZIP timestamp metadata. All46 transcript .txt payloads plus clip metadata/sample ledgers match (18 old session outputs,11 media outputs,24 video-output files including17transcripts+6CSV+metadata). All4 fixture manifests/bytes match. New validator rechecked103externalAPIrefs,2700independent sample comparisons,all protected artifacts/reports and frozenM5 after the final build.

Reproduction from project root uses scripts/Build-RdxCleanFoundation.ps1 (all suites) then scripts/Validate-RdxM7VideoData.ps1. Fixture authoring scripts/New-RdxVideoDataFixtures.ps1 is one-time and refuses to overwrite its manifest. scripts/Compare-RdxProtocolBuilds.ps1 checks library payload reproduction; current session/transcript-fixture-reproducibility.json covers the extra output directories and new fixture sets. Exact paths/hashes: current session/files-created-modified.csv and final-build-inventory.csv.
