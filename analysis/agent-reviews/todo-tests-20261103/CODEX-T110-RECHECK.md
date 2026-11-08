**Verdict: NOT READY. Item 3 introduces a BLOCKER.**

1. **Files inspected:** `PROJECT-RULES.md`, `AGENTS.md`, both T110 review/reconciliation reports, `VISIT.md`, relevant bundle sources, `BundleTests.java`, saved host-test output; supporting Honda decompilation and the capture log referenced by `CODEX-T110.md:11`.
   Aliases: `T=analysis/test-prep/todo-tests-20261103/builds/T110-bundle`; `S=T/source/analysis/parallel-aa-receiver`; `H=S/usb-helper/source/com/rdx/fullscreen/usbhelper`; `P=S/src/com/google/android/projection/protocol`; `F=decompiled/Framework/sources/android/media`.

2. **Files changed:** none.

3. **Commands run:** read-only `Get-Content`, `Get-ChildItem`, `rg`/`rg --files`, and `Select-Object` for source discovery and numbered excerpts. No Git, network, builds or device commands.

4. **Tests run and results:** no executable tests run. Saved `T/host-test-output.txt:1-9` reports 148 bundle checks plus eight passing suites; applicability to these fixes is **UNKNOWN**. `T/BundleTests.java:128-139` does not exercise focus-stack isolation or Play suppression.

5. **Findings:**
   - **1 — Talk: SHOULD-FIX.** Stream 9 targets Honda’s voice focus, conditionally on a granted request and active dialog. Stop-time release is fixed. Our music remaining untouched is **UNKNOWN**: stacks are keyed by sink, with explicit music-stack aliasing.
   - **2 — Decoder: OK for inspected changes.** Config waits total at most 1.2 seconds, frame waits 360 ms, excluding processing/draining. Recovery now covers config drops and respects native focus/minimization.
   - **3 — Night: BLOCKER.** Synchronization is fixed, but every `onPlay()` within 1.5 seconds is discarded—including an intentional knob/wheel resume. Ownership checking also remains incomplete.
   - **4 — USB/reset/VISIT: SHOULD-FIX.** USB commit ordering and qualified wording are fixed; Talk-off reconnect instructions are fixed. Reset saves Auto but does not report it to the active session.

6. **Primary evidence:**
   - **1:** `H/AaSessionService.java:228,239` requests stream 9; `:190-192,241-245` releases during stop; shutdown calls stop before callback removal (`:1010-1012`).
   - Honda requests stream 9 and aborts on loss only while `mDialogStarted`: `C:/Users/REDACTED/AppData/Local/Temp/rdx-t100/vrsvc/sources/com/honda/speechrecognizer/service/AbstractSpeechRecognizerService.java:374,469-470`.
   - Counterexample to isolation: `F/MediaFocusControl.java:415-426` selects by sink and can assign that stack to music; `:429-431` reuses it for stream 3. Loss propagates through the selected stack (`:494-498,826`). Our sinks request music focus and pause on transient loss (`P/AudioSink.java:48,60-64`). This implementation is under Framework, not Services.
   - **2:** `S/src/com/rdx/fullscreen/projection/VideoDecoder.java:59-64,103,111`; `H/AaSessionService.java:853,890-893`. Fresh-keyframe effectiveness remains **UNKNOWN**: `P/VideoSink.java:37` sends video focus.
   - **3:** `H/AaSessionService.java:124-128` synchronizes sampling/reporting. `H/AaMediaSourceService.java:107-111` identifies knob/wheel transport controls, then rejects all Play callbacks inside the window.
   - `H/AaOverlayService.java:450-452` records any fresh key’s down-time, without device/key ownership; `:886` resets media ownership without clearing `nightKeyDown`. A release after that reset can still satisfy the colour-change condition.
   - **4:** `H/UsbHelperService.java:779-781` updates deduplication only after successful commit; `H/AppSettings.java:102` resets night override. `H/SettingsActivity.java:143-148` omits `nightOverrideChanged()`, unlike `:88`; `analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/NightModeWatcher.java:66-69` reports only car-value changes.
   - `analysis/test-prep/todo-tests-20261103/VISIT.md:9,12,43,46` qualifies picture recovery/USB coverage and requires reconnecting after either Talk-switch change.

7. **Assumptions:** supplied Honda decompilation represents the target; unchanged NightModeWatcher supplies the bundle fallback.

8. **Unresolved uncertainties:** live sink mapping, actual Honda abort completion, decoder recovery effectiveness and installed-artifact parity are **UNKNOWN**.

9. **Exact diff summary:** none.

10. **Preservation checks performed:** read-only inspection only; no credential/private-test reads, writes, builds, Git, network, device access or milestone actions. Frozen-artifact hashes were not rechecked.