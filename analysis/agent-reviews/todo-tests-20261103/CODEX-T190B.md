1. **Files inspected**
`J` = `analysis/test-prep/todo-tests-20261103/builds/T190-bundle/source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper`.
`H` = `decompiled/HondaSettings`; `G` = `decompiled/AndroidAuto-current/sources/com/google/android/projection`.
Read `PROJECT-RULES.md`, `AGENTS.md`, `CODEX-WIRELESS4.md`, `SETTINGS-SPEC.md`; J’s session, helper, wireless, settings and AppSettings sources; bundle manifest/VideoSink; H’s Binder/service/state/helper/profile sources; G’s stream/TCP/USB transport sources.

2. **Files changed:** none.

3. **Commands run:** read-only `Get-Content`, numbered excerpts, `rg --files`, `rg -n`, `Select-Object`. Several guessed paths were absent; corrected filename searches followed. No Git, network, builds or device commands.

4. **Tests run and results:** no executable tests. Static review established the parcel match, 16 controls, and counterexamples below; runtime behavior remains untested.

5. **Findings:** **NOT READY** for car test. TCP cancellation and Honda HFP restoration have blocking defects.

6. **Primary evidence for each finding**

| Item | Assessment and evidence |
|---|---|
| T200 GAL framing | **OK at source level:** both pipes feed the same four-byte-header reader and native output writer, without an added TCP envelope (`J/AaSessionService.java:65–81,989–1026`). Google’s stock TCP transport likewise passes socket streams directly (`G/transport/net/TcpTransport.java:15`, `G/transport/StreamTransport.java:31–37`). [Google DHU reference](https://developer.android.com/training/cars/testing/dhu), retained in `CODEX-WIRELESS4.md:89`; not fetched under the no-network constraint. Exact DHU/target-phone interoperability is **UNKNOWN**. |
| T200 threading | **OK:** connect/DNS runs in the worker (`J/AaSessionService.java:458–483`); stream reads/writes run in dedicated threads (`:821–833,989–1026`). Address selection performs local file/Wi-Fi-service access, not a TCP connection (`J/WirelessProbeService.java:79–111`). |
| START_TCP versus USB START | **BLOCKER:** TCP reserves `sessionActive`, so a subsequent USB START is silently ignored (`J/AaSessionService.java:417–420,455`). The USB helper already tracks that handoff and eventually treats its missing generation as overdue (`J/UsbHelperService.java:622–644,656–670`). Arbitration needs an explicit outcome for the losing request. |
| Stop/connect race and cleanup | **BLOCKER:** the connecting socket exists only in the worker; Stop cannot close it. A later successful callback checks neither cancellation nor service destruction and can reopen the overlay (`J/AaSessionService.java:459–481,1287,1345`). Established sockets close, but `onDestroy` before `running` only reports an end and does not close `pendingSocket` (`:1377–1383`). |
| SESSION_ENDED generation 0 | **OK in isolation; BLOCKER in the mixed-start case:** an inactive reconnect tracker ignores the notification; a positive USB generation cannot match TCP’s zero and may expire unclean (`J/AaSessionService.java:476,1357–1365`; `J/UsbHelperService.java:657–670`). |
| Remaining USB assumptions / focus | **OK structurally:** USB permission/device access is confined to USB START and the USB transport branch (`J/AaSessionService.java:422–436,773–784`). Video-focus requests contain no USB dependency (`:1101–1116,1200–1214`; bundle `VideoSink.java:37–38`). Live focus behavior is **UNKNOWN**. |
| Phone address selection | **SHOULD-FIX:** any connected station gateway is labelled “phone hotspot”; otherwise the first complete p2p ARP entry wins. Neither identifies the intended phone (`J/WirelessProbeService.java:79–100`). |
| On-screen passphrase | **OK for manual joining within this test’s scope:** credentials enter the display status; the adjacent log emits lengths only (`J/WirelessProbeService.java:479–481`; `J/SettingsActivity.java:272`). This does not prove screenshots or external capture cannot expose them. |
| T210 parcel | **OK:** token, three integers, presence flag, device parcel and boolean reply match case 19 exactly (`J/WirelessProbeService.java:264–269`; `H/sources/com/honda/settings/btmanager/IBluetoothService.java:322–335`). |
| Cross-process refusal | **OK exception handling; runtime access UNKNOWN:** bind failures and Binder exceptions are logged (`J/WirelessProbeService.java:255–271`). Honda exports the service without a component permission and returns its Binder (`H/resources/AndroidManifest.xml:401–404`; `H/.../btservice/LocalService.java:540–541`). Downstream work is posted to Honda’s handler (`H/.../btservice/utils/BluetoothConnectionHelper.java:124`); no UID refusal is established by this review. |
| HFP restoration on every exit | **BLOCKER:** Stop, normal destruction and unbind attempt restoration (`J/WirelessProbeService.java:274–284,795,804`), but recovery state is cleared before reconnect succeeds. Service loss only logs (`:253,275–277`). A dead Binder, exception or Honda refusal leaves no retained recovery obligation; refusal is explicitly possible (`H/.../btservice/statemachine/BluetoothState.java:369–376`). |
| Four-second “reconnect” result | **BLOCKER:** Honda’s boolean can mean only that work was queued (`H/.../btservice/utils/BluetoothConnectionHelper.java:124`). The implementation neither waits for confirmed disconnect before reconnecting nor confirms restored HFP before clearing state (`J/WirelessProbeService.java:250–251,274–278`). |
| Call safety | **SHOULD-FIX:** checks cover current AudioManager modes before binding/disconnecting, but do not monitor calls during the interruption (`J/WirelessProbeService.java:239,248–251,288–292`). Whether Honda exposes every relevant call through those modes is **UNKNOWN**. |
| Double runs | **SHOULD-FIX:** scheduling/pending guards cover ordinary repeats (`J/WirelessProbeService.java:236,373–376`), but `onServiceConnected` has no operation-identity or already-pending guard; repeated service connection callbacks can disconnect again and create multiple finish timers (`:245–253`). |
| Developer page fit | **SHOULD-FIX:** 16 controls means eight rows (`J/SettingsActivity.java:237–279,307`). Sizing uses display height and minimum heights; actual heights remain content-driven, with long credentials/status text and no scroll container (`:98–102,272,307–322`). Fit is **UNKNOWN** until rendered at the available app-area size. |

7. **Assumptions:** supplied T190 sources are the intended review target; installed-binary parity is not assumed.

8. **Unresolved uncertainties:** phone-server compatibility, live Binder access, actual HFP/call recovery, focus behavior and rendered Settings fit.

9. **Exact diff summary:** none.

10. **Preservation checks performed:** only read commands were issued; credential/private-test material and frozen binaries were not opened. No writes, milestone actions or device access occurred. Frozen hashes were not rechecked.