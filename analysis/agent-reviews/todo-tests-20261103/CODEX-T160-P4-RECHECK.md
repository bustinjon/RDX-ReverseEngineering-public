1. **Files inspected:** `PROJECT-RULES.md`, `AGENTS.md`, prior `CODEX-T160-P4.md`, both target Java files, framework `WifiP2pManager.java`/`WifiP2pGroup.java`.
   Aliases: `J=analysis/test-prep/todo-tests-20261103/builds/T160-bundle/source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper`; `W=J/WirelessProbeService.java`; `A=J/AaSessionService.java`.

2. **Files changed:** none.

3. **Commands run:** read-only `Get-Content`, `rg`, numbered `ForEach-Object`, `Get-FileHash`, `Format-List`. Initial abbreviated bundle-path search failed; corrected.

4. **Tests run/results:** none; static review only.

5. **Findings — verdict: NOT READY.**
   - **BLOCKER, wired BSSID — FIXED:** group-interface hardware MAC supplies the same snapshot used for registration and credentials (`W:151-155,318-326`; `A:825-827,858-865`).
   - **BLOCKER, callback blocking — FIXED:** snapshot uses `credentials(0)`; callback performs no wait; unavailable group suppresses Wi-Fi registration (`A:825-827,857-865`).
   - **BLOCKER, stop/window cleanup — NOT FIXED:** shutdown can occur between TCP accept and client publication, missing that socket before its subsequent blocking read (`W:179-189,393-394`). RFCOMM tracking and 60-second timeout are present (`W:216-221`).
   - **BLOCKER, group ownership/races — FIXED:** failed creates never confer ownership; success after stop invokes removal (`W:125-135,340-345`).
   - **SHOULD-FIX, status replies — FIXED:** field-numbered varints replace leading-field-only parsing (`W:239-240,299-307`).
   - **NEW ISSUE, parser hang:** payload hex `12 FA FF FF FF 0F` makes the length cast to `-6`, returning index 6 to zero forever. Socket closure cannot terminate this parsing loop (`W:302-307,312-315`).
   - **SHOULD-FIX, TCP readiness — NOT FIXED:** bind gates initial readiness, but shutdown between the running check and `tcpReady=true` leaves readiness true for a closed listener (`W:152,170-174,391-392`).
   - **SHOULD-FIX, privacy — NOT FIXED:** TCP logs only byte counts; registration failures still concatenate exceptions, including messages (`W:191`; `A:855,873`).
   - **SHOULD-FIX, failure attribution — NOT FIXED:** Wi-Fi-enabled preflight is logged; actual band and station connection state remain unestablished (`W:105,334-335`).
   - **SHOULD-FIX, persistence — NOT FIXED:** stopping before readiness, including late-create success, leaves `groupName=null`; profile deletion explicitly skips it (`W:127,153,343,354`).
   - **SHOULD-FIX, PASS attribution — NOT FIXED:** peer filtering assumes `/24` through textual prefix comparison; it never obtains the group interface’s actual prefix (`W:183-185,329-332`).

6. **Primary evidence:** source path/line citations above; parser counterexample is derived statically, not executed.
7. **Assumptions:** supplied bundle source is the review target.
8. **Unresolved uncertainties:** APK/source parity, actual subnet prefix/BSSID/band, phone interoperability and Honda coexistence are **UNKNOWN**.
9. **Exact diff summary:** none.
10. **Preservation checks:** target-source SHA-256 hashes recorded; no writes, builds, Git, network, device access or credential-material reads. Frozen-artifact hashes not audited.