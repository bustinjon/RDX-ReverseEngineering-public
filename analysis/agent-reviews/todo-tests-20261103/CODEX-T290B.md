1. **Files inspected:** `PROJECT-RULES.md`, `AGENTS.md`; T290 `AppSettings`, `SettingsActivity`, `AaSessionService`, `WirelessProbeService`, `AudioSink`; T280 counterparts except `AaSessionService`. Paths below use `B=analysis/test-prep/todo-tests-20261103/builds`, `U=source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper`, `A=source/analysis/parallel-aa-receiver/src/com/google/android/projection/protocol`.

2. **Files changed:** none.

3. **Commands run:** `Get-Content`, `rg --files`, `rg -n` and numbered source reads. One search failed PowerShell parsing; a Python comparison failed because Python was unavailable.

4. **Tests run and results:** none; static review only, as requested.

5. **Findings / verdict:** **SHOULD-FIX**. No proven BLOCKER; findings and primary evidence follow.

6. **Primary evidence for each finding:**

   - **SHOULD-FIX — audio overflow:** larger windows permit larger bursts; a full queue drops incoming frames and still acknowledges them. Ack-on-arrival means even 16 does not bound playback backlog, so merely capping at 64 cannot ensure safety. No new mandatory delay, but extra queued PCM can increase latency. `B/T290-bundle/A/AudioSink.java:38,62,146,149,208,246`; T280 already has this queue/ack policy at `AudioSink.java:62,143,146`.

   - **OK — static initialization:** overwritten for each protocol initialization before media construction and its `nativeInit`; guidance remains 16. The native setter itself runs **after** `nativeInit`, before registration/protocol start. Existing sinks do not reread the static. `B/T290-bundle/U/AaSessionService.java:813,833,841,890`; `B/T290-bundle/A/AudioSink.java:90,97,101,102`.

   - **SHOULD-FIX — restart race:** the advertised 3-second wait is bypassed: STOP immediately calls `startDaily`, while group removal/channel reset are asynchronous. Late callbacks lack a run identifier: an old success can create a group once `running` becomes true again; old cleanup can overlap the replacement group/channels. Serialize cleanup/restart and reject stale callbacks. `B/T290-bundle/U/SettingsActivity.java:292`; `B/T290-bundle/U/WirelessProbeService.java:533,636,650,922,992,1031`. The immediate-restart behavior also exists in T280 at `WirelessProbeService.java:529`.

   - **OK — pending boot delay:** shutdown cancels handler callbacks; a replacement start recalculates the boot deadline and checks the main switch. Live wireless sessions receive STOP during shutdown. `B/T290-bundle/U/WirelessProbeService.java:161,573,582,1033,1036`.

   - **OK, conditional — channel 149 refusal:** `onFailure` continues with group creation, avoiding a deliberate stall. However, it performs no explicit default-channel reset; after a failed previous reset, “default band” is unproven and the recovery flag is cleared. Preserve/retry cleanup before claiming default fallback. `B/T290-bundle/U/WirelessProbeService.java:640,922,924`.

   - **SHOULD-FIX — stranded variant:** saved `wireless_variant` remains active whenever Wireless test is ON, including daily starts. Its selector disappeared, its setter has no remaining caller, and `resetAll` does not reset it. This can retain Nudge/Honda reconnect or bypass the channel choice. The removed phone-server button was an action, with no corresponding persisted setting identified. `B/T280-bundle/U/SettingsActivity.java:338,347`; `B/T290-bundle/U/AppSettings.java:92,146`; `B/T290-bundle/U/WirelessProbeService.java:553,558,590,628`.

7. **Assumptions:** reviewed bundle source represents the intended candidate; APK parity was not established.

8. **Unresolved uncertainties:** actual drop/latency changes, native window behavior, callback timing and driver channel refusal/reset behavior are **UNKNOWN** without runtime evidence.

9. **Exact diff summary:** none; no files changed.

10. **Preservation checks performed:** read-only commands only; no builds, Git, network, devices or key-material access. Frozen-artifact hashes were not rechecked.