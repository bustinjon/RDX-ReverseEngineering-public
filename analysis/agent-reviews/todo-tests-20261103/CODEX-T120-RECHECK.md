**Verdict: NOT READY.**
1. **Files inspected:** `PROJECT-RULES.md`, `AGENTS.md`, `CODEX-T120.md`, `CLAUDE-T120-RECONCILE.md`; files cited below, source manifest, saved host-test output, and `tools/Run-Test.ps1`.
   Aliases: `B=analysis/test-prep/todo-tests-20261103`; `T=B/builds/T120-bundle`; `H=T/source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper`; `F=decompiled/Framework/sources/android/media`.
2. **Files changed:** none.
3. **Commands run:** read-only `Get-Content`, `rg`, `Get-FileHash`, and PowerShell filtering/numbering. Hash-output formatting initially failed under constrained language; corrected command succeeded.
4. **Tests run and results:** none executed. Saved `T/host-test-output.txt:1-9` reports 165 bundle checks plus eight feature suites; this does not establish callback ordering.
5. **Findings:**
   - **Focus ownership/release — OK:** denied re-grabs no longer erase cleanup responsibility. Abandonment after an entirely denied request also unregisters the local listener; absent server entries are harmless.
   - **Queued NOT_ACTIVE — BLOCKER:** early completion is preserved, but completion has no takeover identity. Counterexample: new `ACTIVE` queues its start, then a stale previous voice-session `NOT_ACTIVE` queues finish; execution starts the new takeover, immediately releases it, and schedules Assistant. Whether Honda produces this ordering is **UNKNOWN**; the source provides no defense.
   - **Call rechecks — SHOULD-FIX:** start and delayed Assistant now check calls, but re-grabs still do not. The actual Assistant-key runnable also lacks a recheck after its additional queue hop.
   - **Siri gating — OK:** only four explicit active states trigger; availability states are rejected.
   - **onPlayFromMediaId — OK:** now obeys `BTN_PLAY`.
   - **Settings restorations — OK:** Disabled/Never reminder, probe logs, and visible auto-accept result restored.
   - **VISIT — OK for requested corrections:** bounded takeover wording and `COLLECT` then `UNDO` are present. Stale completion above can still violate its “only once Acura voice has stopped” promise.
   - **Accepted limitations — OK as disclosed:** exit icon remains available; Back-hold recovery depends on its switch. Re-grabs remain bounded.
6. **Primary evidence for findings, respectively:**
   - Focus: `H/AaSessionService.java:266-291,1068-1071`; `F/AudioManager.java:967,1003-1006`; `F/MediaFocusControl.java:520-561,838-848`.
   - Ordering: state payload carries only a string (`H/AaSessionService.java:180`); unconditional queued finish at `:236-242`; current-takeover finish and Assistant scheduling at `:271-283`.
   - Calls: `H/AaSessionService.java:256,281`; unchecked re-grab at `:251,263-268`; queued key execution at `:323-325`.
   - Siri: `H/InputEvents.java:59-63`; `T/BundleTests.java:131-133` checks availability rejection.
   - Play: `H/AaMediaSourceService.java:113`.
   - Settings: `H/SettingsActivity.java:121,157-159,170-185`.
   - VISIT: `B/VISIT.md:11-12,49`; runner prompts at `B/tools/Run-Test.ps1:65,68`.
   - Accepted limitations: `H/AaOverlayService.java:244-253,486-489`; retry limits at `H/AaSessionService.java:299-302,315-316`.
7. **Assumptions:** supplied framework decompilation represents target firmware; stale-event counterexample concerns successive voice takeovers on the same bridge.
8. **Unresolved uncertainties:** actual stale-event occurrence, live call effects, Siri behavior, layout fit, focus-stack mapping, and installed-artifact parity are **UNKNOWN**.
9. **Exact diff summary:** none.
10. **Preservation checks performed:** four inspected changed Java sources matched their manifest SHA-256 values (**4/4**). Frozen artifacts untouched; no writes, builds, Git, network, credential/private-material reads, device access, or milestone actions.