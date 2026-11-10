**The head unit can likely replace the dongle for Hackura, but end-to-end wireless AA remains unproven.** Local RFCOMM listening and Wi-Fi Direct group creation have both succeeded. The remaining gates are phone-visible Bluetooth discovery, usable IP connectivity, and completing the wireless bootstrap/TCP integration.

**The T70 “nothing on the phone” result is misleading:** the phone requested credentials, and Hackura deliberately answered with an empty network.

**1. Files inspected**

Paths below use these abbreviations:

- `B` = `analysis/test-prep/todo-tests-20261103/builds`
- `J` = `B/T150-bundle/source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper`
- `M` = `B/T150-bundle/source/analysis/parallel-aa-receiver/usb-helper/AndroidManifest.xml`
- `C` = `analysis/test-prep/todo-tests-20261103/capabilities-20261105-212242`
- `O` = `analysis/parallel-aa-receiver/offline-followup/public/open-headunit/andreknieriem-open-headunit-e9377ff`
- `P2LOG` = `analysis/test-prep/runs/helper_20261106T023903_3f2d85dbf20d4739af9c7c94833073af/longdrive-evidence/rdx_7fff8395347741d4adc4bd0adf4d3bbc/capture.log`
- `T70LOG` = `analysis/test-prep/runs/helper_20261106T161644_0e5f9f0eeb424e918f7563f88d753132/longdrive-evidence/rdx_10903ebb97f14b398a3ba3c4ee24b69f/capture.log`
- `T90LOG` = `analysis/test-prep/runs/helper_20261106T214625_78865cc19bd64bf4993a6daa4a43370a/longdrive-evidence/rdx_f221a028b4e74afd98460af2893b26de/capture.log`

Inspected relevant portions of:

- `PROJECT-RULES.md`, `AGENTS.md`, root `NOTES.md`.
- `analysis/agent-reviews/open-headunit-20261105/{WIRELESS-FEASIBILITY.md,NOTES.md}`.
- T60, T70, T90, T100 and T110 `RESULT.md` files.
- T70/T150 `WirelessProbeService.java`; T70 `AaSessionService.java`.
- T150 manifest, settings, session, USB helper and Bluetooth/Wi-Fi/GAL facade source.
- `C/{features,wifi,wifi-props,bluetooth,routes,net-dev,summary}` files.
- November 6 helper captures, including overlapping copies.
- Framework Bluetooth adapter/socket/secure-manager, Wi-Fi/P2P manager, and connectivity source.
- Services connectivity/system-server source; Honda HFP/hotspot source; stock AA Bluetooth manager.
- `O` wireless framing, protobuf, handshake, HFP policy, server, socket transport and README material.
- Public primary sources linked below.

**2. Files changed**

None.

**3. Commands run**

Read-only command families, with scoped paths:

- `Get-Content`, including numbered-line extracts.
- `rg --files`, `rg -n`, `rg --json`, `rg --count-matches`.
- `Get-ChildItem`, `Select-String`, `Select-Object`, `ForEach-Object`.
- `Get-FileHash -Algorithm SHA256` on the two probe source files.
- Public web search/open/find/click operations.
- One attempted `python -c` read-only extractor: Python could not start.
- Some wildcard-path searches failed and were replaced with supported directory/glob searches.

No git commands, builds, device commands or live tests.

**4. Tests run and results**

No executable tests run.

Static comparison: T70 and T150 `WirelessProbeService.java` have identical SHA-256:

`73EA011EB5EDC28012CFD1539DD88A4E01C72769884D8D0993F2AC994E1EED37`

Recorded car tests were reviewed, not repeated.

**5. Findings**

**F1 — The proposed dongle flow is broadly correct, with several qualifications. Confidence: confident for the examined open implementations.**

The basic sequence is:

1. Pair over Bluetooth and expose the AA wireless RFCOMM UUID  
   `4de17a00-52cb-11e6-bdf4-0800200c9a66`.
2. After RFCOMM connects, the receiver sends `WifiStartRequest` with its reachable IP and TCP port.
3. Phone sends `WifiInfoRequest`.
4. Receiver returns `WifiInfoResponse`: SSID, key, BSSID, security mode and access-point type.
5. Phone acknowledges setup, joins Wi-Fi and connects to the advertised TCP endpoint.
6. The dongle forwards AA traffic between TCP and USB.

The Raspberry Pi implementation directly implements this exchange. [Bluetooth handler](https://raw.githubusercontent.com/nisargjhaveri/WirelessAndroidAutoDongle/main/aa_wireless_dongle/package/aawg/src/bluetoothHandler.cpp), [bootstrap messages](https://raw.githubusercontent.com/nisargjhaveri/WirelessAndroidAutoDongle/main/aa_wireless_dongle/package/aawg/src/bluetoothProfiles.cpp).

Important details:

- RFCOMM bootstrap framing is **two-byte big-endian protobuf payload length, two-byte big-endian message type, then protobuf bytes**. Length excludes the four-byte header.
- Types are start `1`, info request `2`, info response `3`, version request/response `4/5`, connect status `6`, start response `7`.
- Handle partial reads/writes, bounded lengths, timeouts and unexpected/status messages.
- Port **5288 is conventional and used by open-headunit**, but the start request carries a port; it is not an immutable protocol constant.
- Access-point type means **STATIC/DYNAMIC**, not “P2P versus hotspot.” In the examined schema these are `0/1`; WPA2-personal is `8`.
- Optional version negotiation exists; the simple dongle exchange starts directly with type `1`.

Primary local evidence: `O/app/src/main/java/com/andrerinas/openheadunit/connection/wifi/modes/nativeaa/WppFraming.kt:38`, `WppHandshakeSession.kt:119`, `WppMessages.kt:115`; `O/app/src/main/proto/wireless.proto:17`, `:31`, `:65`, `:88`.

The USB terminology needs care: **the car is the USB host; the dongle presents the phone-facing accessory-mode USB device**. The Pi proxy accepts TCP, opens its USB accessory endpoint and forwards both directions. Hackura would eliminate that bridge when receiving directly. [Proxy implementation](https://raw.githubusercontent.com/nisargjhaveri/WirelessAndroidAutoDongle/main/aa_wireless_dongle/package/aawg/src/proxyHandler.cpp).

AAWireless confirms Bluetooth carries Wi-Fi credentials and then disconnects. That supports this architecture, but exact smartBox, Carsifi and Ottocast firmware behavior is **UNKNOWN**. [AAWireless FAQ](https://www.aawireless.io/en/support/topics-faq-aawireless/product-info).

**F2 — “HFP connected to the same device” is not universal across dongle modes.**

Some native receiver implementations use HFP/HSP availability or connection as a startup prerequisite. However:

- WirelessAndroidAutoDongle’s v0.4 release explicitly introduced dongle mode without fake HSP.
- aa-proxy likewise skips its HSP trigger profile in dongle mode.
- Motorola says MA1 startup requires the phone to reconnect to **the vehicle’s** hands-free system, a separate Bluetooth peer from MA1.

Therefore, “every dongle must establish HFP to itself” is incorrect. [Pi release notes](https://github.com/nisargjhaveri/WirelessAndroidAutoDongle/releases), [aa-proxy Bluetooth implementation](https://raw.githubusercontent.com/aa-proxy/aa-proxy-rs/main/src/bluetooth.rs), [Motorola support](https://www.motorolasound.com/support/product-support/?productId=6219).

For direct Hackura reception, Honda already owns the real hands-free implementation through Broadcom `BluetoothHfDevice`. **If that same phone has an active Honda HFP connection through the adapter publishing AA’s UUID, the same-device condition should be satisfied. Confidence: likely.**

Bonding alone does not establish that condition. T70’s `alreadyPaired=true` proves a bond lookup succeeded, not that HFP was connected at that instant.

Evidence: `decompiled/HondaSettings/sources/com/honda/settings/btservice/proxyhandlers/BluetoothHFPProfile.java:58`, `:160`; `T70LOG:5128`.

**Do not add a competing dummy HFP service.** Open-headunit explicitly avoids this when real Hands-Free exists because the duplicate can capture a connection without serving call audio. Evidence: `O/app/src/main/java/com/andrerinas/openheadunit/connection/wifi/modes/nativeaa/HfpServiceRecordPolicy.kt:7`, `:24`.

**F3 — An ordinary app can open the RFCOMM listener here; remote SDP visibility remains UNKNOWN.**

The actual Honda framework retains the standard chain:

- `listenUsingRfcommWithServiceRecord()`
- create socket with service name/UUID
- `bindListen()`
- Bluetooth service `createSocketChannel()`.

Evidence: `decompiled/Framework/sources/android/bluetooth/BluetoothAdapter.java:700`, `:716`; `BluetoothSocket.java:203`.

More importantly, T70 logged `P1_LISTENING` with the correct UUID. This demonstrates that the app’s local listen operation succeeded on the car; it counters a blanket “Honda forbids third-party RFCOMM” claim. Evidence: `T70LOG:5239`.

It does **not** prove that the phone retrieved the SDP record or attempted RFCOMM. No accepted-phone or first-byte markers were found in the searched main captures.

Honda’s secure-mode manager exists, but its existence does not prove it blocked this UUID. Its enabled state and native filtering effect are **UNKNOWN**. Evidence: `decompiled/Framework/sources/android/app/BluetoothSecureManagerService.java:122`, `:139`.

**F4 — Wi-Fi Direct group creation is already demonstrated. TCP reachability is not.**

An earlier captured attempt shows:

- creation accepted;
- group-owner mode;
- generated group interface `p2p-wlan0-0`;
- passphrase present;
- zero connected clients;
- group removed;
- matching persistent profile deleted successfully.

Evidence: `P2LOG:3999`, `:4010`, `:4309`, `:4317`.

This is stronger than the feasibility report’s API-only argument. Overlapping captures contain the same timestamps; they should not be counted as independent successful tests.

However, that attempt logged **`ipv4=none`**. The helper suppresses exceptions and returns the same value for several failure cases. It therefore does not establish whether an address was absent, unreadable or checked too early.

Evidence: `P2LOG:4010`; `J/WirelessProbeService.java:335`.

The next network check should wait for connection information and inspect `groupFormed`, group-owner address and actual group interface. Do not hard-code `p2p0` or `wlan0`.

Capability evidence supports Wi-Fi/P2P availability and 5 GHz scanning, but **5 GHz group-owner operation, client association and throughput remain UNKNOWN**. Evidence: `C/features.txt:23`, `:25`; `C/wifi-props.txt:3`; `C/wifi.txt:69`.

**F5 — Permission requirements need Android 5.1-specific wording.**

The earlier report calls the probe permissions “normal.” That is technically inaccurate for the Android 5.1 reference manifest:

| Operation | Reference Android 5.1 permissions | Privileged? |
|---|---|---|
| RFCOMM listener | `BLUETOOTH` — dangerous, install-time | No |
| P2P management | `ACCESS_WIFI_STATE` — normal; `CHANGE_WIFI_STATE` — dangerous, install-time | No |
| TCP sockets | `INTERNET` — dangerous, install-time | No |
| Network-state diagnostics | `ACCESS_NETWORK_STATE` — normal | No |
| Soft AP, ordinary reference path | Wi-Fi change permission plus `CHANGE_NETWORK_STATE` — normal | Usually no |
| Provisioning-restricted tether path | `CONNECTIVITY_INTERNAL` | Signature/system |

These historical “dangerous” permissions are available to ordinary apps; Android 5.1 does not use the modern runtime permission flow. OEM permission definitions could differ. [Android 5.1 manifest](https://raw.githubusercontent.com/aosp-mirror/platform_frameworks_base/android-5.1.1_r38/core/res/AndroidManifest.xml).

For P2P, the saved successful attempt establishes practical access on this build.

For soft AP, Honda exposes `setWifiApEnabled`, and Honda Settings uses it. The local connectivity helper selects `CONNECTIVITY_INTERNAL` when provisioning is configured, otherwise `CHANGE_NETWORK_STATE`. **The actual Honda Wi-Fi service implementation/provisioning configuration was not established, so ordinary-app soft-AP startup remains UNKNOWN.**

Evidence: `decompiled/Framework/sources/android/net/wifi/WifiManager.java:636`; `decompiled/HondaSettings/sources/com/honda/settings/wifilibrary/statemachine/HotspotState.java:172`; `decompiled/Framework/sources/android/net/ConnectivityManager.java:676`. The comparable 5.1 service performs both checks: [reference implementation](https://raw.githubusercontent.com/LineageOS/android_frameworks_opt_net_wifi/cm-12.1/service/java/com/android/server/wifi/WifiServiceImpl.java).

**T150 lacks `INTERNET`.** Add it before attempting TCP reception. Its current permission declarations are at `M:4` through `M:18`.

Once the phone joins and receives an address, ordinary local TCP reception is plausible with that permission. Honda firewall, interface and routing behavior still require a connection test.

**F6 — 5 GHz is the preferred target, not something this evidence proves for the RDX AP.**

Google specifies a compatible phone with 5 GHz support; MA1 uses 5 GHz. [Google requirements](https://support.google.com/androidauto/answer/6348019?hl=en-CG), [MA1 specifications](https://motorolasound.com/audio-products/android-auto/ma1/).

The examined protocol also represents 2.4 GHz-only capability. That does not establish that this owner’s current phone will accept a 2.4 GHz group. Evidence: `O/app/src/main/proto/wireless.proto:24`.

API22 `createGroup()` has no band parameter. A hidden channel-setting method exists in Honda’s framework, but its usable permissions and driver behavior here are **UNKNOWN**. Evidence: `decompiled/Framework/sources/android/net/wifi/p2p/WifiP2pManager.java:486`, `:501`.

**F7 — T70 exercised two different mechanisms, neither a completed wireless receiver.**

| Observation | Meaning |
|---|---|
| 11:07:44: P3 registered Bluetooth service 8 and Wi-Fi service 14 | AA protocol endpoints registered |
| 11:07:45: phone requested Wi-Fi credentials | The phone responded to P3 |
| Hackura returned an empty network | No usable Wi-Fi handoff was offered |
| 11:07:46: pairing request reported already bonded | Bond present; HFP state still unknown |
| 11:08:02: separate P1 listener started | Local RFCOMM listen succeeded |
| No P1 accepted-connection marker found | No observed RFCOMM connection |

Primary evidence is listed in section 6.

P3’s `receiver.register(...)` is **AA service registration inside the existing wired session**, not Bluetooth SDP registration. Its Settings toggle does not start P1 or P2.

Evidence: `J/AaSessionService.java:679`, `:840`, `:858`; `J/SettingsActivity.java:255`, `:260`, `:265`.

The identical T70/T150 probe only reads for ten seconds and closes a connected socket. It never writes `WifiStartRequest` or credentials. Evidence: `J/WirelessProbeService.java:131`, `:140`, `:162`.

Most likely explanation:

- **No wireless transition from P3:** confidently explained by empty credentials and absent end-to-end wireless plumbing.
- **No P1 socket connection:** startup ordering/phone discovery or cached capability state is a plausible leading explanation—the listener appeared after wired negotiation—but the cause is **UNKNOWN** without phone-side SDP/connection evidence.
- Missing outbound messages would block a connection **after acceptance**; they do not explain the absence of an accepted socket.
- Wrong UUID and a basic listen-permission failure are contradicted by the saved local success.
- Missing HFP, OEM SDP filtering and phone-side policy remain unresolved alternatives.

**F8 — Hackura needs transport/lifecycle work, but a second AA receiver stack is unnecessary. Confidence: likely.**

Current code:

- stores a concrete `UsbBulkTransport`;
- requires a pending USB device before surface initialization;
- constructs USB transport directly;
- then reads/writes framed data through the transport.

Evidence: `J/AaSessionService.java:57`, `:476`, `:690`, `:892`, `:924`.

A TCP transport and a wireless startup path can reuse those receiver-facing loops. That is credible architectural evidence, not proof that merely replacing one constructor completes wireless support.

**F9 — Ranked options**

Effort and risk assessments below are engineering judgments.

| Rank | Option | Likelihood / effort | Main risks |
|---|---|---|---|
| **1** | **(b) Keep the working dongle** | **Confident:** already passed; low additional effort | USB reconnect/sleep behavior; phone battery use without cable charging; preserve Honda call audio |
| **2** | **(a) Entire flow in Hackura** | **Likely feasible**, end-to-end UNKNOWN; medium/high effort | SDP discovery, IP readiness, band/throughput, Honda radio coexistence, reconnect lifecycle and call regression |
| **3** | **(d) Pi/aa-proxy USB device** | **Likely as an architecture**, RDX-specific compatibility UNKNOWN; moderate setup | USB gadget compatibility, boot time, power/heat, extra hardware; phone still consumes wireless power |
| **4** | **(c) Phone helper/manual developer-server hybrid** | Version-dependent, **UNKNOWN** for this phone; medium/high effort | AA startup restrictions, background/battery policy, manual steps and additional software |

The dongle path is supported by actual AOAP switching and protocol traffic, plus later operator PASS results: `T90LOG:1572`, `:1601`, `:1666`, `:1707`; `B/T110-bundle/RESULT.md:15`.

The earlier allow-list/AOAP-switch defect already has a T150 implementation for explicitly added devices. Preserve that behavior rather than reopening all USB devices. Evidence: `J/UsbHelperService.java:748`.

Useful dongle improvements are bounded reconnect diagnostics, clear enabled-device handling and cold-start validation—not a new wireless bootstrap inside Hackura.

The Pi project documents native wireless-to-USB operation and requires USB gadget-capable hardware. [Project README](https://github.com/nisargjhaveri/WirelessAndroidAutoDongle).

The helper route deserves a lower ranking: the examined open-headunit version warns that recent AA versions restrict legacy helper startup. Treat this as project evidence requiring verification against the actual phone version. Evidence: `O/README.md:16`, `:124`.

**All four options retain Honda’s application-launch/motion restriction unless separately addressed.** Transport changes do not establish a remedy. Evidence: `B/T70-bundle/RESULT.md:16`.

**F10 — Concrete parked-only test plan**

Best daily-use choice: keep the dongle. Best candidate for eliminating it: direct Hackura reception using the existing Honda HFP connection and demonstrated P2P support.

Proposed implementation prerequisites: required socket permission, selectable TCP transport, separate wireless lifecycle, and all experimental behaviors off by default. No changes or tests were performed.

Each row introduces one Settings-controlled behavior; retain previously passing conditions.

| Test / Settings switch | What to log | PASS |
|---|---|---|
| **Known dongle enabled** — baseline | AOAP stage, transport open, session start/stop, reconnect reason | Existing dongle starts, reconnects and stops cleanly |
| **Bluetooth discovery probe** | Local listener result; phone-side AA-UUID-present boolean; accept count; HFP-connected boolean; distinguish timeout from other accept errors | Phone retrieves the UUID and opens RFCOMM while Honda HFP remains connected |
| **P2P address-readiness probe** | Group-formed/owner flags, interface, owner-address-present boolean, credential length, frequency if available, cleanup result | Group has usable address information and removal/profile cleanup is confirmed |
| **TCP reachability probe** | Bind result, accepted connection, fixed test-token count, close result | A phone client on that group reaches port 5288 and exchanges the test token |
| **Wireless bootstrap** | Message types/lengths, status codes, credential-ready flag, TCP accept; publish only after network/listener readiness | Phone requests credentials, joins and reaches TCP |
| **Wireless AA session** | Version/TLS stages, first video/audio, frame timing, touch delivery, disconnect reason | Parked picture, touch, media and guidance operate through TCP |
| **Wireless call validation** | HFP/SCO state transitions and AA audio-focus changes | Parked incoming/outgoing calls retain Honda microphone/speakers and AA recovers afterward |
| **Wireless reconnect/idle cleanup** | Bounded retry count, process/connection generation, sockets/groups remaining, battery observations | Reconnect succeeds repeatedly; stopping leaves no listener/group or retry loop |

For the discovery test, start the listener **before** the ordinary phone/HFP reconnect. Keep re-pairing or any alternate startup trigger as a separate later test variable.

Do not add dummy HFP or cycle the Bluetooth radio during the initial tests. Log message metadata and booleans, not names, addresses, credentials or raw bootstrap payloads.

The existing probe needs better diagnostics: it suppresses all accept I/O failures as though they were timeouts, suppresses address-enumeration errors, and logs identifier-bearing fields. Evidence: `J/WirelessProbeService.java:118`, `:226`, `:344`.

**6. Primary evidence for the central findings**

| Finding | Saved primary evidence |
|---|---|
| P2P creation accepted | `P2LOG:3999` |
| Group owner, passphrase present, no clients, IPv4 diagnostic `none` | `P2LOG:4010` |
| Group removed; profile deletion confirmed | `P2LOG:4309`, `P2LOG:4317` |
| P3 endpoint registration succeeded | `T70LOG:5021`, `T70LOG:5022` |
| Phone requested credentials; empty network returned | `T70LOG:5101`; T70 `AaSessionService.java:587`, `:588` |
| Phone bond found | `T70LOG:5128` |
| Correct RFCOMM listener opened | `T70LOG:5239` |
| Dongle accessory start and transport traffic | `T90LOG:1572`, `:1666`, `:1707` |

The final `rg --count-matches` scan for `P1_PHONE_CONNECTED`, `P1_FIRST_BYTES` or `P1_LISTEN_REFUSED` across the November 6 main captures returned **exit 1, no matches**. Absence of those markers does not prove complete phone-side capture coverage.

**7. Assumptions**

- The specified T150 snapshot is the implementation reference.
- Saved captures correspond to the reported bundles; live binary/source parity was not independently verified.
- Bluetooth identity is shared between Honda HFP and the default adapter used by Hackura; the active phone-side identity/state still needs observation.
- Likelihood and effort rankings are judgments, not measured probabilities.

**8. Unresolved uncertainties**

- Phone-visible SDP record and actual wireless startup trigger.
- Active HFP state during the T70 probe.
- Meaning of the suppressed `ipv4=none` diagnostic.
- Client association, DHCP completion, TCP reachability and Honda filtering.
- 5 GHz hosting/control and sustained projection performance.
- Exact Honda soft-AP permission/provisioning behavior.
- Current phone AA version, cached vehicle capabilities and helper compatibility.
- Long-term battery, thermal, sleep and reconnect behavior.

**9. Exact diff summary**

None. No files changed.

**10. Preservation checks performed**

- Read project rules first.
- Rechecked the probe source hashes; both remained identical to the earlier values.
- No git, builds, device access, milestone actions or guard changes.
- No prohibited key-material files or directories read.
- Frozen artifacts were not modified or rebuilt; their hashes were not audited.

Privacy limitation: some broad tool outputs included identifiers despite the requested restriction. They are not repeated in this report.