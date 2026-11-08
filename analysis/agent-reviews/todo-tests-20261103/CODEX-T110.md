**Verdict: NOT READY. Item 3 contains a BLOCKER.**

1. **Files inspected**
   Rules first; all `CODEX-T100*.md`, reconciliation, T100 results; T110 changes against T100/baseline, supporting sources, BundleTests, VISIT, saved logs and preservation records.
   Aliases below:
   `B=analysis/test-prep/todo-tests-20261103`; `T=B/builds/T110-bundle`.
   `H=T/source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper`.
   `P=T/source/analysis/parallel-aa-receiver/src/com/google/android/projection/protocol`.
   `D=T/source/analysis/parallel-aa-receiver/src/com/rdx/fullscreen/projection/VideoDecoder.java`.
   `F=decompiled/Framework/sources/android/media`; `W=decompiled/Services/sources/com/android/server/wm/WindowState.java`.
   `L=analysis/test-prep/runs/helper_20261108T030131_9682eddb8c804a3fbc03092dd014e5cd/longdrive-evidence/rdx_ef060e5861d6451ebcbd6c3be847aee2/capture.log`.
   `R=C:/Users/REDACTED/AppData/Local/Temp/rdx-t100/vrsvc/sources/com/honda/speechrecognizer/service/AbstractSpeechRecognizerService.java`.

2. **Files changed:** none.

3. **Commands run**
   Read-only `Get-Content`, `Get-ChildItem`, `rg`, and `node -e` for numbered reads, in-memory comparisons, SHA-256 and timeout arithmetic. No Git, network, builds or device commands.

4. **Tests run and results**
   No executable suites run. Saved `T/host-test-output.txt:1-9` reports **148 bundle checks plus eight passing feature suites**.
   Comparison: **eight changed source files**; T110 adds the decoder snapshot to the overlay. Candidate, saved-baseline and working-baseline checks each matched **36/36** entries.
   `T/BundleTests.java:128-143` tests night helpers, retry-count constant and TalkGate; it does not exercise codec timing or Android focus cleanup.

5. **Findings**
   - **1 — Home: OK for inspected control flow.** Visible AA minimizes and launches Home; minimized AA launches Home again. No recursive key injection found. Actual duplicate launches during framework/window transitions remain **UNKNOWN**.
   - **2 — Decoder: SHOULD-FIX.** Retries preserve FIFO submission but delay acknowledgments substantially. Picture recovery ignores minimization/native focus and sends a focus request whose ability to obtain a fresh keyframe is **UNKNOWN**.
   - **3 — Talk: BLOCKER.** Shutdown can cancel the only scheduled abandonment of an already-granted focus grab. The grab also perturbs our sinks; their existing internal-duck suppression does not cover this transient loss.
   - **4 — Night: SHOULD-FIX.** Null/native lifetime handling is sound, but reports can race across threads; canceled or orphan releases can cycle colours. Honda’s independent long-seek handling can also affect playback.
   - **5 — USB: SHOULD-FIX.** Main-phone policy remains intact, but “every device” is unsupported by the enumeration paths. Null serials disappear; deduplication remembers only the last serial.
   - **6 — Migration/defaults/VISIT: SHOULD-FIX.** Schema/default promotion and feature retirement agree with the request. Reset omits night override, and VISIT’s Talk-off instruction needs a reconnect.

6. **Primary evidence for each finding**
   - **1:** `H/AaOverlayService.java:233-266` launches an activity, never injects Home; `H/HomeToggle.java:18-22` makes minimization idempotent. Accessibility still returns false (`H/PermissionClickService.java:309-318`).
   - Honda suppresses Home for type 2010 (`decompiled/Policy/sources/com/android/internal/policy/impl/PhoneWindowManager.java:2173-2187`). Alpha and focus flags do not enter `W:526-528`; visible type 2010 is recognized at `W:1272-1288`. These support the minimized-window rationale, although the policy decompilation contains malformed null conditions.
   - Driving permission is checked against the **resolved target package** (`decompiled/Services/sources/com/android/server/am/ActivityStackSupervisor.java:646-648`; `AutoSSMonitor.java:55-62`). Saved launcher evidence names HomeActivity and grants that permission (`analysis/agent-reviews/honda-launcher-tiles/pull-20261105-212243/dumpsys-package.txt:7,277`). Current runtime resolution is **UNKNOWN**.

   - **2:** `D:59-65` requests up to **6 seconds for config**, **360 ms for a frame**; combined requested waits can reach **6.36 seconds**, excluding other work. Acknowledgment follows processing (`D:93-111`), so the 16-frame protocol window can pause (`P/VideoSink.java:29`). FIFO queueing provides no new frame-reordering path (`D:11,32,93`).
   - `H/AaSessionService.java:874-881` checks running/selected and enforces five seconds between requests on its handler, but checks neither `nativeFocus` nor minimization. Contrast the guarded restore retry at `:967-969`. `P/VideoSink.java:37` sends unsolicited focus **1**, not an explicit keyframe request.
   - Startup drops are real (`L:1774-1775,4112-4113`). Config-deferred drops use different messages (`D:53-55,101-103`) and therefore bypass `AaSessionService.java:841` recovery.

   - **3:** Granted grab abandonment exists only in the delayed callback (`H/AaSessionService.java:225-232`). `TalkBridge.stop()` unregisters/unbinds without abandoning it (`:190-195`); shutdown then removes every callback (`:998-1000`). Unplug within that interval therefore removes the release path. **Abandon explicitly during stop before canceling callbacks.**
   - Honda propagates focus loss to existing stack clients (`F/MediaFocusControl.java:494-498,826-828`). Our sinks pause on transient loss (`P/AudioSink.java:58-66`); only guidance-originated **-3** is suppressed (`H/AaSessionService.java:530-538`). Grab-induced **-2** reaches the phone.
   - Honda abort requires `mDialogStarted` (`R:464-470`); Honda requests stream **9**, whereas the grab requests music (`R:374`; session `:226`). Honda maintains sink-dependent stacks (`F/MediaFocusControl.java:410-431`): successful music focus alone does **not** prove Honda voice aborted.
   - Calls are checked only before posting (`session :219-232`). TalkGate suppresses immediate repetition but rearms after NOT_ACTIVE/800 ms or 30 seconds (`H/InputEvents.java:57-64`); native restart loops remain **UNKNOWN**. Historical dismissal failure is confirmed at `L:7320-7321`.

   - **4:** Sink initialization precedes reporting (`session :523-525,597-604`); null checks and synchronized sensor report/destroy protect native lifetime (`:124-128`; `P/SensorSource.java:85-89,110-114`).
   - Watcher reports run on its thread, override reports on the handler (`B/baseline-source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/NightModeWatcher.java:42,66-69`; session `:134-137,600-601`). A report can sample the old override, be delayed, then overwrite a newer report. Serialize sampling and sending. A failed startup override also lacks independent retry if the car source is unavailable.
   - `H/AaOverlayService.java:446-447` accepts `media==0` without checking cancellation/ownership; that return includes ignored releases (`H/InputEvents.java:99-106`). Normal holds correctly avoid a skip.
   - Honda starts long-seek after 500 ms and sends **Play** on release (`decompiled/SystemUI/sources/com/android/systemui/statusbar/auto/SeekKeyHandler.java:164-170`). Hackura advertises Play and forwards it (`H/AaMediaSourceService.java:109,170-171`), so changing colours can resume paused playback.

   - **5:** Toggle actions update extras only; configured main identity remains separate (`H/UsbHelperService.java:167-177`; `H/SettingsActivity.java:189`). The four-extra cap remains (`H/HondaPhonePolicy.java:9,73`).
   - Polling calls `policyAllows` only for AOAP devices, which `rememberDevice` skips; raw enumeration does not call it (`UsbHelperService.java:347-359,777`). Thus arbitrary already-connected devices are not recorded by polling. Null serials are skipped, and `lastRemembered` is set before unchecked commit (`:778-782`): alternating observations can write repeatedly, while a failed same-serial write is suppressed.

   - **6:** Schema 110 resets options on/tests off and removes strip scroll (`H/AppSettings.java:28-40,56-62`); cursor timeout/removal changes appear at `AaOverlayService.java:887,1052-1055`.
   - `AppSettings.java:100-105` leaves `night_override` unchanged on reset. VISIT says turn Talk off (`B/VISIT.md:46`), but session flags refresh only at START (`H/AaSessionService.java:293`). VISIT’s “every device” and fresh-picture claims (`:9,12`) need the qualifications above.

7. **Assumptions:** Supplied Honda decompilation represents the target; omitted overlay paths use the saved baseline.

8. **Unresolved uncertainties:** Actual keyframe response, focus-stack routing, abort completion, duplicate Home launches, report ordering and call-transition effects are **UNKNOWN** live.

9. **Exact diff summary:** none; no files changed.

10. **Preservation checks performed**
    All four frozen anchors, both receiver DEX copies and readiness wrapper/core/schema matched: **8/8**.
    T110 APK SHA-256 matched its build record: `2A0AFA1D55605CCB96E66D1DDC6EE2E731CB7B9DD581C196ED5C0E3936E62837`.
    No writes, credential/private-test reads, guard changes, milestone actions, builds, Git, network or device access.