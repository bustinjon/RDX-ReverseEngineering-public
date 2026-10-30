# Evening exploration plan — 2026-10-27 (about 5 hours of car time, user present)

Status: DRAFT, offline. Nothing here has run on the car. Each numbered stage needs the user to say its phrase at the car.
The 3 PM M5 retry comes first and is unchanged (`INCAR-CHECKLIST-M5-RETRY.md`). M5 must be uninstalled and its evidence
saved before this evening starts.

## Why these tests

Full-screen Android Auto through our own receiver needs four things, apart from the phone protocol:

| Question | What we know now | Tonight's test |
|---|---|---|
| Can our app get USB permission for the phone? | UNKNOWN | 3 PM M5 retry (not tonight) |
| Can our app's window cover the full 1920x720? | Our app measured **1339x720** (live test 02). Honda's window policy reserves a 581 px "B zone" (`mBzoneAreaWidth`, framework resource, PhoneWindowManager:1252). Historically `wm overscan 0,0,-581,0` gave native apps 1920x720 (NOTES.md:69, user-run, visual only). Never measured with our app. | Stage 3 + 4 (grid app, with and without the overscan setting) |
| Can the car decode the phone's video at full size? | codec XML declares TI Ducati AVC up to 1920x1088, exactly at its block-rate limit for 1080p60. Never run. | Stage 5 (decoder app, six clips, small to large) |
| Do touch/knob/buttons reach an app, and where? | Not observed. Honda registers a 1325x720 touchpad; real device list unknown. | Stage 2 (read-only touch capture while you touch) |
| Sound/mic routing for a non-Honda app | Not observed. | Stage 1 (read-only survey) |

## Facts checked offline today

- The overscan setting is currently all zeros. `DisplayInfo.toString` prints ", overscan (" only when it is non-zero
  (Framework DisplayInfo.java:266), and no recent `dumpsys display`/`window` capture contains it. Current app area 1339x720
  comes from the B-zone width, not from overscan.
- `wm overscan reset` sets all four values to 0. `DisplaySettings.setOverscanLocked` then deletes the saved entry
  (DisplaySettings.java:85) and rewrites `/data/system/display_settings.xml`. This restores the **behaviour** exactly. It
  does **not** restore the file byte for byte: if the file didn't exist before, an empty `<display-settings/>` file now
  exists. That has the same effect (no entries = zero overscan). (Corrected after CODEX-EVENING-ATTACK F3.)
- The screen changes in memory first and the file is written second (WindowManagerService.java:6077). If the file write
  fails, WindowManager logs "Failed to write display settings" and keeps the old file, so the next boot could bring the
  wide setting back. The runner checks the log for that line after every reset. If it finds it, the state is
  RUNTIME_ONLY and everything else is blocked until a reset writes the file cleanly.
- `wm overscan` needs WRITE_SECURE_SETTINGS; adb shell has it (it was used historically). It is persistent (it survives a
  reboot) until reset. Uninstalling an app does not undo it.
- With `0,0,-581,0` the app area becomes 1920 wide, but Android's "system" area becomes **2501** px wide
  (PhoneWindowManager:3114/3118, Codex F6). Anything laid out against it (status bar, Honda's top bar) could misplace or
  draw off-screen. So the first thing after APPLY is to look at Honda Home. If anything looks wrong, RESTORE at once.
  RESTORE checks all 11 window-policy rectangles against the baseline, not just two.
- Grid APK `24843A11…7214` and decoder APK `ADD395FC…A374` are on disk and match their recorded hashes. Both passed static
  audits on 10-23: no permissions, no USB, no settings changes, no native code.
- Every install of our APK is logged by Honda's `com.honda.maliciousdetector`. The startup pop-up "Non authorized by Honda
  application(s) detected" has appeared before and can come back after each boot (history latch). Dismissing it is the known
  handling. We do not touch the detector.

## Stages (in order; stop rules in bold)

0. **Setup (you):** laptop in the USB port, exit Diagnostics with the on-screen RETURN steps to Honda Home, as before.
   No phone in the car port all evening unless stage 7 applies.
1. **Survey, looking only (~5 min, automated). Phrase: "Survey authorized".**
   `scripts/Capture-RdxEveningSurvey.ps1 -Serial 00000000 -Mode Survey -OutputDirectory <new dir>`. 36 fixed read commands
   (input devices, audio routing, codec lists, display/window, USB, Honda AA state, logs). An allowlist inside the script
   refuses anything else.
2. **Touch and control map, looking only (~15 min, you help). Phrase: "Input capture authorized".**
   `-Mode Input -InputSeconds 60`, run once per action group: (a) tap the four corners, then the center, slowly;
   (b) swipe across the full width, including over the right-side panel; (c) the touchpad, if present; (d) turn and press
   the knob and the steering-wheel buttons. It records which device sends what and the coordinate ranges.
   A capture can leave the read-only `getevent` on the car until its next event; the script reports it and never kills it.
3. **Grid app, normal screen (~15 min). Phrase: "Grid test authorized".** Install grid APK → start it → photo
   (`screencap`) + window/log capture → you press EXIT on screen → keep installed for stage 4.
   Expect 1339x720. **Unknown error, lock-task refusal or a different package present → stop.**
4. **Full-width screen setting (~20 min). Phrase: "Overscan authorized".**
   Record baseline (display/window dumps; must show no ", overscan (") → `wm overscan 0,0,-581,0` → start grid again →
   photo + capture (expect 1920x720 surface, B zone hidden) → you look at the screen and tap near the right edge →
   EXIT → `wm overscan reset` → capture → must match the baseline (no ", overscan (", mOverscanScreen 1339x720).
   **If the restore doesn't match: no other stages; we fix the restore first, with you there.**
   Then uninstall grid and check it's gone.
5. **Decoder app (~60-90 min, you tap). Phrase: "Decoder test authorized".** Install decoder APK → start → you pick one
   clip and press START TEST, in order 1→6 (1280x720/30 ... 1920x1080/60). After each, I read the result before you press the
   next one. **First failure → stop that sequence, record it, don't retry with other settings.**
   5b (optional, separate phrase "Decoder full-width authorized"): repeat clips 3 and 6 with the full-width setting on, then
   reset and verify as in stage 4. This shows whether our own app can decode and draw video with the full-width window available. It is
   not a full 1920x720 picture, and the video may not reach the full width either: the decoder app's buttons and status take part of the height, and the video is fitted
   into what remains, keeping its shape (DecoderTestActivity:15-28, Codex F7/recheck). The real full-screen picture test
   needs our receiver, not this test app. Read sizes from `Surface=` lines and the screenshots. The
   grid app's `physical=` label uses the vendor-broken getRealMetrics (LIVE-TEST-02 line 47); don't trust it.
   Uninstall decoder and check it's gone.
6. **Postcheck (~5 min, automated):** our packages absent, Honda AA APK hash/signer unchanged, display baseline, overscan
   reset, same boot.
7. **Phone:** none tonight unless the 3 PM M5 retry PASSes. Even then, the next phone step is M6 and needs its own
   separate authorization after a review of the M5 result. A great result in stages 3-5 doesn't unlock a phone test by
   itself: no other phone test is built.

## What a "great" evening looks like

Stage 4 shows our app drawing all 1920x720, and stage 5 decodes 1920x720 or 1920x1080 smoothly. With a 3 PM M5 PASS, every
non-protocol piece of full-screen AA through our own receiver would then be shown on this car. What's left would be the
phone protocol (M6/M7).

## Built (offline, 2026-10-27 morning)

- `tools/evening/Invoke-RdxEveningStage.ps1` v2, `tools/evening/Test-RdxEveningRehearsal.ps1` (fake car, 19 scenarios),
  `scripts/Capture-RdxEveningSurvey.ps1`, `INCAR-CHECKLIST-EVENING-20261027.md`.
- Codex attack `CODEX-EVENING-ATTACK.md` (NOT READY: 4 blocking, 5 should-fix) → all fixed in v2 → Codex recheck pending.
- Known limits: Honda private data (e.g. the AA auto-start preference that Honda writes when any app resumes) is not
  compared. Whether every OEM `dumpsys` handler is side-effect free is UNKNOWN.
