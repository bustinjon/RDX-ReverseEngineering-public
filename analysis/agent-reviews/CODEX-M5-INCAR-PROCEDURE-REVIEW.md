**The runner follows the intended successful path, but several failure branches cannot reach normal cleanup.** The strongest counterexample is a freshness refusal after `ARM_ATTEMPTED` is saved: no service is started, no journal exists, another ARM is forbidden, and UNINSTALL is forbidden.

**1. Files inspected**

All paths are relative to `C:/Users/REDACTED\Desktop\RDX-ReverseEngineering`.

- `PROJECT-RULES.md`, `AGENTS.md`.
- All requested scripts under `tools/m5/`, plus `scripts/Test-M5ArmReadiness.ps1`.
- All four requested procedure/results documents under `analysis/parallel-aa-receiver/`.
- `analysis/agent-reviews/CLAUDE-M5-ANALYSIS.md`. Other agent-review reports were not read.
- All three Java files under `analysis/parallel-aa-receiver/m5-permission/source/`, and its `AndroidManifest.xml`.
- Supporting implementation/tests: `scripts/Convert-RdxM5Dump.ps1`, `scripts/Test-RdxM5Retry.ps1`, `scripts/Test-RdxM5Dump.ps1`, relevant sections of `PermissionTests.java`, and searches in `Test-M5ArmReadinessOffline.ps1`.
- Supporting saved evidence: the latest M5 audit/pointers; retry `commands.jsonl`, reconstructed journal, arm response, initial arm logcat and focused UI excerpt; targeted retry logcat matches; guard session results, saved test summaries and freshness evidence.
- `PROJECT-INTEGRITY.json` and targeted searches in `hashes.json`; four frozen binaries were hashed without rebuilding.

**2. Files changed**

None. This report is returned in the response only.

**3. Commands run**

Read-only commands comprised:

- `Get-Content`, `rg`, `rg --files`, `Get-ChildItem`, `Get-Location`, and metadata/JSON processing against the files above.
- `git status --short` before and after.
- `Get-FileHash` for watched files, the historical journal and frozen artifacts.
- `& ./tools/m5/Test-M5FrozenPreflight.ps1` without `-Output`.
- Memory-only `Invoke-Expression` evaluation of the exact verdict statements from `Get-M5JournalVerdict.ps1:3–6`, against fixtures and the historical journal.
- Memory-only evaluation of UI-scoping statements and cleanup predicates.

Two initial hash-output formatting attempts failed because of a PowerShell syntax error and ConstrainedLanguage restrictions; corrected commands succeeded. A search for historical `m5-install-success.txt` reported that filename absent.

**No ADB, fastboot, runner stage, device operation, build, write-producing test suite or git mutation was executed.**

**4. Tests run and results**

| Check performed now | Result |
|---|---|
| Frozen offline preflight | `PASS: true`; exact frozen package/version/hash; `windowSeconds: 300`; `adbPathExists: true` |
| Verdict source statements against 11 fixtures | `SOURCE-SLICE VERDICT ASSERTIONS: 11/11 expected outcomes; no device or file output` |
| Historical retry journal | One invocation, one return, zero accepted callbacks; INCONCLUSIVE |
| Historical journal SHA-256 | `138F02161E79536D3C7D6F0D671D9253F8573D89881A2B937D1E67AF` **Correction:** exact command output was `138F02161E79536D3C7D6F0D671D9253F8573D89881A2B1BD27B2A937D1E67AF` |
| UI-scoping counterexample | Old rejection with no retained current ARMED marker: `runScoped=False blocked=True`; with complete current markers: `runScoped=True blocked=False` |
| Cleanup-predicate counterexamples | Empty package/process text accepted; error-shaped package text plus empty process text accepted |
| Watched-file preservation | 19 compared; zero changed |
| Four frozen artifact anchors | All matched |

The verdict probes executed the real calculation statements, excluding their file-writing wrapper. They were **not** end-to-end runner or Android tests. Existing Java/readiness suite outputs were inspected, not rerun.

**5. Findings**

**F1 — High: documented failure states can strand installation or evidence.**

There are three concrete cases:

- INSTALL saves `INSTALL_REVIEW_REQUIRED` before validating the reply and fresh package dump. Neither RETRIEVE nor UNINSTALL accepts that phase.
- ARM saves `ARM_ATTEMPTED` before its final freshness check. If that check expires, no ARM command is issued, but the session cannot ARM again or UNINSTALL. RETRIEVE attempts to dump a journal that was never created.
- If ARM delivery fails before journal creation, the same recovery dead end occurs. If INSTALL reaches the device but its host command times out, the saved phase can remain `PREPARED` despite a possible installed package.

These are preservation-oriented refusals, but the checklist does not identify their resulting installed/unknown states or provide a reviewed recovery procedure. Editing `session.json` to escape them would manufacture provenance and should not be improvised.

POSTCHECK has another recovery problem: it creates a fixed `after` directory and records `FINISHED` before throwing a preservation mismatch. Interrupted snapshots and mismatch results are not cleanly repeatable through the normal stage gates. Evidence: E1 below.

**F2 — High: 300 seconds is a decision bound, not a hard service watchdog.**

The app checks elapsed time in its main-thread pump and callback. Permission calls, USB inventory/permission queries and synchronous journal writes run along that path. No independent watchdog guarantees destruction at exactly 300 seconds if a call or write blocks.

The host deadline is also saved **before** the service command, whereas the app starts its monotonic window when `machine.arm()` executes. RETRIEVE uses host deadline plus three seconds as an alternative to seeing terminal logs. A delayed app start can therefore cause premature DUMP_RESULTS; the service explicitly ignores dumps while active.

Consequences: an early retrieval can fail without losing the private journal; repeating RETRIEVE is appropriate. A still-running or unresponsive service after the nominal deadline remains possible by source inspection; whether this occurs on the RDX is **UNKNOWN**. Evidence: E2.

**F3 — Medium: post-arm calls consume time, and confirmation is sampled only once.**

The relevant runner sequence is:

[Code block omitted from public report; see authored source where available.]

Each `Adb` call uses:

[Code block omitted from public report; see authored source where available.]

Therefore:

- After the app emits ARMED, the service command can still be returning, followed by logcat and `ps -Z`.
- After the runner finds ARMED in logcat, `ps -Z` and host writes still precede the swap banner.
- Successful calls approaching their individual timeouts could consume substantial window time. A timed-out call throws instead of authorizing a swap.
- There are **no post-arm sleeps or retries**, and **no more calls after the final swap banner**.

Previously, confirmation logcat took about **0.847 s**, and `ps -Z` about **0.167 s**. The prior 16.753-second ARMED-to-target interval already includes this confirmation period; do not add it again.

A separate race exists: the prior service command returned at `23:31:13.590Z`, before the journal’s ARMED time of `23:31:13.878Z`. A single immediate logcat sample can miss a delayed ARMED event and refuse a run that subsequently arms. Evidence: E3.

**F4 — High assurance gap: cleanup does less than the checklist claims.**

UNINSTALL sends normal stopservice/uninstall commands and checks package/process text. It does not:

- Require a successful uninstall response string.
- Validate that either inventory output has a recognized, complete shape.
- Check retained package state with `-u`.
- Check the former code path or collect direct code-directory absence evidence.

The cleanup predicate accepts empty/error-shaped inventory text if the ADB wrapper otherwise returns successfully. Whether a particular target error produces exit zero is **UNKNOWN**; acceptance of those inputs is demonstrated.

The checklist’s requested “package/process/code absence” is consequently stronger than the runner’s verification. Evidence: E4.

**F5 — Medium: a real PASS can be overwritten by an unrelated UI rejection.**

If the current ARMED marker is absent from retained logcat, the UI extractor searches the entire supplied log. VERIFY then overrides the journal result whenever `blocked` is true, without requiring `runScoped=true`.

Thus a durable valid grant plus a stale UsbPermissionActivity rejection can become INCONCLUSIVE. The memory probe reproduced the scoping condition.

There is also a presentation hazard: VERIFY prints the journal verdict JSON before applying that override, so console output can contain an initial PASS followed by the final INCONCLUSIVE message. Evidence: E5.

**F6 — Medium: the standalone verdict is not a provenance validator.**

Three unmarked lines satisfying the invocation, return and granted-callback predicates produce `M5 PASS`. Cross-run-spliced lines also produced PASS.

The script does not itself establish run identity, event order, callback-device equality, nonce equality or artifact provenance. It relies on a genuine journal from the audited app for those properties. The explicit `SYNTHETIC` safeguard checks only the first line.

This does **not** demonstrate that the normal frozen-app retrieval path fabricates a grant. It demonstrates that standalone `M5 PASS` output cannot establish live success without its capture provenance. Evidence: E6.

**F7 — Medium: the observation and reconnection branches remain underspecified.**

The app has no Activity in its manifest and the runner supplies no live status screen during the phone interval. The instruction “await the 300s bound if no terminal indication” therefore lacks an identified terminal indication available to the operator.

After reconnection, the runner performs fingerprint/API queries before its first log capture. If ADB is unavailable, retrieval, VERIFY, cleanup and POSTCHECK cannot proceed through the runner. The evidence wrapper provides no alternate recovery path.

The readiness gate also remains an operational uncertainty: each critical snapshot contains nine sequential device commands, must finish within two seconds, and successive starts must remain within two seconds despite the 400 ms sleep. This is fail-closed, but successful runtime latency/getter/hash parity remains unproven. Evidence: E7.

**Stage-by-stage operator walkthrough**

These are future-session command templates, not commands executed during this review. From the repository root in PowerShell 7:

[Code block omitted from public report; see authored source where available.]

| Stage / exact command | Expected success | Failure branch and resulting state |
|---|---|---|
| `& .\tools\m5\Test-M5FrozenPreflight.ps1` | JSON containing `PASS: true`, frozen hash/version, 300-second window | Throws on artifact/audit/version/callsite mismatch; no device operation |
| `& $runner -Stage PREPARE -SessionDirectory $session` | `OFFLINE PREPARED. No ADB used...`; phase `PREPARED` | Existing directory refused; interrupted creation can leave a partial host directory |
| `& $runner -Stage INSTALL @live` | Baseline, frozen install and fresh-install proof; `Frozen M5 installed, never launched...`; phase `INSTALLED` | Identity/baseline failure stops before install. Install delivery/reply/package-proof failures can leave the uncertain states in F1 |
| Normal RETURN navigation to Honda Home | Home visible; no M5 launch | ADB survival after this particular exit is not guaranteed; guard queries fail if unavailable |
| `& $runner -Stage ARM @live` | Guard prints `READY_TO_ARM`, then runner eventually prints `Deadline ... SWAP TO PHONE NOW ...`; phase `PHONE_SWAP_WAIT_RECONNECT` | Early guard refusal leaves `INSTALLED`. Later intent/freshness/delivery/confirmation failure leaves `ARM_ATTEMPTED`; do not swap or re-arm |
| Manual laptop-to-phone swap | Phone enumeration and possibly permission dialog | No phone/wrong cable/late arrival: no request or timeout. Re-enumeration after selection: terminal detach. No automatic retry |
| Manual permission response | App accepts and records callback if its gates pass | No prompt, denial, path change or system kill require evidence-based classification, below |
| Reconnect laptop; `& $runner -Stage RETRIEVE @live` | Saves raw logs, performs DUMP_RESULTS, verifies token/chunks/length/hash, reconstructs journal; phase `RETRIEVED` | Unreachable ADB stops retrieval. Possibly active app causes a wait message. Active-service dump is ignored; asynchronous/incomplete dump requires RETRIEVE again. Missing journal cannot currently reach normal cleanup |
| `& $runner -Stage VERIFY @live` | Verdict file; phase `VERIFIED`; `LIVE EXPERIMENT COMPLETE...` | Requires ADB identity queries even though verdict calculation is local. Invariant violation throws. UI override can change initial output, F5 |
| `& $runner -Stage UNINSTALL @live` | Normal stop/uninstall, `cleanup.json`; phase `UNINSTALLED` | Command/check failure retains the earlier phase; absence assurance is limited as in F4 |
| `& $runner -Stage POSTCHECK @live` | Factory hash/signer and geometry comparison; `M5 cleanup/postcheck complete. STOP...` | Snapshot interruption can leave `after`; mismatch records `FINISHED` and throws |

`DUMP_RESULTS` is **not** an accepted runner stage; RETRIEVE invokes that service action internally. `Get-M5FutureEvidence.ps1` delegates to RETRIEVE. `Remove-M5FutureTest.ps1` delegates to UNINSTALL followed by POSTCHECK.

Every stage reruns the frozen preflight. Every non-PREPARE/non-ARM stage also requires live fingerprint/API queries. Missing host audit/SDK dependencies can therefore obstruct later retrieval or cleanup as well as initial installation.

**Concrete verdict scenarios**

These outcomes assume genuine captured evidence. F5’s UI override and evidence loss can change the final result.

| Scenario | App behavior and resulting verdict |
|---|---|
| **(a) Allow, accepted granted/verified callback, detach five seconds later** | **PASS.** GRANTED is terminal; later snapshots/detach cannot downgrade it. `stopSelf()` follows the accepted terminal callback. No five-second connection-duration requirement exists |
| **(b) Allow, new device path before callback** | **INCONCLUSIVE if the changed inventory is observed first**, because DETACHED is terminal. A callback carrying the new path is rejected; an old-path callback with grant=true but verification=false produces CALLBACK_INCONSISTENT. Strictly, physical re-enumeration alone does not determine code ordering: an original-path callback with verification=true before the next snapshot can still produce PASS. Whether the OEM can return true for that removed identity is **UNKNOWN** |
| **(c) No dialog, no lock-task rejection** | Without an accepted verified grant: **INCONCLUSIVE**, commonly TIMED_OUT or DETACHED. Absence of rejection logs proves neither grant nor platform restriction |
| **(d) Cancel/deny** | Accepted callback with grant=false and verification=false gives app state DENIED, but automated verdict **INCONCLUSIVE**. An operator cancellation does not establish platform impossibility |
| **(e) Lock-task blocks dialog again** | **INCONCLUSIVE**, with the runner’s explicit permission-Activity-blocked wording if detected. No automatic FAIL |
| **(f) System kills service mid-run** | Before a durable accepted grant: **INCONCLUSIVE** if the journal is retrievable. After durable grant plus the required request/return records: **PASS**, even without SERVICE_END. If no journal was created: retrieval fails and no verdict is produced |

The verdict script has **no automatic FAIL branch**. The decision tree reserves FAIL for a demonstrated restriction with adequate evidence and manual review.

**Manual actions, in order**

| Action | Likely mistake | Consequence |
|---|---|---|
| Confirm separately authorized M5-only scope | Treat preparation or a prior authorization as permission for another run | Procedure exceeds its stated boundary |
| Start the prepared host shell, select one fresh session path, run preflight/PREPARE | Reuse an old directory or session variable | Refusal or confusion between runs |
| Connect laptop with phone disconnected; run INSTALL | Assume timeout means installation never happened | Possible orphan installation; F1 |
| Read INSTALL result | Continue without saved fresh-install proof | ARM refuses |
| Use ordinary RETURN controls through Diagnostics to Home | Stop one screen early, toggle USB mode, or use a different exit method | Guard refusal or altered USB state |
| Prepare awake/unlocked phone, correct cable and unobstructed head-unit view | Unlock/find cable after arming | Window consumed; prompt missed |
| Run ARM; wait for the **final swap banner** | Mistake `READY_TO_ARM` for permission to unplug | Interrupts subsequent arming/confirmation |
| Pull laptop cable; immediately insert phone into the same port | Pause, choose wrong port/cable, or return to Diagnostics | No target, late target or UI interference |
| Watch the head unit and identify the M5 permission dialog | Treat stock AA or a handler chooser as M5 | Misleading observation or unintended default selection |
| Choose the affirmative permission button once, if shown | Cancel, select a default checkbox, or repeatedly tap/reconnect | Denial, unrelated state change, or terminal re-enumeration |
| Record dialog/action and physical timing | Rely on memory after reconnection | Cannot distinguish physical unplug from stock re-enumeration |
| Follow the agreed phone observation interval; reconnect laptop once | Infer terminal state from stock AA, or unplug while permission remains pending | Intentional detach may terminate the selected run |
| Run RETRIEVE; repeat only retrieval when incomplete | Re-arm, uninstall early, or overwrite evidence | Lost opportunity/evidence |
| Run VERIFY and inspect the final saved result | Read only initial console PASS | Miss F5 override |
| Run normal UNINSTALL and POSTCHECK; stop | Assume success text proves code absence, or advance to another milestone | Unsupported preservation claim or unauthorized follow-on work |

**Proposed checklist wording — report text only**

- Replace “After the runner confirms ARMED” with:  
  **“Wait for the final line containing `Deadline ... SWAP TO PHONE NOW`. `READY_TO_ARM` alone is not the handoff signal. On any ARM exception, keep the laptop connected; do not swap or re-arm.”**
- Add after INSTALL:  
  **“A timeout or `INSTALL_REVIEW_REQUIRED` result does not prove M5 is absent. Preserve the session and report installation state as UNKNOWN; do not reinstall or edit session/proof files.”**
- Replace the ambiguous waiting instruction with an agreed rule before ARM:  
  **“The app supplies no operator-visible terminal status. Record the handoff time. If no dialog has completed, retain the phone connection through the agreed full observation window; 300 seconds from the final handoff banner conservatively covers the already-started app window. Reconnect immediately afterward and retrieve. A shorter 60–90-second interval deliberately ends any still-pending request and must be recorded as such.”**  
  Longer waiting increases log-retention risk; it does not add an independent service watchdog.
- Clarify the dialog instruction:  
  **“The app label is `M5 USB permission only`. Choose the button granting that app USB access only if the actual dialog is visible. Runtime button wording is unverified. Do not select a default-handler checkbox. Stock Android Auto is not the permission result.”**
- Add a reconnection branch:  
  **“If laptop ADB is unavailable after reconnection, preserve the session and record time, screen and host error. Do not re-arm, toggle USB modes, reboot or uninstall without retrieving evidence. Cleanup remains UNVERIFIED.”**
- Qualify preservation wording:  
  **“Current runner verification covers package/process text plus factory APK/signer/display comparison. Direct code absence is not presently verified by this runner.”**
- Add a verdict instruction:  
  **“Review the final saved `m5-verdict.json`, its journal provenance and `permission-ui-evidence.json`. Unscoped UI matches require manual correlation; standalone PASS text is insufficient.”**

**Evidence capture gaps under the single-port constraint**

| Needed observation | Captured now? | Recoverable afterward? |
|---|---|---|
| Durable app request/result/timing | Yes, journal synced per record | Normally through later DUMP_RESULTS, assuming file and storage remain readable |
| USB enumeration and Activity launch/rejection | Raw logcat after reconnection | Only insofar as relevant entries were emitted and retained |
| Actual visible dialog, text, checkbox state and operator tap | No screenshot/video capture | **Requires observation/photo/video during the phone interval**; later logs cannot establish exactly what was visible or tapped |
| Window focus, resumed Activity and ProjectionActivity state at request time | Pre-arm snapshots only; no request-time snapshot | Historical log entries may help, but an exact past dumpsys snapshot cannot be generated afterward |
| Whether stock ProjectionActivity covered or displaced the dialog | Not automatically established | Requires retained transition/focus logs or observation during the interval |
| Physical cable actions versus automatic re-enumeration | Not recorded by runner | Observer timestamps are needed; USB detach logs alone do not prove a physical unplug |
| System kill/crash reason | No dedicated capture | Possibly retained system/crash logs; no guaranteed reason record in the app journal |
| Historical focus/event-buffer records | No explicit events-buffer collection | Cannot assume the default captured log contains them |
| State after ADB fails to return | No defined alternate path | Head-unit observation remains possible; laptop retrieval waits on restored access |

The laptop cannot take request-time screenshots or dumpsys snapshots while the phone occupies the sole port. Any automatic on-head-unit capture would require separately reviewed preparation; the current runner does not arrange it. Reconnect-time screenshots/dumpsys would describe the later state only.

**6. Primary evidence for each finding**

| Evidence | Primary locations |
|---|---|
| **E1 / F1: phase and recovery gaps** | [Runner installation transition:51](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/m5/Invoke-M5FutureSession.ps1:51), [ARM intent/freshness transition:66](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/m5/Invoke-M5FutureSession.ps1:66), [RETRIEVE gate:71](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/m5/Invoke-M5FutureSession.ps1:71), [cleanup/postcheck gates:83](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/m5/Invoke-M5FutureSession.ps1:83), [snapshot directory creation:34](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/m5/Invoke-M5FutureSession.ps1:34). Phase-policy probe confirmed `INSTALL_REVIEW_REQUIRED` accepts neither retrieval nor uninstall; `ARM_ATTEMPTED` accepts retrieval only |
| **E2 / F2: timeout semantics** | [Machine window and clock checks:54](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/m5-permission/source/com/rdx/fullscreen/m5permission/PermissionMachine.java:54), [service pump:57](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/m5-permission/source/com/rdx/fullscreen/m5permission/PermissionService.java:57), [active dump ignored:98](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/m5-permission/source/com/rdx/fullscreen/m5permission/PermissionService.java:98), [synchronous journal persistence:53](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/m5-permission/source/com/rdx/fullscreen/m5permission/PrivateJournal.java:53), runner lines 66 and 74–75 |
| **E3 / F3: post-arm timing** | [Runner timeout:20](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/m5/Invoke-M5FutureSession.ps1:20), [confirmation/handoff:68](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/m5/Invoke-M5FutureSession.ps1:68), [previous command timings:18](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/m5-live-retry-20261025-185128/commands.jsonl:18), [actual ARMED marker:3](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/m5-live-retry-20261025-185128/reconstructed/m5-m5_270c93bb178648759beda65ed9593e72-45b32906-b1b2-494f-abdd-02148f6769a2.txt:3) and target marker at line 13 |
| **E4 / F4: cleanup mismatch** | [Runner cleanup predicate:83](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/m5/Invoke-M5FutureSession.ps1:83), [checklist code-absence requirement:18](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/NEXT-CAR-SESSION-CHECKLIST.md:18). Probe outputs: `cleanup inventory=[] empty ps => accepted=True`; error-shaped inventory also `accepted=True` |
| **E5 / F5: UI override** | [UI scoping and block predicate:79](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/m5/M5ArmReadiness.ps1:79), [VERIFY output/override order:79](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/m5/Invoke-M5FutureSession.ps1:79). Memory probe outputs are reported in item 4 |
| **E6 / F6: standalone PASS limitations** | [Verdict implementation:3](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/m5/Get-M5JournalVerdict.ps1:3). Probes: `missing_provenance_three_lines: M5 PASS`, `cross_run_spliced: M5 PASS`; both expected outcomes asserted in the final 11-case run |
| **E7 / F7: operational/evidence gaps** | [Guard nine-command snapshot:64](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/scripts/Test-M5ArmReadiness.ps1:64), [sample/gap limits:56](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/m5/M5ArmReadiness.ps1:56), [runtime limitation:25](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/m5-locktask-guard-20261025-195507/SESSION-RESULTS.md:25), [runner identity and snapshots:28](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/m5/Invoke-M5FutureSession.ps1:28), [reconnect capture:72](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/tools/m5/Invoke-M5FutureSession.ps1:72) |
| **Scenario outcomes** | [Terminal-state definition:50](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/m5-permission/source/com/rdx/fullscreen/m5permission/PermissionMachine.java:50), [detach handling:96](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/m5-permission/source/com/rdx/fullscreen/m5permission/PermissionMachine.java:96), [callback gates/state:114](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/m5-permission/source/com/rdx/fullscreen/m5permission/PermissionMachine.java:114), [adapter callback verification:38](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/m5-permission/source/com/rdx/fullscreen/m5permission/PermissionService.java:38), service lines 137 and 166–178 |
| **Operator/evidence requirements** | [Checklist:9](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/NEXT-CAR-SESSION-CHECKLIST.md:9), [manifest label/service-only application:4](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/m5-permission/AndroidManifest.xml:4), [decision-tree verdict policy:5](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/NEXT-LIVE-DECISION-TREE.md:5), [latest analysis’s remaining unknowns:17](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/agent-reviews/CLAUDE-M5-ANALYSIS.md:17) |

**7. Assumptions**

- Future commands use the same unmodified frozen APK and a compatible PowerShell 7 host.
- The supplied single-port constraint holds; laptop device access is unavailable during the phone interval.
- Scenario PASS means the required records were durably captured from the genuine app, not merely that Allow was tapped.
- Proposed checklist wording is for review only; it authorizes no live action or tooling change.

**8. Unresolved uncertainties**

- Live framework hash parity, getter accessibility/rendering and readiness-query latency.
- ADB availability after the next Diagnostics exit and phone/laptop swap.
- Actual dialog wording, visibility and interaction with Honda ProjectionActivity when lock-task is inactive.
- Callback-versus-inventory ordering during re-enumeration, and OEM permission verification for a removed identity.
- Log retention over the selected phone interval.
- System behavior if the service’s main thread blocks or is killed.
- Recovery from installation uncertainty or an attempted ARM with no journal remains undefined in the reviewed runner.

**9. Exact diff summary**

No diff; no files edited.

**10. Preservation checks performed**

Nineteen watched source/document files had identical before/after hashes. Initial and final `git status --short` were identical, including the pre-existing modified `.gitignore` and three untracked paths.

Frozen SHA-256 checks all matched:

| Artifact | SHA-256 |
|---|---|
| M5 APK | `A22E96490B9557AFF022893A8B8B7A08BB13CEC236E52704CDDAFA90A8EE8F40` |
| Disabled M6 APK | `D4DAC2DD8B2AFF1FA7B64BFB32D2A5E889854CCEB4B4A9F7AD5AEF89FB28761F` |
| Receiver DEX | `2FDBC63F2F9D63B764697D311AF89D460AE6B8E14B0FADABA9C9339F7FE7C235` |
| API22 TLS qualifier APK | `86350131FFC5CBE5766E523AB03AE07D4C9F5EAD78F0570B68255C9A3999FC1F` |

No key material was read, no frozen artifact was modified, and no milestone was advanced.