**Verdict: NOT READY. Item 4 has a BLOCKER in focus cleanup.**

1. **Files inspected:** `PROJECT-RULES.md`, `AGENTS.md`, all named T110 reviews/reconciliation and results; T110/T120 sources; T120 tests, manifests, saved test output, preparation/collection scripts; runner, checklist, layout spec; saved car log; supporting Honda focus/voice decompilation.
   Aliases: `B=analysis/test-prep/todo-tests-20261103`; `T=B/builds/T120-bundle`; `H=T/source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper`; `P=T/source/analysis/parallel-aa-receiver/src/com/google/android/projection/protocol`.
   `H110=B/builds/T110-bundle/source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper`; `F=decompiled/Framework/sources/android/media`.
   `L=analysis/test-prep/runs/helper_20261108T040526_5c06199efea94e07aa31d368429cfc21/longdrive-evidence/rdx_34fc3e6cc0f94bcd8c32b6ec04cb52a7/capture.log`.

2. **Files changed:** none.

3. **Commands run:** read-only `Get-Content`, `Get-ChildItem`, `Get-Command`, `rg`, and `node -e` for numbered excerpts, in-memory source comparisons and SHA-256 checks. Python launch attempts failed; Node supplied the comparisons. No Git, network, builds or device commands.

4. **Tests run and results:** no executable suites run. Saved `T/host-test-output.txt:1-9` reports **165 bundle checks plus eight passing feature suites**. `T/BundleTests.java:128-133` checks option membership and Siri gate behavior, not Android focus cleanup, callback ordering or UI layout.

5. **Findings:**

   - **1 — Settings: SHOULD-FIX.** Controls, Back navigation and watchdog timestamp survive; no empty-preference crash found. Lost: the Honda Disabled/Never reminder for added devices, wireless probe action logs, and the visible auto-accept attempt result. Actual fit remains **UNKNOWN**.
   - **2 — Button gates: OK for normal Settings interaction; SHOULD-FIX one bypass.** Skip pairs are generated together, and their delayed release is ungated; no ordinary UI toggle-between-down/up failure found. Home off plus side-hold off removes active-session Settings access, but exit/Back and unplug recovery remain. `onPlayFromMediaId()` bypasses `BTN_PLAY`.
   - **3 — Main-phone disable: OK for inspected paths.** It narrows cooperative policy, including matching-serial AOAP devices and both polling paths. It does not stop an existing session. Re-enabling through the tile requires unplugging; the checklist specifies this.
   - **4 — Talk: BLOCKER.** After a successful grab, a denied re-grab overwrites `grabbed=false`; timeout/shutdown then skip abandonment although the earlier focus entry can remain registered. Also **SHOULD-FIX:** lost early `NOT_ACTIVE`, no call recheck during queued work/re-grabs, and Siri availability states triggering Assistant.
   - **5 — Persistent/default/runner: OK for inspected flow.** Missing preference defaults ON; saved OFF survives, while automatic `PERSISTENT_ON` explicitly overrides it. Default ON grants nothing. With accessibility OFF and no grant, boot checks cannot start the helper; already-enabled accessibility can start it without that grant. Collect/UNDO retains explicit OFF, revoke and verification steps. Automatic hooks remain displayed, logged and checked for shell return status.
   - **6 — VISIT: SHOULD-FIX.** Main-phone recovery and Talk reconnect instructions agree with source. Collect omits the preceding `COLLECT` prompt; takeover wording overstates the bounded retries and timeout behavior. Several new switch combinations lack checklist coverage.

6. **Primary evidence for each finding:**

   - **1:** `H/SettingsActivity.java:24-25,44,47-49` retains timestamp and Back handling; `:124-125` handles absent phone preferences. Defaults/clamps are at `H/AppSettings.java:45-54,68-73,97`. Compare `H110/SettingsActivity.java:95,105-107,127,136` with `H/SettingsActivity.java:120,169-182` for the lost reminder, result display and logs.
   - **2:** `H/InputEvents.java:109` emits both skip phases synchronously; `H/AaOverlayService.java:442-448` gates them and schedules an ungated release. Back emits complete pairs (`:482-489`). Exit remains available (`:244-253`); no-phone tile opens Settings directly (`H/HelperActivity.java:37-40`). Side return/Assistant use session flags (`overlay :162-163`), captured at `H/AaSessionService.java:354`; BTN gates read preferences live. Ungated Play path: `H/AaMediaSourceService.java:111-113`.
   - **3:** `H/UsbHelperService.java:78-80,316-317,761,794-795` supplies disable checks; polling uses them at `:355,363`, attached handling at `:262`, final handoff at `:607`. Legacy `policyAllows` returns early (`:759`), but legacy policy has no configured main serial (`H/HondaPhonePolicy.java:89`). Tile launch-versus-Settings behavior: `H/HelperActivity.java:26-40`; recovery instructions: `B/VISIT.md:37-38`.
   - **4, blocker:** `H/AaSessionService.java:262-263` replaces the ownership flag on every request; `:283` skips abandonment when false. Honda can reject before removing the earlier entry (`F/MediaFocusControl.java:767-769`, removal at `:812`); focus-loss propagation retains entries (`:494-498`). Preserve “ever registered” ownership or abandon unconditionally.
   - **4, ordering/calls:** `session :234-239` tests `takeoverActive` on the Binder thread before queued `startTakeover()` sets it (`:251-256`), so ACTIVE→NOT_ACTIVE before handler execution loses completion. Call checking occurs at `:238`, but not in start/re-grab/delayed Assistant (`:251-277,293-296`). Timeout sends nothing (`:274`); normal shutdown releases before callback removal (`:1062-1065`), subject to the blocker.
   - **4, audio/Siri:** retries are bounded to ten/50 ms and three seconds (`session :293-310`), but can repeatedly displace focus. Stream 9 does not prove isolation: `F/MediaFocusControl.java:415-431` permits music-stack aliasing; `P/AudioSink.java:60-66` pauses on transient loss, forwarded by `session :595-599`. Siri maps every non-idle string to ACTIVE (`H/InputEvents.java:59-62`), explicitly including `NOT_AVAILABLE` in `T/BundleTests.java:132`. Binding exceptions are caught (`session :188-192`); saved logs establish the package/action (`L:351`), not successful third-party registration. The motivating loss is recorded at `L:4495-4498`.
   - **5:** `H/PersistentMode.java:24-27,73-74`; `H/PersistentBootService.java:16,44-54`; `H/BootBlockerReceiver.java:27-31`. Setup/undo commands: `T/test.json:74-84`. Runner preserves START/readiness before the automatic hook (`B/tools/Run-Test.ps1:81,104-107`), command display/logging/status checks (`:44-51`) and undo handling (`:65-74`). Shell success does not establish that the receiver persisted its preference.
   - **6:** `B/VISIT.md:11,32-45,49`; runner requires `COLLECT` at `B/tools/Run-Test.ps1:65`, then `UNDO` at `:68`.

7. **Assumptions:** supplied Honda decompilation represents the target firmware; omitted bundle paths use the saved baseline.

8. **Unresolved uncertainties:** actual focus-stack mapping, denied-regrab occurrence, call disruption, Siri registration/initial states, layout fit and installed-source parity are **UNKNOWN**.

9. **Exact diff summary:** none made. Comparison identified eight changed source files versus T110.

10. **Preservation checks performed:** T120 source hashes matched **36/36** manifest entries; saved baseline matched **36/36** corresponding entries; complete saved and live baselines each matched **41/41**. APK SHA-256 matched package verification: `33C895B133198DC15229C35F0D80AF7ABB5F871166A7274AF03FAE3A6D339697`. Frozen anchors were not rehashed. No writes, credential/private-test reads, agents, device access or milestone actions.