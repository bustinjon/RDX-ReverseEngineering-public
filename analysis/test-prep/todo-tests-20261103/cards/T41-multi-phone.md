# T41 — A second phone can use AA

**Type:** Build  
**Run with:** Start-T41-multi-phone.cmd + Add-Phone.cmd / Collect-T41-multi-phone.cmd  
**Do first:** A second phone

**Why:** Up to 4 extra phones besides the configured one, added with an explicit command. Each needs Honda Disabled/Never.

## Connection steps
Parked at Home, phone unplugged during prep. Run the Start shortcut, type START, wait for READY, do the Diagnostics checkpoint and type PASS. Switch USB to phone mode in the Honda Diagnostics menu (the label may say Apple CarPlay/phone mode), return to the Home screen FIRST (never plug the phone in while the Diagnostics menu is still open: on 2026-11-04 that left the permission overlay stuck until a car restart), then plug in the phone. Afterward: unplug the phone, switch back to ADB mode, reconnect the laptop, run the Collect shortcut, wait for SAFE TO DISCONNECT.

## Steps
- Needs: a second Android phone with Android Auto, its USB serial (Settings > About phone > Status, or adb devices), and its Honda Android Auto setting set to Disabled/Never like yours.
- 1 After READY and the Diagnostics PASS, with the laptop still on ADB: run Add-Phone.cmd, enter the second phone serial, type YES.
- 2 Handoff as usual with YOUR phone; check AA works; unplug.
- 3 Plug in the second phone (from Home): AA should start the same way.
- 4 Plug your phone back in: still works.
- Pass: both phones work; an unlisted phone is ignored.

**Pass:** Both phones work; unlisted phones ignored.

**Emergency stop:** stay parked and unplug the phone — that always ends our session.

**Evidence Claude reads:** POLICY_EXTRA_PHONES.

## Result (fill in)
- Date:
- Result: PASS / FAIL / PARTIAL / NOT RUN
- What you saw:
- Photos:
