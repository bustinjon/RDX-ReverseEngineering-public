# T60 visit notes (user report during the visit, 2026-11-06 UTC / 2026-11-05 local evening)

Start: the first attempt was NOT READY. The cause was the accessibility label check (`label=RDX USB`): the service inherited the label "Hackura". I fixed it by setting `android:label="RDX USB"` on PermissionClickService and rebuilding (7039AA7E…). The second Start reached READY.

## Results
- **Volume size:** Medium is preferred. Make Medium the default.
- **Hackura tile:** tapping it works (returns to AA). The label on Honda Home still reads "RDX USB". The tile is probably labelled by HelperActivity, though the service label fix may be what Honda shows: check this.
- **Icon:** too bright next to Honda's tiles. Dim it to match.
- **Return to AA:** the Hackura icon is now the way back to AA. The side-panel button is not needed for that.
- **Absolute touchpad:** works perfectly. The alignment was the default, top. Centred was not needed.
- **Honda audio source:** the source is listed (shown as "Android Auto"). Selecting it shows a blank screen, but the **steering wheel controls now work**. Make it the default, and investigate pushing track info to the dash (metadata through the media session).
- **Self-recovery:** the user sees no value, because a dropped session always reopens to the same screen anyway.
- **Layout probe:** 320 and 400 both failed. Too large; 400 is much larger than 320 (looks like a low-resolution computer), both look bad. Drop the probe values; full-screen apps need another route. A screenshot was requested, but ADB is down during the AA session.
- **P2 Wi-Fi Direct:** ran at 21:28 local.

## New requests (make no changes until the visit ends)
1. Make Medium the default volume size.
2. Show "Hackura" as the Home tile title, not "RDX USB".
3. Dim the icon to match the other Home tiles. Take a Home screenshot for reference.
4. Work around the USB permission popups rather than auto-clicking them.
5. New test: scroll up and down using the side panel's touchpad.
6. Make the audio source the default, then investigate showing track info on the dash.
7. Self-recovery: probably drop it.
- **No-phone Hackura tap:** Settings opens with the phone unplugged. PASS.
- **P1 Bluetooth probe:** the user did not report a result; check the log at Collect.

## Log findings (Collect at 21:34; evidence in runs/helper_20261106T022027_978e1a3b251947be86af19959593de8d)
- **"Starting Android Auto…" with no start: a self-recovery bug.** Self-recovery was ON. Its restart budget (3) counts every session end, including the user's own unplug/replug cycles between switch tests. At 21:32:17 the budget ran out (`restart budget exhausted` → `RECONNECT_DISABLED`). After that, every replug was refused (`SESSION_START_REFUSED (reconnect disabled)`) and every Hackura tap too (`LAUNCH refused: hand-off in progress` / `self-recovery stopped`). The refusal message says "unplug and replug", but replugs were refused as well. Hackura still showed the "Starting Android Auto…" toast. Fixes:
  - A detach followed by a clean end (the user unplugging) must not use up the budget.
  - Disabled recovery must never block a fresh plug-in.
  - HelperActivity should show the refusal reason instead of "Starting…".
  - The user prefers to drop self-recovery anyway.
- **P1 Bluetooth probe:** never started (no P1_* lines). Not tested.
- **P2:** group up `DIRECT-xx-Car_xxxx` owner=true at 21:28:34; removed after 60 s; persistent profile deleted 1/1. Clean.
- **Persistent mode:** switched ON at 21:32:09 (canWrite=true), but the power-off was not done. Collect UNDO turned it off and revoked the grant (all hooks RC 0).
- **Home screenshot:** home-20261106.png. The tile still reads "RDX USB". The emblem is white, brighter than Honda's grey-white icons.

## Power-off run (second Start)
- Car back on at 21:43:40. Honda "Non authorized" appeared at 21:44:25 and was **not** auto-dismissed.
- User request: remove the "TAP OK ON THE PERMISSION DIALOG" overlay.
- The user accepted the authorization popups by hand. The Hackura tap still showed only "Starting Android Auto…" (21:45–21:47). AA did not start without the laptop.
- Settings opens with the phone unplugged. User idea: opening Hackura/Settings first could bring the auto-acknowledge (accessibility) back up.
- Plain plug-in after the restart: the authorization popups appear (no auto-accept). The same happens after opening Settings first.
- User request: put a button in Settings that turns the auto-accept back on, so the popups are handled again.
- After the restart, the audio source is **no longer listed** (steering wheel APPS → scroll → Hackura).

## P1 Bluetooth probe (third Start, no GRANT)
- Listening from about 21:53:40, with the phone connected to HandsFreeLink. Bluetooth was toggled off and on and the phone reconnected. The probe stayed on *listening* the whole time and never showed *phone connected*. Nothing about wireless AA appeared on the phone. The phone has no wireless AA toggle for this car.
- Reading (likely): phones only try wireless AA with a car that announced wireless support during an earlier wired AA session (the Bluetooth service in service discovery, with the car's BT address). Our receiver doesn't announce that yet. That is P3, not a dead end.
- Log (runs/helper_20261106T025219_59937aab116c41f792620712cbca19c0): P1_LISTENING on the AA UUID at 21:53:38, stopped and restarted at 21:54:38/42, then the accept() loop kept running. Honda's Bluetooth profile went down at 21:55:58 and back up at 21:56:12 (the phone toggle). No P1_ACCEPTED line. The car's Bluetooth accepted our listener next to HandsFreeLink with no errors. Final Collect: SAFE TO DISCONNECT.
