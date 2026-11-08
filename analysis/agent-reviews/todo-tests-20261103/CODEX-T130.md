**Verdict: NOT READY. The hold detector has a BLOCKER.**

Aliases: `B=analysis/test-prep/todo-tests-20261103`; `T=B/builds/T130-bundle`; `H=T/source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper`; `S=H/AaSessionService.java`; `U=H/SettingsActivity.java`.
`L=analysis/test-prep/runs/helper_20261108T052347_cea5025136124d48b5ee3861afc2be82/longdrive-evidence/rdx_31a25906f05c4174a52a1c46a14fc073/capture.log`.

1. **Files inspected:** `PROJECT-RULES.md`, `AGENTS.md`, all three `CODEX-T120*.md` reports, `CLAUDE-T120-RECONCILE.md`, T120 `RESULT.md`; both source trees, T130 `BundleTests.java`, saved host-test output, `B/VISIT.md`, and `L`.
2. **Files changed:** none.
3. **Commands run:** read-only `Get-Content`, `Get-ChildItem`, `Get-Item`, `rg`, `fc.exe`, and `node -e` for byte comparisons and arithmetic. Initial `fc.exe` attempts failed; corrected Windows paths succeeded.
4. **Tests run and results:** no executable suites or builds. Saved `T/host-test-output.txt:1-9` reports 170 bundle checks plus eight passing suites. In-memory timing calculation returned `hold predicate=true`; layout calculation returned 102px/30px for 10 items and 83px/24px for 12 items.
5. **Findings:**
   - **1 — BLOCKER:** NOT_ACTIVE does not identify a hold. The saved log contains another qualifying event after call termination. Any short-press NOT_ACTIVE delayed ≥3 seconds after Honda’s last state also qualifies.
   - **1 — SHOULD-FIX, threading/lifecycle:** volatile fields provide visibility, but eligibility checking and timestamp updating are not atomic. Concurrent callbacks can both pass. Initial timestamps admit the first idle notification; reconnect has no explicit suppression. Honda-takeover Assistant sends do not update `lastSiriFireMs`.
   - **2 — OK implementation; SHOULD-FIX test coverage:** schema 130 migrates TALK_VOICE on and SIDE_ASSISTANT off; snapshot defaults agree. Supplied tests check defaults and membership, without exercising migration.
   - **3 — SHOULD-FIX:** sizing establishes minimum heights, without proving rendered fit. Reset confirmation survives page rebuilds/navigation; older timers can cancel a newer confirmation, and expiry depends on callback execution rather than an elapsed-time check.
   - **4 — SHOULD-FIX:** VISIT matches labels/defaults, but lacks idle/reconnect, post-call, delayed-short-press and Reset navigation/rearming checks.
6. **Primary evidence for each finding:**
   - **1, observed counterexample:** `L:7039` reports call IDLE; `L:7053-7055` reports Siri NOT_ACTIVE. Last Honda state is `L:6579` at 681520ms; last preceding hold notification is `L:6837` at 725013ms. At 738540ms, gaps are **57020ms/13527ms**, satisfying `H/InputEvents.java:72-75`. Actual T130 dispatch remains conditional on its call guard.
   - **1, bind/reconnect/feedback:** registration has no initial-event guard (`S:204-218`); timestamps initialize to −100000 (`S:339`); bridges start after `running=true` (`S:676-681`). Siri checks/writes occur separately (`S:228-238`). Honda’s Assistant path (`S:299-303`) and key sender (`S:342-350`) do not record a Siri fire. Initial/reconnect notifications and Assistant-induced late notifications are **UNKNOWN**.
   - **1, threading:** Binder callback entry is `S:175-180`; timestamp operations are `S:228-237`. `TalkGate` synchronization (`H/InputEvents.java:59-64`) does not encompass the hold check and fire update.
   - **2:** option/test membership `H/AppSettings.java:30-39`; schema/migration `:43,52-65`; fallback and snapshots `:98,124,134-137`. Tests: `T/BundleTests.java:16-23,134-139`; no migration invocation.
   - **3, sizing:** `U:225-240` uses display height, a fixed 150px header allowance, and minimum heights; headers use scaled text units (`:70-72,253-255`). Long device labels are dynamic (`:142-154`). Rendered clipping/fit is **UNKNOWN**.
   - **3, reset:** boolean state `U:28`; rebuild/navigation `:47-64`; reset and uncancelled delayed callback `:97-108`. Example: arm at 0s, confirm at 1s, rearm at 2s; the original timer clears confirmation at 4s. Back navigation does not disarm it.
   - **4:** stated behavior and checks are `B/VISIT.md:8-10,21-31`; source labels/defaults match `U:87,119,124` and `H/AppSettings.java:30-39`.
7. **Assumptions:** saved log timing is representative; 720px is the supplied layout-test input.
8. **Unresolved uncertainties:** actual initial/reconnect callback delivery, Assistant feedback timing, call-mode clearance at the logged NOT_ACTIVE, callback overlap, and rendered text fit are **UNKNOWN**.
9. **Exact diff summary:** no review edits. Both source sets contain 36 files, with no additions/removals; five differ: `AaOverlayService`, `AaSessionService`, `AppSettings`, `InputEvents`, `SettingsActivity`.
10. **Preservation checks performed:** byte-compared the source sets; no writes, Git, network, builds, device access, credential/private-material reads, agents, or milestone actions. Frozen artifacts were not rehashed.