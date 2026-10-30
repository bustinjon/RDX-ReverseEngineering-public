# M6 AOA-only offline validation — 2026-10-25

**OFFLINE-PREPARED / LIVE-DISABLED. No real AOA/USB/ADB/vehicle/phone execution. Next live M5 RETRY ONLY.**

The original57-module receiver remains unchanged. Actual fresh baseline/final receiver:110521 deterministic checks and8235885 property assertions PASS;20 more carrier checks than the previous110501 report arise from freshly generated disposable TLS certificate lengths. Source/test hashes, property counts and receiver DEX2FDBC63F…7FE7C235 match. No test was deleted/weakened. Full desktop TLS reruns use only PC memory queues/test credentials and deliver3300 AUs/47649547 bytes to fake decoder. API22 remains verdictD.

Standalone M6 adds9 modules/19 DEX classes,392 deterministic checks,9304615 property assertions,50000 fixed-seed sequences and62 deterministic transcripts. Seed5563706198314856497 (`0x4d36414f41323031`).5000 generated cases complete the synthetic bounded sequence; other cases vary attach/detach/permission/failure/clock/replay/close ordering. Receiver+M6 aggregate:110913 checks/17540500 properties, without merging target runtime claims. M6 and receiver count/reporting remain separately available in the session manifest. The unchanged separate M5 host regression also passes56 checks/2400000 properties over20000 existing sequences, seed5563443368177053746; it is reported separately rather than represented as new M6 coverage.

## Protocol evidence and encoding

Saved Honda `decompiled/AndroidAuto/sources/com/honda/androidauto/projection/sink/transport/usb/UsbHostSetup.java` lines115–123 corroborates51 IN vendor/2-byte response and52/53 OUT vendor. Its100000ms timeouts, unsigned parsing issue, un-terminated strings and force-claim paths were not copied. Saved AASDK `offline-followup/public/aasdk/f1xpl-aasdk-046b3b3/src/USB/AccessoryMode{ProtocolVersion,SendString,Start}Query.cpp` corroborates standard headers, supported1/2 and explicit NUL. No public implementation source was copied; manually encoded standard fixtures are checked independently.

|Action|bmRequestType|bRequest|wValue|wIndex|Length/policy|
|---|---|---|---|---|---|
|GET_PROTOCOL|0xC0|51|0|0|Exactly2 bytes, unsigned LE16;1/2 accepted,0/3/65535 rejected by M6 policy; no future-version assumption|
|SEND_STRING|0x40|52|0|0→5 once|UTF8 plus NUL;<=255 content bytes/256 including NUL; bad surrogate/embedded NUL rejected|
|START|0x40|53|0|0|Zero data, once, after all six strings accepted|

Strings: RDX Research / Clean Receiver / Bounded AOA M6 Test / M6-0.1 / empty URI / random run UUID. No Honda impersonation, machine identifier or phone serial. Empty URI is sent as one NUL; nonempty manufacturer/model/description/version/serial is clean policy, not a claim all six are protocol-mandatory. Protocolv2's audio/HID additions are unused; no request54–58 or audio mode.

`m6-aoa/fixtures/requests.tsv` has8 hand-authored setup/data rows, not production-code-generated. Query0000 is the initial response buffer, not OUT payload. `device-sequences.tsv` adds7 independent temporal expectations; proof-negative-cases.json records16 schema/provenance cases. Host tests consume both TSVs, validate all headers/bytes, bounds and signed negative proofs with an ephemeral non-project test key. No real project-signed M5 PASS artifact exists.

## State and ownership

NEW→GATE_CHECK→WAIT_TARGET→TARGET_SEEN→PERMISSION_VERIFIED (or PERMISSION_PENDING→verified)→OPEN_PENDING→PROTOCOL_PENDING→PROTOCOL_CONFIRMED→IDENTITY_PENDING (six bounded writes)→IDENTITY_SENT→START_PENDING→START_SENT→WAIT_DETACH→WAIT_REENUM→COMPLETE_STOP_REQUIRED.

19 states include ERROR/CLOSED/START_OUTCOME_UNKNOWN.17 normal progression edges include the string-write self-edge;16 change state. Failure/close/replay routes are additional and separately enumerated by observed-edge audit. States describe local intent/return/observation only. No state implies AA, GAL, TLS, phone receiver acceptance or exclusive ownership. Terminal states reject callbacks/events; completion never opens accessory mode or invokes M7.

Identity combines exact reviewed normal VID/PID, device id/path and attach generation; production invalidates cached generations on USB attach/detach broadcasts. Re-enumeration accepts a unique fresh observed18D1:2D00/01/04/05 in-window;02/03 audio-only/other PIDs are not data-mode success. New path is expected. Metadata/time correlation is not proof of same physical phone or exclusive causation. Multiple plausible identities, already-accessory mode or a switch before custom START stop INCONCLUSIVE.

Own-UID permission is checked before opening and every control transfer. See [package strategy](M5-M6-USB-PERMISSION-STRATEGY.md). Max one permission request/callback acceptance; wrong nonce/device/generation/stale/duplicate callbacks cannot advance. No retry after loss/deny/dismiss/timeout. Open once, close on failure/START return; no post-switch reopen/claim/bulk/reset.

Policy bounds (not AOA truth):300sec target wait,60sec permission wait,1000ms each transfer,10sec detach,15sec re-enumeration,420sec total,2048 core steps,32 inventory devices,32 interfaces,256 journal records/128KiB. Waiting polls500ms; actionable steps schedule promptly with no repeated request. Late observations/callbacks cannot bypass deadlines. Real negative controlTransfer result is ERROR/INCONCLUSIVE, not invented definitive protocol rejection; explicit mock REJECTED tests exercise the separate FAIL model.

## Durability, restart and failure

Each journal row: schema/run/sequence/relative monotonic ms/wall ms/state/event/detail/previous SHA256/current SHA256. Intent is flushed+fsynced before each actionable transfer. START_INTENT precedes the START call; START_RETURN follows confirmed return. Transfer headers/payload hashes/returned lengths/status/duration and target generation are preserved; raw phone serial is not read. File and in-memory stores share bounds. Truncated tail, bad checksum, unknown schema, wrong run, duplicate/order/time corruption fail closed.

No automatic resume after any interrupted run. START_INTENT without a durable return becomes START_OUTCOME_UNKNOWN terminal INCONCLUSIVE, never retry. Confirmed prior START also never retries. Completed journals remain evidence; replay does not fabricate a fresh PASS. Service is START_NOT_STICKY, same-run directory replay is refused, no boot receiver exists, and host runner permits one ARM. Host fsync/replay is tested; no OEM filesystem/power-loss durability guarantee is claimed. Missing evidence after power loss requires manual review, not rearm.

Coverage includes all six string failures, protocol/START rejection/timeouts, short/oversized protocol replies, open/permission errors, journal write boundaries/read corruption, crash at eight progression states plus uncertain intent, stale run, attach/detach storms, invalid callback, permission loss, multiple known/unknown phones, wrong VID/PID, late arrival, no detach/reenumeration and all allowed accessory PIDs. The50k event corpus enforces START<=1,transfers<=8,open<=1,request<=1, terminal/replay barriers and journal/event bounds. It is a model, not hardware proof.

Independent host M6EvidenceTool validates chain/order/intent-return/string/START/accessory accounting and preserves SYNTHETIC scope. Modified checksum is refused. A candidate PASS still requires actual signed M5 evidence, artifact/run provenance and human causation review.

## Verdicts and static packaging

PASS candidate: reviewed M5 gate, own permission, supported protocol, all six strings accepted, exactly one successful START, detach plus unique known fresh accessory observed in-window, complete consistent evidence. Wording: **bounded AOA sequence completed and accessory re-enumeration observed — temporal association, not exclusive causation**.

FAIL: demonstrated explicit functional rejection/unsupported version within M6 policy with complete evidence. Android -1 alone does not establish this. INCONCLUSIVE: permission/timing/setup/journal/observation ambiguity, competing Honda switch, missing evidence or uncertain START. Review before classifying platform restrictions. After any result, retrieve/hash/cleanup/postcheck and STOP; M7 is not authorized.

Final APK has3 fixed DEX controlTransfer callsites, no arbitrary request console, no interface claim/release/forceClaim/bulk/reset, no AA/GAL/TLS/media/decoder/Honda-JNI/network/settings/window mutation code. Zero requested permissions; one explicit Service; ordinary untrusted_app expectation, not a runtime SELinux result.137 external API22 references resolve; Java7/D8min22 PASS. Two clean builds have identical class/JAR-entry/DEX/manifest/assets/transcript payloads; signing/ZIP container metadata may differ. [Frozen record](M6-AOA-FROZEN.md).

Future runner and package were not installed or exercised on Android. The frozen gate always throws before manager lookup/action. Its build script refuses an active source flag and exposes no activation switch. A future reviewed activation release is required after M5 PASS; this is an explicit release gate, not missing broad architecture work. Stock Honda may independently start its own AA following re-enumeration; this AOA-only app cannot promise vehicle-wide absence of stock AA.
