**Verdict: READY FOR CAR TEST for the parked VISIT.md checks. No confirmed BLOCKER. PTT delivery and Honda voice interaction remain UNKNOWN.**

1. **Files inspected**

   Path abbreviations:
   - `B` = `analysis/test-prep/todo-tests-20261103/`
   - `H` = `B/builds/T90-bundle/source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/`
   - `P` = T90’s corresponding `source/com/google/android/projection/protocol/`
   - `S` = `decompiled/AndroidAuto-current/sources/`
   - `V` = the supplied scratchpad; `VR` = `V/vrsvc/sources/com/honda/speechrecognizer/service/AbstractVrInputHandlerService.java`
   - `L38` = `analysis/test-prep/runs/helper_20261106T203838_b0ea7f0e53ba4bd9b4981c10d4415201/longdrive-evidence/rdx_0d06e15fa8f9401b9a346b8d9aca3251/capture.log`
   - `L07` = `analysis/test-prep/runs/helper_20261106T211007_2713139761294df49ff7957de59d71ac/longdrive-evidence/rdx_a2e22a6a73944845bc463fd981510f85/capture.log`

   Read PROJECT-RULES.md and AGENTS.md first; both T80 reviews, T80 RESULT.md, T80/T90 overlays and manifests, shared baseline hashes, T90 BundleTests/phone-policy tests/test.json/saved test and build records, VISIT.md, cited logs, stock Java/smali/JNI references, Honda voice references, and preservation metadata.

2. **Files changed:** none.

3. **Commands run**

   Read-only `Get-Content`, `rg`, `Get-ChildItem`, `Get-Item`, `Get-FileHash`, and in-memory `node -e` comparisons, numbered reads and SHA-256 checks. Corrected an initial per-bundle baseline lookup to the shared `B/baseline-source/`. No Git, network, build, device or credential operations.

4. **Tests run and results**

   - No host suites executed or compilation performed.
   - Static comparison: **10 changed source files**, no T80 overlay paths missing from T90.
   - SHA-256 verification: T80 and T90 each **35/35 candidate**, **35/35 shared saved-baseline**, **35/35 working-baseline** entries matched.
   - Historical output reports **158 bundle checks**, plus eight feature suites passing (`B/builds/T90-bundle/host-test-output.txt:1-9`).
   - Native long-key declaration and export matched the supplied stock evidence.

5. **Findings**

   | Item | Status | Finding |
   |---|---|---|
   | 1. Extras/main-phone policy | **OK** | Successful configuration preserves extras only for the exact saved main serial. LEGACY clears them; legacy raw switching still requires the existing stop condition. |
   | 2. Scroll clamp | **OK** | Clamp precedes the edge-room rule and applies to every re-grab. Immediate MOVE and release paths remain. New tests cover both directions and reported anchor heights. |
   | 3. PTT | **SHOULD-FIX** | ABI, threading and receiver lifecycle are sound by inspection. Documentation overstates delivery and stock-equivalent behavior. Key 84 forwarding also operates with T93 off. |
   | 4. Dash refresh | **OK** | Main-thread confinement protects `lastTrack`; one pending refresh is maintained, destruction removes it, and inactive/off callbacks stop rescheduling. |
   | 5. Migration/nav default | **OK** | Schema 90 enables NAV_VOLUME and disables new test switches. This agrees with the recorded stream-10 pass; Gemini failure occurred with navigation volume both on and off. |
   | 6. Checklist/test.json | **OK** | Both place Add-Phone after Start while the laptop remains connected, and Collect after all tests. No post-Collect test is prescribed. |

6. **Primary evidence for each finding**

   **1 — Policy:** `H/HondaPhonePolicy.java:26-27` requires non-null exact equality. `H/UsbHelperService.java:136-160` validates configuration, assigns null for LEGACY, removes extras when equality fails, checks commit success and reloads policy. Invalid or active-service configuration is rejected without changing the configured phone.
   
   Extras are ignored without a main phone (`HondaPhonePolicy.java:18`); cooperative acceptance remains main-or-explicit-extra (`:63-77`). Raw switching retains `rawPolicyAllows` (`UsbHelperService.java:716-724`); session identity remains checked (`:544`). No additional policy weakening found in this delta. Tests cover same/different/null cases (`B/builds/T90-bundle/BundleTests.java:119-124`). `L07:927,1118` records configuration followed by rejection of dongle serial `DONGLE_SERIAL`; those two records alone do not prove the preceding saved-list contents.

   **2 — Scroll:** `H/ScrollStrip.java:97-105` clamps to the middle half, then moves insufficient-room starts to the centre, then emits DOWN immediately followed by a 36-pixel MOVE. Every edge re-grab calls this same function (`:81-86`); `leave()` releases (`:109-113`).
   
   Overlay lift/cancel, minimize and teardown release paths remain (`H/AaOverlayService.java:524-525,816,949-957,989`). Existing tests cover threshold, release and repeated grabs (`BundleTests.java:56-105`); new cases cover anchors 0/46/62/120/600/700 in both directions at 1920×720 (`:125-134`). Reported car anchors appear at `L38:4895,6129`. Actual tap rejection and scrolling success remain live-test questions.

   **3 — ABI/thread/lifecycle:** T90 declares `(long,int,int)->int` and uses elapsed-realtime nanoseconds (`P/InputSource.java:47,113-115`). Stock smali declares `nativeSendKeyLongEvent(JII)I` (`decompiled/AndroidAuto-current-smali-full/com/google/android/projection/protocol/InputSource.smali:161,972`); JNI export and `reportKeyLongPress` symbols appear at `analysis/libautoreceiver_jni.so.strings.txt:282-283`.
   
   Stock’s chain ends in long key 84 (`S/com/honda/androidauto/projection/sink/service/GalService.java:1969-1970`, `ui/ProjectionActivity.java:1171-1175`); key translation is identity (`S/com/google/android/projection/protocol/InputSource.java:81-82`).
   
   Sending is posted to the service handler and rechecks running/input availability (`H/AaSessionService.java:132-140`); initialization is posted to that handler (`:251-255`), and shutdown clears callbacks before destroying input (`:837-879`).
   
   Registration follows successful overlay attachment, excludes test mode, and unregistration occurs on removal/destruction (`H/AaOverlayService.java:564-587,988-999,1041-1044`). VIDEO recreation removes the previous registration first (`:326-334`). Minimizing retains the receiver for the continuing session.

   **3 — Honda interaction/UNKNOWN:** Receiver code logs and conditionally queues the long event; it never aborts or changes broadcast results (`H/AaOverlayService.java:124-131`). Priority 10 exceeds Honda’s priorities 5 and 1 (`:584`; `VR:375-383`). Honda’s registration permission constrains senders; it does not establish sender-side recipient restrictions. Third-party delivery is **UNKNOWN**.
   
   Honda’s long receiver dismisses its focused voice provider (`VR:141-155`); stock AA additionally requests VR focus and checks recognition state before starting (`S/com/honda/androidauto/projection/sink/service/GalVrProviderService.java:104-115`). T90 does not reproduce that coordination. Short-press interference, ordering/focus races and duplicate activation are **UNKNOWN**.
   
   Key 84 is always registered (`H/InputEvents.java:20`; `P/InputSource.java:65,77`) and console dispatch has no T93 gate (`H/AaOverlayService.java:412-420`; `AaSessionService.java:267-268`). Thus delivered console key 84 forwards ordinary DOWN/UP even with T93 off. Qualify `B/VISIT.md:10` accordingly; “logs every press” and “opens” are not established. Tests check key membership/action text, not delivery or lifecycle (`BundleTests.java:135-138`).

   **4 — Dash:** `H/AaMediaSourceService.java:32,38-50,99-112` confines metadata assignment and refresh execution to main, with a scheduling latch and live/switch guards. Stop clears `lastTrack` (`:57-64`); destruction removes refresh callbacks and nulls the released session (`:221-224`). Other queued metadata callbacks return when session is null (`:100`). If Honda retains a bind after AA stops, a pending refresh can wake once and return; it cannot perpetuate the timer. Refresh/lifecycle behavior lacks a dedicated host test in BundleTests.

   **5 — Migration:** `H/AppSettings.java:28-38,47-59,109,119-122` establishes schema/defaults/snapshot behavior. Migration resets all options ON and test switches OFF, including prior user choices; this is explicit in the migration.
   
   `L38:10816,11005` records navigation stream selection and `AUDIO_TRACK_READY ... stream=10`; `B/builds/T80-bundle/RESULT.md:13-14` records the pass and Gemini failure with both settings. Gemini’s cause remains **UNKNOWN**. BundleTests checks defaults/options (`:16-18`), not persisted migration.

   **6 — Procedure:** `B/VISIT.md:19-23` explicitly puts Add-Phone after READY; `B/builds/T90-bundle/test.json:66` follows VISIT’s sequence. Cleanup instructions agree (`test.json:67`; `VISIT.md:56-61`). VISIT explicitly prohibits another test after Collect.

7. **Assumptions**

   The review concerns the supplied overlay and parked checklist. Omitted source paths use the shared baseline. Historical test/results files are records, not executions performed during this review.

8. **Unresolved uncertainties**

   PTT sender restrictions/delivery, Honda voice coexistence, phone interpretation of key 84, dash refresh effectiveness, actual scroll behavior and Gemini failure cause are **UNKNOWN**. Static ABI agreement does not prove native crash freedom.

9. **Exact diff summary:** none; no files changed.

10. **Preservation checks performed**

   `Get-FileHash` matched every PROJECT-RULES anchor:
   - M5: `A22E96490B9557AFF022893A8B8B7A08BB13CEC236E52704CDDAFA90A8EE8F40`
   - M6: `D4DAC2DD8B2AFF1FA7B64BFB32D2A5E889854CCEB4B4A9F7AD5AEF89FB28761F`
   - Both receiver DEX copies: `2FDBC63F2F9D63B764697D311AF89D460AE6B8E14B0FADABA9C9339F7FE7C235`
   - TLS qualifier: `86350131FFC5CBE5766E523AB03AE07D4C9F5EAD78F0570B68255C9A3999FC1F`

   T90 APK matched build-result SHA-256 `A83014F8AFBE198964EE5B0C62A262651B72F4C782FCE523C4E38DF4E766AEFE`. Manifest-listed working paths matched baseline. No writes, device access, milestone actions, builds, Git, network or private-material reads were performed.