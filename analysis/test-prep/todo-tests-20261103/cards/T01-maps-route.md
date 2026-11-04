# T01 — Maps route stays active

**Type:** Watch  
**Run with:** Session A (Start-A-watch-only.cmd / Collect-A-watch-only.cmd), Maps-only build, no new code  
**Do first:** —

**Why:** Routes cancelled after about 30 s. The Maps-only build fixes a confirmed navigation-focus reply defect; this shows whether that was the cause.

## Connection steps
Parked at Home, phone unplugged during prep. Run the Start shortcut, type START, wait for READY, do the Diagnostics checkpoint and type PASS. Switch USB to phone mode in the Honda Diagnostics menu (the label may say Apple CarPlay/phone mode), return to the Home screen FIRST (never plug the phone in while the Diagnostics menu is still open: on 2026-11-04 that left the permission overlay stuck until a car restart), then plug in the phone. Afterward: unplug the phone, switch back to ADB mode, reconnect the laptop, run the Collect shortcut, wait for SAFE TO DISCONNECT.

## Steps
- Step 5 of session A: start a route away from here, at least 90 s, note if/when it cancels.
- End it, start a second route, another 90 s.
- No Spotify or button experiments during these minutes.

**Pass:** Both routes stay active for 90 s or more.

**Emergency stop:** stay parked and unplug the phone — that always ends our session.

**Evidence Claude reads:** NAVIGATION_PROTOCOL_REQUEST / REPLY lines (RDX.SESSION).

## Result (fill in)
- Date:
- Result: PASS / FAIL / PARTIAL / NOT RUN
- What you saw:
- Photos:
