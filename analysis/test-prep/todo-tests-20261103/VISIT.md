# One-visit checklist (T60 feature bundle)

The previous visit's checklist (T50) is in Git history; T50 results are in `builds/T50-bundle/RESULT.md`.

One install, one collection. The app is now called **Hackura**. Its settings open by holding the side-panel button (alone) for about 2 seconds, or by tapping the Hackura icon with no phone plugged in.

Every test switch starts **off**. Turn on **one at a time**. A switch takes effect only at the **next phone plug-in**: press **Home**, unplug, wait 5 s, plug back in. "Start without laptop" takes effect at the next power-on.

The new volume panel is now the default; that is expected. All checks are done **parked**. Emergency stop: **unplug the phone**.

## 1. Start (once)
1. Phone unplugged, laptop on ADB, Honda on **Home**.
2. Run **Start-T60-bundle.cmd** and type `START`. Wait for **READY**.
3. When asked about the extra step, type `GRANT`. This allows the "Start without laptop" test at the end; it is undone afterwards.
4. At **TEST NOW**: open Diagnostics, go back to **Home**, then type `PASS`.
5. Disconnect the laptop. In the Diagnostics USB menu, switch to phone mode. Go back to **Home**.

## 2. Hackura icon (about 3 min)
1. **Look at Honda Home.** Does the old "RDX USB" tile now say **Hackura** with the emblem? (It may need a moment, or a trip into the app list and back.)
2. **No phone:** tap **Hackura**. Hackura Settings should open with "No phone detected". Check: every switch **off**, screen size **Standard**, volume display **On**, size **Small**. If anything differs, press **Reset all**. Press **Home**.
3. **Plug in the phone** (from Home). AA starts as usual.
4. **Everything off (2 min):** AA, music, touchpad, Home → Honda, side panel → AA. The volume knob shows the new rounded panel.
5. **AA hidden:** press Home, then tap **Hackura** (Home tile or app list). AA should come back.

## 3. One switch at a time
For each row: hold the side panel about 2 s to open Settings, change **one** thing, press **Home**, unplug, wait 5 s, plug back in, do the check, then set it back (or **Reset all**). Note the time.

| Change | Check | Pass |
|---|---|---|
| Volume size **Medium**, then **Large** | Turn the knob | Bigger panel; pick your favourite |
| **Absolute touchpad** ON (alignment **top**) | Rest a finger: the ring (white with a dark outline) follows. Press: taps exactly under the ring. Try buttons at the **top and bottom** of the screen | Taps land under the ring |
| Same, plus alignment **centred** | Same taps | Compare: which one lands right? |
| **Honda audio source** ON | Press Home, then look for **Hackura** among Honda's audio sources (Now Playing card, or the console audio/source button). Select it; console next/previous | Listed; music keeps playing; one track per press |
| **Layout probe 320**, then **400** | Look at Maps and Spotify | Does AA stop splitting the screen? Note which value, if any |
| **Self-recovery** ON | Use AA normally; leave it on for the rest of the visit if you like. If AA ever drops to Honda Home with the cable in, wait 10 s | AA comes back by itself; replugs still work |

Car GPS passed last visit (the car sends its position); its switch is still there but needs no test now.

**Honda audio source note:** Honda builds its source list when an app is installed or the car starts. If Hackura is not listed now, check again after the power-off in step 5.

## 4. Wireless probes (about 5 min; observe only, nothing to replug)
These only listen and log. Neither one starts AA over Wi-Fi. Unplugging the phone does **not** stop them: the Bluetooth probe stops when you tap it again (or after 15 min), and the Wi-Fi Direct test removes itself after 60 s. If the Wi-Fi Direct line ever says *REMOVE UNCONFIRMED*, turn the car off and on before driving.
1. **Bluetooth probe (P1):** in Settings, tap **Bluetooth probe** until it says *listening*. Leave the USB cable **unplugged**. On the phone, turn **Bluetooth off and on** so it reconnects to the car (calls/audio as usual). Wait 1 minute and watch the phone for any Android Auto wireless message. Back in Settings, does the probe say *phone connected*? Tap it again to stop (it also stops by itself after 15 min). Note the time.
2. **Wi-Fi Direct test (P2):** tap **Wi-Fi Direct test now**. After about 5 s the line under it should say *group up on ...*; after 60 s *done (group removed)*. Optional: on the phone, open Wi-Fi > Wi-Fi Direct and see if a "DIRECT-...Car" name appears during that minute. Note the time.

## 5. Start without laptop (last, needs a power-off)
1. In Settings, turn **Start without laptop after power-off** ON. It should not say "needs the one-time laptop grant" (if it does, step 1.4 was skipped: leave this test for next time).
2. Press **Home** and unplug the phone.
3. Car **fully off for 2 minutes**, then on. Don't touch the screen for 20 s: does Honda's "Non authorized" warning close by itself?
4. From **Home**, plug in the phone: does AA start with no laptop? If it does not, tap **Hackura**: does it start then?
5. If you turned on the Honda audio source earlier, check Honda's audio sources once more for **Hackura** (switch it ON first and replug if you had turned it off).
6. Note the times.

## 6. Collect (once)
1. Unplug the phone. In the Diagnostics USB menu, switch to **ADB mode** and reconnect the laptop.
2. **If you did step 5:** first run **After-PowerOff.cmd** and type `AFTER`. It saves the log since the restart (the test logger stops at power-off) and switches "Start without laptop" off. Wait for *PERSISTENT MODE OFF*.
3. Run **Collect-T60-bundle.cmd**. When asked, type `UNDO`.
4. Wait for **SAFE TO DISCONNECT**.
5. **If Collect fails or says NOT FULLY CLEANED:** run After-PowerOff.cmd (again), then Collect again, and tell Claude before relying on the car.

Tell Claude what you saw and the times you noted.

## Kept separate
- **T41 second phone:** needs a second phone with its Honda Android Auto setting set to **Disabled/Never**; run Add-Phone.cmd after READY, then follow the T41 card.
