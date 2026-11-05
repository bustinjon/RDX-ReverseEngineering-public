# T26 — Honda unauthorized-app popup closed automatically (+ ignition cycle)

**Type:** Build  
**Run with:** Start-T26-warning-dismiss.cmd / Collect-T26-warning-dismiss.cmd  
**Do first:** —

**Why:** Item 6. The detector flags any non-system app and keeps a permanent history bit, so the popup returns about 10 s after every boot. Narrow fix: our accessibility service taps only the exact Dismiss button on only that dialog (never Remove all). The detector is not touched.

## Connection steps
Parked at Home, phone unplugged during prep. Run the Start shortcut, type START, wait for READY, do the Diagnostics checkpoint and type PASS. Switch USB to phone mode in the Honda Diagnostics menu (the label may say Apple CarPlay/phone mode), return to the Home screen FIRST (never plug the phone in while the Diagnostics menu is still open: on 2026-11-04 that left the permission overlay stuck until a car restart), then plug in the phone. Afterward: unplug the phone, switch back to ADB mode, reconnect the laptop, run the Collect shortcut, wait for SAFE TO DISCONNECT.

## Steps
- 1 Use AA normally for a minute, then unplug the phone. Do NOT run Collect yet.
- 2 Turn the car fully off (doors closed, wait 2 minutes so the head unit sleeps), then start it again.
- 3 Watch the screen for about 20 s after Honda Home appears: does the Non authorized by Honda warning show, and does it close by itself within a second or two?
- 4 Then plug in the phone (from Home). Note whether AA starts without the laptop (this is the ignition-cycle result).
- 5 Afterwards connect the laptop and run Collect as usual.
- Pass: the warning closes itself (or never shows) and, separately, note whether AA starts after the ignition cycle.

**Pass:** The popup closes itself within a couple of seconds.

**Emergency stop:** stay parked and unplug the phone — that always ends our session.

**Evidence Claude reads:** DETECTOR_WINDOW, DETECTOR_WARNING_DISMISSED (RDX.A11Y).

## Result (fill in)
- Date:
- Result: PASS / FAIL / PARTIAL / NOT RUN
- What you saw:
- Photos:
