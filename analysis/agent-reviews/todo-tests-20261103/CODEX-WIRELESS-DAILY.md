**Recommendation:** T220 should keep wireless readiness alive independently of an AA session, retain Bluetooth bootstrap with a dynamic group, and leave Quiet off in daily mode. **Confidence: HIGH** in the architectural fit; unattended cold-start behavior remains **UNKNOWN** until tested.

**1. Files inspected**

Paths are relative to `C:/Users/REDACTED\Desktop\RDX-ReverseEngineering`.

Aliases:

- `B` = `analysis/test-prep/todo-tests-20261103/builds`
- `J` = `B/T210-bundle/source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper`
- `R` = `analysis/agent-reviews/todo-tests-20261103`
- `O` = `analysis/parallel-aa-receiver/offline-followup/public/open-headunit/andreknieriem-open-headunit-e9377ff/app/src/main/java/com/andrerinas/openheadunit`
- `N` = `O/connection/wifi/modes/nativeaa`
- `F` = `decompiled/Framework/sources/android/net/wifi/p2p`
- `H` = `decompiled/HondaSettings/sources/com/honda/settings`

Inspected, selectively for large files:

- `PROJECT-RULES.md`, `AGENTS.md`.
- `B/T190-bundle/RESULT.md`, `B/T200-bundle/RESULT.md`.
- `R/CLAUDE-T200-RECONCILE.md`, `CLAUDE-T210-RECONCILE.md`; wireless research reports for source locations.
- `J/WirelessProbeService.java`, `AaSessionService.java`, `UsbHelperService.java`, `PersistentBootService.java`, `BootBlockerReceiver.java`, `PersistentMode.java`, `ReconnectPolicy.java`, `AppSettings.java`, `SettingsActivity.java`, `AaMediaSourceService.java`, `PermissionClickService.java`, `HelperActivity.java`; T210 manifest.
- `N/EarlyWakePolicy.kt`, `SessionEndGroupPolicy.kt`, `AaListenerRecoveryPolicy.kt`, `NativeAaHandshakeManager.kt`, `NativeCredentialsPolicy.kt`, `WppEndpointPolicy.kt`, `WppMessages.kt`.
- `O/connection/wifi/direct/{NativeGroupKeepPolicy,NativeGroupLossPolicy,GroupIdentityStabilityPolicy}.kt`; boot receiver; wireless protocol schema.
- `F/WifiP2pManager.java`, `WifiP2pConfig.java`; Honda Wi-Fi mode, options, and state implementations.
- Public aa-proxy-rs `src/main.rs` and `src/bluetooth.rs`.

**2. Files changed**

None.

**3. Commands run**

Read-only `Get-Content`, `Select-String`, `rg`, `Get-ChildItem`, `Get-Item`, and `Test-Path`, with identity-bearing lines filtered from relevant output. Public-source browsing used search, open, and find.

Unsuccessful attempts: Python executable unavailable; shell network request denied; several public URLs unavailable; two searches had PowerShell path/syntax errors. Corrected local reads supplied the required evidence.

No Git, builds, device commands, or credential-file reads.

**4. Tests run and results**

No implementation or device tests run.

`Test-Path B/T210-bundle/RESULT.md` returned **False**. T210’s reconciliation records offline checks; this review did not independently establish its car-test outcome. `R/CLAUDE-T210-RECONCILE.md:3`.

**5. Findings and numbered design changes**

All changes below are **proposals**, targeting the corresponding files in a new T220 source tree. T210 remains reference evidence.

1. **Separate the owner setting from Developer testing — HIGH confidence.**  
   In `AppSettings.java`, add `wirelessEnabled()` / `setWirelessEnabled()` with **default OFF**, saved synchronously. Do not migrate `WIRELESS_TEST=on` into owner consent. In `SettingsActivity.mainPage()`, add **Wireless Android Auto** and a short status line; keep test controls in `developerPage()`. Developer testing must use the same runtime, with explicit daily/test ownership, so its timeout or Stop cannot accidentally stop daily mode. Existing settings and test entry points: `J/AppSettings.java:91`, `:127`; `J/SettingsActivity.java:133`, `:275`.

2. **Start readiness through both existing boot paths — HIGH confidence.**  
   Add `WirelessProbeService.ensureDailyStarted(Context,String)`. Call it from `PersistentBootService.startOnce()` before the process-wide duplicate-start return, and from its `check()` reconciliation. Preserve `BootBlockerReceiver.onReceive()` and the media-source startup route. Restore leftover station/channel changes **before** a new group starts. Wireless startup must not wait for successful accessibility restoration; retain the one-time grant requirement for the accessibility functions. Evidence: `J/PersistentBootService.java:23`, `:44`; `J/BootBlockerReceiver.java:40`; `J/AaMediaSourceService.java:130`; `J/PersistentMode.java:69`.

3. **Make readiness last for the drive — HIGH confidence.**  
   In `WirelessProbeService.onStartCommand()`, distinguish daily mode from the timed Developer mode. Daily mode has no `windowEnd`; use `START_STICKY`, rechecking persisted intent after a null-intent restart. Add a foreground-service notification and a small `WirelessRuntimePolicy.java` with `OFF`, `WAITING_RADIOS`, `STARTING`, `READY`, `SESSION`, `RECOVERING`, `STOPPING`, and `ERROR` states. `READY` requires a valid owned group plus functioning listeners. Remove the lifetime 200-accept limits; retain bounded handshake deadlines and rate limits. Current expiry, non-sticky behavior, and caps: `J/WirelessProbeService.java:393`, `:460`, `:547`, `:597`.

4. **Recover components independently — HIGH confidence.**  
   Add `registerRuntimeReceivers()`, `reconcileRuntime()`, and `scheduleRecovery()` in `WirelessProbeService.java`. Observe Bluetooth state, Wi-Fi state, P2P state/connection changes, channel disconnection, and screen-on as a reconciliation hint. Reopen a failed Bluetooth listener without rebuilding a healthy group; invalidate credentials immediately when group loss is confirmed. Retry transient failures with bounded backoff, then wait for a relevant state change. Every callback captures a runtime generation; stale callbacks cannot publish credentials or remove a replacement group. Current initialization supplies no channel-disconnect listener: `J/WirelessProbeService.java:470`; failed accept loops simply exit at `:549` and `:599`.

5. **Give every transport one admission gate — HIGH confidence.**  
   Add `SessionArbiter.java` methods `tryReserve()`, `activate()`, `cancel()`, and `release()`, shared by `AaSessionService.acceptPhoneSocket()`, `onStartCommand()`, and USB admission. Include pending sockets, session starts, and active sessions under the same lock and generation. Policy: **an active session wins**; when idle, an eligible USB phone/dongle already ready to start wins over new wireless admission. Plugging USB into active wireless leaves USB waiting. Gate `UsbHelperService.handleAttached()`, `tick()`, and startup side effects before permission/AOAP work while wireless owns the receiver. Existing active-wireless refusal occurs too late to prevent earlier USB work: `J/AaSessionService.java:466`; `J/UsbHelperService.java:187`, `:261`, `:343`.

6. **Support one wireless driver without second-phone takeover — MEDIUM confidence.**  
   Add `WirelessPeerPolicy.java` methods `mayBootstrap()` and `matchesPendingJoin()`. Store an approved Bluetooth peer privately during parked enrollment; accept credentials requests only from an approved bonded peer. A second phone receives no credentials while another peer owns a pending or active session. Tie TCP acceptance to the current bootstrap and actual P2P client/interface evidence; a matching subnet alone is insufficient. Do not assume existing USB device approval proves Bluetooth identity. Current admission checks only the subnet: `J/WirelessProbeService.java:553`, `:784`; bootstrap begins without a peer-policy gate at `:614`.

7. **Rearm only after confirmed teardown; stop pending work too — HIGH confidence.**  
   Move wireless session-end notification from the beginning of `AaSessionService.shutdown()` into the completed teardown path, carrying unique generation, transport, clean/unclean result, and stop reason. A clean unexpected end rearms against the existing healthy group. Unclean worker/native cleanup blocks another session. Owner switch-off cancels reservations and pending sockets, closes listeners, ends only the matching wireless session, removes only the owned group, and finishes restoration. Keep cleanup alive until callbacks finish; persist unfinished restoration for restart. Current notification precedes worker joins, TCP uses generation zero, and `stopTcpSession()` ignores pending handoffs: `J/AaSessionService.java:132`, `:122`, `:1361`, `:1375`, `:1430`.

8. **Preserve Honda calls and Gemini behavior — HIGH confidence.**  
   Daily mode must never call `nudge()`, `hondaReconnect()`, register substitute HFP/HSP services, or cycle Bluetooth. Treat Honda reconnect broadcasts as readiness hints; do not initiate a Honda disconnect/reconnect. Preserve session-scoped `TalkBridge` registration and call guards, and retain T210’s Wi-Fi restore-picture and still-screen fixes. Existing disruptive experimental paths: `J/WirelessProbeService.java:244`, `:261`, `:356`; assistant setup: `J/AaSessionService.java:865`; Wi-Fi fixes: `:1292`, `:1345`.

9. **Decouple Quiet, band, and Bluetooth security — MEDIUM confidence.**  
   Daily configuration should request 5 GHz and initially retain the tested RFCOMM listener choice, while applying the peer gate above. **Quiet stays OFF**; a station connection or station scan must not trigger automatic profile disabling. Add independent Developer controls for Quiet and band so comparison changes only one variable. T200’s combination proves neither Quiet necessity nor actual operating band. Existing variants couple these choices: `J/AppSettings.java:94`; channel request: `J/WirelessProbeService.java:475`; station disabling: `:718`. If 5 GHz without Quiet fails, T220 has not passed daily acceptance; retain the proven combination for diagnosis.

10. **Respect Honda Wi-Fi ownership — HIGH confidence for policy; compatibility UNKNOWN.**  
    In `reconcileRuntime()`, wait with an actionable status when Network mode/Wi-Fi is off or Honda owns an incompatible mode. Do not force radios or Honda settings back on after the owner changes them. Honda hotspot startup explicitly disables station Wi-Fi, whereas Network mode enables it: `H/wifilibrary/statemachine/HotspotState.java:149`; `WifiState.java:241`. The exact function of the operator’s “Wireless Tethering” setting remains **UNKNOWN**; do not equate that label with hotspot mode.

11. **Keep dynamic identity for T220 — HIGH confidence in the conservative choice.**  
    Keep the same group throughout healthy session reconnects, but retain `AP_DYNAMIC` across group recreation and normal owned-profile cleanup. Do not advertise a remembered WPP TCP control endpoint. A persistent framework profile, stable network identity, and the phone’s STATIC declaration are separate requirements. API22’s inspected `createGroup()` supplies no explicit identity or stored-profile argument: `F/WifiP2pManager.java:486`; enumeration/deletion exist at `:596`, `:601`. Current declaration and cleanup: `J/WirelessProbeService.java:47`, `:794`.

12. **Improve startup readiness without Bluetooth pokes — MEDIUM confidence.**  
    In `startGroup()`, `startTcp()`, `startBluetooth()`, and `bootstrap()`, overlap listener startup with group formation. Request group information immediately, then poll briefly while formation is pending instead of imposing the initial 1.5-second delay. An early RFCOMM accept may wait a bounded few seconds for valid credentials off the main thread; cancel on generation change and never send a stale endpoint. Keep T200’s working message sequence. This borrows EarlyWakePolicy’s overlap idea, without its outgoing wake action. Evidence: `J/WirelessProbeService.java:449`, `:497`, `:615`; `N/EarlyWakePolicy.kt:6`.

**Owner-facing status and pairing**

Use: **Off**, **Starting**, **Ready—waiting for phone**, **Connecting**, **Connected wirelessly**, **USB in use**, **Waiting for Bluetooth**, **Turn on Honda Wi-Fi Network mode**, or **Recovery paused—setup needed**. “Connected” should follow a live AA session/first frame, not TCP handoff; current status advances at handoff: `J/WirelessProbeService.java:562`.

First-time instructions, shown while parked:

- Enable Wireless Android Auto and wait for Ready.
- Keep Honda Wi-Fi in Network mode and Bluetooth on.
- If the phone was paired before wireless was enabled, remove the existing car pairing from both sides and pair again **while Ready**, then accept phone prompts.
- Verify Honda calling afterward. Re-pairing is setup recovery, not a normal startup step.

The recorded re-pair success also involved a tethering-setting change, so its independent necessity is **UNKNOWN**. `B/T190-bundle/RESULT.md:7`.

**Risks**

- **HIGH:** automatic cold-start connection after enrollment has not been established by the inspected results.
- **HIGH:** pending-handoff and teardown races could create overlapping sessions unless admission is centralized.
- **MEDIUM:** no-Quiet station/P2P coexistence and effective 5 GHz operation need isolated testing.
- **MEDIUM:** an external dongle can influence the phone independently of Hackura’s arbitration.
- **MEDIUM:** Android may kill the process or suspend without cleanup callbacks; startup restoration must handle this.
- **MEDIUM:** persistent STATIC enrollment could strand the phone on stale identity or endpoints.

**6. Primary evidence and open-source comparison**

- T200 records native bootstrap, TCP handoff, first frame, and a session ending when the test was disabled: `B/T200-bundle/RESULT.md:7`. Its call result is partial at `:10`; full daily reliability is not established.
- Open-headunit keeps a healthy network and rearms listeners after an unexpected end: `N/SessionEndGroupPolicy.kt:24`; `NativeAaHandshakeManager.kt:1175`. It explicitly models listener failure recovery: `AaListenerRecoveryPolicy.kt:13`.
- Its intended STATIC semantics keep network credentials; DYNAMIC returns through Bluetooth. Remembered WPP endpoints require stable identity and can outlive endpoint withdrawal: `N/WppEndpointPolicy.kt:23`, `:38`. Exact proprietary phone storage on this tested phone is **UNKNOWN**.
- aa-proxy-rs uses a continuing connection loop and suppresses wireless advertising for wired USB: [`src/main.rs:971`](https://github.com/aa-proxy/aa-proxy-rs/blob/main/src/main.rs#L971). Its optional quick-reconnect mode holds RFCOMM and repeats bootstrap; ordinary parameter delivery still declares DYNAMIC: [`src/bluetooth.rs:5938`](https://github.com/aa-proxy/aa-proxy-rs/blob/main/src/bluetooth.rs#L5938), [`:7426`](https://github.com/aa-proxy/aa-proxy-rs/blob/main/src/bluetooth.rs#L7426). These Linux Bluetooth actions should not be copied wholesale onto Honda.

**Proposed T220 test plan — not run**

Add `W220_STATE`, `W220_READY`, `W220_RETRY`, `W220_ADMISSION`, `W220_END`, and `W220_CLEANUP` markers. Log elapsed times, generations, reasons, counts, and equality booleans only. Preserve existing P4/T200/first-frame markers.

| Test | PASS criteria |
|---|---|
| Offline lifecycle and race tests | Duplicate boot requests create one runtime; late callbacks and queued handoffs cannot survive Off; USB/TCP races admit one session; unclean teardown prevents reentry. |
| Parked enrollment | Pair while Ready; native wireless reaches first frame without phone head-unit server or Developer wireless test. Honda calls remain functional. |
| Three cold power cycles and one warm wake | Owner setting persists; no app opening, re-pair, test toggle, or Bluetooth poke needed. Record boot→Ready→bootstrap→first-frame times. |
| Provisional speed target | Ready within 15 seconds of service entry after radios are available; first frame within 30 seconds of Ready. These are acceptance targets, not measured promises. |
| Parked radio recovery | After Bluetooth and Wi-Fi restarts, listeners/group recover without duplicate records or stale credentials; AA reconnects after radios become available. |
| USB phone and dongle | Active wireless continues; idle USB wins; unplug allows wireless readiness again. Include simultaneous startup and an unrelated USB device. |
| Second phone | No takeover, credential leak, or overlapping session; approved phone still reconnects afterward. |
| Quiet comparison | Compare identical 5 GHz configurations with Quiet off/on. Daily acceptance requires Quiet off to work with saved station networks present. |
| Honda Wi-Fi settings | Change Network mode and the separate tethering setting independently. No radio-setting fight; returning to supported mode restores readiness. |
| Parked endurance | At least 45 minutes, including idle time and session reconnects; no 30-minute expiry or listener exhaustion. |
| Calls and Gemini | Incoming/outgoing Honda calls work both ways; media resumes; talk-button Gemini works; no wireless-induced HFP disconnect. |
| Clean stop and interrupted cleanup | Off during group creation, bootstrap, pending handoff, and projection leaves no late session. Previously paused station profiles and channel settings restore; failed restoration remains recorded for retry. |
| Short drive | Start/reconnect through services and overlays without launching Settings or another Activity. Calls, Gemini, Home/restore, navigation, and music remain usable; no false Wi-Fi stuck-screen minimize. |

Motion-path precedent is the service-based USB attach route: `J/UsbHelperService.java:300`; wireless should follow that model without changing Honda’s motion restrictions.

**7. Assumptions**

- The existing persistent-mode installation and one-time grant are retained.
- Active-session priority is the proposed product policy.
- Changes are built from a T220 copy; historical bundles remain untouched.

**8. Unresolved uncertainties**

**UNKNOWN:** T210 live outcome; cold-start phone initiation; Quiet necessity; actual 5 GHz operation; the tethering setting’s role; stable API22 group identity; exact phone persistence; warm-wake signaling; multi-phone and external-dongle behavior.

**9. Exact diff summary**

None; design only.

**10. Preservation checks performed**

Only read/search/metadata operations were issued. No builds, file writes, Git operations, device access, or frozen-artifact modification occurred. Frozen hashes were not recalculated; independent byte-for-byte preservation is **UNKNOWN**.