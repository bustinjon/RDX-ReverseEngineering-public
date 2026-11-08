# One-visit checklist (T140 feature bundle)

The T130 checklist is in Git history; its results are in `builds/T130-bundle/RESULT.md`.

One install, one collection, about 25 minutes, all parked.

**What T140 changes:**
- **Auto-dismiss Honda's warning** (on by default, Developer page): after a power-off Hackura now looks for the warning for 3 minutes and presses **Dismiss** only (before, it gave up after about 5 s, often before the warning appeared).
- **Steady cursor** (on by default, switch on the main Settings page): a press taps where the cursor was just before you pushed, not where the push rolled your finger; small tremor no longer moves the cursor; while you hold the press, small movement stays a tap (a real move becomes a drag). The ring shows your finger; the tap lands where you aimed.

**Never tap "Remove all"** on Honda's "Non authorized" warning: it uninstalls Hackura. Use Dismiss.

**Tips:** leave Settings with **Back**. Emergency stop: **unplug the phone**. Note the time of every check.

## 1. Start (once)
1. Phone and dongle unplugged, Honda on **Home**. In the Diagnostics USB menu, choose **ADB mode** and connect the laptop.
2. Run **Start-T140-bundle.cmd** and type `START`. Wait for **READY** (the grant runs by itself).
3. At **TEST NOW**: open Diagnostics, go back to **Home**, then type `PASS`.
4. Disconnect the laptop. In the Diagnostics USB menu, switch to phone mode. Go back to **Home**.

## 2. Steady cursor (about 8 min)
1. **From Home, plug in the phone.** AA starts.
2. Tap 10 small targets on purpose (AA app icons, list rows, small map buttons such as zoom or recentre). How many land first time? Compare with how it felt before.
3. Pan the map with a press-and-drag. Does it still drag smoothly?
4. Settings (hold side panel) > main page > **Steady cursor: off**. Press **Home**, unplug, wait 5 s, plug back in. Repeat step 2 and note the difference. Switch it back **on**, replug.

## 3. AA highlight mode, for comparison (about 5 min)
1. Settings > **Absolute touchpad: off**. Press **Home**, unplug, wait 5 s, plug back in.
2. AA now shows a highlight that you move with swipes; a press selects it. Try the same targets. Better or worse? Note it.
3. Switch **Absolute touchpad** back **on**, replug.

## 4. "Non authorized" warning after a power-off (about 5 min)
1. Unplug everything. Car **fully off for 2 minutes**, then on. Do **not** touch the warning.
2. Does the warning appear? Does it go away **by itself** (Hackura should press **Dismiss**)? Wait up to **3 minutes** before touching it, and note the times.
3. Only if it is still there after 3 minutes, press **Dismiss** yourself.

## 5. Collect (once)
1. In the Diagnostics USB menu, switch to **ADB mode** and reconnect the laptop.
2. Run **After-PowerOff.cmd** (`AFTER`): it saves the log since the power-off.
3. Run **Collect-T140-bundle.cmd**, type `COLLECT`, then `UNDO`. Wait for **SAFE TO DISCONNECT**.

Do not run another test after Collect.

Tell Claude what you saw and the times you noted.
