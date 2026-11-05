# T35 — Home-screen launch: Android Auto tile + AA Fullscreen icon

**Type:** Build  
**Run with:** Start-T35-home-launch.cmd / Collect-T35-home-launch.cmd (plus Pull-HondaLauncher.cmd for a separate tile)  
**Do first:** —

**Why:** Honda Home's Android Auto tile opens stock ProjectionActivity (a LAUNCHER app). While our session is minimized, our accessibility service sees that window and brings our AA back on top; with no session nothing changes, so Honda AA is not removed. Also our launcher entry becomes "AA Fullscreen" (restore only; the old RDX USB entry started an outdated USB flow). For a SEPARATE new tile, Pull-HondaLauncher.cmd copies the launcher (read-only) so Claude can see how tiles are chosen.

## Connection steps
Parked at Home, phone unplugged during prep. Run the Start shortcut, type START, wait for READY, do the Diagnostics checkpoint and type PASS. Switch USB to phone mode in the Honda Diagnostics menu (the label may say Apple CarPlay/phone mode), return to the Home screen FIRST (never plug the phone in while the Diagnostics menu is still open: on 2026-11-04 that left the permission overlay stuck until a car restart), then plug in the phone. Afterward: unplug the phone, switch back to ADB mode, reconnect the laptop, run the Collect shortcut, wait for SAFE TO DISCONNECT.

## Steps
- 1 With AA running, press Home (AA minimizes).
- 2 On Honda Home, select the Android Auto tile. Expected: our fullscreen AA comes back within a second (a Honda AA screen may flash first). Music and touchpad must keep working.
- 3 Press Home again, then look for an app list on Honda Home: is there an AA Fullscreen icon? If so, select it: AA should come back. (RDX USB should no longer be listed.)
- 4 The side-panel button must still bring AA back as before.
- 5 Unplug the phone and select the Android Auto tile with no session running: note what Honda shows (it should be the normal Honda AA screen; nothing of ours).
- Pass: the tile returns to our AA every time, the session never drops, and nothing changes when no session is running.

**Pass:** Tile/icon return to our AA every time; no session drop; Honda AA unchanged with no session.

**Emergency stop:** stay parked and unplug the phone — that always ends our session.

**Evidence Claude reads:** STOCK_AA_WINDOW, RESTORE_REQUEST via=aa-tile / launcher-icon.

## Result (fill in)
- Date:
- Result: PASS / FAIL / PARTIAL / NOT RUN
- What you saw:
- Photos:
