# T240 pre-run verification — November 9, 2026

**PASS OFFLINE for the bounded parked policy test.** No new application blocker found in this verification. This does not establish car behavior. The exact reviewed APK remains **14CBCFFA0F02AC85AB271C3DE8E9DE2EC3560198F6C71291D6F4E52E6FA77004**.

**One inherited instruction is wrong for wireless:** the generic runner says unplugging the phone always ends the session. Removing USB does not stop wireless AA. For this test, use Hackura Settings > Phone & devices > **Wireless Android Auto: off** as the existing stop control. Stay parked. The per-device Off control itself is what this candidate is testing. No launcher or application was edited by this review.

## 1. Files inspected

PROJECT-RULES.md and AGENTS.md; T240's four changed Java snapshots, source/build/candidate/package manifests, saved host/service checks and build report; actual APK's public classes.dex and manifest/signature; actual production classes.jar; generated Start-T240-bundle.cmd, Collect-T240-bundle.cmd, Prepare/Collect package scripts; shared Run-Test.ps1 and readiness template; frozen preservation entries. Canonical implementation/background report: [T240 bundle report](../../test-prep/todo-tests-20261103/builds/T240-bundle/REPORT.md). No private asset, extracted key or signing-key contents were inspected.

## 2. Files changed

Only new files in this review directory: scope, Verify.ps1, Verify-ClassParity.ps1, fake BluetoothSocket.java, BootstrapBoundaryTest.java, compiled host fixtures, evidence logs/manifests and this report. **No changes to application source, T240 bundle/test spec/APK, Start/Collect launchers, original evidence, shared tools, Git or any device.** The complete existing bundle/launcher inventory was hashed before and after verification.

## 3. Commands run

Read-only file/search inspection, then saved offline procedures:

[Code block omitted; consult project-authored source.]

These use SHA-256; existing JDK17 javac/java; Android SDK apksigner **verify**, zipalign **check** and aapt **dump badging**; PowerShell syntax parsing; the existing Run-Test.ps1 **-Action Check** and Switch-Source.ps1 **-Verify**. Test fixtures call actual compiled Java service methods against fake Android delivery/preferences/Bluetooth and unconnected Java sockets. No ADB/fastboot, actual Bluetooth/Wi-Fi/network/USB action, native-library execution, rebuild/sign, installation, Git mutation or delegation.

## 4. Tests run and results

- Actual APK hash agrees with candidate.json, build-report.json and build-result.json: PASS. Build status is BUILT_AND_PACKAGED with baselineRestored true.
- All 36 snapshot hashes and all 48 recorded production source hashes agree with the separately validated implementation: PASS.
- Actual packaged DEX equals both the recorded build DEX and the separately validated production DEX: **D927D860D321E00D1AB6BE9700162BDB04D8730629D7DD4E5333FDF1912E4A03**.
- All **275 production class files** in the actual build JAR are byte-identical to the separately validated compilation. This verifies the classes used by this review's method tests correspond to that same validated production compilation; the DEX comparison independently ties it to the APK.
- Fresh API22 signature verification and alignment check: PASS. Actual manifest has com.rdx.fullscreen.usbhelper, minSDK21, targetSDK22.
- Existing pure/feature tests rerun against the actual production JAR: **29 policy + 245 bundle + 93 feature checks PASS**. Feature breakdown: 15 touch, 5 frame-rate, 11 phone-policy, 11 Home, 10 persistent, 9 dismiss-label, 24 reconnect, 8 location.
- **18 actual-service policy checks PASS**, including socket cancellation, selective owner handling, USB preservation, queued handoff revocation and existing active shutdown path with no initialized native workers.
- **14 additional bootstrap/admission boundary checks PASS**: positive-control allowed START/INFO response; already-Off silence; initial allowed check reaches the real timed network wait, then Off prevents output when network readiness resumes; Off as the real read returns suppresses INFO and PONG; another allowed owner still gets a response; the same socket in both tracking fields closes once; actual tcpOwner rejects conflicting/no/unknown bootstrap ownership and resolves a linked main owner.
- Generated PowerShell scripts parse, Start/Collect targets resolve to T240, bundled PowerShell exists, offline runner Check passes, mandatory identity/firmware/stable-window segment matches the existing template exactly, host baseline verifies.
- **1,334 existing bundle/launcher files unchanged** across verification; five frozen manifest entries retain their expected hashes.

## 5. Findings

**F1 — The packaged candidate really contains the implementation tested offline.** Hash agreement includes the actual DEX and every public production class, beyond trusting an old PASS string or a source manifest alone. No build/source mismatch found.

**F2 — The added policy boundaries pass direct method checks.** Current-owner Off reaches cancellation/teardown, another permitted owner is preserved, and queued handoff consumption rechecks current policy. The additional bootstrap checks cover the previously unexecuted network-wait and read-completion revocation paths. These are actual production methods with fake OS/transport dependencies, not just copied decision logic.

**F3 — Launcher/package wiring and mandatory preparation checks are intact.** The shortcut names/actions select T240, generated scripts parse, and the mandatory preflight is unchanged. Live Start/Collect behavior cannot be established offline and was not invoked.

**F4 — MEDIUM, inherited operator-instruction defect:** Run-Test.ps1:144 claims that unplugging the phone always ends the session. T240 supports wireless AA; its per-device policy stop path operates independently of USB. That statement must not be relied on for this wireless test. Use the existing global Wireless Android Auto off control; its Settings callback dispatches WirelessProbeService.stop. This review verifies that route in source, not a live emergency-stop result. Fixing shared runner wording is outside this read-only verification scope.

**F5 — Existing limitations remain.** Main-thread shutdown/native joins and the old unversioned session-end cleanup race are unchanged by T240. The short teardown hitch can therefore still occur. Unknown/ambiguous TCP ownership is now refused, which can affect cached-network reconnects; initial unlinked-peer fallback still associates with an unlinked configured main phone without proving physical identity. These are already documented in the candidate report; this verification does not convert them into runtime PASS results.

## 6. Primary evidence for each finding

- F1: verification.json; class-parity.json; preserved source/build metadata in the bundle. SHA values above are computed from the actual files. Public DEX inspection opens only the classes.dex ZIP entry.
- F2: ServicePolicyTest.txt and BootstrapBoundaryTest.txt; review BootstrapBoundaryTest.java. Production snapshot WirelessProbeService.java:80–109 (dispatch/reconcile), 517 (policy action), 694–700 (TCP admission), 768 (post-network-wait check), 777 (post-read check); AaSessionService.java:119–125 (handoff), 515–528 (handoff consumption), 577–585 (live reconciliation); HondaPhonePolicy.java:10–34 (shared owner/policy predicates).
- F3: runner-check.txt, baseline-check.txt, verification.json; actual suite Start-T240-bundle.cmd:3 / Collect-T240-bundle.cmd:3; review Verify.ps1 directly parses generated files and compares the mandatory readiness segment to its template.
- F4: shared tools/Run-Test.ps1:144; candidate SettingsActivity.java:241–245 global toggle; WirelessProbeService.stop and shutdown route. Generic USB-disconnect wording is not evidence of wireless cessation.
- F5: candidate AaSessionService.java:1387–1455, including t.join(2000) at1407; WirelessProbeService's unchanged ACTION_SESSION_ENDED branch; HondaPhonePolicy.Wireless.owner and tcpOwner. Original runtime race/stall evidence remains in [T230 review](../t230-latest-test-20261109/REPORT.md).
- Preservation: preservation-before.json, verification.json and the independent final hash comparison performed by Verify.ps1.

## 7. Assumptions

This is verification of the exact existing T240 local test bundle, not authorization to install or change it. The intended next step is the bounded parked policy sequence in its TEST-PLAN.md, using the already configured phone and established USB-to-Bluetooth link. Host fixtures approximate only the named OS/transport calls; they do not model the complete Android service scheduler or car firmware.

## 8. Unresolved uncertainties

**UNKNOWN:** actual car disconnect/reconnect latency, phone-side reactions, HFP call behavior, native-worker teardown under load, Android lifecycle/disk failures, ignition recovery, sustained driving freezes, multi-phone/IP attribution. No Android/ADB/car/phone session was opened. The unchanged main-thread teardown and session-end race are outside this verification's fix scope. The global stop route was source-inspected only; it was not operated on the car. Full static/native/security qualification remains outside scope.

## 9. Exact diff summary

Verification files/fixtures/logs under this new review directory only. Zero application, bundle, APK, launcher, shared-tool or original-evidence differences. No rebuild or promotion. No fix was silently applied during verification.

## 10. Preservation checks performed

All 1,334 inventoried existing T240/launcher files rehashed unchanged at verification end, including APK and all snapshots. Five frozen entries retain all four required anchor hashes. Host baseline verifies and was never switched. The actual APK hash remains 14CBCFFA0F02AC85AB271C3DE8E9DE2EC3560198F6C71291D6F4E52E6FA77004. No key/private asset content inspected; no Git mutation, device action, readiness bypass, milestone operation or agent call.
