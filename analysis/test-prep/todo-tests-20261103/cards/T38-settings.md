# T38 — Settings screen (density, volume display)

**Type:** Build  
**Run with:** Start-T38-settings.cmd / Collect-T38-settings.cmd  
**Do first:** —

**Why:** "AA Settings" launcher entry: screen density Smaller 180 / Standard 229 / Larger 280 (Android Auto sizes its UI from it), volume display on/off, allowed-phone status. Applies at the next connection.

## Connection steps
Parked at Home, phone unplugged during prep. Run the Start shortcut, type START, wait for READY, do the Diagnostics checkpoint and type PASS. Switch USB to phone mode in the Honda Diagnostics menu (the label may say Apple CarPlay/phone mode), return to the Home screen FIRST (never plug the phone in while the Diagnostics menu is still open: on 2026-11-04 that left the permission overlay stuck until a car restart), then plug in the phone. Afterward: unplug the phone, switch back to ADB mode, reconnect the laptop, run the Collect shortcut, wait for SAFE TO DISCONNECT.

## Steps
- 1 Before plugging in the phone (after the Diagnostics checkpoint, phone unplugged): look for an AA Settings icon on Honda Home or its app list and open it with the touchpad. Note whether it can be reached.
- 2 Choose Smaller, then plug in the phone: AA should show smaller icons and more map. Photo.
- 3 Unplug, open AA Settings, choose Larger, plug in again: bigger icons. Photo. Then Standard.
- 4 Turn the volume display Off, reconnect: no volume box. Turn it back On.
- Pass: each setting changes AA as described after reconnecting; nothing else changes.

**Pass:** Each setting changes AA as described after reconnecting.

**Emergency stop:** stay parked and unplug the phone — that always ends our session.

**Evidence Claude reads:** SETTINGS_DPI=, SETTINGS_APPLIED layoutDpi=, VOLUME_FEEDBACK_DISABLED.

## Result (fill in)
- Date:
- Result: PASS / FAIL / PARTIAL / NOT RUN
- What you saw:
- Photos:
