**The strongest T190 candidate is a verified reconnect through Honda’s real HFP stack, with phone-side SDP evidence.** Open-headunit’s AT exchange is a fallback for units lacking real HFP. Copying it onto Honda could displace working hands-free calling. **Confidence: likely for the recommendation; confident for the inspected code.**

**1. Files inspected**

Paths below use these aliases:

- `O` = `analysis/parallel-aa-receiver/offline-followup/public/open-headunit/andreknieriem-open-headunit-e9377ff`
- `K` = `O/app/src/main/java/com/andrerinas/openheadunit`
- `N` = `K/connection/wifi/modes/nativeaa`
- `J` = `analysis/test-prep/todo-tests-20261103/builds/T180-bundle/source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper`
- `F` = `decompiled/Framework/sources/android`
- `H` = `decompiled/HondaSettings`
- `S` = `decompiled/Services/sources/com/android/server`
- `L` = `analysis/test-prep/runs/helper_20261109T003917_e5372324ccca4b75a22ffd2df56eaff0/longdrive-evidence/rdx_f8722094bd3144dd8af1956995401592/capture.log`

Inspected:

- `PROJECT-RULES.md`, `AGENTS.md`.
- All fourteen requested open-headunit files, including `NativeAaHandshakeManager.kt` from startup through shutdown.
- Supporting `NativeAaWakeDamagePolicy`, `NativeHandoffPolicy`, WPP framing/messages/TCP server, ZBT channel/carrier/wake code.
- `K/connection/wifi/modes/WifiLauncherNative.kt`; Bluetooth and hotspot helpers; manifest; relevant README passages.
- `J/WirelessProbeService.java`, `AaSessionService.registerWirelessAnnounce`, T180 manifest.
- T180/T170 results; archived T160 result; the three earlier Codex reports; relevant entries and marker counts in `L`.
- Framework Bluetooth adapter/device/socket/profile/advertiser, secure-mode manager and connectivity code.
- Honda HFP proxy, Bluetooth receivers/helpers, exported services, AA state and hotspot state; Services Bluetooth manager.
- Public primary sources linked below. Supporting files were inspected selectively.

**2. Files changed**

None.

**3. Commands run**

Read-only command families:

- `Get-Content -LiteralPath PROJECT-RULES.md` and `AGENTS.md`.
- Scoped `rg --files` discovery.
- `rg -n` searches and numbered source reads, bounded with `Select-Object -Skip … -First …`.
- `rg -c` for the four capture markers reported below.
- `Get-FileHash -Algorithm SHA256` twice for three selected evidence files.
- Public web searches, source opens and text searches.

A Python launcher failed; PowerShell reads were used instead. Incorrect initial archive paths and a wildcard search were corrected. Several historical public-source URLs were unavailable. No build, Git or device command ran.

**4. Tests run and results**

No executable tests or builds ran. Static capture checks returned:

| Pattern in `L` | Count |
|---|---:|
| `P5_PHONE_SDP_REQUEST` | 8 |
| `P5_PHONE_SDP_RESULT` | 0 |
| `P4_BT_PHONE_CONNECTED` | 0 |
| `P4_TCP_CONNECTED` | 0 |

These are **log-entry counts**, not counts of completed over-air transactions.

Selected source/evidence files matched their first hashes on the second hash check.

**5. Findings**

**F1 — “HFP SLC is always required” is too strong. Confidence: confident.**

Open-headunit implements that approach, but the Linux dongles provide counterexamples to treating it as a universal requirement:

| Implementation/mode | Implemented startup action |
|---|---|
| open-headunit, normal Android route | Publish AA RFCOMM; optionally poke HFP-AG, then HSP-AG. Initiate HFP AT exchange only when standing in for missing real HFP. |
| WirelessAndroidAutoDongle, phone-first | Register local HSP headset `0x1108`; call BlueZ `ConnectProfile` against phone HSP-AG `0x1112`; await a separate incoming AA RFCOMM connection. |
| WirelessAndroidAutoDongle, dongle mode | Omit fake HSP; advertise AA UUID through BLE; use `ConnectProfile("")` in its connection loop. |
| aa-proxy-rs, ordinary mode | Register HSP headset; optionally initiate phone HSP-AG connection; accept and immediately drop its HSP control stream; await incoming AA RFCOMM. |
| aa-proxy-rs, dongle mode | Skip HSP registration; generally await incoming AA. A special peer-selection branch attempts generic `device.connect()`. |

The dongle code establishes those actions. The phone’s exact proprietary recognition rule remains **UNKNOWN**. BlueZ profile registration/connection is also not equivalent to opening an arbitrary Android RFCOMM socket. [WirelessAndroidAutoDongle Bluetooth implementation](https://github.com/nisargjhaveri/WirelessAndroidAutoDongle/blob/main/aa_wireless_dongle/package/aawg/src/bluetoothHandler.cpp#L103), [daemon sequencing](https://github.com/nisargjhaveri/WirelessAndroidAutoDongle/blob/main/aa_wireless_dongle/package/aawg/src/aawgd.cpp#L15), [aa-proxy connection selection](https://github.com/aa-proxy/aa-proxy-rs/blob/main/src/bluetooth.rs#L5577), [HSP control handling](https://github.com/aa-proxy/aa-proxy-rs/blob/main/src/bluetooth.rs#L7324).

**F2 — Honda already supplies the relevant hands-free role; open-headunit’s guard needs adaptation. Confidence: confident.**

Honda connects through `BluetoothHfDevice.connect(device)`. Its vendor profile is `HF_DEVICE=100`; standard `HEADSET_CLIENT=16` is a different constant. Open-headunit’s HFP guard checks profile 16, optionally profile 1.

A port must therefore avoid interpreting “profile 16 disconnected” as proof that Honda HFP is absent. Whether this firmware mirrors vendor state into standard profile queries is **UNKNOWN**.

Evidence: `H/sources/com/honda/settings/btservice/proxyhandlers/BluetoothHFPProfile.java:58`, `:160`; `F/bluetooth/BluetoothProfile.java:17`, `:19`; `K/utils/BluetoothHelper.kt:102`, `:110`, `:140`.

**F3 — A stock-stack connection request may be reachable from an ordinary app. Confidence: likely; runtime access UNKNOWN.**

Honda’s `btservice.LocalService` is exported, has no component permission in its declaration, and returns its Binder. Its `connectDevice` method forwards to the Bluetooth state machine; no caller-permission check appears on that inspected path.

The state machine explicitly interprets phone state `2` as connect and `0` as disconnect, while `-1` leaves other profiles alone. It still applies Honda’s connection/disconnection policy.

This supports investigating an OEM-mediated HFP reconnect before taking the phone’s HFP channel with raw sockets.

Evidence: `H/resources/AndroidManifest.xml:401`; `H/sources/com/honda/settings/btservice/LocalService.java:211`, `:540`; `H/sources/com/honda/settings/btservice/statemachine/BluetoothState.java:359`.

Honda also exports `BluetoothConnectionService`. Its `startConnection(1,true,…)` enters Honda’s AA state, but that changes discoverability, hopping and profile priorities and can disconnect A2DP. It is not merely a wireless wake command.

Evidence: `H/resources/AndroidManifest.xml:643`; `H/sources/com/honda/settings/bluetooth/BluetoothConnectionService.java:46`, `:74`, `:209`; `H/sources/com/honda/settings/btservice/statemachine/AAState.java:180`.

**F4 — T170’s nudge did not test open-headunit’s HFP SLC path. Confidence: confident.**

T180’s inherited nudge opens **secure HSP-AG**, allows three seconds for connection, sends no AT commands and closes immediately. Open-headunit tries **HFP-AG first**, holds an automatic poke for 15 seconds, and conditionally performs the SLC exchange.

The comment saying the current nudge “never touches Honda’s own call connection” is not an established guarantee. Open-headunit documents HSP and HFP pokes both displacing hands-free links on tested hardware.

Evidence: `J/WirelessProbeService.java:82`, `:136`, `:155`, `:167`; `N/BluetoothWakePolicy.kt:25`, `:35`; `N/NativeAaHandshakeManager.kt:1994`, `:2081`, `:2443`.

**F5 — Missing `P5_PHONE_SDP_RESULT` does not prove no `ACTION_UUID` arrived. Confidence: confident.**

The receiver silently returns when the broadcast has no device or its device does not match `sdpAddress`. Logging occurs **after** that filter. T190 needs an identifier-free reception marker **before** filtering.

Registration already happens before `fetchUuidsWithSdp()`, so “registered too late” is not supported by this source.

Evidence: `J/WirelessProbeService.java:103–115`.

The saved capture contains **eight** request entries, versus seven in the result summary. Some arrive only milliseconds apart. Neither number proves that many independent SDP searches.

Evidence: `L:1735`, `:1747`, `:1841`, `:2621`, `:2633`, `:3281`, `:3831`, `:3842`; marker-count command output above.

**F6 — The Broadcom SDP failure’s cause remains UNKNOWN.**

The local framework method simply returns `IBluetooth.fetchRemoteUuids`. Android documents asynchronous completion, cached fallback results and queued requests during other Bluetooth operations. A `true` return is not proof of completed discovery. [Android API contract](https://developer.android.com/reference/android/bluetooth/BluetoothDevice#fetchUuidsWithSdp()), `F/bluetooth/BluetoothDevice.java:378`.

Plausible explanations include queued/stalled discovery, a vendor completion/broadcast defect, or receipt followed by the application’s filter. These remain **UNKNOWN hypotheses**, not demonstrated Broadcom behavior.

HondaSettings itself registers for standard `ACTION_UUID` and processes its UUID extra. That counters an assumption that Honda intentionally makes this broadcast unavailable in all circumstances.

Evidence: `H/sources/com/honda/settings/btservice/receivers/MainReceiver.java:109`, `:141`.

**F7 — Observe the phone’s query in the phone’s HCI trace. Confidence: confident for the method; availability on this phone UNKNOWN.**

The head unit’s query asks what **the phone advertises**. It does not establish whether the phone discovered **the head unit’s AA record**.

A full Bluetooth HCI trace can distinguish:

- Phone-to-head-unit SDP searches and their responses.
- Presence of the AA UUID and its returned RFCOMM channel.
- Subsequent RFCOMM connection attempts.
- HFP opening/closing around the attempt.

Look for SDP on L2CAP PSM `0x0001`, including service-search/attribute exchanges. Classify the resulting evidence as booleans and status values; do not reproduce identifiers.

Android documents enabling full HCI snoop through Developer options and restarting Bluetooth. Actual export support must be established on the phone. [AOSP Bluetooth debugging](https://source.android.com/docs/core/connect/bluetooth/verifying_debugging).

No incoming-SDP notification to an ordinary app was established in the inspected APIs. `BluetoothSocket.accept()` observes the later RFCOMM connection. The hidden `configHciSnoopLog` wrapper alone proves neither permission nor access to the trace file.

Evidence: `F/bluetooth/BluetoothSocket.java:203`; `F/bluetooth/BluetoothAdapter.java:329`.

**F8 — ZLink-type integration and AutoKit-with-dongle are different architectures.**

- **ZLink-style external Bluetooth — likely:** open-headunit’s executable backend connects to a vendor daemon at loopback port 3152, initializes Android Auto mode, requests reconnect and transports RFCOMM bytes in vendor frames. The daemon owns the module’s RFCOMM server. That explains how an Android app can use Bluetooth outside Android’s ordinary adapter APIs. Evidence: `N/zbt/ZbtByteChannel.kt:14`, `:269`, `:278`, `:294`.
- **Exact ZLink privileges — UNKNOWN:** its original APK manifest, daemon credentials and access policy were not inspected. Open-headunit’s comments report privileged tethering/root-daemon requirements for the examined ZLink AP-start path; that is not independent proof that every ZLink build requires root. Evidence: `N/SoftApCredentialsProvider.kt:39–46`.
- **AutoKit with external product — confident:** the manufacturer describes installing the APK and pairing the phone with the external product; its options explicitly test USB permission and control the box’s wireless band. This does not establish that the head-unit APK owns HFP or needs system signing. Exact firmware wake logic is **UNKNOWN**. [AutoKit installation](https://www.carlinkit.com/autokit.html), [manufacturer’s option descriptions](https://www.carlinkit.com/faq_detail/119.html).
- **Honda applicability — UNKNOWN:** Broadcom HFP does not establish the presence of a ZBT/FYT transport. Open-headunit itself requires measured vendor-route availability rather than assuming all external-Bluetooth units work alike. Evidence: `N/ExternalBtTransportPolicy.kt:55`.

**6. Primary evidence: open-headunit timeline and T190 specification**

The following is **confident about implementation**, not a claim that every phone follows its comments.

1. **Select transport and register credential callbacks.** Native mode constructs the handshake manager and hotspot provider, registers delivery callbacks, then prepares either a quiet P2P group or the unit’s hotspot. `CredentialsHandoff` holds an early result until the consumer exists.  
   Evidence: `K/connection/wifi/modes/WifiLauncherNative.kt:78`, `:311`; `N/CredentialsHandoff.kt:44`, `:55`.

2. **Resolve the offered network.** The hotspot path reads an existing AP, supports manual configuration, resolves interface/IP/address, and attempts automatic enable only as best effort. Hidden configuration getters are called through reflection. This supplies network details; it is not itself the Bluetooth wake.  
   Evidence: `N/SoftApCredentialsProvider.kt:159`, `:420`, `:525`; `K/utils/HotspotConfigReader.kt:24`, `:42`.

3. **Start WPP-over-TCP and select the Bluetooth route.** The manager opens its WPP control server before Bluetooth checks. It then chooses ordinary Android Bluetooth, a measured vendor-module route, or refusal. The inspected WPP control port is **5299**, distinct from projection port **5288**.  
   Evidence: `N/NativeAaHandshakeManager.kt:808`, `:824`, `:860`; `N/WppTcpServer.kt:95`.

4. **Publish the AA RFCOMM server.** UUID `4de17a00-52cb-11e6-bdf4-0800200c9a66`; secure by default, insecure when selected. It uses the public `listenUsing…RfcommWithServiceRecord` APIs. Extra Android-exposed radios receive listeners too.  
   Evidence: `N/NativeAaHandshakeManager.kt:70`, `:927`, `:1238`, `:1298`.

5. **Decide whether dummy HFP is necessary.** Reflectively read local `BluetoothAdapter.getUuids()`. If Hands-Free `0x111e` exists, do not publish a duplicate. Otherwise publish a **secure RFCOMM server** on `0x111e`, with three registration attempts separated by 1.5 seconds. An unreadable UUID list defaults to registering—a portability hazard on Honda.  
   Evidence: `N/HfpServiceRecordPolicy.kt:24`, `:30`; `N/NativeAaHandshakeManager.kt:1313`, `:1339`.

6. **Begin an early or credential-triggered wake.** Early wake overlaps phone startup with network creation. Readiness policy stops, reopens listeners, or permits poking. Target policy uses selected paired phones; widening to every paired phone requires opt-in.  
   Evidence: `N/EarlyWakePolicy.kt:18`; `N/PokeReadinessPolicy.kt:23`; `N/PokeTargetPolicy.kt:22`; `N/NativeAaHandshakeManager.kt:2126`.

7. **Respect existing HFP.** If the target appears connected while real client-role HFP is up, normally stand down. Automatic escalation and radio cycling require that this pairing previously ran native AA here; wired pairing alone does not satisfy that code. After a 90-second stand-down, an eligible cycle is preferred; escalation is budgeted.  
   Evidence: `N/BluetoothWakePolicy.kt:145`; `N/HandsFreeWakeEscalationPolicy.kt:46`, `:72`; `N/BluetoothRadioCyclePolicy.kt:78`.

8. **Make the active poke when permitted.** The head unit becomes an RFCOMM **client**, using secure `createRfcommSocketToServiceRecord`: first phone HFP-AG `0x111f`, then HSP-AG `0x1112`. Automatic hold is 15 seconds; manual hold is 20 seconds; retry gaps are 15 seconds.  
   Evidence: `N/BluetoothWakePolicy.kt:43`; `N/NativeAaHandshakeManager.kt:1994`, `:2001`, `:2443`, `:2584`.

9. **Perform AT negotiation only when standing in for HFP.** Over HFP-AG, send `AT+BRSF=0`, `AT+CIND=?`, `AT+CIND?`, `AT+CMER=3,0,0,1`; then poll `AT+CIND?` every two seconds. The same HF-side opening can run on an accepted dummy-HFP socket. The responder answers peer commands too. HSP does not carry this SLC sequence.  
   Evidence: `N/HfpSlcInitiator.kt:25`, `:49`, `:77`; `N/HfpAtResponder.kt:30`; `N/NativeAaHandshakeManager.kt:970`, `:2081`.

10. **Wait for the phone to open AA RFCOMM separately.** This is the connection Hackura has never observed. The ordinary native manager contains no BLE advertiser calls; its “poke” is a real classic-Bluetooth socket connection.  
    Evidence: `N/NativeAaHandshakeManager.kt:1005`, `:1023`, `:1994`; scoped advertiser-symbol search returned no matches.

11. **Run WPP after acceptance.** After a 300-ms delay, send type 4 version request; allow three seconds for version response; obtain credentials; send type 1 with projection endpoint; answer type 2 with type 3 credentials. Read types 6/7 and echo type 8 pings as type 9. Credential wait is bounded at 60 seconds. Adding this version exchange cannot explain a phone that never opens RFCOMM.  
    Evidence: `N/NativeAaHandshakeManager.kt:2994`, `:3266`, `:3299`; `N/WppHandshakeSession.kt:254`, `:293`.

12. **Let Wi-Fi settle and retain the control channel.** Type 3 stops the poke. The normal settling window is 45 seconds, extendable to 90. When projection lands, keep the existing AA control connection for pings and close AA listeners; reopen them for the next session.  
    Evidence: `N/NativeHandoffPolicy.kt:22`, `:28`; `N/NativeAaHandshakeManager.kt:3076`, `:3102`, `:1175`.

Two limits matter:

- Its “SLC established” state advances on `ERROR` as well as `OK`. That log alone is not proof that the phone accepted a working HFP profile. Evidence: `N/HfpSlcInitiator.kt:71`.
- Its “safe wake” verdict can mean AA started even if hands-free did not recover. T190 must measure call recovery separately. Evidence: `N/NativeAaWakeDamagePolicy.kt:61`.

Permissions and reflection:

- The manifest declares legacy `BLUETOOTH`/`BLUETOOTH_ADMIN`, Wi-Fi/network permissions, and modern `CONNECT`/`SCAN`/`ADVERTISE` permissions. The manager checks `BLUETOOTH_CONNECT` on Android 12+. Evidence: `O/app/src/main/AndroidManifest.xml:57`, `:73`; `N/NativeAaHandshakeManager.kt:891`.
- Hidden/reflected operations include local UUID reads, `BluetoothDevice.isConnected`, service enumeration, Binder-manager lookup, private adapter construction and hotspot configuration getters. Reflection does not bypass service permission checks. Evidence: `N/NativeAaHandshakeManager.kt:1339`; `K/utils/BluetoothHelper.kt:27`, `:217`, `:536`.
- README warns about legacy helper startup on AA 17.4+, while native mode remains an offered route. WPP code comments reference AA 17.5 and protocol 4.2. No named-phone trigger matrix was found in the requested files. The target phone’s installed versions remain **UNKNOWN**. Evidence: `O/README.md:16`; `N/WppHandshakeSession.kt:164`; [project wireless documentation](https://github.com/andreknieriem/open-headunit/wiki/Wireless).

Honda capability map:

| Candidate | Ordinary-app verdict and consequence |
|---|---|
| AA RFCOMM server | **Confident:** local listener works. Remote SDP visibility remains unknown. `L:1066`; `F/bluetooth/BluetoothAdapter.java:700`. |
| OEM HFP reconnect | **Likely:** exported Binder path exists. Briefly interrupts hands-free; Honda policy may refuse. `H/…/LocalService.java:211`; `H/…/BluetoothState.java:368`. |
| Raw HSP/HFP poke | **Confident:** socket APIs permit an attempt. Phone acceptance and Honda recovery unknown; may displace calls. `F/bluetooth/BluetoothDevice.java:525`; `N/BluetoothWakePolicy.kt:35`. |
| Dummy HFP plus AT | **Possible as application code; unsuitable default here.** It cannot carry call audio and competes with real HFP. `N/HfpServiceRecordPolicy.kt:7`. |
| Bluetooth radio cycle | **Likely feasible with `BLUETOOTH_ADMIN`**, subject to active-user checks. T180 lacks that manifest permission. Drops every Bluetooth connection. `S/BluetoothManagerService.java:699`, `:725`; T180 manifest:16. |
| BLE AA advertising | **UNKNOWN hardware support.** Framework returns no advertiser when unsupported. Does not reproduce a complete dongle mode by itself. `F/bluetooth/BluetoothAdapter.java:207`; `F/bluetooth/le/BluetoothLeAdvertiser.java:51`. |
| Ordinary hotspot | Reading/configuring manually is plausible; automatic permission path **UNKNOWN**. Honda’s hotspot start disables station Wi-Fi. `H/…/HotspotState.java:154`; `F/net/ConnectivityManager.java:676`. |
| Vendor ZBT/FYT route | **UNKNOWN applicability:** no matching Honda transport established. `N/ExternalBtTransportPolicy.kt:55`. |
| Disable secure-mode filtering | No ordinary-app route established; setter explicitly checks an internal permission. Filtering this AA UUID is itself **UNKNOWN**. `F/app/BluetoothSecureManagerService.java:28`, `:139`. |

There is **no evidence-backed blanket “wireless cannot work as a user app” verdict**. There is also no established user-app capability to replace Honda’s HFP owner or force the remote phone’s AA startup policy.

**Ranked T190 plan — specification only; no switches implemented or tests executed**

Keep one listener security choice, one network configuration and one expected phone fixed throughout. Existing T180 TCP code logs and closes the connection; a probe PASS is not a functioning wireless projection session. Evidence: `J/WirelessProbeService.java:27`, `:345–353`.

Before comparisons, add the same diagnostics to every variant:

- `P6_LOCAL_RECORDS hasAa=… hasHandsFree=… readable=…`
- `P6_HFP old=… new=… peerMatch=… reason=…`, from Broadcom’s actual broadcast extras.
- `P6_HFP_SNAPSHOT vendorConnected=… standard16=…`
- `P6_UUID_RX devicePresent=… peerMatch=… arrayPresent=… count=…`, **before filtering**.
- `P6_TRIGGER mode=… callIdle=… listenersReady=…`
- `P6_END aaAccepted=… tcpConnected=… hfpRecovered=…`

Broadcom state extras are evidenced at `H/…/BluetoothHFPProfile.java:130–140`. All new markers above are **proposed**, not existing evidence.

| Rank | Single selectable change | Exact distinguishing markers and PASS |
|---|---|---|
| **1** | **Phone HCI snoop enabled**, otherwise passive baseline | Proposed offline summary `P6_TRACE sdpQueryAa=… aaRecordReturned=… rfcommAttempt=… hfpConnected=…`. Diagnostic PASS requires a decoded response containing AA and its RFCOMM channel. No query means visibility remains UNKNOWN. |
| **2** | **Wake = Honda HFP reconnect once** | Bind stock service; request HFP-only disconnect/connect through the OEM path, respecting refusals. Log `P6_OEM_BIND ok=…`, `P6_OEM_HFP_REQUEST state=0/2 accepted=…`, actual `P6_HFP` transitions. Trigger PASS requires subsequent existing `P4_BT_PHONE_CONNECTED`; request acceptance alone fails. |
| **3** | **Wake = one head-unit Bluetooth cycle** | Log `P6_RADIO_REQUEST enabled=false/true accepted=…`, actual adapter transitions, `P6_LISTENER_REOPEN ok=…`, then HFP recovery. Leave the phone unpoked for 90 seconds. PASS requires AA acceptance and recovered OEM HFP; an unrecovered radio/link fails. |
| **4** | **Wake = existing one-shot HSP nudge** | Capture `P5_NUDGE_START`, `P5_NUDGE_CONNECTED` or `FAILED`, and `P5_NUDGE_CLOSED`. Preserve the existing timing for this comparison. PASS requires subsequent AA acceptance; nudge connection alone fails. This fills T170’s lost evidence. |
| **5** | **Wake = BLE AA advertisement only** | First log `P6_BLE_CAPABLE value=…`; then `P6_BLE_START status=…`, `P6_BLE_STOP`. Unsupported means NOT TESTABLE. Advertising success alone fails; require AA acceptance and trace evidence attributing it to this variant. |

For each trigger, distinguish three results:

- **Trigger PASS:** `P4_BT_PHONE_CONNECTED`.
- **Bootstrap/network PASS:** type-2 request, type-3 response, then `P4_TCP_CONNECTED fromGroupNetwork=true`; record whether first bytes arrived.
- **Preservation PASS:** Honda hands-free returns and a separate parked call check confirms audio.

Do not combine raw HFP SLC, duplicate HFP registration, radio cycling or a network change in one variant. **Exclude competing dummy HFP from T190 on present evidence.** Honda AA-state integration deserves separate treatment because it changes profile policy; copying it into a wake switch would obscure the cause.

**7. Assumptions**

- This review treats saved evidence as evidence of those captured runs, not present device state.
- Public moving branches may differ from the pinned local open-headunit copy.
- Existing successful dongle use is supplied context; its exact trigger was not established from a trace.

**8. Unresolved uncertainties**

- Whether the phone receives Hackura’s AA SDP record and attempts RFCOMM.
- Actual Honda HFP state and matching peer during the failed attempts.
- Runtime access to Honda’s exported Binder services from Hackura.
- Broadcom SDP backend behavior, broadcast delivery and receiver-filter effects.
- Phone AA/Android versions, per-car startup decisions and cached wireless associations.
- BLE advertising support and any usable vendor transport on this Honda firmware.
- Recovery of calls after any proposed poke or cycle.

**9. Exact diff summary**

None. No files written; no Git diff requested or run.

**10. Preservation checks performed**

No device access, builds, Git operations, milestone actions or key-material reads. Frozen artifacts were not rebuilt or modified; their hashes were not reverified.

Repeated SHA-256 checks matched for `N/NativeAaHandshakeManager.kt`, `J/WirelessProbeService.java` and `L`. Capture provenance:

`L` SHA-256: `BEB1FBFDA05CA529E7311C8574B7DBB2EAD36957F0B7084607158557F034DC46`.

One failed Python launcher exposed a local environment path in tool output before output filtering was applied. No device or account identifiers are reproduced in this report.