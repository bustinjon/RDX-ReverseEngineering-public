# Offline foundation freeze — 2026-10-25

> Current M5: [latest retry INCONCLUSIVE](M5-RETRY-LIVE-RESULTS.md), one returned permission request, zero callbacks; Diagnostics lock-task rejected UsbPermissionActivity. M5 uninstalled. [Offline pre-arm guard](M5-RETRY-LOCKTASK-GUARD-PLAN.md) is prepared and host-tested; its fixed read-only getter and framework hash parity still need live confirmation before any ARM. No vehicle/ADB action in this guard session. Existing freeze tables below retain their historical baseline context. M6 remains disabled; next live M5 RETRY ONLY with separate authorization.

> M6 continuation: [AOA-only implementation](M6-OFFLINE-VALIDATION.md) and [disabled frozen artifact](M6-AOA-FROZEN.md) are now prepared in a separate9-module package. Main source/DEX are unchanged; fresh full regression110521checks/8235885properties differs from the earlier110501 count by20 regenerated-certificate carrier checks. M6 adds392checks/9304615properties/50000sequences, with own-UID permission strategy and signed M5 gate. Next LIVE remains M5 RETRY ONLY; M6 requires reviewed M5 PASS, separate activation-release review and explicit live authorization. The earlier foundation table below is the pre-M6 snapshot.

**OFFLINE WORK FROZEN; API22 PROVIDER RUNTIME UNQUALIFIED.** The clean receiver is a mature, reproducible host foundation, not a demonstrated deployable receiver. Further broad offline architecture work is not justified without new runtime/live evidence.

Current authority: [PROJECT-STATE.json](PROJECT-STATE.json), [index](INDEX.md), [integrity checker](../../tools/Test-RdxOfflineIntegrity.ps1). This freeze supersedes current-status wording in older design reports without changing their historical results.

|Milestone|Frozen status|
|---|---|
|M4|PASS: ordinary untrusted app observed phone/accessory inventory without USB permission|
|Original M5|INCONCLUSIVE due timing; no permission failure demonstrated|
|M5 retry|READY/FROZEN; **NEXT LIVE MILESTONE: M5 RETRY ONLY**|
|M6|DISABLED UNTIL M5 PASS, then still requires separate authorization|
|M7|OFFLINE FOUNDATION ONLY; no live transport/TLS/media/decoder pass|

## Verified artifacts and evidence levels

|Artifact|Evidence|Not established|
|---|---|---|
|Clean receiver57 modules|110501 deterministic checks,8235885 property assertions PASS;120 independent fixtures;55 semantic transcripts plus7 support outputs; Java7/D8min22;166 saved API22 references resolve|Actual Android provider, USB ownership, phone trust or decoder/display|
|Main receiver DEX|2FDBC63F2F9D63B764697D311AF89D460AE6B8E14B0FADABA9C9339F7FE7C235, unchanged across clean builds|A receiver APK installation/runtime result|
|Desktop real TLS|TLS1.2/GCM, mutual public-test trust, exact AA/media recovery,3300 AUs/47649547 bytes, fake decoder only|Phone/Honda authentication or TI decoder performance|
|New provider shadow model|25000 sequences,8 checks/810078 assertions; prior10000-sequence model preserved|API22 execution; expected-gap tests do not repair/qualify the provider|
|Frozen qualifier APK|Zero permissions, one explicit test Activity, API22v1 signing/alignment,220 saved external references resolve,97 DEX classes;20 same-core desktop semantic groups PASS|Android install/launch/provider/private-storage/cleanup runtime behavior|
|Frozen M5|A22E96490B9557AFF022893A8B8B7A08BB13CEC236E52704CDDAFA90A8EE8F40; one permission invoke;300seconds; complete future staged kit|Actual normal permission grant; next car test still required|
|Prepared decoder APK|ADD395FC46626DD3C43F527E10B1D8C49092DB43C8088CAEABB4A553BE90A374 unchanged|Actual TI configure/start/decode; separate authorization required; no software fallback|

Baseline actual110493/7425807 before the new shadow suite differs from the prior110504 deterministic count only through regenerated-certificate/carrier assertions. DEX/source/old test hashes and fixed property expectations reproduce. No old test was removed or weakened. The new qualifier's per-I/O checks are reported separately, not added to inflate the receiver count.

## Runtime result and provenance

**Verdict D — API22 RUNTIME TEST UNAVAILABLE.** Bounded deep search found no runnable image/emulator across51260 entries and59 local archives. No ADB was executed. [Archaeology](clean-receiver/LOCAL-API22-ASSET-ARCHAEOLOGY.md) records scope, exclusions and metadata limits. The final protected Hyper-V directory listing succeeded and was empty. No VM/WSL distribution was booted or archive executable run.

Saved Android5.1.1/API22 Conscrypt supports memory-buffer TLS1.2/GCM/client-auth by code. Body completion/residue and close behavior are still unqualified. Saved system metadata says build168 while raw M4 live evidence says build14; current vehicle provider parity is not established. A future generic API22 emulator pass must be identified as that exact build, not silently treated as vendor-build proof.

The frozen qualifier APK is [recorded here](clean-receiver/API22-TLS-QUALIFIER-FROZEN.md). It checkpoints every completed case, preserves pre-close observations and tests close last. The emulator-only runner has explicit serial/API/qemu/hardware/hash guards and no physical bypass. Host refusal/schema/comparator tests passed; actual emulator installation/cleanup remains untested. No AndroidOpenSSL completion flag was enabled, no native backend was built and Honda JNI is not required by current evidence.

## Protocol/profile freeze

AA headers remain visible; plaintext fragmentation precedes body encryption. Ciphertext length, decrypted fragment length and logical total remain distinct. Version/0003 handshake carrier and the explicit post-handshake0004 AuthResponse exception remain plaintext. CONTROL is not channel zero.0x8000 is codec Setup PHONE→HU;0x8003 is Config HU→PHONE with WAIT1/READY2.0x8004 is accounting, never display proof.0x0001 carries opaque codec config;0x0000 carries BE64 raw timestamp plus opaque bytes.

Conservative stays default: active1280×688,229dpi,60fps; bytes `08 02 10 01 18 00 20 20 28 e5 01`.
Experimental stays opt-in: nominal1920×1080, width margin0, total vertical margin360,229dpi,30fps; bytes `08 03 10 02 18 00 20 e8 02 28 e5 01`. Conceptual active1920×720 is not a prediction of phone encoding. Crop placement and touch offset remain UNSPECIFIED; no180/180 split.

UNKNOWN: actual phone AU boundaries, timestamp units, exact ACK scheduling, WAIT→READY triggers, start/config/data ordering, reconfiguration, phone-selected experimental raster/SPS/crop, peer focus prerequisites and real TLS control/close AA routing. Factory input reference1325×720 logical /60×40mm /uiNavigation=true /uiAbsolute=true remains metadata, not a fullscreen coordinate transform.

## Next car action and stop

Use [the one-page checklist](NEXT-CAR-SESSION-CHECKLIST.md). First perform the offline frozen-M5 preflight, prepare unlocked phone/cable/normal USB-mode navigation **before arming**, then obtain explicit live authorization. The staged kit installs only M5 and stops issuing ADB after confirmed ARM/swap instructions. Retrieve system logs before private-journal dump, hash evidence, remove M5 and compare factory/package/display preservation. M5 is not debuggable: DUMP_RESULTS is the intended retrieval mechanism.

**After M5, STOP regardless of PASS/FAIL/INCONCLUSIVE.** No M6 automatic branch. The read-only MaliciousDetector acquisition remains a separately authorized later collection; no bypass, suppression, deletion or preference mutation is prepared.

All69 historical APKs and M4/M5 live reports are unchanged. The factory Honda app remains untouched; patched candidates stay research artifacts. Working disposable PKCS12 containers were deleted; intentionally PUBLIC TEST PKCS8 leaf assets remain in the frozen qualifier for reproducibility. No Honda credentials were used. No ADB, vehicle, phone, physical USB, Honda JNI, MediaCodec, installation or factory-setting/data modification occurred.

