# One-visit checklist (T90 feature bundle)

The T80 checklist is in Git history; its results are in `builds/T80-bundle/RESULT.md`.

One install, one collection. **New default:** Separate navigation volume is now an option that is **on** (it passed on Nov 6). Track info, Turn-by-turn, Remember this phone, Absolute touchpad and the Honda audio source stay on.

**What T90 changes:**
- **Dongle:** the Add-Phone entry is no longer wiped by Start (that is why the dongle was rejected on Nov 6).
- **Strip scroll v3:** a scroll never starts in the top or bottom quarter of the screen (fixes "finger down does nothing" in the 1/3 pane).
- **Talk button:** Hackura now listens for the talk button. It is not yet known whether Honda lets it hear the button; this visit finds out. With the new switch on, **holding** it should open the phone assistant, the way stock AA does.
- **Dash refresh:** a switch that re-sends the track to Honda every 10 s.

**Remember this phone is lasting.** Once Android has saved "Use by default" for a device, it stays saved: turning the option off or running UNDO does not clear it. Only uninstalling Hackura, or **Clear defaults** on Hackura's Android app-info page, removes it.

Every **test switch** starts **off**. Turn on **one at a time**. A switch applies at the **next phone plug-in**: press **Home**, unplug, wait 5 s, plug back in. All checks are done **parked**. Emergency stop: **unplug the phone**.

## 1. Start (once)
1. Phone unplugged, Honda on **Home**. In the Diagnostics USB menu, choose **ADB mode** and connect the laptop.
2. Run **Start-T90-bundle.cmd** and type `START`. Wait for **READY**.
3. When asked about the extra step, **skip GRANT** (press Enter).
4. At **TEST NOW**: open Diagnostics, go back to **Home**, then type `PASS`.
5. **Laptop still connected, after READY:** run **Add-Phone.cmd**, enter `DONGLE_SERIAL` (the dongle), type `YES`.
6. Disconnect the laptop. In the Diagnostics USB menu, switch to phone mode. Go back to **Home**.

## 2. Talk button, no switch (about 3 min)
1. **From Home, plug in the phone.** AA starts.
2. **Press** the steering-wheel talk button once, then cancel Honda voice. Note the time.
3. **Hold** the talk button about 2 s. Note the time and what opened (Honda voice, Gemini, both, nothing).

This shows whether Hackura can hear the button at all.

## 3. Gemini (about 3 min)
1. Before this step, check that Gemini answers on the phone itself (unplugged) where you are parked.
2. In AA, tap the mic and ask something simple ("what time is it"). Does Gemini **answer out loud**? Note the time.
3. If it does not, go to Settings, turn **Separate navigation volume** off, replug, and try once more. Note the time.

## 4. One switch at a time
For each switch:
1. Hold the side panel about 2 s to open Settings and turn the switch **on**.
2. Press **Home**, unplug, wait 5 s, plug back in.
3. Do the check and note the time.
4. Turn the switch **off** again.

| Switch | Check | Pass |
|---|---|---|
| **Talk button hold opens Assistant (T93)** | Hold the talk button about 2 s. Then press it briefly | Hold opens Gemini; a short press still opens Honda voice |
| **Side-panel strip scroll v3 (T91)** | List in the **1/3 pane**: rest your finger on it, slide the strip **down**, then **up**. Repeat in the **2/3 pane** | Both directions scroll in both panes; nothing gets tapped |
| **Dash track refresh (T94)** | Play music for 1 minute and watch the dash | The track stays on the dash, not only at a song change. Note if it flickers or pops up |

## 5. Wireless dongle (about 5 min)
1. Press **Home** and unplug your phone. Leave your phone's Bluetooth and Wi-Fi on.
2. **From Home, plug in the dongle.** If a USB popup appears, it is accepted automatically, possibly twice. Wait up to 30 s. Does our full-screen AA start, with the phone in your pocket?
3. If it does, try music, Maps and the touchpad for 2 min. Note the time.
4. Unplug the dongle.

## 6. Collect (once)
1. Unplug everything. In the Diagnostics USB menu, switch to **ADB mode** and reconnect the laptop.
2. Run **Collect-T90-bundle.cmd** and type `UNDO`. Wait for **SAFE TO DISCONNECT**.
3. If it says **NOT FULLY CLEANED**, run **After-PowerOff.cmd** (`AFTER`), then Collect again, and tell Claude.

Do not run another test after Collect: Collect stops Hackura, so plug-ins go to Honda until the next Start.

Tell Claude what you saw and the times you noted.
