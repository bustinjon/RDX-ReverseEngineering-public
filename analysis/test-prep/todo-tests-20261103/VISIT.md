# One-visit checklist (T290: deeper freeze recorder + boot-delay A/B)

T280 results: `builds/T280-bundle/RESULT.md`. T290 adds no visible changes. It records much more about each freeze:
- whether the data was **sitting in the car unread** (a Hackura problem) or **never arrived** (radio/phone problem)
- whether the phone had to **re-send** data (lost packets)
- every **Bluetooth and Wi-Fi event** on the car (calls, contacts, audio connecting, car Wi-Fi scans) on the same timeline

It also adds a test switch: **Settings > Developer > "Wireless: wait 2 min after boot (test)"**, OFF by default.

**Never tap "Remove all"** on Honda's warning. Leave Settings with **Back**. Emergency stop: main Settings > **Wireless Android Auto: off**.

## 1. Start (once)
1. Phone and dongle unplugged. Diagnostics USB menu: **ADB mode**, connect the laptop.
2. Run **Start-T290-bundle.cmd**, type `START`. Honda Settings may flash, then Home. Wait for **READY**. At **TEST NOW**: open Diagnostics, back to **Home**, type `PASS`.
3. Unplug the laptop. Phone hotspot **off**.

## 2. Drive A: normal (boot-delay switch OFF)
- Start the car normally. Wireless AA connects by itself.
- Note the time of each freeze or audio drop, and **where** you were: driveway, on the road, parked somewhere else.
- Note any Bluetooth-only glitches too.

## 3. Drive B: boot delay ON (a later drive, or after a car restart)
1. Parked: **Settings > Developer > "Wireless: wait 2 min after boot (test)"**, turn it **ON**.
2. Next car start: wireless AA now waits about 2 minutes before connecting. That's expected.
3. Note freezes the same way. Are there fewer in the first few minutes than in drive A?
4. When done, turn the switch back **OFF** (or tell me to keep it).

## 4. Collect (whenever convenient; logs survive power-offs)
1. Diagnostics USB menu: **ADB mode**, laptop connected.
2. Run **Collect-T290-bundle.cmd**. It shows **CAR LOGS COPIED**, then type `COLLECT`, then **`KEEP`**. Wait for **SAFE TO DISCONNECT**.

Tell Claude your times and locations for each drive.
