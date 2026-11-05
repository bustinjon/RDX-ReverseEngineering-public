**T39 and T41 have access-control blockers. T43’s port is complete, but its advertised frozen-session recovery is not implemented.**

Path aliases: `R=analysis/test-prep/todo-tests-20261103`; `B=R/baseline-source`; `C37/C38/C39/C41/C43=R/builds/<corresponding candidate>/source`; `H=analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper`; `P=analysis/parallel-aa-receiver/src/com/google/android/projection/protocol`; `M=analysis/parallel-aa-receiver/usb-helper/AndroidManifest.xml`.

**1. Files inspected**

- `PROJECT-RULES.md`, `AGENTS.md`, `analysis/agent-reviews/todo-tests-20261103/CODEX-FINAL.md`.
- All 17 candidate overlay files, their baseline counterparts, manifests and build metadata.
- Baseline input, overlay, microphone, night-mode and sensor implementations; current `VideoDecoder.java`.
- T12 reconnect sources, T21 audio sources, four host-test sources and saved outputs.
- `R/tools/Check-Capabilities.ps1`, `R/tools/Add-Phone.ps1`.

**2. Files changed**

None.

**3. Commands run**

Local inspection using `Get-Content`, `Get-ChildItem`, `rg`, `Select-String`, `Select-Object`, `node -e`, and Node REPL filesystem reads. In-memory line diffs and SHA-256 comparisons. `python -B -c` failed because the Python launcher was unavailable.

No device, ADB, build, Git, network or delegation actions were performed. Neither reviewed script was executed.

**4. Tests run and results**

| Check | Result |
|---|---|
| Baseline manifest hashes/absence declarations | PASS 27/27 |
| Candidate overlay hashes against manifests | PASS 17/17 |
| Available baseline/overlay sources against build-record hashes | PASS 80/80 |
| Preservation recheck | PASS: 76 files, zero hash changes |
| Saved host-test outputs, inspected only | T37: 5; T38: 6; T41: 11; T43: 24 checks reported PASS |
| Android/native execution | Not performed; runtime results **UNKNOWN** |

**5. Findings and verdicts**

“READY” means suitable for the scoped experiment, not authorization for a live action.

| Candidate/tool | Assessment | Verdict |
|---|---|---|
| T37-frame-rate | OK | READY FOR CAR TEST |
| T38-settings | SHOULD-FIX: inaccurate DPI reporting; nonblocking | READY FOR CAR TEST |
| T39-media-source | BLOCKER: unrestricted remote transport controls | NOT READY |
| T41-multi-phone | BLOCKER: unauthenticated persistent phone authorization | NOT READY |
| T43-self-recovery | SHOULD-FIX: advertised freeze recovery absent; cleanup inconsistency | NOT READY |
| Check-Capabilities | OK: target reads only; writes local results | READY FOR CAR TEST |
| Add-Phone | OK command scope; inherits T41 blocker | NOT READY with T41 |

**6. Primary evidence for each finding**

**T37 — OK.** `rendered()` is on the decoder’s per-output-frame path: `analysis/parallel-aa-receiver/src/com/rdx/fullscreen/projection/VideoDecoder.java:79`; its worker starts at `:29`. The candidate adds a clock read and primitive counter arithmetic per frame, with string construction/logging only when the 10-second window closes (`C37/H/FrameRate.java:5`, `:11–19`; `C37/H/AaSessionService.java:594–595`). This is not per-frame logging or allocation. The occasional synchronous log still runs on the decoder thread; its target latency is **UNKNOWN**. The metric counts released decoder outputs, not confirmed display presentations (`VideoDecoder.java:79`).

**T38 — SHOULD-FIX, nonblocking.** Negotiation receives the chosen layout DPI, but the selection callback always reports `229` (`C38/P/VideoSink.java:29`, `:45`). Store and report the effective value. This currently affects evidence/logging: the session logs that callback DPI, while geometry uses dimensions only (`C38/H/AaSessionService.java:528–536`).

Changing this argument preserves physical DPI, resolution, margins, codec and fallback configuration (`C38/P/VideoSink.java:25–32`); touchpad registration remains unchanged (`C38/H/AaSessionService.java:304–308`). Thus no source-level geometry mismatch was found. Actual phone acceptance of `180`/`280` is **UNKNOWN**.

The activity is exported (`C38/M:15–20`), so another app can launch it. However, its implementation consumes no intent-supplied setting values; changes require button callbacks (`C38/H/SettingsActivity.java:21–56`). Preferences are private and DPI values are constrained (`C38/H/AppSettings.java:11–24`). No new direct external settings-write API was found.

**T39 — BLOCKER.** The exported browser service has no permission restriction (`C39/M:27–30`). `onGetRoot()` accepts every client and publishes the session token (`C39/H/AaMediaSourceService.java:38`, `:48–50`). A third-party browser client can consequently obtain transport controls and inject next/previous into an active AA session (`:28–29`, `:42–44`; `C39/H/AaSessionService.java:82–87`). Restrict clients before returning a root/token.

**T39 — SHOULD-FIX.** The media session declares PLAYING and becomes active regardless of AA state; play/pause callbacks do nothing (`C39/H/AaMediaSourceService.java:30–37`). Tie its active/playback state to the actual AA session so an idle browser connection does not leave a misleading media-button target.

The static reference is volatile, established on creation and cleared on destruction; forwarding posts to the session handler and checks `running` (`C39/H/AaSessionService.java:74–87`, `:679`; baseline-equivalent key guard at candidate `:203–207`). No direct cross-thread JNI call or permanent static-reference leak was identified.

The new service requests no Android audio focus, but Honda source selection/routing remains **UNKNOWN**. The existing console path remains present and consumes recognized media keys (`B/H/AaOverlayService.java:228–244`; `B/H/InputEvents.java:44–63`). There is no cross-path deduplication with browser callbacks; whether Honda delivers both paths, causing double skips, is **UNKNOWN**.

**T41 — BLOCKER.** Yes, a third-party app can add/remove phones. `UsbHelperService` is exported without a permission (`B/M:24`). The new command branch validates the serial and existence of a main phone, then commits authorization without checking the caller or obtaining operator confirmation (`C41/H/UsbHelperService.java:137–149`). A caller can persist an additional allowed phone while the helper runs, bypassing the script’s confirmation.

**T41 — SHOULD-FIX.** Reconfiguring the main phone preserves previously authorized extras: configuration writes only `phoneSerial`, then reloads `extraSerials` (`C41/H/UsbHelperService.java:127–134`, `:216–218`). Clear or explicitly reconfirm extras when replacing the main-phone policy.

With no extras, main-phone and legacy acceptance remain unchanged (`C41/H/HondaPhonePolicy.java:13–18`, `:58–65`). The new policy does not verify Honda’s per-phone Disabled/Never setting; its own comment makes that an operator prerequisite (`:4–6`).

**T43 — port completeness OK.** Its helper and policy are byte-identical to T12:
- `UsbHelperService.java`: SHA-256 `64AF18EB418ED3C3CF602EA84E236A684846FA546F55F8A5E6DFBA8F9D79BE93`.
- `ReconnectPolicy.java`: SHA-256 `F36992B8D9C7CCF60579FD20A99B9AC9BF2D7E3599F9554ABDCE077177B51A7F`.

The current mic teardown guard is preserved (`C43/H/AaSessionService.java:645–648`), as is the night watcher stop (`:642`). T21 guidance draining/focus handling is preserved; T43’s `AudioSink` differs from T21 only by adding `workerStopped()` (`C43/P/AudioSink.java:100–104`, `:154–219`). The session retains internal duck suppression (`C43/H/AaSessionService.java:336–343`).

**T43 — SHOULD-FIX.** `liveGeneration` is set before overlay/protocol startup (`C43/H/AaSessionService.java:112–121`). The watchdog immediately returns while that value matches, before evaluating startup expiry (`C43/H/UsbHelperService.java:529–536`). A stalled startup or frozen session that retains its generation therefore cannot be recovered by this watchdog. Recovery handles reported session termination; narrow the frozen-session claim in `R/builds/T43-self-recovery/test.json` or implement the missing health detection.

**T43 — SHOULD-FIX, inherited from T12.** After an audio worker fails its stop check, teardown still destroys remaining native children/receiver and prints “released cleanly” (`C43/H/AaSessionService.java:649–659`). `AudioSink.destroy()` also calls native shutdown after a failed join (`C43/P/AudioSink.java:106–115`). Reconnect correctly receives `clean=false`, but the retention contract and log are inconsistent. An actual JNI crash from this path is **UNKNOWN**.

**Scripts — confirmed scope.** Check-Capabilities issues only target queries (`R/tools/Check-Capabilities.ps1:14–28`); it creates/writes local output (`:11`, `:28`, `:43`). Add-Phone validates the serial, requires YES, and contains exactly one external invocation: explicit `am startservice` to `.UsbHelperService`, selecting ADD or REMOVE (`R/tools/Add-Phone.ps1:9–12`). Neither script explicitly checks each command’s exit status before presenting results/success (`Check-Capabilities.ps1:28–46`; `Add-Phone.ps1:12–13`): a diagnostic SHOULD-FIX.

**7. Assumptions**

Candidate directories are overlays on the supplied baseline. Readiness assessments cover these changes and requested tools; they do not carry forward unrelated historical tooling verdicts.

**8. Unresolved uncertainties**

Live playback latency, DPI negotiation, Honda audio-source discovery/routing, duplicate button delivery and native-call termination remain **UNKNOWN**. APK contents were not independently decompiled or runtime-tested.

**9. Exact diff summary**

No review changes. Candidate overlays contain respectively 2/6/3/2/4 files, including 1/2/1/0/1 additions; every overlay file was compared with its baseline counterpart or verified absent baseline.

**10. Preservation checks performed**

All 76 captured file hashes remained unchanged. Baseline and candidate manifest checks passed as recorded above. No credential/private-test material was opened. Frozen artifacts were not rebuilt, modified or rehashed. Whole-workspace equality is **UNKNOWN**.