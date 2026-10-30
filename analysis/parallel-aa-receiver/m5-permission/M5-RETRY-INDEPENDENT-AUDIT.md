# M5 retry0.2 independent final-APK clearance — 2026-10-23

**PASS — READY FOR A SEPARATELY AUTHORIZED BOUNDED M5 PERMISSION-ONLY RETRY. NOT INSTALLED OR RUN ON A DEVICE IN THIS SESSION.**

APK `build/20261023-180320-335/rdx-m5-permission-0.2.0-m5-single-port-300s-development.apk`.
SHA256 `A22E96490B9557AFF022893A8B8B7A08BB13CEC236E52704CDDAFA90A8EE8F40`.
Package com.rdx.fullscreen.m5permission, version0.2.0-m5-single-port-300s/code3, min21/target22.
Development signer SHA256 c001f59b25081ddfc73937155ca3580717e817c45c66e68b9e059737b0b28831. API22 v1 signature and zip alignment verified PASS.

## Independent inspection

Final ZIP entries: manifest, classes.dex and signature/JAR metadata only. aapt packaged manifest: one exported .PermissionService; no Activity, manifest permission, receiver, intent filter, provider, shared UID or native library. No USB attachment/boot/package auto-start. No host tests packaged.

SDK DEXDUMP independently shows exactly one SDK request invoke at byte offset002d5a in PermissionService.requestOnce. A single interface request invoke at001f2c in PermissionMachine.snapshot leads through the owned adapter to it. Complete method/string/class inventories and JADX actual decompilation were reviewed. Source hashes match the artifact. No unexplained support library or dynamic loader.

| API/behavior | Final APK status |
|---|---|
|getDeviceList, hasPermission, device path/VID/PID reads|PRESENT in explicit armed polling path|
|requestPermission|PRESENT, exactly ONE invoke instruction|
|openDevice|ABSENT|
|claimInterface, releaseInterface|ABSENT|
|controlTransfer, bulkTransfer, AOA control execution|ABSENT|
|System.loadLibrary / Honda native receiver|ABSENT|
|GAL/socket/TLS/network access|ABSENT|
|MediaCodec/audio/microphone|ABSENT|
|Runtime.exec, ProcessBuilder, su/root helper/Shizuku|ABSENT|
|Settings/property/WM mutations, reboot, force-stop, pm clear|ABSENT|
|Honda package control/default USB handler|ABSENT|
|Private own-file create/read/sync and explicit evidence dump|PRESENT, reviewed|

## Manual source-to-decompilation flow review — PASS

Public model/store constructors only initialize object fields. Android Service constructor creates Handler/callback objects on its existing main looper; no thread, USB query, TLS, native/media operation or private-file open. Own-file Session is created only by explicit store.create, after action gates. No active operation on install, Application startup or constructor alone.

All Service entrypoints are non-sticky. Normal arm requires REQUEST_ONCE_AFTER_M4_PASS, m4_pass_confirmed=true, wait_for_target=true, vendor_id6353/product_id11521, and a fresh explicit run_id. All IDs are bounded and path traversal is rejected. A same-lifetime armConsumed latch prevents another arm; active duplicates ignored. Same run_id on a new Service/process is rejected by exclusive file creation BEFORE acquiring UsbManager or constructing/arming a machine. A different fresh run_id requires another explicit arm command, never automatic replay.

Only unique exact18D1:2D01 can trigger. Normal22D9:2769/2765 are logged but never selected. Actual path/VID/PID pinned. Ambiguity stops. Existing authorization ends with zero requests. Reservation/latch is persisted and synced BEFORE the single PermissionRequester boundary. File-write failure stops before boundary crossing. The boundary revalidates pinned identity, registers one callback, creates API22-compatible FLAG_ONE_SHOT|FLAG_CANCEL_CURRENT PendingIntent, persists invocation intent and rechecks the monotonic deadline before the only SDK call. Request exceptions cause terminal ERROR without retry.

Clock uses elapsedRealtime, not wall time. Total bound300000ms includes finding target and awaiting callback; polling1sec/heartbeat10sec. Every event checks deadline. Device at/after deadline cannot trigger; exact final millisecond model test is not a real-time Android scheduling guarantee. Binder/filesystem calls cannot be forcibly cancelled by this watchdog if the platform itself blocks the main thread; no hard real-time process-lifetime claim. No endless polling/retry loop. Handler stops on terminal state.

Callback action contains per-request random nonce and package target; Intent nonce plus exact returned path/VID/PID are verified. GRANTED requires both callback extra and current hasPermission. Contradiction is terminal CALLBACK_INCONSISTENT. Wrong/early callbacks are rejected. Duplicate/terminal callbacks cannot request. Detach after request is terminal DETACHED, with no re-selection even if a later18D1:2D01 appears. onDestroy removes handlers, cancels pending callback, unregisters receiver and closes journal. No callback receiver remains after stop; cancelling PendingIntent does not necessarily dismiss an existing system dialog or undo a platform grant. No claim that permission survives USB detach.

PrivateJournal writes only getFilesDir()/m5-<run_id>.txt, UTF8, flush+FileDescriptor.sync per event. No external storage or storage permission.8runs/65536bytes each/4096bytes per line; full storage refuses new arm rather than deleting. Private results survive ordinary Service/process recreation; no claim of journal survival across uninstall or arbitrary storage corruption/power loss.

LIST_RESULTS and DUMP_RESULTS branches run before UsbManager acquisition and never arm a model. Explicit DUMP reads one validated private run, emits UUID-tokened Base64 chunks<=1200bytes plus byte length/SHA256 and end count. Prior data remains unchanged. Host reconstruction requires matching run, complete newest dump, exact lengths and SHA; corruption never becomes permission denial. Live retrieval through this new dump path remains unmeasured; it has only host fixtures and static API checks so far.

## Validation and limits

56 deterministic model/store assertions,9 arrival timing cases, all A–M scenarios PASS.20000 seeded sequences x120events =2400000 invariant checks; seed0x4D35524458323032, max request count1.8 independent dump reconstruction cases PASS. No external dependency or third-party implementation imported. Java7/D8min21 PASS;89 method refs checked against actual locally pulled API22 definitions/inheritance (compiler stubs are SDK33). All65 pre-existing APK hashes unchanged.

These are host/static results, not M5 live PASS. Normal permission UI/lock-task behavior, actual ordinary permission grant, cable-disconnect lifetime, private dump retrieval and SystemUI/Honda side effects require the separately authorized live retry. Prior M5 remains INCONCLUSIVE, M4 PASS, M6 disabled.
