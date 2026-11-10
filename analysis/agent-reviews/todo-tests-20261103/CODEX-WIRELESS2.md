**The cause is still UNKNOWN.** The evidence points first to Bluetooth discovery/start policy, rather than a missing pairing method. The station retry loop is real, but this capture does **not** show it continuing while the Wi-Fi Direct group is active.

**1. Files inspected**

Path abbreviations used below:

- `B` = `analysis/test-prep/todo-tests-20261103/builds`
- `J` = `B/T170-bundle/source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper`
- `P` = `decompiled/AndroidAuto-current/sources/com/google/android/projection`
- `H` = `decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink`
- `F` = `decompiled/Framework/sources/android/net`
- `S` = `decompiled/HondaSettings/sources/com/honda/settings/wifilibrary/statemachine`
- `O` = `analysis/parallel-aa-receiver/offline-followup/public/open-headunit/andreknieriem-open-headunit-e9377ff/app/src/main`
- `L` = `analysis/test-prep/runs/helper_20261108T183827_1f84bd0942ec4ee2824a67739d119d3d/longdrive-evidence/rdx_afcb16d731b14fc398206d7accaf89d1/capture.log`

Inspected relevant portions of:

- `PROJECT-RULES.md`, `AGENTS.md`.
- Earlier `CODEX-WIRELESS.md`, `CODEX-BT-TRIGGER.md`.
- T160 `RESULT.md`; public `LATEST-TEST-PLAN.md`.
- `J/{AaSessionService,WirelessProbeService}.java`; T170 manifest and protocol facades.
- `P/proto/Protos.java`; protocol Bluetooth, Wi-Fi, credentials and receiver classes.
- `H/bluetooth/{BluetoothManager,BluetoothHelper}.java`; integration and pairing settings.
- `F/wifi/WifiManager.java`, `F/wifi/p2p/WifiP2pManager.java`, `F/ConnectivityManager.java`.
- Honda hotspot/state-machine source.
- `O/proto/{control,common,wireless}.proto`; service-discovery builder and WPP endpoint/server implementation.
- Public implementation and Android sources linked below.

**2. Files changed**

None.

**3. Commands run**

Read-only commands: `rg --files`, scoped `rg -n` searches, `Get-Content`, `Get-ChildItem`, `Resolve-Path -Relative`, filtering/counting pipelines, and `Get-FileHash -Algorithm SHA256`.

Capture output was reduced to timestamps, event labels, booleans and numeric fields.

Public web search/open/find operations were also used. Some public-source fetches failed. T170 `RESULT.md` was absent at the requested location.

**4. Tests run and results**

No builds, executable tests, Git commands or device operations.

Static checks:

- Capture: **3,592 lines**.
- Station-association/wrong-key matches after group-start line 1430: **0**.
- Repeated SHA-256 checks of both T170 service files and the capture: **all matched**.

**5. Findings**

**F1 — No missing wireless-support flag is demonstrated. Confidence: confident for this library; UNKNOWN for the phone’s complete eligibility policy.**

The local protocol provides:

| Configuration | Fields available | Hackura behavior |
|---|---|---|
| Bluetooth service | Car Bluetooth address; supported pairing methods | Sends numeric comparison and PIN |
| Wi-Fi projection service | Car Wi-Fi BSSID | Sends the group interface address |
| Wired credentials response | Password; security mode; network identifier | Supplies the current group credentials |

The old car-information schema has no explicit `wirelessSupported` field. Its opaque `session_configuration` integer does not establish a wireless switch.

The phone’s credential request proves that it recognized enough of the Wi-Fi service to request credentials. It does **not** prove it stored them, marked this receiver eligible, or learned a wireless TCP endpoint.

Stock Honda registers Bluetooth service 8 but does not register the Wi-Fi endpoint in its examined integration. It therefore supplies a pairing comparison, **not a known-working wireless advertisement**. A certified wireless head unit’s exact wired announcement remains **UNKNOWN**.

Evidence: `J/AaSessionService.java:851`, `:860`; `P/proto/Protos.java:4753`, `:12773`, `:49560`, `:50225`; `H/integration/AbstractGalIntegration.java:103`, `:115`; `L:1642`.

**F2 — Method 4 does not, by itself, require a different readiness answer. Confidence: confident.**

In this protocol version, method **4 = PIN**, and method **2 = numeric comparison**. Hackura advertises both.

Honda also derives `alreadyPaired` from its bond list and sends that value through readiness. It sends auth data when an actual Android pairing-request broadcast supplies the authentication value.

Therefore:

- Keep `readyForPairing(true)` when the matching bond exists.
- Do not invent auth data or report `false` merely to provoke wireless startup.
- For a genuinely unbonded phone, Hackura lacks Honda’s complete pairing/authentication handling.
- Honda additionally prepares the Bluetooth connection through its connection service. Hackura’s bond lookup alone does not establish an active hands-free connection.

A logged pairing request also does not prove the posted readiness callback ran or that its response reached the phone.

Evidence: `P/proto/Protos.java:849`; `J/AaSessionService.java:835`; `H/bluetooth/BluetoothManager.java:96`, `:514`, `:548`, `:559`; `H/bluetooth/BluetoothHelper.java:74`.

**F3 — Wired credentials are not a complete wireless-start instruction. Confidence: confident about transmitted fields; UNKNOWN about phone persistence.**

The wired credentials response contains **no IP address or port**. The Wi-Fi service announcement supplies a BSSID, not a TCP destination.

The examined dongle implementation separately sends `WifiStartRequest` over RFCOMM containing the receiver’s IP and port, then supplies Wi-Fi credentials. Hackura follows that model only after an RFCOMM accept.

Consequently, “credentials sent” does not establish that unplugging should make the phone connect directly to the group gateway.

Evidence: `P/proto/Protos.java:49560`, `:50225`; `J/WirelessProbeService.java:354`, `:399`; [dongle bootstrap implementation](https://raw.githubusercontent.com/nisargjhaveri/WirelessAndroidAutoDongle/main/aa_wireless_dongle/package/aawg/src/bluetoothProfiles.cpp).

**F4 — Bluetooth-free reconnects are a real alternative architecture, but are not established here. Confidence: likely.**

The local open-headunit implementation advertises a separate WPP-over-TCP endpoint through `WifiVersionRequest.wpp_info`. It implements a TCP bootstrap server and documents subsequent phone reconnects using the remembered endpoint.

That implementation uses **5299 for WPP bootstrap**, then announces **5288 for projection**. These are implementation choices, not evidence of universally mandatory ports.

Hackura currently sends the legacy start/info exchange and never advertises that separate endpoint. Simply opening another listener does not teach the phone to use it. Whether this phone supports that path is **UNKNOWN**.

Evidence: `O/proto/wireless.proto:101`, `:135`; `O/java/com/andrerinas/openheadunit/connection/wifi/modes/nativeaa/WppMessages.kt:51`; `WppTcpServer.kt:101`, `:405`; `J/WirelessProbeService.java:359`.

**F5 — Adding a head-unit listener on 5277 is unsupported by this evidence. Confidence: confident.**

Google documents **5277 as the phone-side developer head-unit server**, to which the emulated receiver connects. That reverses the connection direction of the normal wireless receiver listener.

For Hackura’s present bootstrap, the destination is the current group-owner IP plus the advertised **5288**. No evidence shows the phone independently guessing that endpoint from wired credentials.

Evidence: `J/WirelessProbeService.java:272`, `:359`; [Google DHU connection documentation](https://developer.android.com/training/cars/testing/dhu).

**F6 — The station retry claim needs a timing qualification. Confidence: confident.**

The capture contains association attempts at approximately 13-second intervals, followed by `WRONG_KEY`.

However:

- Last matching attempt: **13:36:50**, line 847.
- Last matching wrong-key event: **13:36:56**, line 862.
- P2P group starts: **13:39:46**, line 1430.
- Group frequency: **2412 MHz**, channel 1.
- Capture continues until **13:42:45**.
- No matching association/wrong-key events occur after group creation.

This capture does not prove ongoing station retries disrupted the active group.

Evidence: `L:406`, `:472`, `:571`, `:626`, `:686`, `:847`, `:862`, `:1430`; command result: `Post-group station-association matches: 0`.

**F7 — Shared-radio interference is plausible; the exact Honda behavior is UNKNOWN. Confidence: likely.**

Contemporary Broadcom source explicitly delays P2P action-frame work while the primary station interface connects, demonstrating interaction between the roles. This is not the exact Honda driver/firmware.

Scanning or association can consume radio time. Actual group channel changes, beacon disruption or client failures on this unit require evidence.

Pausing station connections is a reasonable isolation test. On Android 5.1-era reference code, `disconnect()` and `disableNetwork()` require `CHANGE_WIFI_STATE`, which T170 declares. Honda-specific enforcement remains unverified.

Use temporary network disabling plus disconnect if needed to suppress reselection, restoring affected network states afterward. Keep Wi-Fi enabled: turning off the radio already prevented P2P in T160. Disconnecting alone should not be assumed to suppress all later scans or OEM reconnect requests.

Evidence: [Broadcom source, primary-station/P2P scheduling](https://android.googlesource.com/kernel/bcm/+/android-wear-5.0.2_r0.5/drivers/net/wireless/bcmdhd/wl_cfg80211.c); [Android 5.1-era Wi-Fi service](https://raw.githubusercontent.com/LineageOS/android_frameworks_opt_net_wifi/cm-12.1/service/java/com/android/server/wifi/WifiServiceImpl.java); `F/wifi/WifiManager.java:279`, `:287`; T170 manifest:18; T160 `RESULT.md:12`.

**F8 — `createGroup()` does not promise 5 GHz. Confidence: confident.**

The API22 call has no band argument. Supplicant preferences, existing radio use, regulatory constraints and driver capabilities influence selection. Upstream supplicant includes social-channel defaults; the exact disconnected-station default on Honda is **UNKNOWN**.

The observed selection was 2.4 GHz. The hidden API accepts separate listen and operating channels; setting a 5 GHz operating channel is worth an isolated test, with actual band confirmation.

Google lists 5 GHz phone support as a wireless requirement. That alone does not prove this phone rejects every 2.4 GHz receiver.

Evidence: `F/wifi/p2p/WifiP2pManager.java:486`, `:501`; `L:1430`; [supplicant channel-selection source](https://raw.githubusercontent.com/vanhoefm/hostap-wpa3/master/wpa_supplicant/p2p_supplicant.c); [Google requirements](https://support.google.com/androidauto/answer/6348019?hl=en).

**F9 — Two diagnostic distinctions matter. Confidence: confident.**

- `P5_PHONE_SDP_RESULT hasAa` asks whether **the phone advertises** the AA service. It does not show whether the phone discovered **Hackura’s** service.
- Even after TCP succeeds, this probe reads briefly and closes the connection. It cannot yet run a wireless AA session.

Also preserve the separate security enums: wired GAL uses WPA2-personal **5**; RFCOMM WPP uses **8**. The current distinction matches the examined schemas.

Evidence: `J/WirelessProbeService.java:91`, `:301`, `:316`; `P/proto/Protos.java:2117`; `O/proto/wireless.proto:31`.

**6. Primary evidence and ranked T180 recommendation**

Evidence for each finding is attached above. The ranking below is engineering judgment about test value, not a proven cure.

| Rank | One Settings switch | Recommendation and confidence |
|---|---|---|
| **1 — T180** | **Pause station reconnects** | **Likely useful diagnostically.** Temporarily suppress saved-network selection while retaining Wi-Fi/P2P. Compare with the already-tested insecure-listener baseline; keep the nudge off. This isolates the new radio hypothesis. |
| **2** | **Start listener before hands-free reconnect** | **Likely relevant to the observed failure stage.** Have the listener ready before a normal Honda hands-free connection event. Measure actual profile state and remote SDP visibility. Local listening alone is insufficient. |
| **3** | **Prefer 5 GHz P2P** | **UNKNOWN compatibility.** Request a supported non-DFS operating channel through the hidden API; log request result and actual band. This tests band selection without changing AP technology. |
| **4** | **Use soft AP** | **UNKNOWN ordinary-app feasibility.** Honda uses `setWifiApEnabled`; its hotspot path first disables station Wi-Fi. Replace P2P for this variant. T170 currently lacks `CHANGE_NETWORK_STATE`, and provisioning may require privileged permission instead. |
| **5** | **Reuse persistent group** | **Likely useful for reconnect identity; UNKNOWN first-start benefit.** Preserve credentials/BSSID across restarts and reannounce them accurately. Persistence alone does not supply a wireless trigger. |
| **6** | **Numeric comparison only** | **UNKNOWN benefit.** Advertise method 2 alone. Any actual new pairing needs the OS authentication exchange; do not falsify existing bond status. |
| **7** | **Connect outward to phone AA service** | **UNKNOWN, low priority.** Consider only if fresh SDP says the phone advertises that UUID. A UUID match still does not establish that the phone accepts the expected server role. |

Soft-AP evidence: `S/HotspotState.java:154`, `:172`; `F/ConnectivityManager.java:676`; T170 manifest:4; [reference service’s tether-permission checks](https://raw.githubusercontent.com/LineageOS/android_frameworks_opt_net_wifi/cm-12.1/service/java/com/android/server/wifi/WifiServiceImpl.java).

Review the pending T170 nudge result before interpreting or repeating that variant.

For T180, add these **boolean/enum-only** observations:

| Area | Fields |
|---|---|
| Actual wired announcement | `btServicePresent`, `wifiServicePresent`, `pairingMethods=NUMERIC/PIN/BOTH`, `advertisedBtMatchesAdapter`, `advertisedBssidMatchesLiveGroup` |
| Pairing response | `bondState`, `readyCallbackExecuted`, `readyResponseSent`, `alreadyPaired`, `osPairingVariant`, `authDataSent` |
| Bluetooth discovery | `localAaRecordPresent`; separately, phone-observed `huAaRecordPresent=YES/NO/UNKNOWN` |
| Connection trigger | `hfpState`, `hfpPeerMatchesSessionPhone`, `aclState`, `listenerReadyBeforeHfp`, `callState` |
| Radio | `stationSupplicantState`, `stationReconnectSuppressionResult`, `stationRetryWhileGroupUp`, `groupFormed`, `isOwner`, `band`, `channelChangeSeen`, `clientPresent` |
| Bootstrap | `rfcommAccepted`, `wppMessageType`, decoded `wppStatus`, `tcpListening`, `tcpAccepted`, `tcpPeerOnGroupSubnet`, `ownerAddressMatchesLiveInterface` |
| Restoration | `networkStatesRestored`, `groupCleanupResult` |

If T180 remains silent at RFCOMM with station retries suppressed, prioritize the phone’s view of SDP and its hands-free/start decision. Further AP and port changes would leave that earlier failure unexplained.

**7. Assumptions**

- Supplied T170 outcomes supplement the saved capture; no T170 result file was available.
- Source snapshots correspond to the tested builds; installed binary parity was not verified.
- Public implementations demonstrate possible mechanisms, not this phone’s exact behavior.

**8. Unresolved uncertainties**

Remote visibility of Hackura’s AA SDP record; actual Honda hands-free state; phone-side per-car wireless eligibility; credential persistence; readiness response delivery; pending nudge outcome; exact Honda radio scheduling; 5 GHz group support; and cached WPP-over-TCP support.

The exact reason wireless startup is rejected remains **UNKNOWN**.

**9. Exact diff summary**

None. No files changed.

**10. Preservation checks performed**

Read-only operations throughout; no Git, builds, device access, key-material reads or milestone actions.

Repeated SHA-256 checks matched:

- `J/WirelessProbeService.java`: `171324DFEA3348F814063BDFBD76B2C111A4BFA0417916B43F67DFA03A07858C`
- `J/AaSessionService.java`: `A83E8F987C96BC2B454DD546AA452FC5764831849D27F0120F0D338BC3C6B3EC`
- `L`: `08158B73A2C21D1737A8B9E083A35006A4897F3DADC8A8ADC110EB0961735E93`

Frozen artifact hashes were not rechecked; those artifacts were not modified or rebuilt.