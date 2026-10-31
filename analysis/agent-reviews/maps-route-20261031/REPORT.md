# Maps route ending while AA continues — offline investigation, 2026-10-31

## 1. Files inspected

PROJECT-RULES.md; collected long-drive installed-posttest.apk and pinned candidate.json; current GalReceiver.java, SensorSource.java and relevant AaSessionService initialization; stock decompiled GalReceiver, Protos.NavFocusType, NavigationFocusManager, ProjectionActivity, GalNavigationFocusManagerService, SensorManager and LocationSensors under `decompiled/AndroidAuto-current/sources/`; saved current-session input/transport/health extracts and capture.log. Exact indexed source excerpts are in source-evidence.txt; installed DEX disassembly is in installed-dexdump.txt.

## 2. Files changed

New files only under `analysis/agent-reviews/maps-route-20261031/`: offline extraction and verification scripts, installed DEX copy/disassembly, source excerpts, hashes, verification results and this report. No application source, build, installation, device setting or historical report changed.

## 3. Commands run

Saved `Collect-OfflineEvidence.ps1` extracts only classes.dex from the already collected installed APK and runs SDK32 dexdump offline. `Verify-OfflineFindings.ps1` verifies five source/DEX assertions and unchanged inspected-source/APK hashes. Read-only Get-Content/Get-ChildItem/rg commands examined scoped source and logs. One initially guessed Protos path was absent; the stock class imports established its correct `projection/proto/Protos.java` path. No ADB, phone, USB, network, Git write or agent delegation.

## 4. Tests run and results

Five static assertions PASS, recorded in verification.json: stock value1=native, value2=projected; stock simple manager answers the requested state; current source always answers1; installed DEX overwrites the request register with literal1 immediately before nativeSetNavFocus. Collected APK hash matches **D1A29B34812B2C3188C57C840DB1DE4F44E1362FF8BD8E3D9A52B1317EDABCE4**. GalReceiver and SensorSource hashes match the candidate's recorded inputs and remain unchanged after review. These are static evidence checks, not a runtime Maps test.

## 5. Findings

**Clarified symptom:** user confirms only the Maps route ends; Android Auto/music remain running. The reported interval is approximately30 seconds. This narrows the investigation to navigation state rather than whole-session shutdown.

**Confirmed defect, high confidence:** `GalReceiver.navigationFocusCallback(int request)` ignores request and calls `nativeSetNavFocus(1)`. Stock protocol maps1 to native/OEM navigation and2 to projected navigation. Thus, if the phone requests projected navigation2, this APK answers native1. This is a navigation-focus contract defect in the installed APK itself, not a source/build mismatch.

**First demonstrable divergence:** phone navigation-focus request -> native/JNI callback -> Java `navigationFocusCallback(request)` -> hardcoded reply1. Stock's simple manager sends the requested focusType through its Java/native reply method. Stock's fuller navigation integration also switches to PROJECTED when projected navigation becomes active. Our method cannot grant projected focus regardless of its request.

**Relationship to observed cancellation:** this is the strongest identified code-level explanation for a Maps-only route stop, with moderate confidence in causality. It can send native-focus state without shutting down audio/video. However, the callback logs neither its argument nor its reply; the saved drive logs do not establish whether/when the callback fired, what was requested, or the phone's cancellation policy. There is no primary evidence establishing an exact30-second navigation-focus timeout. Root-cause confirmation remains UNKNOWN until a targeted runtime comparison.

**Counterexamples and alternatives:** incorrect focus handling alone does not prove every cancelled route has this cause. A phone-side Maps issue, arrival handling or an input action could still cancel navigation. Three raw Back presses are recorded at13:41:44.112,13:43:32.545 and13:43:33.360, but route start/end times are absent, so none can be identified as causal. The Java sensor implementation advertises LOCATION and multiple sensors but supplies static initial parked/day/zero-speed state; stock instead connects discovered sensors to live collectors and GPS updates. That sensor discrepancy is real in the inspected Java scope, but its effect on this symptom is less direct and native/phone behavior is unverified. It should remain unchanged for the first focus-only comparison.

**Session timeout explanation weakened:** current session first frame13:41:27.751, transport-write failure13:50:12.135 and surface loss13:50:13.210. These are not a30-second session end. The user's confirmation that AA/music continue supports examining navigation focus separately. Whether the late USB failure is normal unplug remains UNKNOWN.

## 6. Primary evidence for each finding

- Current callback: `analysis/parallel-aa-receiver/src/com/google/android/projection/protocol/GalReceiver.java:85`; native reply declaration at:43.
- Installed proof: `installed-dexdump.txt:2815–2832`, especially:2824 (`const/4 v1, #int 1`) and:2825 (`invoke-direct {v0,v1} ...nativeSetNavFocus`). This overwrites the method's incoming request register. Condensed copy: installed-navigation-callback.txt. Hash chain: provenance.json and run collection.json.
- Enum semantics: `decompiled/AndroidAuto-current/sources/com/google/android/projection/proto/Protos.java:1102–1143`, especially valueOf at:1125–1130 and constructor assignment at:1140–1142. The two enum constructor arguments are index and wire value; projected's wire value is2, not its index1.
- Stock reply path: `decompiled/AndroidAuto-current/sources/com/google/android/projection/protocol/GalReceiver.java:353–361`; `.../com/honda/androidauto/projection/sink/navigation/NavigationFocusManager.java:22–29`; `.../GalNavigationFocusManagerService.java:389–411`. ProjectionActivity:666–675 passes/compares the request with PROJECTED.
- Sensor alternative: current `SensorSource.java:54–81`, caller `AaSessionService.java:357`; stock `.../sensors/SensorManager.java:88–103,160–200`; `.../sensors/LocationSensors.java:36–38,79–93,134–143`. Indexed copies are in source-evidence.txt. No claim that native code cannot emit additional data is made.
- Runtime boundaries and Back events: `analysis/test-prep/runs/helper_20261031T173855_e72a6103b88a4bdc815a3e210f2c4f69/longdrive-evidence/rdx_226d727ddd5b406c92924a6c548c8bb0/capture.log:514,992,2117,2124,3237,3245`; previous offline-review/own-session-timeline.txt. Operator clarification is the subsequent user message, not inferred from logs.

## 7. Assumptions

The user's clarification describes the collected candidate. Stock decompiled Java documents the protocol/JNI contract used by this facade; it is receiver-side evidence, not the current phone's Maps implementation. The reply discrepancy is independently confirmed in the installed APK DEX. No precise route start timestamp or30-second timeout mechanism is assumed.

## 8. Unresolved uncertainties; smallest fix and proof test

**Smallest proposed fix:** honor a valid requested navigation-focus state rather than unconditionally returning1. Request2 -> reply2; request1 -> reply1. Stock simple-manager behavior supports `nativeSetNavFocus(request)` for valid1/2. Add only numeric request/reply logging via the existing listener; explicitly handle unknown values without inventing a focus state. Do not change this into an unconditional reply2, which would mishandle a native-focus request. No sensor, input, overlay, audio, transport or OEM navigation-manager implementation is needed for this candidate.

**Smallest proposed offline validation:** verify the callback answers1 and2 correctly, leaves invalid inputs unforwarded under the chosen policy, and that the built DEX contains the intended request-dependent reply rather than literal1. Preserve existing working input/audio code and pin the new APK hash. This report does not implement or build that change.

**Smallest proposed car comparison:** start a Maps route to a destination away from the current location; timestamp start and make no input for at least90 seconds. Require a recorded projected request2/reply2 if a focus request occurs, route still active, and AA/music continuing. End navigation normally and capture any native request1/reply1; start another route and repeat. If the route still ends with correct focus replies, collect contemporaneous phone Maps/AA evidence and examine the sensor contract separately. Do not promise phone GPS fallback from merely removing advertised sensors. A request not appearing in the log is an inconclusive focus test, not a pass. No car step has been started.

## 9. Exact diff summary

Production implementation diff: none. Added offline evidence extraction/verification and this scoped investigation report. Previous Spotify, volume and hardware media-key work was not expanded or modified.

## 10. Preservation checks performed

Collected installed APK hash matches the pinned long-drive candidate before/after extraction. Both inspected production source hashes match the candidate and remain unchanged. ZIP access extracted only public executable classes.dex; signing/key entries were not read. No frozen artifact rebuilt/modified; no build, installation, source patch, Git mutation, milestone advancement or device action occurred.
