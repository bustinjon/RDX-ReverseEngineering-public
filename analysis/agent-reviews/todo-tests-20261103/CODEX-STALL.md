**The logs favor a shared AA stream stall. A Home-triggered Honda source switch is unproven; root cause remains UNKNOWN.**

1. **Files inspected**

   Path aliases below:
   - `B` = `analysis/test-prep/todo-tests-20261103/builds/T250-bundle`
   - `L` = [B/live-20261109-201311/logcat.txt](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/test-prep/todo-tests-20261103/builds/T250-bundle/live-20261109-201311/logcat.txt)
   - `C` = `analysis/test-prep/runs/helper_20261110T004153_*/longdrive-evidence/*/capture.log` — one matching file.
   - `J` = `B/source/analysis/parallel-aa-receiver`
   - `S` = `J/usb-helper/source/com/rdx/fullscreen/usbhelper`
   - `P` = `J/src/com/google/android/projection/protocol`
   - Read `PROJECT-RULES.md`, `AGENTS.md`; searched/read `S/{AaSessionService,AaOverlayService,AaMediaSourceService,WirelessProbeService,AppSettings}.java`, `P/{AudioSink,VideoSink}.java`, and bundled `GalReceiver`, `WifiProjectionEndpoint`, `CarWifi` source.

2. **Files changed:** none.

3. **Commands run**

   `Get-Content`, `rg --files`, `rg -n/-c/-o`, capture-path `Get-ChildItem`, PowerShell filtering/grouping, and `Get-FileHash -Algorithm SHA256`.
   Failed queries: unavailable Python executable, unsupported shell brace syntax, and constrained-language rejection of `PSCustomObject`. Findings use successful queries.

4. **Tests run and results**

   No builds or executable tests. Offline log/source correlation only.
   Successful `rg -c` counts: HCI completion events **20 / 19 / 20** in consecutive 30-second windows before/during/after the stall; **25** GAL ping responses and **26** playback-state updates during 20:09:27.

5. **Findings**

   - **F1 — HIGH:** The first measured starvation interval starts **before Home**. The read duration places its start around **20:09:01.978**; the PCM duration places the preceding arrival around **20:09:01.962**. Home minimizes at **20:09:03.582**. Home/NATIVE therefore cannot explain the beginning of that interval.
   - **F2 — HIGH observation; MEDIUM interpretation:** Audio, video, GAL pings, and playback-state delivery are affected together. Recovery delivers accumulated control/status updates in a burst. This favors a shared transport/native-processing obstruction over an isolated AudioTrack problem. Phone-side queuing, TCP loss/retransmission, and receiver blocking remain **UNKNOWN**.
   - **F3 — HIGH:** No Honda source-selection or AA audio-focus transition is logged in either requested window. During starvation, Honda repeatedly retains `OTHER_APPS`/`CT2`. The mute/unmute cycles follow AudioTrack starvation/restart, supporting their being consequences.
   - **F4 — HIGH:** The FM display message is recurring background activity, present well before Home. It does **not establish FM selection**. Earlier and later explicit source observations identify Hackura.
   - **F5 — HIGH observation; causal link UNKNOWN:** AVRCP playback positions continue advancing through the stall. No corresponding A2DP start/suspend or AVRCP pause command was found in these windows. AVRCP activity alone does **not prove concurrent A2DP audio streaming**.
   - **F6 — HIGH:** Logged HCI event frequency does not surge during starvation. The observed events are sparse packet-completion notifications. These logs do **not measure incoming A2DP payload airtime**, so Bluetooth coexistence remains possible but unproven.
   - **F7 — HIGH:** This session already used **5180 MHz**. No Wi-Fi/P2P event or pid-2671 GC is logged in the requested windows. CPU starvation remains **UNKNOWN** because scheduling/CPU measurements are absent.
   - **F8 — HIGH:** The nearest measured event to the reported 20:10:45 blip is **20:10:42.915–42.922**: 1168-ms header-read wait and 1175-ms PCM gap, queue empty. Normal pings and PCM counters subsequently continue.
   - **F9 — HIGH:** T240 exhibits similar underruns and delayed ping bursts, including after restoring the overlay. T250 NATIVE is not necessary for this failure pattern; repeated later T250 minimizes also do not reproduce it.

   **Ranked candidate fixes — no permanent fix is established**

   1. **Locate and correct the shared-stream obstruction first — highest diagnostic priority.** Instrument `AaSessionService.tcpPipe().readFully()`, both reads in `readLoop()`, `receiver.incoming()`, and `writeLoop()`. The current gap logger times only the four-byte header read; long body reads or native calls can escape it. Choose the correction after identifying which operation stalls. (`S/AaSessionService.java:76`, `:1097`, `:1103`, `:1108`, `:1131`)
   2. **Isolate A2DP/AVRCP interplay — LOW causal confidence.** In a future controlled comparison, disable only the pairing’s **Media audio** profile while retaining calls and AA bootstrap, then repeat the same sequence. Confirm actual A2DP streaming state and command direction. Present evidence does not justify disabling Bluetooth wholesale.
   3. **Add a true media pre-buffer for short blips — MEDIUM mitigation confidence.** In `AudioSink.playLoop()`, accumulate approximately 1.5–2 seconds for service 4 before initial playback/rebuffering; leave guidance buffering separate. Current code starts playback immediately and allocates a 0.5-second AudioTrack buffer. Queue capacity alone is not prefill. This could mask the 1.175-second blip, but cannot reasonably hide the roughly 25-second starvation without substantial latency. (`P/AudioSink.java:55`, `:189`, `:208`, `:220`)
   4. **Preserve Hackura selection if a switch is demonstrated — LOW current priority.** Keep its MediaSession active while AA runs; retain audio focus independently of overlay visibility. Current minimize path releases video, and MediaSession activation already follows session state. A verified Honda source-selection API is **UNKNOWN**; do not invent an unconditional reselection call. (`S/AaMediaSourceService.java:46`, `:125`; `S/AaSessionService.java:1327`)
   5. **Band comparison — LOW priority.** The existing 5-GHz request is `setWifiP2pChannels(..., 6, 36, listener)`; it succeeded here. A 2.4-GHz comparison would be diagnostic only. `resetChannels(..., 0, 0, ...)` restores automatic selection and does not establish 2.4 GHz. (`S/WirelessProbeService.java:609`, `:897`)

   **What to log next**

   - Monotonic start/end times, requested/received byte counts, and thread CPU time around header reads, body reads, native incoming processing, outgoing generation, socket writes, and `nativeAckFrames()`. No payloads.
   - PCM timestamp/arrival deltas, queued **milliseconds**, playback-head progress, writes and underruns; distinguish queue capacity from actual buffered audio. (`P/AudioSink.java:125`, `:139`, `:221`)
   - Selected Honda component, main-audio mode, focus callbacks/forwarding, MediaSession play/pause callbacks, AA playback state, and AVRCP command direction.
   - A2DP streaming-state transitions and aggregated Bluetooth payload bytes; numeric P2P frequency, RSSI/retry counters, TCP retransmissions/RTT, and zero-window events.
   - A lightweight process heartbeat and per-thread CPU timing to distinguish blocked I/O, native processing, and scheduling delay.

6. **Primary evidence for findings**

   - **F1:** `L:25221` read gap; `L:25349` PCM gap; `L:24990` minimize; `L:25042` NATIVE. Gap semantics: `S/AaSessionService.java:1096`; `P/AudioSink.java:129`.
   - **F2:** `L:25828`, `:26549` low video FPS; `L:26436` onward ping burst; `L:24917` last regular playback update, `:26438` onward delayed updates.
   - **F3:** `L:25238` timeout precedes `:25250` mute; `:25263–25267` retain `OTHER_APPS`/`CT2`; `:25349` PCM arrival precedes `:25363` unmute. Window searches returned zero source/focus events.
   - **F4:** `L:23364`, `:24796`, `:24940`, `:31758` recurring FM display; `L:22860`, `:28507` Hackura selected.
   - **F5:** `L:24972`, `:25574`, `:26377`, `:26499` advancing AVRCP positions. Bluetooth source discovery at `L:20929` establishes availability, not selection or streaming.
   - **F6:** `L:24903–24907`, `:25563–25567`, `:26663–26667` completion events; successful count command outputs **20, 19, 20**.
   - **F7:** `L:15105` channel request accepted; `L:15316` supplicant reports `freq=5180`. Next observed pid-2671 GC is `L:27300`, paused 5.142 ms at 20:09:41.732.
   - **F8:** `L:31672`, `:31675` gaps; `:31677`, `:31731`, `:31740` subsequent pings/PCM.
   - **F9:** `C:2152`, `:2170`, `:2182`, `:2225`, `:2297`, `:2326`; later T250 minimizes at `L:27407`, `:27852`, `:28812`, `:29845`.

7. **Assumptions**

   Gap-duration subtraction approximates onset; bundled source describes the logger semantics. Live binary/source identity was not independently verified.

8. **Unresolved uncertainties**

   Actual A2DP payload streaming, combo-chip arbitration, TCP loss, phone scheduling, native blocking, and unlogged source changes are **UNKNOWN**.

9. **Exact diff summary:** none.

10. **Preservation checks performed**

   Read-only operations; no Git, builds, device access, or credential-file access. Frozen artifacts were untouched; their hashes were not reverified.
   SHA-256: `L` = `606C03DDF2617225C22A73F8D52F34BBC06939A3870B418113A10D5487F586CD`; `C` = `63B9A07A5B28ED0804A373A9291511A63B5719A7A74D8576EB64FF9FAC851B8F`.