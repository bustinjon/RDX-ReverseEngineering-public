# M5 lock-task UI failure reconstruction — 2026-10-25

**M5 INCONCLUSIVE.** The one standard permission request reached Android's permission-Activity launch path. Diagnostics lock-task mode rejected that launch. This does not demonstrate that ordinary-app USB permission is unavailable. No M5 harness change is justified by this evidence.

This is a local analysis of saved evidence, not another vehicle test. The [live result](M5-RETRY-LIVE-RESULTS.md), original timing-INCONCLUSIVE report, journals and raw logs remain unchanged. Evidence: [reconnect logcat](m5-live-retry-20261025-185128/reconnect-logcat.txt), [journal events](m5-live-retry-20261025-185128/journal-events.json), [pre-arm activities](warning-phonefree-20261025-190517/20261025-190548-460-activities.stdout.txt). Raw logs can contain device identifiers; the new fixture excerpt contains only relevant framework/Diagnostics lines.

## Exact sequence

Logcat times below are the saved Eastern local labels on October 25. App journal UTC times are four hours later.

|Time|Evidence and meaning|
|---|---|
|19:31:13.878|M5 ARMED, journal monotonic3050211|
|19:31:30.631|Selected accessory18D1:2D01 seen;16.753s after arm|
|19:31:30.658|One SDK request invocation journaled|
|19:31:30.671|`ActivityManager: START u0 {flg=0x10000000 cmp=com.android.systemui/.usb.UsbPermissionActivity (has extras)} from uid 1000 on display 0`|
|19:31:30.682|`ActivityManager: Attempted Lock Task Mode violation r=ActivityRecord{abfde64 u0 com.android.systemui/.usb.UsbPermissionActivity t-1}`|
|19:31:30.683|SDK request returned; this is not a UI-launch success or a grant|
|19:31:31.624–32.090|Diagnostics MenuActivity pauses/destroys; dealer Main starts/resumes; dropped touch entries near RETURN are supporting context|
|19:31:32.577|`dealer.Main: finish(), stop lock task`, then `ActivityManager: stopLockTaskMode`|
|19:31:50.602|Selected enumeration disappears; terminal DETACHED|
|19:31:50.644|SERVICE_END;36.767s after arm, not the300s deadline|

Lock-task exit occurred **1.895 seconds after rejection**. There was no callback and no verified `hasPermission=true`. User saw stock AA and no prompt. No reselection or second request occurred. The selected enumeration's disappearance is not evidence of a physical unplug; the phone remained connected while the system sequence was22D9:2769 →18D1:2D01 →22D9:2765 →18D1:2D01. Stock Honda switching is independent of M5.

## Owner, foreground and rejecting component

Owner: `com.honda.auto.diagnostics`, task4 rooted at `com.honda.auto.diagnostics/.dealer.MainActivity`. Pre-arm resumed/focused Activity: `com.honda.auto.diagnostics/.developer.USBModeSwitchActivity`, task4. Saved run Diagnostics PID2984 is a historical identifier, not a future matching rule.

`MainActivity.onCreate()` calls `startLockTask()`. Its overridden `finish()` logs the exact observed message and calls `stopLockTask()` before `super.finish()`. Sources: [MainActivity](../../decompiled/HondaDiagnostics/sources/com/honda/auto/diagnostics/dealer/MainActivity.java), [RETURN base handler](../../decompiled/HondaDiagnostics/sources/com/honda/auto/diagnostics/BaseContentsActivity.java), [menu navigation](../../decompiled/HondaDiagnostics/sources/com/honda/auto/diagnostics/MenuActivity.java).

The rejecting framework is API22 system_server ActivityManager / ActivityStackSupervisor, not a separate modern ActivityTaskManager service. Saved [ActivityStackSupervisor](../../decompiled/Services/sources/com/android/server/am/ActivityStackSupervisor.java) checks `isLockTaskModeViolation`: a different task cannot launch while `mLockTaskModeTask` is non-null. The rejected record has task `t-1`, not the locked Diagnostics task. The exact rejection establishes active lock-task protection at that instant even though no simultaneous getter reply was captured.

**Exit trigger: not established exactly.** The lifecycle/touch sequence, observed `MainActivity.finish()` and prior successful normal RETURN route support ordinary navigation as a plausible cause. There is no direct RETURN-handler invocation record proving that action caused this particular finish. Do not classify the1.895s interval as a timeout, automatic USB-triggered exit, or guaranteed transition delay. The saved MainActivity USB/full-mode receiver updates UI; its presence is not proof it called finish here.

## Normal future exit route

[Live02](LIVE-TEST-02-RESULTS.md) demonstrated normal RETURN navigation: USB Mode Switch → Developer Diagnostics → Detail Information & Setting → Dealer Diagnostics → Honda Home. Four RETURN actions were used from that particular starting screen; future operators follow the actual screen, not a fixed tap count or coordinate macro. ADB remained available. Do not change USB mode selections while exiting; those selections can write `dev.adb`.

No force-stop, lock-task stop command, package modification, synthetic input, settings write or reboot is needed by the prepared guard. The operator exits normally, then the host observes the result.

## What can be measured before ARM

|Signal|Classification|Limit|
|---|---|---|
|`isInLockTaskMode()` getter through reviewed API22 Binder dispatch|RELIABLE BY CODE, runtime query not yet exercised|Must match both pinned framework/services JARs first; error/unrecognized Parcel refuses|
|`dumpsys activity activities` resumed/focused component and task|RELIABLE for the reported foreground snapshot; SUPPORTING for lock state|Honda Home alone does not prove absence of a locked task|
|`dumpsys window` current focus and geometry|SUPPORTING|Does not expose dependable current lock ownership in saved dumps|
|Saved `dumpsys activity`/supervisor lock fields|NOT USEFUL as direct proof on this saved implementation|Supervisor dump does not print `mLockTaskModeTask` or `mLockTaskIsLocked`|
|Recent `stopLockTaskMode` log|SUPPORTING ONLY|History; lock mode may have re-entered|
|device_policy allowlist/statusbar flags/window policy/package metadata|SUPPORTING or UNKNOWN|No demonstrated current-lock boolean in saved target evidence; allowlist is not actual state|
|`am lock-task`|NOT A READ-ONLY QUERY|Saved am.jar requires a task ID or `stop`, mutates first, prints state afterward|
|Modern `cmd activity`/ActivityTaskManager syntax|NOT USED|Not established on this API22 target|

The read-only getter is transaction217 in the reviewed `android.app.ActivityManagerNative.onTransact`: enforce interface → `isInLockTaskMode()` → write no exception → write one boolean. ActivityManagerService synchronizes and returns supervisor `mLockTaskModeTask != null`. Transactions215/216 mutate state and must never be guessed or invoked. This session independently re-decompiled the saved framework dispatch and saved am command locally; no Binder call was made.

The checker first pulls and hashes `/system/framework/framework.jar` and `services.jar`. Required SHA256 respectively:

[Code block omitted from public report; see authored source where available.]

Only after both match may the future checker issue `adb -s 00000000 shell service call activity 217`. Success must contain exactly a zero exception word and one0/1 word. Active, denied, null, malformed or unknown means NOT_READY. Saved system build168 and latest live build14 differ in provenance; these binary hashes have not yet been compared with live build14. A mismatch stops before the numeric transaction. Preserve the pulled files for a narrow dispatch/getter review; do not add a bypass or use a guessed transaction.

## Consequence

The race is detectable before arm: Diagnostics foreground and active lock-task are refusal conditions. A five-second observed stable inactive window and an immediate second check address the demonstrated failure. Polling cannot prove continuous state between samples or guarantee future dialog launch after the cable swap. The next M5 remains a separately authorized live experiment with evidence-based PASS/FAIL/INCONCLUSIVE classification. Warning-detector historical installation persistence is a separate finding and was not modified.
