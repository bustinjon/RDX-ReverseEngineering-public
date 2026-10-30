# M5 retry offline validation — 2026-10-23

**READY for a separately authorized M5-only live retry. No device was used in this session.** M4 remains PASS. Previous M5 remains INCONCLUSIVE; this build is not a live permission PASS. M6 remains disabled.

## 1. Root cause, measured precisely

The0.1.1 Service used1sec passive polling and a180000ms total timer. It started17:35:16.889 and timed out17:38:16.933. Phone normal identity appeared17:42:58.732,281.799sec after timeout; accessory18D1:2D01 appeared17:42:59.481,282.548sec after timeout.172 inventory samples contained no target; ZERO permission requests/callbacks/target permission measurements. [Historical final live report](M5-LIVE-TEST-RESULTS.md) remains untouched.

The original0.1.0 build also assumed the exact device path existed at Service start and allowed45sec for callback. The0.1.1 deferred matching fixed that selection issue but its timer did not cover the actual mode/cable workflow. Neither result establishes a platform permission restriction.

**The requested five-minute timer alone would still NOT cover the previous7min42sec start-to-accessory delay.** Prepare the phone, cable and normal USB-mode UI navigation before arming; verify ARMED immediately and swap promptly. Announce deadline. Do not claim that a longer timer guarantees a prompt or process survival.

## 2. Artifact

| Field | Value |
|---|---|
|Package|com.rdx.fullscreen.m5permission|
|Version / code|0.2.0-m5-single-port-300s /3|
|Service|com.rdx.fullscreen.m5permission/.PermissionService|
|minSdk / targetSdk|21 /22|
|APK|m5-permission/build/20261023-180320-335/rdx-m5-permission-0.2.0-m5-single-port-300s-development.apk|
|SHA256|A22E96490B9557AFF022893A8B8B7A08BB13CEC236E52704CDDAFA90A8EE8F40|
|Development signer SHA256|c001f59b25081ddfc73937155ca3580717e817c45c66e68b9e059737b0b28831|
|API22 v1 / zipalign|PASS / PASS|
|Final manifest|One exported headless Service; no Activity, permission, receiver/filter/provider/shared UID/native library|
|Final audit|[PASS including manual source-vs-JADX/DEXDUMP review](m5-permission/M5-RETRY-INDEPENDENT-AUDIT.md)|

Absolute APK path:

[Code block omitted from public report; see authored source where available.]

## 3. State machine and one-shot invariant

Pure PermissionMachine has no Android dependency; constructor only initializes fields/containers. PermissionRequester is the sole permission-effect boundary. Evidence is an injected persistence boundary.

| State/event | Transition/action |
|---|---|
|IDLE + explicit valid arm|ARMED → WAITING_FOR_TARGET; journal synced|
|WAITING + normal22D9:2769/2765|Observe only; remain waiting|
|WAITING + unique18D1:2D01|TARGET_SEEN; pin path/VID/PID|
|Already authorized target|ALREADY_AUTHORIZED, zero requests|
|Ambiguous matching targets/malformed inventory|ERROR; zero requests|
|Target without grant|Persist REQUEST_RESERVED/latch, then PERMISSION_REQUESTED; invoke boundary once|
|Valid same-device/nonce callback, granted=true and verified=true|GRANTED; RESULT_RECEIVED|
|Valid callbackGranted=false and verified=false|DENIED; RESULT_RECEIVED|
|Callback flag and current permission disagree|CALLBACK_INCONSISTENT; no success claim|
|Wrong nonce/path/VID/PID/null/early callback|Reject; no new request|
|Pinned device disappears or identity changes after request|DETACHED terminal; later target cannot retrigger|
|Elapsed300000ms reached|TIMED_OUT terminal; no request/callback acceptance afterward|
|Persistence/boundary/runtime/clock error|ERROR terminal; no retry|
|Service destruction while active|STOPPED terminal|
|Any terminal state|No further permission transitions; Service ends while retaining exact outcome|

The five-minute total bound includes target wait and callback wait. It uses elapsedRealtime age/subtraction; wall clock is evidence only. Target at/after deadline is rejected. Public calls are main-thread confined in the adapter. There is no generic FINISHED state that erases the result; SERVICE_END records the preserved terminal outcome.

The persistent run file is created exclusively before arming. Reusing the same run_id after a new Service/process is refused before any USB operation. A new run_id requires another explicit operator command. Same-lifetime armConsumed and active-run guards prevent duplicate arming. Reservation is durable before requesting; no reset clears the one-shot latch. Exactly one SDK invoke instruction exists in final DEX. This invariant has a structural basis as well as tests; randomized testing alone is not a mathematical proof over all programs/platform failures.

## 4. Deterministic and seeded host simulations

Final result: **56 deterministic model/store assertions PASS**, all requested A–M scenarios, **9 target-arrival timings** (0,5,30,60,120,240,299.999,300,300.001sec), plus **8 independent dump-reconstruction cases PASS**.

| Required scenario | Result |
|---|---|
|A no target for5min|TIMED_OUT,0requests|
|B normal22D9:2769 only|0requests|
|C target appears|1request|
|D repeated target sightings|1request|
|E exact M4 identity sequence|22D9:2769→18D1:2D01→22D9:2765→18D1:2D01:1request total, DETACHED after first selection disappears|
|F target240sec|1request|
|G after deadline|0requests|
|H granted callback + actual permission|GRANTED|
|I denied callback + no actual permission|DENIED|
|J duplicate callback|Terminal state unchanged; no extra request|
|K wrong nonce/path/VID/PID/null|Rejected; later valid callback may finish|
|L detach before callback|DETACHED terminal; no second selection/request|
|M journal/store reconstruction|Prior reservation/result readable, same run ID refused; no replay|

Also covered: immediate/reentrant fake callback, already-granted target, ambiguity, duplicate path, inventory overflow, evidence failure before request/reservation/result, request-boundary exception, clock reversal, Long.MAX_VALUE arithmetic, explicit stop, path-control escaping, private ID traversal refusal, line/run/byte/read bounds, no automatic deletion. Restart testing reconstructs host objects/files after closing them; no real Android process or Service was executed/killed.

Property seed **0x4D35524458323032 =5563443368177053746**. **20000 lifecycles ×120 events =2400000 invariant assertions**, with normal/target/reattach/duplicates/empty inventory/time/callback variations. Maximum PermissionRequester count observed **1**; every lifecycle had0or1, never2+. Fake request-boundary counts are not actual hardware/Android calls.

Evidence: m5-permission/offline-retry-20261023-175755-444/host-20261023-180317-914/result.json and tests.log. First exploratory test pass had51 checks; final additions increased this to56. A dump-test input filename typo was corrected and rerun; initial failed fixture setup is preserved, not an APK defect. No production code changed afterward.

## 5. Durable private evidence and explicit retrieval

Only getFilesDir()/m5-<run_id>.txt is written. No getExternalFilesDir, broad storage permission, Honda directory, system file, private-data bypass or direct shell-readable export. UTF8 lines store wallMs/monoMs/state/event, selected path/VID/PID/hasPermission, reserved/count status, callback identity/flag/current permission, errors and final outcome. DEVICE events preserve observed normal identities; callbackDevice fields distinguish current permission from original pinned beforePermission.

FileOutputStream flush+FileDescriptor.sync occurs on every event; REQUEST_RESERVED must sync before crossing the requester boundary. REQUEST_API_INVOKING is explicitly an invocation-intent record, not proof the SDK returned; REQUEST_API_RETURNED and callback provide stronger evidence. Crashes between reservation and SDK invocation cannot be identified perfectly and must not be reported as a known framework request. Refusing replay is safer than silently retrying such a run.

Eight runs max,65536bytes/run,4096bytes/event;32 devices/snapshot,256-character paths. Full evidence storage refuses new arm instead of deleting old files. Reads enforce the same64KiB bound. Private results survive normal object/process reconstruction, but not uninstall; always retrieve and verify before cleanup. No guarantee against arbitrary filesystem corruption, forced storage loss or power failure is made.

Explicit LIST_RESULTS logs saved run filenames. Explicit DUMP_RESULTS with a validated run_id emits a random dump token, byte count/SHA256, numbered Base64 chunks≤1200bytes and end count. It executes before any UsbManager acquisition and never arms a core. Active runs reject dump commands rather than stopping/rearming. Capture logcat before issuing dump, then use scripts/Convert-RdxM5Dump.ps1 locally. The converter accepts only the requested run's newest complete dump, verifies every chunk/length/SHA and refuses overwrite of reconstructed files. A missing/corrupt dump permits repeating **DUMP only**, not repeating the permission test; original private evidence remains intact.

Eight host dump cases: saved multi-chunk GRANTED result exact bytes; maximum65536bytes/55chunks exact bytes; missing chunk/end, wrong run/hash, conflicting duplicate and newest-incomplete/older-complete substitution all rejected correctly. This validates fixture reconstruction and static Android dump structure, not actual live dump retrieval.

## 6. API22 callback review and bounded runtime limits

FLAG_ONE_SHOT|FLAG_CANCEL_CURRENT are API22-compatible; no modern immutable/mutable flag dependency. Dynamic receiver exists only around the permission request. Action includes per-request UUID and is package-targeted; nonce plus exact callback path/VID/PID verified. Current hasPermission must agree with EXTRA_PERMISSION_GRANTED. Invalid callbacks cannot create another request. onDestroy removes handlers, cancels PendingIntent, unregisters receiver and closes journal. A callback after destruction is no longer delivered to this receiver. Cancellation does not promise dismissal of an already-shown SystemUI dialog or reversal of a grant.

Polling is at most1sec between scheduled samples, heartbeat10sec. SDK boundary rechecks monotonic deadline after receiver/journal setup. Android scheduling can miss a very late/brief target; the299.999sec host case is not a hard real-time SDK guarantee. A blocking Android Binder/filesystem call cannot be forcibly cancelled by the main-looper timer; there is no claim of an absolute OS kill deadline. No wakelock or privileged background mechanism was added. If Android kills the process, retrieve the existing partial private journal; do not silently replay it.

SystemUI permission UI may cause Honda Activity lifecycle/preference effects. A headless Service cannot promise that a permission prompt is lifecycle-neutral. Honda may convert or consume the phone independently. No stock suppression, default-handler association or forced permission grant.

## 7. Independent APK/API review

Final aapt/JADX/DEXDUMP/method/string/class/ZIP/source/signature/alignment checks PASS, with manual actual decompiled flow inspection. DEX has **one** requestPermission invoke at002d5a, and one pure-core requester-interface invoke at001f2c. No openDevice/claimInterface/releaseInterface/controlTransfer/bulkTransfer/AOA, GAL/socket/TLS/network, native loader, MediaCodec/audio, Runtime.exec/ProcessBuilder/su/Shizuku, Honda control, settings/WM/property mutations, reboot/force-stop/pm clear or automatic attach/boot/package startup.

Java7 source/target and D8min21 succeed. Installed compile stubs are SDK33, not SDK22. **89 external method references** resolve against actual locally pulled D.1.6.4 core-libart/framework definitions, including inherited methods/array intrinsics. This supports API22 compatibility without pretending an Android runtime test occurred. Host tests are excluded from APK. Same development signer, ordinary package. All65 pre-existing APKs unchanged.

No upstream implementation/schema code was imported; this small state model/store/adapter is original project code using previously known Android public API behavior. No credentials, AGPL code or Honda receiver binary packaged.

## 8. Exact reproduction commands — host only

[Code block omitted from public report; see authored source where available.]

These scripts compile/read local files and run the host JVM/SDK tools only. Build/audit preserve each timestamped artifact. Final manual review is recorded separately in M5-RETRY-INDEPENDENT-AUDIT.md/manual-clearance.json. First exploratory host compilation ran the same javac source7/target7 and PermissionTests main directly; all inputs/output hashes are retained. The written future vehicle commands in M5-USB-PERMISSION-TEST.md were NOT executed.

## 9. Files created/modified

Production: m5-permission/source/com/rdx/fullscreen/m5permission/PermissionService.java (revised), PermissionMachine.java (new), PrivateJournal.java (new); AndroidManifest.xml (version3/name0.2.0); README.md (current revision). Tests: tests/com/rdx/fullscreen/m5permission/PermissionTests.java. New scripts: Test-RdxM5Retry.ps1, Validate-RdxM5Retry.ps1, Convert-RdxM5Dump.ps1, Test-RdxM5Dump.ps1. Existing generic build/audit scripts unchanged.

Reports: this file, m5-permission/M5-RETRY-INDEPENDENT-AUDIT.md, M5-USB-PERMISSION-TEST.md, BUILD-VALIDATION-MATRIX.md, NEXT-LIVE-TEST.md, NOTES.md; historical copies preserved before replacement. New build folder build/20261023-180320-335; validation folder offline-retry-20261023-175755-444; history/pre-0.2.0-300s. Latest build/audit/test/session pointer files updated. See offline session files-inventory.csv for exact generated file paths and hashes.

## 10. Local detector check and next decision

After final APK audit/manual clearance, a local filename inventory found no MaliciousDetector APK candidate. Existing metadata/runtime logs identify com.honda.maliciousdetector and historical/system/app/MaliciousDetector/MaliciousDetector.apk; precise authorization predicate/UI/persistence/Dismiss implementation still unavailable. **APK ACQUISITION STILL REQUIRED.** No speculative reconstruction or bypass work was performed.

**Next LIVE: separately authorized M5 permission-only retry using this exact APK and prepared cable/UI workflow. Do not execute it now.** M6 requires actual M5 evidence and later authorization. M3 remains deferred; clean ordinary receiver preferred.

**NO ADB, VEHICLE, PHONE OR USB HARDWARE WAS USED. NO APK WAS INSTALLED.**
