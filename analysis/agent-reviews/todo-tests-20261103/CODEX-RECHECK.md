**Re-review does not pass. T11 retains a teardown blocker, T12 has a new generation-identity blocker, and source-lifecycle tooling remains partly fixed.**

All paths below are repository-relative. Citation aliases:

- `R` = `analysis/test-prep/todo-tests-20261103`
- `C09` through `C13` = corresponding `R/builds/T09-volume-display`, `T10-track-buttons`, `T11-mic`, `T12-reconnect`, `T13-day-night`
- `H` = `source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper`
- `P` = `source/analysis/parallel-aa-receiver/src/com/google/android/projection/protocol`
- `Tools` = `R/tools`
- `Baseline` = `R/baseline-source`

**1. Files inspected**

Read `PROJECT-RULES.md` and `AGENTS.md` first, then the previous `analysis/agent-reviews/todo-tests-20261103/CODEX-REVIEW.md`.

Inspected current candidate source, source manifests, candidate/build metadata, baseline records and relevant baseline implementations; suite tooling, documentation, cards, host-test sources/results; generated preparation/collection scripts and canonical templates.

Supporting source included `CarTest.Core.ps1`, the standard builder, `GalReceiver`, Android service/receiver dispatch, stock sensor dispatch, and Android broadcast-record/filter dumping and permission enforcement.

Preservation manifests and the specified frozen artifacts were read for hashing only.

**2. Files changed**

None. No report file was written.

**3. Commands run**

Only local, read-only inspection:

- `Get-Content`
- `rg --files` and `rg -n`
- `node -e` using filesystem reads, SHA-256 calculations, metadata/template comparisons, numbered excerpts, and an in-memory permission-parser counterexample

Two inspection commands failed because of shell quoting/parsing and were corrected. One optional `rg` wildcard path produced a path error.

No operational suite script, device command, ADB, build, Git, network action, or agent delegation ran. No key/credential/private-test file was opened.

**4. Tests run and results**

| Check performed during this review | Result |
|---|---|
| Candidate copies versus source manifests | PASS: 13/13 entries |
| Intended Java changes versus Maps provenance | PASS: exactly 2/2/1/4/3 for T09–T13; no unexpected changes or removals |
| Candidate APK hashes versus candidate/build metadata | PASS: 5/5 |
| Recorded manifest and native hashes versus supplied inputs | PASS: 5/5 each |
| Live Maps Java provenance | PASS: 27/27 |
| Saved and live baseline tracked paths, including absences | PASS: 11/11; `active-source.json` absent |
| Generated PowerShell versus templates after allowed substitutions | PASS: 18/18 |
| Generated shell helpers versus templates | PASS: 24/24 byte-identical |
| Frozen artifact anchors | PASS: 4/4 |
| Readiness script/core/schema versus integrity manifest | PASS: 3/3 |
| Signal-permission attribution counterexample | Defect reproduced using the script’s extracted regex |

Saved host outputs report **11 volume, 63 track-button, 22 reconnect-policy, and 10 day/night checks passing**. These outputs were inspected, **not rerun**. No microphone host test was present.

**5. Findings — previous findings, individually reassessed**

| Previous finding | Status | Current evidence |
|---|---|---|
| T10: lost release suppresses subsequent controls | **FIXED** | Every fresh, noncanceled, nonrepeat press replaces ownership: `C10/H/InputEvents.java:48-53`. |
| T10: consecutive press/release differs from stock timing | **FIXED** | Overlay sends release through a 100 ms delayed callback: `C10/H/AaOverlayService.java:179-183`. |
| T10: stock/Bluetooth path can duplicate a skip | **ACCEPTED-RISK** | Candidate consumes local delivery only: `C10/H/AaOverlayService.java:172-187`. Bluetooth comparison is explicitly required: `R/cards/T10-track-buttons.md:14-19`. |
| T10: declaring 87/88 also broadens generic local dispatch | **ACCEPTED-RISK** | Still accepted by `key()` and `dispatchKey()`: `C10/H/InputEvents.java:15-27`. |
| T11: native destruction before capture termination | **PARTLY FIXED** | AudioSource retains its native object when capture survives, but parent cleanup still proceeds. See F1. |
| T11: recorder leaked when `startRecording()` throws | **FIXED** | Catch releases the locally constructed recorder: `C11/P/AudioSource.java:105-123`. |
| T11: unlimited failed preparations | **FIXED**, with new race | Failure pauses capture after the preparation batch: `C11/P/AudioSource.java:103-135`. New-open race described in F6. |
| T11: zero-length reads spin without error accounting | **FIXED** | `len <= 0` increments errors and sleeps; inner capture ends after three errors: `C11/P/AudioSource.java:139-148`. |
| T11: ACKs cross microphone sessions | **ACCEPTED-RISK** | Mismatches are logged, but ACKs still release the current semaphore: `C11/P/AudioSource.java:67-70,79-81`. |
| T11: no strict outstanding-frame ceiling | **NOT FIXED** | Send still precedes acquire, and timeout permits continued sending: `C11/P/AudioSource.java:157-163`. The stated session-mapping acceptance does not establish a ceiling. |
| T13: late watcher report overlaps sensor destruction | **FIXED** at the Java lifetime boundary | Post-read running check plus synchronized reporting/destruction: `C13/H/NightModeWatcher.java:63-69`; `C13/P/SensorSource.java:74-95`. Native deadlock/termination remains UNKNOWN. |
| T13: failed report suppresses retry | **FIXED**, assuming zero means success | `reported` advances only after delivery succeeds: `C13/H/NightModeWatcher.java:66-69`; result interpretation: `C13/P/SensorSource.java:85-89`. |
| T12: disabled/cooldown states fail to guard ordinary handoffs | **FIXED** | Policy rejects disabled, active and cooldown starts; helper invokes it before handoff: `C12/H/ReconnectPolicy.java:27-34`; `C12/H/UsbHelperService.java:492-515`. |
| T12: duplicate handoffs increment generation | **FIXED** within one helper lifetime | Active policy rejects another start without incrementing: `C12/H/ReconnectPolicy.java:28-31`. Cross-lifetime identity defect remains F2. |
| T12: clean completion excludes audio workers | **FIXED** for the completion flag | Both workers are checked before notification: `C12/H/AaSessionService.java:633-637,660`; `C12/P/AudioSink.java:97-98`. |
| T12: explicit session STOP automatically rearms | **FIXED** | STOP records operator intent; policy disables reconnect: `C12/H/AaSessionService.java:123-125,667`; `C12/H/ReconnectPolicy.java:50`. |
| T12: completion broadcast can be lost/spoofed | **PARTLY FIXED** | Broadcast is now a reconciliation prompt, backed by static state and watchdog: `C12/H/UsbHelperService.java:75-78,520-539`. F2 compromises identity after helper recreation. |
| T12: destruction before running omits completion | **FIXED** for reporting | Reports unclean when `sessionActive` but not running: `C12/H/AaSessionService.java:685-690`. |
| T12: attachment restarts a stopped helper | **ACCEPTED-RISK** | Explicitly documented: `R/REVIEW.md:15-16`. |
| Tooling: incomplete source verification/already-active shortcut | **PARTLY FIXED** | All 11 tracked paths are covered, including manifest/additions; already-active tests revalidate: `Tools/Switch-Source.ps1:19-26,29-35,56`. Unlisted files/resources/native inputs are not checked by this verifier. |
| Tooling: failed preparation silently leaves candidate source | **PARTLY FIXED** | Ordinary preparation failures restore before READY: `Tools/Run-Test.ps1:103-107`. Partial switch failures remain unhandled as ownership failures; F4. |
| Tooling: Build-Test restores another active test | **PARTLY FIXED** | Different-test refusal no longer restores, and launcher locking exists: `Tools/Build-Test.ps1:24-30,55-57`. Already-active same-test case remains F3. |
| Tooling: signal permission verdicts overstate evidence | **PARTLY FIXED** | Record parsing replaces the arbitrary window: `Tools/Check-Signals.ps1:30-40`. Nested filter permissions still contaminate attribution, and line 43 still infers likely exclusion. See F5. |

T09’s HUD cleanup remains sound in the inspected code: `C09/H/AaOverlayService.java:564-584,598-624`. Runtime broadcast delivery remains **UNKNOWN**.

**6. Primary evidence and new findings**

**F1 — BLOCKER: T11 retains the child native object while destroying its parent receiver.**

When capture survives its join, `AudioSource.destroy()` returns without native shutdown, after clearing `created` and removing `capture`: `C11/P/AudioSource.java:50-61`.

The unchanged session coordinator receives no failure result. It continues from `audioSource.destroy()` to `receiver.destroy()` and logs clean release: `Baseline/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/AaSessionService.java:613-621`.

The audio source was initialized with the receiver handle and registered into that receiver: same baseline file `:335-338`; receiver registration/destruction enter native code: `analysis/parallel-aa-receiver/src/com/google/android/projection/protocol/GalReceiver.java:65-66,77`.

Thus retention does **not** establish a safe teardown boundary for the remaining stack. Actual native use-after-free behavior is **UNKNOWN**, but parent lifetime is not preserved while capture may remain inside JNI. The coordinator must learn that capture did not terminate and retain the required parent resources too.

**F2 — BLOCKER: T12 reuses generation identities while static completion state survives helper recreation.**

Each new helper constructs a new policy: `C12/H/UsbHelperService.java:68`. Its generation starts at zero and increments to one: `C12/H/ReconnectPolicy.java:17,31`.

Conversely, `AaSessionService.lastEnd` is static and survives helper recreation: `C12/H/AaSessionService.java:73-78,667`. A new start does not invalidate that old completion: `:111-115`.

Counterexample:

1. Previous helper’s generation 1 finishes cleanly.
2. Helper is recreated; its next handoff is generation 1 again.
3. That new START is lost or has not published matching live state.
4. Reconciliation accepts the **old** generation-1 completion as current, bypassing the grace-period failure handling and choosing clean rearm.

The decisive predicates are `C12/H/UsbHelperService.java:532-539`, followed by `C12/H/ReconnectPolicy.java:48-56`.

Generation identity needs to remain unique across helper lifetimes, or reconciliation needs an additional lifetime/start identity.

**F3 — SHOULD-FIX: Build-Test can still restore an active same-test candidate.**

`Switch-Source -Test` succeeds when that test is already active: `Tools/Switch-Source.ps1:56`. Build-Test then sets `$switched=true` and unconditionally restores baseline in `finally`: `Tools/Build-Test.ps1:28-30,55`.

Run-Test releases the launcher lock when preparation returns: `Tools/Run-Test.ps1:111`. Therefore the lock does not protect the subsequent car-test period awaiting collection.

Also, Build-Test rewrites `source-manifest.json` **before acquiring the lock**: `Tools/Build-Test.ps1:15-25`. A refused concurrent build can already have changed verification metadata.

**F4 — SHOULD-FIX: partially failed source switches escape restoration/warnings.**

Switch-Source writes active state before copying candidate files: `Tools/Switch-Source.ps1:65-70`. A later copy/verification failure can leave a partially switched tree.

Both callers set `$switched` only after successful subprocess exit: `Tools/Run-Test.ps1:67-69`; `Tools/Build-Test.ps1:28-30`. Consequently, their restoration logic does not cover that partial mutation. Run-Test’s active-source warning is also conditional on this flag: `:103-107`.

**F5 — SHOULD-FIX: whole-record scanning confuses receiver sender-permissions with broadcast delivery restrictions.**

Android dumps receiver-filter details inside each broadcast record: `decompiled/Services/sources/com/android/server/am/BroadcastRecord.java:188-199`. Those details also print `requiredPermission=`: `decompiled/Services/sources/com/android/server/am/BroadcastFilter.java:30-43`.

These permissions constrain the **sender**, whereas the broadcast record’s permission constrains the receiver: `decompiled/Services/sources/com/android/server/am/BroadcastQueue.java:297-307`.

Check-Signals scans every line without distinguishing those fields: `Tools/Check-Signals.ps1:40-43`. The in-memory counterexample, using its extracted regex, attributed `example.SENDER_ONLY` to an otherwise unrestricted broadcast.

**F6 — SHOULD-FIX: T11’s failure pause can overwrite a subsequent open.**

An open resumes capture under `pauseLock`: `C11/P/AudioSource.java:79-83,186-187`.

After preparation fails, the worker independently acquires that lock and sets `paused=true`: `:132-135`. An open arriving between the failed preparation and that assignment is overwritten, leaving the newly requested capture paused until another open.

**OK — T12’s inspected concurrency and cooldown handling.**

- `liveGeneration` and `lastEnd` are volatile; completion fields are final; completion publishes before live state clears: `C12/H/AaSessionService.java:73-78,667-668`.
- Receiver reconciliation and watchdog use the main handler: `C12/H/UsbHelperService.java:107,114,521-524`. Default receiver scheduling uses the main handler: `decompiled/Framework/sources/android/app/ContextImpl.java:1461-1471`.
- Cooldown refusal explicitly reschedules polling: `C12/H/UsbHelperService.java:500-505`. I found no ordinary cooldown-refusal path that leaves polling stopped.
- **Direct grant still bypasses handoff:** `C12/H/UsbHelperService.java:410-412`. Polling then exits at `:225`. This is baseline behavior (`Baseline/.../UsbHelperService.java:395-397`) and documented acceptance (`R/REVIEW.md:17`), rather than a newly introduced session-start bypass.

**OK, with UNKNOWN native behavior — T13 synchronization.**

The monitor prevents sensor report/shutdown overlap. No definite Java/native callback deadlock was established. However, a stuck native report holds that monitor, so `destroy()` can wait without a bound despite the watcher’s timed join: `C13/P/SensorSource.java:85-95`; `C13/H/NightModeWatcher.java:47-53`.

The “still in Binder read” message cannot establish where the surviving thread actually is; it could be inside the listener/JNI call at `:67`.

**Candidate verdicts**

These are operational package verdicts, including shared tooling.

| Candidate | Verdict | Reason |
|---|---|---|
| T09 volume display | **NOT READY** | No candidate-code blocker found; shared source-lifecycle tooling remains incomplete. T06 delivery prerequisite also remains unproven. |
| T10 track buttons | **NOT READY** | Requested code fixes pass inspection; shared tooling remains incomplete. Double skip remains accepted test risk. |
| T11 microphone | **NOT READY** | F1 teardown blocker; F6 race; outstanding-frame ceiling unresolved. |
| T12 reconnect | **NOT READY** | F2 generation-identity blocker. |
| T13 day/night | **NOT READY** | Java lifetime fix passes inspection; shared tooling remains incomplete. Own-thread JNI safety remains UNKNOWN. |

**7. Assumptions**

- Baseline and build metadata identify the intended comparison artifacts.
- Decompiled framework/OEM code represents the captured firmware; live parity is not established.
- T13 interprets native result zero as success; this review did not establish that native method’s return contract.
- Documented accepted risks were treated as accepted limitations, not repaired behavior.

**8. Unresolved uncertainties**

**UNKNOWN:** native parent/child ownership and callback locking; native-call termination; actual microphone permission/routing; OEM broadcast delivery eligibility; actual duplicate skips; runtime teardown/reconnect behavior.

No live behavior was established.

**9. Exact diff summary**

None. This review changed no files.

**10. Preservation checks performed**

- All four frozen artifacts matched the complete SHA-256 anchors in `PROJECT-RULES.md:36-39`.
- Readiness script, core and schema matched `PROJECT-INTEGRITY.json`.
- Live source matched all 27 Maps Java hashes and all 11 baseline tracked-path expectations.
- Generated scripts retained all template content outside the allowed substitutions: **18 PowerShell matches and 24 shell matches**.
- No device, milestone, guard, credential or repository state was modified by this review.

Whole-workspace before/after equality is **UNKNOWN** because no complete initial snapshot was taken.