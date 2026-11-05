# T16 — Ignition off/on, then plug in (laptop-free restart)

**Type:** Watch  
**Run with:** Start-B-current-baseline.cmd / Collect-B-current-baseline.cmd  
**Do first:** —

**Why:** Reconnect/startup item 1. Replug already reconnects inside one run; nobody has tested whether the helper survives the head unit sleeping.

## Connection steps
Parked at Home, phone unplugged during prep. Run the Start shortcut, type START, wait for READY, do the Diagnostics checkpoint and type PASS. Switch USB to phone mode in the Honda Diagnostics menu (the label may say Apple CarPlay/phone mode), return to the Home screen FIRST (never plug the phone in while the Diagnostics menu is still open: on 2026-11-04 that left the permission overlay stuck until a car restart), then plug in the phone. Afterward: unplug the phone, switch back to ADB mode, reconnect the laptop, run the Collect shortcut, wait for SAFE TO DISCONNECT.

## Steps
- 1 Start a session as usual, use AA a minute, unplug the phone. Do NOT Collect.
- 2 Car fully off, doors closed, wait 2 minutes; start again.
- 3 From Home, plug in the phone. Does AA start without the laptop? Note the time.
- 4 Connect the laptop and Collect.

**Pass:** AA starts after the restart with no laptop action (otherwise: the helper needs a start-at-boot path; see T30).

**Emergency stop:** stay parked and unplug the phone — that always ends our session.

**Evidence Claude reads:** RDX.USB service start after boot, UsbAttachActivity lines.

## Result (fill in)
- Date:
- Result: PASS / FAIL / PARTIAL / NOT RUN
- What you saw:
- Photos:
