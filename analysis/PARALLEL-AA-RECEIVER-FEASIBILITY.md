# Parallel Android Auto receiver: feasibility decision

Exact target2021 Acura RDX D.1.6.4 / Android5.1.1 API22 / ARMv7. Factory package, original files and Candidate A/B were not changed. Prior recovery/root/update audits were reused, not repeated.

**Latest: live test02 passed M0/M1/M2.** Normal Diagnostics RETURN exit released lock task and retained ADB. Isolated synthetic revision0.1.1 ran as UID10050/untrusted_app and rendered/measured1339x720, then cleanly exited/uninstalled. M3 deferred: actual ELF constructors exist and load-only safety was not proved; no native/GAL/USB/decoder ran. [Results](parallel-aa-receiver/LIVE-TEST-02-RESULTS.md), [next gated plan](parallel-aa-receiver/NEXT-LIVE-TEST.md). **Stock APK/signer/package are unchanged; all-private-data equality is not claimed:** Honda's own APP_LAUNCHED observer called its auto-start=false preference setter when our Activity resumed. No direct app/agent Honda-data write or restoration was performed. This supersedes the earlier launch and “wholly untouched data” assumptions; underlying static protocol/USB feasibility remains unproved at runtime.

**Live test01 update, 2026-10-22 local:** normal install and uninstall of the separately signed APK succeeded, UID10049. Launch failed before process creation with **START_RETURN_LOCK_TASK_MODE_VIOLATION=5** while Honda Diagnostics task2 was foreground. No custom Surface/domain/native-load milestone was reached. Factory APK/signature/package and full window dump match before/after. [Results/raw evidence](parallel-aa-receiver/LIVE-TEST-01-RESULTS.md), [next bounded plan](parallel-aa-receiver/NEXT-LIVE-TEST.md). The earlier static expectation of an ordinary launch is now conditional on leaving the existing diagnostic lock task. No phone, USB, native GAL, decoder or overscan was tested.

**Prioritize a disposable ordinary-UID receiver.** The core data path is public USB host→local GAL native engine→public MediaCodec→own Surface. The protected GAL socket is reset control, not transport. No mandatory Honda signer/system UID check was identified in the traced core. An independently signed staged prototype has been built and statically checked.

**A complete second receiver is not yet demonstrated.** The principal unresolved system interaction is exclusive ownership of the phone interface while Honda's attach receiver/service remains active. Native initialization, normal USB grant/open, a safe claim, phone acceptance of a video-only service catalog,60fps decode and actual full-window geometry all remain untested in the custom app. No live milestone is claimed.

## What was established

- Stock's GalService/ConnectionManager/UsbHostDelegate opens the phone directly with UsbManager.openDevice. Stock UID1000 gets automatic USB permission; the same framework explicitly implements normal-app user permission and a public FD-brokering path. No required Honda transport Binder or `/data/misc/gal/socket` data stream was found.
- `/data/misc/gal/socket` is used by GalUsbReset to request VBUS/device reset. The root usbresetserver binary/process/path were identified. Exact socket owner/group/mode and full effective policy remain unknown but are not minimum-video dependencies.
- Current libautoreceiver_jni.so uses Google protocol JNI class names, ordinary32-bit library dependencies and Java-supplied protocol credentials. Those class names can remain inside a manifest package named com.rdx.fullscreen.projection. No original Honda application DEX/resources are needed by the small native-facing prototype.
- Stock protocol credentials are static software values supplied by PlatformCertKeysImpl, not a hardware/private Binder keystore lookup. Their private-key/certificate pairing was checked without putting private contents in reports. Native TLS setup is separate from the new APK signer and Honda OTA signing.
- Stock rendering uses public MediaCodec. A normal app can request the same TI component; decoder resources/codec limits/runtime access remain to be proved. Candidate A's1080-profile60fps reaches the XML's declared macroblock-rate ceiling.
- Current permission definitions show protected OEM integration is mixed: amplifier/state/VCS/analog/VR and media control are restricted; navigation provider/consumer definitions are normal. It is incorrect to collapse all Honda functionality into “requires UID1000.” The prototype requires none of these for startup/native setup.
- The build is minSDK21/targetSDK22, ARMv7, DEX035, development-signed and without sharedUserId, permissions, OEM services/providers or attach receivers. Static checks match22 native signatures,19 callbacks,16 fields and buffer-pool ABI; native bytes are unchanged. These checks are preparation, not native execution.

## Direct answers to the twelve decision questions

| Question | Answer |
| --- | --- |
| 1. Can a completely separate normal APK act as receiver? | **Technically plausible, with no mandatory core system-UID gate found; complete operation is unproved.** Public USB/grant/native/MediaCodec paths exist. Stock transport arbitration and phone catalog acceptance are the main unresolved parts. |
| 2. If not fully, how far can it get? | Live M0/M1/M2 passed with a synthetic-only revision: ordinary install, process/Surface/UI1339x720 and cleanup. No receiver native/GAL/phone/decoder execution demonstrated. Original full prototype remains unchanged. |
| 3. FIRST privilege boundary? | Earlier diagnostic lock-task boundary was resolved through normal RETURN UI. Next is **load-time native safety**, a review gate rather than a proven privilege denial. USB per-device grant/effective policy and exclusive ownership remain later runtime boundaries. |
| 4. Does transport require UID1000/signature/system_app? | No such requirement found for the public USB data path. UID1000 bypasses the grant dialog; ordinary UIDs can be granted. Effective MAC and ownership still apply. Reset-socket access is separate and omitted. |
| 5. Can the native library be reused unchanged? | Yes as an offline packaged candidate, preserving JNI ABI and required system dependencies. It has been copied unchanged and compared. Dynamic loading/initialization remains untested in this app. |
| 6. Can stock credentials/setup be used without replacing stock APK? | The software-constant provider and native string API allow a local copy to be supplied independently; the prototype does so. No APK-signer/UID/VIN binding found in that provider/setup path. Phone acceptance/OEM support or redistribution rights are not established by this technical analysis. |
| 7. Can both coexist installed? | **Demonstrated installed and running:** synthetic UID10050/untrusted_app coexisted with stock UID1000/PID2440. Protocol concurrency/phone ownership remains unproved. Normal Honda lifecycle observers react and can commit their own preferences. |
| 8. Can our app access TI decoder/render video? | Public APIs and advertised capabilities support trying it as an ordinary app. Actual listing/allocation/configuration/playback/resource sharing and SPS crop are untested. No proprietary direct decoder permission identified. |
| 9. Can eventual test be install→test→uninstall with Honda untouched? | **Install→synthetic Surface test→clean exit→uninstall demonstrated**, factory code/package unchanged. Whole private-data immutability cannot be promised because stock's lifecycle observer called its auto-start preference setter. Native/phone and overscan are separate stages. |
| 10. Would temporary root help? | It might overcome a specific proven MAC/FD/control barrier, but is not presently necessary for the shown core and does not create safe ownership of one USB session. Accessing the reset socket would not supply data. Prior root/recovery blockers remain; no root proposed. |
| 11. Safest next live test? | First audit actual native constructors/dependencies offline. Only if safe, design isolated load-only M3; existing L2 initializes GAL and remains unsuitable. No phone/GAL/decoder/overscan authorized by current plan. |
| 12. A/B/C/D priority? | **A: disposable custom receiver.** Use B only if a concrete ordinary-grant/ownership/policy barrier proves that a narrow cooperative bridge is needed. No existing such bridge found. C remains unavailable/higher risk; D is not the default. |

## Scope change and recovery implications

The earlier “no stock patch deployment meets recovery threshold” conclusion remains valid for root/wrapper/stock replacement/staging. This new route changes the object being tested: a new ordinary package with its own sandbox and normal removal path. A bounded L1 install/launch/uninstall can therefore be considered independently of having full boot/system recovery media. This does not authorize any action and does not extend to root, global policy changes or taking over an active projection session.

The factory application remains installed and active according to its own lifecycle. No code promises to stop, disable, clear or alter it. Normal USB attach may start it and cause its own normal bookkeeping/recovery operations; “our app never writes Honda data” is not a guarantee Honda writes no data during a phone session. Full-session coexistence needs evidence before a phone test is recommended.

## Built prototype and remaining gates

[Source/build/README](parallel-aa-receiver/README.md), [signed APK](parallel-aa-receiver/build/rdx-parallel-aa-0.1.0-development.apk), [machine build report](parallel-aa-receiver/build/build-report.json). **Contains copied protocol credentials/native software for same-unit local research; keep the APK/asset local.** The development signing certificate is independent of both OEM trust systems.

The APK does not switch a normal phone into AOAP. It only tests an already-enumerated allowed AOAP interface and never forces a claim. This makes a safe failed claim possible but leaves first-connect setup/arbitration unresolved. It may not reach video until those are solved; building a transport adapter is not evidence that stock has released the interface.

Next gates, in order: normal diagnostic exit/ADB continuity and actual custom Activity/Surface; isolated load-only native control (existing L2 also initializes GAL and was skipped); native initialization/teardown without USB under separate approval; ordinary USB grant; exclusive non-forcing ownership without stock reset/retry races; phone service-discovery/video-config acceptance; AVC output/crop/frame geometry; optional independent overscan; input after video. Ordinary install/removal is now demonstrated. Stop at the exact failed boundary rather than importing root or OEM integration wholesale.

Reports: [dependency matrix](AA-PRIVILEGE-DEPENDENCY-MATRIX.md), [transport trace](GAL-TRANSPORT-TRACE.md), [architecture/authentication/decoder](CUSTOM-RECEIVER-ARCHITECTURE.md), [first live test design](PARALLEL-AA-FIRST-LIVE-TEST.md). No 2022+ artifact is required.

## 2026-10-23 offline implementation/build continuation

No vehicle/ADB operation or new live milestone. Historical M0–M2 remain PASS; M3 remains deferred/off critical path. Clean ordinary-app receiver remains preferred. Existing M4 APK BAD93C688F7019E4205DC86EF34E6078B695623DB85770C789F29B0A3CFF4148 independently aapt/JADX/DEXDUMP/source/control-flow audited: READY FOR BOUNDED LIVE M4 TEST, not yet run. No Activity, permissions, filters, native library or USB open/request/claim/transfer. Grid built/audited; decoder built/audited with named TI codec/no fallback but all six clip assets absent, so not ready for decoding. Read-only explicit-serial capture tool prepared; only its offline PlanOnly branch executed. M5 source compiled/design only; M6 documentation only. Candidate A/B, factory files, original prototype and raw logs preserved.

New warning evidence identifies installation detector com.honda.maliciousdetector (MDBroadcastReceiver/MDService; package-scheme/BOOT receiver) and runtime scan log naming our installed package. Exact later warning dialog/class/resource, authorization predicate, persistent state and Dismiss code remain unresolved because its APK is missing locally. Successful uninstall does not prove OEM history cleared; a later warning does not prove APK remnants. Headless M4 avoids the identified Activity-resume path, not installation detection. Stock AA can still react to phone attachment with auto-start=false. Never suppress it for M4.

Future first fullscreen video target1920x720 active/30fps/229dpi remains an experiment; nominal1080/margins0,360 does not prove encoded SPS/crop/input coordinates. No180px touch offset or TTI width change. Grid has no overscan mutation; overscan is separate persistent state, not automatically rolled back by uninstall.
Current detailed continuation: [report/procedure](parallel-aa-receiver/OFFLINE-IMPLEMENTATION-RESULTS-20261023.md). Prior findings above retain their original chronology and uncertainty.


## 2026-10-23 portable toolchain, clips and foundation continuation

Offline only; no ADB/installation/vehicle operation. Cleared M4 APK remains BAD93C688F7019E4205DC86EF34E6078B695623DB85770C789F29B0A3CFF4148 and was not rebuilt. NEXT LIVE SESSION REMAINS M4 ONLY, GPT-6.1 Sol High. No decoder/grid/M5/M6 or MaliciousDetector acquisition combined with M4.

Project-local FFmpeg9.0.2 obtained from the FFmpeg-listed Gyan build, publisher checksum/archive/binary provenance recorded, no installer/global PATH change. All six10sec Constrained Baseline/yuv420p/no-B clips generated with moving grids/counters/edges, ffprobe/frame/GOP/SPS/PPS evidence. Independent SPS parser confirms1080 clips coded1920x1088 cropped8px bottom to1080;720/688 clips unpadded. These are SYNTHETIC clip results, not measured phone AA raster/margins/touch. No180px offset inferred.

Decoder0.2.0-with-clips APK ADD395FC46626DD3C43F527E10B1D8C49092DB43C8088CAEABB4A553BE90A374 built/independently audited with all six stored hash-verified assets, explicit TI only/no software fallback. Ready for a separately authorized decoder session, no TI execution demonstrated. Historical0.1 APK/source preserved. M5 APK757726DE360D466ACE5F7C12A90DE5B4377F2BD19D8D4BD8C13879967FDE95C8 built/audited but DO NOT RUN BEFORE LIVE M4 PASS; one permission request gated by explicit action/ack/current exact device identity. No open/claim/transfer/AOA.

Clean receiver foundation21 Java modules compile to API22 library JAR/DEX, NOT APK.67 synthetic host checks PASS. Frame parser/writer/post-TLS reassembly and capability models implemented; active USB/AOA/TLS/control/video disabled/stubbed, constructors local only. Fullscreen model active1920x720/229/30 with UNSPECIFIED crop/input placement; default remains conservative1280x688/229/60. No credentials/native receiver included. Clean ordinary receiver still preferred; M3 deferred/off critical path. Exact warning implementation still missing; separate read-only MaliciousDetector acquisition procedure prepared, no bypass or collection.
Detailed continuation: [report](parallel-aa-receiver/OFFLINE-CONTINUATION-CLIPS-FOUNDATION-20261023.md). Earlier statements above remain historical; the current matrix and latest audit identify reviewed builds.

## 2026-10-23 pure protocol-core continuation

Clean library now31 source modules;261 deterministic +23059 fixed-seed property assertions PASS. Pure control/discovery/video/touchpad serialization, explicit state/registry, fake byte-array conversations and bounds are implemented. No real USB/AOA/TLS/projection/decoder enabled; no credentials or new receiver APK. All48 protected analysis APK hashes unchanged. SDK33 compile stubs/Java7/D8min22 plus69 external method resolutions against pulled D.1.6.4 platform improve static API evidence without runtime claims. [Detailed results/protocol conflicts](parallel-aa-receiver/clean-receiver/PROTOCOL-CORE-RESULTS-20261023.md). **M4 ONLY remains next live; M3 deferred; ordinary clean receiver preferred.**

