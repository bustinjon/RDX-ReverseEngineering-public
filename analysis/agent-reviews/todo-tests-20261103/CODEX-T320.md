Paths: `B=analysis/test-prep/todo-tests-20261103/builds`; `S=B/T320-bundle/source/analysis/parallel-aa-receiver/usb-helper`; `APP=S/source/com/rdx/fullscreen/usbhelper`.

1. **Files inspected:** `PROJECT-RULES.md`, `AGENTS.md`, Fable `REPORT.md`; the five requested files in T310/T320; supporting settings, callers, Bluetooth wrapper, runner, cleanup, saved logs and Android service-permission sources.
2. **Files changed:** none.
3. **Commands run:** `Get-Content`, `rg`, `Compare-Object`, `Get-Command`, `Get-ChildItem`, Node read/diff/argument checks and local `sh` mocks. Python launch attempts failed; Node completed the comparisons.
4. **Tests/results:** JSON parsing and PowerShell argument preservation passed. Mock hooks reproduced the missing-success-marker failure. No builds or application/device tests run.
5. **Findings — verdict: BLOCKER; fix UNDO before approval.**
   - **BLOCKER:** `B/T320-bundle/test.json:122` ends with `exit 0`, preventing Invoke-Hook’s appended marker from executing. Successful verification therefore throws before `pm revoke`. Run verification inside a subshell or use a non-exiting final status.
   - **SHOULD-FIX:** `test.json:121` deletes without consulting saved originals. Correct for this car’s recorded unset originals; incorrect for a car whose originals were set, including legitimately `300000`. Restore saved values and verify equality.
   - **OK:** `APP/WirelessProbeService.java:711` replaces display text only. The found consumers are Settings labels; credentials still come from the separate `Network` object.
   - **OK, inspected callers:** DUMP preserves same-UID starts/binds and app-created PendingIntents. Accessibility callbacks execute inside this app; inspected Honda integrations use other components. Shell access follows the supplied premise that shell holds DUMP.
   - **SHOULD-FIX / qualification gap:** `APP/AaSessionService.java:866` advertises Bluetooth even with daily wireless off. `:1022` suppresses Wi-Fi endpoint advertising, but pairing methods and readiness replies remain active (`:1027–1048`). Pairing prompts/HFP changes remain possible; harmless wired behavior and absence of phone-initiated wireless switching are **UNKNOWN**.
   - **SHOULD-FIX:** `APP/WirelessProbeService.java:192` treats lookup exceptions as interface loss; stale interface names receive no refresh. Two such observations call shutdown during an active Wi-Fi session. Confirm current group identity before destructive recovery; reset `groupMissing` on shutdown/new-group acquisition.
   - **OK:** Genuine group loss warrants ending its Wi-Fi session. `APP/WirelessProbeService.java:1100` stops TCP sessions, and `:1104` clears `groupIface`; USB sessions are excluded by `AaSessionService.java:130–132`.
6. **Primary evidence:**
   - Runner: `analysis/test-prep/todo-tests-20261103/tools/Run-Test.ps1:49–51`. Local mock: deletion hook returned `RDX_HOOK_RC:0`; verification returned exit **0**, stdout **empty**, marker acceptance **false**.
   - Restoration: `APP/WirelessProbeService.java:977–990`; original-unset record: `B/T300-bundle/headunit-logs-20261110-153805/hackura-20261110-122954.txt:24`.
   - Status consumers: `APP/SettingsActivity.java:140,349`; credential publication: `APP/WirelessProbeService.java:709–710`.
   - Permissions: `S/AndroidManifest.xml:46,53,58`; `decompiled/Framework/sources/android/app/ActivityManager.java:1416–1433`; `decompiled/Services/sources/com/android/server/am/PendingIntentRecord.java:229`.
   - Bluetooth is operational pairing functionality: `decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/bluetooth/BluetoothManager.java:449–451`; T320 replies at `APP/AaSessionService.java:1040`.
   - Watcher coverage adds only threshold assertions: `B/T320-bundle/BundleTests.java:166`; lifecycle behavior is untested.
7. **Assumptions:** shell holds DUMP, as supplied; saved car logs describe the tested car.
8. **Unresolved uncertainties:** Exact Android 5.1 `settings delete global KEY` parser/runtime behavior is **UNKNOWN** from inspected local evidence. Quote transport passed; pairing/HFP and interface-renaming behavior require runtime evidence.
9. **Exact diff summary:** No review changes. T310→T320 removed/added lines: Wireless **2/19**, Session **3/5**, manifest **3/3**, JSON **14/16**, tests **0/1**.
10. **Preservation checks:** Read-only operations only; no Git, network, device access, builds or key-material reads. Frozen artifacts were untouched; hashes were not rechecked.