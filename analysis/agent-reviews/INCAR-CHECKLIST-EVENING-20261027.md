# In-car checklist — evening exploration 2026-10-27 (v3, after CODEX-EVENING-ATTACK and CODEX-EVENING-RECHECK fixes)

Plan and reasons: `EVENING-EXPLORATION-PLAN-20261027.md`. Each stage runs only after the user says its phrase at the car.
No phone in the car's USB port all evening (see the plan, stage 7). Run from the repo root in pwsh 7.

[Code block omitted from public report; see authored source where available.]

## 0. Setup (user)
Laptop in the USB port. Exit Diagnostics with the on-screen RETURN steps to Honda Home. M5 from 3 PM must already be
uninstalled (its POSTCHECK done).

## 1. Survey — phrase "Survey authorized"
[Code block omitted from public report; see authored source where available.]
Expected: summary JSON with `nonZeroExit` possibly listing files that don't exist on this car (e.g. media_codecs_performance);
that is a finding, not a failure.

## 2. Touch and controls — phrase "Input capture authorized"
One run per group; tell the user the group before starting. 60 s each.
[Code block omitted from public report; see authored source where available.]
a: tap the four corners then the center, slowly. b: swipe across the full width, over the right-side panel too.
c: touchpad (if present). d: turn/press the knob, steering-wheel buttons.
"getevent is still on the device" → report it, do nothing else. It only reads, and it ends by itself after at most 4000 more input events (or earlier if the closed connection stops it). It never injects or blocks input.

## 3. Baseline, then grid app on the normal screen — phrase "Grid test authorized"
[Code block omitted from public report; see authored source where available.]
Expected: `Surface=1339x720`. User looks at the screen, then presses the app's EXIT button.
`Launch refused` with a lock-task message → Diagnostics is still open: user goes back to Honda Home, run LAUNCH again.

## 4. Full-width screen setting — phrase "Overscan authorized"
[Code block omitted from public report; see authored source where available.]
Expected: APPLY "full width: ... 1920x720; system bounds (0,0)-(2501,720)". **Right after APPLY, the user looks at Honda Home and the top bar. Anything wrong, cut off or frozen → OVERSCAN_RESTORE immediately.** LAUNCH `Surface=1920x720`; RESTORE "restored: ... all 11 window-policy rectangles match".
"Screen restored NOW, but the saved file may still hold the change" (state RUNTIME_ONLY) → run OVERSCAN_RESTORE again until it says "restored". **OVERSCAN_APPLY or RESTORE fails → run OVERSCAN_RESTORE again (it can always be run). If it still fails: STOP all other
stages; we look at it together.** Don't reboot to "fix" it: the setting survives a reboot.

## 5. Decoder app — phrase "Decoder test authorized"
[Code block omitted from public report; see authored source where available.]
Per clip, in order 1→6: user selects the clip and presses START TEST, waits for the on-screen result, then:
[Code block omitted from public report; see authored source where available.]
Exit code 3 "no NEW complete clip result yet" just means the clip is still running: wait for the on-screen result and run CAPTURE again with a new label. I read the result before the next clip. **First failure, WATCHDOG or "STOP" text on screen → no more clips.**
5b, only with the phrase "Decoder full-width authorized": user presses EXIT; OVERSCAN_APPLY; LAUNCH decoder `-Label wide`;
clips 3 and 6 with CAPTURE; EXIT; OVERSCAN_RESTORE. Then:
[Code block omitted from public report; see authored source where available.]

## 6. Postcheck (always, before leaving the car)
[Code block omitted from public report; see authored source where available.]
FINISHED → done. POSTCHECK_MISMATCH → read `checks` in the output: overscan → OVERSCAN_RESTORE; a package → UNINSTALL;
Honda AA hash or fingerprint changed → STOP, preserve everything, review.

## Warnings and recovery
- Exit code 3 = WARNING (the stage did its job but something needs a look, e.g. no new Surface line yet). Read the line; usually just CAPTURE again after a few seconds.
- LAUNCH "already on screen" → press the app's EXIT button first. An app process that stays alive after EXIT is normal and is not blocked.
- "session.json unreadable" → only OVERSCAN_RESTORE, UNINSTALL (with its -Authorization) and POSTCHECK run; they compare against the 10-26 stock reference. Run RESTORE, then UNINSTALL for any installed app, then POSTCHECK.
- Never reboot to fix anything: the overscan setting survives a reboot.

## Known and expected
- Honda's "Non authorized by Honda application(s) detected" pop-up may appear at later startups. Dismiss it. We don't
  touch the detector.
- A rerun of a stage writes a new timestamped folder; nothing is overwritten.
