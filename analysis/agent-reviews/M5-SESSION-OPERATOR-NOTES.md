# M5 retry — operator notes (for me, during the live session)

Technical companion to `INCAR-CHECKLIST-M5-RETRY.md` (the plain-language version the user sees). This file
exists so I don't have to reconstruct commands or re-derive Codex's findings under time pressure. Not a new
procedure — same steps, same guard, same no-bypass rule. Read this immediately before the session starts.

## Command templates (fill in `$session` once, reuse for every stage)

[Code block omitted from public report; see authored source where available.]

If INSTALL throws before producing a phase: re-run `Test-M5FrozenPreflight.ps1` once to confirm the car/APK
identity didn't change, then decide with the user rather than retrying blindly (F1 below).

## Five things from the Codex reviews that are easy to get wrong live

**F1 — stuck phases have no auto-recovery.** `INSTALL_REVIEW_REQUIRED` (after INSTALL) and `ARM_ATTEMPTED`
(after a failed ARM) are both dead ends in the runner: neither accepts another ARM or UNINSTALL cleanly.
If either appears: **stop, don't improvise a fix, don't hand-edit `session.json`**, tell the user the app
state is UNKNOWN, and decide the next step together rather than reinstalling or re-arming over it.

**F3 — the ARM confirmation read can race the actual event.** The runner reads logcat once right after
sending the arm command to confirm `event=ARMED`. The prior live run showed the service call returning
*before* the ARMED journal entry actually appeared (both within ~0.3 s, but in that order). If the ARM
step reports a problem at the confirmation check specifically (not at the readiness gate, not at identity
checks) — **re-read logcat once more before concluding ARM failed**; don't immediately tell the user to
abandon the attempt. Do not re-issue a second ARM command; only re-check the existing log.

**F4 — the cleanup check is weaker than the checklist's wording implies.** After UNINSTALL, run the read-only
absence checks the checklist promises, don't just trust the runner's own built-in check: `pm path
com.rdx.fullscreen.m5permission` should return nothing, and the process should not appear in a process list.
POSTCHECK's factory-AA hash/signer check is the one that matters for "car is back to normal" — read its
actual output, not just its exit code.

**F5 — VERIFY can print a PASS then downgrade it.** `Get-M5JournalVerdict.ps1`'s console output can show an
initial PASS line, then the runner's own UI-correlation step can override it to INCONCLUSIVE if an unrelated
stale UI rejection matches loosely. **Always open and read the saved `m5-verdict.json` file itself** as the
real result — never report the first line printed to console as the verdict.

**F6 — the verdict script alone proves nothing.** `Get-M5JournalVerdict.ps1` will say PASS for any
sufficiently-shaped text, including hand-edited or spliced text; it is not a provenance check on its own.
Only ever run it against the actual journal that RETRIEVE pulled from *this session's* real device, never
against a reconstructed, copied, or edited file, even for a quick sanity check.

## Reading the result, precisely
PASS requires: exactly one request, an accepted device-validated callback, a verified `hasPermission=true`
afterward, all from the real retrieved journal. A visible dialog + a tap is not itself a PASS — the callback
and post-check are what matter. Everything else (no dialog, lock-task again, re-enumeration, a cancel) is
INCONCLUSIVE; there's no automatic FAIL branch in this tooling at all — FAIL would need deliberate human
review of a clearly demonstrated restriction, not an automated label.

## If I need to resume mid-session after an interruption
Check `$session\session.json` for `.phase` before doing anything. Don't repeat a stage that already
succeeded; don't guess — read the file.
