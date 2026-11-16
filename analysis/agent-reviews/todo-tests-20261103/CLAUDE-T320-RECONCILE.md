# T320 reconciliation (Claude, 2026-11-11)

Final build: T320-bundle 23B094B0D8CF1BDF149A71F6CDA345113A453EC0EB654A643CF0CDD9C603DF40, PASS 264.

Source: Fable review fixes 1, 3, 4, 5 and 7 (analysis/agent-reviews/fable-review-20261111/REPORT.md).

CODEX-T320.md fixes:
- **BLOCKER:** the UNDO verify command ended with `exit 0`, so Invoke-Hook's `echo RDX_HOOK_RC:$?` never ran and a successful verify threw. Fixed: it ends with `true` and fails with `exit 1` (the existing hook pattern).
- **Delete vs saved originals:** UNDO first sends BootBlockerReceiver RESTORE_WIFI (new, DUMP-protected). That runs the app's own restoreAfterBoot (exact saved scan values, paused networks, channels) while the grant still exists. Then a laptop fallback deletes only keys still at 300000, then the verify, then `pm revoke`.
- **Bluetooth service on wired sessions:** registered only while everyday wireless is on. UNKNOWN until the car test (pairing prompts, HFP). VISIT step 2.2 checks one USB plug-in.
- **Group watcher:**
  - A lookup exception no longer counts as lost.
  - groupMissing resets on each new group and on shutdown.
  - A genuine loss ending the Wi-Fi session is accepted.

OK per Codex:
- No code depends on the old status text.
- DUMP keeps same-uid starts, PendingIntents and adb working.

Loop stopped.
