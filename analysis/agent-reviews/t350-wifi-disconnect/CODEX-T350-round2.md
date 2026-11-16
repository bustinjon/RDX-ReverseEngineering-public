**Verdict: the new timeout passes the recorded stall case, but the full proposition does not hold as stated.** Both AA TCP paths receive the timeout. Global once-only teardown is disproven by the source; healthy-session silence guarantees remain **UNKNOWN**.

1. **Files inspected**

   Citations below use these aliases:

   - **S**: T350 [AaSessionService.java](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/test-prep/todo-tests-20261103/builds/T350-bundle/source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/AaSessionService.java)
   - **I**: T350 [InputEvents.java](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/test-prep/todo-tests-20261103/builds/T350-bundle/source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/InputEvents.java)
   - **W**: T350 [WirelessProbeService.java](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/test-prep/todo-tests-20261103/builds/T350-bundle/source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/WirelessProbeService.java)
   - **O**: T350 [AaOverlayService.java](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/test-prep/todo-tests-20261103/builds/T350-bundle/source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/AaOverlayService.java)
   - **G**: T350 [GalReceiver.java](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/test-prep/todo-tests-20261103/builds/T350-bundle/source/analysis/parallel-aa-receiver/usb-helper/source/com/google/android/projection/protocol/GalReceiver.java)
   - **L**: [recorded 8549 ms stall log](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/test-prep/todo-tests-20261103/builds/T300-bundle/headunit-logs-20261110-153805/hackura-20261110-094547-auto-stall-8549ms.txt)

   Also inspected: `PROJECT-RULES.md`, `AGENTS.md`; T340 counterparts of S/I/manifest; T300 `readLoop`; T350 manifest, `AaMediaSourceService.java`, `AppSettings.java`, `VideoDecoder.java`, `BundleTests.java`, host-test output/compile records; and `CLAUDE-T350-RECONCILE.md`. Hashed all 34 Java/manifest files in each supplied source snapshot.

2. **Files changed**

   None.

3. **Commands run**

   Read-only commands: `Get-Content`, `rg`, `rg --files`, `Get-ChildItem`, `Get-Command`, `git status --short`, scoped `git diff --stat`, three `git diff --no-index` comparisons, and in-memory `node -e` checks for hashes, unchanged code regions, and arithmetic.

   `python -B -c` could not start because the Windows Store executable was inaccessible; Node performed the checks instead. Some searches for dependency files and an initially assumed `BundleTests.java` location returned “file not found”; corrected locations were inspected where available.

   Browsed official Java/Android socket and Handler documentation. Attempts to retrieve historical AOSP implementation sources failed. No builds, device commands, or repository mutations were performed.

4. **Tests run and results**

   In-memory static assertions **PASS**: T340/T350 equality for the USB pipe, writer and ping loops, freeze-recorder region, `shutdown()`, and USB-only `stuckWatch`.

   Source comparison: **34 versus 34 files; exactly three differ**—S, I, and `AndroidManifest.xml`; none removed. Preservation comparison: **PASS**, identical beginning/end hash snapshots.

   No application, socket-runtime, Android, or device tests ran. Existing [host-test-output.txt:10](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/test-prep/todo-tests-20261103/builds/T350-bundle/host-test-output.txt:10) records `PASS 280 bundle checks`; this was inspected, not independently rerun.

5. **Findings, ranked**

   - **P2 — “Teardown happens at most once” is false globally.** The new gate limits posts originating from `abortIo()`. Direct `shutdown()` callers bypass it, and `shutdown()` resets `stopping=false` before later callbacks can arrive. A subsequent surface-loss callback can enter teardown again. Concrete resulting damage is **UNKNOWN**. Evidence: S:674, 1413–1418, 1664, 1721–1738; O:385–387, 559–563, 1104.

   - **P2 — The gate does not guarantee teardown will be posted.** After successfully claiming `aborting`, the winner executes `receiver.prepare()` before posting. A native exception or indefinite wait there leaves `running=false`, transport closed, and no teardown post; later abort callers return at the gate. Whether that native failure occurs in practice is **UNKNOWN**. This failure exposure partly predates T350, but the new gate prevents a later abort caller from retrying the preparation/post sequence. Evidence: S:1411–1418; G:36, 80.

   - **P2 — “Healthy/slow-but-alive never trips” remains unproven.** The implementation necessarily terminates a recoverable session if one socket read receives no application data for 20 seconds. No inspected evidence establishes a shorter receive bound for every requested operating state. Evidence: S:78, 84, 1311–1317, 1397–1404; detailed state assessment below.

   - **P3 — “Per-byte timer” and “~11 s of silence” overstate the evidence.** This is a timeout on each underlying `read()`. The saved gap logs measure whole `readFully` operations, not individual byte arrivals. Evidence: S:82–84, 1283–1299; I:99–104; L:688, 1102.

   **No demonstrated P1 failure was established in this review.**

6. **Primary evidence and answers to the seven attacks**

   **1 — Partial reads and SO_TIMEOUT**

   `SO_TIMEOUT` bounds an individual blocking socket-input `read()` and raises `SocketTimeoutException`; the socket itself remains valid afterward. It is not a deadline for a complete GAL frame. This matches both [Java’s specification](https://docs.oracle.com/javase/8/docs/api/java/net/Socket.html#setSoTimeout-int-) and [Android’s reference](https://developer.android.com/reference/java/net/Socket#setSoTimeout(int)).

   S:84 starts another `in.read(...)` after each successful partial result, giving that next call another timeout window. A four-byte header delivered one byte every 19,999 ms can therefore take **79,996 ms**. A 16,153-byte body under the same schedule takes **323,043,847 ms**, approximately **89.7 hours**.

   A fixed-length frame is not mathematically unbounded if every successful read advances by at least one byte, but its duration can greatly exceed 20 seconds. Continuous trickling can keep the session alive indefinitely.

   A timeout mid-header/body escapes the loop. S:1307 passes data into `receiver.incoming()` only after the complete body read succeeds. Thus the incomplete frame is abandoned, without attempting stream resynchronization. Successful teardown still depends on the lifecycle conditions described above.

   **2 — Coverage of both TCP session paths**

   The inbound path is W:743 → W:759 → S:522–535 → `beginTcpSession()` → S:884. The outbound 5277 path is S:550–578 → the same `beginTcpSession()` → S:884. Both reach S:78 before their session input stream is obtained or read.

   No AA payload read precedes handoff on the successful inbound branch: W:763 explicitly continues after ownership transfers. W:768–774 is a separate diagnostic read on sockets that were not handed off, with its own five-second timeout and close.

   Bluetooth bootstrap reads use a `BluetoothSocket` at W:822–836 and W:872–881. They do not receive this TCP timeout, correctly matching the requested AA-session-only scope. Bluetooth ping/pong at W:839–842 is also a separate channel; those pings do not establish TCP receive activity.

   **3 — Healthy-state false teardown**

   S:1399–1401 attempts a native ping every second while running. This establishes an intended send cadence, not a guaranteed TCP delivery/reply cadence. Its exception handler only logs; it does **not** call `abortIo()`.

   G:79 delegates ping generation to native code, and G:88 logs parsed responses. If replies actually reach the AA socket within each timeout window, they prevent an idle-read timeout. Whether that condition always holds is:

   | State | Guaranteed AA TCP bytes within 20 s |
   |---|---|
   | Long-term minimized/backgrounded | **UNKNOWN** |
   | Voice/Gemini session | **UNKNOWN** |
   | Navigation only | **UNKNOWN** |
   | Phone screen off | **UNKNOWN** |
   | Audio-only playback | **UNKNOWN** |

   The recorded session itself shows ping callbacks bunched after recovery: L:446, then L:1103–1122. Parsed ping timing therefore cannot be treated as byte-arrival timing.

   **4 — Original counterexample against v2**

   L:688 records an **8,549 ms header read**; L:1102 records a **10,896 ms body read**. T300 source:1275–1291 confirms these measure entire header/body operations.

   Arithmetic:

   ```text
   max phase = 10,896 ms < 20,000 ms; margin = 9,104 ms
   phase sum = 19,445 ms < 20,000 ms; margin =   555 ms
   ```

   Each underlying read lies within its enclosing completed operation; these recorded operations do not contain a demonstrated 20-second blocking read. The new timeout therefore **passes this timing case by source/log analysis**. This was not a runtime replay.

   Whether either interval was continuously zero-byte silence is **UNKNOWN**. `readBytes` advances only after completed header/body reads, S:1286 and 1297; recorder `readKB+=0` cannot exclude partial input.

   **5 — Teardown races and half-dead paths**

   Reader/writer exceptions call `abortIo()` at S:1317 and 1392; `byeBye()` does so at S:1507. The winning abort closes transport, claims the gate, prepares the receiver, and posts shutdown. Losing abort callers close transport and return.

   Surface loss and device-policy stop call `shutdown()` directly at S:674 and 588. During an already-running shutdown, `stopping` rejects another overlapping shutdown entry. After S:1731 resets it, another direct caller can enter again.

   A concrete callback chain exists in source:

   ```text
   shutdown → request overlay STOP → reset stopping
   overlay STOP → removeView → surface destroyed
   surface listener → onSurfaceLost → shutdown again
   ```

   Evidence: S:1721–1731; O:385–387, 559–563, 1104. No listener clearing appears in the inspected removal path.

   There is no ordinary Java early return between successful CAS and posting, but native preparation remains before the post. Additionally, the post result is ignored; [Handler documents that posting can fail](https://developer.android.com/reference/android/os/Handler#post(java.lang.Runnable)). Failure of this main-thread Handler during normal live operation is **UNKNOWN**.

   `aborting` is never reset—its only references are S:1409 and 1413. Any supported reuse of the same service instance after an abort would need scrutiny; a successful normal reuse sequence was **not established**.

   Reclosing the same TCP socket during joins does not create a new stream or restore it; IOException is swallowed by S:87. Harm from the repeated TCP close was not established. USB close concurrency was not independently proven.

   **6 — Failure while setting SO_TIMEOUT**

   An already-connected ordinary `Socket` is a valid target; the documented exception is `SocketException` for underlying errors. The positive 20,000 value fits `int`—I:104 and `BundleTests.java`:49–52.

   If setting the option throws, S:884 has not completed assigning the new pipe. S:945–947 catches the exception and calls shutdown; S:1728 closes `pendingSocket`, and S:1725–1730 clears session state. Thus a cleanup path exists. Successful cleanup remains conditional on shutdown itself completing.

   **7 — Regression scope**

   Static comparison confirms unchanged write/ping loops, recorder code, USB pipe, USB watchdog, and shutdown body. The successful-read T250/T270 instrumentation is unchanged in the reviewed diff.

   However, **“USB unaffected” needs qualification**: socket timeout is TCP-only, but `abortIo()` is shared with USB. Its close ordering and new gate change USB abort behavior too. Also, a timed-out read cannot reach the subsequent T250/T270 success-gap log; it produces `T350_LINK_DEAD` instead. Evidence: S:65–87, 1285–1317, 1409–1418.

7. **Assumptions**

   Ordinary conforming Java socket-input behavior; successfully completed native preparation; a functioning main Looper; and no material suspend-clock discrepancy when applying the recorded uptime intervals. Source review does not establish installed APK/native runtime parity.

8. **Unresolved uncertainties**

   Healthy-state receive bounds for all five states; native preparation exception/blocking behavior; practical consequences of duplicate shutdown; service-instance reuse; runtime USB concurrency; and actual elapsed time until Honda becomes usable. Overlay removal follows thread joins and other cleanup, S:1681–1723, so 20 seconds is not an end-to-end screen-return deadline.

9. **Exact diff summary**

   Reviewer diff: none.

   Reviewed T340 → T350 delta: TCP read timeout; timeout-specific logging; shared abort close/gate changes; comments; `LINK_DEAD_MS=20000`; manifest version `0.9-T350`. The Wi-Fi frame watchdog branch is absent; S:1650 retains `&& !tcpMode`.

10. **Preservation checks performed**

   Beginning/end SHA-256 snapshots matched for all **68 selected source/manifest files**. T350 S hash:

   ```text
   1771a39c2db983c5e5debf4a813b2b7397137bbaa3f388e3b36f67cf94d7ab55
   ```

   No artifacts were rebuilt or modified. Frozen APK/DEX anchors were not rehashed. No key material was read, no device was accessed, no milestone was advanced, and no agents were spawned.