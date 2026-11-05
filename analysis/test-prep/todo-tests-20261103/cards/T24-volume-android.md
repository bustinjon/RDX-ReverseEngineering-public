# T24 — Volume number on screen (Android master volume) - PASSED 2026-11-04

**Type:** Build  
**Run with:** Start-T24-volume-android.cmd / Collect-T24-volume-android.cmd  
**Do first:** —

**Why:** Item 3. Honda's amplifier broadcast is protected, but Android's MASTER_VOLUME_CHANGED_ACTION (no permission) followed the knob 14 to 18 in the signal check.

## Connection steps
Parked at Home, phone unplugged during prep. Run the Start shortcut, type START, wait for READY, do the Diagnostics checkpoint and type PASS. Switch USB to phone mode in the Honda Diagnostics menu (the label may say Apple CarPlay/phone mode), return to the Home screen FIRST (never plug the phone in while the Diagnostics menu is still open: on 2026-11-04 that left the permission overlay stuck until a car restart), then plug in the phone. Afterward: unplug the phone, switch back to ADB mode, reconnect the laptop, run the Collect shortcut, wait for SAFE TO DISCONNECT.

## Steps
- 1 Play music in AA. Turn the volume knob up 3 clicks and down 3 clicks, then use the wheel volume buttons.
- 2 Watch the top centre: a Volume N box should show for about 3 s, the number following the knob.
- 3 Check the touchpad still works while the box shows.
- Pass: the box appears on every change and the number tracks the knob; nothing else changes.

**Pass:** Volume N box on every change, number follows the knob.

**Emergency stop:** stay parked and unplug the phone — that always ends our session.

**Evidence Claude reads:** VOLUME_FEEDBACK_REGISTERED source=ANDROID_MASTER_VOLUME / _RECEIVED / _SHOWN.

## Result (fill in)
- Date:
- Result: PASS / FAIL / PARTIAL / NOT RUN
- What you saw:
- Photos:
