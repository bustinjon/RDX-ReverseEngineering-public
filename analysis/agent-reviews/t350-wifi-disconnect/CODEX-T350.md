1. **Files inspected**

   Paths below are relative to `analysis/test-prep/todo-tests-20261103/builds/T350-bundle/` unless stated otherwise.

   - `PROJECT-RULES.md`, `AGENTS.md`.
   - Bundle source under `source/analysis/parallel-aa-receiver/usb-helper/source/`:
     - `S` = `com/rdx/fullscreen/usbhelper/AaSessionService.java`
     - `I` = `com/rdx/fullscreen/usbhelper/InputEvents.java`
     - `W` = `com/rdx/fullscreen/usbhelper/WirelessProbeService.java`
     - `U` = `com/rdx/fullscreen/usbhelper/UsbHelperService.java`
     - `R` = `com/rdx/fullscreen/usbhelper/ReconnectPolicy.java`
     - `A` = `com/rdx/fullscreen/usbhelper/AppSettings.java`
     - `AaOverlayService.java`, `com/google/android/projection/protocol/GalReceiver.java`.
   - Bundled `VideoDecoder.java`, `AudioSink.java`; manifest; `BundleTests.java`; saved host-test output/compile output; `test.json`; `build-report.json`.
   - T340 counterparts of the four changed files; targeted searches of canonical `AaSessionService.java` and `InputEvents.java`.
   - Historical T280/T290/T300 `RESULT.md` files and the two stall logs cited below.
   - `PROJECT-INTEGRITY.json`, `hashes.json`; eight files hashed for preservation.

2. **Files changed**

   None.

3. **Commands run**

   - Read-only `Get-Content`, numbered source excerpts, `rg -n`, `rg --files`, `Select-String`, and file listings.
   - Four `git diff --no-index` comparisons between T340 and T350.
   - `git status --short`; final targeted status check.
   - `Get-FileHash -Algorithm SHA256`, repeated for preservation.
   - PowerShell watchdog-phase enumeration reported below.
   - An attempted Python analysis failed because the WindowsApps `python.exe` alias was inaccessible. Two searches used nonexistent source locations; subsequent searches found the relevant files.

   No build or device command was executed.

4. **Tests run and results**

   No Java or Android tests were executed. Existing `host-test-output.txt:10` reports **285 bundle checks passed**, but the eight new checks exercise only the predicate (`BundleTests.java:48–57`).

   Read-only arithmetic replay of the 8s threshold and 2s check interval produced:

   | Recorded recoverable gap | Check phases causing teardown before recovery |
   |---|---:|
   | 8,040ms | 40/2,000 |
   | 8,549ms | 549/2,000 |
   | 10,896ms | 2,000/2,000 |

   This assumes the watchdog is armed and the handler runs on schedule; it is not an Android integration test.

5. **Findings**

   **P1 — An 8s silence threshold misclassifies recorded recoverable stalls as disconnects.**

   The historical logs contain an **8,549ms header wait**, followed by a **10,896ms body wait**, queued ping replies, and resumed video in the same session. T350 would abort during the latter wait under every nominal watchdog phase.

   Additionally, `lastGalMs` measures completed headers, not continuing byte reception. A slow body or blocked protocol delivery can age it despite a connected transport. The conclusion logged as “phone disconnected” is stronger than the available evidence.

   **P1 — Disconnect protection never arms before the first rendered frame.**

   The initial watchdog post exists only inside `rendered()`’s `!firstFrame` branch. A TCP connection that becomes silent during handshake or before successful rendering has no scheduled `stuckWatch`. The blocking TCP reader has no session read timeout here. That path has no demonstrated 8–10s escape.

   **P2 — Automatic Wi-Fi reconnect is conditional; REARM and the restart budget do not govern it.**

   TCP sessions set `generation = 0` and bypass `ReconnectPolicy`. Normal everyday wireless leaves the TCP listener available, allowing a phone-initiated retry, but teardown does not actively reconnect the phone.

   More specifically, releasing the held Bluetooth bootstrap channel through `WirelessProbeService.sessionEnded()` is gated on `WIRELESS_TEST`. That switch defaults off. In everyday mode, a still-live Bluetooth channel can remain blocked in the existing bootstrap read loop; its start request is sent only when bootstrap begins. Whether the phone independently retries TCP after returning is **UNKNOWN**.

   **P2 — 8–10s describes nominal detection, not guaranteed return to Honda’s screen.**

   `abortIo()` synchronously closes transport and calls native preparation before posting shutdown. Shutdown then joins workers and stops decoder/audio resources **before** requesting overlay removal. Three transport-thread joins alone allow six additional seconds; decoder stop allows another two. Native preparation has no Java-side deadline.

   **P2 — Duplicate teardown is possible; the guard is not permanent idempotence.**

   Reader/writer failures and the watchdog can pass their `running` checks concurrently. `byeBye()` calls `abortIo()` without that check. Each `abortIo()` can post shutdown independently.

   Shutdown removes queued callbacks, but later resets `stopping` to false. An abort thread posting after callback removal can therefore leave a second shutdown runnable that executes after the first finishes. Duplicate notifications/overlay-stop requests are source-supported possibilities; an observed crash or reconnect failure from this race is **UNKNOWN**.

6. **Primary evidence for each finding**

   - **Recoverable stall:**  
     `analysis/test-prep/todo-tests-20261103/builds/T300-bundle/headunit-logs-20261110-153805/hackura-20261110-094547-auto-stall-8549ms.txt`
     - `:688`: `T250_READ_GAP ms=8549 hidden=false`
     - `:1102`: `T270_BODY_GAP ms=10896 len=16153`
     - `:1103–1122`: accumulated `GAL ping response` callbacks
     - `:1123`: `T280_FREEZE_END ms=10963`
     - `:1124`: resumed `VIDEO_FPS`
     
     These are historical T290-era records copied into the T300 collection, not a T350 run. The independent T280 log  
     `analysis/test-prep/todo-tests-20261103/archive/builds/T280-bundle/headunit-logs-20261109-214205/hackura-20261109-214051-auto-stall-8040ms.txt:588` records an 8,040ms header wait; `:611` records recovery.

   - **Header-only timestamp:** `S:1279–1281` updates after the four-byte header; `S:1290–1301` reads the body and delivers it without refreshing that timestamp. `I:103–105` applies the unconditional 8s age test.

   - **Missing startup coverage:** [S:1622](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/test-prep/todo-tests-20261103/builds/T350-bundle/source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/AaSessionService.java:1622) is the sole initial watchdog post. `S:72–81` implements blocking TCP reads; `S:1272` seeds the timestamp before any inbound header.

   - **Reconnect:** `S:141–142` sets TCP generation zero/operator-stop false. `U:707–718` retires self-recovery; `U:756` excludes reconciliation when it is off. `S:1665` gates wireless end notification on the developer test. `A:38`, `A:143–144` establish that test’s default-off state. `W:577–578` releases Bluetooth on notification; `W:831` sends the bootstrap start request; `W:834–856` thereafter reads/answers messages. `W:741–763` continues accepting new TCP connections.

   - **Delayed screen return:** `S:1399–1405`, `S:1680–1692`, `S:1719–1722`; bundled `VideoDecoder.java:121–125`. Actual overlay removal occurs in `AaOverlayService.java:385–387`.

   - **Duplicate teardown:** `S:1306–1308`, `S:1381–1383`, `S:1494–1495`, `S:1663`, `S:1669`, `S:1730`.

   Other requested checks:

   | Check | Result and evidence |
   |---|---|
   | Every GAL channel refreshes the timestamp | **Yes, every completed header**, without channel filtering (`S:1279–1285`). Not every received byte. |
   | Healthy idle heartbeat | Car initiates pings approximately every second (`S:1388–1395`); inbound replies traverse the common reader. Historical replies appear approximately 1Hz at the stall log’s `:419–446`. Reply timing is not guaranteed. |
   | Watchdog continues after frames stop | Yes, once armed: `S:1657` reposts independently of rendering. |
   | Cancellation | `S:1669` removes handler callbacks; `S:1637` stops a late invocation when `running` is false. |
   | Minimized/native-focus/voice exemptions | None in the TCP branch (`S:1639–1649`). These states need continuing GAL traffic to avoid teardown. |
   | Ping-thread failure | Exception logs and ends the ping loop without restarting it (`S:1394–1395`). |
   | Restart-budget exhaustion | **Not applicable to current Wi-Fi admission.** `R:56` would disable on the fourth qualifying end if used; current TCP paths do not use it. |
   | USB/T150 regression | No direct regression found: the USB predicate and action remain unchanged in the T340/T350 diff (`S:1649–1654`; `I:95–97`). Runtime preservation is untested. |

7. **Assumptions**

   - Phase enumeration assumes an armed watchdog, enabled stuck protection, and a runnable handler.
   - Historical stalls demonstrate recoverability, not proof that identical stalls occur with T350’s default scan settings.
   - Existing configuration can disable protection (`S:1639`) or retain previous switch values (`A:62–67`).

8. **Unresolved uncertainties**

   - T350’s actual disconnect-to-Honda timing: **UNKNOWN**.
   - Guaranteed automatic reconnect for the returning phone: **UNKNOWN**.
   - Native preparation blocking/deadlock behavior: **UNKNOWN**. The watchdog path has no evident Java self-join.
   - A false teardown during a completely healthy, purely idle session: **UNKNOWN**. The demonstrated counterexample is a recoverable stalled session.
   - Actual duplicate-shutdown consequences: **UNKNOWN**.

9. **Exact diff summary**

   No review edits. The inspected proposed patch adds the predicate, adds the TCP watchdog branch, changes versionName to `0.9-T350`, and adds eight predicate checks.

10. **Preservation checks performed**

   Repeated SHA-256 checks reported `hashesUnchangedSinceReviewSnapshot=true` for all eight checked files: four changed bundle files and four frozen artifacts.

   All four frozen artifacts matched the complete `PROJECT-RULES.md` anchors. T350 service/input hashes also matched `build-report.json:63` and `:133`. Pre-existing tracked modifications remained listed; none were edited. No key material was opened, no agents were spawned, and no device or milestone action occurred.