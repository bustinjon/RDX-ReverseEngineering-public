# In-car checklist — M5 retry (v3, 2026-10-26 night; for 2026-10-27 ~3 PM)

## What changed in v3 (read this first)
- **No 400 ms pause** in the safety check any more (commit 5356aa1). The gap problem that refused all three ARMs on 10-26 should be gone. The one remaining tight spot is the very last freshness check right before arming.
- **A late freshness refusal no longer strands the test app.** Before, a refusal at the last two checks marked the session "arm attempted" with nothing sent, and no cleanup stage would accept it. Now the runner records it, returns to "installed", and a new ARM re-runs the full safety check. Nothing reaches the app in that case.
- **The failures we know about now have a cleanup path**, rehearsed offline against a fake car replaying real car output (`tools/m5/Test-M5SessionEndToEnd.ps1`, 15 scenarios): failed or lost-reply install, slow "armed" log line, slow results dump, an old dump already in the log, interrupted uninstall, interrupted postcheck, an app that never confirms. A new explicit **PRESERVE** stage saves and fingerprints the evidence when RETRIEVE cannot finish. It unlocks UNINSTALL only after **two failed RETRIEVEs at least 30 s apart** and **proof the app has stopped** (its own "finished" line, or no app process in a normal process list). Without that proof it saves the evidence and we stop for review; the app stays installed, which is harmless. The rehearsal cannot model everything the real car does (adb reconnect trouble, unknown error text), so "zero in-car edits" is the goal, not a guarantee.
- **Fixed a hidden 4-hour bug:** the runner read its own 5-minute deadline back about 4 hours late (time-zone mix-up). RETRIEVE only got through on 10-25 because the app's "finished" line was present.
- **Exact timing is now captured**: Claude saves every stage's console output and runs `tools/m5/Get-M5ArmTimingReport.ps1` right after ARM (gaps, sample lengths, the age at each last check, whether the arm command ran).
- VERIFY is now an explicit step; phone time after Allow is **60 seconds** (matches the runner).

## Claude's ARM rules at the car (no improvising)
- Up to **3 ARM tries** per session, and only when the previous try was refused **before anything was sent** (phase back to INSTALLED). Each try re-runs the full 5-second safety check.
- Same timing refusal on all 3 → **stop for the day**: that proves the check is still too slow on the real install, and the next fix is a faster last sample, offline. Never a looser limit, never a bypass.
- Any refusal for a *safety* reason (kiosk on, not Home, unknown output, file mismatch) → fix the cause (usually: not fully out of Diagnostics) or stop.
- ARM error **after** the arm command was sent → no second ARM; RETRIEVE, and only if it fails twice after the 5-minute deadline, PRESERVE; then UNINSTALL if PRESERVE unlocked it.

**Goal of this session:** find out ONE thing — with kiosk mode (lock-task) OFF, does Android's normal "Allow USB access?" dialog appear for our test app, can you tap **Allow**, and does Android record the grant? Nothing else is attempted. Whatever happens, we STOP after cleanup.

**Needs your explicit go-ahead in chat** ("M5 retry authorized"). Nothing live starts before that. M6 and M7 stay locked no matter what.

What changed from v1 (from four Codex reviews + my checks): the car must be **parked**; the handoff signal is the **"SWAP TO PHONE NOW" line**, not "READY"; **don't press Home or Back** while the dialog is up (either one dismisses it); Honda's own Android Auto screen may pop in front of the dialog; there is no on-screen signal that the test app finished, so the waiting rule is spelled out; and I'll film/photograph the screen because logs can't show what you actually saw.

## Exact commands (Claude runs these, only after "M5 retry authorized")
[Code block omitted from public report; see authored source where available.]
The tee runs in the parent process, so it adds nothing to the runner's own timing.

## Bring
- [ ] Laptop **charged and plugged in**, lid open, Claude session running.
- [ ] Phone: charged, unlocked, screen stays on, correct cable. Laptop ADB cable too. (One USB port: laptop and phone take turns.)
- [ ] **A second device to record the head-unit screen** (another phone or camera) and ideally something to prop it. Logs cannot show what was visible or what you tapped.
- [ ] Park, **handbrake on**, ignition ON/engine running. Honda blocks app launches while it thinks the car is moving.

## The session — who does what
| # | What happens | You do | I do |
|---|---|---|---|
| 1 | Setup (phone NOT connected) | Plug the laptop into the car USB port. Say "authorized". | Preflight, new session folder, car baseline, install the frozen test app (hash `A22E…8F40`). Nothing launched. If INSTALL errors or times out I treat the app as **possibly installed** and stop: no reinstall. |
| 2 | Leave kiosk mode | Press **RETURN** step by step to **Honda Home** (last time: USB Mode Switch → Developer Diagnostics → Detail Information & Setting → Dealer Diagnostics → Home). Don't toggle USB modes. Say "on Home". | Watch the safety check. |
| 3 | Safety gate | Hold still ~5–10 s. | Guard needs kiosk OFF + Honda Home for 5 continuous seconds. **NOT READY → we don't arm**; I explain. |
| 4 | **ARM** | Phone ready in hand, unlocked. Eyes on me. | I arm (one use, 5-minute window). **Wait for my message "SWAP TO PHONE NOW".** The earlier line "READY_TO_ARM" is not the signal. If ARM shows ANY error: keep the laptop connected, don't swap, don't re-arm; tell me. |
| 5 | **Swap — be quick** | On "SWAP TO PHONE NOW": **unplug laptop, plug phone into the same port.** Start recording the screen. Note the time you swapped. | Nothing possible during the phone interval (no ADB). |
| 6 | The dialog | If "Allow … M5 USB permission only …?" appears: tap **Allow once**. **Do NOT tick "Use by default".** **Do NOT press Home or Back** (both dismiss it). If Honda's Android Auto screen covers the dialog, don't press anything; keep filming and tell me later. If you can't see a pointer for the touchpad, try touching the touchpad where the button is; say what happened. | – |
| 7 | How long to stay on the phone | **If you tapped Allow:** wait ~60 seconds, then go to step 8. **If no dialog ever appeared:** keep the phone connected for the full **5 minutes** from the swap, then go to step 8. (The app shows no "I'm done" signal, and unplugging early ends a pending request.) | – |
| 8 | Back to laptop | Unplug phone, plug laptop in. Say "laptop back" and what you saw/did, with times. | RETRIEVE logs and the test app's record first (if it says "no complete dump yet", wait 30 s and re-run RETRIEVE only); then **VERIFY** and read the verdict **file**; then UNINSTALL (if it fails partway, re-run it); then extra read-only checks that the app and its files are gone (the runner's own check is package/process only); then POSTCHECK (if it fails partway, re-run it). If RETRIEVE fails twice, 30 s or more apart, after the 5-minute deadline, run **PRESERVE**; if it unlocks cleanup, UNINSTALL; if it says termination UNKNOWN, stop for review. |
| 9 | Stop | Nothing. | Plain-English result. No M6/M7 action. |

## If something goes wrong
| Situation | What we do |
|---|---|
| Guard says NOT READY | Don't arm. I explain; fix (usually: not fully out of Diagnostics) or abort. |
| INSTALL times out / says "review required" | App state UNKNOWN. No reinstall, no editing session files. I run PRESERVE, then UNINSTALL, then POSTCHECK. No ARM. |
| ARM refused with "ARM NOT ISSUED" | Nothing was sent. Stay on Home; I re-run ARM (max 3 tries total, see ARM rules). |
| ARM errors after the arm command was sent | Laptop stays connected. No swap, no second ARM. Tell me. I RETRIEVE; if that fails twice (30 s apart, after the 5-minute deadline) I run PRESERVE, which unlocks UNINSTALL only with proof the app stopped. |
| A cleanup stage fails halfway (UNINSTALL, POSTCHECK) | I re-run that same stage; partial evidence is kept aside, never deleted. A stage that already completed is not re-run. |
| Missed the swap | The test app times out by itself. Plug the laptop back; result INCONCLUSIVE. Don't re-arm this session. |
| Dialog appears but won't take a tap | Describe what you pressed. Don't keep tapping. |
| Dialog never appears | INCONCLUSIVE or informative; never "permission impossible" from this alone. |
| Honda warning screen about an unauthorized app | Stop touching things; tell me what it says. Clear nothing. |
| Laptop can't reach ADB after the phone interval | Don't re-arm, toggle USB modes, or reboot. Tell me; cleanup stays UNVERIFIED until we can read the car again. |
| Anything surprising | Stop, tell me. |

## Hard rules
- One arm, one phone interval, one request. No retries, no second test.
- Don't tick **Always / Use by default**.
- Don't press Home or Back while the dialog is up.
- Don't force-stop, clear data on, disable, or reboot anything Honda. Don't toggle USB modes.
- PASS or not: evidence → uninstall → postcheck → **STOP**. M6 needs your separate decision later.

## How we read the result
- **PASS:** exactly one request; you pressed Allow; the app recorded a granted callback; Android confirms permission afterward. (Tapping Allow alone is not a PASS.)
- **INCONCLUSIVE:** anything else short of a demonstrated restriction: kiosk again, phone dropped, dialog covered, no dialog, you cancelled. No automatic FAIL exists.
- **FAIL:** only if logs show the dialog worked normally and Android refused, reviewed by me and you.

## Known unknowns going in (honest)
Whether the dialog shows at all with kiosk off (never seen); whether the touchpad can press its buttons (the dialog lacks the pointer help Honda added to a similar one); whether Honda's own Android Auto screen covers it; whether a re-enumeration of the phone cancels everything (it did 20 s after the last attempt, when you swapped back); whether the full safety check is fast enough **with the test app installed** right up to the arm command. (The kiosk-state reading itself now works live: 3 refused ARMs on 10-26 plus 48 replies in the latency session, all read correctly. What is still unproven is the final freshness margin on the installed path.)

## Safety-check fixes: APPLIED (2026-10-26, your approval)
Three defects found and fixed, all tested before applying, all verified after:
- Two small guard defects from the morning review (a disabled test app counting as "fresh"; error text accepted as a valid system listing): 62 checks + 1000 generated cases pass. Details: `analysis/agent-reviews/proposed-guard-fixes/README.md`.
- Two install-success parsing bugs found live at the car (the install genuinely worked both times; the check was too strict about adb's exact wording): fixed in both places it appeared.
- The framework-file trust gap hit live at the car (car's real system files didn't match the single reviewed version): closed after Claude and Codex independently found the car's actual files are code-identical to the reviewed ones (differ only in file timestamps). The guard now accepts either version, and still refuses anything else. Details: `analysis/agent-reviews/CLAUDE-FRAMEWORK-PARITY-REVIEW.md`, `CODEX-FRAMEWORK-PARITY-ADVERSARIAL-REVIEW.md`.

Integrity passes all 567 files; frozen artifacts unchanged. (Historical v2 note, superseded: the getter has since run live on 10-26; what remains unproven is the final freshness margin with the app installed.)

Sources: Codex reviews `CODEX-M5-GUARD-ATTACK.md`, `CODEX-M5-PERMISSION-PATH.md`, `CODEX-M5-INCAR-PROCEDURE-REVIEW.md`, `CODEX-M5-PROJECTIONACTIVITY-REVIEW.md`, `CODEX-FRAMEWORK-PARITY-ADVERSARIAL-REVIEW.md`; exact runner commands in `analysis/parallel-aa-receiver/NEXT-CAR-SESSION-CHECKLIST.md` and the walkthrough table in the procedure review.
