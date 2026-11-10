**The open-dongle trigger is an outgoing HSP Audio Gateway connection. Reproducing it on Honda is technically possible, but its safety alongside Honda’s existing HFP connection is UNKNOWN.** Under the strict “never disturb calls” requirement, P5 should default to listener/SDP diagnostics and skip the audio-gateway probe.

1. **Files inspected**

Path abbreviations used below:

- `B` = `analysis/test-prep/todo-tests-20261103/builds/T160-bundle`
- `J` = `B/source/analysis/parallel-aa-receiver/usb-helper`
- `W` = `J/source/com/rdx/fullscreen/usbhelper/WirelessProbeService.java`
- `S` = `J/source/com/rdx/fullscreen/usbhelper/AaSessionService.java`
- `F` = `decompiled/Framework/sources/android/bluetooth`
- `H` = `decompiled/HondaSettings/sources/com/honda/settings/btservice`
- `A` = `decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink`

Inspected:

- `PROJECT-RULES.md`, `AGENTS.md`, `B/RESULT.md`, `W`, `S`, `J/AndroidManifest.xml`.
- `analysis/agent-reviews/todo-tests-20261103/CODEX-WIRELESS.md`, relevant sections.
- `F/BluetoothDevice.java`, `BluetoothSocket.java`, `BluetoothServerSocket.java`, `BluetoothAdapter.java`, `BluetoothUuid.java`, `IBluetoothSecureManagerService.java`.
- `decompiled/Framework/sources/android/app/BluetoothSecureManagerService.java`.
- `H/proxyhandlers/BluetoothHFPProfile.java`, `AbstractBluetoothProfile.java`, `H/utils/BluetoothHelper.java`.
- HondaSettings `BluetoothConnectionService.java`, `IBluetoothConnectionService.java`, manifest.
- `A/bluetooth/BluetoothManager.java`, `BluetoothHelper.java`; relevant `ProjectionActivity.java` matches.
- Stock `com/google/android/projection/protocol/BluetoothEndpoint.java`.
- Services `BluetoothManagerService.java`, `SystemServer.java`, relevant matches.
- Public source files and documentation linked below.

2. **Files changed**

None.

3. **Commands run**

Read-only command families:

- `Get-Content -LiteralPath PROJECT-RULES.md` and `AGENTS.md`.
- `rg --files` over the supplied research, build and decompiled directories, with filename filters.
- Targeted `rg -n` searches for UUIDs, socket APIs, pairing/authentication, permissions, HFP and secure-mode handling.
- Numbered excerpts using `rg -n '^' <file> | Select-Object -Skip … -First …`.
- Output filtering/redaction with `Where-Object` and `ForEach-Object`.
- `Get-FileHash -Algorithm SHA256` for `W` and `S`, followed by equality checks.
- One attempted read-only Python reader failed because the launcher was unavailable.
- Public web search/open/find requests.

The initially supplied root-relative build path did not exist; the build was located under `analysis/test-prep/todo-tests-20261103/builds/`. No Git commands ran.

4. **Tests run and results**

No builds, executable tests or device tests ran.

Static review completed. Both source hash comparisons returned `True`.

5. **Findings, with evidence**

**F1 — Exact open-dongle Bluetooth sequence**

**WirelessAndroidAutoDongle:** registers AA UUID `4de17a00-52cb-11e6-bdf4-0800200c9a66`, server role, channel 8, service label “AA Wireless”. Outside dongle mode it additionally registers HSP headset UUID `00001108-0000-1000-8000-00805f9b34fb`, then initiates `ConnectProfile` to the phone’s **HSP AG**, `00001112-0000-1000-8000-00805f9b34fb`. It does not register HFP in this path. The phone separately connects to the AA server. [bluetoothHandler.cpp, lines 20–25, 104–127, 176–190](https://github.com/nisargjhaveri/WirelessAndroidAutoDongle/blob/main/aa_wireless_dongle/package/aawg/src/bluetoothHandler.cpp#L104)

Its retry loop waits 20 seconds between attempts. Before connecting it calls device-wide `Disconnect()` behind `if (deviceConnected)`—a shared-pointer test, not an explicit property-value test. **Do not copy this cleanup onto Honda.** Dongle mode omits fake HSP, changes the adapter alias prefix, advertises the AA UUID over BLE, and attempts `ConnectProfile("")`. The phone’s exact recognition rule is UNKNOWN. [same file, lines 176–242](https://github.com/nisargjhaveri/WirelessAndroidAutoDongle/blob/main/aa_wireless_dongle/package/aawg/src/bluetoothHandler.cpp#L176)

Its AA callback sends `WifiStartRequest`, receives `WifiInfoRequest`, sends credentials, then reads two further messages. The HSP callback has no AT-command handling or explicit timed hold. [bluetoothProfiles.cpp, lines 28–56, 148–172](https://github.com/nisargjhaveri/WirelessAndroidAutoDongle/blob/main/aa_wireless_dongle/package/aawg/src/bluetoothProfiles.cpp#L28)

**aa-proxy-rs:** its core path likewise registers AA on channel 8 and HSP headset outside dongle mode, initiates the phone’s HSP AG connection, then waits for phone-initiated AA RFCOMM. It explicitly disables authentication/authorization requirements on its AA profile. [bluetooth.rs, lines 4275–4283, 5608–5638, 5850–5853, 7328–7343](https://github.com/aa-proxy/aa-proxy-rs/blob/main/src/bluetooth.rs#L4275)

The HSP callback accepts and immediately drops the control stream; comments warn that holding it without an AT state machine can misroute calls. Connect timeout is 20 seconds; retry backoff is 1–15 seconds. Normal completion disconnects the device and unregisters HSP; quick-reconnect options differ. The nominal 150-ms sleep in normal cleanup lacks `.await`. [lines 44–47, 5619–5621, 7362–7377, 7570–7587](https://github.com/aa-proxy/aa-proxy-rs/blob/main/src/bluetooth.rs#L7362)

In dongle mode it skips HSP and generally waits for incoming AA; a special branch calls `device.connect()` for peers matching an adapter-name prefix. Optional companion/audio/proxy profiles elsewhere are separate features. [lines 5639–5678, 5951–5953](https://github.com/aa-proxy/aa-proxy-rs/blob/main/src/bluetooth.rs#L5639)

Neither implementation proves that the phone requires an exact SDP service label, channel 8, or particular class of device. Those are implementation choices, not established phone-side checks.

Dongle mode is also not universally reliable: the project introduced it as default in v0.4.0, then restored phone-first as default in v0.4.1. [Release notes](https://github.com/nisargjhaveri/WirelessAndroidAutoDongle/releases)

**F2 — An ordinary app can request the outgoing connection**

The Honda framework exposes both:

- `createRfcommSocketToServiceRecord(uuid)`: authentication and encryption enabled.
- `createInsecureRfcommSocketToServiceRecord(uuid)`: both disabled.

Neither constructor restricts the supplied UUID. `connect()` forwards that UUID to the Bluetooth service. Thus the app can **attempt** HSP AG, HFP AG or another advertised RFCOMM service; this does not guarantee acceptance or implement the associated profile. Evidence: `F/BluetoothDevice.java:525`, `:529`; `F/BluetoothSocket.java:157`, `:169`.

HSP AG is `…1112…`; HFP AG is `…111f…`. They are different UUIDs, and the examined dongle trigger uses **1112**, not 111f. Evidence: `F/BluetoothUuid.java:19`, `:21`.

For legacy Android, `BLUETOOTH` covers connecting to paired devices and SDP fetching. `BLUETOOTH_ADMIN` is additionally relevant to discovery/pairing operations; it is not needed merely to supply an AG UUID. Both are install-time dangerous permissions in Android 5.1, not signature permissions. T160 already declares `BLUETOOTH`. [Android 5.1 manifest, lines 774–790](https://github.com/aosp-mirror/platform_frameworks_base/blob/android-5.1.1_r38/core/res/AndroidManifest.xml#L774); `J/AndroidManifest.xml:16`; [SDP API documentation](https://developer.android.com/reference/android/bluetooth/BluetoothDevice#fetchUuidsWithSdp()).

**F3 — Honda already owns the real HFP implementation**

HondaSettings uses Broadcom `BluetoothHfDevice`, including `connect(device)` and `disconnect(device)`. Stock AA asks Honda’s service to `startConnection(1, true, …)`. Evidence: `H/proxyhandlers/BluetoothHFPProfile.java:11`, `:54`, `:65`; `A/bluetooth/BluetoothManager.java:571`.

Therefore, “the car must initiate a connection” is **not yet a sufficient explanation**: Honda already has an outgoing HFP path.

Whether the phone maps HSP AG and HFP AG onto the same RFCOMM channel, and what a second raw connection would do, are **UNKNOWN**. A UUID list alone cannot establish their channel mapping. Do not equate “different UUID” with “independent, harmless connection”.

Also, bonding does not establish current HFP state. T160 checks the bond list; its result report explicitly says Honda Bluetooth capture is missing for the retries. Evidence: `S:835–844`; `B/RESULT.md:14`.

**F4 — SDP hiding is unproven; visibility needs a remote observation**

The local registration chain is intact:

`listenUsing…WithServiceRecord` → service name/UUID → `bindListen()` → `createSocketChannel()`.

Evidence: `F/BluetoothAdapter.java:700–723`; `F/BluetoothSocket.java:203–250`.

`BluetoothSecureManagerService` stores secure-mode and whitelist settings, with zero defaults. Its presence does **not** establish active filtering or suppression of third-party records. The inspected Services/Framework search found its SystemServer registration, not an enforcement path proving this UUID is hidden. Evidence: `decompiled/Framework/sources/android/app/BluetoothSecureManagerService.java:122–145`, `:157–184`; `decompiled/Services/sources/com/android/server/SystemServer.java:430`.

Cheap checks for a future test:

- Log successful registration and whether the local adapter UUID list contains AA. This is **local evidence only**. The OEM `BluetoothAdapter.getUuids()` exists, but is outside the ordinary public SDK surface: `F/BluetoothAdapter.java:342–355`.
- From the head unit, call the **phone’s** `fetchUuidsWithSdp()` and log only `hasHspAg`, `hasHfpAg`, callback timing and null/empty status. Available here: `F/BluetoothDevice.java:378–389`; `ACTION_UUID`: `:35`.
- To establish that the **phone sees Honda’s AA record**, discovery must run from the phone or another remote Bluetooth peer. A phone-side diagnostic app is one option; an existing diagnostic facility could substitute.
- `ACTION_UUID` can contain cached results. A successful callback is not proof of a fresh over-air query. [API contract](https://developer.android.com/reference/android/bluetooth/BluetoothDevice#fetchUuidsWithSdp()).
- An ordinary head-unit listener has no demonstrated callback for incoming SDP searches. Without existing lower-level trace evidence, it cannot distinguish “no query” from “query answered but AA declined”.

**F5 — Wired pairing response is plausible; missing authentication is not established**

T160 advertises the adapter’s actual Bluetooth address and answers `readyForPairing` using the requested phone’s bond status. Evidence: `S:817–818`, `:834–851`.

Stock Honda also answers readiness from `isPaired`. On a real pairing request it formats the system pairing value as six decimal digits and forwards it through `sendAuthData`. Evidence: `A/bluetooth/BluetoothManager.java:96–107`, `:514–515`, `:548–550`; stock `BluetoothEndpoint.java:60–71`.

Accordingly:

- `alreadyPaired=true` is appropriate when that exact peer is bonded.
- Do not fabricate authentication data or send a blank placeholder.
- New pairing would require handling the real pairing event; the examined code does not establish that auth data must be resent for an existing bond.
- Bonding/readiness still does not prove the phone discovered AA’s SDP record or enabled wireless for this receiver.

A universal “the same Bluetooth device must first have appeared during wired AA” rule is contradicted by the dongle’s documented setup: wired AA with the original car, then pairing a separate dongle. Honda-specific association requirements remain UNKNOWN. [Project setup instructions](https://github.com/nisargjhaveri/WirelessAndroidAutoDongle/blob/main/README.md#first-time-connection)

**F6 — Ranked explanations and distinguishing logs**

Ranking is investigation priority, not a measured probability.

| Rank | Explanation | What would distinguish it |
|---|---|---|
| 1 | AA record unavailable, stale or never rediscovered remotely | Remote SDP result for AA UUID; correlate listener lifetime with wired setup and natural HFP reconnect. Local `LISTENING` alone cannot decide this. |
| 2 | Phone-side receiver association/start policy | Log pairing method, requested-peer bond match, advertised-adapter identity match, readiness dispatch, and HFP timing. Phone-side AA diagnostics are needed to establish rejection policy. |
| 3 | Secure-listener mismatch | Compare secure/insecure listeners with identical UUID and service label. Log accept/error times. T160 is secure: `W:206`; API distinction: `F/BluetoothAdapter.java:700–705`. |
| 4 | Missing fresh initiator/profile event | Correlate actual Honda HFP transitions with listener readiness. Honda’s outgoing path is a counterexample to treating direction alone as proven: `A/bluetooth/BluetoothManager.java:571`. |
| 5 | Existing dongle wins wireless selection | Record whether the dongle is powered/available and which connection the phone selects. A saved bond alone is not proof of exclusivity. |
| 6 | AA per-car wireless eligibility/state | Inspect the relevant phone entry and any available phone diagnostics. Global wireless ON does not establish this receiver’s stored eligibility; exact flag semantics are UNKNOWN. |
| 7 | SDP service label | Later compare “Android Auto” and the open implementations’ label, changing nothing else. No examined phone code proves label matching. |

Wi-Fi band, association, DHCP and TCP failures remain later gates. They do not themselves explain the missing RFCOMM accept marker: that marker precedes bootstrap/network handling. Evidence: `W:214–231`.

**Recommended P5 design — proposal only**

**Default: one diagnostic Settings switch, preserving Honda HFP.**

1. Create the group and TCP listener; confirm readiness before wired announcement. Register one AA listener and keep it alive through wired setup/unplug and subsequent natural Honda reconnection. Log monotonic timestamps.
2. First compare the current secure listener with an **insecure listener using the same UUID and service label**. Use one active listener at a time; change the service label only in a later variant. APIs: `F/BluetoothAdapter.java:700–705`.
3. Observe Honda’s Broadcom connection broadcast, including previous/new state and reason. Do not substitute a generic phone-side headset proxy for Honda’s actual HFP state. Evidence: `H/proxyhandlers/BluetoothHFPProfile.java:129–140`; `F/BluetoothAdapter.java:762–797`.
4. Perform at most one phone SDP fetch. **Default outgoing profile UUID: none. Hold time: none.**
5. If Honda HFP is connected, connecting, or UNKNOWN, log `P5_TRIGGER_SKIPPED` with that reason. Do not disconnect it or try HFP AG as fallback.

Suggested markers:

`P5_START`, `P5_LISTENER_READY security=…`, `P5_LOCAL_AA_UUID`, `P5_PHONE_SDP_REQUEST`, `P5_PHONE_SDP_RESULT hasHspAg=… hasHfpAg=…`, `P5_HFP_STATE`, `P5_TRIGGER_SKIPPED`, `P5_AA_RFCOMM_ACCEPT`, `P5_BOOTSTRAP_STATUS`, `P5_TCP_ACCEPT`, `P5_END`.

Log booleans, enums, durations and sanitized error categories—not peer identifiers or authentication/credential contents.

**Second-ranked experimental variant: brief raw HSP AG probe.**

If the lead later elects to test it, the exact target is **`00001112-0000-1000-8000-00805f9b34fb`**, using secure `createRfcommSocketToServiceRecord`, only after listener/group/TCP readiness and wired session end. Require known-disconnected Honda HFP and known-idle call state; otherwise skip.

Use one worker-thread attempt, a proposed three-second connection deadline, and **zero deliberate hold after success: immediately close only the app-owned socket**. No AT commands, SCO, dummy server, retries, device-wide disconnect, or radio cycling. Socket close aborts pending operations. [Socket documentation](https://developer.android.com/reference/android/bluetooth/BluetoothSocket)

That deadline is a proposed test bound, not a discovered protocol requirement. Even this brief probe is **not proven call-safe**, so exclude it when “never disturb calls” is absolute. HFP AG `…111f…` is not recommended.

**PASS:** phone-initiated AA RFCOMM accept, successful Wi-Fi bootstrap, TCP 5288 connection and working AA, with Honda HFP preserved and no unintended disconnect/audio-route event. `connect()` success alone is not PASS.

6. **Primary evidence for findings**

Source locations and public URLs accompany each finding. T160 outcomes above rely on `B/RESULT.md:13–14`; raw Honda Bluetooth evidence for those retries was not established.

7. **Assumptions**

- The task’s operator account is accurate.
- “Never disturb calls” is a hard design constraint.
- Public `main` sources describe those examined versions; they do not establish proprietary dongle or phone internals.

8. **Unresolved uncertainties**

Remote AA SDP visibility; actual HFP state during T160; phone-side AG channel mapping; second-connection behavior; exact phone startup policy; per-car wireless state; and eventual Wi-Fi/TCP compatibility are **UNKNOWN**.

9. **Exact diff summary**

None; no files changed.

10. **Preservation checks performed**

Repeated SHA-256 comparisons returned `True` for:

- `W`: `FBD0E177CBEBF2C7D4BFA07B723B0E005E9CEF32D4E67FF33FF105C4715261DC`
- `S`: `FEA0FED1C020FEDEDB97F5EF0C0442B560C8937C7487480D98B57A7C23B84546`

No builds, Git operations, device access, milestone actions or private-key reads occurred. Frozen artifacts were not rebuilt or modified; their hashes were not independently rechecked.