# Diagnostic-access evidence collection
1. Files inspected: current session/cleanup metadata and newly saved buffered logs, input, window/policy, activities and package state.
2. Files changed: new saved collector, separate private evidence/hashes, menu-access-collection.json and this report. Earlier run evidence retained.
3. Commands run: Collect-DiagnosticAccessLogs.ps1; explicit-target read-only dumps; own-helper cleanup only if unexpectedly active.
4. Tests/results: logs saved; helper/owned diagnostics absent; accessibility matched original. No AA behavior test or rearm.
5. Findings: manual Diagnostics entry regression is reported; cause UNKNOWN. Evidence retrieved, device no longer needed for offline analysis.
6. Primary evidence: logcat-main-system.txt, logcat-events.txt, input.txt, windows.txt, window-policy.txt, activities.txt, diagnostics-package.txt, commands.jsonl and evidence-hashes.json.
7. Assumptions: user request authorizes evidence retrieval and previously specified own-helper cleanup on the connected head unit.
8. Uncertainties: which change or OEM input state prevents manual menu entry is not yet established. ADB activity launch success is not manual-shortcut success.
9. Exact diff summary: local evidence/script/report additions; no app source/build/setting changes, no forced OEM package action.
10. Preservation: earlier captures/reports retained; no log-buffer clear, credential inspection, frozen rebuild, guard bypass, milestone/Git/network update.
