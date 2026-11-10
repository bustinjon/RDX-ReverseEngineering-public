**Wireless AA without a dongle remains plausible. The strongest additional route is QR-provisioned WPP over TCP, which can avoid the missing AA RFCOMM connection. Its compatibility with this phone is UNKNOWN.** The pinned implementation builds that setup link and implements the TCP control server. Evidence: `N/ProjectionDeepLink.kt:6`, `N/WppTcpServer.kt:253`, with aliases below.

**1. Files inspected**

Paths below are relative to the workspace.

| Alias | Location |
|---|---|
| `R` | `analysis/agent-reviews/todo-tests-20261103` |
| `B` | `analysis/test-prep/todo-tests-20261103/builds` |
| `P` | `B/T190-bundle/source/analysis/parallel-aa-receiver/usb-helper` |
| `J` | `P/source/com/rdx/fullscreen/usbhelper` |
| `G` | `decompiled/AndroidAuto-current/sources/com/google/android/projection` |
| `H` | `decompiled/HondaSettings` |
| `F` | `decompiled/Framework/sources/android` |
| `O` | `analysis/parallel-aa-receiver/offline-followup/public/open-headunit/andreknieriem-open-headunit-e9377ff` |
| `K` | `O/app/src/main/java/com/andrerinas/openheadunit` |
| `N` | `K/connection/wifi/modes/nativeaa` |
| `A` | `analysis/parallel-aa-receiver/offline-followup/public/open-android-auto/mrmees-open-android-auto-61eab61` |
| `L` | `analysis/test-prep/runs/helper_20261109T003917_e5372324ccca4b75a22ffd2df56eaff0/longdrive-evidence/rdx_f8722094bd3144dd8af1956995401592/capture.log` |

Inspected, selectively where large:

- `PROJECT-RULES.md`, `AGENTS.md`.
- `R/{CODEX-WIRELESS,CODEX-BT-TRIGGER,CODEX-WIRELESS2,CODEX-WIRELESS3}.md`.
- Archived T160, T170 and T180 `RESULT.md`.
- T190 manifest; `WirelessProbeService.java`, `AaSessionService.java`; protocol facades including `GalReceiver`, `BluetoothEndpoint`, `CarWifi`, `WifiProjectionEndpoint`.
- `G/proto/{Protos,WifiDiscoveryProtos}.java`; stock protocol, transport factory, TCP delegate/transport and Honda integration.
- Honda exported Bluetooth services, Bluetooth state machine, HFP proxy, AA state, hotspot state and Wi-Fi interface.
- Framework Bluetooth adapter/device/profile/advertiser, secure-mode service, Wi-Fi/P2P APIs and connectivity permission helper.
- Pinned open-headunit WPP messages/state machine/server/policies, QR/link builders, wake/HFP policies, legacy launcher, discovery policy and Nearby implementation.
- Relevant `A/oaa` Wi-Fi/control schemas, including their retraction notices.
- Selected T180 capture markers and saved capability files.
- Public primary sources linked throughout.
- Preservation exception: a broad search unexpectedly matched embedded key-bearing decompiled source; see item 10.

**2. Files changed**

None.

**3. Commands run**

Read-only command families:

- `Get-Content` for rules, reports and numbered source excerpts.
- `rg --files`, scoped filename discovery.
- `rg -n`, `rg -l`, `rg -n -o` for protocol, permissions, services, wireless integration and sanitized capture markers.
- `rg -c` for four T180 markers.
- `Get-ChildItem -Directory decompiled`.
- `Get-FileHash -Algorithm SHA256` twice for five selected rules/source files.
- Public web search/open/find operations.

Some guessed paths and wildcard arguments failed; corrected searches followed. No Git commands, builds, device commands or agent delegation.

**4. Tests run and results**

No executable or live tests ran.

The independent T180 marker count returned:

[Code block omitted; consult project-authored source.]

These count log entries, not completed SDP transactions. The diagnostic source filters its older result marker; T190 adds an earlier reception marker. Evidence: command output above; `J/WirelessProbeService.java:103`, `:163`.

Sanitized capture checks confirmed insecure listening, station pause/restore, wired credential-response markers, pairing-readiness responses, and groups at 2437 and 5180 MHz. Evidence: `L:1063`, `:1066`, `:1075`, `:1447`, `:1473`, `:1827`, `:1850`, `:2091`, `:3248`, `:3290`.

All five before/after hash comparisons matched. Details are in item 10.

**5. Findings — catalogue**

Confidence means:

- **Confident:** established code behavior or recorded evidence.
- **Likely:** a supported engineering inference; this car/phone combination remains unproved.
- **UNKNOWN:** missing runtime evidence, undocumented policy or speculative compatibility.

Effort estimates are judgments: **small** means settings/instrumentation or a narrow change; **medium** means transport/bootstrap integration; **large** means substantial porting, privileged work or additional hardware integration.

Every switch and marker below is a **proposal unless explicitly identified as existing**. A trigger PASS, network PASS and working-AA PASS are different outcomes.

| ID / route | Mechanism and required access | Evidence elsewhere / confidence | Honda calls, Bluetooth and Wi-Fi risk | Effort | One parked test and PASS |
|---|---|---|---|---|---|
| **1. Existing working dongle** | Dongle owns wireless discovery/bootstrap and presents USB AA to Hackura. Ordinary app plus existing USB permission path. | **Confident architecture; supplied working-car context.** [Pi proxy source](https://raw.githubusercontent.com/nisargjhaveri/WirelessAndroidAutoDongle/main/aa_wireless_dongle/package/aawg/src/proxyHandler.cpp); `R/CODEX-WIRELESS.md:234`. | Leaves Honda Wi-Fi out of projection; separate Bluetooth peer can still affect call selection. | Small | `Transport=known dongle`; log USB/session/reconnect stages. PASS: parked picture, controls, sound and Honda call audio after reconnect. |
| **2. Phone developer head-unit server** | Phone listens on **5277**; Hackura connects outward and runs AA over that socket. HU: `INTERNET`; phone: AA developer mode, no demonstrated root requirement. | **Confident documented server; Hackura integration UNKNOWN.** [Google DHU documentation](https://developer.android.com/training/cars/testing/dhu); `K/connection/wifi/DiscoveryModePolicy.kt:5`. | No deliberate HFP interference; occupies a Wi-Fi link. | Medium | Phone’s single `Start head unit server` action, with HU connector already waiting. `DEV_CONNECT`, `AAP_VERSION`, `AAP_TLS`, `FIRST_VIDEO`. PASS: functional AA through 5277. |
| **3. Fresh pairing while listener exists — T190** | Publish AA service before a new Bluetooth bond/profile discovery. Manual Settings pairing; no root needed. | **Likely diagnostic route; mandatory pairing-time discovery UNKNOWN.** Android supports asynchronous/cached SDP; `J/WirelessProbeService.java:103`, `:422`; [SDP contract](https://developer.android.com/reference/android/bluetooth/BluetoothDevice#fetchUuidsWithSdp()). | Temporarily removes that phone’s Honda pairing and associated profile setup. | Small; already prepared | Existing T190 procedure. Require `P6_BOND`, local AA record, actual Honda HFP state, then existing `P4_BT_PHONE_CONNECTED`. Pairing alone fails the trigger test. |
| **4. Honda-owned HFP reconnect** | Use exported `LocalService.connectDevice`: phone state 0, then 2; other profiles −1. Binder interface needed; ordinary-app runtime access **UNKNOWN**. | **Likely best native trigger experiment.** Export and forwarding exist: `H/resources/AndroidManifest.xml:401`; `LocalService.java:211`; `BluetoothState.java:359`. | Deliberate brief hands-free interruption; Honda policy can refuse. Avoids implementing a competing HFP owner. | Small–medium | `Wake=Honda HFP reconnect once`. Log bind/request acceptance and actual vendor transitions. PASS: AA RFCOMM accepted **and** Honda HFP restored. |
| **5. QR/setup-link provisioning** | Phone consumes AA’s setup link carrying network, WPP TCP endpoint and connected-car Bluetooth identity. HU needs WPP TLS server and reachable network; phone resolver compatibility UNKNOWN. | **Confident implementation exists; target-phone behavior likely, unproved.** `N/ProjectionDeepLink.kt:6`, `:24`, `:74`; [public source](https://raw.githubusercontent.com/andreknieriem/open-headunit/main/app/src/main/java/com/andrerinas/openheadunit/connection/wifi/modes/nativeaa/ProjectionDeepLink.kt). | Avoids raw HFP sockets; incorrect/stale enrollment can leave a bad per-car endpoint. Stable Wi-Fi identity matters. | Medium–large | `Provisioning=setup QR`, on an already established fixed network. `QR_ACCEPTED`, `WPP_TCP_ACCEPT`, `WPP_TLS_OK`, `AAP_TCP_ACCEPT`. PASS: WPP arrives without an AA RFCOMM accept. |
| **6. Remembered WPP-over-TCP endpoint** | First teach endpoint through `WifiVersionRequest.wpp_info`; later phone opens TCP control connection, then projection TCP. Ordinary sockets plus TLS implementation. | **Confident implementation; target support UNKNOWN.** `N/WppMessages.kt:51`; `WppTcpServer.kt:32`, `:101`, `:405`. | Avoids repeated AA RFCOMM bootstrap; stale network identity can obstruct fallback. Bluetooth presence may still be required. | Medium–large | `Advertise WPP endpoint=on`, after a successful RFCOMM bootstrap. PASS: next reconnect reaches WPP TCP before any new AA RFCOMM session. |
| **7. Phone companion helper** | Phone app discovers HU via mDNS/P2P/passive trigger and invokes phone-side wireless startup. HU listens for projection or supports the helper’s server mode. | **Confident project route; version-dependent.** [Wireless Helper source project](https://github.com/andreknieriem/wireless-helper); `K/connection/wifi/DiscoveryModePolicy.kt:18`. | No required raw Honda HFP takeover; phone background restrictions and network switching remain. | Medium | `Phone helper=manual start`; fixed network. Log helper trigger separately from TCP arrival. PASS: actual AA session, not “intent sent.” |
| **8. HU joins phone hotspot / shared router** | Change network topology, then use developer server/helper or an explicit reachable receiver endpoint. HU is an ordinary station. | **Confident supported by HUR instructions; native WPP phone-AP behavior UNKNOWN.** [HUR publisher instructions](https://play.google.com/store/apps/details?hl=en&id=gb.xxy.hr); `DiscoveryModePolicy.kt:25`. | Honda station connection changes; phone hotspot costs power. No inherent HFP change. | Small–medium | `Network=phone hotspot`, keeping an already passing developer-server flow. PASS: same AA session works with HU as client. |
| **9. Honda hotspot enabled manually** | Honda Settings owns AP startup; Hackura reads/receives its configuration and advertises the live endpoint. No HU root needed for the manual switch. | **Confident OEM startup path; AA over it UNKNOWN.** `H/.../HotspotState.java:154`, `:172`. | Honda hotspot startup disables station Wi-Fi; affects existing network use. | Medium | Single Honda `Hotspot=on` switch, with a passing trigger held fixed. `AP_READY`, `CLIENT_JOINED`, `AAP_TCP_ACCEPT`. PASS: projection over this AP. |
| **10. Automatic Honda soft AP** | Reflect hidden `setWifiApEnabled`. Requires Wi-Fi change permission and tether permission path; may require system/signature access. | **UNKNOWN on Honda.** `F/net/wifi/WifiManager.java:636`; `F/net/ConnectivityManager.java:676`; [5.1 service implementation](https://raw.githubusercontent.com/LineageOS/android_frameworks_opt_net_wifi/cm-12.1/service/java/com/android/server/wifi/WifiServiceImpl.java). | Same Wi-Fi mode change as row 9; provisioning or OEM policy may refuse. | Medium | `AP start=app request once`; log permission/result/state. Capability PASS requires actual enabled AP; wireless PASS additionally requires AA. |
| **11. Persistent P2P group** | Reuse group credentials and address instead of deleting/recreating identity. Hidden persistent-group APIs exist; reliable GO reinvocation on API22 UNKNOWN. | **Likely useful for reconnects.** `F/net/wifi/p2p/WifiP2pManager.java:596`; `WifiP2pConfig.java:41`; `N/WppEndpointPolicy.kt:23`. | Retains saved network state; recovery/cleanup differs from current disposable groups. | Medium; possibly privileged fallback | `Group lifetime=persistent`. Log only identity-equality booleans across two bring-ups. PASS: stable network and successful reconnect. |
| **12. STATIC versus DYNAMIC AP declaration** | Tell phone whether credentials should persist. This is a WPP enum, not the AP technology or DHCP mode. No extra privilege. | **Confident enum/code; phone persistence semantics likely.** `O/app/src/main/proto/wireless.proto:17`; `N/WppEndpointPolicy.kt:38`. | Wrong STATIC declaration can retain obsolete credentials. | Small after bootstrap works | `AP type=STATIC` only on a measured stable network. PASS: repeat connection with unchanged identity; first-start success alone does not prove persistence. |
| **13. Reset only this AA car association** | Forget AA’s car entry, enable accepting new cars, repeat wired enrollment with live Wi-Fi service. Phone Settings only. | **Likely diagnostic; exact stored eligibility UNKNOWN.** [Google setup guidance](https://developer.android.com/training/cars/testing/dhu); `J/AaSessionService.java:843`, `:871`. | Loses that entry’s setup preferences; Bluetooth bond need not be the same reset. | Small | One phone `Forget this car` action, then fixed enrollment procedure. PASS: new wireless-start behavior with identical HU configuration. |
| **14. Phone-side SDP refresh** | Ask **phone → HU** for services, with listener alive; cancel concurrent discovery and allow completion. Phone diagnostic app needs applicable Bluetooth permission. | **Confident API mechanism; cache invalidation not guaranteed.** [SDP contract](https://developer.android.com/reference/android/bluetooth/BluetoothDevice#fetchUuidsWithSdp()); `F/bluetooth/BluetoothDevice.java:378`. | Small discovery load; no intentional profile disconnect. | Small | `Remote SDP probe=once`. PASS: fresh over-air response containing AA plus RFCOMM channel; callback alone is insufficient. |
| **15. One Bluetooth radio cycle** | Restart HU Bluetooth, reopen listener after ON, allow Honda to reconnect. API22 needs `BLUETOOTH_ADMIN`; current T190 manifest lacks it. | **Likely callable; wireless benefit UNKNOWN.** `decompiled/Services/.../BluetoothManagerService.java:704`, `:726`; `P/AndroidManifest.xml:16`. | Drops **all** Bluetooth connections and call availability during cycle. | Small–medium | `Wake=one radio cycle`. Log adapter states, listener reopening, HFP recovery and AA accept. PASS requires both AA trigger and recovered HFP. |
| **16. Raw HFP-AG poke with hold** | HU opens phone HFP-AG RFCOMM; hold about 15 seconds. AT SLC only when deliberately standing in for absent real HFP. Public socket API, `BLUETOOTH`. | **Confident open-headunit mechanism; Honda success UNKNOWN.** `N/NativeAaHandshakeManager.kt:1994`, `:2081`, `:2443`; `N/HfpSlcInitiator.kt:25`. | Can displace Honda hands-free; hold/AT success does not preserve call audio. | Medium | `Wake=HFP hold`, no fallback target. Log connect, AT OK/error counts, independent AA accept and HFP restoration. PASS requires recovered Honda calls. |
| **17. Raw HSP-AG poke with hold** | Open phone HSP-AG and hold; no HFP BRSF/CIND sequence. Public RFCOMM API. | **Confident related implementations; Honda benefit UNKNOWN.** `N/BluetoothWakePolicy.kt:33`, `:43`, `:48`; [dongle Bluetooth code](https://raw.githubusercontent.com/nisargjhaveri/WirelessAndroidAutoDongle/main/aa_wireless_dongle/package/aawg/src/bluetoothHandler.cpp). | HSP can displace the same hands-free connection; different UUID does not imply isolation. | Small–medium | `Wake=HSP hold`, changing only hold relative to brief-poke baseline. PASS: AA accept and Honda HFP restored. |
| **18. Dummy HF/HSP service** | Publish a standard headset/hands-free record and implement its opening dialogue to satisfy phone presence checks. Public listener API can attempt it. | **Confident fallback architecture; unsuitable default here.** `N/HfpServiceRecordPolicy.kt:7`, `:24`; [Pi releases](https://github.com/nisargjhaveri/WirelessAndroidAutoDongle/releases). | High call risk: app may win a call connection without implementing SCO audio. | Medium–large | `Dummy profile=on` only in a dedicated parked experiment with known real-HFP state. PASS requires AA **and** verified Honda call recovery; duplicate-record visibility alone fails. |
| **19. BLE AA advertisement** | Advertise AA service UUID while classic AA listener remains available. API21 advertiser; hardware peripheral support required. | **Confident dongle implementation; Honda advertising capability UNKNOWN.** [Bluetooth source](https://raw.githubusercontent.com/nisargjhaveri/WirelessAndroidAutoDongle/main/aa_wireless_dongle/package/aawg/src/bluetoothHandler.cpp); `F/bluetooth/BluetoothAdapter.java:207`. | Radio coexistence/load; no intentional HFP takeover. | Small–medium | `BLE advertisement=on`. First capability/advertiser-result markers. Unsupported = NOT TESTABLE; PASS needs subsequent AA RFCOMM/bootstrap. |
| **20. HU initiates phone AA RFCOMM** | Reverse normal connection direction to a phone-advertised AA UUID. Public client socket API; first establish actual remote service/channel. | **UNKNOWN normal-phone support.** `F/bluetooth/BluetoothDevice.java:525`; normal dongle awaits incoming AA, [aa-proxy source](https://raw.githubusercontent.com/aa-proxy/aa-proxy-rs/main/src/bluetooth.rs). | Extra ACL/socket attempt; phone may offer no service or wrong protocol role. | Small probe; unknown integration | `AA socket direction=outgoing`, only after remote evidence. PASS requires valid WPP response, not socket connection alone. |
| **21. Service label / adapter identity / class of device** | Test label, then adapter naming convention, then CoD separately. Label is listener argument; adapter rename needs admin access; no suitable public CoD setter established. | **UNKNOWN universal checks; dongle-name branching is implemented in current research.** `N/ProjectionDeepLink.kt:26`; `F/bluetooth/BluetoothAdapter.java:358`. | Rename/CoD can alter Honda identification or phone classification. | Small label test; large CoD work | `Service label=reference label` as the first isolated test. PASS: repeatable AA-start change with unchanged UUID/security. CoD requires a separate privileged experiment. |
| **22. Repair SDP publication / secure-manager policy** | Compare actual remote record with local registration; repair stack/record filtering only if demonstrated. Public listener first; native record edits/internal secure permission need privileged access. | **Confident permission barrier; active filtering UNKNOWN.** `F/app/BluetoothSecureManagerService.java:28`, `:139`; `F/bluetooth/BluetoothAdapter.java:700`. | Privileged changes can affect Honda’s whole Bluetooth policy. | Small diagnostics; large repair | `SDP diagnostic=on`; PASS: remote AA record and usable channel. Do not treat disabling an unproved filter as the initial test. |
| **23. Honda AA connection-state service** | Use exported `BluetoothConnectionService.startConnection(1,true,…)`, matching stock AA integration. Binder access likely, runtime UNKNOWN. | **Confident code path.** `H/.../BluetoothConnectionService.java:46`, `:74`; manifest `:643`. | Broader than HFP reconnect: AA state affects discoverability, profile priorities, hopping and A2DP. | Medium | `OEM integration=AA state`. Log state entry/exit, profile transitions and restoration. PASS: AA starts and previous Honda policy is restored. |
| **24. Wired session requests wireless switch** | Search/use an explicit GAL transport-switch message rather than Bluetooth bootstrap. No such callable method/message established in this library. | **UNKNOWN viable route; examined API argues against a simple switch.** `G/proto/Protos.java:2185`, `:49559`, `:50224`; `G/protocol/WifiProjectionCallbacks.java:4`. | Session replacement/duplicate-session risk if an undocumented message is guessed. | Unknown/large | `Wired handoff=explicit request` is **not implementation-ready**. First PASS prerequisite: identify a real message ID, schema and phone handler; no justified live packet test yet. |
| **25. WPP type-11 setup information** | Newer RFCOMM setup message can carry WPP endpoint/AP information. Still requires a working RFCOMM carrier. | **Confident schema exists; usable sender UNKNOWN.** `O/app/src/main/proto/wireless.proto:217`; implementation deliberately never sends it. | Can persist a bad endpoint; unknown fields/token semantics. | Large | `WPP setup-info=on` only after a complete verified encoder exists. PASS: phone accepts setup and reconnects; not a solution to absent RFCOMM. |
| **26. Tasker/MacroDroid automation** | Automate a passing helper, supported link or manual receiver connection. Does not independently create AA permission/eligibility. | **Confident automation surface.** [Wireless Helper](https://github.com/andreknieriem/wireless-helper); [open-headunit automation](https://github.com/andreknieriem/open-headunit/wiki/Automation). | Depends on underlying route; background and UI restrictions remain. | Small after manual PASS | `Automation=Bluetooth-connected event`. PASS: repeats the previously passing manual sequence without intervention. |
| **27. Rooted-phone startup workaround** | Restore the phone’s legacy wireless-start component, then use helper flow. Phone root/system authority; HU can remain ordinary app. | **Likely version-specific workaround, not a universal fix.** [open-headunit wireless documentation](https://github.com/andreknieriem/open-headunit/wiki/Wireless). | Changes phone component policy; updates may overwrite behavior. Honda risks follow helper topology. | Medium | Dedicated rooted test phone, `Legacy startup=enabled`. PASS: helper works on the same AA version/network where it previously failed. |
| **28. Pi / aa-proxy USB dongle** | Linux owns BT/Wi-Fi; gadget USB forwards AA bytes to Hackura. Root/configuration on external board; no new HU signature permission. | **Confident supported architecture.** [Pi project](https://github.com/nisargjhaveri/WirelessAndroidAutoDongle), [aa-proxy](https://github.com/aa-proxy/aa-proxy-rs). | Extra hardware, boot/power/USB recovery; Bluetooth call selection still matters. | Medium | `Transport=DIY dongle`. PASS: existing USB receiver path works, including reconnect and Honda calls. |
| **29. External Bluetooth bootstrap relay** | Separate radio relays WPP bytes while projection connects directly to HU Wi-Fi. ESP32 implementation uses classic BT ↔ BLE GATT. | **Confident implementation; supplied app requires API23+, so no drop-in API22 fit.** [Relay project](https://github.com/kendrickkim/aa-native-bt-broker-for-openheadunit). | Relay’s HF role can compete for phone calls; extra pairing/radio dependency. | Large API22 port | `Bluetooth backend=relay`. PASS: relayed WPP, direct HU projection and Honda calls. API22 compatibility must be established first. |
| **30. Other USB gadget hardware / spare phone** | Replace Pi with a board or rooted Android device capable of presenting the required accessory endpoints and proxying traffic. Needs a real USB device controller and kernel support. | **Confident Linux gadget foundation; specific alternatives UNKNOWN.** [Kernel gadget requirements](https://docs.kernel.org/usb/gadget_configfs.html). | Wrong USB role/kernel support blocks it; external firmware and power complexity. | Large | `Transport=alternate gadget`. First PASS: correct USB enumeration and bidirectional AA traffic; then functional session/calls. |
| **31. AutoKit-style proprietary USB box** | Vendor box owns wireless side; vendor Android app handles proprietary USB protocol. Different from a transparent AA dongle. | **Confident manufacturer architecture; exact AA product/Honda integration UNKNOWN.** [AutoKit instructions](https://www.carlinkit.com/autokit.html). | Alternative app may not preserve Hackura controls/audio integration; USB ownership conflicts. | Medium–large | Separate `Receiver backend=vendor box`. PASS: parked AA plus required Honda controls/calls; ordinary box detection is insufficient. |
| **32. Google Nearby helper tunnel** | Companion and HU relay stream payloads through Nearby Connections. Needs compatible Google services and phone startup path. | **Confident implementation; Honda services/AA compatibility UNKNOWN.** `K/connection/wifi/modes/helper/NearbyManager.kt:65`, `:455`, `:549`. | Additional radio/service dependency; same phone-start restrictions as helper route. | Large | `Helper transport=Nearby`. PASS: authenticated stream, actual AA and sustained audio/video. |
| **33. Reuse stock TCP receiver code** | Adapt stock `TcpTransport`/`TcpDelegate` or equivalent stream handling into Hackura. Ordinary sockets; does not supply phone discovery. | **Confident reusable code exists; stock caller disables TCP.** `G/transport/TransportFactory.java:85`; Honda `integration/ConnectionManager.java:33`. | Session lifecycle and audio/control regressions; no inherent HFP change. | Medium | `Projection transport=TCP`. PASS: real version/TLS/video/input exchange over a socket, not the current short probe. |
| **34. Wireless AA through wired CarPlay converter** | External device accepts wireless AA and presents wired CarPlay to the original receiver. Requires functioning wired CarPlay support. | **Confident commercial architecture; this car’s compatibility UNKNOWN.** [Manufacturer CP2A specification](https://www.carlinkit.com/carlinkit4.0-cp2a). | Bypasses Hackura receiver integration; converter controls audio/calls/translation. | Medium hardware evaluation | Separate `Receiver=CarPlay converter`. PASS: AA picture/input/audio/calls through stock CarPlay. Decompiled CarPlay references alone do not establish compatibility. |

**Details that materially change the ranking**

**Discovery, caches and the phone’s car record**

The head unit’s `fetchUuidsWithSdp()` queries **the phone’s services**. It does not show whether the phone discovered Hackura. A `true` result can mean an initiated request or cached-result delivery; requests can queue behind bonding/inquiry. Consequently, repeating that call is not a demonstrated fix for the phone’s HU-service cache. Evidence: `F/bluetooth/BluetoothDevice.java:378`; [Android API contract](https://developer.android.com/reference/android/bluetooth/BluetoothDevice#fetchUuidsWithSdp()).

Plausible refresh experiments, each separate, are: fresh pairing with listener already present; a phone-side SDP request; phone Bluetooth restart; AA car-entry reset; or process/device restart. A universal cache-flush API or guaranteed “refresh trick” was **not established** in the inspected `BluetoothDevice` API. Evidence: `F/bluetooth/BluetoothDevice.java:245`, `:295`, `:378`; [API contract](https://developer.android.com/reference/android/bluetooth/BluetoothDevice#fetchUuidsWithSdp()).

**Whether AA’s record must exist at pairing time is UNKNOWN.** Starting it first is a good controlled test, not proof of a requirement. The ordinary public listener registers a service dynamically, while the SDP API explicitly accommodates cached discovery. Evidence: `F/bluetooth/BluetoothAdapter.java:700`; [SDP contract](https://developer.android.com/reference/android/bluetooth/BluetoothDevice#fetchUuidsWithSdp()).

There is also no established universal AA device-name, service-label or CoD requirement. However, open-headunit’s newer setup-link code explicitly distinguishes dongle-looking Bluetooth names from head-unit identities. That supports treating **dongle classification** as a real research branch; it does not justify renaming Honda to impersonate a dongle without testing the changed association semantics. Evidence: `N/ProjectionDeepLink.kt:26`, `:126`.

The exact phone database flag meaning “this car is wireless-capable” remains **UNKNOWN**. The examined old car-information schema exposes `session_configuration`, but no explicit wireless-supported field. Wired service 14 supplies network identity, and the credentials response supplies credentials; neither supplies the WPP TCP endpoint. Evidence: `G/proto/Protos.java:4764`, `:5928`, `:49560`, `:50225`.

The separate public protocol research describes credential persistence into phone car records, but labels parts of that reconstruction with limited confidence. It is evidence of a candidate persistence path, not direct proof of this phone’s stored state. Evidence: `A/oaa/wifi/WifiCredentialsResponseMessage.proto:14`, `:26`.

**AA version changes**

The open-headunit and Wireless Helper maintainers report that **AA 17.4+ restricts legacy third-party startup**, while native Bluetooth negotiation and the developer server remain offered routes. Wireless Helper also reports an earlier restriction affecting Android 10 and below with AA 16.4+. These are maintainer compatibility findings; the target phone’s versions and feature flags remain UNKNOWN. [Wireless Helper project](https://github.com/andreknieriem/wireless-helper), [open-headunit wireless guide](https://github.com/andreknieriem/open-headunit/wiki/Wireless).

A controlled second-phone/version comparison is therefore useful. It should change the phone/version only, with the same HU listener, network and trigger. Success on one version would establish a compatibility boundary, not identify its internal cause. This is a proposed experiment based on the version-specific reports above.

**Bluetooth triggers and Honda calling**

T190 retains the brief HSP nudge: secure connection attempt, approximately three-second deadline, then immediate close. It does **not** test a 15-second HFP hold or the open-headunit SLC exchange. Evidence: `J/WirelessProbeService.java:198`, `:223`; `N/NativeAaHandshakeManager.kt:2443`; `N/HfpSlcInitiator.kt:25`.

The HFP exchange in that implementation is BRSF → CIND test → CIND read → CMER, followed by indicator polling. Its state machine advances on `ERROR` as well as `OK`; an “established” marker alone therefore overstates evidence of a successful negotiated profile. Evidence: `N/HfpSlcInitiator.kt:25`, `:71`, `:77`.

The same source records an HSP poke leaving a hands-free link down for minutes, similar to HFP. This directly counters the assumption that HSP is harmless merely because its UUID differs. Evidence: `N/BluetoothWakePolicy.kt:35`.

Honda’s real client profile is Broadcom **profile 100**, whereas standard `HEADSET_CLIENT` is 16. A port that checks only profile 16 could wrongly conclude Honda HFP is absent and create a competing connection. Evidence: `F/bluetooth/BluetoothProfile.java:17`, `:19`; `H/sources/com/honda/settings/btservice/proxyhandlers/BluetoothHFPProfile.java:65`, `:136`.

BLE support is only partially established: the captured feature list advertises BLE, but no peripheral/advertiser capability result was found. Framework advertiser access returns unavailable unless multiple-advertisement or peripheral support exists. **Chipset advertising support is UNKNOWN.** Evidence: capability `features.txt:5`; `F/bluetooth/BluetoothAdapter.java:207`, `:511`, `:527`.

HFP is also not a universal dongle prerequisite: the Pi project introduced a mode without fake HSP, then changed its default back because of reliability problems. This is a useful counterexample to both “HFP SLC is always required” and “dongle mode always fixes startup.” [Project release history](https://github.com/nisargjhaveri/WirelessAndroidAutoDongle/releases).

**The wired-session question: complete message inventory found**

| Location | Wireless-relevant contents | Consequence |
|---|---|---|
| T190 `WifiProjectionEndpoint` | Native init/shutdown; credential-request callback only | No exposed start/switch method. `P/source/com/google/android/projection/protocol/WifiProjectionEndpoint.java:15`, `:33`. |
| Stock Wi-Fi GAL message enum | Credentials request `0x8001`, response `0x8002` | No switch request in this enum. `G/proto/Protos.java:2185`. |
| Stock `WifiProjectionService` | One network-identity field | No endpoint port/IP. `G/proto/Protos.java:49559`. |
| Stock `WifiCredentialsRequest` | Empty request | Requests credentials only. `G/proto/Protos.java:49919`. |
| Stock `WifiCredentialsResponse` | Password, security mode, network identifier | No endpoint/start command. `G/proto/Protos.java:50224`. |
| Stock discovery type 1 | `WifiStartRequest`: IP and port | **A real start request exists, but in WPP discovery**, not as the wired GAL credential response. `G/proto/WifiDiscoveryProtos.java:1381`. |
| Stock discovery types 2/3 | Info request/response; response carries network credentials/security | Separate WPP bootstrap exchange. `WifiDiscoveryProtos.java:2276`, `:2581`. |
| Stock discovery types 4/5 | Version/channel negotiation; response also has status/device metadata | Older schema lacks modern `wpp_info`. `WifiDiscoveryProtos.java:312`, `:787`. |
| Stock discovery types 6/7 | Connection status; start response with endpoint/status | Diagnostic/response messages, not another wired switch. `WifiDiscoveryProtos.java:1798`, `:3120`. |
| Modern open-headunit WPP | Start reason; channel list; car info; `wpp_info`; ping 8/9; rejection 10; setup 11 | Additional discovery/control protocol, not evidence these can be injected into wired GAL. `O/app/src/main/proto/wireless.proto:65`, `:135`, `:190`, `:201`, `:221`. |

The old library also contains `WIFI_PORT=30515`. No examined Honda call site enabled a TCP listener using it: Honda builds its transport factory without setting a TCP port, and the factory includes TCP only when that value is positive. **A constant is not evidence the phone will dial that port.** Evidence: `G/proto/Protos.java:3755`; `G/transport/TransportFactory.java:85`; Honda `integration/ConnectionManager.java:33`.

Two tempting public-schema leads are explicitly **retracted**: `WifiDirectConfigData.proto` and `ConnectionConfigurationData.proto`. `WirelessTcpConfigurationData.proto` describes socket tuning and is unverified for the analysed modern APK. They provide no reliable hidden wired-switch recipe. Evidence: `A/oaa/wifi/WifiDirectConfigData.proto:5`; `A/oaa/control/ConnectionConfigurationData.proto:5`; `A/oaa/common/WirelessTcpConfigurationData.proto:18`.

**Verdict: a no-Bluetooth wired-to-wireless switch command is UNKNOWN, and no implementation-ready command was found.** Credentials delivered during USB are not sufficient evidence of such a transition.

**WPP over TCP and QR provisioning**

Open-headunit separates **WPP control port 5299** from **projection port 5288**. The phone first connects to the control endpoint; that exchange advertises the projection endpoint. These are implementation choices carried in protocol fields, not immutable port requirements. Evidence: `N/WppTcpServer.kt:101`, `:405`, `:414`; `J/WirelessProbeService.java:43`.

Its accepted WPP TCP socket is wrapped in TLS **client mode on the head-unit side**, despite the HU being the TCP listener. Then the same WPP message/state machine runs over it. Merely opening a plaintext 5299 listener would not reproduce this implementation. Evidence: `N/WppTcpServer.kt:253`, `:263`, `:266`, `:382`.

The implementation announces WPP **4.2**; comments report endpoint acceptance restrictions below 4.1 and a make allowlist at exactly 4.1. That behavior is **likely**, based on this project’s reconstruction; target-phone verification remains absent. Evidence: `N/WppHandshakeSession.kt:164`; `N/WppMessages.kt:79`.

There are two plausible enrollment paths:

- A successful RFCOMM version exchange carries `wpp_info`.
- A setup QR/link carries network details and endpoint directly, avoiding that first RFCOMM exchange.

Evidence: `N/WppMessages.kt:64`; `N/ProjectionDeepLink.kt:74`.

**“Without Bluetooth” needs qualification.** These mechanisms can remove **AA RFCOMM bootstrap**. The setup-link implementation still requires a connected Bluetooth identity to associate the car. Operation with the phone’s Bluetooth radio completely off is **UNKNOWN**. Evidence: `N/ProjectionDeepLink.kt:15`, `:52`.

A stable network is central to unattended reconnects. The source withholds remembered endpoints until identity repeats, and warns that stale endpoints can be preferred over Bluetooth fallback. QR enrollment is restricted to its hotspot strategy. Evidence: `N/WppEndpointPolicy.kt:23`, `:51`; `N/ProjectionQrPolicy.kt:63`.

**Network variants**

T180 already produced 5 GHz groups without AA RFCOMM acceptance. Further band changes cannot by themselves explain that earlier missing connection. Evidence: `L:1850`, `:3290`; marker-count output in item 4.

T190 currently sends **DYNAMIC** in its RFCOMM credential response, appropriate for disposable groups. STATIC is a persistence declaration; it should be tested after identity stability, not used as an unsupported first-start cure. Evidence: `J/WirelessProbeService.java:462`; `N/WppEndpointPolicy.kt:38`.

API22 exposes persistent-group enumeration/deletion and a network ID in `WifiP2pConfig`, but the inspected `createGroup()` takes no stored-group ID or explicit credentials. Stable autonomous GO recreation through this API remains **UNKNOWN**; retaining a group for one session is easier than guaranteeing identity across boots. Evidence: `F/net/wifi/p2p/WifiP2pManager.java:486`, `:596`, `:601`; `WifiP2pConfig.java:41`.

For soft AP, reflection does not bypass service permission checks. Honda’s connectivity helper chooses `CONNECTIVITY_INTERNAL` when provisioning is configured, otherwise `CHANGE_NETWORK_STATE`. The actual Honda Wi-Fi service/provisioning configuration was not available, so ordinary-app automatic AP startup remains **UNKNOWN**. Evidence: `F/net/ConnectivityManager.java:676`; [comparable 5.1 service checks](https://raw.githubusercontent.com/LineageOS/android_frameworks_opt_net_wifi/cm-12.1/service/java/com/android/server/wifi/WifiServiceImpl.java).

Joining the **phone’s hotspot is supported by helper/developer-server architectures**. It is not established that native AA’s ordinary “phone joins car AP” flow automatically reverses roles. A shared router is likewise a network carrier, not a startup trigger. [HUR publisher instructions](https://play.google.com/store/apps/details?hl=en&id=gb.xxy.hr), `K/connection/wifi/DiscoveryModePolicy.kt:25`.

**Phone helpers and hardware**

The developer-server path reverses TCP direction: **HU → phone:5277**. The legacy helper path typically causes **phone → HU projection listener**. A head-unit listener on 5277 would implement neither correctly. Evidence: [Google DHU documentation](https://developer.android.com/training/cars/testing/dhu); `K/connection/self/launchers/SelfLauncherLegacy.kt:30`.

The AAWireless companion app is documented as adapter setup, troubleshooting, firmware and configuration software. That is not evidence it can turn Hackura into an AAWireless adapter or provide a generic startup trigger. [Publisher listing](https://play.google.com/store/apps/details?hl=en-US&id=app.aawireless).

A Pi proxy would replace the existing dongle’s wireless/USB bridge. Hackura would continue contributing its receiver, display/input/audio integration and device handling; it would not need to own the Pi’s Bluetooth bootstrap. The car remains USB host, the Pi USB device. [Proxy implementation](https://raw.githubusercontent.com/nisargjhaveri/WirelessAndroidAutoDongle/main/aa_wireless_dongle/package/aawg/src/proxyHandler.cpp), [supported gadget hardware](https://github.com/nisargjhaveri/WirelessAndroidAutoDongle).

An external Bluetooth-only relay is more unusual and potentially useful: keep Honda’s troublesome AA SDP path out of bootstrap while receiving projection directly over HU Wi-Fi. However, the published ESP32 route has an API23 app requirement and an HF role; API22 porting and call behavior are unresolved. [Relay implementation](https://github.com/kendrickkim/aa-native-bt-broker-for-openheadunit).

**Honda-specific reuse**

The firmware contains **generic Google wireless-capable building blocks**: Wi-Fi credential endpoint, WPP discovery schemas, TCP delegate/transport and wireless ping timing. Honda’s examined integration does not register the Wi-Fi endpoint or enable its TCP factory path. Evidence: `G/protocol/WifiProjectionEndpoint.java:4`; `G/protocol/GalReceiver.java:300`; Honda `integration/AbstractGalIntegration.java:103`; `integration/ConnectionManager.java:33`.

Scoped Java/XML/smali searches found no additional wired-wireless switch, WPP TCP endpoint enrollment, wireless CarPlay or iAP2-over-Wi-Fi integration outside those generic AA classes. **This is a bounded negative result, not proof the complete firmware lacks it.** The available `decompiled/` inventory has CarPlay-facing SystemUI interfaces, but no full standalone CarPlay decompilation. Native services/libraries were not exhaustively analysed in this review.

ZLink/FYT/HCT-style vendor Bluetooth backends work through specific daemon/module interfaces; Honda’s Broadcom HFP implementation does not establish one of those interfaces exists here. Reusing such a backend is **UNKNOWN**, not a generic solution for all Android head units. [Open-headunit backend documentation](https://github.com/andreknieriem/open-headunit/wiki/Wireless).

**6. Primary evidence and ranked test plan**

The catalogue attaches primary code locations or public sources to each mechanism. The decisive local findings are:

| Finding | Primary evidence |
|---|---|
| Wi-Fi groups at both bands; no observed AA socket arrival | `L:1075`, `:1850`, `:3290`; four-marker count output in item 4 |
| T190 is still a network probe | `J/WirelessProbeService.java:401`, `:403`, `:409` |
| Hackura session currently constructs USB transport | `J/AaSessionService.java:57`, `:702` |
| Wired Wi-Fi endpoint has no exposed switch operation | `G/protocol/WifiProjectionEndpoint.java:9`, `:37`; `G/proto/Protos.java:2185` |
| Ordinary exported Honda HFP request path exists | `H/resources/AndroidManifest.xml:401`; `H/.../LocalService.java:211`; `H/.../BluetoothState.java:368` |
| QR can carry the endpoint without AA RFCOMM | `N/ProjectionDeepLink.kt:6`, `:74`; runtime target support UNKNOWN |
| WPP TCP needs its own TLS/control implementation | `N/WppTcpServer.kt:263`, `:405` |
| BLE advertising capability remains unproved | Saved `features.txt:5`; `F/bluetooth/BluetoothAdapter.java:215` |

**Ranking for obtaining working AA:** existing dongle first; direct TCP via developer server next; ordinary native discovery with T190/OEM HFP next; QR/WPP enrollment next. Helpers depend heavily on phone version. Raw profile takeover, privileged Bluetooth changes and proprietary backend ports rank lower because they add unresolved call/stack behavior. This ranking is engineering judgment, not measured success probability.

**Next three visits — proposals only**

Common preparation should use one fixed listener security mode, one fixed network/band and identifier-free diagnostics. Every test needs separate discovery, bootstrap, projection and restoration verdicts. The existing TCP probe must be replaced by a real session path before any “working wireless AA” verdict. Evidence: `J/WirelessProbeService.java:403`, `:409`; `J/AaSessionService.java:702`.

| Visit | Single experimental change | Required observations | PASS and interpretation |
|---|---|---|---|
| **T200 — prove the Wi-Fi projection path** | Phone Settings: **Start head unit server**. HU connector is prepared beforehand; retain the existing P2P network. | Proposed `T200_DEV_CONNECT`, version/TLS status, first video/audio, input acknowledgement, end reason. | **Projection PASS:** functional parked AA over phone port 5277. Failure distinguishes unreachable server from AA/TLS/session failure. This avoids depending on AA RFCOMM discovery. |
| **T210 — test the real Honda trigger** | **Wake = Honda HFP reconnect once**. Developer server stopped; return to fixed T190 native baseline. | Existing `P6_HFP`, `P6_LOCAL_RECORDS`, `P6_UUID_RX`, `P4_BT_PHONE_CONNECTED`; proposed Binder result and recovery summary. | **Trigger PASS:** phone opens AA RFCOMM after the real OEM transition. **Network PASS:** WPP then projection TCP. **Preservation PASS:** Honda HFP returns and a parked call verifies microphone/speakers. |
| **T220 — bypass AA RFCOMM enrollment** | **Provisioning = setup QR/WPP TCP** on the same already-established network. Do not simultaneously change AP technology or wake method. | Proposed QR acceptance, WPP TCP/TLS, WPP types/status, projection arrival; independently count AA RFCOMM accepts. | **Bootstrap PASS:** WPP TCP arrives without AA RFCOMM. **Projection PASS:** functional AA. Use one held network for the first test; claim persistent reconnect only after separate identity-stability proof. |

T190’s pending result remains a prerequisite to interpretation: if fresh pairing already produces AA RFCOMM, prioritize completing that passing path rather than adding another trigger. T200 still provides useful independent transport validation.

Phone HCI capture can distinguish SDP query, returned AA record/channel, RFCOMM attempt and HFP timing. Enable it as a separate capture-preparation step and keep its configuration fixed across comparisons; do not publish raw traces containing identifiers. [AOSP Bluetooth debugging](https://source.android.com/docs/core/connect/bluetooth/verifying_debugging).

**7. Assumptions**

- Supplied successful dongle use is accurate; its proprietary startup mechanism was not traced.
- T190 source represents the intended pending build; installed-binary parity was not established.
- The default adapter publishing AA corresponds to Honda’s calling identity; runtime confirmation is still needed.
- Public moving branches can differ from pinned local snapshots.
- All proposed experiments are parked specifications, not authorization or execution of live work.

**8. Unresolved uncertainties**

- Phone Android/AA version, feature flags, stored car eligibility and endpoint state.
- Whether the phone queries and receives Hackura’s AA SDP record.
- Actual matching Honda HFP state during each unsuccessful attempt.
- Runtime access to exported Honda services from Hackura.
- BLE peripheral/advertising support on the captured chipset.
- Automatic hotspot permissions, stable P2P identity and sustained Wi-Fi performance.
- Target-phone QR/WPP TLS compatibility and fully Bluetooth-off behavior.
- Undocumented native Honda/CarPlay integration outside the inspected material.
- End-to-end Hackura TCP session behavior: current code intentionally stops at the probe.

**9. Exact diff summary**

None. No files changed.

**10. Preservation checks performed**

Repeated SHA-256 checks returned **all five unchanged**:

| File | SHA-256 |
|---|---|
| `PROJECT-RULES.md` | `1646C941F938598E17199D542B3644EB780815A8A862E4C5E8C2F694A0E625A8` |
| `AGENTS.md` | `BFDE7264965B0D9A68AD8F0A6B667CA55A81D0CB185262781A4FC4629CB6B77F` |
| `P/AndroidManifest.xml` | `F9CD12959B3B56C1F429199221F6DA16A12C90B6C16C33ABC128F41E0CB79CE2` |
| `J/WirelessProbeService.java` | `28C783F2C6A40A33CA1D6CDF34736EEC952091913F9925E5E0D6361FAB5E8710` |
| `J/AaSessionService.java` | `F84B455FF24965D18F24E5A404E93E11841DD1C2898789805402C3C44CFE74F8` |

No filesystem writes, builds, Git operations, device access, milestone actions or guard changes occurred. Frozen artifacts were not rebuilt or modified; their hashes were not rechecked.

**Preservation exception:** an early broad decompiled-source search unexpectedly matched and displayed an embedded private-key constant in certificate-provider source. I stopped that search approach and excluded key/certificate source files thereafter. The material is not reproduced here; the requested no-key-read/no-key-output boundary was not fully preserved.