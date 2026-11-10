**Verdict: NOT READY.** Static review found blocking lifecycle and wired-handoff defects.

1. **Files inspected:** `PROJECT-RULES.md`, `AGENTS.md`, `CODEX-WIRELESS.md`; T160 files and reference files cited below.
   Aliases: `B=analysis/test-prep/todo-tests-20261103/builds/T160-bundle`; `U=B/source/analysis/parallel-aa-receiver/usb-helper`; `J=U/source/com/rdx/fullscreen/usbhelper`; `W=J/WirelessProbeService.java`.
   `O=analysis/parallel-aa-receiver/offline-followup/public/open-headunit/andreknieriem-open-headunit-e9377ff/app/src/main`; `F=decompiled/Framework/sources/android`.

2. **Files changed:** none.

3. **Commands run:** read-only `Get-Content`, `rg`, `Select-Object`, `ForEach-Object`, `Get-FileHash`, `Format-List`. One PowerShell brace-list search failed; corrected.

4. **Tests run/results:** none executed. Saved results report “PASS 211 bundle checks”; wireless checks cover encoding and a field-1 status example, not lifecycle (`B/host-test-output.txt:9`; `B/BundleTests.java:110–120`).

5. **Findings:**
   - **OK — framing:** payload-length uint16 BE, type uint16 BE, payload; partial reads handled (`W:235–255`; `O/java/com/andrerinas/openheadunit/connection/wifi/modes/nativeaa/WppFraming.kt:38–64`).
   - **OK — WifiStartRequest:** string field 1 and int32 field 2 match. Omitting optional reason field 3 is schema-compatible; explicit USER_REQUEST=0 would improve clarity (`W:258–262`; `O/proto/wireless.proto:57–69`).
   - **OK — WifiInfoResponse:** strings 1/2/3, varints 4/5, WPA2=8 and DYNAMIC=1 match (`W:264–278`; `O/proto/wireless.proto:17–19,31–37,88–94`).
   - **SHOULD-FIX — status replies:** `firstVarint` only recognizes leading field 1. Type 7 status is field 3; type 5 status is field 4. Type 6 works only when status appears first. Parse by message type and field number (`W:224–225,280–285`; `O/proto/wireless.proto:146–154,171–184`).
   - **OK — initiation/version:** HU sends type 1 before waiting for credentials request; waiting for the phone first is unnecessary. Types 4/5 are optional for this basic exchange; type 5 is the phone’s response (`W:218–227`; `O/java/com/andrerinas/openheadunit/connection/wifi/modes/nativeaa/WppHandshakeSession.kt:119–125,264–269`).
   - **OK / SHOULD-FIX — IP/port/readiness:** using formed-group owner IP and 5288 is consistent. Credentials become available independently of TCP bind success, so the phone can receive an unusable endpoint (`W:43,144–148,163–165,218`).
   - **BLOCKER — wired BSSID:** registration can retain the station MAC before group readiness, while later returning group credentials. Furthermore, `getOwner().deviceAddress` comes from `go_dev_addr`; equality with the interface BSSID is **UNKNOWN**. Obtain and validate the actual group-interface BSSID before registration (`J/AaSessionService.java:819–826,857–864`; `W:145`; `F/net/wifi/p2p/WifiP2pGroup.java:23,74`).
   - **BLOCKER — AA callback blocking:** the native callback synchronously calls `credentials(3000)`, which waits when no group exists. This demonstrably blocks that callback; wider AA impact is **UNKNOWN**. Supply an already-ready snapshot (`J/AaSessionService.java:861`; `W:61–69`; `U/source/com/google/android/projection/protocol/WifiProjectionEndpoint.java:32–33`).
   - **BLOCKER — stop/window cleanup:** accepted RFCOMM sockets are local variables, with an unbounded read; shutdown closes only listeners. Accepted TCP sockets also survive shutdown until reads finish. TCP listener creation can race shutdown (`W:161–181,200–222,252–255,291–299`).
   - **BLOCKER — group ownership/races:** BUSY sets `groupRequested=true`, authorizing removal of a group this run did not create. Conversely, create success arriving after stop returns without removing the newly created group (`W:121–126,300–307`).
   - **OK structurally — Honda Bluetooth/HFP:** P4 adds only the AA RFCOMM service; it does not cycle Bluetooth or create dummy HFP. Actual Honda call/coexistence impact remains **UNKNOWN** (`W:189–209`; reference warning: `O/java/com/andrerinas/openheadunit/connection/wifi/modes/nativeaa/HfpServiceRecordPolicy.kt:7–11`).
   - **SHOULD-FIX — privacy:** credential logging uses lengths/booleans, but arbitrary TCP bytes and exception messages are logged. Remove these before claiming identifier-free logging (`W:150–151,164,179`; `J/AaSessionService.java:829,863`).
   - **SHOULD-FIX — non-phone failure attribution:** no Wi-Fi-enabled/station-state or band preflight exists; default-band `createGroup` does not establish 5 GHz. Unsupported-band refusal is represented by the reference protocol (`W:116–155`; `O/proto/wireless.proto:22–27`).
   - **SHOULD-FIX — persistence:** framework `createGroup` requests persistent mode; cleanup removes the active group without deleting its persistent profile (`F/net/wifi/p2p/WifiP2pManager.java:486–488`; `F/net/wifi/p2p/WifiP2pGroup.java:14`; `W:300–308`).
   - **SHOULD-FIX — PASS attribution:** wildcard TCP accept immediately declares phone/Wi-Fi PASS without verifying the incoming interface or peer. Any reachable client can trigger it (`W:163,170–173`).
   - **OK — feature controls/permission:** default off, Developer start/stop button, INTERNET permission and non-exported probe service are present (`J/AppSettings.java:38,64,98`; `J/SettingsActivity.java:257–262`; `U/AndroidManifest.xml:20,52`).

6. **Primary evidence:** path-and-line citations accompany every finding above; external implementation material was treated as reference, not proof of phone behavior.

7. **Assumptions:** supplied T160 source is the review target; APK/source parity was not established.

8. **Unresolved uncertainties:** actual BSSID, hosting band, station/P2P coexistence, phone discovery/join, native scheduling and Honda HFP behavior.

9. **Exact diff summary:** none.

10. **Preservation checks:** source hashes recorded; `W` SHA-256=`52AB49B8629B6C701106F80A5FA1E656DA192A44EC281ACE71922AF2C300094E`. No writes, builds, Git, network, device access or credential/private-material reads; frozen-artifact hashes were not audited.