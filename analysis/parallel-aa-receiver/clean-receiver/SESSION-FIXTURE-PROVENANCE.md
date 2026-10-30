# Session fixture provenance

22 .bin/.json fixtures and manifest under test-fixtures/session. Authored independently by scripts/New-RdxSessionFixtures.ps1 using its own BE header, tag, varint and length construction, never production Java codecs. Expected video bytes and base control/media scalar bytes are literal vectors; independent full HU advertisements are assembled from explicit fields/strings. The script refuses to overwrite a manifest. Production code never generates expected fixtures during tests.

|Fixture family|Precise local source/layout evidence|Limits|
|---|---|---|
|version-request/response,unsupported/malformed version|CONTROL provenance and existing ControlMessages.Version: raw BE16 major/minor[/status], not protobuf|Only base1.1 modeled; extensions UNKNOWN, not guessed|
|discovery-request|Existing DiscoveryRequest tags4/5, pinned control definitions|Strict local subset requires both strings; not a global requiredness claim|
|discovery-conservative/experimental/unknown-service|Existing discovery root repeated service1; service ID1/video3/input4; nested H264 codec3/config4; prior field-confidence inventory|These are LOCAL HU advertisements, not phone-supplied responses; service99 intentionally unsupported|
|open-video/input|Pinned AASDK/Honda/OHU control fields, ZigZag priority1/serviceID2; per-service CONTROL flag|Nonidentity mappings are a local lookup test, not proved phone binding|
|video-conservative/experimental|Honda VideoSink nominal resolution/margin fields; exact pre-existing vectors|No SPS/crop/touch or phone acceptance inference|
|media-setup|A-ID/A-SETUP/O-AV in MEDIA-CONTROL-EVIDENCE.md|Field1=3 raw; meaning deliberately UNKNOWN|
|media-start|A-START/O-AV fields1session/2config|Engine does not advance to running|
|media-stop|A-STOP/O-AV empty base|No invented response or lifecycle ordering|
|media-ack|A-ACK/O-AV legacy session1/count2|Not display acknowledgment; newer timestamp-only modes out of supported typed subset|
|ping-unknown|Known timestamp1 plus literal unknown99=7|Raw retained; typed response does not echo unknown request fields|
|shutdown-request/response|Prior control definitions/Stop reason1 and empty base response|Local strict stop policy, not universal lifecycle proof|
|malformed-frame/partial-frame/first-fragment|Existing independent framing oracle's structural layout/flag rules|Synthetic deadlines, not production timeout values|

Each metadata file records ID/raw hex/decoded expectation/before-after states/confidence/unknown notes/SHA256. Source file hashes are in current m7-session/media-reference-hashes.json. The full14-column message/state coverage matrix is MESSAGE-STATE-COVERAGE.csv.

An initial draft fixture-authoring script accidentally flattened the four-byte unknown-service entry into four one-byte entries (PowerShell jagged-array conversion). The new engine's test rejected it. The draft was preserved under the M7 evidence directory and the independent generator was corrected; no production decoder or assertion was weakened. A separate first draft invoked PowerShell's h history alias; it was renamed HexBytes before fixture creation. No original28 v1 golden fixture changed.

No private authentication material. AASDK/OAA remain GPL reference context; no upstream implementation/runtime was copied. Synthetic metadata strings identify offline research rather than a real vehicle VIN/device identity.
