# One-visit checklist (T310: freeze fix on by default)

T300 results: `builds/T300-bundle/RESULT.md` (no freezes since the car's Wi-Fi scans were reduced). T310 changes one thing:
- **"Fewer car Wi-Fi scans" is ON by default** (no longer a test switch). Channel 149 stays the default.

**Never tap "Remove all"** on Honda's warning. Leave Settings with **Back**. Emergency stop: main Settings > **Wireless Android Auto: off**.

## 1. Start (once)
1. Phone and dongle unplugged. Diagnostics USB menu: **ADB mode**, connect the laptop.
2. Run **Start-T310-bundle.cmd**, type `START`. Wait for **READY**. At **TEST NOW**: open Diagnostics, back to **Home**, type `PASS`.
3. Unplug the laptop.

## 2. Use it normally
- Daily drives as usual. Note the time and place of any freeze.
- Once, parked: main Settings > **Wireless Android Auto off**, wait 10 s, **on** again (this logs that the car's own Wi-Fi settings come back when wireless stops).

## 3. Collect (whenever convenient)
1. Diagnostics USB menu: **ADB mode**, laptop connected.
2. Run **Collect-T310-bundle.cmd**. **CAR LOGS COPIED**, then `COLLECT`, then **`KEEP`**. Wait for **SAFE TO DISCONNECT**.
