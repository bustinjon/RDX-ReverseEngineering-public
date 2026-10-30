# M6 offline implementation and freeze — 2026-10-25

**M6: OFFLINE-PREPARED / LIVE-DISABLED. Next LIVE: M5 RETRY ONLY. M7: NOT AUTHORIZED.**

The separate M6 core, simulator, disabled Android APK and future tooling are complete for review. The frozen APK unconditionally refuses live progression. A small separately reviewed activation release, actual reviewed M5 PASS and explicit M6 authorization are still required; no flag or script can activate this artifact. Android glue and actual USB behavior have not been run.

The important finding is that M5's USB grant does not transfer to a separate M6 UID, and detach invalidates a device grant. M6 must request its own exact-attachment permission normally after M5 proves that permission path. Stock Honda can switch the phone first; that is an INCONCLUSIVE stop, never permission to race/retry or interfere with Honda.

## Requested results

|#|Item|Recorded result|
|---|---|---|
|1|Starting baseline|Actual 57 modules /110,521 deterministic /8,235,885 properties PASS. Previous 110,501 differs by20 disposable-certificate/handshake-carrier checks; original sources/tests/DEX/properties unchanged.|
|2|Final modules|Receiver57 unchanged; separate M6 adds9 production modules,19 DEX classes. Not a66-module receiver build.|
|3|Final deterministic|Receiver110,521; M6 392; receiver+M6 aggregate110,913 PASS. Existing separate M5 regression56 also PASS, reported separately.|
|4|Final properties|Receiver8,235,885; M6 9,304,615; receiver+M6 aggregate17,540,500 PASS. Existing separate M5 regression2,400,000 also PASS.|
|5|New sequences|50,000 M6 event sequences, including5,000 complete synthetic sequences; not live USB transactions.|
|6|Seeds|M6 5563706198314856497 /0x4d36414f41323031. Existing desktop TLS23727818689957712, AA18367703799771442; M5 regression5563443368177053746.|
|7|Scaffold|Original receiver AoaNegotiator remains disabled; isolated M6 implementation supersedes the old planning-only scaffold without activating it. [Audit](M6-CURRENT-SCAFFOLD-AUDIT.md).|
|8|States|19 explicit states; [guarantees](M6-STATE-MACHINE.md).|
|9|Transitions|17 normal progression edges including one repeated-string self-edge;16 change state.34 exercised changing-state edges in transcripts, not exhaustive graph proof.|
|10|M5 gate|Strict signed reviewed metadata, pinned project review certificate, exact frozen M5 identity and actual evidence-bundle SHA256; no force/debug/env bypass. Additional unconditional frozen live block.|
|11|Proof schema|13 ordered LF-terminated key=value fields plus detached SHA256withRSA signature. [Schema](m6-aoa/proof-schema.json). Project review provenance, not device attestation.|
|12|Gate negatives|Missing/FAIL/INCONCLUSIVE/wrong APK/package/version/schema/counts/hash/callback/grant/provenance/signature/malformed/contradictory fields refused. Ephemeral TEST-key fixtures only; no actual reviewed PASS created.|
|13|Permission scope|Saved UsbSettingsManager keys device permission by UID and removes it on detach. Same signer alone does not share UID.|
|14|M5 grant transfer|NO. Separate package and fresh normal-phone attachment require an independent M6 grant.|
|15|Package strategy|Separate ordinary M6 package for artifact isolation; preserve frozen M5. No shared system/Honda UID.|
|16|Own request|Yes, if own hasPermission is false: one standard request, manual ALLOW, nonce/device/generation validation, fresh hasPermission before actions. Deny/dismiss/timeout stops.|
|17|Identity|Immutable VID/PID/deviceId/path/interface summary/generation/observation time; no path-only identity. Phone serial not read; no serial leakage.|
|18|Fake environment|Scripted inventory, attach/detach, permission, transfers/errors, time and competing switches; core shared with future Android glue. No UsbManager execution.|
|19|GET_PROTOCOL|One0xC0/51/value0/index0/length2 request; unsigned little-endian response, exact2 bytes.|
|20|Version policy|AOA1/2 accepted;0/3/65535/short/oversized/error rejected or classified conservatively. No audio/HID extensions.|
|21|SEND_STRING|0x40/52/value0/index0..5, deterministic order, UTF8+NUL, <=256 total bytes; invalid NUL/surrogate/oversize/index/duplicates/missing local fields tested.|
|22|Strings|RDX Research; Clean Receiver; Bounded AOA M6 Test; M6-0.1; empty URI; random run UUID. Required nonempty local fields are clean policy, not all claimed mandatory by AOA.|
|23|START|0x40/53/value0/index0/zero bytes; hard one-attempt guard.|
|24|Exactly once|START_INTENT durable before call, no retry path, uncertain crash terminal.50k sequences plus explicit storms/restarts/callback tests enforce <=1.|
|25|Max controls|8 total: one query +six strings +one START; no retries. One open, one permission request maximum.|
|26|Journal|Append-only chained SHA256, relative monotonic and wall time, run/schema/sequence/state/identity/permission/transfer/result; flush+FD.sync.256 records/128KiB bound. Host evidence only, not OEM power-loss certification.|
|27|Crash/restart|Explicit crash/replay boundaries, corrupt/truncated/order/schema/run/time cases fail closed; no automatic resume/rearm. Service START_NOT_STICKY; repeated run directory refused.|
|28|Uncertain START|START_INTENT without durable successful return => START_OUTCOME_UNKNOWN, terminal INCONCLUSIVE, manual review; never auto-retry.|
|29|Re-enumeration|Original detach then unique fresh known accessory in bounded window; path change supported. Temporal/metadata correlation cannot prove exclusive causation or physical continuity.|
|30|Accessory IDs|18D1:2D00/2D01/2D04/2D05 accepted for observation. Audio-only02/03 and unknown IDs not success. Normal targets22D9:2769/2765.|
|31|Honda race|Switch before custom START => external/Honda switch possible, INCONCLUSIVE stop. Stock app is never controlled.|
|32|Already accessory|Observe and stop INCONCLUSIVE; never open/accessory START.|
|33|Multiple devices|Multiple plausible candidates => stop; no guessing. Unknown plausible phone alongside known target tested.|
|34|Permission loss|Recheck before open/every transfer; loss stops immediately, no reopen/retry.|
|35|Transfer failures|Fail fast/close; explicit modeled rejection distinguishable from generic Android negative return. Real negative return is ERROR/INCONCLUSIVE unless evidence proves rejection.|
|36|Timeouts|Policy: target300s,permission60s,each control1s,detach10s,reenum15s,total420s; late events cannot bypass deadlines.2048 event limit.|
|37|Transcripts|62 deterministic M6 transcripts, plus original receiver55 semantic transcripts/7 support files unchanged.|
|38|Properties|9,304,615 M6 assertions PASS: start/transfer/open/request bounds, gates, terminal/replay behavior, no unbounded storm/history, no wrong-device advancement.|
|39|Independent fixtures|8 hand-authored raw request rows +7 device-sequence rows;16 negative-proof categories. Receiver120 independent fixtures retained.|
|40|Forbidden-call audit|Final actual DEX/manifest/assets audited:3 fixed controlTransfer callsites, no arbitrary request path, host/test classes/private keys/native libraries absent.|
|41|claimInterface|Absent. releaseInterface also absent.|
|42|bulkTransfer|Absent; no endpoint read/write.|
|43|forceClaim|Absent.|
|44|reset|Absent; no reset/reopen loops.|
|45|GAL|Absent.|
|46|TLS|Absent from M6. Existing receiver desktop RAM TLS regression ran with disposable test credentials; no phone/vehicle TLS.|
|47|MediaCodec|Absent; not executed.|
|48|After START|Observation only; accessory never opened. COMPLETE_STOP_REQUIRED cannot cascade to AA/M7.|
|49|APK build|PASS, two fresh final builds; Java7, D8 min22,137 saved API22 external methods resolve. Android runtime untested.|
|50|APK path|[rdx-m6-aoa-only-disabled.apk](m6-aoa/build/FINAL/rdx-m6-aoa-only-disabled.apk).|
|51|APK SHA256|D4DAC2DD8B2AFF1FA7B64BFB32D2A5E889854CCEB4B4A9F7AD5AEF89FB28761F|
|52|Package/version|com.rdx.fullscreen.m6aoa /0.1.0-m6-aoa-only-frozen /code1 /min22 /target22.|
|53|Signer certificate SHA256|C001F59B25081DDFC73937155CA3580717E817C45C66E68B9E059737B0B28831; ordinary project test signer, not Honda.|
|54|Manifest|Zero requested permissions; one explicit exported Service; no boot/default USB handler/auto-start. Test-only/debuggable for private evidence retrieval.|
|55|App context|Ordinary untrusted_app expected; not a measured runtime SELinux/USB result. No privileged/shared system UID.|
|56|Safety manifest|[M6-LIVE-SAFETY.json](m6-aoa/M6-LIVE-SAFETY.json), allowlist51/52/53 with exact headers/bounds and liveExecutionEnabled=false.|
|57|Preflight|Hash/package/version/audit/reviewer proof checks prepared; host-tested; does not install or invoke ADB.|
|58|Future runner|Explicit staged runner prepared. Current frozen artifact refuses all live stages before ADB, even with authorization text. No activation switch.|
|59|Retrieval|Prepared private journal/summary/proof/config +system USB log/hash retrieval; independent evidence parser. Missing evidence INCONCLUSIVE; no automatic retry. Not run on Android.|
|60|Cleanup|Prepared retrieval-first uninstall/process/package checks and read-only factory APK/signer/display comparison; no Honda data clearing/equality claim. Not run live.|
|61|Single port|Arm/durable acknowledgement while laptop connected; exit for manual phone swap; no ADB dependency during phone period; reconnect/retrieve afterward. Permission dialog manually allowed only.|
|62|Verdicts|Conservative PASS/FAIL/INCONCLUSIVE; host oracle preserves SYNTHETIC_PASS_NOT_LIVE_M6 on synthetic evidence.|
|63|PASS|Valid gate, own permission, supported query,6 strings accepted, exactly1 successful START, detach +known fresh accessory, complete consistent evidence; reviewed temporal association only.|
|64|FAIL|Demonstrated functional rejection or unsupported protocol under policy with adequate evidence; generic -1/timeout alone insufficient.|
|65|INCONCLUSIVE|Missing permission/target/callback/evidence, setup/timing, Honda-first, ambiguous identity/detach, uncertain START, generic errors.|
|66|Causation|“Bounded AOA sequence completed and accessory re-enumeration observed”; never exclusive custom causation from timing alone.|
|67|Frozen report|[M6-AOA-FROZEN.md](M6-AOA-FROZEN.md).|
|68|Permission report|[M5-M6-USB-PERMISSION-STRATEGY.md](M5-M6-USB-PERMISSION-STRATEGY.md), exact saved service/framework anchors.|
|69|Decision tree|[Next live decision tree](NEXT-LIVE-DECISION-TREE.md): M5 PASS→STOP/review→separate M6 activation release/authorization; FAIL/INCONCLUSIVE→no M6.|
|70|Project state|[PROJECT-STATE.json](PROJECT-STATE.json), index/build/freeze/current README updated; historical reports retained.|
|71|Regression|All receiver suites/full real desktop TLS repeated PASS; original M5 regression56/2,400,000 PASS; M6 suite PASS;16 M6 host-tool checks and27 existing freeze-tool checks PASS. No old test weakening.|
|72|Receiver DEX|2FDBC63F2F9D63B764697D311AF89D460AE6B8E14B0FADABA9C9339F7FE7C235 unchanged. Separate M6 DEX21E02321DBA74E245FD863EC56D45A3DF3A76C622B6BF683249EB12961B5C0B1.|
|73|API22 references|Receiver166/M6 137 resolve. Qualification remains D: API22 RUNTIME TEST UNAVAILABLE; static surface != runtime conformance.|
|74|Java7|PASS for both production source sets.|
|75|D8|min-api22 PASS for both.|
|76|Reproducibility|Receiver and M6 final pairs: identical classes/JAR-entry/DEX/manifest/assets and deterministic transcript expectations. ZIP timestamps/signature-container metadata differences documented; TLS randomness not compared.|
|77|Frozen M5|A22E96490B9557AFF022893A8B8B7A08BB13CEC236E52704CDDAFA90A8EE8F40 verified unchanged; never rebuilt.|
|78|Historical APKs|Original69 and all APKs present at task start hash-preserved. New M6 builds are separate additional artifacts.|
|79|Live reports|M4/M5 reports hash-preserved; no live evidence rewritten.|
|80|Qualifier|Unchanged86350131FFC5CBE5766E523AB03AE07D4C9F5EAD78F0570B68255C9A3999FC1F; no new Android run.|
|81|Boundary|No ADB, vehicle, phone, physical USB, real AOA, Honda credentials/JNI, GAL, phone TLS, MediaCodec, installation or factory software changes. No downloads.|
|82|Most important finding|Permission is per UID and attachment; M5 eligibility evidence cannot stand in for M6's own normal-device grant.|
|83|Biggest uncertainty|Stock Honda may switch within the permission choreography; real ordinary-app open/control and timing remain unknown. No offline model can establish live ownership/causation.|
|84|Offline-ready?|Yes as a frozen disabled review candidate with tested pure core and prepared future glue/tooling; not a runnable live approval.|
|85|Live-disabled?|YES, unconditional packaged block plus gate checks; scripts refuse current artifact.|
|86|Prerequisites|Actual reviewed M5 PASS imported/signed against exact frozen artifact, separately reviewed minimal activation release/static audit, explicit M6 authorization, own exact-attachment permission and no competing switch.|
|87|Next LIVE|M5 RETRY ONLY.|
|88|After M5|Retrieve/hash evidence, cleanup/postcheck, classify/review, STOP regardless of result; no automatic M6.|
|89|Future PASS action|Review M5 evidence and this disabled M6 freeze/permission strategy; only then consider activation release and separately authorize an M6-only test.|
|90|More broad M6 offline work?|Not justified without new M5/runtime/USB evidence. Targeted activation review and live-result-driven fixes remain, not another speculative development cycle.|

## Evidence and exact file inventory

Session: `m6-offline-20261025-130328-474`. [Machine results](m6-offline-20261025-130328-474/session-results.json), [receiver reproducibility](m6-offline-20261025-130328-474/receiver-reproducibility.json), [M6 freeze](m6-aoa/FROZEN.json), [M6 reproducibility](m6-aoa/reproducibility.json), [file inventory](m6-offline-20261025-130328-474/FILE-INVENTORY.md), [CSV hashes](m6-offline-20261025-130328-474/FILE-INVENTORY.csv), [integrity manifest](PROJECT-INTEGRITY.json).

The inventory includes retained intermediate/failed-build diagnostics so they are not confused with final frozen outputs. Fresh desktop test PKCS12 containers were deleted after regression; hashes/metadata remain. Preexisting project signing key was untouched. No secure-erasure claim is made.
