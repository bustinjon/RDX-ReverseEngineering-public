1. **Files inspected:** `PROJECT-RULES.md`, `AGENTS.md`; source and log files defined below.
   `B = analysis/test-prep/todo-tests-20261103/builds/T180-bundle/source/analysis/parallel-aa-receiver`
   `S = B/usb-helper/source/com/rdx/fullscreen/usbhelper/AaSessionService.java`; `I =` adjacent `InputEvents.java`.
   `A = B/src/com/google/android/projection/protocol/AudioSink.java`; `G = B/usb-helper/source/com/google/android/projection/protocol/GalReceiver.java`.
   Also inspected `analysis/parallel-aa-receiver/src/com/google/android/projection/protocol/AudioFocusPolicy.java` and decompiled files cited below.
   `L = analysis/test-prep/runs/helper_20261108T174704_24e2dc638e044e73993ae71b1884badd/longdrive-evidence/rdx_9dbb50755111460d9dffccea1d6da4de/capture.log`.
2. **Files changed:** none.
3. **Commands run:** read-only `Get-Content`, `rg --files`, `rg -n`, directory listing, and numbered source/log excerpts; initial abbreviated paths failed and were resolved.
4. **Tests run and results:** static source/log review only; no executable tests or builds.
5. **Findings — NOT READY.**
   **OK:** missed-restore diagnosis and protocol status `2 = ended` are supported.
   **BLOCKER:** an owed restore survives a subsequent focus loss; an old assistant-end event can therefore send gain during a new talk takeover or call.
   **BLOCKER:** timeout checks guidance focus but not whether Gemini remains active/listening; after 12 seconds of silence it can announce music gain during Gemini.
   **SHOULD-FIX:** guidance suppression discards the debt and cancels its timeout, potentially leaving music paused again.
   **SHOULD-FIX:** repeated internal restores enqueue the same timeout without replacing earlier deadlines.
   **OK:** repeated end/timeout callbacks cannot pay the same debt twice; phone gain clears debt; shutdown removes queued timeouts.
6. **Primary evidence:**
   Diagnosis: `L:6723–6725` sends state 5/stops media; `L:6762–6768` grants transient focus/internal duck; `L:6790–6792` suppresses gain. Successful comparison gains occur at `L:7069` (12:53:51) and `L:7372` (12:54:13), rather than the stated seconds.
   Later-talk counterexample: `L:7315–7316` internal restore → `L:7355–7357` new takeover/loss → `L:7358` previous voice end. Applying this order to `S:652`, `S:987`, `S:997–1006` pays stale debt during takeover; new losses never invalidate it. Call checks exist at `S:332–337`, outside the payment path.
   Timeout/guidance: `I:80` specifies 12 seconds; `S:1001–1006` clears debt before checking guidance and has no active-assistant/call/takeover guard. `A:104` covers held/requesting/draining guidance.
   Timer/duplicate/shutdown: enqueue at `S:652`; payment cancellation at `S:1001–1003`; phone-gain cancellation at `S:674`; shutdown cancellation at `S:1198`, running guard at `S:1004`.
   Protocol: `decompiled/AndroidAuto-current/sources/com/google/android/projection/proto/Protos.java:1226–1227` maps 2 to END; adjacent `protocol/GalReceiver.java:377–379` forwards status unchanged; `G:106` preserves it.
7. **Assumptions:** counterexamples apply the inspected implementation to the saved event order; they are not observed T180 executions.
8. **Unresolved uncertainties:** actual phone response to a premature gain and runtime callback races remain **UNKNOWN**.
9. **Exact diff summary:** none.
10. **Preservation checks performed:** read-only command audit; no writes, Git, network, builds, device access, credential reads, or frozen-artifact changes; no artifact hashes verified.