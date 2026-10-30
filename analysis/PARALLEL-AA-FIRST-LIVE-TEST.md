# Parallel-receiver live-test plans and recorded outcomes

**Latest historical-plan outcome: live test02 reached M2.** Normal RETURN exit from Diagnostics preserved ADB; synthetic-only revision0.1.1 installed, ran as UID10050/untrusted_app, rendered1339x720 and cleanly exited/uninstalled. Native library was not loaded; M3 deferred due unproved ELF constructor safety. Factory APK/signer/package/geometry preserved. Honda's own lifecycle observer called its auto-start=false preference setter, so complete private-data equality is not claimed. [Live02 results](parallel-aa-receiver/LIVE-TEST-02-RESULTS.md), [current next plan](parallel-aa-receiver/NEXT-LIVE-TEST.md). Plans below are historical scope, not new execution authority.

**Historical plan below; first authorized attempt is now complete.** On2026-10-22 local, installation/removal passed as UID10049, but launch returned Lock Task Mode error5 before app process creation. Honda Diagnostics was already foreground in task2. No Surface/native/USB/decoder/overscan test ran. Factory APK/signature/package and window dump are unchanged. See [live-test01 results](parallel-aa-receiver/LIVE-TEST-01-RESULTS.md) and [next bounded test](parallel-aa-receiver/NEXT-LIVE-TEST.md). Do not replay this plan automatically; normal diagnostic exit is the next setup question and was not invoked.

Target2021 RDX D.1.6.4/API22/ARMv7. Factory AA and Candidate A/B stay intact. **The first proposed test is only ordinary install→synthetic Surface startup→uninstall, with no phone, native GAL, codec allocation or overscan.** This is a different, narrower risk than the previously rejected stock-package/root tests. Normal removal is code-backed but has not yet been demonstrated for this new package on the vehicle.

The commands below are documentation only. No install, launch, decoder test, USB grant/open, force-stop, uninstall or overscan was performed. Read-only investigation logs are separate. Do not batch all stages into one approval or run later stages automatically after L1.

## Preconditions for any approved L1 test

1. Confirm exact firmware and approved artifact SHA256 against [build-report.json](parallel-aa-receiver/build/build-report.json). New package must be absent; if present, stop rather than install with `-r` or remove an unknown prior app.
2. Verify stock package codePath/version/shared UID and preserve a fresh local APK/native hash baseline if the old capture is insufficient. Read-only pulling existing files is suitable; do not write back to them. Stock remains installed/enabled and is not force-stopped.
3. Confirm no phone projection session is active. If a phone is present, do not make changes to its connection or stock lifecycle under this test; defer until an explicitly approved test setup is available. Avoid vehicle power/ignition transitions during measurement: OEM StateMachine may stop ordinary com.rdx apps.
4. Independently available ADB must be able to remove the new ordinary package. Do not change unknown-sources settings, verifier settings, user restrictions or any OEM configuration to make installation succeed. A denied install is a finding and stop condition.

## Exact L1 commands and observations

From project root, **after separate approval only**:

[Code block omitted from public report; see authored source where available.]

Expected: installation Success, code under `/data/app`, own non1000 app UID, launch success, experimental title and synthetic Surface; logs identify actual UID/API/ABI and Surface dimensions. Default launch does not load native GAL or allocate a codec and does not request USB permission. No phone handshake/config selection/video success is inferred from the synthetic image.

Expected stock geometry is approximately1339x720 under the previously captured OEM policy; actual custom-app dimensions are the measurement. No correction is applied if different. First launch must not require working TTI: startup geometry logs are automatic and no controls need activating.

## Exact L1 rollback

Use app Exit/back if available. If the test app hangs, the approved cleanup target is **only the new package**:

[Code block omitted from public report; see authored source where available.]

Expected: uninstall Success; no package path for the test app; factory AA still codePath `/system/app/AndroidAuto`, UID1000, versionCode22/versionName5.1.1-14, enabled/installed. Compare any pre/post stock APK/native pull hashes locally. Do not clear package data or uninstall/disable factory AA if anything fails. No reboot is required by this design.

Normal app installation changes `/data/app`, its own `/data/data`/cache/native extraction, PackageManager/signature/user records and ordinary logs/launcher metadata. Uninstall is expected to remove that package and its private data/code; it is not byte-for-byte rollback of global package files, logs, timestamps or OEM observers' own bookkeeping. It does not rewrite `/system`, `/persistdata`, original AA code or stock private data through our app.

Worst credible L1 outcome on present evidence is rejected install, test-app crash/ANR, UI/resource issues or OEM termination of the ordinary app. PackageManager/storage/media failures cannot be proved impossible on this unit; no claim of demonstrated head-unit recovery is made. Risk: **LOW relative to the other proposed methods**, bounded to a new unprivileged package. If removal fails, stop and investigate that exact failure; do not use factory reset/flashing as cleanup.

## Later stages: separate decisions, same ordinary package

| Stage | Exact invocation/action | Changed state / expected evidence | Rollback / worst case | Risk |
| --- | --- | --- | --- | --- |
| L1 inventory | Launch with `--es stage inventory`, or press L1 inventory | Enumerates codecs and allowed AOAP entries/hasPermission only; no open/grant/codec allocation. | Exit/uninstall new package. Listing is not hardware decode proof. | LOW |
| L1 codec allocation | Press `L1 TI allocate/release` after separate approval | Creates TI component, immediately releases; no configure/start/frame feed. Tests availability/resource arbitration. | Exit/uninstall new package; should release handle even on Java exception. Native media-service/driver failure could affect other users of shared resources. | MODERATE |
| L2 native only | Clean launch `am start -W -n com.rdx.fullscreen.projection/.ReceiverActivity --es stage native` | Loads unchanged ARM library, initializes local native GAL/SSL credentials, registers/configures video service. **No USB open/native protocol start or decoder allocation.** | Stop/Exit; own-package force-stop/uninstall if needed. Native crash/ABI error confined by normal process boundary, but native teardown is unproved. | MODERATE |
| L3 permission | With an already enumerated allowed AOAP phone, press L3 USB grant | System permission UI/per-device map; no automatic open/start. Dialog may pause app, which closes L2 session; initialize a fresh L2 afterward. | Stop/uninstall test app; detach session/phone only as separately authorized. Avoid setting any default app. Per-device grant lifetime may extend until disconnect; no stock prefs changed by prototype. | MODERATE; defer until coexistence plan exists |
| L3 claim / L4 handshake / L5 config | Press L3 start AOAP only after ordinary grant, fresh L2 and independent ownership approval | Non-force interface0 claim; native protocol threads/TLS/discovery. Config-selection callback is L5; primary index0 is Candidate A. No mode switch or reset. | Stop closes/releases only our FD, prepares native shutdown, joins workers and releases own objects. Own-package force-stop/uninstall if cleanup stalls. Stock may retry/reset phone, so app uninstall alone is not a guaranteed live-session handback. | HIGH currently because arbitration unresolved; **not recommended yet** |
| L6 video | No separate automatic action beyond a successful approved session; frames configure TI decoder | Actual decoded outputs, format/SPS crop, Surface/fit geometry and errors. Audio/input unsupported. | Stop own session/decoder and uninstall; restore standard phone/session through a separately understood sequence. Decoder resources may conflict with stock; code-success logs alone do not prove visible fullscreen. | HIGH until prior stages pass |

Do not add an AOAP mode-switch/forced-claim workaround when L3 cannot proceed. The current prototype intentionally requires an already enumerated phone; its absence or a busy claim is the stopping boundary. Root, reset-socket commands, stock force-stop/disable and global routing changes are not fallback steps.

For an eventual approved phone trial, the desired lifecycle remains verify stock→install new app→launch test→connect phone→observe→stop→uninstall→verify normal factory operation. **That complete lifecycle is not ready yet** because phone attach automatically reaches stock and a safe lease/handoff is unproved. Do not claim choosing our launcher alone suppresses Honda. Verifying factory projection with a phone afterward is itself a separately approved functional step, not one of the read-only checks performed now.

## Optional fullscreen window stage: separate persistent setting

First confirm normal install/Surface/removal and useful video independently. The app advertises Candidate A regardless of whether the window is narrow; negotiation and geometry must not be confused.

Matching WMS code writes overscan to `/data/system/display_settings.xml` through AtomicFile. Therefore the historically effective command is a **persistent global display-setting change that is reversible**, not RAM-only state and not part of uninstall. It can affect stock UI, right-side panel layout and input geometry for other apps. No overscan command was executed here.

Future documentation only:

[Code block omitted from public report; see authored source where available.]

If the baseline was not the reset/default state, restore its exact captured left/top/right/bottom tuple instead. Do not invent it. Confirm previous Surface/window geometry afterward; app uninstall does not do this. No reboot is needed for the setting application/restore, and reboot is not a reliable way to clear it. Worst case is global UI clipping/input displacement/control difficulty until restored; risk **MODERATE**, with ADB-based restoration required before application. Defer if the original values or control path cannot be recorded.

## Observation rules and success labels

- L1 = own Activity/Surface, then optional codec facts; synthetic pixels are not AA video.
- L2 = local native load/SSL/video-service setup; configuration added locally is not phone advertisement.
- L3 = authorized exclusive FD/claim; permission alone is not ownership.
- L4 = actual handshake/service discovery; L5 = selected source configuration callback; L6 = actual decoder output plus visible/crop geometry validation.
- Each stage remains NOT RUN on the vehicle. Record failure as permission, policy/AVC, busy claim, JNI/linker, TLS, service catalog, decoder or geometry; do not collapse it into “requires system UID.”

The current recommendation is to seek approval **only for the bounded L1 experiment when desired**, after reviewing the artifact and its cleanup. No installation or approval request was issued as part of this offline task.

## 2026-10-23 offline implementation/build continuation

No vehicle/ADB operation or new live milestone. Historical M0–M2 remain PASS; M3 remains deferred/off critical path. Clean ordinary-app receiver remains preferred. Existing M4 APK BAD93C688F7019E4205DC86EF34E6078B695623DB85770C789F29B0A3CFF4148 independently aapt/JADX/DEXDUMP/source/control-flow audited: READY FOR BOUNDED LIVE M4 TEST, not yet run. No Activity, permissions, filters, native library or USB open/request/claim/transfer. Grid built/audited; decoder built/audited with named TI codec/no fallback but all six clip assets absent, so not ready for decoding. Read-only explicit-serial capture tool prepared; only its offline PlanOnly branch executed. M5 source compiled/design only; M6 documentation only. Candidate A/B, factory files, original prototype and raw logs preserved.

New warning evidence identifies installation detector com.honda.maliciousdetector (MDBroadcastReceiver/MDService; package-scheme/BOOT receiver) and runtime scan log naming our installed package. Exact later warning dialog/class/resource, authorization predicate, persistent state and Dismiss code remain unresolved because its APK is missing locally. Successful uninstall does not prove OEM history cleared; a later warning does not prove APK remnants. Headless M4 avoids the identified Activity-resume path, not installation detection. Stock AA can still react to phone attachment with auto-start=false. Never suppress it for M4.

Future first fullscreen video target1920x720 active/30fps/229dpi remains an experiment; nominal1080/margins0,360 does not prove encoded SPS/crop/input coordinates. No180px touch offset or TTI width change. Grid has no overscan mutation; overscan is separate persistent state, not automatically rolled back by uninstall.
Current detailed continuation: [report/procedure](parallel-aa-receiver/NEXT-LIVE-TEST.md). Prior findings above retain their original chronology and uncertainty.


## 2026-10-23 portable toolchain, clips and foundation continuation

Offline only; no ADB/installation/vehicle operation. Cleared M4 APK remains BAD93C688F7019E4205DC86EF34E6078B695623DB85770C789F29B0A3CFF4148 and was not rebuilt. NEXT LIVE SESSION REMAINS M4 ONLY, GPT-6.1 Sol High. No decoder/grid/M5/M6 or MaliciousDetector acquisition combined with M4.

Project-local FFmpeg9.0.2 obtained from the FFmpeg-listed Gyan build, publisher checksum/archive/binary provenance recorded, no installer/global PATH change. All six10sec Constrained Baseline/yuv420p/no-B clips generated with moving grids/counters/edges, ffprobe/frame/GOP/SPS/PPS evidence. Independent SPS parser confirms1080 clips coded1920x1088 cropped8px bottom to1080;720/688 clips unpadded. These are SYNTHETIC clip results, not measured phone AA raster/margins/touch. No180px offset inferred.

Decoder0.2.0-with-clips APK ADD395FC46626DD3C43F527E10B1D8C49092DB43C8088CAEABB4A553BE90A374 built/independently audited with all six stored hash-verified assets, explicit TI only/no software fallback. Ready for a separately authorized decoder session, no TI execution demonstrated. Historical0.1 APK/source preserved. M5 APK757726DE360D466ACE5F7C12A90DE5B4377F2BD19D8D4BD8C13879967FDE95C8 built/audited but DO NOT RUN BEFORE LIVE M4 PASS; one permission request gated by explicit action/ack/current exact device identity. No open/claim/transfer/AOA.

Clean receiver foundation21 Java modules compile to API22 library JAR/DEX, NOT APK.67 synthetic host checks PASS. Frame parser/writer/post-TLS reassembly and capability models implemented; active USB/AOA/TLS/control/video disabled/stubbed, constructors local only. Fullscreen model active1920x720/229/30 with UNSPECIFIED crop/input placement; default remains conservative1280x688/229/60. No credentials/native receiver included. Clean ordinary receiver still preferred; M3 deferred/off critical path. Exact warning implementation still missing; separate read-only MaliciousDetector acquisition procedure prepared, no bypass or collection.
Detailed continuation: [report](parallel-aa-receiver/OFFLINE-CONTINUATION-CLIPS-FOUNDATION-20261023.md). Earlier statements above remain historical; the current matrix and latest audit identify reviewed builds.

## 2026-10-23 pure protocol-core continuation

Host-only library work completed:31 modules,261 deterministic/23059 property assertions PASS; bounded codecs, state/registry and fake transcripts. No APK/device operation or live compatibility proof. Existing cleared artifacts unchanged. [Results](parallel-aa-receiver/clean-receiver/PROTOCOL-CORE-RESULTS-20261023.md). **The next live procedure stays M4 ONLY**, without M5/M6/decoder/grid/native-load/TLS/projection additions. M3 deferred.

