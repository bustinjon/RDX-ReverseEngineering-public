# T180 reconciliation (Claude, 2026-11-08)

Final build: T180-bundle 1956F47B766FD04FA0C43EB73596D63622E19431775BD7A0D07BC0F9E86F6EF2, PASS 219 bundle checks plus feature suites.

- Research CODEX-WIRELESS2.md:
  - No missing "wireless" flag was found in the wired announcement.
  - The wired credentials carry no IP or port.
  - My earlier claim that the station Wi-Fi retries disturbed the group was WRONG: the retries ended at 13:36:56 and the group started at 13:39:46. Corrected to the user.
  - T180 adds Codex's top two variants: Quiet Wi-Fi and Quiet + 5 GHz. The checklist now has the listener ready before the phone's Bluetooth reconnects (rank 2).
- Start auto-stop (operator request): New-TestPackage regenerates Prepare-*.ps1 from the protected launcher templates, so the edits were moved:
  - a generic automatic `preStartAdb` hook in tools/Run-Test.ps1, which the T180 test.json uses for PERSISTENT_OFF + force-stop
  - the template's UNTRACKED check still runs afterwards
- Collect tags: added via test.json logTags (RDX.P4, SET_BTH_BluetoothHFPProfile); confirmed in the generated Prepare-Test.ps1. The wireless TAG is now RDX.WIRELESS.
- Recheck CODEX-T180-RECHECK.md:
  - F1-F3 FIXED.
  - The F6 flag ordering was fixed after the recheck: saved before the request, with failures cleared.
  - Accepted, not knowable offline: exact network-state restoration (F4/F5). The checklist tells the operator how to re-select a network.
  - A partial hook failure leaves Hackura as after a normal UNDO (harmless).
  - The pre-existing Run-Test failure.txt ordering is unchanged.
- Loop stopped here.
- Pending: the T170 saved logs (Secure / Insecure / Nudge results) are still on the head unit; VISIT step 1 pulls them first.

## Music not resuming after Gemini (operator report on T170, 2026-11-08)
- Cause (T160 drive log, helper_20261108T174704, 12:53:39-45):
  - The talk takeover's focus loss was forwarded to the phone as state 5.
  - Honda VR briefly retook focus, so the media sink got no GAIN on release.
  - The later +1 was taken as the end of an internal guidance duck and not forwarded, so the phone stayed paused.
  - Codex confirmed the diagnosis, and that voice session status 2 means ended.
- Fix: forwardMediaFocus tracks phoneMediaLost. An internal restore while the phone still has a loss creates an owed restore. It's paid at voice-session end or after 12 s, but only when there's no assistant, no guidance, and the media sink holds focus. It retries every 2 s; any newer forwarded message clears it.
- Review CODEX-T180-AUDIO.md found 2 blockers + 2 should-fix; all FIXED per CODEX-T180-AUDIO-RECHECK.md. READY FOR CAR TEST.
- Accepted minor: the 120-s give-up applies only while blocked.
- Final build: T180-bundle 3A5D8D6661559444C2E00D9632C06FA6C07B1B16E86A940257A3B89DE77E3350, PASS 222 bundle checks.
