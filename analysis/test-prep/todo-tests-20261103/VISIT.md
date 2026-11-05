# One-visit checklist (T50 feature bundle)

Everything below is one install and one collection. Each feature is a switch in **AA Settings**. All switches start **off**. With everything off (switches off, density **Standard**, volume display **On**), AA behaves like today's tested build. The only additions are the **AA Fullscreen** and **AA Settings** icons, the side-panel long hold, and frame-rate logging. A switch only takes effect at the **next phone plug-in**; it never changes a running session.

All checks below are done **parked**. Emergency stop at any time: **unplug the phone**.

## 0. Survey (about 3 min, laptop only)
1. Phone unplugged, laptop on ADB, Honda on the **Home** screen, audio source not FM.
2. Run **Survey.cmd** and type `SURVEY`. When asked: turn the volume knob, release and set the parking brake, press the steering-wheel buttons.
3. Wait for SAFE TO DISCONNECT. Don't disconnect yet.

## 1. Start the bundle (once)
1. Run **Start-T50-bundle.cmd** and type `START`.
2. Wait for **READY**.
3. At **TEST NOW**: open Diagnostics, go back to **Home**, then type `PASS`.
4. Disconnect the laptop. In the Diagnostics USB menu, switch to phone mode.
5. **Go back to Home first.** Hold the side-panel button about 2 s to open **AA Settings**. Check it shows every switch **off**, density **Standard** and volume display **On**. If anything differs, press **Reset all**.
6. Press **Home**, then plug in the phone.
7. **Check with everything off (2 min):** AA, music, touchpad, Home → Honda, side panel → AA. This must behave like today.

## 2. One switch at a time

For each switch:
1. Press **Home**, then hold the side-panel button about 2 s. **AA Settings** opens.
2. Turn **one** switch ON.
3. Press **Home** so you are on Honda Home. Unplug the phone, wait 5 s, then plug it back in.
4. Do the checks below.
5. Press Home and open AA Settings again. Turn the switch **off** (or press **Reset all**).
6. Note the time.

| Switch | Checks (parked) | Pass |
|---|---|---|
| New volume look | Turn the knob and the wheel volume buttons | Rounded panel with level bar; you like it |
| Absolute touchpad | Rest a finger: a ring follows it. Press: taps there. Press and slide: pans the map. Back still works | Taps land under the ring |
| Android Auto tile returns to AA | Home, then the **Android Auto** tile on Honda Home | Our AA comes back. If Honda lists apps, also try the **AA Fullscreen** icon |
| Honda audio source | Home, then Honda's audio source list. Select **AA Fullscreen**. Console next/previous; hold a seek button | Listed, music keeps playing, one track per press, no pause on hold |
| Car GPS to phone | Parked: AA map shows your position and the log records the car GPS. Moving check only if you later choose to drive with it on | Position correct, no jumps |

**Density, once, with all switches off.** In AA Settings choose **Smaller**, then Home and replug, and look. Then **Larger**, Home and replug, and look. Then **Standard**, Home and replug: AA must look like today again. The frame rate is logged automatically.

**Opening AA Settings:** hold the **side-panel button for about 2 seconds**, alone with no other button. AA minimizes first, then the settings screen opens. If AA cannot minimize, nothing opens. A short press still brings AA back. If Honda Home has an app list, the "AA Settings" icon works too.

## 3. Collect (once)
1. Before unplugging, open AA Settings and press **Reset all**. Press **Home**, then unplug the phone.
2. In the Diagnostics USB menu, switch back to ADB mode and reconnect the laptop.
3. Run **Collect-T50-bundle.cmd** and wait for **SAFE TO DISCONNECT**.

Tell Claude the times you noted for each switch.

## Kept separate (they change things across a restart or rewire USB)
- **T30 persistent mode:** Start-T30-persistent.cmd (power-off test).
- **T43 self-recovery:** Start-T43-self-recovery.cmd.
- **T41 second phone:** needs a second phone with Android Auto, **with its Honda Android Auto setting set to Disabled/Never** like yours. After READY in the bundle (laptop still on ADB), run Add-Phone.cmd. Then follow the T41 card.
