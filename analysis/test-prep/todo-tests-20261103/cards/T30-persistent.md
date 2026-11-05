# T30 — Persistent mode (laptop-free after power-off) + popup dismiss

**Type:** Build  
**Run with:** Start-T30-persistent.cmd / Collect-T30-persistent.cmd  
**Do first:** —

**Why:** 2026-11-04 T26 run: the head unit fully resets at power-off and returns with accessibility switched off, so the auto-clicker, popup dismiss and AA start all failed. WRITE_SECURE_SETTINGS is signature|system|development on this firmware, so it can be granted once over ADB; persistent mode then re-enables only our accessibility service at boot (0, 20, 60 s) and starts the helper. Off by default; switched on and off by explicit ADB steps the runner shows and asks for.

## Connection steps
Parked at Home, phone unplugged during prep. Run the Start shortcut, type START, wait for READY, do the Diagnostics checkpoint and type PASS. Switch USB to phone mode in the Honda Diagnostics menu (the label may say Apple CarPlay/phone mode), return to the Home screen FIRST (never plug the phone in while the Diagnostics menu is still open: on 2026-11-04 that left the permission overlay stuck until a car restart), then plug in the phone. Afterward: unplug the phone, switch back to ADB mode, reconnect the laptop, run the Collect shortcut, wait for SAFE TO DISCONNECT.

## Steps
- Persistent mode is now ON (you typed PERSIST after READY).
- 1 Phone handoff as usual; check AA works; unplug the phone. Do NOT Collect.
- 2 Car fully off 2 minutes, then on. Do not touch the screen for 20 s: does the Non authorized popup close by itself?
- 3 From Home, plug in the phone: does the USB prompt get accepted by itself and AA start, with no laptop?
- 4 Then connect the laptop in ADB mode and Collect. When asked, type UNDO to switch persistent mode off and remove the grant.
- Pass: popup dismissed and AA starts after the power-off, all without the laptop.

**Pass:** After power-off: popup closes by itself and AA starts on plug-in, no laptop.

**Emergency stop:** stay parked and unplug the phone — that always ends our session.

**Evidence Claude reads:** RDX.PERSIST PERSIST_A11Y_RESTORED / PERSIST_HELPER_STARTED; RDX.A11Y DETECTOR_WARNING_DISMISSED.

## Result (fill in)
- Date:
- Result: PASS / FAIL / PARTIAL / NOT RUN
- What you saw:
- Photos:
