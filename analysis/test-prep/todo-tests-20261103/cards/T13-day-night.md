# T13 — Day/night map colours

**Type:** Build  
**Run with:** Start-T13-day-night.cmd / Collect-T13-day-night.cmd  
**Do first:** T06 lists lcd_service (helpful, not required)

**Why:** We always tell the phone it is daytime, so the map stays bright at night.

## Connection steps
Parked at Home, phone unplugged during prep. Run the Start shortcut, type START, wait for READY, do the Diagnostics checkpoint and type PASS. Switch USB to phone mode in the Honda Diagnostics menu (the label may say Apple CarPlay/phone mode), return to the Home screen FIRST (never plug the phone in while the Diagnostics menu is still open: on 2026-11-04 that left the permission overlay stuck until a car restart), then plug in the phone. Afterward: unplug the phone, switch back to ADB mode, reconnect the laptop, run the Collect shortcut, wait for SAFE TO DISCONNECT.

## Steps
- Best done around dusk, or by switching the head unit display between day and night if your car allows it (headlights on/off with auto dim).
- 1 Start AA in daylight: map should be light. 2 Switch the car to night display (or wait for dark): within about 10 s the AA map should turn dark. 3 Switch back.
- Pass: AA map colours follow the car. If they never change, note whether the car display itself changed.

**Pass:** AA map turns dark when the car display goes to night, and back.

**Emergency stop:** stay parked and unplug the phone — that always ends our session.

**Evidence Claude reads:** NIGHT_MODE_* (RDX.NIGHT), Night mode reported (RDX.SENSOR).

## Result (fill in)
- Date:
- Result: PASS / FAIL / PARTIAL / NOT RUN
- What you saw:
- Photos:
