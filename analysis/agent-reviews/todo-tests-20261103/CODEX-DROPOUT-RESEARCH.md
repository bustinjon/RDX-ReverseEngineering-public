1. **Files inspected**

   Relative-path abbreviations used below:

   - `B` = `analysis/test-prep/todo-tests-20261103/builds/T280-bundle`
   - `S` = `B/source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper`
   - `F0` = `B/headunit-logs-20261109-214205/hackura-20261109-203935-auto-stall-body-3023ms.txt`
   - `F1` = same directory, `hackura-20261109-213801-auto-stall-3663ms.txt`
   - `F2` = same directory, `hackura-20261109-214051-auto-stall-8040ms.txt`
   - `P` = preparation capture identified in `analysis/agent-reviews/todo-tests-20261103/CODEX-FREEZE2.md:6`.
   - Read `PROJECT-RULES.md`, `AGENTS.md`, T270/T280 `RESULT.md`, `CODEX-FREEZE2.md`; selected primary-log and bundled-source sections.
   - Public sources included Android documentation/source, Broadcom driver source, Google support/tracker reports, Reddit, and both dongle projects. XDA requests failed with HTTP 403/502.

2. **Files changed**

   None.

3. **Commands run**

   Read-only `Get-Content`, `Get-ChildItem`, `Get-Command`, `Select-Object`, `rg -n`, and numbered/filtering PowerShell pipelines; public web searches/opens; GitHub HTTP GET requests. One attempted Python reader failed before reading files; PowerShell replaced it. No Git commands.

4. **Tests run and results**

   Static evidence checks only. Confirmed receive collapse, recorder-counter scope, long frame-body reads, existing socket options, channel request, and wireless shutdown code. No builds, runtime tests, device access, or proposed driving tests performed.

5. **Findings**

   **Verdict — likely:** the long simultaneous freezes involve transport starvation or backpressure somewhere between phone production and head-unit delivery. **UNKNOWN:** which endpoint causes it. The evidence does not justify “the phone’s radio is responsible.”

   **Confident corrections to the starting interpretation:**

   - `rxPkts+=` counts packets per sample, approximately 1.04 seconds apart; it is not an already normalized rate. Zero errors/drops does not certify a healthy RF/firmware path.
   - TCP retransmits are system-wide, without AA-flow attribution. They do not establish bidirectional AA radio loss. The claimed loopback baseline is also **UNKNOWN**.
   - Low aggregate CPU weakens sustained CPU saturation; it does not exclude a blocked reader, lock, driver problem, or individual busy core.
   - The boot audio-focus interruption must be excluded from radio-freeze comparisons. Primary evidence is listed in §6.

   **Ranked match table — investigation order, not measured probabilities**

   | Rank | Explanation and confidence | Expected counter pattern; match and counterexample | Concrete one-drive test |
   |---|---|---|---|
   | **1** | **Phone off-channel activity: home-network contention, scans, roaming. Likely candidate; actual occurrence UNKNOWN.** | Channel absence can interrupt data and ACK delivery, collapse RX without netdev errors, and cluster around connection/search activity. Driveway exposure fits. Away-from-home freezes mean home association cannot explain everything. Normal channel sharing alone should not imply 40-second outages. | **Phone:** disable home-network auto-connect before starting; keep Wi-Fi enabled. Compare a driveway period and the usual route. On a separate leg, disable Location Wi-Fi scanning only. |
   | **2** | **BT/Wi-Fi combo interaction at either endpoint. Likely candidate; endpoint UNKNOWN.** | Radio/firmware scheduling trouble could affect traffic and ACKs without host error counters. BT-only glitches make shared radio/phone/OEM behavior worth testing, but are unlogged and may be a separate audio problem. Boot phonebook timing does not prove a trigger. | **Phone:** disable Contacts and Messages sharing for the car, leaving calls connected; compare startup and the same route. Improvement implicates profile activity, not a particular chip. |
   | **3** | **Channel-specific interference or poor 5-GHz reception. Likely candidate; source UNKNOWN.** | Bursty interference can produce RX collapse, TCP recovery delays, and geographic clusters. No netdev errors is compatible. A channel change helping would not distinguish interference from firmware/channel behavior. | **Car build:** independently select 36 or 149, verify actual frequency, then compare equal route legs. Keep bootstrap and other settings constant. |
   | **4** | **Head-unit bcmdhd concurrency, GO power management/NoA, or firmware stall. UNKNOWN.** | Can explain stopped delivery with low host CPU and no group teardown. Periodic absence could produce trickling. No beacon, NoA, or firmware-state evidence establishes this here. | **Car build:** independent high-performance Wi-Fi-lock switch plus passive transport recording. Compare matched legs. A negative result does not exclude GO power management because the lock may not control it. |
   | **5** | **Phone AA/OS stall or transport flow-control stall, including receiver backpressure. UNKNOWN.** | Phone production stopping can collapse RX. A blocked head-unit reader can fill its receive window and eventually suppress inbound traffic. Both can freeze all multiplexed GAL channels; CPU need not be high. | **Phone:** repeat the same route with another Android phone. **Car build:** record reader phase, socket queues and effective receive buffer. A growing receive queue favors receiver backpressure. |

   The mechanism behind rank 1 is documented, but the topology matters. **Confident:** Android supports optional concurrent interfaces, and multi-channel operation can require time sharing. **UNKNOWN:** whether this phone remains associated with home Wi-Fi, uses dual radios, or joins the car as a legacy STA rather than a P2P client. A head-unit GO does not establish the phone’s interface type. [Android interface concurrency](https://source.android.com/docs/core/connect/wifi-hal), [channel-sharing guidance](https://source.android.com/docs/core/connect/wifi-sta-sta-concurrency).

   **Background scanning and roaming — plausible, not proven.** Android documents connected-network scans, firmware roaming scans, and scans initiated by other components. Its documented network-selection policy also skips scans under sufficient active traffic. That is a counterexample to assuming every ordinary background scan explains these long freezes. Turning off Location Wi-Fi scanning does not establish that all connectivity or firmware scans stopped. [Android network selection](https://source.android.com/docs/core/connect/wifi-network-selection).

   **Dongle advice about home Wi-Fi/scanning:** AAWireless’s inspected official FAQ recommends Audio Stutter Fix and channels 36/149; it does not recommend forgetting home Wi-Fi or disabling scanning. Those remain diagnostic experiments. A Reddit report describes disabling scanning alongside several other changes, so causation is **UNKNOWN**; another MA1 report lists disabling scanning among unsuccessful attempts. [AAWireless FAQ](https://www.aawireless.io/en/support/topics-faq-aawireless/troubleshooting), [multi-change owner report](https://www.reddit.com/r/AndroidAuto/comments/10v7fau), [counterexample](https://www.reddit.com/r/AndroidAuto/comments/1b8ir1k/motrola_ma1_audio_skipping_since_getting_galaxy/).

   **BT coexistence, including 5 GHz:** ordinary Bluetooth spectrum overlap concerns 2.4-GHz Wi-Fi. Our channel 36 link therefore weakens that simple explanation. Shared firmware/resources or additional 2.4-GHz activity remain possible, but a specific 5-GHz coexistence defect here is **UNKNOWN**. An Infineon-hosted combo-chip report actually describes improvement on 5 GHz. [Linux coexistence documentation](https://wireless.docs.kernel.org/en/latest/en/users/documentation/bluetooth-coexistence.html), [combo-chip report](https://community.infineon.com/t5/AIROC-Wi-Fi-and-Wi-Fi-Bluetooth/Bluetooth-audio-streaming-WiFi-inteference/td-p/379269).

   **GO power save / NoA / listen:** Broadcom source implements separate NoA scheduling, opportunistic power save/CTWindow, and legacy power-management controls. This establishes mechanisms, not their activation on Honda’s firmware. `wl PM 0` would not by itself establish that every P2P absence mechanism was disabled. Normal discovery is documented to stop when a group forms; the configured social listen channel is not evidence of repeated off-channel listening during projection. [Broadcom P2P implementation](https://android.googlesource.com/kernel/bcm/+/android-wear-5.0.2_r0.5/drivers/net/wireless/bcmdhd/wl_cfgp2p.c), [Android discovery lifecycle](https://developer.android.com/reference/android/net/wifi/p2p/WifiP2pManager).

   **DFS / channel choice:** **Confident:** the implementation explicitly requests non-DFS channel 36 (`S/WirelessProbeService.java:614–620`). DFS evacuation of that recorded channel is a poor match. Channel 149 is a worthwhile comparison because AAWireless recommends it, subject to actual hardware/regulatory acceptance. An explicit 2.4-GHz trial can discriminate band effects, but introduces Bluetooth spectrum overlap; it is not automatically an improvement. Verify selected frequency after every request or fallback. [AAWireless channel advice](https://www.aawireless.io/en/support/topics-faq-aawireless/troubleshooting).

   **TCP / power saving:** **Likely:** TCP recovery can amplify short delivery failures into much longer visible freezes. **UNKNOWN:** whether the observed 2.1–2.7-second cadence is retransmission backoff, window probing, scheduling, or application pacing. RTO doubles after timeout; a roughly fixed cadence alone is not its fingerprint. No Android-P2P-specific TCP defect was established. [RFC 6298 §5](https://www.rfc-editor.org/rfc/rfc6298.html).

   **Doze/adaptive connectivity:** classical Doze requires an idle, unplugged, screen-off phone; Android also has lighter idle behavior. Neither should be confused with firmware Wi-Fi power save. A charging/screen-state comparison is useful, but no power-state evidence exists here. Google’s inspected Adaptive Connectivity documentation describes cellular 5G selection, not an AA Wi-Fi power-save switch; treating its disablement as a known fix is **UNKNOWN**. [Doze](https://developer.android.com/training/monitoring-device-state/doze-standby), [Android 7 idle behavior](https://developer.android.com/about/versions/nougat/android-7.0), [Adaptive Connectivity](https://support.google.com/pixelphone/answer/2819583?hl=en).

   **Known regressions and comparable projects**

   | Source | What is established; relevance |
   |---|---|
   | Google AA support, Samsung/Pixel reports across Android 14–16 | **Confident:** Google announced a wireless-audio-stutter fix in AA 13.2+ in December 2024. Later users reported persistence, including Android 16 audio/display stalls. These establish reports and an announced fix, not a universal OS defect. The original report explicitly had unaffected display and good BT-only audio—a weaker match to ours. [Primary thread](https://support.google.com/androidauto/thread/298706745?hl=en&msgid=335618895), [later reports](https://support.google.com/androidauto/thread/298706745?hl=en&msgid=373828683). |
   | Google tracker, Pixel networking | A detailed Android 16 report attributes disconnects to 30-second DHCP leases/address expiry. **UNKNOWN:** platform confirmation; it was closed for component-routing reasons. Expected teardown/reconnect and lease timing differ from our surviving, trickling connection. [Report](https://issuetracker.google.com/issues/566467869). |
   | aa-proxy-rs #39 | Clustered dropouts on 5-GHz channel 36; later location-specific audio/display trouble. One report says another dongle worked with the same phone/car—counterevidence against phone-only attribution. No comparable packet counters. [Issue](https://github.com/aa-proxy/aa-proxy-rs/issues/39). |
   | WirelessAndroidAutoDongle | #217 contains persistent stutter despite channel/band experiments; #346 reports Pixel drops after an update without proving causation. #322 identifies an actual phone automation disabling Wi-Fi—a useful settings check, though teardown differs from ours. [#217](https://github.com/nisargjhaveri/WirelessAndroidAutoDongle/issues/217), [#346](https://github.com/nisargjhaveri/WirelessAndroidAutoDongle/issues/346), [#322](https://github.com/nisargjhaveri/WirelessAndroidAutoDongle/issues/322). |
   | OpenAuto / Crankshaft | OpenAuto ships audio-buffer and post-disconnection hang fixes, but its documented wireless path uses the phone head-unit server. Crankshaft reports include UI/audio/resource problems without our counters. These are compatibility examples, not evidence for native-wireless radio freezes here. [OpenAuto releases](https://github.com/f1xpl/openauto/releases), [Crankshaft issue](https://github.com/opencardev/crankshaft/issues/139). |

   **What projects actually ship, and what Hackura could apply**

   | Change | Evidence/status | Unprivileged Android 5.1 feasibility |
   |---|---|---|
   | Fixed channel / 5-GHz AP configuration | Original dongle’s Pi4 template explicitly uses 5 GHz and channel 36. [Template](https://github.com/nisargjhaveri/WirelessAndroidAutoDongle/blob/main/aa_wireless_dongle/board/raspberrypi4/rootfs_overlay/etc/hostapd.conf.in). | **Yes, conditionally:** extend the existing reflected channel request. Cannot replace the system’s AP configuration; verify frequency and refusal/fallback. |
   | Audio flow-control tuning | aa-proxy ships `audio_max_unacked`, modifying GAL AudioConfig. This is distinct from TCP socket buffering. [Implementation](https://github.com/aa-proxy/aa-proxy-rs/blob/main/src/mitm.rs#L2647). | **Potentially**, if Hackura’s receiver configuration exposes it. Not an established cure for whole-stream starvation. |
   | `wl PM 0` / `iw … power_save off` | General driver controls exist; **UNKNOWN** as a shipped freeze fix in the inspected dongle versions. `iw` SET_POWER_SAVE requires administrative permission. [Kernel implementation](https://android.googlesource.com/kernel/exynos/+/refs/heads/android-exynos-3.4/net/wireless/nl80211.c). | **No direct equivalent** under supplied privileges. Reflection does not grant administrative driver access. |
   | Android high-performance Wi-Fi lock | Available in API 12; historical API describes reduced loss/latency, hardware-dependent. [Android 5.1 source](https://github.com/aosp-mirror/platform_frameworks_base/blob/android-5.1.1_r38/wifi/java/android/net/wifi/WifiManager.java#L467). | **App-level experiment**, with required permission. Actual control of the GO/NoA remains **UNKNOWN**. |
   | TCP buffer / TCP_NODELAY | aa-proxy enables TCP_NODELAY. Hackura already requests a 1-MiB listener receive buffer before bind and enables NODELAY/keepalive. `S/WirelessProbeService.java:681,700`. | **Yes** for owned sockets; kernel limits still apply. Log effective sizes before changing them. No verified project-specific TCP-buffer cure found. |
   | Beacon interval / WMM/QoS | No explicit beacon/WMM tuning appears in the inspected original Pi4 or aa-proxy Pi templates. Effective defaults and a shipped corrective setting are **UNKNOWN**. [aa-proxy template](https://github.com/aa-proxy/buildroot/blob/main/external/board/rpi/rootfs_overlay/etc/hostapd.conf.in). | No established ordinary-app control over system GO beacon/WMM parameters. |
   | Stop peer discovery | Public API since level 16. [API](https://developer.android.com/reference/android/net/wifi/p2p/WifiP2pManager#stopPeerDiscovery(android.net.wifi.p2p.WifiP2pManager.Channel,%20android.net.wifi.p2p.WifiP2pManager.ActionListener)). | **Yes**, but does not disable Honda’s STA scans or firmware roaming. |

   **Recommended phone-side settings/tests — available now**

   - First test home auto-connect and Location Wi-Fi scanning separately, as rank 1 describes. Keep Wi-Fi itself enabled.
   - Next test Contacts/Messages sharing off. Configure settings before each comparison leg.
   - Check phone driving routines for Wi-Fi changes; the dongle issue above contains a confirmed example.
   - For power-state discrimination, compare matched periods with charging and without charging; log screen state. Battery Saver off is a reasonable controlled experiment, not a demonstrated fix.
   - Record OS, AA and Play-services versions before updating; compare another phone before attributing this to an Android 14–16 regression.
   - Use downloaded media to separate internet buffering from projection trouble. Continued navigation/video/pings would identify a different failure class.
   - A single clean drive only weakens a hypothesis because the existing failures are clustered and intermittent.

   **Recommended car-side work — needs a build; proposals only**

   - Add bounded passive recording first: elapsed sample time, P2P TX, effective socket buffers, socket queues, last successful read, reader phase, and audio-focus state. Redact connection identifiers. Source insertion areas: `S/AaSessionService.java:1140–1154,1226–1246`.
   - Add an independent 36/149 channel selector with verified frequency and preserved recovery behavior.
   - Add an independent high-performance Wi-Fi-lock experiment; report it as requested, not “GO power save disabled.”
   - Preserve existing defaults while comparing changes. Avoid another large audio cushion: T270 added latency and still ran dry (`T270-bundle/RESULT.md:21,43–44`).

   **“Connecting to Android Auto” while wireless is off**

   **Confident:** unwanted repeated connection attempts are publicly documented. A dongle report describes the phone trying for minutes while the receiver is powered but unavailable. AAWireless ships manual/automatic standby to prevent unwanted connections. [Connection-strategy report](https://github.com/nisargjhaveri/WirelessAndroidAutoDongle/issues/336), [official standby instructions](https://www.aawireless.io/en/support/topics-faq-aawireless/troubleshooting).

   **Confident implementation examples:** aa-proxy unregisters its AA Wireless Bluetooth profile while wired mode is present; the original dongle supports waiting for the downstream accessory before enabling Bluetooth. These prevent invitation/advertisement rather than relying on an undocumented permanent-refusal message. [Profile suppression](https://github.com/aa-proxy/aa-proxy-rs/blob/main/src/bluetooth.rs#L4986), [connection strategy](https://github.com/nisargjhaveri/WirelessAndroidAutoDongle/blob/main/aa_wireless_dongle/package/aawg/src/aawgd.cpp#L27).

   Hackura already closes its RFCOMM listener/client, TCP sockets and group on shutdown (`S/WirelessProbeService.java:1014–1037`). **UNKNOWN:** whether off-state retries come from phone-cached capability, an incomplete shutdown, another startup route, or another advertised service. A build should verify off-state lifecycle and absence of fresh bootstrap attempts. An established GAL session can receive a graceful ByeBye, but no verified RFCOMM refusal/status value was found that guarantees suppression of future attempts while preserving Honda Bluetooth profiles. [aa-proxy graceful disconnect](https://github.com/aa-proxy/aa-proxy-rs/releases).

6. **Primary evidence for local findings**

   - **Receive collapse:** `F1:1677–1682` records RX deltas 1/4/3/4 with zero reported errors/drops; `F2:516–520` records 0–4 packets per sample.
   - **Counter limitations:** `S/AaSessionService.java:1142–1151,1168–1181` reads selected-netdev RX and system-wide TCP counters.
   - **CPU limitation:** `F2:611,653` records 80% and 88% at/after recovery.
   - **Trickling:** `F0:571–601` records repeated 8,231-byte body reads taking roughly 1.8–3.0 seconds.
   - **Reader/backpressure alternative:** `F0:486` records `incoming()` taking 819 ms; `S/AaSessionService.java:1226–1246` shows synchronous header/body reads and receiver dispatch.
   - **Audio-focus counterexample:** `P:7787,7791` records focus loss `-2`; `P:10233,10619,12483` records continuing ping/video activity.
   - **BT-only glitches/retry:** `B/RESULT.md:11–12` is operator-report evidence only, without corresponding transport logs.

7. **Assumptions**

   Bundled source describes the recorder used in these captures. Installed-binary parity was not independently verified. Public project source represents the fetched revision; applicability to Honda’s vendor firmware is **UNKNOWN**.

8. **Unresolved uncertainties**

   Failing endpoint; phone interface topology/home association; actual scans; RF retries; GO beacons/NoA; firmware power state; per-flow retransmissions/windows; phone thermal/power state; cause of BT-only glitches and off-state retries. XDA content was inaccessible, and some Google tracker details required sign-in.

9. **Exact diff summary**

   None; no files changed.

10. **Preservation checks performed**

   All local operations were reads/searches. No builds, Git commands, device operations, key-material reads, artifact modifications, or milestone actions. Frozen-artifact hashes were not checked.