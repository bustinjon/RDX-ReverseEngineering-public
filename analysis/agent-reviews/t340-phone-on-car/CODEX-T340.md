The review found **two setup-selection hazards, incomplete device discovery, and a conditional wireless restore gap**. I found no direct USB takeover path while setup mode remains active.

1. **Files inspected**

   Path abbreviations below:

   - `B` = `analysis/test-prep/todo-tests-20261103/builds/T340-bundle`
   - `U` = `B/source/analysis/parallel-aa-receiver/usb-helper`
   - `J` = `U/source/com/rdx/fullscreen/usbhelper`

   Inspected `PROJECT-RULES.md`, `AGENTS.md`, the supplied `t340.diff`; T340 policy, service, Settings, launcher, boot, wireless and session sources; manifest and device filter; source/build manifests; relevant host tests and stored results; corresponding T330 sources; installer device-list/rename code and test excerpts.

   Also inspected canonical `UsbAttachActivity.java` and `UsbBulkTransport.java`, whose hashes match T340’s build report, and relevant Android 5.1.1 AOSP sources.

2. **Files changed**

   None.

3. **Commands run**

   Read-only commands: `Get-Content`, `rg`, `rg --files`, `Get-FileHash`, JSON parsing, and:

   ```text
   git diff --no-index --stat <T330 usb-helper> <T340 usb-helper>
   ```

   That comparison reported five changed files, 187 insertions and 10 deletions; exit 1 indicated differences.

   Used web retrieval for Android platform sources. No installer, device, build, or mutation commands ran.

4. **Tests run and results**

   - **22 read-only checks passed:** source-extracted policy expressions and structural assertions. These demonstrated that an unlisted serial is selectable, a storage-class device is recordable, terminal polling skips recording, cold listing skips initialization, and setup recording precedes permission validation.
   - These were **not Java/Android service execution tests**.
   - Stored `B/host-test-output.txt` reports `PASS 277 bundle checks` plus feature suites. I inspected that output; I did not rerun those suites.
   - Four reviewed T340 Java files matched `source-manifest.json`.
   - No car, phone, USB, or runtime permission tests ran.

5. **Findings, ranked by severity**

   **F1 — P2: An ordinary app can poison the setup selection list through exported UsbAttachActivity.**

   Counterexample: explicitly launch that activity with a fabricated, recordable `UsbDevice`. It forwards the object using its own UID as `AUTO_GRANTED`. In setup, `policyAllows()` calls `rememberDevice()` before rejecting takeover, before `hasPermission()`, and without resolving the object against `UsbManager.getDeviceList()`.

   This permits fabricated serial/product entries in the owner’s selection list. It does **not** directly set the main phone; the owner must still tap the poisoned entry. The DUMP restriction on direct service calls does not protect this intermediary.

   **F2 — P2: One tap can permanently select a stale or non-phone device, without an on-car correction path.**

   Counterexample: a USB stick with a valid serial and device class 8 passes `recordable()`, appears as “Make main phone,” and can become the main phone. `canChooseMain()` checks only setup state and serial syntax; it does not check list membership, current presence, or phone capability.

   Once selected, later selections are rejected. “Reset all” resets `app_settings`, not `honda_phone_policy`, so it does not undo this choice.

   Selecting a stick also authorizes permission requests and AOAP probing against it. The implementation sends AOAP string/start requests only after GET_PROTOCOL succeeds; actual effects on arbitrary non-phone hardware are **UNKNOWN**. Laptop-free recovery is absent. Whether that product restriction is acceptable is an owner decision, **UNKNOWN** from the supplied evidence.

   **F3 — P2: “Every plugged-in device is recorded” fails after handoff, failure, and some cold starts.**

   Counterexample A: main phone starts AA, making helper phase `GRANTED`; another unlisted device is then connected. Polling returns before `tick()`. The attach receiver ignores an unlisted serial, and generic devices do not match the activity’s USB filter. The new device need never reach `recentDevices`.

   Counterexample B: helper is stopped, a device is already connected, and the installer requests `LIST_DEVICES`. That action reads saved history and returns before polling initialization. Repeating the request does not discover the connected device.

   **F4 — P2, conditional: The new wireless skip can leave saved Wi-Fi recovery work pending on a cold daily/sticky restart.**

   Counterexample state: no main serial, `running=false`, and saved paused networks or scan settings remain from an earlier run—particularly relevant to old legacy installations during update or process restart.

   The new daily/null-intent gate calls `stopSelf()` without restoring those settings. `onDestroy()` calls `shutDown()` only when `running || groupCreated`, so this cold path does not restore them either.

   Explicit `ACTION_RESTORE` remains before the gate, and the boot receiver requests it. A running wireless session also bypasses the new gate. Thus this is a **cold daily/sticky recovery gap**, not evidence that normal boot restore or an active session is universally broken.

   **F5 — P2 compatibility change: Old null-serial legacy installations silently become setup installations.**

   T330’s `CONFIGURE_LEGACY` did not write `legacyAnyPhone`; T340 defaults the missing key to false. Consequently, an unchanged null-serial installation stops USB takeover and skips cold everyday wireless startup.

   This fails closed regarding Honda takeover, but breaks prior operation until the owner completes setup. The installer’s update branch says “Main phone unchanged”; it does not distinguish this migration. Acceptance of that migration is **UNKNOWN**.

   **F6 — P3: “Last plugged in” is an approximation, not a reliable attachment ordering.**

   Devices first observed together are processed in `HashMap.values()` order, and each insertion prepends to history. A disconnect/reconnect entirely between polls is invisible to the serial set. Old history is also retained after unplugging, and installer-added fallback entries can receive index zero without an observed attachment.

6. **Primary evidence for each finding and requested attack**

   | Finding | Primary evidence |
   |---|---|
   | F1 | [Manifest:35](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/test-prep/todo-tests-20261103/builds/T340-bundle/source/analysis/parallel-aa-receiver/usb-helper/AndroidManifest.xml:35) exports the activity without a permission. [UsbAttachActivity:23](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/UsbAttachActivity.java:23) accepts and forwards the supplied device. `J/UsbHelperService.java:292–298, 322–327, 835–836, 861–872` establish the recording path. |
   | F2 | [HondaPhonePolicy:127](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/test-prep/todo-tests-20261103/builds/T340-bundle/source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/HondaPhonePolicy.java:127), lines 133–134; `J/SettingsActivity.java:220–225, 251–264`; `J/AppSettings.java:14, 150–155`. AOAP probing: `J/UsbHelperService.java:883–925`. |
   | F3 | [UsbHelperService:403](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/test-prep/todo-tests-20261103/builds/T340-bundle/source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/UsbHelperService.java:403), lines 223, 246–256, 382–383, 418–424. `U/res/xml/device_filter.xml:4–13` limits activity matches. |
   | F4 | [WirelessProbeService:598](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/test-prep/todo-tests-20261103/builds/T340-bundle/source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/WirelessProbeService.java:598), lines 565–572, 988–1023, 1124–1137; `J/BootBlockerReceiver.java:47–48`. |
   | F5 | T330 `UsbHelperService.java:158–170`; T340 `J/HondaPhonePolicy.java:120–121`, `J/UsbHelperService.java:98–100, 186`, `J/WirelessProbeService.java:598–599`; [installer:449](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/hackura-installer/Hackura-Installer.ps1:449). |
   | F6 | `J/UsbHelperService.java:86–96, 410–423`; `J/HondaPhonePolicy.java:59–69`; `tools/hackura-installer/Hackura-Installer.ps1:379`. |

   Additional conclusions from the requested attack surface:

   - **Setup takeover:** startup avoids force-stop/VBUS at service lines 248–255; tick exits at 424; attach and permission callbacks use `policyAllows()` at 323 and 617; permission requests and session starts recheck it at 554 and 680; AOAP switching rechecks `rawPolicyAllows()` at 884. `tryDirectGrant()` has one call site, after the callback’s non-null-device policy rejection. Null callback devices cannot reach that call. `LAUNCH` only rearms polling; sticky startup reloads policy before startup effects. I found no direct setup takeover counterexample through these paths.
   - **SET_MAIN races:** successful first selection updates preferences; duplicate taps then fail `canChooseMain()`. Initialized service removes/reposts polling; cold service falls through to normal initialization (`UsbHelperService.java:199–220, 246–256`). Android delivers service starts through its main-thread message handler, supporting serialization with this service’s `Handler`. [AOSP ActivityThread](https://raw.githubusercontent.com/aosp-mirror/platform_frameworks_base/android-5.1.1_r38/core/java/android/app/ActivityThread.java)
   - **Existing configured main:** strict T330 parity is false for non-OnePlus phones: T330 switched non-OnePlus extras only; T340 also switches a matching main serial. The configured OnePlus main retains its existing policy/switch path, with additional recording work. Source-level comparison is not runtime parity proof.
   - **Growth and churn:** normal history is capped at eight and custom names at sixteen (`HondaPhonePolicy.java:58–69, 139–159`). Stable connected serials avoid repeated commits (`UsbHelperService.java:866–869`). Failed commits retry; repeated getter exceptions log each tick. Commits are synchronous on the main thread. Actual latency is **UNKNOWN**.
   - **Serial access:** stock Android 5.1.1 `getSerialNumber()` simply returns a stored field; it does not perform a permission check. T340 catches runtime exceptions in both new enumeration paths. Null or invalid serials disappear from selection. Honda framework deviations are **UNKNOWN**. [AOSP UsbDevice](https://raw.githubusercontent.com/aosp-mirror/platform_frameworks_base/android-5.1.1_r38/core/java/android/hardware/usb/UsbDevice.java)
   - **Direct-call security:** manifest line 45 requires DUMP for all three actions. AOSP checks service permissions and grants same-UID component access; the platform shell requests DUMP. An ordinary app **without DUMP cannot directly invoke SET_MAIN_PHONE, LIST_DEVICES, or RENAME_DEVICE** under that implementation. DUMP is specifically `signature|system|development`, so “no third-party app can ever hold it” would be too broad. Actual Honda runtime enforcement was not tested. [Service enforcement](https://raw.githubusercontent.com/aosp-mirror/platform_frameworks_base/android-5.1.1_r38/services/core/java/com/android/server/am/ActiveServices.java), [same-UID access](https://raw.githubusercontent.com/aosp-mirror/platform_frameworks_base/android-5.1.1_r38/core/java/android/app/ActivityManager.java), [DUMP declaration](https://raw.githubusercontent.com/aosp-mirror/platform_frameworks_base/android-5.1.1_r38/core/res/AndroidManifest.xml), [shell permissions](https://raw.githubusercontent.com/aosp-mirror/platform_frameworks_base/android-5.1.1_r38/packages/Shell/AndroidManifest.xml)
   - **Rename injection:** I found no injection path through the reviewed name argument. Installer lines 392–397 trim and validate before single-quoting it; quotes, substitutions, separators and newlines are excluded. Service validation independently applies the whitelist. Products/names are URI-encoded at service line 94 and decoded as data at installer line 380.

7. **Assumptions**

   Counterexamples describe source-reachable inputs and states, not observed vehicle outcomes. Android platform conclusions assume the relevant Honda implementation follows Android 5.1.1 behavior.

8. **Unresolved uncertainties**

   - Live Honda permission enforcement, descriptor availability, other-brand AOAP behavior, and write latency.
   - Visual usability of the long setup hint and full history list in the non-scrolling Settings layout (`SettingsActivity.java:218, 423–441`).
   - Failed `SET_MAIN_PHONE` persistence and process-death timing were not exercised.
   - Whether legacy migration and laptop-only correction are accepted product constraints.

9. **Exact diff summary**

   No review changes; no review-generated diff.

10. **Preservation checks performed**

   All four reviewed candidate hashes matched the source manifest:

   ```text
   HondaPhonePolicy.java  31FE003A5C604DD39E3E053F8AE26909F441680626D594D64C0D98A73F88AEA2
   UsbHelperService.java  7D5D173B0EFB4E70CF90DE5D221EF3EA5F1B733EB0C8C08351EFA6ED00553358
   SettingsActivity.java  EF9FBDF724642563DBF085887304B1E760C97D432140F0E6BFE315D2C2F26ADC
   WirelessProbeService  16E9E0B2F9E7F78D68800563791DB4A5941182B8DC20D3D096C484EAE203A768
   ```

   Service and policy contents were unchanged on repeat reads. Canonical attach/transport hashes matched `B/build-report.json`. No frozen artifacts were rebuilt or modified; their hashes were not recomputed. No key material or devices were accessed.