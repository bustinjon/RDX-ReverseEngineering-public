1. **Files inspected:** `PROJECT-RULES.md`, `AGENTS.md`; T140/T150 Java/XML comparisons; detailed inspection of the five changed Java files, `HomeToggle.java`, `VideoSink.java`, `VideoDecoder.java`, and manifest.
2. **Files changed:** none.
3. **Commands run:** `Get-Content`, `rg`, `Get-ChildItem`, `Get-FileHash`, `Compare-Object`, `fc.exe /n`. Initial Python comparison failed; PowerShell relative-path comparison failed; subsequent hash comparisons and `fc.exe` succeeded.
4. **Tests run and results:** no runtime tests or builds; final preservation comparison **PASS: all five changed-source hashes matched the review snapshot**.
5. **Findings — verdict: NOT READY.**

   - **1a — BLOCKER, false triggers:** Any legitimate frame pause ≥8 seconds remains indistinguishable from failure unless minimized/native-focus flags suppress it. Static map, screen-off, calls, reverse camera and Honda-overlay behavior are **UNKNOWN**; there are no dedicated guards. Nominal detection is 8–10 seconds, longer when the handler is delayed.
   - **1b — SHOULD-FIX, focus return/recovery:** Native focus returning to AA does not reset the clock; after a long handoff, the next tick can immediately minimize AA before its first resumed frame. `requestVideo()` requests unsolicited AA video focus, before the posted minimization executes; interference with calls/camera is **UNKNOWN**.
   - **1c — OK, restore/end:** Explicit overlay restoration resets the clock. Shutdown removes handler callbacks and sets `running=false`; the watchdog also checks `running`. Protection starts only after the first rendered frame.
   - **2a — OK under platform assumptions:** Log copying runs on a worker; UI updates return to the UI thread. App-specific external storage needs no storage permission on standard Android 5.1. Ordinary logcat access is limited to retained records available to the app UID, not comprehensive Honda/system/phone logs.
   - **2b — SHOULD-FIX, reliability:** Repeated taps launch concurrent workers; second-resolution names can collide/truncate. No exit-status/stderr check means failed logcat can report “saved.” No timeout; opening the output file can fail before process cleanup is established.
   - **2c — SHOULD-FIX, growth:** `-d` requests a finite dump, but there is no byte cap. Five-file retention runs only after successful copying, ignores deletion failures and retains partial failed files. Five files is therefore not a guaranteed bound.
   - **3 — SHOULD-FIX, settings fit:** Fifteen items produce eight rows. At 720px screen height the formula gives 59px button minima and 20px text. It uses display height rather than available content height; wrapping status text can enlarge controls, with no scrolling fallback. Actual fit is **UNKNOWN**.

6. **Primary evidence for each finding:** Paths below are relative to `analysis/test-prep/todo-tests-20261103/builds/T150-bundle/source/analysis/parallel-aa-receiver/`. `H` means `usb-helper/source/com/rdx/fullscreen/usbhelper/`; `P` means `src/com/google/android/projection/protocol/`.

   - **1a:** `H/InputEvents.java:78–80`; `H/AaSessionService.java:1121–1133`; default enabled/schema 150: `H/AppSettings.java:30–43`; playback start/stop callbacks are empty: `P/VideoSink.java:44–45`.
   - **1b:** `H/AaSessionService.java:1066–1073,1129–1131`; posted minimization/Home: `H/AaOverlayService.java:247–253`; unsolicited focus request: `P/VideoSink.java:37`.
   - **1c:** `H/AaSessionService.java:1080,1108–1111,1123,1144–1149`; restore caller: `H/AaOverlayService.java:935–937`.
   - **2a:** `H/SettingsActivity.java:43–46,52–59,69–70`; package/SDK/permissions: `usb-helper/AndroidManifest.xml:1–18`. Android permission/UID behavior is assumed below, not verified against Honda firmware.
   - **2b/2c:** `H/SettingsActivity.java:40–70,234`; omitted stuck-protection setting in saved snapshot description: `H/AppSettings.java:126–130`.
   - **3:** Fifteen controls: `H/SettingsActivity.java:218–249`; sizing/columns: `:276–292`; variable header: `:214–216`; minimum-height controls: `:282,310–315`.

7. **Assumptions:** Standard API22 app-specific storage and logcat UID restrictions; 720px is the illustrative layout height, matching `H/AaOverlayService.java:54`.
8. **Unresolved uncertainties:** Actual frame cadence/pause signaling in all requested scenarios; Honda focus consequences, storage availability/log visibility, and rendered settings fit.
9. **Exact diff summary:** no review edits. T150/T140 Java/XML hash comparison identified only `AaOverlayService`, `AaSessionService`, `AppSettings`, `InputEvents`, and `SettingsActivity` as different.
10. **Preservation checks:** Five-file SHA-256 recheck passed. No Git, network, builds, device access, credential/private-material reads, or frozen-artifact operations performed.