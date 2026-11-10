1. **Files inspected:** `PROJECT-RULES.md`, `AGENTS.md`; 35 paired Java/XML source files; T210 `RESULT.md`; T220 `BundleTests.java` and `host-test-output.txt`.
   Paths below: `B=analysis/test-prep/todo-tests-20261103/builds/T220-bundle`; `H=B/source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper`; `P=B/source/analysis/parallel-aa-receiver/src/com/google/android/projection/protocol`.
2. **Files changed:** none.
3. **Commands run:** `Get-Content`, `rg`, `Select-Object`, `Get-Command`; Node read-only source comparison and SHA-256 calculation. Python/py attempts failed before execution.
4. **Tests run and results:** none executed. Archived `B/host-test-output.txt:1–9` records passing feature suites and 237 bundle checks; this does not establish runtime lifecycle correctness.
5. **Findings — verdict: BLOCKER for dependable everyday recovery; address F1 before approval.**
   - **F1 BLOCKER:** Bluetooth reopening makes one attempt after five seconds. If Bluetooth remains off, or listener creation fails, recovery ends permanently while daily mode stays running. Group-information timeout and TCP-listen failure likewise leave daily mode stranded.
   - **F2 SHOULD-FIX:** Enabling the Developer test while everyday mode already runs does not apply its selected variant: variant selection occurs only inside `!running`. The retained `daily` flag also prevents the test’s 30-minute window.
   - **F3 SHOULD-FIX:** Boot channel cleanup can clear the new run’s recovery preference: an outstanding reset callback writes `false` after daily startup writes `true`; the new channel-success callback does not restore that preference.
   - **F4 SHOULD-FIX:** Both listeners retain the test’s 200-accept ceiling. Reaching it exits the loop without closing/reopening the listener, despite everyday mode having no time limit.
   - **F5 SHOULD-FIX:** Special-action branches return `START_NOT_STICKY` even when daily mode remains active, notably `ACTION_SESSION_ENDED` during Developer testing. Preserve the daily restart policy consistently.
   - **F6 OK, with timing UNKNOWN:** Queue insertion still uses `offer`, and AudioTrack writes remain on the worker. Full-queue packets are dropped and acknowledged, preserving bounded overload handling. Guidance shares the larger buffers: capacity adds no deliberate queue-fill delay, but permits more backlog; actual prompt onset/drain latency is unproven.
   - **F7 OK:** Delayed retries recheck the owner switch; an OFF switch prevents another daily attempt. Duplicate daily starts do not create additional listeners. Normal daily variant 4 cannot select nudge/Honda reconnect. Bluetooth reopening checks both `running` and socket identity, protecting against a stale reopen after shutdown.
   - **F8 UNKNOWN:** Settings fit is unverified. The switch includes potentially long status text, buttons can wrap, and there is no scrolling container. Existing fit assertions omit Devices.
6. **Primary evidence for each finding:**
   - F1: `H/WirelessProbeService.java:616–636` (single reopen, terminal off/refusal); `:545` (group timeout); `:574` (TCP failure).
   - F2: `H/SettingsActivity.java:277–287`; `H/WirelessProbeService.java:461–485`.
   - F3: `H/BootBlockerReceiver.java:40–41`; `H/WirelessProbeService.java:429–435`, `:503–515`, `:784–786`. Station restore/pause itself is synchronous and ordered at `:758–772`; the identified race concerns asynchronous channel recovery.
   - F4: `H/WirelessProbeService.java:580–610`, `:630–649`.
   - F5: `H/WirelessProbeService.java:429–453`, contrasted with daily return at `:491`; caller gate: `H/AaSessionService.java:1361`.
   - F6: `P/AudioSink.java:54`, `:124–135`, `:158–176`, `:185–220`; guidance configuration: `H/AaSessionService.java:807–812`.
   - F7: `H/AppSettings.java:31`, `:94–98`, `:127`; `H/WirelessProbeService.java:82–91`, `:423–427`, `:443–468`, `:636`, `:889–895`.
   - F8: `H/SettingsActivity.java:232–239`, `:317–355`; `B/BundleTests.java:202–204`.
7. **Assumptions:** Owner default ON and everyday Quiet Wi-Fi ON are accepted operator decisions.
8. **Unresolved uncertainties:** Runtime stop/recreation ordering, Bluetooth recovery duration, native acknowledgement blocking, guidance latency, and rendered Devices-page fit are **UNKNOWN**.
9. **Exact diff summary:** No review edits. Source comparison found exactly six changed files: AudioSink, AppSettings, WirelessProbeService, BootBlockerReceiver, PersistentBootService, SettingsActivity.
10. **Preservation checks performed:** Read-only operations only; no builds, Git, network, device access, or credential-material reads. Frozen artifacts were untouched; their hashes were not reverified.