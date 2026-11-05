# T22 — Get back to our AA after pressing Home

**Type:** Build  
**Run with:** Start-T22-return-to-aa.cmd / Collect-T22-return-to-aa.cmd  
**Do first:** —

**Why:** Found 2026-11-04: once Honda Home is pressed there is no way back to our AA without replugging. Also blocks changing the Honda audio source mid-session.

## Connection steps
Parked at Home, phone unplugged during prep. Run the Start shortcut, type START, wait for READY, do the Diagnostics checkpoint and type PASS. Switch USB to phone mode in the Honda Diagnostics menu (the label may say Apple CarPlay/phone mode), return to the Home screen FIRST (never plug the phone in while the Diagnostics menu is still open: on 2026-11-04 that left the permission overlay stuck until a car restart), then plug in the phone. Afterward: unplug the phone, switch back to ADB mode, reconnect the laptop, run the Collect shortcut, wait for SAFE TO DISCONNECT.

## Steps
- 0 At the Diagnostics checkpoint, check the three-button shortcut still opens normally (key filtering is new).
- 1 With AA showing and music playing, press Home ONCE. Expected: AA minimizes to the Honda screen and music keeps playing. If nothing happens, hold Back 1 s instead.
- 2 Use Honda screens normally (change audio source, open menus). Every Honda button must behave normally.
- 3 Press Home twice quickly. Expected: AA comes back with picture, touchpad and audio.
- 4 Repeat minimize/restore 3 times.
- 5 Press each side-panel / console button once while on a Honda screen and note the time (the logs show which ones our helper can see, for a possible remap).
- Pass: Home minimizes, double Home restores, and Honda buttons all work normally.

**Pass:** Honda screens usable while AA keeps running; back to AA without replugging.

**Emergency stop:** stay parked and unplug the phone — that always ends our session.

**Evidence Claude reads:** HOME_KEY decision=, OVERLAY_MINIMIZED, OVERLAY_RESTORED via= (RDX.AAOVERLAY).

## Result (fill in)
- Date:
- Result: PASS / FAIL / PARTIAL / NOT RUN
- What you saw:
- Photos:
