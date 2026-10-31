# Home / installation / USB-menu automation feasibility

Normal Home navigation and the existing installation/capture preparation can be joined into a saved-script workflow. Automatically returning to the USB-mode screen requires one live qualification of the normal UI route. **Do not assume direct activity launch works**: the archived Diagnostics manifest declares USBModeSwitchActivity without exported=true or an intent filter. Current live component accessibility/UI hierarchy remains UNKNOWN. No device command was run for this review.

## 1. Files inspected

- PROJECT-RULES.md and existing live-preparation structure.
- `decompiled/HondaDiagnostics/sources/com/honda/auto/diagnostics/developer/USBModeSwitchActivity.java:15–67`.
- `decompiled/HondaDiagnostics/resources/AndroidManifest.xml:160`.
- `decompiled/HondaDiagnostics/sources/com/honda/auto/diagnostics/BaseContentsActivity.java:60–61`.
- `scripts/Analyze-RdxLive02.ps1:47` (prior observed ordinary RETURN path), the existing M5 retry checklist and lock-task reconstruction. Source paths/search output saved in source-index.json and navigation-evidence.txt.

## 2. Files changed

Only new offline review directory: Inspect-Navigation.ps1, search/index outputs, a source working copy and this report. No navigation/guard/production script, source, APK or original evidence changed.

## 3. Commands run

Targeted Get-Content/rg reads; saved `pwsh -File analysis/agent-reviews/usb-menu-automation-20261031/Inspect-Navigation.ps1`. An initial broad search returned excessive output; subsequent multi-step searching was saved to this script and detailed results to local files. No completed car test/collection/build repeated. No ADB/USB action.

## 4. Tests run and results

Offline source inspection only. Found one archived USB-mode source and its manifest. No UI automation, activity launch, automatic Home transition or runtime permissions test performed. Previous installation/capture script success is already preserved in the test-run preparation evidence and was not rerun.

## 5. Findings

1. The existing preparation handles installation, artifact verification, temporary permission auto-clicker, logger/watchdog and capture arms. A wrapper need not duplicate that work or add repeated Home checking.
2. Ordinary Diagnostics RETURN invokes finish(); a prior captured session exited USB Mode -> Developer Diagnostics -> Detail Information/Setting -> Dealer Diagnostics -> Home with ordinary RETURN taps. Automating these same controls is different from force-stopping Diagnostics or overriding lock-task. Existing mandatory readiness guard remains intact.
3. In archived USBModeSwitchActivity, onCreate installs the UI and onStart only reads dev.adb and sets the button label. The mode-changing SystemProperties.set("dev.adb",...) is inside the list-item selection callback. Thus opening that archived screen is distinct from selecting a mode. Current runtime parity and superclass behavior still require qualification.
4. The archived labels are Apple CarPlay (position0/phone mode) and ADB (position1). Refer to the actual car label during handoff instead of assuming a literal Android Auto menu entry.
5. The USB activity is not explicitly exported and has no intent filter in the archived manifest. A simple external `am start -n ...USBModeSwitchActivity` is not established as an allowed route. Do not add permissions, change Diagnostics, use an OEM service bypass or guess screen coordinates. Qualify the normal menu route/UI controls once when connected.
6. Final handoff can be: ADB connected -> ordinary RETURN to Home -> existing prepared install/arm -> normal UI route back to USB Mode -> READY cue. Selecting phone mode breaks ADB, so the operator still selects the mode and returns normally to Honda Home before plugging in the phone. That final Home return is important because permission dialogs previously failed in Diagnostics lock-task. A second device-side queued automation across the disconnect is outside this proposed wrapper.

## 6. Primary evidence for each finding

- Finding1: existing `analysis/test-prep/pad-absolute-off-20261031/Prepare-LiveTest.ps1` and its completed run PREPARATION-REPORT.md/session.json/final-ready.json.
- Finding2: BaseContentsActivity.java:60–61; Analyze-RdxLive02.ps1:47; checklist normal four-RETURN path in navigation-evidence.txt. These are historical evidence, not proof of today's UI layout.
- Findings3/4: USBModeSwitchActivity.java:20 (labels), :33–56 (listeners/write), :60–66 (onStart read). Saved working copy is developer-USBModeSwitchActivity.txt.
- Finding5: archived manifest:160, activity with no attributes beyond name, no child filter; current shell/root/export behavior UNKNOWN.
- Finding6: existing preparation guard and archived menu behavior above; canonical `analysis/parallel-aa-receiver/M5-LOCKTASK-LIVE-FAILURE-RECONSTRUCTION.md` documents Diagnostics lock-task rejecting the standard permission activity.

## 7. Assumptions

The user wants normal UI automation around the already authorized test procedure, not removal of readiness checks or automatic USB mode switching. A future connection is needed to qualify the actual UI route. No assumption that the head unit is currently connected.

## 8. Unresolved uncertainties

Current Diagnostics APK parity, current UI resource identifiers/navigation route, allowed shell activity entry, ability to reopen the menu without its physical diagnostic entry sequence, and latency/timer budget remain UNKNOWN. Full Home->install->menu automation is not yet implemented or tested. No further car test candidate is selected by this review.

## 9. Exact diff summary

New offline inspection/report artifacts only. No preparation/guard change, no UI action script installed, no bypass/force-stop of an OEM app, no extra Home verification loop and no program build.

## 10. Preservation checks performed

Original source/evidence read only. No production, original media/log, APK or frozen artifact writes. No key material, Git mutation, ADB, phone/car/USB action or milestone advancement. Existing artifact preservation evidence retained without unnecessary rehash/recollection for this feasibility question.
