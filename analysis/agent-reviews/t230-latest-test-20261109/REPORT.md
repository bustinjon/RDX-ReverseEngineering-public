# T230 latest saved test — review for Claude/Codex

Review date: November9, 2026. **Verdict: PARTIAL / needs correction.** The recorded main-phone Off selection does not disconnect active wireless AA. Short main-thread stalls and a session/BT cleanup race are separately evidenced. This review changes no application or car state.

## 1. Files inspected

Current PROJECT-RULES.md/AGENTS.md; T230 candidate/build/test/source manifests and saved host tests; source snapshot SettingsActivity, WirelessProbeService, AaSessionService and relevant helper/test paths; five head-unit log exports under builds/T230-bundle/headunit-logs-20261109-121940; latest actual run helper_20261109T170817_5e216d0851eb4e338098ca2ff9981fe3 collection/installed APK; suite tools/Run-Test.ps1, Collect-Test.ps1 and KEEP receipt; current public test-plan context. Two relevant classes were independently decompiled from the selected APK's public classes.dex. The review is scoped to recent policy/session/collection behavior, not a whole-app audit.

## 2. Files changed

Only this directory's scope, saved analysis procedures, indexed source/log evidence, public DEX extraction/scoped decompilation and this report. No production/test implementation, APK, original log/result, setting, dependency/runtime, Git state or device changed.

## 3. Commands run

Read-only file/search/Git-history inspection; saved Analyze-SavedTest.ps1, Analyze-Symptoms.ps1, Verify-Artifact.ps1 and Inspect-CompiledClasses.ps1. SHA-256 comparisons and in-memory chronological/deduplication analysis. Exactly classes.dex was opened from the APK; no protocol/signing/private asset entry opened. Bundled JADX JRE initially failed loading java.security; existing installed JDK17 completed the two-class decompile without modifying either runtime. No ADB, phone/car action, build, network, patch to implementation or agent delegation.

## 4. Tests run and results

- APK identity PASS: candidate file, candidate metadata, collection receipt and actual installed-posttest.apk all equal **D4251090D1AFE7EB4FC74162044038E0A14B63A67B7DB88A72C9E1E28336D893**.
- Source provenance PASS: all36 source-manifest entries match; all48 recorded Java inputs match, including33 reviewed bundle snapshots and15 inherited source files independently hashed. Initial snapshot-only coverage was33/48 because unchanged baseline files are not duplicated in the bundle; this is not a source mismatch. Full verification resolves that gap.
- Actual compiled SettingsActivity/WirelessProbeService match the relevant reviewed policy paths: preference writes with no active-session stop in the per-device callback; unversioned session-end handling closes the current btEstablished; TCP handoff has no per-device policy recheck.
- Five exports contain overlapping history. Selected text deduplication:707 occurrences ->442 distinct timestamp/PID/TID/message records;314 within the latest12:10–12:20 device-wall-time window. Identical repeated lines can also occur within one file, so these inventory counts are not counts of independent failures or guaranteed unique runtime calls. Off-state proof is separately indexed directly from the latest export. The earlier Nov8/morning exports are not assumed to contain the later APK.
- Off interval:27.650s before the operator switches back to Both. There are34 live protocol/video/audio entries while Off; final pre-reenable liveness at12:13:38.356. No shutdown/stop marker in that interval.
- Two material shutdown spans on the app main thread:1399ms and981ms. One corresponding Choreographer message reports81 skipped frames. Two additional near-immediate4ms shutdown repeats are also recorded.
- No application FATAL/ANR marker in the latest filtered export. This does not exclude absent/rolled-out buffers or prove the absence of all freezing.
- Saved T230 host results report245 bundle checks plus feature suites. Inspection shows the T230 additions test mode values/lists and initial bootstrap predicates, not an Android preference click against an already-active AA session or these lifecycle interleavings. No new device/runtime or behavioral code test was run by this review.

## 5. Findings

### F1 — HIGH: per-device Off is persisted but never enforced against the current wireless session

**Exact recorded sequence, main phone:**

| Device wall time | Event |
|---|---|
|12:12:05.698|USB only selected|
|12:12:46.715|Wireless only selected|
|12:12:58.122|A new phone-wireless TCP AA session starts|
|12:13:10.937|Off selected|
|12:13:10.976 onward|Video, PCM and GAL responses continue|
|12:13:38.356|GAL response still received while Off|
|12:13:38.587|Operator changes back to USB + Wireless|

The first code divergence is **SettingsActivity's per-device mode click -> save preferences -> redraw**, rather than **save preferences -> reconcile/stop a now-disallowed active transport**. It writes wirelessOff and mainDisabled (or changes the extra USB list) without notifying WirelessProbeService/AaSessionService. Wireless peer permission is checked when a Bluetooth bootstrap begins; it does not retroactively apply to an established AA transport.

This explains the operator's specific complaint with high confidence and is confirmed in the actual APK, not just current source. The lifetime of the already-handed-off socket belongs to AaSessionService, so closing a listener or changing the persisted list cannot itself terminate it.

**Important distinction:** the separate global “Wireless Android Auto” switch does call WirelessProbeService.stop, whose shutdown asks AaSessionService.stopTcpSession. The observed main-phone mode callback does not use that path. Do not diagnose this as proof that the global switch's existing stop implementation never runs; there is no paired global-false toggle in the relevant recorded mode sequence.

**Smallest corrective scope:** after a successful per-device mode update, dispatch an explicit policy-change event identifying the changed device/new permitted transports. Reconcile against the identity and generation of the active/pending session, stop only a transport now forbidden for that owner, and suppress automatic restart of that forbidden route. Reuse coordinated owner teardown; preserve Bluetooth HFP/pairing, unrelated devices and the everyday wireless service for allowed peers. Merely saving preferences, relabeling the screen or globally turning off Bluetooth is insufficient. No code change made here.

### F2 — HIGH source gap, runtime consequence not yet tested: cached/in-flight admission can outlive the setting change

Bluetooth bootstrap checks peerAllowed once, **before** its up-to10s wait for network readiness; the subsequent read/respond loop does not recheck it. Separately, TCP acceptance checks fromGroupNetwork and hands the socket to AaSessionService without checking the current per-device allow policy. AaSessionService's handoff checks session ownership/busy state, not the device setting.

Therefore the initial bootstrap predicate alone does not guarantee Off blocks an in-flight or cached-network reconnect. This is a code-level enforcement gap; a post-Off unauthorized reconnection was **not** observed in the selected interval, which kept the original session alive.

**Minimal companion fix/test:** revalidate current policy before returning network bootstrap data and at transport admission/handoff. Bind that decision to a real device/session identity, including a defined conservative policy when identity is unavailable. Existing serial-to-BT linking does not automatically identify every same-subnet TCP connection. Do not stop an unrelated active device because another row was disabled.

### F3 — HIGH/SUPPORTED: old session-end cleanup closes a newly established bootstrap channel

This sequence is independent of the later Off selection:

| Time | Current export evidence |
|---|---|
|12:11:24.054|First shutdown completes|
|12:11:24.064–.069|Session-end handler releases held BT channel|
|12:11:24.108–.112|Another shutdown occurs|
|12:11:24.127|New BT connection n=3 accepted|
|12:11:24.230|Connection n=3 reports Wi-Fi state (type7); bootstrap assigns btEstablished=c|
|12:11:24.275–.278|Another P5_SESSION_ENDED handler clears/closes current btEstablished; BT worker gets IOException|
|12:11:24.350|Connection n=4 accepted, another bootstrap attempt|

WirelessProbeService.sessionEnded sends only an action; the receiving handler unconditionally closes whichever socket is currently in btEstablished, with no session/connection generation or socket owner to match. The fresh n=3 acceptance and type7 precede that cleanup; source and compiled code show why newer work can be closed by older cleanup. Repeated shutdown notices in this window contribute to reconnect churn. This supports a real ownership race; it does not establish the cause of every preceding disconnect or all user-reported freezing.

**Smallest corrective scope:** exactly-once end/teardown per AA session, with end notifications carrying an owner token/generation and cleanup affecting only the socket owned by that session. Ignore stale end events, serialize admission against teardown, and keep fail-closed native resource checks. Removing only a duplicate log or adding a delay does not close the ownership race.

### F4 — HIGH for short stalls, UNKNOWN for prolonged freezes: blocking teardown executes on main thread

The latest export records shutdown at12:11:22.655 and completion at12:11:24.054, both PID=TID2691; Choreographer reports81 skipped frames at12:11:24.060. A second material main-thread shutdown takes981ms at12:12:33.986–12:12:34.967. AaSessionService.shutdown synchronously closes/prepares transport/native state, joins up to three threads, stops decoder and destroys capture/playback/native objects on that calling thread.

This provides a concrete explanation for a brief visible UI hitch around teardown/reconnect. The data does not isolate how much time belongs to each join/native/audio operation. There is also a low VIDEO_FPS sample near the settings changes, but static/covered AA content can legitimately produce few frames; low FPS alone is not a freeze diagnosis. The Off selection itself occurs later and invokes no shutdown, so F1 and these measured stalls must not be conflated.

**Smallest corrective direction:** keep the request/state transition on main, perform blocking teardown on one serialized worker/coordinator, and post terminal UI/lifecycle updates back only for the matching session. Preserve timeout/worker-ownership/fail-closed rules; do not merely shorten joins and destroy objects still used by surviving native workers. Add per-stage durations and a small event-loop delay marker if longer stalls remain unexplained. Treat this as a separate fix from F1.

### F5 — KEEP/collection is a separate state boundary; it is not a functional PASS or an APK rollback

The final collection receipt at17:20:16Z verifies installed D425, evidence retrieval and own helper/diagnostics absence at that check. The KEEP receipt at17:20:18Z explicitly records KEEP_DAILY_FEATURES. Run-Test's KEEP branch skips the test's postCollect undo (persistent setup/grant revocation) and restores **host baseline source**. It does not reinstall a baseline APK or prove the helper is currently running.

Consequently:

- “baseline source restored” means local development source restoration, not that the car returned to an older receiver build;
- KEEP intentionally retains daily-use setup rather than full stock restoration;
- “SAFE TO DISCONNECT” describes collection/cleanup checks, not that Off passed or that the drive was freeze-free;
- no contemporaneous post-KEEP runtime snapshot establishes today's service/permission state;
- repeating Collect later cannot explain the earlier12:13 Off failure. No evidence here supports blaming that repetition.

No canonical T230 RESULT.md was present at review start. The operator observations and above partial/failed checks should be recorded before treating this bundle as promoted or fully passing.

### What Codex's recent work got right, and what remains missing

The reviewed implementation has explicit USB/Wireless/Both/Off representation, remembered serial/BT links, an initial Bluetooth admission predicate and a source/APK identity trail. Its annotated list-capacity and unknown-peer-bootstrap fixes are present in the built snapshot. Existing host checks are useful for those pure branches.

The missing layer is **live policy/session reconciliation**: tests that call next/of/mayBootstrap cannot prove that an active or pending socket is stopped, a late end cannot close newer work, or UI teardown stays responsive. The next review should demand those lifecycle cases, not simply another large total of predicate assertions.

## 6. Primary evidence

All source paths below refer to the **T230 bundle snapshot**, not the restored live baseline:

- `source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/SettingsActivity.java:218–243`; compiled counterpart `dex-review/sources/com/rdx/fullscreen/usbhelper/SettingsActivity.java:389–408`.
- `WirelessProbeService.java:96–125,201–212,504–512,648–669,725–757,965–994`; compiled counterpart's session-end branch around987–996 and TCP handoff around1276. Indexed exact excerpts/hashes in source-excerpts.json.
- `AaSessionService.java:109–140,507–516,1360–1436`; reviewed against all48 recorded source hashes. Installed APK identity/decompiled public DEX evidence in artifact-verification.json/full-source-verification.json.
- Latest export `hackura-20261109-121927.txt:680,1309,1628,1722–1723`: mode changes and Off-state liveness. Additional34 ping/video/PCM references in off-active-session-proof.json.
- Same export:345–363 shutdown/stall;373–388 later shutdown and new-BT/old-end sequence;394 onward next bootstrap. Full deduplicated aliases in latest-timeline.json; source proof of type7 ownership is WirelessProbeService.java:757.
- off-interval.json, shutdown-durations.json, jank-events.json and symptom-summary.json record exact timing/count limits.
- BundleTests.java:136–146: T230 pure mode/bootstrap tests; saved host-test-output.txt/build-result.json: reported compile/check results, not live Android lifecycle validation.
- Latest actual run collection.json/installed-posttest.apk; `tools/Run-Test.ps1:67–84`; operator-20261109-172003/daily-features-kept.json.

## 7. Assumptions

The user's cited Off complaint corresponds to the logged main-phone row toggles in the latest test. If a separate global switch was also tried, its exact failure timeline is not established here. Device-wall timestamps are used as recorded, without inventing sub-second operator/visual timings. D425's latest-run receipt and same PID/time window support attribution; older morning/previous-day exports are not assumed to be this build. Host/source restoration after Collect does not invalidate the preserved candidate snapshot.

## 8. Unresolved uncertainties and smallest next tests

No new car step is performed or armed by this report. For lead review after a scoped fix:

1. **Policy-only candidate:** active Wi-Fi AA -> same device USB-only/Off. Require a logged policy decision for the real owner, matching terminal session end/socket close, no reconnect while disallowed, settings responsive and HFP calls/other allowed devices preserved. Return to Wireless/Both and verify one reconnection. Explicitly check the separate global switch as a different control.
2. **Admission boundary:** set Off while network readiness is pending, and try the existing cached Wi-Fi route. Require policy recheck before response/handoff, not only at the earlier BT connection. Disabling a different device must not kill the active permitted phone.
3. **Ownership/race:** delayed end(A) arriving after bootstrap/session(B) must not close B. Repeated end(A) must be inert. Verify stop during pending handoff/connect and during shutdown before native objects are released.
4. **UI responsiveness:** separately time teardown stages and main-loop latency across rapid settings/transport changes. A brief shutdown hitch and a sustained driving freeze require different evidence. Keep long-drive qualification separate from these short checks.

Current car state is UNKNOWN; user selected KEEP and no device inspection occurred. No wire trace/phone-side log, ANR trace, video synchronized to the reported freeze or full car-wide performance profile was available. No complete security/native audit or credential/firmware change is implied. No new version promotion recommended on the basis of host checks alone.

## 9. Exact diff summary

New review/evidence files in this directory only. No implementation fix or settings change. Earlier raw exports, installed APK copies, source snapshots and canonical test outcomes remain unmodified; proposed minimal fixes are recommendations to the lead.

## 10. Preservation checks performed

Candidate and actual collected APK hashes match D425;36 manifest snapshot entries and48 recorded Java inputs verified. Original five export hashes recorded and rechecked. Relevant source/manifest/build/collection/KEEP records retained. Only the public classes.dex entry was extracted; no signing/protocol/private asset read. All mutations are scoped to new review outputs. No ADB, native library execution, build/sign, car change, Git mutation/reset/cleanup, agent spawn, readiness bypass or milestone advancement. Whole-workspace equality is UNKNOWN because unrelated uncommitted changes/pruning existed at review start; nothing was restored or removed.
