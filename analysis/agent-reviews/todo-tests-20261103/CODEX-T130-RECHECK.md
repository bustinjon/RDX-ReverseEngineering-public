**Verdict: READY FOR CAR TEST**, under the operator’s acceptance of the default-off hold experiment.

Aliases: `B=analysis/test-prep/todo-tests-20261103`; `T=B/builds/T130-bundle`; `H=T/source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper`; `S=H/AaSessionService.java`; `U=H/SettingsActivity.java`.

1. **Files inspected:** `PROJECT-RULES.md`, `AGENTS.md`, `CODEX-T130.md`, `CLAUDE-T130-RECONCILE.md`; T130 `S`, `U`, `AppSettings.java`, `InputEvents.java`, `BundleTests.java`, `host-test-output.txt`; T120 `AaSessionService.java`; `B/VISIT.md`.
2. **Files changed:** none.
3. **Commands run:** read-only `Get-Content` and `rg`. One search failed PowerShell parsing; corrected search succeeded.
4. **Tests run and results:** none executed. Saved `T/host-test-output.txt:1-9` reports eight passing suites and 173 bundle checks; current-source/build correspondence is **UNKNOWN**.
5. **Findings:** no BLOCKER identified within the accepted experimental scope; remaining SHOULD-FIX items follow.
6. **Primary evidence for each finding:**

   - **OK — default-off isolation:** TALK_HOLD is a feature with false fallback/migration/reset defaults (`H/AppSettings.java:38,64,98,108`); only hold enables Siri and polling (`S:702-708`).
   - **OK — press takeover with hold off:** Honda still binds with takeover enabled when TALK_VOICE is on (`S:703-704`). Sequencing, focus acquisition/release and delayed Assistant path remain as in T120; the added timestamp cannot trigger Siri when its bridge is absent (`S:245-340`; T120 counterpart `:236-330`).
   - **OK — hold-only does no takeover:** Honda updates its timestamp and returns before takeover processing (`S:232-233`); Siri dispatches the Assistant key (`S:241-242`).
   - **OK / SHOULD-FIX — claimHold atomicity:** hold callers serialize eligibility and reservation (`S:347-350`). Honda/call/press timestamp writers remain outside that lock (`S:232,240,306,359`), so cross-path ordering is not atomic.
   - **OK / SHOULD-FIX — call watcher:** starts only with hold, stops rescheduling without a running Siri session, and shutdown removes callbacks (`S:354-361,706-708,1117-1125`). Polling can miss a call entirely between samples; the 10-second interval measures from the last observed call, not hang-up (`H/InputEvents.java:73-75`).
   - **OK — settle window:** each bridge connection records uptime before registration; Siri suppresses callbacks for 5 seconds, including reconnection (`S:206-209,239,345`).
   - **OK / SHOULD-FIX — Reset:** elapsed-time validation and age-checked expiry prevent the old timer problem; hardware Back disarms (`U:51-54,101-107`). On-screen submenu Back uses `open()` without disarming (`U:57,132,217`).
   - **SHOULD-FIX — VISIT/coverage:** checks default press, enabled hold, post-call behavior and hardware Back (`B/VISIT.md:24-34`), but omits hold-only, explicit idle/reconnect false-trigger observation and rapid Reset rearming. Buttons now has 11 items (`U:121-132`), while its sizing assertion still uses 10 (`T/BundleTests.java:139`).

7. **Assumptions:** operator acceptance covers remaining unknown Siri NOT_ACTIVE sources, as supplied.
8. **Unresolved uncertainties:** live callback ordering, short-call detection, rendered fit and APK/source parity are **UNKNOWN**.
9. **Exact diff summary:** none; no files changed.
10. **Preservation checks performed:** only read/search commands used; no Git, network, builds, device access, credential/private-material reads or milestone actions. Frozen artifacts were not rehashed.