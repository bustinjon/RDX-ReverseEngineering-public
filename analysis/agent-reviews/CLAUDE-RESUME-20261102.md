# Claude resumption handoff: Android Auto fullscreen research

Prepared **2026-10-29** for the user's intended **2026-11-02** resumption. This date in the filename is a handoff target, not a claim of future testing.

**Scope:** consolidate existing research, inspect the current implementation and saved evidence, attack the new v6h proposal, and prepare concrete recommendations. No implementation, build, installation, device access, or milestone advancement occurred. Claude remains the lead. This report does not replace [PROJECT-RULES.md](../../PROJECT-RULES.md), the readiness guard, or historical records.

**Read this first:**

- The Honda per-phone **Disable/NEVER** approach is worth pursuing, but v6h is a proposal, not an implemented or validated standalone workflow. Its confidence statements need qualification.
- The saved v6e session reached video selection and decoder startup. v6f failed at a different stage with a recorded TLS error. v6g-retry did not start our session. These are different failure classes.
- `latest-build.txt` points to an APK whose recorded session-service and decoder source hashes do not match current source. Do not assume a source fix is in the APK or a named car test.
- Newly identified preparation gaps include an in-memory-only proposed mode, unconditional force-stop/reset paths, terminal helper states that prevent reconnect recovery, no permission-callback deadline, and USB defaults that can be invalidated by package changes.
- No saved log examined contains our `FIRST FRAME RENDERED` marker. That is a bounded log finding, not proof that no frame was ever physically shown. Fullscreen playback, input, audio, and independent restart remain unestablished.

Companion artifacts: [machine-readable evidence and preservation inventory](claude-resume-20261102/evidence.json), [native video-focus disassembly](claude-resume-20261102/native-video-focus.txt). The prior [laptop-independent alternatives review](codex-20261029-laptop-independent-receiver-alternatives.md) remains the detailed comparison of separate apps and OEM replacement paths.

## 1. Files inspected

Substantive inspection covered:

- Project instructions, `PROJECT-STATE.json`, `INDEX.md`, selected `NOTES.md` and `CLAUDE-CURRENT-WORK.md` checkpoints.
- New proposals: `v6h-honda-disable-plan.md`, `honda-disable-adversarial-review.md`, `usb-default-research.md`.
- Current helper manifest/filter and `UsbHelperService`, `UsbAttachActivity`, `HelperActivity`, `PermissionClickService`, `AaSessionService`, and relevant overlay/boot behavior.
- Current receiver `VideoDecoder`, `VideoSink`, `GalReceiver`, `UsbBulkTransport`, audio/sensor stubs, and the **helper-side** `InputSource` override.
- `Run-CarTest.ps1`, `device-kill-honda.sh`, relevant `Build-RdxUsbHelper.ps1` portions, and syntax of `v6g-car-test.ps1`.
- All nine `analysis/logs/car-test-*.txt` files for bounded event extraction, with detailed review of v6e, v6f, and v6g-retry evidence.
- Latest helper build metadata and its 20 recorded source hashes; the APK was hashed only, not unpacked for credential contents.
- Honda `GalService`, device settings, `GalUsbReset`, `ProjectionActivity`, USB framework/SystemUI classes, and prior package-signature evidence.
- Prior decoder, service-stub, touchpad, dialog-dismissal, transport, integration, deployment, and fullscreen reviews, as navigation to evidence rather than independent proof.
- Read-only disassembly of selected functions in `libautoreceiver_jni.so`; bounded inspection of existing `usbresetserver` analysis and the stripped binary's relevant strings.

The companion JSON inventories **263 pre-existing files hashed for preservation**. Hashing a file does not mean every line was substantively reviewed. This was a targeted consolidation of active work, not an exhaustive re-audit of every archive, framework class, or binary.

## 2. Files changed

Only three new handoff artifacts:

1. `analysis/agent-reviews/CLAUDE-RESUME-20261102.md`
2. `analysis/agent-reviews/claude-resume-20261102/evidence.json`
3. `analysis/agent-reviews/claude-resume-20261102/native-video-focus.txt`

Existing source, scripts, plans, historical reviews, logs, instruction files, and frozen artifacts were not edited. Recommendations below are not implemented changes.

## 3. Commands run

Read-only commands included `Get-Content`, `rg -n`, `rg --files` (including scoped `--no-ignore` inventories), `Get-FileHash -Algorithm SHA256`, `git status --short`, `git diff --numstat`, and `git log -5 --format='%h %ad %s' --date=short`.

Native PowerShell extracted LF-numbered log events and compared build-report hashes. `System.Management.Automation.Language.Parser.ParseFile` parsed three scripts without executing them; XML casts parsed two manifests/resources. Rizin used `-N -q -e scr.color=0` and explicit ARM/Thumb addresses, with no write/debug option or native execution. Exact selected disassembly commands are in the companion text file.

The Python 3.13 launcher could not create its interpreter process; the analysis completed in PowerShell instead. Several exploratory searches found missing guessed resource paths or unsupported literal wildcard paths; corrected file inventories or directory-scoped searches were used. No result was inferred from those failed searches.

Only `apply_patch` wrote the new documents/evidence. No ADB, fastboot, device-facing script, builder, signing tool, installation, Git staging, commit, or push was run. No Claude or sub-agent was called.

## 4. Tests run and results

| Check | Result | What it establishes |
|---|---|---|
| Latest APK hash versus build report | MATCH, `C7943B4F...F80757` | Local APK agrees with that metadata; installed-car parity UNKNOWN |
| Latest build's 20 source hashes versus current files | 18 match; 2 differ | Session and decoder edits are newer/different than the recorded build inputs |
| Nine saved car logs | Extracted stage counts and first/last matching lines | Bounded historical observations; not complete session reconstruction |
| Three PowerShell scripts | 0 syntax errors each | Parseability only; not operational readiness |
| Helper manifest and device filter | Both parse as XML | XML syntax only |
| Native video-focus inspection | Closed-channel branch and setup ordering confirmed in instructions | Static mechanism; no proof it caused a particular car failure |
| Four frozen artifacts | 4/4 expected SHA-256 matches | Preservation anchors remain intact |
| Existing-file preservation | Compared with the 263-file starting inventory | See final validation in companion JSON |

No Android runtime test, decoder execution, APK build, M5/M6/M7 execution, hardware test, or live validation was performed. Historical host-probe suites were not rerun because their saved results and source assumptions must not be silently overwritten or confused with the current implementation.

## 5. Findings and recommendations

### F01. Separate dated project status from newer experimental evidence

`PROJECT-STATE.json` still carries date `2026-10-25` and M5-inconclusive/M6-disabled/M7-not-authorized entries, although later notes exist inside it. `CLAUDE-CURRENT-WORK.md` ends with October 27 preparation. The October 28 logs and October 29 v6h proposal are newer experimental evidence. [E01]

This is a **documentation coverage gap**, not authority to advance any milestone. On resumption, reconcile the newer experiments, their exact binaries, and their authorization history with the canonical record. Do not erase the prior M5 result or turn helper permission success into a retroactive pass for a different frozen package.

At review start, Git HEAD was `a313153` (2026-10-28, dialog-cause reconciliation). The worktree already contained five modified tracked files and multiple untracked implementation files, scripts, logs, and reviews. The companion baseline preserves their hashes. Do not overwrite, clean, or stage this set merely to resume.

### F02. The latest build is not current source

`usb-helper/latest-build.txt` points to `build/20261028-164612-233`. Its APK hash is:

`C7943B4FD9194E6AAD3E2C28AE68F880519D8EC624148AA794FBE9CA97F80757`

The build report records `staticAudit: PENDING`. Two source inputs differ now:

| File | Recorded build input SHA-256 | Current SHA-256 |
|---|---|---|
| Helper `AaSessionService.java` | `531779ACC4C783245CB9654A1DFAAB48F9DF206E8754C6E6BDE8A1A9D815617B` | `A6D60C6137FB5E7ADF732109B14E14E1D32B92424A0D1D4A1547D30962BBBFC4` |
| `VideoDecoder.java` | `E1A8EA65322AEBC3CB197787B13F0C80E5573F7E214028949B2EF128B068B6AE` | `CDA9CF3BE91CBB45ED77CBA71A9F299455F2843C88D81EF3D656113415FB9229` |

`Run-CarTest.ps1` defaults to the latest-build pointer. A filename such as v6f/v6g is not an APK provenance record. Reconstruct which APK each saved test actually installed before crediting a code change with a result. [E02]

The builder also resolves duplicate source files by **basename**, with helper-side files taking precedence. The effective `InputSource.java` is under `usb-helper/source/com/google/android/projection/protocol/`, not the similarly named shared-source file. Review and modify the compiled input, and retain the effective source list in future build metadata. [E02]

### F03. v6h's mode sketch does not yet produce a cooperative standalone workflow

The search for `hondaDisabled`/`HONDA_DISABLED` found no implementation in current helper source or `Run-CarTest.ps1`. The new plan is still a proposal despite its later "Files Modified" heading. [E03]

The proposal changes three necessary non-accessory gates, but leaves several independent issues:

1. **Mode lifetime:** a plain boolean set by a start intent disappears on process recreation. `START_STICKY` does not reconstruct the user's per-phone configuration. A cold USB attach only supplies `AUTO_GRANTED`; the proposed mode signal still comes from the laptop script.
2. **Startup order:** `UsbHelperService.onCreate()` unconditionally attempts Honda force-stop and `VBUS_DATA_RESET` before `onStartCommand()` sees the proposed mode action. Merely adding the new action does not select a different startup path early enough.
3. **Script behavior:** the plan skips Step 7's kill loop but leaves Step 3's unconditional Honda force-stop. That does not isolate the intended "Honda running but declining this phone" experiment.
4. **Scope of assertion:** the proposed global flag is not evidence of Honda's actual preference and is not tied to a particular phone. The raw-phone matcher accepts the OnePlus vendor broadly. Represent user configuration separately from observed evidence, and bind it to the intended device.
5. **Manual entry:** the launcher still opens the old permission checker, and boot handling starts the blocker overlay only. A durable mode flag alone would not finish the Start/Stop user flow.

Recommendation: specify the intended on-device lifecycle and configuration semantics before applying the three-file sketch. The normal Honda settings UI is the supported way to set its private per-phone preference; do not fabricate proof by changing our boolean. [E03, E04]

### F04. Current helper state handling has reconnect and callback stalls

These are static control-flow counterexamples, not claims of observed v6h failures:

**After one successful session:** `phase=GRANTED` stops polling. A later `AUTO_GRANTED` accessory intent is ignored whenever that phase remains GRANTED. Detach broadcasts only increment/log counters. `AaSessionService` shutdown does not reset or stop the helper. Thus a surviving helper can reject a legitimate reconnect even though permission is available. [E04]

**When a permission callback never arrives:** `doRequest()` sets REQUESTING. The poll loop has no request deadline; with no device it only logs, and with a device it does not enter either WAITING or STABILIZING handling. The 15-attempt ceiling bounds denied callbacks, not an indefinitely missing callback. [E04]

**During re-enumeration:** the current "handles re-enumeration" logic cited by the v6h review applies to STABILIZING. It does not establish recovery from every phase. `aoapSwitchSent` is reset on a particular no-target timeout, not by a complete session lifecycle.

**Duplicate raw-device starts:** the AUTO_GRANTED non-accessory branch does not check `aoapSwitchSent`. A future mode change needs a single attachment/session owner so duplicate starts cannot issue multiple accessory switches before re-enumeration.

Recommendation: define explicit attachment generations, request completion/timeout, switch-in-progress, active session, stop completion, and reconnect transitions. Verify callbacks against the current attachment. Do not solve these with a longer global sleep or an unbounded retry loop.

### F05. USB defaults help, but the new persistence claims are too broad

Confirmed: SystemUI saves a default when the user chooses the relevant persistent option; framework later grants and launches that saved matching handler. Grants themselves are removed on detach. Saved defaults match a concrete `DeviceFilter`, including numeric identifiers and available descriptor fields. [E05]

Newly checked limitation: `MyPackageMonitor.onPackageAdded/onPackageChanged` calls the update handler, which examines USB metadata and invokes `clearCompatibleMatchesLocked()`. That method removes matching default entries without using its `packageName` argument to exempt the same app. A matching package event can therefore invalidate remembered defaults. Exact event behavior for a particular installation sequence is UNKNOWN; permanent immunity to repeated installs is not supported. [E05]

Also:

- Raw phone and accessory mode are different identities; AOAP-only and AOAP+ADB PIDs can differ too.
- Honda's private per-phone NEVER setting does not remove its manifest USB filter from Android's resolver. Preference-disabled is not package-disabled.
- The current accessibility service recognizes the USB permission class or a SystemUI Dialog event and clicks OK/Allow. A USB **chooser** must select the intended application and persist that choice. Adding a checkbox click is not a demonstrated chooser implementation.
- The plan's checkbox snippets use an undefined `log()` helper in this class, do not consistently recycle nodes on break, and do not verify the click result or resulting checked state. They are sketches, not tested patches.
- `usb-default-research.md` still repeats the unsupported closeSystemDialogs causal claim and overstates "all future connects". Preserve its valid framework findings while correcting those conclusions.

Recommendation: treat first-time selection, missing/default-invalidated selection, and later auto-launch as separate cases. A user-selected initial default is a useful baseline before adding more accessibility automation. Current installed candidate inventory and actual chooser behavior remain UNKNOWN. [E05, E11]

### F06. Honda NEVER is supported, but "confirmed safe / no interference" is not

Preserve the strong finding: `acceptDevice()` rejects NEVER before opening the raw phone, and the normal accessory branch declines NEVER. The settings Disable listener writes 0 through Honda's own identity. [E06]

Qualify the new adversarial review:

- `mAllowedDeviceSerial` is not a problem in a clean process that has never accepted that phone, but that precondition is not the same as proving it can never override NEVER. It is set before switching, checked before the NEVER branch, and is not cleared by the inspected ordinary detach path. Settings changes during an existing transition remain a counterexample to the unconditional statement.
- The claimed `startGalAfterSwitch()` path at line 912 is not present in this inspected `GalService.java`; line 912 belongs to timer setup. Use the actual methods and callers. `onEnableGal()` can call `setupGui(GALVIEW)` from DEVICE_NOT_SUPPORTED. This does not prove a spontaneous NEVER bypass, but it invalidates an argument that every GUI entry is reachable only through DEVICE_ACCEPTED.
- `changeState()` is not just a field assignment: it notifies device listeners. `ProjectionActivity` processes the change and can update its view. This does not prove USB contention, but the "internal state only" argument is incomplete.
- USB handling occurs before the preference check. In addition to CDP_OFF on attach, the detach path can request CDP_ON. The Java socket client proves commands are sent; the name CDP does not prove their physical effect is harmless.
- Bounded inspection found the matching stripped `usbresetserver` binary and command strings, but did not establish the complete native command-to-hardware behavior. Its disruption risk remains **UNKNOWN**, not quantitatively LOW on this evidence.

Recommendation: describe the approach as **SUPPORTED under clean-state/device-identity assumptions; end-to-end behavior untested**. Observe the preference branch, resets, ownership and service lifecycle separately. An icon being gray is not sufficient proof of every condition. [E06]

### F07. Protocol errors and video-focus ordering need independent treatment

The v6f log contains a TLS bad-record-MAC/decryption error at line 3134, followed by 21 `GAL error=-251` messages in the helper session. This precedes its later transport timeout. The phone did not simply remain silent immediately after service discovery: the log contains codec setup and 13 helper ping responses. [E07]

Current `GalReceiver.incoming()` discards the native queue return value; `unrecoverableErrorCallback()` only logs. Recommendation: preserve the first terminal protocol error and schedule one coordinated shutdown, with worker/native ownership handled deliberately. Do not overwrite the first cause with a later read timeout or synchronously destroy objects inside an unreviewed native callback. [E07]

Native video-focus findings were rechecked against library SHA-256 `031797DD4B0AECCA007A3AD7AF31C365BA3D47BEBDA8C94BFF13C5289F464C50`:

- `ProtocolEndpointBase::onChannelOpened` at `0xC9AE0` sets the open flag at object offset +4 and channel ID at +5.
- `VideoSink::setVideoFocus` at `0xCA2D0` builds the message, tests +4, and skips queuing when false before freeing the temporary buffer. That path does not retain a pending focus request.
- `VideoSink::handleSetup` at `0xCA338` invokes the callback before sending configuration and evaluating its auto-start flag.
- Discovery handling at `0xCD420` calls the callback before its subsequent response path. Native initialization stores the boolean used by setup at +0x2c.
- Our facade passes `autoStart=false`. Posting a request from discovery onto a handler changes scheduling but does not prove the video channel is already open. The current recursive 2-second retry is unbounded while running/unselected despite its "Retry once" comment.

This supports a **specific channel-readiness race**. It does not prove that race caused v6f or that turning on autoStart alone repairs the complete protocol. Review the intended native setup/focus contract, instrument request acceptance, and bound retries by protocol state. Evidence: companion disassembly plus E07.

### F08. Decoder fixes are partial; reconcile old reviews against current source

| Earlier finding | Current source assessment |
|---|---|
| Codec reference published before configure/start succeeds | Changed: local `mc` is assigned to the field after successful startup; failure releases it |
| Acquired input buffer abandoned on capacity failure | Changed: zero-length buffer is now queued before throwing; vendor recovery behavior remains untested |
| Config-failure log spam | Changed: logging has a counter condition |
| Initial IDR lost while config feeding fails | Still present as a control-flow risk: packet is dropped and ACKed while config is deferred |
| Config A/B lost-update interleaving | Still present: separate mutable `config` and `configFed`; simple volatile fields alone would not make the pair atomic |
| Missing config accepted | Still present: `header == null` returns true |
| Output-drain exception exits worker | Still present: drain is outside the per-packet recovery block |
| Temporary surface absence becomes permanently broken | Still present: codec-null exception sets `broken=true` |
| Format/config changes ordered with media packets | Still absent; config updates bypass the packet queue |

A concrete lost-update trace is: worker captures A -> reader installs B and clears configFed -> worker finishes A and sets configFed=true -> B is skipped. A concrete startup risk is: config submission times out -> the packet carrying an initial IDR is acknowledged/discarded -> later dependent frames do not establish a decodable sequence. The latter depends on actual packet contents; no IDR loss was proven from the car log. [E08]

Recommendation: use one owner for codec/config state and define a bounded retention/resynchronization policy for complete access units. Distinguish normal backpressure from codec failure. A rendered counter should distinguish accepted input, output dequeued/released, and visible-screen confirmation. `releaseOutputBuffer(..., true)` alone is not a physical-screen observation.

Do not repeat already-addressed review findings as current blockers; do not label the remaining decoder as recovered solely because the permanent first-timeout latch was removed. The latest recorded APK still differs from this current decoder source. [E02, E08]

### F09. Input and service stubs are separate completion gaps

The effective helper `InputSource.registerTouchPad()` hardcodes `tapAsSelect=false`. `AaSessionService.onAaTouch()` forwards DOWN/UP/MOVE as pad motion and does not reproduce Honda's DPAD_CENTER press/release conversion or key registration. It clamps raw X to 1324 rather than consuming the supplied `aaX` coordinate; correct coordinate semantics need evidence, not a blind rescaling change. [E09]

The prior touchpad review also found that Honda hover input enters its AA pipeline. A persistent native touchbridge latch and a reboot-free restoration operation remain UNKNOWN. Avoid treating video focus restoration as a demonstrated input-routing reset. See [touchpad investigation](codex-touchpad-investigation.md).

AudioSink currently ACKs and discards audio. AudioSource logs a denied mic request but returns 0 and does not implement capture; the protocol meaning of that return is not established by its log message. SensorSource reports static parked/day/speed values. These are test stubs, not vehicle integration. [E09]

Reconciliation: the old service-stub review describes mic return -1 and fuel type {1}; current source has return 0 and empty fuel/connector arrays. Preserve the historical review, but do not apply those old byte-level findings to current code unchanged.

### F10. The test runner can announce readiness after prerequisites fail

Confirmed in current script:

- Device enumeration checks for the target, but subsequent ADB invocations are not explicitly serial-selected. A multi-device environment is not handled by that initial check alone.
- A non-successful install prints a message and continues.
- Helper/accessibility checks use a `ServiceRecord` text match; this is not evidence that the accessibility service is bound, enabled, retrieving windows, or ready to click.
- The fallback at line 169 replaces the enabled-accessibility list with only our service, unlike the initial append behavior.
- After the retry still fails, execution reaches the green READY message.
- The cleanup timer starts before readiness and human plug-in. It later force-stops the entire helper package, including accessibility.
- The Honda loop is 300 command executions with no elapsed-time bound or sleep. The stated 30-second window is not enforced by the script.
- Anonymous surviving cleanup timers have no session identity; overlap between invocations is a design risk, not an observed cause established here.

Recommendation: make readiness reflect verified prerequisites, preserve existing settings through recovery paths, identify all background work by session, and tie bounded cleanup to the experiment being cleaned up. The v6h proposal explicitly retaining the safety timer and accessibility setup "as-is" leaves these issues unresolved. [E10]

### F11. Retain corrected causal claims and avoid reopening dead ends without new evidence

The dialog review **refuted the supplied HMI broadcast -> AMS activity-finishing causal chain as written**. HMI sends a broadcast; AMS's close operation is a different entry path that itself sends a notification. The actual dismissing actor was not established. `usb-default-research.md` should not revive the old explanation as fact. [E11]

Likewise:

- A host USB timeout does not uniquely identify the phone's file-descriptor state. Earlier transport narratives remain hypotheses without phone-side or lower-level evidence.
- Permission, device open, interface claim, TLS, discovery, video selection, and actual rendering are separate observations. One success is not proof of the next.
- The v6e `1525 frames` message counts outgoing transport packets, not rendered video frames.
- A matching filter alone does not auto-grant an ordinary app; a saved matching default is a different path.
- Force-claiming an interface is not a supported proof that another app's open file descriptor was revoked.
- Re-signing the Honda APK or another system app does not bypass installed-package/shared-UID signature checks.
- A DPI/negotiation-only change does not establish correct stock viewport, decoder crop, or physical window area.

Use the [dialog review](codex-dialog-kill-review-20261028.md), [proxy geometry analysis](CODEX-PROXY-VIDEO-CONFIG-ANALYSIS.md), and [deployment report](../DEPLOYMENT-PATHS.md) as indexes to their primary evidence. No new device permissions or recovery capabilities were discovered in this consolidation.

### F12. Historical session matrix: compare the stage, not the filename

These counts are extracted from saved files using the exact patterns in `evidence.json`. RDX-stage metrics require the `RDX.SESSION` tag. File labels are not timestamps or binary identities, and zero matches do not establish complete capture.

| Saved log suffix | Our sessions / USB opens | Discovery / codec setup | Video selected / decoder started | Helper ping replies / GAL errors | Interpretation |
|---|---:|---:|---:|---:|---|
| 1100 | 1 / 1 | 1 / 0 | 0 / 0 | 0 / 0 | Reached discovery; no later video-stage marker |
| 1130 | 0 / 0 | 0 / 0 | 0 / 0 | 0 / 0 | No helper session-start marker in this capture |
| 1145 | 2 / 2 | 0 / 0 | 0 / 0 | 0 / 0 | Two opened helper sessions, no discovery marker |
| 1400 | 1 / 0 | 0 / 0 | 0 / 0 | 0 / 0 | Helper created; open-success marker absent |
| 1730 | 1 / 1 | 1 / 0 | 0 / 0 | 0 / 0 | Reached discovery |
| v6e | 1 / 1 | 1 / 1 | 1 / 1 | 86 / 0 | Selected 1920x1080 encoded / 1920x720 active; decoder input failure follows |
| v6f | 1 / 1 | 1 / 1 | 0 / 0 | 13 / 21 | TLS bad-record-MAC event; no selection/decoder start |
| v6g-retry | 0 / 0 | 0 / 0 | 0 / 0 | 0 / 0 | Permission/startup failure class; no decoder experiment established |
| v6g | 0 / 0 | 0 / 0 | 0 / 0 | 0 / 0 | Only 24 bytes; not useful session evidence |

All nine have zero matching helper first-render markers. v6e/v6f also contain Honda activity; do not attribute Honda codec or later TLS events to our app merely because they share the same file. The v6f bad-MAC event belongs to PID 5253, the helper session PID. [E12]

### Recommended preparation packages for Claude's review

These are candidate work packages and acceptance criteria, not assigned milestones or authorization to deploy them. Review dependencies before choosing an implementation scope.

| Candidate | Purpose | Concrete acceptance criteria |
|---|---|---|
| Evidence/provenance reconciliation | Ensure a test can be attributed to its actual code | Exact APK hash, effective source hashes, native-library hash, test log, and installed-build observation linked; unknowns explicit |
| Cooperative startup specification | Make Honda NEVER useful without a laptop signal | Device-scoped configuration; cold-start/restart behavior; intentional startup path; no hidden unconditional Honda force-stop/reset in that mode |
| Helper lifecycle repair | Make reconnect and absent-callback behavior deterministic | Missing callback terminates boundedly; duplicate start does not duplicate AOAP switch; detach/stop resets ownership; next connection can start |
| Default-selection handling | Remove unnecessary dialog races | Raw and accessory defaults distinguished; chooser selects exact app; settings verified after package change; manual fallback clear |
| Protocol error/focus handling | Separate channel readiness from arbitrary delay | First fatal error preserved, one coordinated stop; focus request accepted only at an established state; finite retry policy |
| Decoder ownership/recovery | Progress from negotiated geometry to usable video | Ordered config/media, retained/resynchronized keyframe policy, surface-loss handling, failure classification, output/crop evidence |
| Input/audio completion | Progress from picture to usable projection | Correct compiled input facade, press/release mapping, coordinate validation, actual playback/capture semantics and real-state integration |

Suggested offline cases for any future implementation review:

1. Cold service start with persisted user mode; restart with null intent; different phone arrives.
2. Permission requested, then no callback; detach before callback; stale callback after another attachment.
3. Duplicate raw AUTO_GRANTED while switch is pending; second AOAP attachment after a completed session.
4. Saved default invalidated by an app update; resolver appears instead of a permission alert.
5. Codec config A in progress while B arrives; config delayed while initial IDR arrives; output drain fails; surface invalid at first frame.
6. Fatal native/TLS callback while workers are active; cleanup deadline exceeded; old callback arrives during a new session.
7. Video focus requested before channel-open and after setup; ensure no unbounded timer chain.
8. Install failure or unavailable accessibility; runner must not report readiness.

For later separately authorized hardware evaluation, use one changed factor at a time, a fixed build, durable local logs, and explicit stage results. Actual changing frames, 1920x720 content/crop, input behavior, and reconnect should be observed separately. A Wi-Fi receiver comparison can isolate a useful combination, but changing both transport and implementation at once cannot identify which caused the difference.

The alternatives review remains relevant: an updated helper is the shortest route to preserving current progress; Open Headunit is an inspectable independent receiver; HUR is a packaged comparison; direct Wi-Fi removes the shared phone USB path only when that data path is absent. Exact RDX compatibility is UNKNOWN. Upstream product information was not refreshed in this local consolidation; consult the dated [alternatives report](codex-20261029-laptop-independent-receiver-alternatives.md) and revalidate the selected release before spending time on deployment.

## 6. Primary evidence index

Line numbers refer to the reviewed source snapshot. Logs use **LF-delimited physical lines**, stripping CR while retaining blank lines, to agree with `rg` despite CRCRLF captures.

- **E01:** [PROJECT-STATE.json](../parallel-aa-receiver/PROJECT-STATE.json), `date`, `milestones`, and `lastM5LiveResult`; [CLAUDE-CURRENT-WORK.md](CLAUDE-CURRENT-WORK.md), final October 27 check-in; initial Git command output and companion preservation inventory.
- **E02:** [latest-build.txt](../parallel-aa-receiver/usb-helper/latest-build.txt); [build-report.json](../parallel-aa-receiver/usb-helper/build/20261028-164612-233/build-report.json), `apk`, `sha256`, `staticAudit`, `sourceHashes`; companion `latest_build.sources` comparison. [Build-RdxUsbHelper.ps1](../../scripts/Build-RdxUsbHelper.ps1):55-63 selects source precedence. [Run-CarTest.ps1](../../scripts/Run-CarTest.ps1):43-48 reads the pointer.
- **E03:** [v6h plan](v6h-honda-disable-plan.md), flag/action snippets, Step 7 replacement, and proposed file table; [UsbHelperService.java](../parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/UsbHelperService.java):88-160 startup and intent handling, 195 raw gate, 397 callback gate, 466 raw matcher; [Run-CarTest.ps1](../../scripts/Run-CarTest.ps1):66 onward unconditional Step 3.
- **E04:** [UsbHelperService.java](../parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/UsbHelperService.java):67-84 detach logging, 129-137 GRANTED duplicate branch, 168-174 terminal polling, 207-267 state handling, 313-334 request path, 366-425 callback path; [AaSessionService.java](../parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/AaSessionService.java):566-629 shutdown. [HelperActivity.java](../parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/HelperActivity.java):301-303 permission-only success; [BootBlockerReceiver.java](../parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/BootBlockerReceiver.java):14 boot target; [manifest](../parallel-aa-receiver/usb-helper/AndroidManifest.xml):8-31 entry points.
- **E05:** [UsbSettingsManager.java](../../decompiled/Services/sources/com/android/server/usb/UsbSettingsManager.java):372-390 package monitor, 400-406 persisted settings, 604-620 attach/detach, 665-695 defaults, 724-732 removal, 746-809 package update, 923-937 save; [UsbResolverActivity.java](../../decompiled/SystemUI/sources/com/android/systemui/usb/UsbResolverActivity.java):69-91 selected app/default handling; [UsbPermissionActivity.java](../../decompiled/SystemUI/sources/com/android/systemui/usb/UsbPermissionActivity.java):93-96; [PermissionClickService.java](../parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/PermissionClickService.java):34-54 event filter, 114-147 validation/click behavior. [usb-default-research.md](usb-default-research.md) contains the claims being qualified.
- **E06:** [GalService.java](../../decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/service/GalService.java):719 pre-preference handler, 736-759 accessory branch, 808-845 detach, 855-874 speed path, 889-938 timer/start behavior, 973-1005 switch/allowed serial, 1058-1067 NEVER rejection, 1399-1407 listener notification, 1593-1634 GUI start, 1803-1845 enable/disable/reset. [SelectDeviceActivity.java](../../decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/settings/SelectDeviceActivity.java):48-84; [StartPreferences.java](../../decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/settings/StartPreferences.java):33-35 and 88-105; [GalUsbReset.java](../../decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/common/GalUsbReset.java):34 onward socket client; [ProjectionActivity.java](../../decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/ui/ProjectionActivity.java):232-234, 2373-2411 listener effects. [Adversarial review](honda-disable-adversarial-review.md) is the challenged claim source.
- **E07:** [v6f log](../logs/car-test-20261028-v6f.txt):2113 helper PID, 2624 codec setup, 3133-3137 TLS/error sequence; companion ping/error counts. [GalReceiver.java](../parallel-aa-receiver/src/com/google/android/projection/protocol/GalReceiver.java):64 and 70; [AaSessionService.java](../parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/AaSessionService.java):458-483 request/retry, 514-516 setup callback; [VideoSink.java](../parallel-aa-receiver/src/com/google/android/projection/protocol/VideoSink.java):24 autoStart false, 33 focus call. Exact native addresses/hash/commands: [native-video-focus.txt](claude-resume-20261102/native-video-focus.txt).
- **E08:** [VideoDecoder.java](../parallel-aa-receiver/src/com/rdx/fullscreen/projection/VideoDecoder.java):17-18 state pair, 31 config setter, 33-42 codec creation, 44-67 config/feed, 69-80 drain, 83-112 loop/ACK/exit. [Historical decoder review](codex-v6f-decoder-review.md) F1-F8 supplies the prior claims, not current source parity.
- **E09:** Effective [helper InputSource.java](../parallel-aa-receiver/usb-helper/source/com/google/android/projection/protocol/InputSource.java):59-86; [AaSessionService.java](../parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/AaSessionService.java):191-205 and 295-299; stock [ProjectionActivity.java](../../decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/ui/ProjectionActivity.java):559-587 click/hover; [AudioSink.java](../parallel-aa-receiver/src/com/google/android/projection/protocol/AudioSink.java):54-56; [AudioSource.java](../parallel-aa-receiver/src/com/google/android/projection/protocol/AudioSource.java):48-51; [SensorSource.java](../parallel-aa-receiver/src/com/google/android/projection/protocol/SensorSource.java):59-61 and 74-81. Historical [service-stub review](codex-v6e-service-stubs-review.md) F6/F7 differs from current source.
- **E10:** [Run-CarTest.ps1](../../scripts/Run-CarTest.ps1):18-20 unspecific shell invocation, 29-34 device check, 55-61 install handling, 129-140 timer/loop, 153-182 readiness/recovery; [device-kill-honda.sh](../../scripts/device-kill-honda.sh):4-8 count-based loop. [v6g-retry log](../logs/car-test-20261028-v6g-retry.txt):101-111 package force-stop and accessibility stop; 291 failed app force-stop.
- **E11:** [Dialog review](codex-dialog-kill-review-20261028.md), findings and primary-evidence sections; stock [HMIPresenter.java](../../decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/presentation/HMIPresenter.java):842-844 versus [ActivityManagerService.java](../../decompiled/Services/sources/com/android/server/am/ActivityManagerService.java):3991-4026. [PackageManagerService.java](../../decompiled/Services/sources/com/android/server/pm/PackageManagerService.java):4427-4449 signature checks. [DimensionUtils.java](../../decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/video/DimensionUtils.java):14-28 viewport logic.
- **E12:** Companion [evidence.json](claude-resume-20261102/evidence.json), `patterns`, `log_metrics`, and `log_caveats` contain all counts, hashes, and first/last evidence lines. [v6e log](../logs/car-test-20261028-v6e.txt):6587 selection, 6737 decoder start, 6747 input failure, 10759 outgoing transport count.

Useful retained indexes: [deep integration evidence](deep-integration-20261027/README.md), [touchpad investigation](codex-touchpad-investigation.md), [proxy geometry](CODEX-PROXY-VIDEO-CONFIG-ANALYSIS.md), [deployment paths](../DEPLOYMENT-PATHS.md), [2022 reference requirements](../2022-reference-needed.md), and the [alternatives review](codex-20261029-laptop-independent-receiver-alternatives.md). Consult their dated scope and primary evidence before reusing conclusions.

## 7. Assumptions

- The intended result remains reliable, correctly rendered 1920x720 Android Auto on the captured D.1.6.4/API22/ARMv7 RDX head unit, followed by usable input/audio and independent operation.
- Saved firmware and logs are relevant to that target; no live state or exact currently installed APK identity is assumed.
- Source changes made before this review belong to ongoing project work and are preserved.
- This handoff is for Claude's review when usage returns. It does not create a task scheduler, autonomous continuation, or permission for live work.

## 8. Unresolved uncertainties

**UNKNOWN:** the exact APK used by every historical session; current installed state and persistent USB defaults; native CDP command effects; total Honda side effects under NEVER; whether the focus race explains v6f; origin of the TLS corruption; actual keyframe/config contents and TI decoder behavior; causes of persistent touchpad problems; full-surface visible rendering; real audio/mic/vehicle-state integration; and exact alternate-app release compatibility.

The absence of a first-render marker and the existence of source-level counterexamples do not prove what happened outside captured logs. No phone trace, USB bus trace, or live visual verification was acquired. The number of reviewed files, code paths, or historical checks is not a confidence percentage for the whole system.

## 9. Exact diff summary

Added this handoff and its two companion evidence files. No existing implementation, script, plan, state document, log, or frozen artifact was changed. The companion JSON records the starting 263-file inventory and final comparison. No implementation recommendation is represented as completed work.

## 10. Preservation checks performed

All four frozen artifacts matched the exact anchors in `PROJECT-RULES.md`; full paths and expected/actual hashes are in `evidence.json` under `frozen_artifacts`. The native receiver library also matches `031797DD4B0AECCA007A3AD7AF31C365BA3D47BEBDA8C94BFF13C5289F464C50`.

The final comparison checks the 263 pre-existing files against hashes collected before this review. New handoff artifacts are excluded from that baseline. Document validation checks the ten required report sections, companion JSON parseability, and local-link targets.

No private key/keystore/credential material was opened, no car/phone/USB device was touched, no frozen binary was rebuilt, no readiness guard was changed or bypassed, and no Git mutation or milestone advancement occurred.
