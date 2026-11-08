1. **Files inspected:** `PROJECT-RULES.md`, `AGENTS.md`, both T120 review/reconciliation reports, and bundle `AaSessionService.java`, `InputEvents.java`, `BundleTests.java`.
   Paths: `H=analysis/test-prep/todo-tests-20261103/builds/T120-bundle/source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper`; `S=H/AaSessionService.java`.
2. **Files changed:** none.
3. **Commands run:** read-only `Get-Content`, `rg --files`, `rg -n`, PowerShell numbering/filtering.
4. **Tests run and results:** none executed; static control-flow review only.
5. **Findings:**
   - **BLOCKER:** stale NOT_ACTIVE remains possible. New ACTIVE receives sequence N; a subsequently arriving stale NOT_ACTIVE receives N+1, passes the guard, releases the new takeover, and schedules Assistant. Arrival order does not identify the originating voice session.
   - **SHOULD-FIX:** an early legitimate stop can still be lost if Binder callbacks overlap: ACTIVE passes its gate but pauses before posting; NOT_ACTIVE posts and executes while inactive; ACTIVE then posts and starts. Timeout eventually releases it without Assistant.
   - **SHOULD-FIX (accepted):** actual Assistant-key execution still lacks a call recheck.
   - **OK:** re-grabs now check calls and finish without Assistant; ordinary later stops finish; timeout and shutdown retain cleanup paths.
6. **Primary evidence:**
   - Stale completion: string-only payload `S:180`; arrival numbering/posting `S:238–245`; start identity `S:266`; acceptance/release/Assistant scheduling `S:280–293`.
   - Lost legitimate stop: separate gate/post operations `S:243–245`; inactive completion discarded `S:281`; start has no remembered-stop check `S:262–269`.
   - Assistant call gap: check `S:291`, additional queue hop and unchecked send `S:333–335`.
   - Cleanup: call-triggered finish `S:257`; timeout `S:260,269,325`; cancellation/release `S:283–288`; shutdown release `S:195–201` precedes callback removal `S:1078–1081`.
7. **Assumptions:** concurrency counterexample assumes overlapping Binder callbacks; occurrence is **UNKNOWN**.
8. **Unresolved uncertainties:** actual stale delivery, runtime callback ordering, call behavior, and installed-artifact parity are **UNKNOWN**. Normal-path timeout is bounded; handler stalls/exceptions remain unverified.
9. **Exact diff summary:** none.
10. **Preservation checks performed:** commands were read-only; no writes, builds, Git, network, devices, credential/private-material reads, or milestone actions.

**Verdict: NOT READY.**