# Diagnostics shortcut regression — offline investigation, 2026-10-31

## 1. Files inspected

PROJECT-RULES.md; current run menu-access collection, window/input/policy/activity/package snapshots, main/system/events buffers, original filtered receiver capture and command journals; preceding long-drive command journal and actual deployed shell payloads. Current helper, accessibility clicker/config, BootBlocker, manifest and startup branches were inspected. Archived RDX android.policy.jar, its extracted public DEX, decompiled PhoneWindowManager and Generic.kl supplied the shortcut contract. AOSP InputReader references were consulted as a caution about interpreting input timestamps, not as proof of the live vendor implementation.

## 2. Files changed

Only new offline investigation scripts, extracted archive DEX/disassembly, indexed evidence, JSON comparisons/verification, NEXT-CAPTURE.md and this report under `analysis/agent-reviews/diagnostic-shortcut-20261031/`. No app source, APK, car state, existing evidence or Git publication changed during this review.

## 3. Commands run

Saved Inspect-Evidence.ps1, Inspect-PolicyAndKeys.ps1, verify-combo.cjs, Verify-Findings.ps1 and Compare-Preparation.ps1. SDK dexdump read the archived policy classes.dex. Read-only Get-Content/rg/Get-ChildItem inspected bounded source/evidence. A comparison-script parse error was corrected before it ran. Empty-match pipeline files were initially absent; structured counts/results rather than nonexistent excerpts support the zero-match claims. Official AOSP source lookup did not establish an exact vendor-equivalent InputReader revision, so no hold duration is inferred from its DownTime field. No device command, root operation, injected key, setting change or new build.

## 4. Tests run and results

128 key sets were executed through a constrained interpreter of the archived DEX BitSet predicates/control flow: only exact logical set `{3,4,172}` selects Diagnostics. The interpreter models the extracted predicates, not Android scheduling or real devices. The archived detector's3,000ms timer/start/cancel calls were verified in DEX. All28 current production input hashes and the A2F478… APK are unchanged. Seven original evidence files and the archived policy jar retain their hashes. The successful and failed preparations each recorded55 core commands; their normalized unique mutation-command sets match. Six actual deployed shell payloads match after normalizing only the run path. This set comparison alone does not prove command ordering or all possible external side effects.

## 5. Findings

**Operator clarification:** all three buttons were held long enough, over repeated attempts; this is the first occurrence of the failure. Treat that as the reported regression. Insufficient hold is not the leading explanation and is not assumed. Actual kernel overlap timing was not captured, so it remains a measurement gap rather than a diagnosis of user operation.

**Earlier entry and change boundary:** the retained system log records normal dealer-action launches from system UID1000 at16:22:50.417 and16:22:59.285, with flags0x10800000 matching the archived policy's launch path. Their exact physical trigger is UNKNOWN; these are not proof of a measured last-good three-button attempt. The following receiver preparation installed A2F478… instead of the earlier D1A29… build. Installation/preparation is therefore a boundary worth isolating, but temporal association does not prove the APK caused the regression.

**Actual startup changes:** old and new runs use PhonePreference, the same original accessibility baseline and equivalent deployed startup/cleanup/logging payloads. There is no new observed preparation mutation command that disables Diagnostics, changes a key layout or patches policy. The changed APK remains installed after cleanup; installer/OEM reactions or an indirect transient state change are not excluded merely because the command sets match. No changed persistent OEM setting has been established: **UNKNOWN**.

**New AA handlers were not active:** the original receiver capture anchors PID5810 creating the overlay service only for CAPTURE_ARM_ONCE. It records no added overlay, protocol-stack/transport start, volume receiver registration or media-handler event for that PID. Home had focus before and after cleanup; own helper/diagnostic processes were confirmed stopped and accessibility returned to the original empty/0 baseline. New pad registration, media forwarding and volume HUD logic therefore have no observed execution in this attempt. This weakens direct interception by those handlers; it does not clear APK installation or startup transitions of every possible indirect effect.

**Correct logical keys reach the input path:** the ten-entry recent queue ends with Back4, Home3 and Guide172 UP events, with scans158,172 and362. These match the archived Generic.kl and Diagnostics predicate. That is evidence against a wholly dead/misidentified button path. It is not a complete DOWN/UP timeline. Three reader keyboard states show zero keys held at the later snapshot; dispatch is enabled, not frozen, with no pending event and Home focused.

**Concrete OEM-state hypothesis:** the archived detector requires exactly three bits in a global WindowManager mPressedKeys set, not merely inclusion of the desired three. A stale additional bit or cancellation of the delayed detector could prevent launch despite a correct sustained gesture. The reader's zero-held-key snapshot does not reveal that private policy bitset. This is a specific mechanism to instrument, not a proven root cause. Do not claim a stuck bit exists from these dumps alone.

**Diagnostics itself works and exits normally:** explicit normal dealer action/component launch succeeded at16:32. The subsequent normal return logged finish()/stopLockTaskMode at16:32:46.989 and Diagnostics mode returning to0 at16:32:48.289. Package state is installed, not hidden, enabled by default, with the dealer action registered. This weakens a disabled package or continuing Diagnostics lock-task explanation. There is no matching late shortcut-detected or launch-error marker in retained logs. Earlier main-buffer messages have rolled out, so absence of markers does not negate the earlier system-log launches.

**First observed divergence:** the manual physical gesture does not produce the successful dealer-menu transition, while an explicit normal launch does. Evidence points to the OEM shortcut-recognition/state/dispatch portion before that transition. The exact first failing instruction/state cannot yet be identified. A new AA input remap is not an evidence-supported repair for this failure.

## 6. Primary evidence for each finding

- Operator statement: operator-clarification.json, recording repeated sufficient holds and first occurrence.
- Prior/new preparation: preparation-comparison.json, preparation-command-differences.json, old/new-preparation-mutations.txt and deployed-shell-comparison.json, derived only through each untimed READY timestamp. Original runs: helper_20261031T173855_e72a6103b88a4bdc815a3e210f2c4f69 and helper_20261031T202520_d9d4842542f44317878ae4818a4d27e7.
- Current-handler inactivity: verification.json/current-helper-log.txt; original current run `longdrive-evidence/rdx_0879164340ac4eba9ff42d8ae7fb8cb3/capture.log:205–207`. The later broad buffer's zero counts alone are not used to prove startup absence.
- Input/focus: current run `menu-access-logs-20261031-203454/input.txt:56,76,150,173–195,213–214`, windows.txt:110; recent-key-events.json. Package registration/default-enabled state: diagnostics-package.txt:4–7,52. Accessibility values and helper absence: menu-access-collection.json plus its corresponding files.
- Predicate/timer: archived-policy-dexdump.txt and extracted isDiagnosticComboKeyPressed.dex.txt, checkComboKeyPressed.dex.txt, detectLongPressComboKey.dex.txt; combo-verification.json and policy-provenance.json. Archived PhoneWindowManager source:2098–2169,5990–6060. Live policy jar hash was not collected, so exact runtime binary parity is unproved.
- Earlier OEM launches: broad logcat-main-system.txt:939 and1022. Normal post-ADB exit: that file:27625–27626,27860–27864; lifecycle-log-matches.txt retains those original line numbers. Explicit launch/result: diagnostics-open-result.json and open-diagnostics-20261031-203222 evidence.

## 7. Assumptions

The operator's failed gesture corresponds to this session and reported normal procedure. Archived RDX policy is a useful contract reference, not a live-hash attestation. Saved command-journal comparison covers the successful preparation intervals and normalizes identifiers/owned PIDs/APK selection explicitly; it does not hide APK-content differences. No assumption that the user pressed too briefly, that a ghost key exists, or that all installation side effects are captured.

## 8. Unresolved uncertainties and ranked investigation targets

1. **OEM combo state/timer or upstream delivery changes:** first instrumentation target, consistent with a valid sustained gesture failing after preparation and after helper cleanup. Exact state/cause UNKNOWN. Complete passive key timing, including other input devices, is missing.
2. **Indirect installation/startup/accessibility transition effect:** possible, not excluded by handler inactivity. No persistent setting difference has been identified; compare transient state under controlled conditions rather than inventing an APK fix.
3. **Our active AA window or new per-app media/pad handlers:** weakened substantially by the execution/focus/cleanup evidence. An old effect on OEM state is a separate question.
4. **Diagnostics package disabled or still pinning Home:** weak given successful normal launch, default-enabled package and logged normal mode0/lock-task exit.

No fault is attributed to hold duration from the repeat count36. InputReader DownTime is not a full three-key timeline; [AOSP InputReader](https://android.googlesource.com/platform/frameworks/native/%2B/d00f1007ef440975dccd3f7a3f6354a2fb7b3087/services/inputflinger/InputReader.cpp) was consulted only for context, with vendor/revision differences unresolved.

The smallest next evidence step is one bounded passive trace with the helper stopped, measuring all physical DOWN/UP events and concurrent OEM dispatch. NEXT-CAPTURE.md specifies that comparison. No new APK is needed. A separately controlled ordinary full head-unit restart can test transient state, but is not claimed a fix or executed here. Normal ADB dealer entry remains the already proven fallback for reaching the menu; it does not repair the shortcut or authorize arming inside Diagnostics.

## 9. Exact diff summary

Investigation scripts/derived evidence/report only. No production method, manifest, native library, key layout, permission, OEM package setting, guard, installed artifact or Git branch changed during this offline work. The collection-only fix made earlier uses a whitelisted exit-marker reader for buffered logs, recovering the already saved dump instead of treating historical error text as a failed command; shared readiness parsing was not changed.

## 10. Preservation checks performed

All28 app-source inputs and candidate APK match recorded hashes. Seven original evidence files and the archived policy jar match before/after hashes; original captures/reports are retained. Archived DEX was copied for read-only analysis, not installed or rebuilt. No ADB/car/phone/USB action, log-buffer clear, credential inspection, frozen rebuild, guard bypass, milestone advancement, package reset or Git publication occurred. All current AA candidate feature outcomes remain untested, and Git work remains paused.
