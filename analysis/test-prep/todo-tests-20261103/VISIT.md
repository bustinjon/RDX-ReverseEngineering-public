# One-visit checklist (T70 feature bundle)

The previous visit's checklist (T60) is in Git history; its results are in `builds/T60-bundle/RESULT.md`.

One install, one collection. **New defaults from the last visit:** Medium volume panel, the absolute touchpad on, the Honda audio source on, and a dimmer icon. The Hackura icon is now the **only** way back to AA. A short side-panel press leaves you on Honda's screen; holding the side panel about 2 s still opens Settings. Removed: self-recovery, the layout probe and the "TAP OK" hint.

Every **test switch** starts **off**. Turn on **one at a time**. A switch takes effect only at the **next phone plug-in**: press **Home**, unplug, wait 5 s, plug back in. All checks are done **parked**. Emergency stop: **unplug the phone**.

## 0. Before you start (reminder)
- In Honda's Android Auto settings, set the **dongle** (the second "OnePlus 13" in the phone list) to **Disabled/Never**, like your phone. It is needed for step 6.

## 1. Start (once)
1. Phone unplugged, laptop on ADB, Honda on **Home**.
2. Run **Start-T70-bundle.cmd** and type `START`. Wait for **READY**.
3. When asked about the extra step, type `GRANT`. This is needed for the "Turn on auto-accept" button and the power-off test; Collect undoes it.
4. At **TEST NOW**: open Diagnostics, go back to **Home**, then type `PASS`.
5. Disconnect the laptop. In the Diagnostics USB menu, switch to phone mode. Go back to **Home**.

## 1b. Quick check before plugging in (1 min, no laptop needed)
- With the phone connected over **Bluetooth** (not USB), look at Honda Home's top-right status area: does it show the **phone battery and signal**?
- Later, with AA full screen: does AA's own bar show the phone's signal or battery?

## 2. New defaults (about 4 min)
1. **No phone:** tap **Hackura**. Settings shows:
   - Options: Absolute touchpad **ON**, Honda audio source **ON**
   - every test switch **off**
   - volume size **Medium**
   - "Auto-accept is ON"
   Is the icon dimmer on Home?
2. **Plug in the phone** (from Home). AA starts.
3. Check, in order:
   - The ring follows your finger and a press taps under it.
   - The volume knob shows the Medium panel.
   - Home goes to Honda.
   - A **short side-panel press does nothing** (Honda stays).
   - Tapping **Hackura** brings AA back.
4. Honda's audio sources list **Hackura / Android Auto**. Select it, then try the steering-wheel next/previous.

## 3. One switch at a time
For each row: hold the side panel about 2 s to open Settings, turn **one** switch on, press **Home**, unplug, wait 5 s, plug back in, do the check, then turn it off again. Note the time.

| Switch | Check | Pass |
|---|---|---|
| **Side-panel strip scroll (T71)** | Open a long list (Spotify library, or a Maps search result). Rest a finger on the list so the ring sits on it. Then slide a finger **up and down the side-panel strip** of the touchpad (the area you use for Honda's side panel) | The list or map scrolls. Resting on or crossing the strip never taps anything |
| **Track info to Honda (T72)** | Play music in AA. Press Home and look at Honda's **Now Playing** card, the audio screen and the instrument display. Skip a track | Title/artist (maybe album art) appear and update. AA keeps working normally |
| **Maps turn-by-turn to Honda (T74)** | Start a Google Maps route in AA (parked). Press Home and look at Honda's screens and the **instrument display** for the next turn and distance. Return with Hackura; end the route | The next turn (arrow/road) and distance show on Honda's side; they clear when the route ends. AA and Maps behave as usual |
| **Wireless announce (P3)** | AA should work exactly as usual. Then press Home, **unplug**, open Settings, turn on the **Bluetooth probe** (*listening*). Turn the phone's Bluetooth off and on. Wait 1 min | AA normal while plugged in. Unplugged: the phone shows anything about wireless Android Auto, or the probe says *phone connected* |
| **Remember this phone (T73)**, do this one last | Plug in: the popups are accepted as before (with "Use by default" ticked). Then unplug, wait 5 s and plug in again | On the second plug-in AA starts with **no USB popup at all** |

**About T73:** Android keeps "Use by default" after the visit, also after a power-off. That is the point: it is how the popups go away. Turning the switch off does not undo it, and Collect does not either. From then on, **every plug-in of this phone goes straight to Hackura**, also outside a test and with any later build, and Honda's own Android Auto can no longer take this phone. That is the intended product behaviour. It only ticks the box on a popup that names Hackura, never on Honda's own. To undo, use Honda Settings > Apps > Hackura > **Clear defaults** if Honda shows it; otherwise uninstall and reinstall the app. Leave T73 on for step 4.

## 4. Power-off (optional, about 8 min)
1. In Settings, turn **Start without laptop after power-off** ON.
2. Press **Home** and unplug the phone. Car **fully off for 2 minutes**, then on. Don't touch the screen for 20 s: does Honda's "Non authorized" warning close by itself?
3. Tap **Hackura** (no phone): what does the auto-accept line say? Press **Turn on auto-accept now** and **write down the message** it shows (it now gives the system's reason).
4. From **Home**, plug in the phone. With T73 done, AA should start **with no popup**, even if auto-accept is off. Does it?
5. Look for **Hackura** in Honda's audio sources (it should still be listed after the restart). Note the times.

## 5. Collect (once)
1. Unplug the phone. In the Diagnostics USB menu, switch to **ADB mode** and reconnect the laptop.
2. **If you did step 4:** first run **After-PowerOff.cmd** and type `AFTER`. Wait for *PERSISTENT MODE OFF*.
3. Run **Collect-T70-bundle.cmd** and type `UNDO` when asked. Wait for **SAFE TO DISCONNECT**.
4. **If Collect fails or says NOT FULLY CLEANED:** run After-PowerOff.cmd (again), then Collect again, and tell Claude before relying on the car.

Tell Claude what you saw and the times you noted.

## 6. Wireless AA dongle (after Collect, about 20 min, two short rounds)
The dongle plugs into the car USB and acts like a wired phone, talking to your phone over Wi-Fi. Our receiver only accepts listed phones, so round A learns the dongle's identity and round B allows it.
- **Before:** your phone has used the dongle before (paired). Its Honda Android Auto setting (the second "OnePlus 13" in Honda's phone list) is **Disabled/Never**, like your phone.

**Round A: identify (no Add-Phone yet)**
1. Run **Start-T70-bundle.cmd** (`START`, skip GRANT, `PASS` at TEST NOW), disconnect the laptop, switch to phone mode, go to **Home**.
2. Keep your phone's USB cable out. Bluetooth and Wi-Fi stay on. Plug the **dongle** into the car's USB from Home. Wait 1 minute and note what happens (AA? Honda? nothing?).
3. Unplug the dongle, switch to ADB mode, reconnect the laptop, run **Collect-T70-bundle.cmd** (`UNDO`). Tell Claude: the log line `POLICY_UNLISTED_DEVICE` gives the dongle's serial.

**Round B: allow the dongle**
1. Run **Start-T70-bundle.cmd** again up to READY/PASS. **Before disconnecting the laptop**, run **Add-Phone.cmd**, enter the dongle serial from round A, type `YES`.
2. Disconnect the laptop, phone mode, **Home**, plug in the **dongle**. Does our full-screen AA start, with the phone in your pocket? Try music, Maps and the touchpad for 2 minutes.
3. Unplug the dongle, collect as usual.
