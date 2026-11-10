1. **Files inspected:** `PROJECT-RULES.md`, `AGENTS.md`, T190 `RESULT.md`; both bundles’ scoped Java files; reference handshake, TCP policy, socket, transport and TLS sources.
   Evidence aliases: `B=analysis/test-prep/todo-tests-20261103/builds`; `S=source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper`.
   `A=B/T200-bundle/S/AaSessionService.java`; `W=B/T200-bundle/S/WirelessProbeService.java`.
   `O=analysis/parallel-aa-receiver/offline-followup/public/open-headunit/andreknieriem-open-headunit-e9377ff/app/src/main/java/com/andrerinas/openheadunit`.
2. **Files changed:** none.
3. **Commands run:** read-only `Get-Content`, `rg`, `Get-ChildItem`, `Get-FileHash`, `fc.exe`. Python was unavailable; initial slash-path comparisons and a guessed reference path failed and were corrected.
4. **Tests run and results:** none; static review only. Hash comparison identified exactly two differing scoped Java files: `AaSessionService.java`, `WirelessProbeService.java`; `fc.exe` confirmed `GalReceiver.java` identical.
5. **Findings — verdict: NOT READY.**
   - **BLOCKER:** After projection starts, bootstrap still answers type 2 with credentials. The reference explicitly suppresses this because it can make the phone re-associate and drop projection. Add a projection-established holding state.
   - **SHOULD-FIX:** Wireless STOP does not explicitly terminate the handed-off AA socket. It closes bootstrap and requests group removal; prompt, clean session termination is **UNKNOWN**, particularly if removal fails.
   - **SHOULD-FIX:** Reconnect lifetime remains bounded: Bluetooth stops accepting after 10 connections, TCP after 200. An established bootstrap also remains held after AA ends unless the peer closes it, potentially blocking the next Bluetooth bootstrap.
   - **SHOULD-FIX:** A `startService()` exception leaves `handoffSocket` occupied and escapes the TCP listener; ownership transfer needs rollback and close.
   - **OK:** HU speaks first; accepted TCP and phone-server TCP share the protocol path. HU remains TLS client regardless of who initiated TCP.
   - **OK:** Ping response is type 9 with the unchanged type-8 payload. The reference requires only ping responses during its holding state.
   - **OK, qualified:** Current handoffs have one serial TCP producer and a main-thread ownership recheck. Successful handoffs avoid probe closure; refused sockets close, although producer-side refusal waits up to five seconds.
   - **OK:** USB START during Wi-Fi is refused with `notifyEnded`; the branch does not shut down Wi-Fi. The automatic window extends during an active session.
6. **Primary evidence for each finding:**
   - Credential resend: `W:632–636`; reference `O/connection/wifi/modes/nativeaa/WppHandshakeSession.kt:243–250`, `NativeAaHandshakeManager.kt:3226–3233`.
   - STOP: `W:841–860`; removal failure `W:802–806`; blocking TCP read `A:76–78`; I/O-error cleanup `A:1070–1073,1113–1120`.
   - Reconnect limits/held channel: `W:545,595–605,620–636`; session-ended handler does not release bootstrap: `W:414–428`.
   - Handoff exception/slot: `A:110–116`; caller has no exception cleanup around acceptance: `W:556–573`.
   - Shared startup: `A:119–128,498–506,543–544,837–852`; writer sends native output: `A:1081–1090`.
   - Reference projection acceptance: `O/connection/wifi/server/WirelessServer.kt:129–146`; HU version transmission: `O/aap/AapTransport.kt:1127–1139`; TLS client: `O/aap/AapSslContext.kt:147–148`, `O/connection/wifi/modes/nativeaa/WppTcpTls.kt:10–22`. `WppTcpServePolicy.kt:15–17` gates WPP control serving; it does not select projection TLS role.
   - Ping/framing: `W:624–628,642–657`; reference `WppHandshakeSession.kt:19–21,243–250`.
   - Ownership/refusal: `W:558–573`; `A:498–506`. USB refusal: `A:457–463`; window extension: `W:393–395`.
7. **Assumptions:** Supplied T190 live outcomes are accepted as background; no live logs were independently examined.
8. **Unresolved uncertainties:** Actual phone behavior on late type 2, network-loss timing and native-library TLS internals are **UNKNOWN**; shared Java startup establishes path parity, not live success.
9. **Exact diff summary:** No review edits. Bundle differences add accepted-socket startup/shared initialization, ping handling, bootstrap retention, window extension and increased TCP accept limit.
10. **Preservation checks performed:** Read-only source comparisons only; no builds, Git, network, devices, credential/private-test reads or frozen-artifact modifications. Frozen hashes were not reverified.