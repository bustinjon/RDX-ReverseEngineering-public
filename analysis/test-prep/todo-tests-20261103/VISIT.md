# One-visit checklist (T320: review fixes)

Fixes from the Fable review (`analysis/agent-reviews/fable-review-20261111/REPORT.md`). Everything else is the same as T310.
- Collect **UNDO** now also puts the car's own Wi-Fi scan settings back.
- The main Settings page no longer shows the wireless network name and password.
- Other apps on the head unit can no longer send commands to Hackura (the laptop still can).
- On every **USB** connection Hackura learns the phone's Bluetooth address, so per-phone wireless settings work on a fresh install.
- If the car's wireless network disappears (Wi-Fi restart), Hackura rebuilds it within about a minute.

**Never tap "Remove all"** on Honda's warning. Leave Settings with **Back**. Emergency stop: main Settings > **Wireless Android Auto: off**.

## 1. Start (once)
1. Phone and dongle unplugged. Diagnostics USB menu: **ADB mode**, connect the laptop.
2. Run **Start-T320-bundle.cmd**, type `START`. Wait for **READY**. At **TEST NOW**: open Diagnostics, back to **Home**, type `PASS`.
3. Unplug the laptop.

## 2. Quick checks (parked, 5 min)
1. Wireless AA connects by itself. Main Settings shows "Wireless Android Auto: ON · ready", with **no network name or password**.
2. Plug the phone in by **USB** once (wired AA starts normally, no extra pairing pop-up on the phone?), then unplug. Wireless AA comes back.
3. Wireless Android Auto **off**, wait 10 s, **on** (logs the scan settings being restored).

## 3. Use it normally
Drive as usual; note the time and place of any freeze.

## 4. Collect (whenever convenient)
1. Diagnostics USB menu: **ADB mode**, laptop connected.
2. Run **Collect-T320-bundle.cmd**. **CAR LOGS COPIED**, then `COLLECT`, then **`KEEP`**. Wait for **SAFE TO DISCONNECT**.
