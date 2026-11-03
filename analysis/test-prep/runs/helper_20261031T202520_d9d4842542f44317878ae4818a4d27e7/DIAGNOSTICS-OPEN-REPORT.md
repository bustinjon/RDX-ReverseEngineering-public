# Normal Diagnostics launch — 2026-10-31 20:32 UTC

1. **Files inspected:** archived HondaDiagnostics manifest and dealer entry activity; policy's normal DIAGNOSTICS_INTENT; prior menu-access review; latest run cleanup metadata and current helper state.
2. **Files changed:** new saved Open-Diagnostics.ps1, activity-launch command journal, before/after state and result metadata, this report. No source/APK/settings change.
3. **Commands run:** `pwsh -File analysis/test-prep/media-input-fixes-20261031/Open-Diagnostics.ps1`; explicit-serial identity/service reads, normal exported dealer-menu `am start -W`, then activity-state read. No permission bypass or protected internal component was used.
4. **Tests/results:** target identity matched; helper inactive; launch succeeded; dealer.MainActivity confirmed resumed. No AA behavior test or rearm performed.
5. **Findings:** Diagnostics is open. The helper remains stopped, so the phone test is not armed. The normal Diagnostics entry may enter OEM lock-task; this is menu behavior, not readiness for an AA permission test.
6. **Primary evidence:** diagnostics-open-result.json; open-diagnostics-20261031-203222/launch.txt, activities-after-launch.txt, helper-before-launch.txt and commands.jsonl. Archived manifest has dealer.MAIN/default filter; PhoneWindowManager.java:129 defines that same action.
7. **Assumptions:** user's explicit “Try to open via adb” authorizes opening the ordinary dealer menu on the reconnected head unit.
8. **Uncertainties:** original three-button failure remains unexplained. USB-mode selection and subsequent AA test are not completed by this action. Do not arm inside Diagnostics or assume lock-task permits AA prompts.
9. **Exact diff summary:** one action-specific script and local evidence/report additions; ordinary UI launch only. No setting toggle, helper restart, new build or Git activity.
10. **Preservation:** current installed APK left intact; no credential inspection, frozen rebuild, guard change/bypass, milestone advance, OEM package force-stop or Git publication.
