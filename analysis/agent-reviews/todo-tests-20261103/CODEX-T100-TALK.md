**NOT READY — items 3 and 5 are BLOCKERs.**

1. **Files inspected:** `PROJECT-RULES.md`, `AGENTS.md`, `analysis/agent-reviews/todo-tests-20261103/CODEX-T100-RECHECK2.md`, preservation manifest, and sources below. Path aliases:
   - `H=analysis/test-prep/todo-tests-20261103/builds/T100-bundle/source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper`: AaSessionService, InputEvents, AaOverlayService, AaMediaSourceService, AppSettings.
   - `R=C:/Users/REDACTED/AppData/Local/Temp/rdx-t100`; `V=R/vrlib/sources/com/honda/auto/voicerecognition`: IVrProvider, IVrStateListener, VrProvider, ConnectionRecordManager.
   - `S=R/vrsvc/sources/com/honda/speechrecognizer/service`: AbstractVrInputHandlerService, AbstractNuanceVrProviderService, AbstractSpeechRecognizerService, NatpConnection.
   - `T=R/vrsvc/sources/com/honda/tjba/speechrecognizer`: SpeechRecognizerService, syscall/impl/{SystemStateSet,HMIHideAll}, service/VRUIStateMachine, common/VoiceRecognitionStatusFactory; also `R/vrsvc/resources/AndroidManifest.xml` and `decompiled/HondaLib/sources/com/honda/auto/voicerecognitionservice/datatypes/VoiceRecStatus.java`.

2. **Files changed:** none.

3. **Commands run:** read-only `Get-Content`, `rg`, `ConvertFrom-Json`, `Get-FileHash`; in-memory JavaScript branch models. Two guessed reference paths were absent; corrected paths were located. No Git, network, builds, or device commands.

4. **Tests run and results:** branch models reproduced an unreleased key 88 and repeated TalkGate takeover without NOT_ACTIVE. These model the inspected branches; Java/Android execution was **not performed**. Preservation comparisons: **8/8 matched**.

5. **Findings:**
   - **1 — OK:** Provider transactions and listener replies are wire-compatible; `addListener` can accept this listener. Some callback arguments are ignored.
   - **2 — SHOULD-FIX:** Short-press reporting is conditional on engine availability and VR focus. TalkGate omits legitimate statuses and permits another takeover after four seconds without an inactive transition. Dismiss completion and next-press recovery are **UNKNOWN**.
   - **3 — BLOCKER:** Active state provides no evidence of a talk-button press. Other Honda voice starts trigger takeover. Pending takeover has no call-state cancellation.
   - **4 — SHOULD-FIX:** Posting from Binder avoids an immediate synchronous callback cycle, and normal shutdown unregisters/unbinds/cancels callbacks. Provider transactions still block the main handler; failure paths lack a closed/session-generation check.
   - **5 — BLOCKER:** SkipGate’s shared release counter can swallow another key’s real release, leaving that key held.

6. **Primary evidence:**
   - **1:** `V/IVrProvider.java:31-40,90-107` defines descriptor `com.honda.auto.voicerecognition.IVrProvider`, dismiss=5, register=6, unregister=7. Register/unregister consume token, package string, listener binder; dismiss consumes only token; replies contain no-exception. `H/AaSessionService.java:141-155,180-191` matches.
   - **1:** `V/IVrStateListener.java:27-108,224-237`: descriptor `com.honda.auto.voicerecognition.IVrStateListener`; callbacks 1/2/3/4 are connect/failure/disconnect/death, each with a package string and no-exception reply; 5 returns package string, 6 returns integer ID, 7 receives nullable enum followed by caller string. Enum encoding is its name string (`VoiceRecStatus.java:31-32,48-49`). Bridge ignores callback package/caller arguments but returns compatible replies (`H/AaSessionService.java:149-156`).
   - **1:** Registration constructs the record directly (`V/VrProvider.java:210-219`). Acceptance uses ID/package deduplication and `linkToDeath`, with no permission check here (`V/ConnectionRecordManager.java:60-79`). ID 9105 and package replies satisfy those calls. Manifest provider is exported without a service permission (`R/vrsvc/resources/AndroidManifest.xml:78-85`).
   - **2:** Short PTT_UP starts/dispatches the session (`S/AbstractVrInputHandlerService.java:98-119`); session BEGIN emits ACTIVE (`T/syscall/impl/SystemStateSet.java:31-41`). Provider forwards through `updateVrState` (`S/AbstractNuanceVrProviderService.java:24-28`); ordinary active states require focus, whereas SCREEN_FOREGROUND reports before requesting focus (`V/VrProvider.java:84-105`).
   - **2:** TalkGate omits UNDERSTOOD, NOT_UNDERSTOOD, SCREEN_FOREGROUND (`H/InputEvents.java:56-60`; enum `:8-16`); UNDERSTOOD has a native mapping (`T/common/VoiceRecognitionStatusFactory.java:16`). SCREEN_FOREGROUND is treated as NOT_ACTIVE for Honda’s communicator (`S/AbstractVrInputHandlerService.java:284-287`), so blindly adding it is unjustified. Model: ACTIVE at 1000 and 5000 ms fires twice (`H/InputEvents.java:59-60`).
   - **2:** Dismiss releases audio focus/mic (`S/AbstractSpeechRecognizerService.java:322-334`), sends native SILENT_ABORT and hides UI (`T/SpeechRecognizerService.java:846-854`; `S/NatpConnection.java:131-140`). It does not directly reset VR state/timestamp or abandon VR focus. END reports NOT_ACTIVE; HMIHideAll updates timestamp (`T/syscall/impl/SystemStateSet.java:44-50`; `HMIHideAll.java:31-48`). Native completion timing is **UNKNOWN**; no permanent focus break is established.
   - **3:** Non-PTT `startVrSession` reaches the same engine (`S/AbstractNuanceVrProviderService.java:142-157`). Bridge gates only on running/state and sends Assistant even if dismiss fails (`H/AaSessionService.java:195-202`). Incoming/dialing/active calls block Honda focus (`S/AbstractVrInputHandlerService.java:303-311,538-548`); incoming call alone is **not established** as an ACTIVE producer. No hang-up operation appears in the takeover path; actual call/audio harm remains **UNKNOWN**.
   - **4:** Honda waits synchronously under its listener-list lock (`V/ConnectionRecordManager.java:40-43,110-115`; `IVrStateListener.java:236-237`). Bridge posts work, but register/dismiss/unregister use synchronous transactions (`H/AaSessionService.java:168-199`). Disconnect clears provider; reconnect registers (`:173-178`). Shutdown stops bridge and removes callbacks before clearing running (`:936-946`); queued work has no closed/generation check (`:198-202`).
   - **5:** Counterexample, all releases exactly 100 ms after DOWN: `88D@1000,87D@1010,87D@1020,88U@1100,87U@1110,87U@1120` forwards **88D,87D,87U,87U**. Shared `dropUps` consumes 88U (`H/InputEvents.java:36-45`). Both routes schedule 100 ms releases (`H/AaSessionService.java:129-130`; `AaOverlayService.java:404-408`). Gate is service-scoped, runs before the running check, and has no reset (`AaSessionService.java:120,344-347`; `InputEvents.java:34-48`), leaving reuse/restart suppression concerns.

7. **Assumptions:** Supplied decompilation represents the target Honda implementation; event traces are possible orderings, not observed vehicle logs.

8. **Unresolved uncertainties:** Live binding, native abort completion, next-press timing, call interference, and service-restart ordering are **UNKNOWN**.

9. **Exact diff summary:** none.

10. **Preservation checks:** SHA-256 matched PROJECT-INTEGRITY for four frozen anchors, both receiver DEX copies, and readiness wrapper/core/schema: **8 matches**. No writes, credential/private-material reads, device access, guard changes, or milestone actions.